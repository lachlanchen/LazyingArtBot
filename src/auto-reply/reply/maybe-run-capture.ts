import fs from "node:fs/promises";
import path from "node:path";
import type { OpenClawConfig } from "../../config/config.js";
import type { FinalizedMsgContext } from "../templating.js";
import type { ReplyPayload } from "../types.js";
import { toEmailCaptureInput } from "../../adapters/email-capture-adapter.js";
import { toFeishuCaptureInput } from "../../adapters/feishu-capture-adapter.js";
import { toGenericCaptureInput } from "../../adapters/generic-capture-adapter.js";
import { toTelegramCaptureInput } from "../../adapters/telegram-capture-adapter.js";
import { toWechatCaptureInput } from "../../adapters/wechat-capture-adapter.js";
import { toWhatsAppCaptureInput } from "../../adapters/whatsapp-capture-adapter.js";
import { resolveHubPaths } from "../../capture-agent/hub.js";
import { runCaptureAgent } from "../../capture-agent/run.js";

export type MaybeRunCaptureResult = {
  handled: boolean;
  payload?: ReplyPayload;
  error?: string;
};

function isCaptureEnabled(cfg: OpenClawConfig): boolean {
  const fromEnv = process.env.MOLTBOT_CAPTURE_ENABLED?.trim().toLowerCase();
  if (fromEnv === "1" || fromEnv === "true" || fromEnv === "yes" || fromEnv === "on") {
    return true;
  }
  const captureValue = (cfg as Record<string, unknown>)["capture"];
  if (!captureValue || typeof captureValue !== "object") {
    return false;
  }
  const enabled = (captureValue as Record<string, unknown>)["enabled"];
  return enabled === true;
}

function isGenericCaptureEnabled(cfg: OpenClawConfig): boolean {
  const fromEnv = process.env.MOLTBOT_CAPTURE_GENERIC_ENABLED?.trim().toLowerCase();
  if (fromEnv === "1" || fromEnv === "true" || fromEnv === "yes" || fromEnv === "on") {
    return true;
  }
  const captureValue = (cfg as Record<string, unknown>)["capture"];
  if (!captureValue || typeof captureValue !== "object") {
    return false;
  }
  const genericEnabled = (captureValue as Record<string, unknown>)["genericEnabled"];
  return genericEnabled === true;
}

type CaptureControlAction = "watch_converted" | "watch_abandoned";

function getCommandText(ctx: FinalizedMsgContext): string {
  return (
    (ctx.BodyForCommands ?? ctx.RawBody ?? ctx.CommandBody ?? ctx.BodyForAgent ?? ctx.Body ?? "").trim() || ""
  );
}

function normalizeCommandText(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .replace(/\s+/g, "");
}

function detectCaptureControlAction(commandText: string): CaptureControlAction | null {
  const raw = commandText.trim();
  if (!raw) {
    return null;
  }
  if (/^1(?:[.!。！])?(?:\s+\d{4}-\d{2}-\d{2}-\d{3,4})?$/.test(raw)) {
    return "watch_converted";
  }
  if (/^0(?:[.!。！])?(?:\s+\d{4}-\d{2}-\d{2}-\d{3,4})?$/.test(raw)) {
    return "watch_abandoned";
  }
  const normalized = normalizeCommandText(raw);
  if (
    normalized === "1" ||
    normalized === "1." ||
    normalized === "1。" ||
    normalized === "1!" ||
    normalized === "1！" ||
    normalized === "轉任務" ||
    normalized === "转任务" ||
    normalized === "convert" ||
    normalized === "totask" ||
    normalized === "action"
  ) {
    return "watch_converted";
  }
  if (
    normalized === "0" ||
    normalized === "0." ||
    normalized === "0。" ||
    normalized === "0!" ||
    normalized === "0！" ||
    normalized === "不用提醒" ||
    normalized === "不用提醒了" ||
    normalized === "放棄" ||
    normalized === "放弃" ||
    normalized === "abandon" ||
    normalized === "dismiss" ||
    normalized === "ignore"
  ) {
    return "watch_abandoned";
  }
  if ((raw.includes("轉任務") || raw.includes("转任务")) && raw.length <= 16) {
    return "watch_converted";
  }
  if ((raw.includes("不用提醒") || raw.includes("放棄") || raw.includes("放弃")) && raw.length <= 16) {
    return "watch_abandoned";
  }
  return null;
}

function extractCaptureId(text: string | undefined): string | null {
  const raw = text?.trim();
  if (!raw) {
    return null;
  }
  const hit = raw.match(/(\d{4}-\d{2}-\d{2}-\d{3,4})(?!\d)/);
  return hit?.[1] ?? null;
}

function escapeForRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function frontmatterField(content: string, key: string): string | null {
  const hit = content.match(new RegExp(`^${key}:\\s*(.+)$`, "m"));
  if (!hit?.[1]) {
    return null;
  }
  return hit[1].trim().replace(/^"(.*)"$/, "$1").replace(/^'(.*)'$/, "$1");
}

async function listMarkdownFiles(dirPath: string): Promise<string[]> {
  try {
    const entries = await fs.readdir(dirPath, { withFileTypes: true });
    const out: string[] = [];
    for (const entry of entries) {
      const full = path.join(dirPath, entry.name);
      if (entry.isDirectory()) {
        out.push(...(await listMarkdownFiles(full)));
      } else if (entry.isFile() && entry.name.endsWith(".md")) {
        out.push(full);
      }
    }
    return out;
  } catch {
    return [];
  }
}

async function readText(filePath: string): Promise<string> {
  try {
    return await fs.readFile(filePath, "utf8");
  } catch {
    return "";
  }
}

async function writeText(filePath: string, content: string): Promise<void> {
  await fs.mkdir(path.dirname(filePath), { recursive: true });
  await fs.writeFile(filePath, content, "utf8");
}

type WatchCardTarget = {
  id: string;
  path: string;
  title: string;
  due: string | null;
};

async function findWatchCardById(tasksDir: string, id: string): Promise<WatchCardTarget | null> {
  const files = await listMarkdownFiles(tasksDir);
  const direct = files.find((filePath) => path.basename(filePath).startsWith(`${id}_`));
  if (!direct) {
    return null;
  }
  const content = await readText(direct);
  if (!content) {
    return null;
  }
  const type = frontmatterField(content, "type");
  if (type !== "watch") {
    return null;
  }
  return {
    id,
    path: direct,
    title: frontmatterField(content, "title") ?? id,
    due: frontmatterField(content, "due"),
  };
}

async function findWatchCardByReplyMessageId(params: {
  tasksDir: string;
  replyMessageId: string;
}): Promise<WatchCardTarget | null> {
  const { tasksDir, replyMessageId } = params;
  const files = await listMarkdownFiles(tasksDir);
  if (files.length === 0) {
    return null;
  }
  const escaped = escapeForRegExp(replyMessageId);
  const re = new RegExp(`\\b(?:message_id|reply_to)\\s*[:=]\\s*${escaped}\\b`, "m");
  for (const filePath of files) {
    const content = await readText(filePath);
    if (!content || !re.test(content)) {
      continue;
    }
    const type = frontmatterField(content, "type");
    if (type !== "watch") {
      continue;
    }
    const id = frontmatterField(content, "id");
    if (!id) {
      continue;
    }
    return {
      id,
      path: filePath,
      title: frontmatterField(content, "title") ?? id,
      due: frontmatterField(content, "due"),
    };
  }
  return null;
}

type FrontmatterSplit = {
  frontLines: string[];
  body: string;
};

function splitFrontmatter(content: string): FrontmatterSplit | null {
  if (!content.startsWith("---\n")) {
    return null;
  }
  const fenceEnd = content.indexOf("\n---\n", 4);
  if (fenceEnd < 0) {
    return null;
  }
  return {
    frontLines: content.slice(4, fenceEnd).split(/\r?\n/),
    body: content.slice(fenceEnd + 5),
  };
}

function withTrailingNewline(input: string): string {
  return input.endsWith("\n") ? input : `${input}\n`;
}

function upsertFrontmatterLine(lines: string[], key: string, value: string): { lines: string[]; changed: boolean } {
  const prefix = `${key}:`;
  let changed = false;
  let replaced = false;
  const next = lines.map((line) => {
    if (!line.startsWith(prefix)) {
      return line;
    }
    replaced = true;
    const nextLine = `${prefix} ${value}`;
    if (line !== nextLine) {
      changed = true;
      return nextLine;
    }
    return line;
  });
  if (!replaced) {
    next.push(`${prefix} ${value}`);
    changed = true;
  }
  return { lines: next, changed };
}

function appendLifecycleLine(body: string, line: string): { body: string; changed: boolean } {
  const base = withTrailingNewline(body);
  if (base.includes(line)) {
    return { body: base, changed: false };
  }
  if (base.includes("\n## Watch Lifecycle\n")) {
    const idx = base.indexOf("\n## Watch Lifecycle\n");
    const head = base.slice(0, idx + "\n## Watch Lifecycle\n".length);
    const tail = base.slice(idx + "\n## Watch Lifecycle\n".length);
    return {
      body: `${head}${line}\n${tail}`,
      changed: true,
    };
  }
  return {
    body: `${base}\n## Watch Lifecycle\n${line}\n`,
    changed: true,
  };
}

