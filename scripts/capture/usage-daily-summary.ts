#!/usr/bin/env -S node --import tsx
/**
 * usage-daily-summary.ts
 * Scans session JSONL transcripts for today and produces a token usage summary
 * broken down by model and agent. Outputs formatted text to stdout.
 *
 * Run via cron (daily, 22:00) or on demand.
 */

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import readline from "node:readline";

// ── Config ────────────────────────────────────────────────────────────────────

const STATE_DIR =
  process.env.OPENCLAW_STATE_DIR ??
  process.env.KAIRO_HOME ??
  process.env.CLAWDBOT_STATE_DIR ??
  path.join(os.homedir(), ".openclaw");

const AGENT_IDS = ["main", "executor", "reviewer"];

// Rough cost estimates per 1M tokens (USD). The session transcripts often
// contain actual cost data from the API, but we keep these as fallbacks.
const MODEL_COST_FALLBACK: Record<string, { input: number; output: number; cacheRead: number }> = {
  "gpt-5.3-codex": { input: 30.0, output: 60.0, cacheRead: 0.3 },
  "gpt-4o": { input: 5.0, output: 15.0, cacheRead: 0.05 },
  "gpt-4": { input: 30.0, output: 60.0, cacheRead: 0.3 },
  "gpt-4-turbo": { input: 10.0, output: 30.0, cacheRead: 0.1 },
  "qwen-plus": { input: 0.5, output: 2.0, cacheRead: 0.05 },
  "qwen-turbo": { input: 0.3, output: 0.6, cacheRead: 0.03 },
  "qwen-max": { input: 2.0, output: 6.0, cacheRead: 0.1 },
  "claude-3-5": { input: 3.0, output: 15.0, cacheRead: 0.03 },
  "claude-3": { input: 3.0, output: 15.0, cacheRead: 0.03 },
  default: { input: 3.0, output: 15.0, cacheRead: 0.03 },
};

// ── Types ─────────────────────────────────────────────────────────────────────

interface UsageEntry {
  model: string;
  provider: string;
  agentId: string;
  inputTokens: number;
  outputTokens: number;
  cacheReadTokens: number;
  cacheWriteTokens: number;
  totalTokens: number;
  costTotal?: number; // from API if available
}

interface ModelStats {
  provider: string;
  model: string;
  inputTokens: number;
  outputTokens: number;
  cacheReadTokens: number;
  cacheWriteTokens: number;
  totalTokens: number;
  calls: number;
  costTotal: number;
  hasDirectCost: boolean; // whether cost came from API data
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function toFinite(value: unknown): number | undefined {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    return undefined;
  }
  return value;
}

function getFallbackCost(
  model: string,
  inputTokens: number,
  outputTokens: number,
  cacheReadTokens: number,
): number {
  const key =
    Object.keys(MODEL_COST_FALLBACK).find(
      (k) => k !== "default" && model.toLowerCase().includes(k.toLowerCase()),
    ) ?? "default";
  const rates = MODEL_COST_FALLBACK[key];
  return (
    (inputTokens * rates.input + outputTokens * rates.output + cacheReadTokens * rates.cacheRead) /
    1_000_000
  );
}

function formatNumber(n: number): string {
  if (n >= 1_000_000) {
    return `${(n / 1_000_000).toFixed(2)}M`;
  }
  if (n >= 1_000) {
    return `${(n / 1_000).toFixed(1)}k`;
  }
  return String(Math.round(n));
}

function formatCost(usd: number): string {
  if (usd >= 1) {
    return `$${usd.toFixed(2)}`;
  }
  if (usd >= 0.01) {
    return `$${usd.toFixed(3)}`;
  }
  return `$${usd.toFixed(5)}`;
}

// ── Parsing ───────────────────────────────────────────────────────────────────

