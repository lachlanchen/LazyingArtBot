#!/usr/bin/env -S node --import tsx
import { spawnSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { envBool, initHub, readJsonl, writeJsonl, writeText } from "./_utils.js";

type PriorityLabel = "P0" | "P1" | "P2" | "P3";

type NotebookLmRequest = {
  id?: string;
  created_at?: string;
  updated_at?: string;
  status?: "queued" | "running" | "done" | "failed";
  source?: string;
  question?: string;
  title?: string;
  priority?: PriorityLabel | null;
  tags?: string[];
  context?: string[];
  push?: boolean;
  attempts?: number;
  result_id?: string;
  last_error?: string | null;
};

type NotebookLmSource = {
  title?: string;
  url?: string;
  note?: string;
};

type NotebookLmToolOutput = {
  summary: string;
  key_points: string[];
  action_items: string[];
  sources: NotebookLmSource[];
  confidence: number | null;
  raw_text: string | null;
};

type NotebookLmResult = {
  result_id: string;
  request_id: string;
  created_at: string;
  title: string;
  summary: string;
  key_points: string[];
  action_items: string[];
  sources: NotebookLmSource[];
  confidence: number | null;
  raw_text: string | null;
  note_path: string;
  tool: {
    cmd: string;
    duration_ms: number;
    attempts: number;
  };
};

type ToolRunSuccess = {
  ok: true;
  output: NotebookLmToolOutput;
  durationMs: number;
};

type ToolRunFailure = {
  ok: false;
  error: string;
  durationMs: number;
};

type ToolRunResult = ToolRunSuccess | ToolRunFailure;

type PushRun = {
  mode: string;
  pushed: 0 | 1;
  error: string | null;
};

function normalizePriority(input: string | null | undefined): PriorityLabel | null {
  if (!input) {
    return null;
  }
  const hit = input.toUpperCase().match(/\bP([0-3])\b/);
  if (!hit?.[1]) {
    return null;
  }
  return `P${hit[1]}` as PriorityLabel;
}

function parseIntEnv(name: string, fallback: number): number {
  const raw = process.env[name];
  if (!raw) {
    return fallback;
  }
  const n = Number.parseInt(raw, 10);
  if (!Number.isFinite(n) || n <= 0) {
    return fallback;
  }
  return n;
}

function normalizeStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }
  const out = value.map((item) => (typeof item === "string" ? item.trim() : "")).filter(Boolean);
  return Array.from(new Set(out));
}

function normalizeSources(value: unknown): NotebookLmSource[] {
  if (!Array.isArray(value)) {
    return [];
  }
  const out: NotebookLmSource[] = [];
  for (const row of value) {
    if (!row || typeof row !== "object") {
      continue;
    }
    const rec = row as Record<string, unknown>;
    const title = typeof rec.title === "string" ? rec.title.trim() : "";
    const url = typeof rec.url === "string" ? rec.url.trim() : "";
    const note = typeof rec.note === "string" ? rec.note.trim() : "";
    if (!title && !url && !note) {
      continue;
    }
    out.push({
      title: title || undefined,
      url: url || undefined,
      note: note || undefined,
    });
  }
  return out;
}

function normalizeConfidence(value: unknown): number | null {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    return null;
  }
  if (value < 0) {
    return 0;
  }
  if (value > 1) {
    return 1;
  }
  return Number(value.toFixed(2));
}

function normalizeToolOutput(input: unknown): NotebookLmToolOutput {
  if (!input || typeof input !== "object") {
    return {
      summary: "NotebookLM returned empty output.",
      key_points: [],
      action_items: [],
      sources: [],
      confidence: null,
      raw_text: null,
    };
  }

  const raw = input as Record<string, unknown>;
  const summary =
    typeof raw.summary === "string" && raw.summary.trim()
      ? raw.summary.trim()
      : typeof raw.raw_text === "string" && raw.raw_text.trim()
        ? (raw.raw_text.trim().split(/\r?\n/)[0] ?? "NotebookLM completed.")
        : "NotebookLM completed.";

  const rawText =
    typeof raw.raw_text === "string" && raw.raw_text.trim() ? raw.raw_text.trim() : null;

  return {
    summary,
    key_points: normalizeStringArray(raw.key_points),
    action_items: normalizeStringArray(raw.action_items),
    sources: normalizeSources(raw.sources),
    confidence: normalizeConfidence(raw.confidence),
    raw_text: rawText,
  };
}

