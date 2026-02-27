import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import type { OpenClawConfig } from "../../config/config.js";
import type { CronMessageChannel } from "../../cron/types.js";
import type { FinalizedMsgContext } from "../templating.js";
import type { ReplyPayload } from "../types.js";
import { toEmailCaptureInput } from "../../adapters/email-capture-adapter.js";
import { toFeishuCaptureInput } from "../../adapters/feishu-capture-adapter.js";
import { toGenericCaptureInput } from "../../adapters/generic-capture-adapter.js";
import { toTelegramCaptureInput } from "../../adapters/telegram-capture-adapter.js";
import { toWechatCaptureInput } from "../../adapters/wechat-capture-adapter.js";
import { toWhatsAppCaptureInput } from "../../adapters/whatsapp-capture-adapter.js";
import { resolveHubPaths, resolveHubRoot } from "../../capture-agent/hub.js";
import { runCaptureAgent } from "../../capture-agent/run.js";
import { getGlobalCron } from "../../cron/global-cron.js";

export type MaybeRunCaptureResult = {
  handled: boolean;
  payload?: ReplyPayload;
  error?: string;
};

type NotebookLmMode = "queue_only" | "queue_and_capture" | "queue_capture_and_model" | "auto";
type NotebookLmResolvedMode = Exclude<NotebookLmMode, "auto">;

type NotebookLmTrigger = {
  keyword: string;
  query: string;
};

type NotebookLmQueueResult = {
  id: string;
  keyword: string;
  duplicate: boolean;
  queueSize: number;
  mode: NotebookLmResolvedMode;
};

type NotebookLmQueueRow = {
  id: string;
  created_at: string;
  updated_at: string;
  status: "queued" | "running" | "done" | "failed";
  source: string;
  question: string;
  title?: string;
  priority?: "P0" | "P1" | "P2" | "P3" | null;
  tags?: string[];
  context?: string[];
  push?: boolean;
  attempts?: number;
  result_id?: string;
  last_error?: string | null;
  trigger_keyword?: string;
  source_message_id?: string;
  source_sender_id?: string;
  source_chat_type?: string;
};

const DEFAULT_NOTEBOOKLM_KEYWORDS = [
  "/nb",
  "/notebooklm",
  "notebooklm",
  "notebook lm",
  "nb:",
  "nb：",
  "用notebooklm",
  "交給notebooklm",
  "請notebooklm",
  "请notebooklm",
] as const;

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

async function maybeUpdateHeartbeat(out: {
  items: Array<{
    type: string;
    title: string;
    id: string;
    due: string | null;
    nextBestAction: string | null;
    priority: string | null;
  }>;
}): Promise<void> {
  const item = out.items[0];
  if (!item) {
    return;
  }

  const { type, title, id, due, nextBestAction, priority } = item;
  const isActionable = type === "action" || type === "watch" || type === "timeline";
  const hasNextAction =
    typeof nextBestAction === "string" &&
    nextBestAction !== "none" &&
    nextBestAction !== "null" &&
    nextBestAction.trim().length > 0;

  if (!isActionable && !hasNextAction) {
    return;
  }

  // hub root = ~/.openclaw/workspace/automation/assistant_hub → workspace root is 2 levels up
  const workspaceRoot = path.resolve(resolveHubRoot(), "../..");
  const heartbeatPath = path.join(workspaceRoot, "HEARTBEAT.md");

  const hm = new Intl.DateTimeFormat("zh-CN", {
    timeZone: "Asia/Shanghai",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  }).format(new Date());

  let line: string;
  if (isActionable) {
    const dueStr = due ? ` due:${due}` : "";
    const prioStr = priority ? ` [${priority}]` : "";
    line = `- [ ] [${type}]${prioStr} ${title} (id:${id})${dueStr} · ${hm}`;
  } else {
    line = `- [ ] [跟進] ${nextBestAction} (ref:${id}) · ${hm}`;
  }

  try {
    await fs.appendFile(heartbeatPath, `\n${line}\n`, "utf8");
  } catch {
    // best-effort: don't fail capture if heartbeat write fails
  }
}