function tokyoYmd(now = new Date()): string {
  const formatter = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Shanghai",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  });
  return formatter.format(now);
}

async function updateWatchCard(params: {
  cardPath: string;
  action: CaptureControlAction;
  today: string;
}): Promise<boolean> {
  const { cardPath, action, today } = params;
  const raw = await readText(cardPath);
  const split = splitFrontmatter(raw);
  if (!split) {
    return false;
  }
  let changed = false;
  let frontLines = split.frontLines.slice();

  if (action === "watch_converted") {
    const typeUpdate = upsertFrontmatterLine(frontLines, "type", "action");
    frontLines = typeUpdate.lines;
    changed = changed || typeUpdate.changed;
    const stageUpdate = upsertFrontmatterLine(frontLines, "stage", "active");
    frontLines = stageUpdate.lines;
    changed = changed || stageUpdate.changed;
  } else {
    const stageUpdate = upsertFrontmatterLine(frontLines, "stage", "archived");
    frontLines = stageUpdate.lines;
    changed = changed || stageUpdate.changed;
  }

  const lifecycleEntry =
    action === "watch_converted"
      ? `- watch_converted: ${today}`
      : `- watch_abandoned: ${today}`;
  const lifecycle = appendLifecycleLine(split.body, lifecycleEntry);
  changed = changed || lifecycle.changed;
  if (!changed) {
    return false;
  }

  const next = `---\n${frontLines.join("\n")}\n---\n${withTrailingNewline(lifecycle.body)}`;
  await writeText(cardPath, withTrailingNewline(next));
  return true;
}

async function updateTasksMaster(params: {
  workDir: string;
  id: string;
  action: CaptureControlAction;
  today: string;
}): Promise<void> {
  const filePath = path.join(params.workDir, "tasks_master.md");
  const raw = await readText(filePath);
  if (!raw.trim()) {
    return;
  }
  const lines = raw.split(/\r?\n/);
  let changed = false;
  const next = lines.map((line) => {
    if (!line.includes(`(id:${params.id})`)) {
      return line;
    }
    if (params.action === "watch_converted") {
      const replaced = line.replace(/\btype:watch\b/g, "type:action");
      if (replaced !== line) {
        changed = true;
      }
      return replaced;
    }
    let out = line;
    if (out.startsWith("- [ ]")) {
      out = out.replace("- [ ]", "- [x]");
    }
    if (!out.includes(`abandoned:${params.today}`)) {
      out = `${out} abandoned:${params.today}`;
    }
    if (out !== line) {
      changed = true;
    }
    return out;
  });
  if (!changed) {
    return;
  }
  await writeText(filePath, withTrailingNewline(next.join("\n")));
}

async function updateWaiting(params: {
  workDir: string;
  id: string;
}): Promise<void> {
  const filePath = path.join(params.workDir, "waiting.md");
  const raw = await readText(filePath);
  if (!raw.trim()) {
    return;
  }
  const lines = raw.split(/\r?\n/);
  const filtered = lines.filter((line) => !line.includes(`(id:${params.id})`));
  if (filtered.length === lines.length) {
    return;
  }
  await writeText(filePath, withTrailingNewline(filtered.join("\n")));
}

async function updateReasoningQueue(params: {
  metaDir: string;
  id: string;
  action: CaptureControlAction;
}): Promise<void> {
  const filePath = path.join(params.metaDir, "reasoning_queue.jsonl");
  const raw = await readText(filePath);
  if (!raw.trim()) {
    return;
  }
  const rows = raw
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => {
      try {
        return JSON.parse(line) as Record<string, unknown>;
      } catch {
        return null;
      }
    })
    .filter((row): row is Record<string, unknown> => Boolean(row));
  let changed = false;
  const nowIso = new Date().toISOString();
  for (let i = 0; i < rows.length; i += 1) {
    const row = rows[i];
    if (String(row.id ?? "").trim() !== params.id) {
      continue;
    }
    rows[i] = {
      ...row,
      consumed: true,
      consumed_at: nowIso,
      consumed_reason: params.action,
    };
    changed = true;
  }
  if (!changed) {
    return;
  }
  const out = rows.map((row) => JSON.stringify(row)).join("\n");
  await writeText(filePath, out ? `${out}\n` : "");
}

