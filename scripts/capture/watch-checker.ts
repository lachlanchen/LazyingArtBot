#!/usr/bin/env -S node --import tsx
import { spawnSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  appendJsonlUnique,
  buildCardIndex,
  envBool,
  initHub,
  readJsonl,
  readText,
  tokyoYmd,
  writeJsonl,
  writeText,
} from "./_utils.js";

function runOpenclawMessageSend(params: {
  pushChannel: string;
  pushTo: string;
  text: string;
  pushAccountId?: string;
  pushDryRun: boolean;
}) {
  const cliBin = (process.env.CAPTURE_WATCH_PUSH_CLI_BIN ?? "openclaw").trim() || "openclaw";
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

function withTrailingNewline(value: string): string {
  return value.endsWith("\n") ? value : `${value}\n`;
}

function parseYmd(input: string): string {
  return input.slice(0, 10);
}

function isWatchExpired(entry: Record<string, unknown>, today: string): boolean {
  if (entry.consumed === true) {
    return false;
  }
  const id = String(entry.id ?? "").trim();
  if (!id) {
    return false;
  }
  const type = String(entry.type ?? "").trim();
  if (type !== "watch") {
    return false;
  }
  const autoArchiveAfter =
    typeof entry.auto_archive_after === "string" ? parseYmd(entry.auto_archive_after) : "";
  if (!autoArchiveAfter) {
    return false;
  }
  return autoArchiveAfter < today;
}

async function archiveWatchCard(params: { filePath: string; today: string }): Promise<boolean> {
  const raw = await readText(params.filePath);
  if (!raw || !raw.startsWith("---\n")) {
    return false;
  }
  const fenceEnd = raw.indexOf("\n---\n", 4);
  if (fenceEnd < 0) {
    return false;
  }

  const frontRaw = raw.slice(4, fenceEnd);
  const bodyRaw = raw.slice(fenceEnd + 5);
  const frontLines = frontRaw.split(/\r?\n/);
  let frontChanged = false;
  let hasStage = false;
  for (let i = 0; i < frontLines.length; i += 1) {
    if (!frontLines[i].startsWith("stage:")) {
      continue;
    }
    hasStage = true;
    if (frontLines[i] !== "stage: archived") {
      frontLines[i] = "stage: archived";
      frontChanged = true;
    }
  }
  if (!hasStage) {
    frontLines.push("stage: archived");
    frontChanged = true;
  }

  const lifecycleLine = `- watch_expired: ${params.today}`;
  let nextBody = withTrailingNewline(bodyRaw);
  let bodyChanged = false;
  if (!nextBody.includes(lifecycleLine)) {
    nextBody = `${nextBody}\n## Watch Lifecycle\n${lifecycleLine}\n`;
    bodyChanged = true;
  }

  if (!frontChanged && !bodyChanged) {
    return false;
  }

  const next = `---\n${frontLines.join("\n")}\n---\n${nextBody}`;
  await writeText(params.filePath, withTrailingNewline(next));
  return true;
}

function removeWaitingLines(
  raw: string,
  expiredIds: Set<string>,
): { changed: boolean; text: string; removed: number } {
  if (!raw.trim() || expiredIds.size === 0) {
    return { changed: false, text: raw, removed: 0 };
  }
  const lines = raw.split(/\r?\n/);
  const out: string[] = [];
  let removed = 0;
  for (const line of lines) {
    const idHit = line.match(/\(id:(\d{4}-\d{2}-\d{2}-\d{3,4})\)/);
    const id = idHit?.[1] ?? "";
    if (id && expiredIds.has(id)) {
      removed += 1;
      continue;
    }
    out.push(line);
  }
  const text = withTrailingNewline(out.join("\n"));
  return { changed: removed > 0, text, removed };
}

function extractOriginalSummary(content: string): string | null {
  if (!content.trim()) {
    return null;
  }
  const marker = /^##\s*原文\s*$/m;
  const hit = content.match(marker);
  if (!hit || hit.index === undefined) {
    return null;
  }
  const after = content.slice(hit.index + hit[0].length);
  const lines = after.split(/\r?\n/).map((line) => line.trim());
  for (const line of lines) {
    if (!line) {
      continue;
    }
    if (line.startsWith("## ")) {
      break;
    }
    return line.length > 90 ? `${line.slice(0, 90)}...` : line;
  }
  return null;
}

async function readCardSummary(cardPath: string | undefined): Promise<string | null> {
  if (!cardPath) {
    return null;
  }
  const raw = await readText(cardPath);
  if (!raw) {
    return null;
  }
  return extractOriginalSummary(raw);
}

function inferFriendlyMeaning(summary: string): string | null {
  const lower = summary.toLowerCase();
  const targets: string[] = [];

  if (/(mayberuncapture|capture|agent mode|agent)/.test(lower)) {
    targets.push("機器人收訊與記錄功能");
  }
  if (/(lark|feishu|飛書|飞书)/.test(lower)) {
    targets.push("Lark/飛書通道");
  }
  if (/(telegram|wechat|whatsapp)/.test(lower)) {
    targets.push("訊息通道");
  }
  if (/(webhook|adapter)/.test(lower)) {
    targets.push("接入連線");
  }
  if (/(smoke|test|驗證|验证|check)/.test(lower)) {
    if (targets.length > 0) {
      return `檢查${targets.slice(0, 2).join("、")}是否正常`;
    }
  }
  if (targets.length > 0) {
    return `跟進${targets.slice(0, 2).join("、")}狀態`;
  }
  return null;
}

type PriorityLabel = "P0" | "P1" | "P2" | "P3";

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

function inferWatchPriority(params: { type: string; priorityRaw?: string | null }): PriorityLabel {
  const direct = normalizePriority(params.priorityRaw);
  if (direct) {
    return direct;
  }
  if (params.type === "action") {
    return "P1";
  }
  if (params.type === "watch") {
    return "P2";
  }
  return "P3";
}

async function main() {
  const today = tokyoYmd();
  const pushEnabled = envBool("CAPTURE_WATCH_PUSH_ENABLED", false);
  const pushDryRun = envBool("CAPTURE_WATCH_PUSH_DRY_RUN", true);
  const pushDryRunCli = envBool("CAPTURE_WATCH_PUSH_DRY_RUN_CLI", false);
  const pushChannel = (process.env.CAPTURE_WATCH_PUSH_CHANNEL ?? "telegram").trim() || "telegram";
  const pushTo = (process.env.CAPTURE_WATCH_PUSH_TO ?? "").trim();
  const pushAccountId = (process.env.CAPTURE_WATCH_PUSH_ACCOUNT_ID ?? "").trim() || undefined;

  const paths = await initHub();
  const queuePath = path.join(paths.meta, "reasoning_queue.jsonl");
  const queue = await readJsonl<Record<string, unknown>>(queuePath);
  const cards = await buildCardIndex(paths.root);
  const existingFeedback = await readJsonl<Record<string, unknown>>(
    path.join(paths.meta, "feedback_signals.jsonl"),
  );
  const existingTokens = new Set(
    existingFeedback.map((row) => String(row?.token ?? "")).filter((value) => value.length > 0),
  );

  const expired = queue.filter((entry) => isWatchExpired(entry, today));
  const expiredIds = new Set(expired.map((entry) => String(entry.id ?? "").trim()).filter(Boolean));
  let queueConsumedUpdated = 0;
  const queueNext = queue.map((entry) => {
    const id = String(entry.id ?? "").trim();
    if (!id || !expiredIds.has(id) || entry.consumed === true) {
      return entry;
    }
    queueConsumedUpdated += 1;
    return {
      ...entry,
      consumed: true,
      consumed_at: new Date().toISOString(),
      consumed_reason: "watch_expired",
    };
  });
  if (queueConsumedUpdated > 0) {
    await writeJsonl({
      filePath: queuePath,
      rows: queueNext,
    });
  }

  let archivedCards = 0;
  for (const id of expiredIds) {
    const card = cards.get(id);
    if (!card?.path) {
      continue;
    }
    if (await archiveWatchCard({ filePath: card.path, today })) {
      archivedCards += 1;
    }
  }

  let waitingRemoved = 0;
  if (expiredIds.size > 0) {
    const waitingPath = path.join(paths.work, "waiting.md");
    const waitingRaw = await readText(waitingPath);
    const pruned = removeWaitingLines(waitingRaw, expiredIds);
    if (pruned.changed) {
      waitingRemoved = pruned.removed;
      await writeText(waitingPath, pruned.text);
    }
  }

  const dueToday = queueNext.filter((entry) => {
    if (entry?.consumed === true) {
      return false;
    }
    const checkpoints = Array.isArray(entry?.checkpoints)
      ? entry.checkpoints.map((v) => String(v).slice(0, 10))
      : [];
    return checkpoints.includes(today);
  });

  const reminderLines = [];
  const feedbackRows: Record<string, unknown>[] = [];
  const newReminderLines = [];
  const newReminderPushBlocks: string[] = [];

  for (const entry of dueToday) {
    const id = String(entry?.id ?? "").trim();
    if (!id) {
      continue;
    }
    const card = cards.get(id);
    const title = card?.title ?? id;
    const type = card?.type ?? String(entry?.type ?? "watch");
    const priority = inferWatchPriority({
      type,
      priorityRaw: typeof entry?.priority === "string" ? entry.priority : null,
    });
    const dueText = typeof entry?.due === "string" && entry.due ? String(entry.due) : "none";
    const summary = (await readCardSummary(card?.path)) ?? title;
    const friendlyMeaning = inferFriendlyMeaning(summary);
    const line = `- [ ] (${priority}) ${title} (id:${id}) type:${type} due:${entry?.due ?? "none"} checkpoint:${today}`;
    reminderLines.push(line);

    const token = `watch_checkpoint:${today}:${id}`;
    if (!existingTokens.has(token)) {
      newReminderLines.push(line);
      const displayTitle = friendlyMeaning ?? (summary !== title ? summary : title);
      newReminderPushBlocks.push(
        [
          `• ${displayTitle}（${priority}）`,
          `  到期：${dueText}（今天是 checkpoint 提醒，不是到期）`,
          `  回覆：1 ${id} = 轉任務；0 ${id} = 停止提醒`,
        ].join("\n"),
      );
    }

    feedbackRows.push({
      token,
      type: "watch_checkpoint",
      id,
      date: today,
      created_at: new Date().toISOString(),
      confidence: entry?.confidence ?? null,
    });
  }

  for (const entry of expired) {
    const id = String(entry?.id ?? "").trim();
    if (!id) {
      continue;
    }
    feedbackRows.push({
      token: `watch_expired:${today}:${id}`,
      type: "watch_expired",
      id,
      date: today,
      created_at: new Date().toISOString(),
      due: entry?.due ?? null,
    });
  }

  const reportPath = path.join(paths.meta, "watch_reminders.md");
  const report = [
    "# watch_reminders",
    "",
    `date: ${today}`,
    `count: ${reminderLines.length}`,
    `expired_count: ${expired.length}`,
    `queue_consumed_updates: ${queueConsumedUpdated}`,
    `archived_cards: ${archivedCards}`,
    `waiting_removed: ${waitingRemoved}`,
    "",
    ...(reminderLines.length > 0 ? reminderLines : ["- (none)"]),
    "",
    "## expired",
    ...(expired.length > 0 ? [...expiredIds].map((id) => `- ${id}`) : ["- (none)"]),
    "",
  ].join("\n");
  await writeText(reportPath, report);

  const added = await appendJsonlUnique({
    filePath: path.join(paths.meta, "feedback_signals.jsonl"),
    rows: feedbackRows,
  });

  let pushed = 0;
  let pushError = null;
  let pushMode = "skipped";
  let pushPayloadPath: string | null = null;
  if (pushEnabled && newReminderLines.length > 0) {
    if (!pushTo) {
      pushError = "missing CAPTURE_WATCH_PUSH_TO";
    } else {
      const previewBlocks = newReminderPushBlocks.slice(0, 8);
      const omitted = newReminderPushBlocks.length - previewBlocks.length;
      const text = [
        `📌 今日 Watch 提醒（${today}）`,
        "說明：今天是 checkpoint 檢查，不是到期通知。",
        ...previewBlocks,
        ...(omitted > 0 ? [`… 另有 ${omitted} 條，請看 watch_reminders.md`] : []),
      ].join("\n");
      pushPayloadPath = path.join(paths.meta, "watch_push_payload.md");
      await writeText(
        pushPayloadPath,
        [
          "# watch_push_payload",
          "",
          `date: ${today}`,
          `channel: ${pushChannel}`,
          `target: ${pushTo}`,
          "",
          text,
          "",
        ].join("\n"),
      );

      if (pushDryRun && !pushDryRunCli) {
        // Keep dry-run useful in environments where OpenClaw dist/CLI is unavailable.
        pushMode = "simulated_dry_run";
        pushed = newReminderLines.length;
      } else {
        pushMode = "cli";
        try {
          const run = runOpenclawMessageSend({
            pushChannel,
            pushTo,
            text,
            pushAccountId,
            pushDryRun,
          });
          if (run.status !== 0) {
            if (run.error) {
              pushError = String(run.error);
            } else {
              pushError = (run.stderr || run.stdout || `exit_${run.status ?? "unknown"}`).trim();
            }
          } else {
            pushed = newReminderLines.length;
          }
        } catch (err) {
          pushError = String(err);
        }
      }
    }
  }

  const pushReportPath = path.join(paths.meta, "watch_push_results.md");
  const pushReportLines = [
    "# watch_push_results",
    "",
    `date: ${today}`,
    `push_enabled: ${String(pushEnabled)}`,
    `push_dry_run: ${String(pushDryRun)}`,
    `push_dry_run_cli: ${String(pushDryRunCli)}`,
    `push_mode: ${pushMode}`,
    `target_channel: ${pushChannel}`,
    `target_to: ${pushTo || "(unset)"}`,
    `due_count: ${reminderLines.length}`,
    `new_due_count: ${newReminderLines.length}`,
    `pushed_count: ${pushed}`,
    `payload_file: ${pushPayloadPath ?? "(none)"}`,
    `error: ${pushError ?? "none"}`,
    "",
  ];
  await writeText(pushReportPath, pushReportLines.join("\n"));

  console.log(
    `capture:watch-checker due=${reminderLines.length} new=${newReminderLines.length} expired=${expired.length} signals_added=${added} pushed=${pushed} -> ${reportPath}`,
  );
}

await main();