function parseDueToIso(due: string): string | null {
  // Accept "YYYY-MM-DD" or "YYYY-MM-DDTHH:mm..." — schedule at 09:00 Asia/Shanghai on that day
  const dateMatch = due.match(/^(\d{4}-\d{2}-\d{2})/);
  if (!dateMatch?.[1]) {
    return null;
  }
  const scheduledAt = new Date(`${dateMatch[1]}T09:00:00+08:00`);
  if (Number.isNaN(scheduledAt.getTime())) {
    return null;
  }
  // Skip if already past
  if (scheduledAt <= new Date()) {
    return null;
  }
  return scheduledAt.toISOString();
}

async function maybeScheduleCronReminder(
  out: {
    items: Array<{
      type: string;
      title: string;
      id: string;
      due: string | null;
      nextBestAction: string | null;
    }>;
  },
  _ctx: FinalizedMsgContext,
): Promise<void> {
  const item = out.items[0];
  if (!item) {
    return;
  }
  const { type, title, id, due, nextBestAction } = item;

  // Only action/timeline items with a future due date
  if (type !== "action" && type !== "timeline") {
    return;
  }
  if (!due) {
    return;
  }

  const atIso = parseDueToIso(due);
  if (!atIso) {
    return;
  }

  const cron = getGlobalCron();
  if (!cron) {
    return;
  }

  // 4A — deduplication: skip if a job for this capture id already exists
  try {
    const existing = await cron.list({ includeDisabled: false });
    const isDuplicate = existing.jobs.some(
      (j) => j.description?.includes(`capture id:${id}`) || j.name === `到期提醒：${title}`,
    );
    if (isDuplicate) {
      return;
    }
  } catch {
    // if list fails, proceed anyway (best-effort)
  }

  const hubPaths = resolveHubPaths();
  const nba =
    typeof nextBestAction === "string" &&
    nextBestAction !== "none" &&
    nextBestAction !== "null" &&
    nextBestAction.trim()
      ? nextBestAction.trim()
      : null;

  // 4B — post-execution lifecycle + 4C — autonomous reschedule if incomplete
  const messageParts = [
    `【到期任務追蹤】`,
    `任務：${title}（id:${id}）`,
    `到期：${due}`,
    nba ? `建議行動：${nba}` : null,
    ``,
    `執行指引：`,
    `1. 找任務卡片：find ${hubPaths.tasks} -name "${id}_*" -type f`,
    `2. read 卡片取得完整上下文與最新狀態`,
    `3. 按建議行動執行（可用 exec/web_fetch/cron 等工具）`,
    `4. 用繁體中文向 Ken 簡短回報結果`,
    ``,
    `執行後自主更新狀態（Ken 不需要手動標記任何東西）：`,
    `- 任務**完成** → edit 卡片 frontmatter：status: done, completed_at: <today_yyyy-mm-dd>`,
    `  → 在 ${hubPaths.work}/tasks_master.md 找 (id:${id}) 那行，把 [ ] 改為 [x]`,
    `- 任務**未完成/需繼續追蹤** → cron 工具重排提醒（3天後），並在卡片加一行進度備註`,
  ]
    .filter((line): line is string => line !== null)
    .join("\n");

  try {
    await cron.add({
      name: `到期提醒：${title}`,
      description: `capture id:${id} auto due-reminder`,
      schedule: { kind: "at", at: atIso },
      sessionTarget: "isolated",
      deleteAfterRun: true,
      payload: {
        kind: "agentTurn",
        message: messageParts,
        // Use "last" so the system delivers to the main agent's last active chat.
        // This is more reliable than capturing ctx.From at schedule time.
        deliver: true,
        channel: "last" as CronMessageChannel,
        bestEffortDeliver: true,
      },
    });
  } catch {
    // best-effort; don't fail capture if cron scheduling fails
  }
}