function runToolCommand(params: {
  command: string;
  timeoutMs: number;
  payload: Record<string, unknown>;
}): ToolRunResult {
  const startedAt = Date.now();
  let run: ReturnType<typeof spawnSync>;
  try {
    run = spawnSync("bash", ["-lc", params.command], {
      encoding: "utf8",
      env: process.env,
      input: `${JSON.stringify(params.payload)}\n`,
      timeout: params.timeoutMs,
      maxBuffer: 8 * 1024 * 1024,
    });
  } catch (err) {
    return {
      ok: false,
      error: err instanceof Error ? err.message : String(err),
      durationMs: Date.now() - startedAt,
    };
  }

  const durationMs = Date.now() - startedAt;
  if (run.error) {
    const code = String((run.error as { code?: unknown }).code ?? "");
    if (code === "ETIMEDOUT") {
      return {
        ok: false,
        error: `tool_timeout_${params.timeoutMs}ms`,
        durationMs,
      };
    }
    return {
      ok: false,
      error: run.error.message,
      durationMs,
    };
  }

  if (run.status !== 0) {
    const stderr = (run.stderr ?? "").trim();
    const stdout = (run.stdout ?? "").trim();
    return {
      ok: false,
      error: stderr || stdout || `tool_exit_${run.status}`,
      durationMs,
    };
  }

  const stdout = (run.stdout ?? "").trim();
  if (!stdout) {
    return {
      ok: false,
      error: "tool_empty_stdout",
      durationMs,
    };
  }

  try {
    const parsed = JSON.parse(stdout);
    return {
      ok: true,
      output: normalizeToolOutput(parsed),
      durationMs,
    };
  } catch {
    return {
      ok: true,
      output: normalizeToolOutput({ summary: stdout, raw_text: stdout }),
      durationMs,
    };
  }
}

function nowLocalDate(now = new Date()): string {
  const formatter = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Shanghai",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  });
  return formatter.format(now);
}

function withNewline(value: string): string {
  return value.endsWith("\n") ? value : `${value}\n`;
}

function escapeInline(value: string): string {
  return value.replace(/\|/g, "\\|").trim();
}

function slugify(input: string): string {
  const lowered = input.toLowerCase();
  const replaced = lowered.replace(/[^a-z0-9]+/g, "_").replace(/^_+|_+$/g, "");
  return (replaced || "note").slice(0, 36);
}

function runOpenclawMessageSend(params: {
  pushChannel: string;
  pushTo: string;
  text: string;
  pushAccountId?: string;
  pushDryRun: boolean;
}) {
  const cliBin = (process.env.CAPTURE_NOTEBOOKLM_PUSH_CLI_BIN ?? "openclaw").trim() || "openclaw";
  const sendArgs = [
    "message",
    "send",
    "--channel",
    params.pushChannel,
    "--target",
    params.pushTo,
    "--message",
    params.text,
  ];
  if (params.pushAccountId) {
    sendArgs.push("--account", params.pushAccountId);
  }
  if (params.pushDryRun) {
    sendArgs.push("--dry-run");
  }

  const env = process.env;
  const runDirect = () =>
    spawnSync(cliBin, sendArgs, {
      encoding: "utf8",
      env,
    });
  const runViaNode = (entryPath: string) =>
    spawnSync(process.execPath, [entryPath, ...sendArgs], {
      encoding: "utf8",
      env,
    });

  const direct = runDirect();
  if (!direct.error) {
    return direct;
  }
  const code = String((direct.error as { code?: unknown }).code ?? "");
  if (code !== "ENOENT") {
    return direct;
  }

  const repoCli = fileURLToPath(new URL("../../openclaw.mjs", import.meta.url));
  return runViaNode(repoCli);
}

function buildPushText(params: {
  title: string;
  summary: string;
  keyPoints: string[];
  priority: PriorityLabel | null;
  requestId: string;
}): string {
  const lines: string[] = [];
  lines.push("📚 NotebookLM 已完成");
  lines.push(`主題：${params.title}`);
  lines.push(`優先級：${params.priority ?? "P2"}`);
  lines.push(`摘要：${params.summary}`);
  if (params.keyPoints.length > 0) {
    lines.push("重點：");
    for (const point of params.keyPoints.slice(0, 3)) {
      lines.push(`• ${point}`);
    }
  }
  lines.push(`編號：${params.requestId}`);
  return lines.join("\n");
}

