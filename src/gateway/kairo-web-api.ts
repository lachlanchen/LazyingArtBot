import type { IncomingMessage, ServerResponse } from "node:http";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import readline from "node:readline";
import { authorizeGatewayConnect, isLocalDirectRequest, type ResolvedGatewayAuth } from "./auth.js";
import { getBearerToken } from "./http-utils.js";

const API_PREFIX = "/api";

const STATE_DIR =
  process.env.OPENCLAW_STATE_DIR ??
  process.env.KAIRO_HOME ??
  process.env.CLAWDBOT_STATE_DIR ??
  path.join(os.homedir(), ".openclaw");

function sendJson(res: ServerResponse, status: number, body: unknown) {
  res.statusCode = status;
  res.setHeader("Content-Type", "application/json; charset=utf-8");
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Headers", "Authorization, Content-Type");
  res.end(JSON.stringify(body));
}

function sendError(res: ServerResponse, status: number, message: string) {
  sendJson(res, status, { ok: false, error: message });
}

// Path traversal protection
function isSafeWorkspacePath(relPath: string): boolean {
  if (!relPath) {
    return false;
  }
  const normalized = path.normalize(relPath);
  if (normalized.startsWith("../") || normalized === "..") {
    return false;
  }
  if (normalized.includes("\0")) {
    return false;
  }
  // Allow only certain extensions
  const ext = path.extname(normalized).toLowerCase();
  if (ext && ![".md", ".json", ".txt", ".log"].includes(ext)) {
    return false;
  }
  return true;
}

// GET /api/status
async function handleStatus(res: ServerResponse) {
  const startMs = parseInt(process.env.OPENCLAW_START_MS || "0", 10) || Date.now();
  const uptime = Math.floor((Date.now() - startMs) / 1000);

  // Read agents from cron jobs to infer active agents
  const agents: Array<{ id: string; name: string; online: boolean; lastHeartbeatMs: number }> = [
    { id: "main", name: "Planner", online: true, lastHeartbeatMs: 0 },
    { id: "executor", name: "Executor", online: true, lastHeartbeatMs: 0 },
    { id: "reviewer", name: "Reviewer", online: true, lastHeartbeatMs: 0 },
  ];

  sendJson(res, 200, {
    ok: true,
    uptime,
    version: "1.0.0",
    ts: Date.now(),
    agents,
    pid: process.pid,
  });
}

// GET /api/cron
async function handleCron(res: ServerResponse) {
  const jobsPath = path.join(STATE_DIR, "cron", "jobs.json");

  if (!fs.existsSync(jobsPath)) {
    sendJson(res, 200, { jobs: [], summary: { active: 0, disabled: 0, errored: 0 } });
    return;
  }

  try {
    const raw = fs.readFileSync(jobsPath, "utf-8");
    const data = JSON.parse(raw) as { jobs?: unknown[] };
    const jobs = Array.isArray(data.jobs) ? data.jobs : Array.isArray(data) ? data : [];

    // Return simplified job info (strip sensitive fields)
    const simplified = jobs
      .map((job: unknown) => {
        if (!job || typeof job !== "object") {
          return null;
        }
        const j = job as Record<string, unknown>;
        return {
          id: j.id,
          name: j.name || j.label || j.id,
          enabled: j.enabled !== false,
          schedule: j.schedule || j.cron,
          agentId: j.agentId,
          state: {
            lastRunAtMs: (j.state as Record<string, unknown>)?.lastRunAtMs || null,
            nextRunAtMs: (j.state as Record<string, unknown>)?.nextRunAtMs || null,
          },
        };
      })
      .filter(Boolean);

    const active = simplified.filter((j) => j?.enabled !== false).length;
    const disabled = simplified.filter((j) => j?.enabled === false).length;

    sendJson(res, 200, {
      jobs: simplified,
      summary: { active, disabled, errored: 0 },
    });
  } catch (err) {
    sendError(res, 500, `Failed to read cron jobs: ${String(err)}`);
  }
}

// GET /api/workspace/:path
async function handleWorkspaceFile(res: ServerResponse, filePath: string) {
  if (!isSafeWorkspacePath(filePath)) {
    sendError(res, 400, "Invalid file path");
    return;
  }

  // Search across known workspace directories
  const workspaceDirs = [
    path.join(STATE_DIR, "workspace"),
    path.join(STATE_DIR, "workspace-executor"),
    path.join(STATE_DIR, "workspace-reviewer"),
  ];

  for (const dir of workspaceDirs) {
    const fullPath = path.join(dir, filePath);
    // Security: ensure path stays within workspace dir
    if (!fullPath.startsWith(dir)) {
      continue;
    }

    if (fs.existsSync(fullPath) && fs.statSync(fullPath).isFile()) {
      try {
        const content = fs.readFileSync(fullPath, "utf-8");
        sendJson(res, 200, { ok: true, path: filePath, content });
        return;
      } catch (err) {
        sendError(res, 500, `Failed to read file: ${String(err)}`);
        return;
      }
    }
  }

  sendError(res, 404, `File not found: ${filePath}`);
}

// GET /api/usage/today - scan today's session JSONL files
interface TokenStats {
  input: number;
  output: number;
  tokens: number;
  cost: number;
}

