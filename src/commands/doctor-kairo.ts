import fs from "node:fs";
import http from "node:http";
import https from "node:https";
import os from "node:os";
import path from "node:path";
import { note } from "../terminal/note.js";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function resolveHomeDir(): string {
  return process.env.HOME ?? os.homedir();
}

function resolveStateDir(): string {
  const override =
    process.env.OPENCLAW_STATE_DIR?.trim() ||
    process.env.KAIRO_HOME?.trim() ||
    process.env.CLAWDBOT_STATE_DIR?.trim();
  if (override) {
    return override;
  }
  return path.join(resolveHomeDir(), ".openclaw");
}

function existsDir(dir: string): boolean {
  try {
    return fs.existsSync(dir) && fs.statSync(dir).isDirectory();
  } catch {
    return false;
  }
}

function existsFile(filePath: string): boolean {
  try {
    return fs.existsSync(filePath) && fs.statSync(filePath).isFile();
  } catch {
    return false;
  }
}

function fileSizeBytes(filePath: string): number {
  try {
    return fs.statSync(filePath).size;
  } catch {
    return 0;
  }
}

function readJsonFile(filePath: string): unknown {
  try {
    const raw = fs.readFileSync(filePath, "utf-8");
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

function probeUrl(url: string, timeoutMs: number): Promise<number | null> {
  return new Promise((resolve) => {
    const parsed = new URL(url);
    const lib = parsed.protocol === "https:" ? https : http;
    const options = {
      hostname: parsed.hostname,
      port: parsed.port || (parsed.protocol === "https:" ? 443 : 80),
      path: parsed.pathname || "/",
      method: "HEAD",
      timeout: timeoutMs,
    };
    const req = lib.request(options, (res) => {
      res.resume(); // consume response to free socket
      resolve(res.statusCode ?? null);
    });
    req.on("timeout", () => {
      req.destroy();
      resolve(null);
    });
    req.on("error", () => {
      resolve(null);
    });
    req.end();
  });
}

// ---------------------------------------------------------------------------
// Check 1: Feishu Token
// ---------------------------------------------------------------------------

async function checkFeishuToken(): Promise<void> {
  const stateDir = resolveStateDir();
  const tokenPath = path.join(stateDir, "feishu_user_token.json");
  const lines: string[] = [];

  if (!existsFile(tokenPath)) {
    lines.push("- FAIL: feishu_user_token.json not found.");
    lines.push(`  Expected: ${tokenPath}`);
    lines.push("  Fix: re-run Feishu OAuth flow to obtain a token.");
    note(lines.join("\n"), "Kairo: Feishu Token");
    return;
  }

  const data = readJsonFile(tokenPath) as Record<string, unknown> | null;
  if (!data || typeof data !== "object") {
    lines.push("- FAIL: feishu_user_token.json is unreadable or invalid JSON.");
    note(lines.join("\n"), "Kairo: Feishu Token");
    return;
  }

  const accessToken = data["access_token"];
  const obtainedAt = data["obtained_at"];
  const expiresIn = typeof data["expires_in"] === "number" ? data["expires_in"] : 6900;

  if (!accessToken || typeof accessToken !== "string" || accessToken.trim().length === 0) {
    lines.push("- FAIL: access_token is missing or empty in feishu_user_token.json.");
    note(lines.join("\n"), "Kairo: Feishu Token");
    return;
  }

  const obtainedAtStr = typeof obtainedAt === "string" ? obtainedAt : null;
  if (!obtainedAtStr) {
    lines.push("- WARN: obtained_at missing; cannot determine token age.");
    lines.push("  access_token exists; assuming valid.");
    note(lines.join("\n"), "Kairo: Feishu Token");
    return;
  }

  const obtainedMs = Date.parse(obtainedAtStr);
  if (Number.isNaN(obtainedMs)) {
    lines.push(`- WARN: obtained_at "${obtainedAtStr}" cannot be parsed; cannot determine expiry.`);
    lines.push("  access_token exists; assuming valid.");
    note(lines.join("\n"), "Kairo: Feishu Token");
    return;
  }

  const nowMs = Date.now();
  const ttlMs = expiresIn * 1000;
  const ageMs = nowMs - obtainedMs;
  const remainingMs = ttlMs - ageMs;
  const tenMinMs = 10 * 60 * 1000;

  if (remainingMs <= 0) {
    lines.push("- FAIL: Feishu access_token has expired.");
    lines.push(`  Obtained: ${obtainedAtStr}  TTL: ${expiresIn}s`);
    lines.push("  Fix: token will auto-refresh on next request, or run feishu-refresh-token.mjs.");
    note(lines.join("\n"), "Kairo: Feishu Token");
    return;
  }

  if (remainingMs < tenMinMs) {
    const remainingSec = Math.floor(remainingMs / 1000);
    lines.push(`- WARN: Feishu access_token expires in ${remainingSec}s (< 10 min).`);
    lines.push("  Token will auto-refresh on next request.");
    note(lines.join("\n"), "Kairo: Feishu Token");
    return;
  }

  const remainingMin = Math.floor(remainingMs / 60000);
  lines.push(`- OK: Feishu access_token valid; expires in ~${remainingMin} min.`);
  note(lines.join("\n"), "Kairo: Feishu Token");
}

// ---------------------------------------------------------------------------
// Check 2: Hub Directory Integrity
// ---------------------------------------------------------------------------

async function checkHubDirectories(): Promise<void> {
  const stateDir = resolveStateDir();
  const lines: string[] = [];

  const workspaceDirs = [
    { path: path.join(stateDir, "workspace"), label: "workspace (Planner)" },
    { path: path.join(stateDir, "workspace-executor"), label: "workspace-executor (Executor)" },
    { path: path.join(stateDir, "workspace-reviewer"), label: "workspace-reviewer (Reviewer)" },
  ];

  // Also check the hub root under workspace
  const hubRoot = path.join(stateDir, "workspace", "automation", "assistant_hub");
  const hubDirs = [
    { path: path.join(hubRoot, "00_inbox"), label: "hub/00_inbox" },
    { path: path.join(hubRoot, "02_work"), label: "hub/02_work" },
    { path: path.join(hubRoot, "03_life"), label: "hub/03_life" },
    { path: path.join(hubRoot, "04_knowledge"), label: "hub/04_knowledge" },
    { path: path.join(hubRoot, "05_meta"), label: "hub/05_meta" },
  ];

  const mainWorkspaceExists = existsDir(workspaceDirs[0].path);

  if (!mainWorkspaceExists) {
    lines.push(`- FAIL: Main workspace missing (${workspaceDirs[0].path}).`);
    lines.push("  The Planner agent cannot function without a workspace directory.");
    note(lines.join("\n"), "Kairo: Hub Directories");
    return;
  }

  const missingWorkspaces: string[] = [];
  for (const { path: dirPath, label } of workspaceDirs) {
    if (!existsDir(dirPath)) {
      missingWorkspaces.push(label);
    }
  }

  const missingHubDirs: string[] = [];
  for (const { path: dirPath, label } of hubDirs) {
    if (!existsDir(dirPath)) {
      missingHubDirs.push(label);
    }
  }

  if (missingWorkspaces.length > 0) {
    for (const label of missingWorkspaces) {
      lines.push(`- WARN: Missing agent workspace: ${label}`);
    }
  }

  if (missingHubDirs.length > 0) {
    for (const label of missingHubDirs) {
      lines.push(`- WARN: Missing hub directory: ${label}`);
    }
    lines.push("  Fix: run agent task to scaffold hub directories.");
  }

  if (missingWorkspaces.length === 0 && missingHubDirs.length === 0) {
    lines.push(`- OK: All workspace and hub directories present.`);
    lines.push(`  Hub root: ${hubRoot}`);
  }

  note(lines.join("\n"), "Kairo: Hub Directories");
}

// ---------------------------------------------------------------------------
// Check 3: Bootstrap Cron Jobs
// ---------------------------------------------------------------------------

async function checkBootstrapCronJobs(): Promise<void> {
  const stateDir = resolveStateDir();
  const jobsPath = path.join(stateDir, "cron", "jobs.json");
  const lines: string[] = [];

  const EXPECTED_JOB_NAMES = ["每日晨報", "月度記憶壓縮", "佇列歸檔"] as const;

  if (!existsFile(jobsPath)) {
    lines.push(`- FAIL: cron/jobs.json not found (${jobsPath}).`);
    lines.push("  Fix: start the gateway to auto-create bootstrap jobs.");
    note(lines.join("\n"), "Kairo: Bootstrap Cron Jobs");
    return;
  }

  const data = readJsonFile(jobsPath) as Record<string, unknown> | null;
  if (!data || typeof data !== "object") {
    lines.push("- FAIL: cron/jobs.json is unreadable or invalid JSON.");
    note(lines.join("\n"), "Kairo: Bootstrap Cron Jobs");
    return;
  }

  // jobs.json has shape { version, jobs: [...] } or { version, jobs: {...} }
  const rawJobs = data["jobs"];
  let jobNames: string[] = [];
  if (Array.isArray(rawJobs)) {
    jobNames = rawJobs
      .filter((j): j is Record<string, unknown> => typeof j === "object" && j !== null)
      .map((j) => (j["name"] as string) ?? "");
  } else if (rawJobs && typeof rawJobs === "object") {
    jobNames = Object.values(rawJobs as Record<string, unknown>)
      .filter((j): j is Record<string, unknown> => typeof j === "object" && j !== null)
      .map((j) => (j["name"] as string) ?? "");
  }

  const missing: string[] = [];
  for (const expectedName of EXPECTED_JOB_NAMES) {
    if (!jobNames.includes(expectedName)) {
      missing.push(expectedName);
    }
  }

  if (missing.length === 0) {
    lines.push(`- OK: All bootstrap cron jobs present (${EXPECTED_JOB_NAMES.join(", ")}).`);
    lines.push(`  Total jobs registered: ${jobNames.length}`);
  } else if (missing.length < EXPECTED_JOB_NAMES.length) {
    for (const name of missing) {
      lines.push(`- WARN: Bootstrap job missing: "${name}"`);
    }
    lines.push("  Fix: restart the gateway to auto-create missing bootstrap jobs.");
  } else {
    lines.push("- FAIL: All bootstrap cron jobs are missing.");
    lines.push("  Fix: restart the gateway to auto-create bootstrap jobs.");
  }

  note(lines.join("\n"), "Kairo: Bootstrap Cron Jobs");
}

// ---------------------------------------------------------------------------
// Check 4: SOUL.md Files
// ---------------------------------------------------------------------------

async function checkSoulMdFiles(): Promise<void> {
  const stateDir = resolveStateDir();
  const lines: string[] = [];

  const MIN_SIZE_BYTES = 100;

  const soulPaths = [
    { path: path.join(stateDir, "workspace", "SOUL.md"), label: "workspace (Planner)" },
    {
      path: path.join(stateDir, "workspace-executor", "SOUL.md"),
      label: "workspace-executor (Executor)",
    },
    {
      path: path.join(stateDir, "workspace-reviewer", "SOUL.md"),
      label: "workspace-reviewer (Reviewer)",
    },
  ];

  const results = soulPaths.map(({ path: p, label }) => {
    const exists = existsFile(p);
    const size = exists ? fileSizeBytes(p) : 0;
    const nonEmpty = size >= MIN_SIZE_BYTES;
    return { path: p, label, exists, size, nonEmpty };
  });

  const allOk = results.every((r) => r.exists && r.nonEmpty);
  const anyOk = results.some((r) => r.exists);
  const noneOk = !anyOk;

  if (allOk) {
    lines.push("- OK: SOUL.md present and non-empty in all 3 agent workspaces.");
    for (const r of results) {
      lines.push(`  ${r.label}: ${r.size} bytes`);
    }
  } else if (noneOk) {
    lines.push("- FAIL: SOUL.md missing from all agent workspaces.");
    lines.push("  Fix: create SOUL.md for each agent (Planner/Executor/Reviewer).");
    for (const r of results) {
      lines.push(`  Missing: ${r.path}`);
    }
  } else {
    for (const r of results) {
      if (!r.exists) {
        lines.push(`- WARN: SOUL.md missing for ${r.label} (${r.path})`);
      } else if (!r.nonEmpty) {
        lines.push(
          `- WARN: SOUL.md for ${r.label} is too small (${r.size} bytes < ${MIN_SIZE_BYTES} threshold).`,
        );
      } else {
        lines.push(`- OK: SOUL.md present for ${r.label} (${r.size} bytes)`);
      }
    }
  }

  note(lines.join("\n"), "Kairo: SOUL.md Files");
}

// ---------------------------------------------------------------------------
// Check 5: Primary Model Reachable
// ---------------------------------------------------------------------------

async function checkPrimaryModelReachable(): Promise<void> {
  const stateDir = resolveStateDir();
  const configPath = path.join(stateDir, "openclaw.json");
  const lines: string[] = [];

  if (!existsFile(configPath)) {
    lines.push(`- WARN: openclaw.json not found (${configPath}); cannot check primary model.`);
    note(lines.join("\n"), "Kairo: Primary Model");
    return;
  }

  const data = readJsonFile(configPath) as Record<string, unknown> | null;
  if (!data || typeof data !== "object") {
    lines.push("- WARN: openclaw.json is unreadable or invalid JSON.");
    note(lines.join("\n"), "Kairo: Primary Model");
    return;
  }

  const primaryRef = (
    (data["agents"] as Record<string, unknown> | null)?.["defaults"] as Record<
      string,
      unknown
    > | null
  )?.["model"] as Record<string, unknown> | null;

  const primary = typeof primaryRef?.["primary"] === "string" ? primaryRef["primary"] : null;

  if (!primary) {
    lines.push("- WARN: agents.defaults.model.primary not set in openclaw.json.");
    note(lines.join("\n"), "Kairo: Primary Model");
    return;
  }

  const providerName = primary.includes("/") ? primary.split("/")[0] : primary;
  const modelName = primary.includes("/") ? primary.split("/").slice(1).join("/") : primary;

  const providers = (data["models"] as Record<string, unknown> | null)?.["providers"] as
    | Record<string, unknown>
    | null
    | undefined;

  const providerConfig = providers?.[providerName] as Record<string, unknown> | null | undefined;
  const baseUrl =
    typeof providerConfig?.["baseUrl"] === "string" ? providerConfig["baseUrl"] : null;

  if (!baseUrl) {
    lines.push(`- WARN: No baseUrl configured for provider "${providerName}".`);
    lines.push(`  Primary model: ${primary}`);
    lines.push(`  Cannot probe reachability without a baseUrl.`);
    note(lines.join("\n"), "Kairo: Primary Model");
    return;
  }

  lines.push(`  Primary model: ${primary} (${providerName} at ${baseUrl})`);

  let statusCode: number | null = null;
  try {
    statusCode = await probeUrl(baseUrl, 5000);
  } catch {
    statusCode = null;
  }

  if (statusCode === null) {
    lines.unshift(`- FAIL: Primary model provider unreachable (timeout/connection refused).`);
    lines.push(`  Fix: check network, or ensure "${providerName}" server is running.`);
    lines.push(`  Model: ${modelName}`);
  } else if (statusCode >= 500) {
    lines.unshift(`- WARN: Primary model provider returned HTTP ${statusCode} (server error).`);
    lines.push(`  Provider may be degraded; check provider logs.`);
  } else {
    lines.unshift(`- OK: Primary model provider reachable (HTTP ${statusCode}).`);
  }

  note(lines.join("\n"), "Kairo: Primary Model");
}

// ---------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------

export async function runKairoChecks(): Promise<void> {
  await checkFeishuToken();
  await checkHubDirectories();
  await checkBootstrapCronJobs();
  await checkSoulMdFiles();
  await checkPrimaryModelReachable();
}