async function parseSessionFile(filePath: string, agentId: string): Promise<UsageEntry[]> {
  const entries: UsageEntry[] = [];

  const fileStream = fs.createReadStream(filePath, { encoding: "utf-8" });
  const rl = readline.createInterface({ input: fileStream, crlfDelay: Infinity });

  for await (const line of rl) {
    const trimmed = line.trim();
    if (!trimmed) {
      continue;
    }

    let parsed: Record<string, unknown>;
    try {
      parsed = JSON.parse(trimmed) as Record<string, unknown>;
    } catch {
      continue;
    }

    // Session transcripts have usage inside message objects (assistant turns)
    const msg = parsed["message"] as Record<string, unknown> | undefined;
    if (!msg || typeof msg !== "object") {
      continue;
    }

    const role = msg["role"];
    if (role !== "assistant") {
      continue;
    } // only count assistant turns (LLM responses)

    const rawUsage = (msg["usage"] ?? parsed["usage"]) as Record<string, unknown> | undefined;
    if (!rawUsage || typeof rawUsage !== "object") {
      continue;
    }

    // Normalize token counts (support both normalized and raw key forms)
    const inputTokens =
      toFinite(rawUsage["input"]) ??
      toFinite(rawUsage["inputTokens"]) ??
      toFinite(rawUsage["input_tokens"]) ??
      toFinite(rawUsage["prompt_tokens"]) ??
      0;
    const outputTokens =
      toFinite(rawUsage["output"]) ??
      toFinite(rawUsage["outputTokens"]) ??
      toFinite(rawUsage["output_tokens"]) ??
      toFinite(rawUsage["completion_tokens"]) ??
      0;
    const cacheReadTokens =
      toFinite(rawUsage["cacheRead"]) ??
      toFinite(rawUsage["cache_read"]) ??
      toFinite(rawUsage["cache_read_input_tokens"]) ??
      0;
    const cacheWriteTokens =
      toFinite(rawUsage["cacheWrite"]) ??
      toFinite(rawUsage["cache_write"]) ??
      toFinite(rawUsage["cache_creation_input_tokens"]) ??
      0;
    const totalTokens =
      toFinite(rawUsage["totalTokens"]) ??
      toFinite(rawUsage["total_tokens"]) ??
      toFinite(rawUsage["total"]) ??
      inputTokens + outputTokens + cacheReadTokens;

    if (inputTokens === 0 && outputTokens === 0 && totalTokens === 0) {
      continue;
    }

    // Try to extract cost directly from API data (most accurate)
    const costRaw = rawUsage["cost"] as Record<string, unknown> | undefined;
    const costTotal = toFinite(costRaw?.["total"]) ?? toFinite(rawUsage["costTotal"]) ?? undefined;

    const model =
      (typeof msg["model"] === "string" ? msg["model"] : undefined) ??
      (typeof parsed["model"] === "string" ? parsed["model"] : undefined) ??
      "unknown";
    const provider =
      (typeof msg["provider"] === "string" ? msg["provider"] : undefined) ??
      (typeof parsed["provider"] === "string" ? parsed["provider"] : undefined) ??
      "unknown";

    entries.push({
      model,
      provider,
      agentId,
      inputTokens,
      outputTokens,
      cacheReadTokens,
      cacheWriteTokens,
      totalTokens,
      costTotal,
    });
  }

  return entries;
}