function buildReferenceMarkdown(params: {
  requestId: string;
  title: string;
  question: string;
  source: string;
  priority: PriorityLabel | null;
  tags: string[];
  createdAt: string;
  summary: string;
  keyPoints: string[];
  actionItems: string[];
  sources: NotebookLmSource[];
  confidence: number | null;
  rawText: string | null;
  command: string;
  attempts: number;
}): string {
  const tags = Array.from(new Set(["notebooklm", "secretary", "research", ...params.tags]));
  const lines: string[] = [];
  lines.push("---");
  lines.push(`id: ${params.requestId}`);
  lines.push("type: reference");
  lines.push(`title: ${JSON.stringify(params.title)}`);
  lines.push(`created: ${params.createdAt}`);
  lines.push("source: notebooklm");
  lines.push(`priority: ${params.priority ?? "null"}`);
  lines.push(`tags: [${tags.map((tag) => JSON.stringify(tag)).join(", ")}]`);
  lines.push("convert_to_task: false");
  lines.push("long_term_memory: true");
  lines.push("calendar_entry: false");
  lines.push("stage: done");
  lines.push(`q_status: ${params.confidence !== null ? "answered" : "unknown"}`);
  lines.push(`confidence: ${(params.confidence ?? 0.7).toFixed(2)}`);
  lines.push("---");
  lines.push("");
  lines.push("## 問題");
  lines.push(params.question);
  lines.push("");
  lines.push("## 摘要");
  lines.push(params.summary);
  lines.push("");
  lines.push("## 重點");
  if (params.keyPoints.length === 0) {
    lines.push("- (none)");
  } else {
    for (const point of params.keyPoints) {
      lines.push(`- ${point}`);
    }
  }
  lines.push("");
  lines.push("## 建議行動");
  if (params.actionItems.length === 0) {
    lines.push("- (none)");
  } else {
    for (const item of params.actionItems) {
      lines.push(`- ${item}`);
    }
  }
  lines.push("");
  lines.push("## 來源");
  if (params.sources.length === 0) {
    lines.push("- (none)");
  } else {
    for (const source of params.sources) {
      const title = source.title?.trim() || "(untitled)";
      if (source.url) {
        const notePart = source.note?.trim() ? ` — ${source.note.trim()}` : "";
        lines.push(`- [${title}](${source.url})${notePart}`);
      } else if (source.note) {
        lines.push(`- ${title} — ${source.note}`);
      } else {
        lines.push(`- ${title}`);
      }
    }
  }
  if (params.rawText) {
    lines.push("");
    lines.push("## Tool Raw Output");
    lines.push("```text");
    lines.push(params.rawText);
    lines.push("```");
  }
  lines.push("");
  lines.push("## Trace");
  lines.push(`- request_id: ${params.requestId}`);
  lines.push(`- source: ${params.source}`);
  lines.push(`- command: ${params.command}`);
  lines.push(`- attempts: ${params.attempts}`);
  lines.push("");
  return withNewline(lines.join("\n"));
}

function clampPriority(input: PriorityLabel | null | undefined): PriorityLabel | null {
  if (!input) {
    return null;
  }
  return normalizePriority(input) ?? null;
}