async function appendFeedbackSignal(params: {
  metaDir: string;
  id: string;
  action: CaptureControlAction;
  today: string;
  due: string | null;
}): Promise<void> {
  const filePath = path.join(params.metaDir, "feedback_signals.jsonl");
  const token = `${params.action}:${params.today}:${params.id}`;
  const raw = await readText(filePath);
  const lines = raw
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);
  if (lines.some((line) => line.includes(`"token":"${token}"`))) {
    return;
  }
  const row = {
    token,
    type: params.action,
    id: params.id,
    date: params.today,
    created_at: new Date().toISOString(),
    due: params.due,
  };
  const next = `${raw}${raw.endsWith("\n") || raw.length === 0 ? "" : "\n"}${JSON.stringify(row)}\n`;
  await writeText(filePath, next);
}

async function maybeHandleCaptureControlCommand(params: {
  ctx: FinalizedMsgContext;
  action: CaptureControlAction;
}): Promise<ReplyPayload> {
  const { ctx, action } = params;
  const commandText = getCommandText(ctx);
  const explicitId = extractCaptureId(commandText);
  const replyBodyId = extractCaptureId(ctx.ReplyToBody);
  const replyMessageId = (ctx.ReplyToId ?? ctx.ReplyToIdFull ?? "").trim() || null;
  const hubPaths = resolveHubPaths();

  let target: WatchCardTarget | null = null;
  if (explicitId) {
    target = await findWatchCardById(hubPaths.tasks, explicitId);
  }
  if (!target && replyBodyId) {
    target = await findWatchCardById(hubPaths.tasks, replyBodyId);
  }
  if (!target && replyMessageId) {
    target = await findWatchCardByReplyMessageId({
      tasksDir: hubPaths.tasks,
      replyMessageId,
    });
  }

  if (!target) {
    return {
      text:
        "⚠️ 找不到要操作的 watch 卡。請直接回覆 bot 的 capture 回覆訊息，或在訊息中附上卡片 id（例如 2026-02-19-001）。",
    };
  }

  const today = tokyoYmd();
  await updateWatchCard({
    cardPath: target.path,
    action,
    today,
  });
  await updateTasksMaster({
    workDir: hubPaths.work,
    id: target.id,
    action,
    today,
  });
  await updateWaiting({
    workDir: hubPaths.work,
    id: target.id,
  });
  await updateReasoningQueue({
    metaDir: hubPaths.meta,
    id: target.id,
    action,
  });
  await appendFeedbackSignal({
    metaDir: hubPaths.meta,
    id: target.id,
    action,
    today,
    due: target.due,
  });

  if (action === "watch_converted") {
    return {
      text: `✅ 已轉任務：${target.title} (id:${target.id})\n→ 之後不再用 watch checkpoint 追這條，改按 action 追蹤。`,
    };
  }
  return {
    text: `🧹 已停止提醒：${target.title} (id:${target.id})\n→ 此 watch 已標記為 abandoned 並封存。`,
  };
}

export async function maybeRunCapture(params: {
  ctx: FinalizedMsgContext;
  cfg: OpenClawConfig;
}): Promise<MaybeRunCaptureResult> {
  const { ctx, cfg } = params;
  if (!isCaptureEnabled(cfg)) {
    return { handled: false };
  }

  const commandText = getCommandText(ctx);
  const controlAction = detectCaptureControlAction(commandText);

  const provider = String(ctx.Surface ?? ctx.Provider ?? "").toLowerCase();
  const genericFallback = isGenericCaptureEnabled(cfg);

  try {
    if (controlAction) {
      const payload = await maybeHandleCaptureControlCommand({
        ctx,
        action: controlAction,
      });
      return {
        handled: true,
        payload,
      };
    }

    let captureInput: ReturnType<typeof toTelegramCaptureInput> | null = null;
    if (provider === "telegram") {
      captureInput = toTelegramCaptureInput(ctx);
    } else if (provider === "email" || provider === "mail") {
      captureInput = toEmailCaptureInput(ctx);
    } else if (provider === "feishu" || provider === "lark") {
      captureInput = toFeishuCaptureInput(ctx);
    } else if (provider === "whatsapp") {
      captureInput = toWhatsAppCaptureInput(ctx);
    } else if (provider === "wechat" || provider === "weixin" || provider === "wechatbot") {
      captureInput = toWechatCaptureInput(ctx);
    } else if (genericFallback) {
      captureInput = toGenericCaptureInput(ctx);
    }
    if (!captureInput) {
      return { handled: false };
    }

    const out = await runCaptureAgent({
      input: captureInput,
      applyWrites: true,
      outputMode: process.env.OUTPUT_MODE ?? "json",
    });
    const lines = [out.ack.line1, out.ack.line2, out.ack.line3].filter(Boolean);
    return {
      handled: true,
      payload: { text: lines.join("\n") },
    };
  } catch (err) {
    return {
      handled: false,
      error: String(err),
    };
  }
}
