import fs from "node:fs/promises";
import path from "node:path";
import {
  classifyCaptureInput,
  inferRemindSchedule,
  type CaptureClassifierContext,
} from "./classifier.js";
import {
  applyFileOps,
  buildCardMarkdown,
  ensureHubPaths,
  ensureHubScaffoldFiles,
  escapeTableCell,
  nextDailyId,
  resolveHubPaths,
  resolveMainPath,
  resolvePathSet,
  slugifyTitle,
  typeEmoji,
} from "./hub.js";
import type {
  CaptureAck,
  CaptureAgentRunParams,
  CaptureAgentCardOutput,
  CaptureCardFrontmatter,
  CaptureContentParts,
  CaptureDateParts,
  CaptureFeedback,
  CaptureFileOp,
  CaptureInference,
  CaptureItem,
  CaptureJsonOutput,
  CaptureRunOutput,
  CaptureRemindSchedule,
  CaptureType,
} from "./types.js";

const TZ = "Asia/Shanghai";
const DEDUPE_FILE_AGE_MS = 3 * 24 * 60 * 60 * 1000;
const TITLE_SIMILARITY_THRESHOLD = 0.72;
const CONTEXT_READ_LIMIT = 6_000;

function getDateParts(ts: number): CaptureDateParts {
  const formatter = new Intl.DateTimeFormat("en-CA", {
    timeZone: TZ,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  });
  const parts = formatter.formatToParts(new Date(ts));
  const byType = new Map(parts.map((part) => [part.type, part.value]));
  const y = byType.get("year") ?? "1970";
  const m = byType.get("month") ?? "01";
  const d = byType.get("day") ?? "01";
  const h = byType.get("hour") ?? "00";
  const min = byType.get("minute") ?? "00";
  return {
    ymd: `${y}-${m}-${d}`,
    hm: `${h}:${min}`,
    isoWithOffset: `${y}-${m}-${d}T${h}:${min}:00+08:00`,
  };
}

function parseTimestamp(raw: string | undefined): number {
  if (!raw) {
    return Date.now();
  }
  const value = Date.parse(raw);
  return Number.isFinite(value) ? value : Date.now();
}