async function handleUsageToday(res: ServerResponse) {
  const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD
  const agentIds = ["main", "executor", "reviewer"];

  const byModel: Record<string, TokenStats> = {};
  const byAgent: Record<string, TokenStats> = {};
  const total: TokenStats = { input: 0, output: 0, tokens: 0, cost: 0 };

  // Model cost estimates per 1M tokens (USD)
  const MODEL_COSTS: Record<string, { input: number; output: number }> = {
    "gpt-5.3-codex": { input: 30.0, output: 60.0 },
    "gpt-4o": { input: 5.0, output: 15.0 },
    "qwen-plus": { input: 0.5, output: 2.0 },
    "qwen-turbo": { input: 0.3, output: 0.6 },
    default: { input: 3.0, output: 15.0 },
  };

  function getCostRate(model: string) {
    const key =
      Object.keys(MODEL_COSTS).find(
        (k) => k !== "default" && model.toLowerCase().includes(k.toLowerCase()),
      ) ?? "default";
    return MODEL_COSTS[key] ?? MODEL_COSTS.default;
  }

  const scanPromises = agentIds.map(async (agentId) => {
    const sessionDir = path.join(STATE_DIR, "agents", agentId, "sessions");
    if (!fs.existsSync(sessionDir)) {
      return;
    }

    let files: string[];
    try {
      files = fs.readdirSync(sessionDir).filter((f) => f.endsWith(".jsonl"));
    } catch {
      return;
    }

    for (const file of files) {
      // Check file modification date
      const filePath = path.join(sessionDir, file);
      try {
        const stat = fs.statSync(filePath);
        const fileDateStr = stat.mtime.toISOString().slice(0, 10);
        if (fileDateStr !== today) {
          continue;
        }
      } catch {
        continue;
      }

      // Read file line by line
      try {
        const rl = readline.createInterface({
          input: fs.createReadStream(filePath),
          crlfDelay: Infinity,
        });

        for await (const line of rl) {
          if (!line.trim()) {
            continue;
          }
          try {
            const entry = JSON.parse(line) as Record<string, unknown>;
            // Look for usage data in the entry
            const usage = entry.usage as Record<string, unknown> | undefined;
            if (!usage) {
              continue;
            }

            const inputTokens = Number(usage.input_tokens || usage.prompt_tokens || 0);
            const outputTokens = Number(usage.output_tokens || usage.completion_tokens || 0);
            const model = typeof entry.model === "string" ? entry.model : "unknown";

            if (!inputTokens && !outputTokens) {
              continue;
            }

            const rate = getCostRate(model);
            const cost = (inputTokens * rate.input + outputTokens * rate.output) / 1_000_000;

            // Accumulate by model
            if (!byModel[model]) {
              byModel[model] = { input: 0, output: 0, tokens: 0, cost: 0 };
            }
            byModel[model].input += inputTokens;
            byModel[model].output += outputTokens;
            byModel[model].tokens += inputTokens + outputTokens;
            byModel[model].cost += cost;

            // Accumulate by agent
            if (!byAgent[agentId]) {
              byAgent[agentId] = { input: 0, output: 0, tokens: 0, cost: 0 };
            }
            byAgent[agentId].input += inputTokens;
            byAgent[agentId].output += outputTokens;
            byAgent[agentId].tokens += inputTokens + outputTokens;
            byAgent[agentId].cost += cost;

            // Total
            total.input += inputTokens;
            total.output += outputTokens;
            total.tokens += inputTokens + outputTokens;
            total.cost += cost;
          } catch {
            // Skip malformed lines
          }
        }
      } catch {
        // Skip unreadable files
      }
    }
  });

  await Promise.all(scanPromises);

  sendJson(res, 200, { ok: true, date: today, byModel, byAgent, total });
}

type KairoWebApiOptions = {
  auth: ResolvedGatewayAuth;
  trustedProxies?: string[];
};

export async function handleKairoWebApiRequest(
  req: IncomingMessage,
  res: ServerResponse,
  opts: KairoWebApiOptions,
): Promise<boolean> {
  const urlRaw = req.url;
  if (!urlRaw) {
    return false;
  }

  const url = new URL(urlRaw, "http://localhost");
  const pathname = url.pathname;

  // Must match /api or /api/*
  if (pathname !== API_PREFIX && !pathname.startsWith(`${API_PREFIX}/`)) {
    return false;
  }

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    res.statusCode = 204;
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Access-Control-Allow-Methods", "GET, OPTIONS");
    res.setHeader("Access-Control-Allow-Headers", "Authorization, Content-Type");
    res.end();
    return true;
  }

  if (req.method !== "GET") {
    res.statusCode = 405;
    res.setHeader("Allow", "GET, OPTIONS");
    res.end("Method Not Allowed");
    return true;
  }

  // Auth: localhost is free, remote needs Bearer token
  const isLocal = isLocalDirectRequest(req, opts.trustedProxies ?? []);
  if (!isLocal) {
    const token = getBearerToken(req);
    const authResult = await authorizeGatewayConnect({
      auth: opts.auth,
      connectAuth: { token, password: token },
      req,
      trustedProxies: opts.trustedProxies ?? [],
    });
    if (!authResult.ok) {
      res.statusCode = 401;
      res.setHeader("WWW-Authenticate", 'Bearer realm="kairo-web-api"');
      res.setHeader("Access-Control-Allow-Origin", "*");
      res.end("Unauthorized");
      return true;
    }
  }

  const subPath = pathname.slice(API_PREFIX.length).replace(/^\/+/, "");

  if (subPath === "status") {
    await handleStatus(res);
    return true;
  }

  if (subPath === "cron") {
    await handleCron(res);
    return true;
  }

  if (subPath.startsWith("workspace/")) {
    const filePath = decodeURIComponent(subPath.slice("workspace/".length));
    await handleWorkspaceFile(res, filePath);
    return true;
  }

  if (subPath === "usage/today") {
    await handleUsageToday(res);
    return true;
  }

  sendError(res, 404, `Unknown API endpoint: /api/${subPath}`);
  return true;
}