async function main() {
  const toolCommand = (process.env.CAPTURE_NOTEBOOKLM_TOOL_CMD ?? "").trim();
  if (!toolCommand) {
    throw new Error("missing CAPTURE_NOTEBOOKLM_TOOL_CMD");
  }

  const maxPerRun = parseIntEnv("CAPTURE_NOTEBOOKLM_MAX_PER_RUN", 2);
  const timeoutMs = parseIntEnv("CAPTURE_NOTEBOOKLM_TOOL_TIMEOUT_MS", 180_000);
  const maxAttemptsPerRequest = parseIntEnv("CAPTURE_NOTEBOOKLM_TOOL_MAX_ATTEMPTS", 2);
  const retryFailed = envBool("CAPTURE_NOTEBOOKLM_RETRY_FAILED", false);

  const pushEnabled = envBool("CAPTURE_NOTEBOOKLM_PUSH_ENABLED", false);
  const pushDryRun = envBool("CAPTURE_NOTEBOOKLM_PUSH_DRY_RUN", true);
  const pushDryRunCli = envBool("CAPTURE_NOTEBOOKLM_PUSH_DRY_RUN_CLI", false);
  const pushChannel =
    (process.env.CAPTURE_NOTEBOOKLM_PUSH_CHANNEL ?? "telegram").trim() || "telegram";
  const pushTo = (process.env.CAPTURE_NOTEBOOKLM_PUSH_TO ?? "").trim();
  const pushAccountId = (process.env.CAPTURE_NOTEBOOKLM_PUSH_ACCOUNT_ID ?? "").trim() || undefined;

  const now = new Date();
  const nowIso = now.toISOString();
  const today = nowLocalDate(now);
  const paths = await initHub();

  const queuePath = path.join(paths.meta, "notebooklm_requests.jsonl");
  const resultsPath = path.join(paths.meta, "notebooklm_results.jsonl");
  const reportPath = path.join(paths.meta, "notebooklm_worker_results.md");
  const pushPreviewPath = path.join(paths.meta, "notebooklm_push_preview.md");
  const pushResultPath = path.join(paths.meta, "notebooklm_push_results.md");

  const queue = await readJsonl<NotebookLmRequest>(queuePath);
  const existingResults = await readJsonl<NotebookLmResult>(resultsPath);
  const pendingIndexes = queue
    .map((entry, index) => ({ entry, index }))
    .filter(({ entry }) => {
      const status = entry.status ?? "queued";
      if (status === "done" || status === "running") {
        return false;
      }
      if (status === "failed" && !retryFailed) {
        return false;
      }
      return true;
    })
    .sort((a, b) =>
      String(a.entry.created_at ?? "").localeCompare(String(b.entry.created_at ?? "")),
    )
    .slice(0, maxPerRun);

  const pushPreviewBlocks: string[] = [];
  const pushSummaryRows: string[] = [];
  let processed = 0;
  let succeeded = 0;
  let failed = 0;

  for (const { index } of pendingIndexes) {
    const original = queue[index];
    const requestId = String(original.id ?? "").trim();
    const question = String(original.question ?? "").trim();
    if (!requestId || !question) {
      queue[index] = {
        ...original,
        status: "failed",
        updated_at: nowIso,
        last_error: "invalid_request_record",
      };
      failed += 1;
      processed += 1;
      continue;
    }

    const priority = clampPriority(original.priority ?? null);
    const title = (original.title ?? "").trim() || question.slice(0, 48);
    const source = (original.source ?? "").trim() || "manual";
    const tags = normalizeStringArray(original.tags);
    const context = normalizeStringArray(original.context);
    const baselineAttempts = Number.isFinite(original.attempts) ? Number(original.attempts) : 0;

    let runError: string | null = null;
    let runOutput: NotebookLmToolOutput | null = null;
    let runDurationMs = 0;
    let runAttempts = 0;

    for (let attempt = 1; attempt <= maxAttemptsPerRequest; attempt += 1) {
      runAttempts = attempt;
      const toolRun = runToolCommand({
        command: toolCommand,
        timeoutMs,
        payload: {
          request_id: requestId,
          title,
          question,
          source,
          priority,
          tags,
          context,
          created_at: original.created_at ?? nowIso,
        },
      });
      runDurationMs += toolRun.durationMs;
      if (toolRun.ok) {
        runOutput = toolRun.output;
        runError = null;
        break;
      }
      runError = toolRun.error;
    }

    processed += 1;
    const totalAttempts = baselineAttempts + runAttempts;

    if (!runOutput) {
      queue[index] = {
        ...original,
        status: "failed",
        updated_at: nowIso,
        attempts: totalAttempts,
        last_error: runError ?? "tool_failed",
      };
      failed += 1;
      pushSummaryRows.push(
        `| ${requestId} | failed | 0 | ${escapeInline(runError ?? "tool_failed")} |`,
      );
      continue;
    }

    const resultId = `${requestId}:r${totalAttempts}`;
    const noteFileName = `${requestId}_${slugify(title)}.md`;
    const notePath = path.join(paths.references, "notebooklm", noteFileName);
    const noteMarkdown = buildReferenceMarkdown({
      requestId,
      title,
      question,
      source,
      priority,
      tags,
      createdAt: nowIso,
      summary: runOutput.summary,
      keyPoints: runOutput.key_points,
      actionItems: runOutput.action_items,
      sources: runOutput.sources,
      confidence: runOutput.confidence,
      rawText: runOutput.raw_text,
      command: toolCommand,
      attempts: totalAttempts,
    });
    await writeText(notePath, noteMarkdown);

    const resultRow: NotebookLmResult = {
      result_id: resultId,
      request_id: requestId,
      created_at: nowIso,
      title,
      summary: runOutput.summary,
      key_points: runOutput.key_points,
      action_items: runOutput.action_items,
      sources: runOutput.sources,
      confidence: runOutput.confidence,
      raw_text: runOutput.raw_text,
      note_path: notePath,
      tool: {
        cmd: toolCommand,
        duration_ms: runDurationMs,
        attempts: totalAttempts,
      },
    };
    existingResults.push(resultRow);

    let pushResult: PushRun = { mode: "disabled", pushed: 0, error: null };
    const pushAllowedForRequest = original.push !== false;
    if (pushEnabled && pushAllowedForRequest) {
      if (!pushTo) {
        pushResult = {
          mode: "config_error",
          pushed: 0,
          error: "missing CAPTURE_NOTEBOOKLM_PUSH_TO",
        };
      } else {
        const pushText = buildPushText({
          title,
          summary: runOutput.summary,
          keyPoints: runOutput.key_points,
          priority,
          requestId,
        });
        pushPreviewBlocks.push(
          [
            `## ${requestId}`,
            "",
            `priority: ${priority ?? "null"}`,
            "```text",
            pushText,
            "```",
            "",
          ].join("\n"),
        );
        if (pushDryRun && !pushDryRunCli) {
          pushResult = { mode: "simulated_dry_run", pushed: 1, error: null };
        } else {
          try {
            const run = runOpenclawMessageSend({
              pushChannel,
              pushTo,
              text: pushText,
              pushAccountId,
              pushDryRun,
            });
            if (run.status === 0) {
              pushResult = { mode: "cli", pushed: 1, error: null };
            } else {
              pushResult = {
                mode: "cli",
                pushed: 0,
                error: (run.stderr || run.stdout || `exit_${run.status ?? "unknown"}`).trim(),
              };
            }
          } catch (err) {
            pushResult = {
              mode: "cli",
              pushed: 0,
              error: err instanceof Error ? err.message : String(err),
            };
          }
        }
      }
    } else if (pushEnabled && !pushAllowedForRequest) {
      pushResult = { mode: "request_opt_out", pushed: 0, error: null };
    }

    pushSummaryRows.push(
      `| ${requestId} | done | ${pushResult.pushed} | ${escapeInline(pushResult.error ?? "none")} |`,
    );

    queue[index] = {
      ...original,
      status: "done",
      updated_at: nowIso,
      attempts: totalAttempts,
      result_id: resultId,
      last_error: null,
    };
    succeeded += 1;
  }

  await writeJsonl({ filePath: queuePath, rows: queue });
  await writeJsonl({ filePath: resultsPath, rows: existingResults });

  await writeText(
    pushPreviewPath,
    [
      "# notebooklm_push_preview",
      "",
      `date: ${today}`,
      `enabled: ${pushEnabled ? "1" : "0"}`,
      `channel: ${pushChannel}`,
      `target: ${pushTo || "(unset)"}`,
      "",
      ...(pushPreviewBlocks.length > 0 ? pushPreviewBlocks : ["(none)", ""]),
    ].join("\n"),
  );

  await writeText(
    pushResultPath,
    [
      "# notebooklm_push_results",
      "",
      `date: ${today}`,
      `processed: ${processed}`,
      `success: ${succeeded}`,
      `failed: ${failed}`,
      `push_enabled: ${pushEnabled ? "1" : "0"}`,
      `push_channel: ${pushChannel}`,
      `push_target: ${pushTo || "(unset)"}`,
      "",
      "| request_id | status | pushed | error |",
      "| --- | --- | --- | --- |",
      ...(pushSummaryRows.length > 0 ? pushSummaryRows : ["| (none) | - | - | - |"]),
      "",
      `preview: ${pushPreviewPath}`,
      "",
    ].join("\n"),
  );

  await writeText(
    reportPath,
    [
      "# notebooklm_worker_results",
      "",
      `date: ${today}`,
      `tool_cmd: ${toolCommand}`,
      `max_per_run: ${maxPerRun}`,
      `tool_timeout_ms: ${timeoutMs}`,
      `tool_attempts_per_request: ${maxAttemptsPerRequest}`,
      `retry_failed: ${retryFailed ? "1" : "0"}`,
      "",
      `processed: ${processed}`,
      `success: ${succeeded}`,
      `failed: ${failed}`,
      `queue_size: ${queue.length}`,
      "",
      `results_file: ${resultsPath}`,
      `push_result_file: ${pushResultPath}`,
      "",
    ].join("\n"),
  );

  console.log(
    `capture:notebooklm-worker processed=${processed} success=${succeeded} failed=${failed} queue=${queue.length}`,
  );
}

await main();