function shiftYmd(ymd: string, offsetDays: number): string {
  const [year, month, day] = ymd.split("-").map((part) => Number(part));
  const date = new Date(Date.UTC(year, month - 1, day));
  date.setUTCDate(date.getUTCDate() + offsetDays);
  const y = date.getUTCFullYear();
  const m = String(date.getUTCMonth() + 1).padStart(2, "0");
  const d = String(date.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

async function listInboxFilesForDay(inboxDir: string, ymd: string): Promise<string[]> {
  try {
    const entries = await fs.readdir(inboxDir, { withFileTypes: true });
    return entries
      .filter((entry) => entry.isFile())
      .map((entry) => entry.name)
      .filter((name) => name.startsWith(`${ymd}_`) && name.endsWith("_inbox.md"))
      .map((name) => path.join(inboxDir, name))
      .sort();
  } catch {
    return [];
  }
}

function extractKnownTags(content: string): string[] {
  if (!content) {
    return [];
  }
  const out = new Set<string>();
  for (const line of content.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) {
      continue;
    }
    const normalized = trimmed.replace(/^[-*]\s+/, "");
    const candidates = normalized.match(/[#]?[a-zA-Z0-9_\u4e00-\u9fa5-]{2,24}/g) ?? [];
    for (const raw of candidates) {
      const tag = raw.replace(/^#/, "").trim();
      if (!tag || tag.length < 2) {
        continue;
      }
      out.add(tag);
      if (out.size >= 64) {
        return [...out];
      }
    }
  }
  return [...out];
}

async function buildClassifierContext(params: {
  hubPaths: ReturnType<typeof resolveHubPaths>;
  now: CaptureDateParts;
}): Promise<CaptureClassifierContext> {
  const { hubPaths, now } = params;
  const filesToRead: string[] = [
    path.join(hubPaths.work, "tasks_master.md"),
    path.join(hubPaths.work, "waiting.md"),
    path.join(hubPaths.work, "calendar.md"),
    path.join(hubPaths.root, "TAGS.md"),
    path.join(hubPaths.dailyLogs, `${now.ymd}.md`),
    path.join(hubPaths.ideas, "_ideas_index.md"),
  ];

  for (let offset = 0; offset < 3; offset += 1) {
    const ymd = shiftYmd(now.ymd, -offset);
    const inboxFiles = await listInboxFilesForDay(hubPaths.inbox, ymd);
    filesToRead.push(...inboxFiles);
  }

  const chunks: string[] = [];
  for (const filePath of filesToRead) {
    const content = await readText(filePath);
    if (!content) {
      continue;
    }
    const compact = content.trim();
    if (!compact) {
      continue;
    }
    chunks.push(compact.slice(0, CONTEXT_READ_LIMIT));
  }

  const tagsContent = (await readText(path.join(hubPaths.root, "TAGS.md"))) ?? "";
  return {
    recentText: chunks.join("\n"),
    knownTags: extractKnownTags(tagsContent),
  };
}

function normalizeTitleKey(input: string): string {
  return input
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, "")
    .trim();
}

function titleSimilarity(a: string, b: string): number {
  const left = normalizeTitleKey(a);
  const right = normalizeTitleKey(b);
  if (!left || !right) {
    return 0;
  }
  if (left === right) {
    return 1;
  }
  if ((left.includes(right) || right.includes(left)) && Math.min(left.length, right.length) >= 6) {
    return 0.9;
  }
  const leftSet = new Set(left.split(""));
  const rightSet = new Set(right.split(""));
  const intersect = [...leftSet].filter((ch) => rightSet.has(ch)).length;
  const union = new Set([...leftSet, ...rightSet]).size;
  if (union === 0) {
    return 0;
  }
  return intersect / union;
}

function extractFrontmatterField(content: string, key: string): string | null {
  const match = content.match(new RegExp(`^${key}:\\s*(.+)$`, "m"));
  if (!match) {
    return null;
  }
  const raw = match[1]?.trim();
  if (!raw) {
    return null;
  }
  const unquoted = raw.replace(/^"(.*)"$/, "$1").replace(/^'(.*)'$/, "$1");
  return unquoted.trim();
}

function extractIdFromPath(filePath: string): string | null {
  const base = path.basename(filePath);
  const match = base.match(/^(\d{4}-\d{2}-\d{2}-\d{3,4})_/);
  return match?.[1] ?? null;
}

async function listMarkdownFiles(dirPath: string): Promise<string[]> {
  try {
    const entries = await fs.readdir(dirPath, { withFileTypes: true });
    const out: string[] = [];
    for (const entry of entries) {
      const full = path.join(dirPath, entry.name);
      if (entry.isFile() && entry.name.endsWith(".md")) {
        out.push(full);
      }
      if (entry.isDirectory()) {
        const nested = await listMarkdownFiles(full);
        out.push(...nested);
      }
    }
    return out;
  } catch {
    return [];
  }
}

async function readText(filePath: string): Promise<string | null> {
  try {
    return await fs.readFile(filePath, "utf8");
  } catch {
    return null;
  }
}

function containsMessageRef(content: string, messageId: string | undefined): boolean {
  const value = messageId?.trim();
  if (!value) {
    return false;
  }
  const escaped = value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  return new RegExp(`\\bmessage_id\\s*[:=]\\s*${escaped}\\b`, "m").test(content);
}

function mergeCardContent(params: {
  existing: string;
  now: CaptureDateParts;
  inputText: string;
  inference: CaptureInference;
}): string {
  const { existing, now, inputText, inference } = params;
  if (containsMessageRef(existing, inference.rawInput.metadata.messageId)) {
    return existing;
  }

  const meta: string[] = [];
  if (inference.rawInput.metadata.messageId) {
    meta.push(`message_id: ${inference.rawInput.metadata.messageId}`);
  }
  if (inference.rawInput.metadata.replyTo) {
    meta.push(`reply_to: ${inference.rawInput.metadata.replyTo}`);
  }
  if (inference.rawInput.metadata.groupId) {
    meta.push(`group_id: ${inference.rawInput.metadata.groupId}`);
  }

  const addition = [
    `### ${now.hm} 補充原文`,
    inputText,
    meta.length > 0 ? `（${meta.join(" | ")}）` : "",
    "",
  ]
    .filter(Boolean)
    .join("\n");

  const marker = "\n## 你的整理";
  const idx = existing.indexOf(marker);
  if (idx >= 0) {
    return `${existing.slice(0, idx)}\n${addition}${existing.slice(idx)}`;
  }
  return `${existing.trimEnd()}\n\n${addition}\n`;
}

type AppendMatch = {
  path: string;
  reason: "reply_to" | "similar_title" | "already_seen";
};

async function findAppendTarget(params: {
  hubPaths: ReturnType<typeof resolveHubPaths>;
  inference: CaptureInference;
  nowTs: number;
}): Promise<AppendMatch | null> {
  const { hubPaths, inference, nowTs } = params;
  if (inference.type === "memory") {
    return null;
  }

  const candidateDirs = [
    hubPaths.tasks,
    hubPaths.projects,
    hubPaths.ideas,
    hubPaths.highlights,
    hubPaths.people,
    hubPaths.questions,
    hubPaths.beliefs,
    hubPaths.references,
  ];

  const filesNested = await Promise.all(candidateDirs.map((dir) => listMarkdownFiles(dir)));
  const files = filesNested.flat();
  if (files.length === 0) {
    return null;
  }

  const replyTo = inference.rawInput.metadata.replyTo?.trim();
  const currentMessageId = inference.rawInput.metadata.messageId?.trim();
  let best: { path: string; score: number } | null = null;

  for (const filePath of files) {
    try {
      const stat = await fs.stat(filePath);
      if (nowTs - stat.mtimeMs > DEDUPE_FILE_AGE_MS) {
        continue;
      }
    } catch {
      continue;
    }

    const content = await readText(filePath);
    if (!content) {
      continue;
    }

    if (containsMessageRef(content, currentMessageId)) {
      return { path: filePath, reason: "already_seen" };
    }

    if (replyTo && containsMessageRef(content, replyTo)) {
      return { path: filePath, reason: "reply_to" };
    }

    const candidateType = extractFrontmatterField(content, "type");
    if (candidateType && candidateType !== inference.type) {
      continue;
    }
    const candidateTitle = extractFrontmatterField(content, "title");
    if (!candidateTitle) {
      continue;
    }
    const score = titleSimilarity(inference.title, candidateTitle);
    if (score < TITLE_SIMILARITY_THRESHOLD) {
      continue;
    }
    if (!best || score > best.score) {
      best = { path: filePath, score };
    }
  }

  if (!best) {
    return null;
  }
  return { path: best.path, reason: "similar_title" };
}

function mapWatchType(type: CaptureType): CaptureFeedback["watchType"] {
  if (type === "action") {
    return "completion";
  }
  if (type === "idea") {
    return "promotion";
  }
  if (type === "reference") {
    return "reference";
  }
  if (type === "watch") {
    return "watch";
  }
  return "none";
}

function normalizeDueDate(due: string | null): string | null {
  if (!due) {
    return null;
  }
  return due;
}

function includeCalendarEntry(type: CaptureType, due: string | null, schedule: CaptureRemindSchedule): boolean {
  if (type === "timeline") {
    return true;
  }
  if (due) {
    return true;
  }
  return schedule.checkpoints.length > 0;
}

function buildContentParts(params: {
  inference: CaptureInference;
  now: CaptureDateParts;
  inputText: string;
}): CaptureContentParts {
  const { inference, inputText } = params;
  const reason =
    inference.type === "watch"
      ? "訊息含時間結構且未見強制轉任務指令，先以 watch 追蹤。"
      : inference.type === "action"
        ? "訊息包含明確推進語意，判斷為 action。"
        : inference.type === "question"
          ? "訊息呈現待解問題，先落為 question。"
          : inference.type === "reference"
            ? "訊息含外部連結/資料訊號，判斷為 reference。"
            : inference.type === "idea"
              ? "訊息偏向想法與備忘，先落為 idea。"
              : "訊息偏生活紀錄，先落為 memory。";

  const conservativeLine =
    inference.confidence < 0.65 ? "信心偏低，採保守策略：不自動轉任務、不升級優先級。" : undefined;
  const keyFacts: string[] = [];
  if (inference.due) {
    keyFacts.push(`due: ${inference.due}`);
  }
  if (inference.rawInput.metadata.messageId) {
    keyFacts.push(`message_id: ${inference.rawInput.metadata.messageId}`);
  }
  if (inference.rawInput.metadata.replyTo) {
    keyFacts.push(`reply_to: ${inference.rawInput.metadata.replyTo}`);
  }
  if (inference.rawInput.metadata.groupId) {
    keyFacts.push(`group_id: ${inference.rawInput.metadata.groupId}`);
  }
  return {
    originalText: inputText,
    summaryLine: inference.title,
    rationaleLine: reason,
    conservativeLine,
    nextActionLine: inference.nextBestAction ?? "none",
    keyFacts,
    attachmentLines: inference.attachments,
  };
}

function buildFrontmatter(params: {
  id: string;
  inference: CaptureInference;
  now: CaptureDateParts;
  schedule: CaptureRemindSchedule;
  feedback: CaptureFeedback;
  calendarEntry: boolean;
}): CaptureCardFrontmatter {
  const { id, inference, now, schedule, feedback, calendarEntry } = params;
  return {
    id,
    type: inference.type,
    title: inference.title,
    created: now.ymd,
    source: inference.source,
    priority: inference.priority,
    due: normalizeDueDate(inference.due),
    tags: inference.tags,
    convertToTask: inference.convertToTask,
    longTermMemory: inference.longTermMemory,
    calendarEntry,
    stage: inference.type === "idea" ? "spark" : null,
    qStatus: inference.type === "question" ? "open" : null,
    confidence: inference.confidence,
    alts: [],
    dedupeHint: inference.dedupeHint,
    nextBestAction: inference.nextBestAction,
    links: [],
    attachments: inference.attachments,
    remindSchedule: schedule,
    feedback,
  };
}

function displayHubPath(root: string, absPath: string): string {
  const rel = path.relative(root, absPath).replaceAll(path.sep, "/");
  return `assistant_hub/${rel}`;
}

function isCardMarkdownWrite(op: CaptureFileOp): boolean {
  if (op.op !== "create" && op.op !== "overwrite") {
    return false;
  }
  if (!op.path.endsWith(".md")) {
    return false;
  }
  return op.content.includes("\n## 原文\n") && op.content.includes("\n## 你的整理\n");
}

function buildAgentOutput(params: {
  root: string;
  ops: CaptureFileOp[];
  ack: CaptureAck;
}): { cards: CaptureAgentCardOutput[]; text: string } {
  const { root, ops, ack } = params;
  const cards = ops
    .filter((op) => isCardMarkdownWrite(op))
    .map((op) => ({
      path: displayHubPath(root, op.path),
      content: op.content,
    }));
  const ackText = [ack.line1, ack.line2, ack.line3].filter(Boolean).join("\n");
  const text = [...cards.map((card) => card.content.trimEnd()), ackText].filter(Boolean).join("\n\n");
  return { cards, text };
}

function buildAck(params: {
  root: string;
  mainPath: string;
  inference: CaptureInference;
  schedule: CaptureRemindSchedule;
  merged: boolean;
}): CaptureAck {
  const { root, mainPath, inference, schedule, merged } = params;
  const emoji = typeEmoji(inference.type);
  const conf = inference.confidence.toFixed(2);
  const line1 = merged
    ? `📥 已合併：${emoji} ${inference.type} | ${inference.title} | conf:${conf}`
    : `📥 已收：${emoji} ${inference.type} | ${inference.title} | conf:${conf}`;
  const nextCheckpoint = schedule.checkpoints[0];
  const line2 = nextCheckpoint
    ? `→ ${displayHubPath(root, mainPath)} ⏰ ${nextCheckpoint}`
    : `→ ${displayHubPath(root, mainPath)}`;

  if (inference.confidence >= 0.85) {
    return { line1, line2 };
  }
  const line3 =
    inference.type === "watch"
      ? "回覆：1=轉任務  6=只提醒一次  0=不用提醒了"
      : "回覆：1=轉任務  2=加期限  3=長期記憶  4=拆分  5=合併上一條  0=忽略";
  return { line1, line2, line3 };
}

function buildMemoryLogBlock(params: {
  now: CaptureDateParts;
  inputText: string;
  inference: CaptureInference;
}): string {
  const { now, inputText, inference } = params;
  const tags = inference.tags.join(", ");
  const attachments =
    inference.attachments.length > 0 ? inference.attachments.map((value) => `"${value}"`).join(", ") : "";
  return [
    `## ${now.hm}`,
    `原文：${inputText}`,
    `整理：${inference.title}`,
    `tags：${tags || "none"}`,
    inference.rawInput.metadata.messageId ? `message_id: ${inference.rawInput.metadata.messageId}` : "",
    inference.rawInput.metadata.replyTo ? `reply_to: ${inference.rawInput.metadata.replyTo}` : "",
    inference.rawInput.metadata.groupId ? `group_id: ${inference.rawInput.metadata.groupId}` : "",
    `attachments：${attachments || "none"}`,
    "",
  ]
    .filter(Boolean)
    .join("\n");
}

function buildCalendarLine(params: {
  now: CaptureDateParts;
  title: string;
  type: CaptureType;
  due: string | null;
  schedule: CaptureRemindSchedule;
}): string {
  const { now, title, type, due, schedule } = params;
  const firstDate = due ? due.slice(0, 10) : schedule.checkpoints[0] ?? now.ymd;
  const dueText = due ?? (schedule.checkpoints.length > 0 ? `checkpoints:${schedule.checkpoints.join(",")}` : "none");
  return `| ${escapeTableCell(firstDate)} | ${escapeTableCell(title)} | ${typeEmoji(type)} ${type} | ${escapeTableCell(dueText)} |\n`;
}

function appendLine(value: string): string {
  return value.endsWith("\n") ? value : `${value}\n`;
}

async function buildItemAndOps(params: {
  id: string;
  now: CaptureDateParts;
  inference: CaptureInference;
  root: string;
  mainPath: string;
  pathSet: ReturnType<typeof resolvePathSet>;
  appendReason: AppendMatch["reason"] | null;
}): Promise<{ item: CaptureItem; ops: CaptureFileOp[]; ack: CaptureAck }> {
  const { id, now, inference, root, mainPath, pathSet, appendReason } = params;
  const inputText = inference.rawInput.content;
  const alreadySeenByMessage = appendReason === "already_seen";
  const appendExisting = appendReason !== null && inference.type !== "memory";
  let memoryAlreadySeen = false;
  const schedule = inferRemindSchedule({
    type: inference.type,
    due: inference.due,
    todayYmd: now.ymd,
  });
  const calendarEntry = includeCalendarEntry(inference.type, inference.due, schedule);
  const feedback: CaptureFeedback = {
    token: `fb_${now.ymd.replaceAll("-", "")}_${id.slice(-3)}`,
    watchType: mapWatchType(inference.type),
    expectedHorizonDays: inference.due ? 7 : null,
  };

  const contentParts = buildContentParts({
    inference,
    now,
    inputText,
  });

  const frontmatter = buildFrontmatter({
    id,
    inference,
    now,
    schedule,
    feedback,
    calendarEntry,
  });

  const ops: CaptureFileOp[] = [];
  const inboxEntry = [
    `## ${now.hm}`,
    inputText,
    inference.rawInput.metadata.messageId
      ? `message_id: ${inference.rawInput.metadata.messageId}`
      : "",
    inference.rawInput.metadata.replyTo ? `reply_to: ${inference.rawInput.metadata.replyTo}` : "",
    inference.attachments.length > 0 ? `attachments: ${inference.attachments.join(", ")}` : "",
    "",
  ]
    .filter(Boolean)
    .join("\n");
  ops.push({
    op: "append",
    path: pathSet.inboxPath,
    content: appendLine(inboxEntry),
  });

  if (inference.type === "memory") {
    const existingMemoryLog = await readText(mainPath);
    memoryAlreadySeen = containsMessageRef(existingMemoryLog ?? "", inference.rawInput.metadata.messageId);
    if (!memoryAlreadySeen) {
      ops.push({
        op: "append",
        path: mainPath,
        content: appendLine(buildMemoryLogBlock({ now, inputText, inference })),
      });
    }
  } else if (appendExisting) {
    const existing = await readText(mainPath);
    if (existing !== null) {
      const merged = mergeCardContent({
        existing,
        now,
        inputText,
        inference,
      });
      ops.push({
        op: "overwrite",
        path: mainPath,
        content: merged,
      });
    } else {
      const card = buildCardMarkdown(frontmatter, contentParts);
      ops.push({
        op: "create",
        path: mainPath,
        content: card,
      });
    }
  } else {
    const card = buildCardMarkdown(frontmatter, contentParts);
    ops.push({
      op: "create",
      path: mainPath,
      content: card,
    });
  }

  if (!appendExisting && (inference.type === "action" || inference.type === "watch")) {
    ops.push({
      op: "append",
      path: pathSet.tasksMasterPath,
      content: appendLine(
        `- [ ] ${inference.title} (id:${id}) type:${inference.type} priority:${inference.priority ?? "null"} due:${inference.due ?? "none"} conf:${inference.confidence.toFixed(2)} tags:${inference.tags.join(",")} remind:${schedule.checkpoints.join(",") || "none"}`,
      ),
    });
  }

  if (!appendExisting && inference.type === "watch") {
    ops.push({
      op: "append",
      path: pathSet.waitingPath,
      content: appendLine(
        `- ${inference.title} (id:${id}) due:${inference.due ?? "none"} checkpoints:${schedule.checkpoints.join(",") || "none"} conf:${inference.confidence.toFixed(2)}`,
      ),
    });
  }

  if (!appendExisting && inference.type === "idea") {
    ops.push({
      op: "append",
      path: pathSet.ideasIndexPath,
      content: appendLine(
        `- ${inference.title} (id:${id}) stage:spark conf:${inference.confidence.toFixed(2)} tags:${inference.tags.join(",") || "none"}`,
      ),
    });
  }

  if (!appendExisting && inference.type === "question") {
    ops.push({
      op: "append",
      path: pathSet.questionsIndexPath,
      content: appendLine(
        `- [open] ${inference.title} (id:${id}) conf:${inference.confidence.toFixed(2)} tags:${inference.tags.join(",") || "none"}`,
      ),
    });
  }

  if (!appendExisting && inference.type === "belief") {
    ops.push({
      op: "append",
      path: pathSet.beliefsIndexPath,
      content: appendLine(
        `- ${inference.title} (id:${id}) v1 conf:${inference.confidence.toFixed(2)} tags:${inference.tags.join(",") || "none"}`,
      ),
    });
  }

  const messageReplay = alreadySeenByMessage || memoryAlreadySeen;
  const queueEntry = {
    token: feedback.token,
    id,
    type: inference.type,
    priority: inference.priority,
    tags: inference.tags,
    confidence: Number(inference.confidence.toFixed(2)),
    calendar_entry: calendarEntry,
    due: inference.due ? inference.due.slice(0, 10) : null,
    checkpoints: schedule.checkpoints,
    auto_archive_after: schedule.autoArchiveAfter,
    ts: now.isoWithOffset,
    consumed: false,
  };
  if (!appendExisting && !messageReplay) {
    ops.push({
      op: "append",
      path: pathSet.reasoningQueuePath,
      content: appendLine(JSON.stringify(queueEntry)),
    });
  }

  if (calendarEntry && !appendExisting && !messageReplay) {
    ops.push({
      op: "append",
      path: pathSet.calendarPath,
      content: buildCalendarLine({
        now,
        title: inference.title,
        type: inference.type,
        due: inference.due,
        schedule,
      }),
    });
  }

  const item: CaptureItem = {
    id,
    type: inference.type,
    title: inference.title,
    priority: inference.priority,
    due: inference.due,
    tags: inference.tags,
    convertToTask: inference.convertToTask,
    longTermMemory: inference.longTermMemory,
    calendarEntry,
    stage: inference.type === "idea" ? "spark" : null,
    qStatus: inference.type === "question" ? "open" : null,
    confidence: Number(inference.confidence.toFixed(2)),
    alts: [],
    dedupeHint: appendExisting || messageReplay ? "append_existing" : inference.dedupeHint,
    nextBestAction: inference.nextBestAction,
    mainPath: displayHubPath(root, mainPath),
    attachments: inference.attachments,
    remindSchedule: schedule,
    feedback,
    links: [],
    files: ops,
  };

  const ack = buildAck({
    root,
    mainPath,
    inference,
    schedule,
    merged: appendExisting || messageReplay,
  });

  return { item, ops, ack };
}

export async function runCaptureAgent(params: CaptureAgentRunParams): Promise<CaptureRunOutput> {
  const requestedOutputMode = (params.outputMode ?? process.env.OUTPUT_MODE ?? "json").toLowerCase();
  const outputMode = requestedOutputMode === "agent" ? "agent" : "json";

  const ts = parseTimestamp(params.input.metadata.timestamp);
  const now = getDateParts(ts);
  const hubPaths = resolveHubPaths();
  await ensureHubPaths(hubPaths);
  await ensureHubScaffoldFiles(hubPaths);

  const classifierContext = await buildClassifierContext({
    hubPaths,
    now,
  });
  const inferenceRaw = classifyCaptureInput(params.input, now, classifierContext);
  const appendMatch = await findAppendTarget({
    hubPaths,
    inference: inferenceRaw,
    nowTs: ts,
  });
  const id = appendMatch ? (extractIdFromPath(appendMatch.path) ?? (await nextDailyId(hubPaths, now))) : await nextDailyId(hubPaths, now);
  const slug = slugifyTitle(inferenceRaw.title, inferenceRaw.type);
  const mainPath =
    appendMatch?.path ??
    resolveMainPath({
      id,
      slug,
      type: inferenceRaw.type,
      paths: hubPaths,
      now,
    });
  const inference: CaptureInference = {
    ...inferenceRaw,
    dedupeHint: appendMatch ? "append_existing" : inferenceRaw.dedupeHint,
  };
  const pathSet = resolvePathSet(hubPaths, now, inference.source);

  const built = await buildItemAndOps({
    id,
    now,
    inference,
    root: hubPaths.root,
    mainPath,
    pathSet,
    appendReason: appendMatch?.reason ?? null,
  });

  if (params.applyWrites) {
    await applyFileOps(built.ops);
  }

  const base: CaptureJsonOutput = {
    timezone: "Asia/Shanghai",
    date: now.ymd,
    source: inference.source,
    ack: built.ack,
    items: [built.item],
  };
  if (outputMode === "agent") {
    return {
      ...base,
      outputMode: "agent",
      agent: buildAgentOutput({
        root: hubPaths.root,
        ops: built.ops,
        ack: built.ack,
      }),
    };
  }
  return base;
}