// ── Main ──────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD
  const tz = "Asia/Shanghai";
  const todayDisplay = new Date().toLocaleDateString("zh-TW", {
    timeZone: tz,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  });

  // Start of today (Asia/Shanghai midnight) in ms
  const startOfDayMs = new Date(today + "T00:00:00+08:00").getTime();

  const allEntries: UsageEntry[] = [];
  let filesScanned = 0;
  let filesSkipped = 0;

  for (const agentId of AGENT_IDS) {
    const sessionsDir = path.join(STATE_DIR, "agents", agentId, "sessions");
    if (!fs.existsSync(sessionsDir)) {
      continue;
    }

    let files: string[];
    try {
      files = fs.readdirSync(sessionsDir).filter((f) => f.endsWith(".jsonl"));
    } catch {
      continue;
    }

    for (const file of files) {
      const filePath = path.join(sessionsDir, file);
      let stat: fs.Stats;
      try {
        stat = fs.statSync(filePath);
      } catch {
        continue;
      }

      // Only scan files modified today
      if (stat.mtimeMs < startOfDayMs) {
        filesSkipped++;
        continue;
      }

      filesScanned++;
      try {
        const entries = await parseSessionFile(filePath, agentId);
        allEntries.push(...entries);
      } catch (err) {
        console.error(`[usage-daily-summary] Error parsing ${filePath}:`, err);
      }
    }
  }

  // ── Aggregate by model ────────────────────────────────────────────────────

  // Key: "provider/model"
  const byModel = new Map<string, ModelStats>();

  for (const entry of allEntries) {
    const key = `${entry.provider}/${entry.model}`;
    if (!byModel.has(key)) {
      byModel.set(key, {
        provider: entry.provider,
        model: entry.model,
        inputTokens: 0,
        outputTokens: 0,
        cacheReadTokens: 0,
        cacheWriteTokens: 0,
        totalTokens: 0,
        calls: 0,
        costTotal: 0,
        hasDirectCost: false,
      });
    }
    const s = byModel.get(key)!;
    s.inputTokens += entry.inputTokens;
    s.outputTokens += entry.outputTokens;
    s.cacheReadTokens += entry.cacheReadTokens;
    s.cacheWriteTokens += entry.cacheWriteTokens;
    s.totalTokens += entry.totalTokens;
    s.calls += 1;
    if (entry.costTotal !== undefined) {
      s.costTotal += entry.costTotal;
      s.hasDirectCost = true;
    } else {
      // Fallback cost estimation
      s.costTotal += getFallbackCost(
        entry.model,
        entry.inputTokens,
        entry.outputTokens,
        entry.cacheReadTokens,
      );
    }
  }

  // ── Aggregate by agent ────────────────────────────────────────────────────

  const byAgent = new Map<string, { tokens: number; cost: number; calls: number }>();
  for (const entry of allEntries) {
    if (!byAgent.has(entry.agentId)) {
      byAgent.set(entry.agentId, { tokens: 0, cost: 0, calls: 0 });
    }
    const s = byAgent.get(entry.agentId)!;
    s.tokens += entry.totalTokens;
    s.calls += 1;
    if (entry.costTotal !== undefined) {
      s.cost += entry.costTotal;
    } else {
      s.cost += getFallbackCost(
        entry.model,
        entry.inputTokens,
        entry.outputTokens,
        entry.cacheReadTokens,
      );
    }
  }

  // ── Format output ─────────────────────────────────────────────────────────

  if (allEntries.length === 0) {
    const output = [
      `📊 *${todayDisplay} 用量摘要*`,
      ``,
      `暫無數據（今日無 LLM 調用記錄）`,
      `掃描: ${filesScanned} 個活躍 session 檔案，略過 ${filesSkipped} 個舊檔案`,
    ].join("\n");
    console.log(output);
    return;
  }

  const lines: string[] = [];
  lines.push(`📊 *${todayDisplay} Token 用量日報*`);
  lines.push(``);

  // Sort by total tokens descending
  const sortedModels = [...byModel.values()].toSorted((a, b) => b.totalTokens - a.totalTokens);

  lines.push(`🤖 *按模型分類：*`);
  for (const s of sortedModels) {
    const label = s.model === "unknown" ? s.provider : `${s.provider}/${s.model}`;
    const cacheNote =
      s.cacheReadTokens > 0 ? ` (+${formatNumber(s.cacheReadTokens)} cache命中)` : "";
    const costNote = s.hasDirectCost ? "" : " (估)";
    lines.push(
      `  • *${label}*: in ${formatNumber(s.inputTokens)} + out ${formatNumber(s.outputTokens)}${cacheNote} | ${s.calls} 次 | ${formatCost(s.costTotal)}${costNote}`,
    );
  }

  if (byAgent.size > 1) {
    lines.push(``);
    lines.push(`🎭 *按 Agent 分類：*`);
    for (const [agentId, s] of [...byAgent.entries()].toSorted(
      (a, b) => b[1].tokens - a[1].tokens,
    )) {
      lines.push(
        `  • *${agentId}*: ${formatNumber(s.tokens)} tokens | ${s.calls} 次調用 | ${formatCost(s.cost)}`,
      );
    }
  }

  const grandInputTokens = [...byModel.values()].reduce((acc, s) => acc + s.inputTokens, 0);
  const grandOutputTokens = [...byModel.values()].reduce((acc, s) => acc + s.outputTokens, 0);
  const grandCacheRead = [...byModel.values()].reduce((acc, s) => acc + s.cacheReadTokens, 0);
  const grandTotal = [...byModel.values()].reduce((acc, s) => acc + s.totalTokens, 0);
  const grandCost = [...byModel.values()].reduce((acc, s) => acc + s.costTotal, 0);
  const grandCalls = [...byModel.values()].reduce((acc, s) => acc + s.calls, 0);

  lines.push(``);
  lines.push(`📈 *今日合計：*`);
  lines.push(
    `  in ${formatNumber(grandInputTokens)} + out ${formatNumber(grandOutputTokens)} + cache ${formatNumber(grandCacheRead)} = ${formatNumber(grandTotal)} tokens`,
  );
  lines.push(`  共 ${grandCalls} 次 LLM 調用 | 總費用 ≈ ${formatCost(grandCost)}`);
  lines.push(``);
  lines.push(`_掃描 ${filesScanned} 個 session 檔案_`);

  console.log(lines.join("\n"));
}

main().catch((err) => {
  console.error("[usage-daily-summary] Fatal error:", err);
  process.exit(1);
});