async function maybeCreateFeishuCalendarEvent(out: {
  items: Array<{
    type: string;
    title: string;
    id: string;
    due: string | null;
  }>;
}): Promise<void> {
  const item = out.items[0];
  if (!item) {
    return;
  }

  const { type, title, id, due } = item;
  if (type !== "action" && type !== "timeline") {
    return;
  }
  if (!due) {
    return;
  }

  const dateMatch = due.match(/^(\d{4}-\d{2}-\d{2})/);
  if (!dateMatch?.[1]) {
    return;
  }
  const dateStr = dateMatch[1];

  // Skip if already past
  if (new Date(`${dateStr}T23:59:59+08:00`) <= new Date()) {
    return;
  }

  const TOKEN_FILE = path.join(os.homedir(), ".openclaw", "feishu_user_token.json");
  let tokenData: { access_token: string; calendar_id: string } | null = null;
  try {
    const raw = await fs.readFile(TOKEN_FILE, "utf8");
    tokenData = JSON.parse(raw) as { access_token: string; calendar_id: string };
  } catch {
    return; // No token file, silently skip
  }

  if (!tokenData?.access_token || !tokenData?.calendar_id) {
    return;
  }

  const calendarId = tokenData.calendar_id;

  // End date = next day (Feishu all-day event convention)
  const endDateObj = new Date(`${dateStr}T00:00:00+08:00`);
  endDateObj.setDate(endDateObj.getDate() + 1);
  const endDateStr = endDateObj.toISOString().slice(0, 10);

  const body = {
    summary: title,
    description: `[Kairo] capture id:${id}`,
    start_time: { date: dateStr },
    end_time: { date: endDateStr },
    visibility: "default",
    color: -1,
  };

  try {
    const resp = await fetch(
      `https://open.feishu.cn/open-apis/calendar/v4/calendars/${encodeURIComponent(calendarId)}/events`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${tokenData.access_token}`,
        },
        body: JSON.stringify(body),
      },
    );
    const data = (await resp.json()) as { code?: number; msg?: string };
    if (data.code !== 0) {
      console.warn("[feishu-calendar-create] API error:", data.code, data.msg);
    } else {
      console.log(`[feishu-calendar-create] Created event "${title}" on ${dateStr}`);
    }
  } catch (e) {
    console.warn("[feishu-calendar-create] fetch error:", e);
  }
}

function isAlsoReplyEnabled(cfg: OpenClawConfig): boolean {
  const fromEnv = process.env.MOLTBOT_CAPTURE_ALSO_REPLY?.trim().toLowerCase();
  if (fromEnv === "1" || fromEnv === "true" || fromEnv === "yes" || fromEnv === "on") {
    return true;
  }
  const captureValue = (cfg as Record<string, unknown>)["capture"];
  if (!captureValue || typeof captureValue !== "object") {
    return false;
  }
  const alsoReply = (captureValue as Record<string, unknown>)["alsoReply"];
  return alsoReply === true;
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

function parseBoolLike(input: unknown): boolean | null {
  if (typeof input === "boolean") {
    return input;
  }
  if (typeof input !== "string") {
    return null;
  }
  const normalized = input.trim().toLowerCase();
  if (!normalized) {
    return null;
  }
  if (normalized === "1" || normalized === "true" || normalized === "yes" || normalized === "on") {
    return true;
  }
  if (normalized === "0" || normalized === "false" || normalized === "no" || normalized === "off") {
    return false;
  }
  return null;
}

function getCaptureConfig(cfg: OpenClawConfig): Record<string, unknown> | null {
  const captureValue = (cfg as Record<string, unknown>)["capture"];
  if (!captureValue || typeof captureValue !== "object") {
    return null;
  }
  return captureValue as Record<string, unknown>;
}

function getNotebookLmConfig(cfg: OpenClawConfig): Record<string, unknown> | null {
  const captureCfg = getCaptureConfig(cfg);
  if (!captureCfg) {
    return null;
  }
  const value = captureCfg["notebooklm"];
  if (!value || typeof value !== "object") {
    return null;
  }
  return value as Record<string, unknown>;
}

function isNotebookLmEnabled(cfg: OpenClawConfig): boolean {
  const env = parseBoolLike(process.env.MOLTBOT_NOTEBOOKLM_ENABLED);
  if (env !== null) {
    return env;
  }
  const nb = getNotebookLmConfig(cfg);
  if (!nb) {
    return false;
  }
  return nb["enabled"] === true;
}

function normalizeNotebookLmMode(value: unknown): NotebookLmMode | null {
  if (typeof value !== "string") {
    return null;
  }
  const normalized = value.trim().toLowerCase();
  if (!normalized) {
    return null;
  }
  if (normalized === "queue_only" || normalized === "only" || normalized === "notebook_only") {
    return "queue_only";
  }
  if (
    normalized === "queue_and_capture" ||
    normalized === "capture_only" ||
    normalized === "capture"
  ) {
    return "queue_and_capture";
  }
  if (
    normalized === "queue_capture_and_model" ||
    normalized === "capture_and_model" ||
    normalized === "both" ||
    normalized === "model"
  ) {
    return "queue_capture_and_model";
  }
  if (normalized === "auto") {
    return "auto";
  }
  return null;
}

function parseKeywordList(value: unknown): string[] {
  if (typeof value !== "string") {
    return [];
  }
  return value
    .split(/[,\n|]/)
    .map((item) => item.trim())
    .filter(Boolean);
}

function getNotebookLmKeywords(cfg: OpenClawConfig): string[] {
  const envList = parseKeywordList(process.env.MOLTBOT_NOTEBOOKLM_KEYWORDS);
  if (envList.length > 0) {
    return envList;
  }
  const nb = getNotebookLmConfig(cfg);
  const cfgList = Array.isArray(nb?.keywords)
    ? nb?.keywords.map((item) => (typeof item === "string" ? item.trim() : "")).filter(Boolean)
    : [];
  if (cfgList.length > 0) {
    return cfgList;
  }
  return [...DEFAULT_NOTEBOOKLM_KEYWORDS];
}

function extractNotebookLmPrefixQuery(commandText: string): NotebookLmTrigger | null {
  const raw = commandText.trim();
  if (!raw) {
    return null;
  }
  const patterns: Array<{ re: RegExp; keyword: string }> = [
    { re: /^\/(?:nb|notebook|notebooklm)\s*[:：]?\s+([\s\S]+)$/i, keyword: "/nb" },
    { re: /^(?:nb|notebooklm)\s*[:：]\s*([\s\S]+)$/i, keyword: "nb:" },
  ];
  for (const pattern of patterns) {
    const hit = raw.match(pattern.re);
    if (!hit?.[1]) {
      continue;
    }
    const query = hit[1].trim();
    if (!query) {
      continue;
    }
    return {
      keyword: pattern.keyword,
      query,
    };
  }
  return null;
}

function keywordRegexHit(raw: string, keyword: string): boolean {
  const trimmed = keyword.trim();
  if (!trimmed) {
    return false;
  }
  if (/^[a-z0-9_]+$/i.test(trimmed)) {
    const re = new RegExp(`\\b${escapeForRegExp(trimmed)}\\b`, "i");
    return re.test(raw);
  }
  return raw.toLowerCase().includes(trimmed.toLowerCase());
}

function extractNotebookLmTrigger(
  commandText: string,
  keywords: string[],
): NotebookLmTrigger | null {
  const explicit = extractNotebookLmPrefixQuery(commandText);
  if (explicit) {
    return explicit;
  }
  const raw = commandText.trim();
  if (!raw) {
    return null;
  }
  const rawLower = raw.toLowerCase();
  for (const keyword of keywords) {
    const trimmed = keyword.trim();
    if (!trimmed || !keywordRegexHit(raw, trimmed)) {
      continue;
    }
    const loweredKeyword = trimmed.toLowerCase();
    const idx = rawLower.indexOf(loweredKeyword);
    let query = raw;
    if (idx >= 0) {
      const before = raw.slice(0, idx).trim();
      const after = raw.slice(idx + loweredKeyword.length).trim();
      query = `${before} ${after}`.replace(/\s+/g, " ").trim();
      query = query.replace(/^[:：,，-]+\s*/u, "").trim();
    }
    return {
      keyword: trimmed,
      query: query || raw,
    };
  }
  return null;
}

function chooseNotebookLmAutoMode(commandText: string): NotebookLmResolvedMode {
  const lower = commandText.toLowerCase();
  if (
    lower.includes("只用notebooklm") ||
    lower.includes("不用即時回覆") ||
    lower.includes("不用即时回复") ||
    lower.includes("先排隊") ||
    lower.includes("先排队")
  ) {
    return "queue_and_capture";
  }
  if (
    lower.includes("先給結論") ||
    lower.includes("先给结论") ||
    lower.includes("順便回答") ||
    lower.includes("顺便回答") ||
    lower.includes("先答我") ||
    lower.includes("immediate")
  ) {
    return "queue_capture_and_model";
  }
  if (commandText.includes("?") || commandText.includes("？")) {
    return "queue_capture_and_model";
  }
  return "queue_and_capture";
}

function resolveNotebookLmMode(cfg: OpenClawConfig, commandText: string): NotebookLmResolvedMode {
  const envMode = normalizeNotebookLmMode(process.env.MOLTBOT_NOTEBOOKLM_MODE);
  const cfgMode = normalizeNotebookLmMode(getNotebookLmConfig(cfg)?.mode);
  const mode = envMode ?? cfgMode ?? "queue_and_capture";
  if (mode === "auto") {
    return chooseNotebookLmAutoMode(commandText);
  }
  return mode;
}

function inferPriorityFromText(commandText: string): "P0" | "P1" | "P2" | "P3" | null {
  const hit = commandText.toUpperCase().match(/\bP([0-3])\b/);
  if (!hit?.[1]) {
    return null;
  }
  return `P${hit[1]}` as "P0" | "P1" | "P2" | "P3";
}

function nowTokyoCompact(now = new Date()): { ymd: string; hms: string } {
  const formatter = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Shanghai",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: false,
  });
  const parts = formatter.formatToParts(now);
  const byType = new Map(parts.map((part) => [part.type, part.value]));
  const ymd = `${byType.get("year") ?? "1970"}-${byType.get("month") ?? "01"}-${byType.get("day") ?? "01"}`;
  const hms = `${byType.get("hour") ?? "00"}${byType.get("minute") ?? "00"}${byType.get("second") ?? "00"}`;
  return { ymd, hms };
}

function nextNotebookLmRequestId(now = new Date()): string {
  const tokyo = nowTokyoCompact(now);
  const suffix = String(Math.floor(Math.random() * 10_000)).padStart(4, "0");
  return `nb-${tokyo.ymd.replace(/-/g, "")}-${tokyo.hms}-${suffix}`;
}

function trimSingleLine(value: string, limit: number): string {
  const normalized = value.replace(/\s+/g, " ").trim();
  if (normalized.length <= limit) {
    return normalized;
  }
  return `${normalized.slice(0, Math.max(0, limit - 3)).trim()}...`;
}

async function enqueueNotebookLmRequest(params: {
  metaDir: string;
  provider: string;
  ctx: FinalizedMsgContext;
  query: string;
  keyword: string;
  mode: NotebookLmResolvedMode;
}): Promise<NotebookLmQueueResult> {
  const queuePath = path.join(params.metaDir, "notebooklm_requests.jsonl");
  const raw = await readText(queuePath);
  const lines = raw
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);
  const rows: Record<string, unknown>[] = [];
  for (const line of lines) {
    try {
      rows.push(JSON.parse(line) as Record<string, unknown>);
    } catch {
      // ignore malformed row
    }
  }

  const messageId = (
    params.ctx.MessageSidFull ??
    params.ctx.MessageSid ??
    params.ctx.MessageSidFirst ??
    params.ctx.MessageSidLast ??
    ""
  ).trim();
  if (messageId) {
    const duplicate = rows.find((row) => String(row.source_message_id ?? "").trim() === messageId);
    if (duplicate) {
      return {
        id: String(duplicate.id ?? "").trim() || nextNotebookLmRequestId(),
        keyword: params.keyword,
        duplicate: true,
        queueSize: lines.length,
        mode: params.mode,
      };
    }
  }

  const createdAt = new Date().toISOString();
  const pushDefault = parseBoolLike(process.env.CAPTURE_NOTEBOOKLM_REQUEST_PUSH_DEFAULT) ?? true;
  const row: NotebookLmQueueRow = {
    id: nextNotebookLmRequestId(),
    created_at: createdAt,
    updated_at: createdAt,
    status: "queued",
    source: params.provider || "unknown",
    question: params.query,
    title: trimSingleLine(params.query, 48),
    priority: inferPriorityFromText(params.query),
    tags: ["notebooklm", params.provider || "unknown"],
    context: [],
    push: pushDefault,
    attempts: 0,
    last_error: null,
    trigger_keyword: params.keyword,
    source_message_id: messageId || undefined,
    source_sender_id: (params.ctx.SenderId ?? params.ctx.From ?? "").trim() || undefined,
    source_chat_type: (params.ctx.ChatType ?? "").trim() || undefined,
  };
  const next = `${raw}${raw.endsWith("\n") || raw.length === 0 ? "" : "\n"}${JSON.stringify(row)}\n`;
  await writeText(queuePath, next);
  return {
    id: row.id,
    keyword: params.keyword,
    duplicate: false,
    queueSize: lines.length + 1,
    mode: params.mode,
  };
}

function buildNotebookLmQueueAck(params: NotebookLmQueueResult): string {
  const statusLine = params.duplicate ? "♻️ NotebookLM 任務已存在" : "📚 NotebookLM 任務已排隊";
  const modeLabel =
    params.mode === "queue_only"
      ? "queue_only"
      : params.mode === "queue_capture_and_model"
        ? "queue_capture_and_model"
        : "queue_and_capture";
  return [
    statusLine,
    `id: ${params.id} | mode: ${modeLabel}`,
    `keyword: ${params.keyword} | queue: ${params.queueSize}`,
  ].join("\n");
}

type CaptureControlAction = "watch_converted" | "watch_abandoned";

function getCommandText(ctx: FinalizedMsgContext): string {
  return (
    (
      ctx.BodyForCommands ??
      ctx.RawBody ??
      ctx.CommandBody ??
      ctx.BodyForAgent ??
      ctx.Body ??
      ""
    ).trim() || ""
  );
}

function normalizeCommandText(value: string): string {
  return value.trim().toLowerCase().replace(/\s+/g, "");
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
  if (
    (raw.includes("不用提醒") || raw.includes("放棄") || raw.includes("放弃")) &&
    raw.length <= 16
  ) {
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
  return hit[1]
    .trim()
    .replace(/^"(.*)"$/, "$1")
    .replace(/^'(.*)'$/, "$1");
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

function upsertFrontmatterLine(
  lines: string[],
  key: string,
  value: string,
): { lines: string[]; changed: boolean } {
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
    action === "watch_converted" ? `- watch_converted: ${today}` : `- watch_abandoned: ${today}`;
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

async function updateWaiting(params: { workDir: string; id: string }): Promise<void> {
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
      text: "⚠️ 找不到要操作的 watch 卡。請直接回覆 bot 的 capture 回覆訊息，或在訊息中附上卡片 id（例如 2026-02-19-001）。",
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
    // 4A/B: schedule a cron reminder for the newly-converted action if it has a due date
    await maybeScheduleCronReminder(
      {
        items: [
          {
            type: "action",
            title: target.title,
            id: target.id,
            due: target.due,
            nextBestAction: null,
          },
        ],
      },
      {} as FinalizedMsgContext,
    );
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
  const notebookLmEnabled = isNotebookLmEnabled(cfg);
  const notebookLmKeywords = notebookLmEnabled ? getNotebookLmKeywords(cfg) : [];
  const notebookLmTrigger = notebookLmEnabled
    ? extractNotebookLmTrigger(commandText, notebookLmKeywords)
    : null;

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

    const deleteRequest = parseDeleteRequest(commandText);
    if (deleteRequest) {
      const result = await deleteFromAssistantHub(deleteRequest.query);
      const text =
        result.removedLines > 0
          ? `✅ 已處理：已刪除「${deleteRequest.query}」相關 ${result.removedLines} 行（${result.touchedFiles} 檔）`
          : `✅ 已檢查：未找到「${deleteRequest.query}」相關內容`;
      return {
        handled: true,
        payload: { text },
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

    let notebookLmQueued: NotebookLmQueueResult | null = null;
    if (notebookLmTrigger) {
      const notebookLmMode = resolveNotebookLmMode(cfg, commandText);
      notebookLmQueued = await enqueueNotebookLmRequest({
        metaDir: resolveHubPaths().meta,
        provider,
        ctx,
        query: notebookLmTrigger.query,
        keyword: notebookLmTrigger.keyword,
        mode: notebookLmMode,
      });

      if (notebookLmMode === "queue_only") {
        return {
          handled: true,
          payload: { text: buildNotebookLmQueueAck(notebookLmQueued) },
        };
      }
    }

    const out = await runCaptureAgent({
      input: captureInput,
      applyWrites: true,
      outputMode: process.env.OUTPUT_MODE ?? "json",
    });
    await maybeUpdateHeartbeat(out);
    await maybeScheduleCronReminder(out, ctx);
    await maybeCreateFeishuCalendarEvent(out);
    const lines = [out.ack.line1, out.ack.line2, out.ack.line3].filter(Boolean);

    if (notebookLmQueued?.mode === "queue_capture_and_model") {
      return {
        handled: true,
      };
    }

    const notebookAck = notebookLmQueued ? buildNotebookLmQueueAck(notebookLmQueued) : "";
    const combined = notebookAck ? [...lines, notebookAck].join("\n") : lines.join("\n");
    const alsoReply = isAlsoReplyEnabled(cfg);
    return {
      handled: !alsoReply,
      payload: alsoReply ? undefined : { text: combined },
    };
  } catch (err) {
    return {
      handled: false,
      error: String(err),
    };
  }
}
