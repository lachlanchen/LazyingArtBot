import type { CaptureInput } from "../adapters/capture-input.js";
import type { CaptureDateParts, CaptureInference, CapturePriority, CaptureRemindSchedule } from "./types.js";

export type CaptureClassifierContext = {
  recentText?: string;
  knownTags?: string[];
};

const HARD_NO_TASK_TERMS = [
  "不要變成待辦",
  "先別推進",
  "不用做",
  "只是記一下",
  "不用提醒",
];

const HARD_FORCE_TASK_TERMS = ["轉任務", "推進", "今天要做", "請提醒", "幫我跟進"];

const HARD_LONG_TERM_TERMS = ["long-term", "永久記錄", "長期記憶", "釘住", "pin"];
const URGENT_PRIORITY_TERMS = ["緊急", "urgent", "asap", "立即", "馬上", "马上"];
const IMPORTANT_PRIORITY_TERMS = ["重要", "關鍵", "关键", "高優先", "high priority"];
const LATER_PRIORITY_TERMS = ["有空", "之後", "之后", "later", "someday", "低優先"];

const TIMELINE_TERMS = [
  "timeline",
  "時間線",
  "时间线",
  "里程碑",
  "milestone",
  "roadmap",
  "階段",
  "阶段",
  "phase",
  "sprint",
  "迭代",
  "版本規劃",
  "版本规划",
];
const BELIEF_TERMS = ["我相信", "我認為", "我认为", "信念", "原則", "原则", "價值觀", "价值观", "底層邏輯", "方法論", "方法论"];
const HIGHLIGHT_TERMS = ["重點", "重点", "精華", "精华", "亮點", "亮点", "金句", "摘錄", "摘录", "highlight", "收藏這句", "mark this"];
const IDEA_TERMS = ["想法", "idea", "點子", "点子", "靈感", "灵感", "腦洞", "脑洞", "構思", "构思", "試試", "尝试", "prototype"];
const QUESTION_TERMS = ["如何", "怎麼", "怎么", "是否", "能不能", "可不可以", "why", "what", "how"];
const REFERENCE_TERMS = ["參考", "参考", "文檔", "文档", "連結", "链接", "paper", "repo", "readme", "資料來源", "资料来源"];
const DUE_INTENT_TERMS = ["提醒", "截止", "到期", "due", "before", "之前", "跟進", "跟进", "完成", "交付", "review", "check"];
const PERSON_HINT_TERMS = [
  "朋友",
  "同事",
  "客戶",
  "客户",
  "老師",
  "老师",
  "醫生",
  "医生",
  "mentor",
  "hr",
  "recruiter",
  "夥伴",
  "伙伴",
];
const PERSON_ACTION_TERMS = ["聯絡", "联系", "跟進", "跟进", "回覆", "回复", "對齊", "对齐", "聊", "談", "谈", "見面", "见面", "約", "约", "介紹", "介绍"];

const URL_RE = /https?:\/\/\S+/i;
const QUESTION_RE = /[?？]/;
const PRIORITY_RE = /\bP([0-3])\b/i;
const ISO_DUE_RE = /\b(20\d{2}-\d{2}-\d{2})(?:[ T](\d{2}:\d{2}))?\b/;
const MD_DUE_RE = /\b(\d{1,2})[/-](\d{1,2})(?:\s+(\d{1,2}:\d{2}))?\b/;
const ZH_REL_DUE_RE = /(今天|明天|後天|后天)(?:\s*(\d{1,2}:\d{2}))?/;
const EN_REL_DUE_RE = /\b(today|tomorrow|tmr|day after tomorrow)\b(?:\s+(\d{1,2}:\d{2}))?/i;
const TIMELINE_RANGE_RE = /\b\d{1,2}[/-]\d{1,2}\s*[-~～至到]\s*\d{1,2}[/-]\d{1,2}\b/;

function containsAny(text: string, terms: string[]): boolean {
  const lower = text.toLowerCase();
  return terms.some((term) => lower.includes(term.toLowerCase()));
}

function parseYmd(ymd: string): Date {
  const [year, month, day] = ymd.split("-").map((part) => Number(part));
  return new Date(Date.UTC(year, month - 1, day));
}

function shiftYmd(ymd: string, days: number): string {
  const date = parseYmd(ymd);
  date.setUTCDate(date.getUTCDate() + days);
  const year = date.getUTCFullYear();
  const month = String(date.getUTCMonth() + 1).padStart(2, "0");
  const day = String(date.getUTCDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function parseHm(raw: string | undefined): string | null {
  if (!raw) {
    return null;
  }
  const hit = raw.trim().match(/^(\d{1,2}):(\d{2})$/);
  if (!hit?.[1] || !hit[2]) {
    return null;
  }
  const hour = Number(hit[1]);
  const minute = Number(hit[2]);
  if (!Number.isFinite(hour) || !Number.isFinite(minute) || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    return null;
  }
  return `${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}`;
}

function isValidMonthDay(month: number, day: number): boolean {
  if (!Number.isFinite(month) || !Number.isFinite(day)) {
    return false;
  }
  if (month < 1 || month > 12 || day < 1 || day > 31) {
    return false;
  }
  const date = new Date(Date.UTC(2026, month - 1, day));
  return date.getUTCMonth() + 1 === month && date.getUTCDate() === day;
}

function hasDueIntent(text: string): boolean {
  return containsAny(text, DUE_INTENT_TERMS);
}

function extractPriority(text: string): CapturePriority {
  const hit = text.match(PRIORITY_RE);
  if (!hit) {
    if (containsAny(text, URGENT_PRIORITY_TERMS)) {
      return "P0";
    }
    if (containsAny(text, IMPORTANT_PRIORITY_TERMS)) {
      return "P1";
    }
    if (containsAny(text, LATER_PRIORITY_TERMS)) {
      return "P2";
    }
    return null;
  }
  const level = hit[1];
  return level ? (`P${level}` as CapturePriority) : null;
}

function extractDue(text: string, todayYmd: string): string | null {
  const hit = text.match(ISO_DUE_RE);
  if (!hit) {
    const zhHit = text.match(ZH_REL_DUE_RE);
    if (zhHit?.[1]) {
      if (!hasDueIntent(text)) {
        return null;
      }
      const key = zhHit[1];
      const hm = parseHm(zhHit[2]);
      const offset = key === "今天" ? 0 : key === "明天" ? 1 : 2;
      const ymd = shiftYmd(todayYmd, offset);
      return hm ? `${ymd} ${hm}` : ymd;
    }
    const enHit = text.match(EN_REL_DUE_RE);
    if (enHit?.[1]) {
      if (!hasDueIntent(text)) {
        return null;
      }
      const key = enHit[1].toLowerCase();
      const hm = parseHm(enHit[2]);
      const offset = key === "today" ? 0 : key === "day after tomorrow" ? 2 : 1;
      const ymd = shiftYmd(todayYmd, offset);
      return hm ? `${ymd} ${hm}` : ymd;
    }
    const mdHit = text.match(MD_DUE_RE);
    if (!mdHit?.[1] || !mdHit[2]) {
      return null;
    }
    const month = Number(mdHit[1]);
    const day = Number(mdHit[2]);
    if (!isValidMonthDay(month, day)) {
      return null;
    }
    const hm = parseHm(mdHit[3]);
    const current = parseYmd(todayYmd);
    const currentYear = current.getUTCFullYear();
    let candidate = new Date(Date.UTC(currentYear, month - 1, day));
    if (candidate < current) {
      candidate = new Date(Date.UTC(currentYear + 1, month - 1, day));
    }
    const y = candidate.getUTCFullYear();
    const m = String(candidate.getUTCMonth() + 1).padStart(2, "0");
    const d = String(candidate.getUTCDate()).padStart(2, "0");
    const ymd = `${y}-${m}-${d}`;
    return hm ? `${ymd} ${hm}` : ymd;
  }
  const date = hit[1];
  const hm = parseHm(hit[2] ?? undefined);
  return hm ? `${date} ${hm}` : date;
}

function normalizeTitle(raw: string, fallbackType: string): string {
  const firstLine = raw
    .split(/\r?\n/)
    .map((line) => line.trim())
    .find((line) => line.length > 0);

  const value = (firstLine ?? `${fallbackType} note`)
    .replace(URL_RE, "")
    .replace(/[【】\[\]{}()]/g, " ")
    .replace(/\s+/g, " ")
    .trim();

  if (!value) {
    return `${fallbackType} note`;
  }
  return value.length <= 18 ? value : value.slice(0, 18);
}

function normalizeSearchKey(input: string): string {
  return input
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function hasContextHit(params: {
  content: string;
  title: string;
  contextText: string;
}): boolean {
  const { content, title, contextText } = params;
  if (!contextText) {
    return false;
  }
  const titleKey = normalizeSearchKey(title);
  if (titleKey.length >= 6 && contextText.includes(titleKey)) {
    return true;
  }
  const contentKey = normalizeSearchKey(content).slice(0, 48);
  return contentKey.length >= 10 ? contextText.includes(contentKey) : false;
}

function matchContextTags(content: string, knownTags: string[]): string[] {
  if (knownTags.length === 0) {
    return [];
  }
  const contentLower = content.toLowerCase();
  const matched: string[] = [];
  for (const rawTag of knownTags) {
    const tag = rawTag.trim().replace(/^#/, "");
    if (!tag) {
      continue;
    }
    if (contentLower.includes(tag.toLowerCase())) {
      matched.push(tag);
    }
    if (matched.length >= 3) {
      break;
    }
  }
  return matched;
}

function hasTimelineSignal(content: string): boolean {
  if (TIMELINE_RANGE_RE.test(content)) {
    return true;
  }
  if (/\bQ[1-4]\b/i.test(content)) {
    return true;
  }
  return containsAny(content, TIMELINE_TERMS);
}

function hasPersonSignal(content: string): boolean {
  if (/(?:和|跟|與|与)\s*[@\p{L}\p{N}_-]{1,24}\s*(?:聊|談|谈|對齊|对齐|跟進|跟进|聯絡|联系|見面|见面|約|约|回覆|回复)/u.test(content)) {
    return true;
  }
  const hasHint = containsAny(content, PERSON_HINT_TERMS) || /@\w{2,}/.test(content);
  const hasAction = containsAny(content, PERSON_ACTION_TERMS);
  return hasHint && hasAction;
}

function hasQuestionSignal(content: string): boolean {
  return QUESTION_RE.test(content) || containsAny(content, QUESTION_TERMS);
}

function inferType(params: {
  convertToTask: boolean;
  due: string | null;
  hasNoTaskSignal: boolean;
  timelineSignal: boolean;
  personSignal: boolean;
  beliefSignal: boolean;
  highlightSignal: boolean;
  questionSignal: boolean;
  referenceSignal: boolean;
  ideaSignal: boolean;
}): CaptureInference["type"] {
  const {
    convertToTask,
    due,
    hasNoTaskSignal,
    timelineSignal,
    personSignal,
    beliefSignal,
    highlightSignal,
    questionSignal,
    referenceSignal,
    ideaSignal,
  } = params;
  if (convertToTask) {
    return "action";
  }
  if (timelineSignal) {
    return "timeline";
  }
  if (personSignal) {
    return "person";
  }
  if (due) {
    return "watch";
  }
  if (questionSignal) {
    return "question";
  }
  if (referenceSignal) {
    return "reference";
  }
  if (beliefSignal) {
    return "belief";
  }
  if (highlightSignal) {
    return "highlight";
  }
  if (hasNoTaskSignal || ideaSignal) {
    return "idea";
  }
  return "memory";
}

function inferConfidence(params: {
  type: CaptureInference["type"];
  convertToTask: boolean;
  hardTask: boolean;
  hardNoTask: boolean;
  due: string | null;
}): number {
  const { type, convertToTask, hardTask, hardNoTask, due } = params;
  if (hardTask) {
    return 0.9;
  }
  if (hardNoTask && !convertToTask) {
    return 0.86;
  }
  if (type === "timeline") {
    return 0.84;
  }
  if (type === "person") {
    return due ? 0.85 : 0.8;
  }
  if (type === "watch" && due) {
    return 0.84;
  }
  if (type === "question" || type === "reference") {
    return 0.78;
  }
  if (type === "belief" || type === "highlight") {
    return 0.77;
  }
  if (type === "idea") {
    return 0.76;
  }
  if (type === "action") {
    return 0.74;
  }
  return 0.7;
}

function buildAttachmentDescriptions(input: CaptureInput): string[] {
  const out: string[] = [];
  for (let i = 0; i < input.attachments.length; i += 1) {
    const item = input.attachments[i];
    const ordinal = i + 1;
    const prefix =
      item.type === "image"
        ? `[圖${ordinal}]`
        : item.type === "audio"
          ? "[語音]"
          : item.type === "video"
            ? "[視頻]"
            : item.type === "text"
              ? "[文字]"
              : `[附件${ordinal}]`;
    const description =
      item.semanticDesc ??
      (item.transcript ? `逐字稿：${item.transcript}` : `file:${item.fileRef}`.slice(0, 220));
    out.push(`${prefix} ${description}`.trim());
  }
  return out;
}

function inferNextAction(params: {
  type: CaptureInference["type"];
  due: string | null;
  content: string;
}): string | null {
  const { type, due, content } = params;
  if (type === "action") {
    return due ? `在 ${due} 前完成第一個可交付版本。` : "拆成一個 25 分鐘可完成的小步驟並立即開始。";
  }
  if (type === "timeline") {
    return "補上 2~3 個里程碑日期與每個里程碑的完成定義。";
  }
  if (type === "person") {
    return due ? `在 ${due} 前完成一次明確跟進並記錄結果。` : "補一行關係背景與下一次跟進時點。";
  }
  if (type === "watch") {
    return due ? `在下一個 checkpoint 重新評估是否轉任務（截止 ${due}）。` : "保留觀察，等新訊號後再決定是否轉任務。";
  }
  if (type === "question") {
    return "先列出 3 個已知事實與 1 個待驗證假設。";
  }
  if (type === "reference") {
    return "補 2 行你想從這份資料拿走的重點，方便未來檢索。";
  }
  if (type === "belief") {
    return "寫下 1 個支持例與 1 個反例，避免信念過度泛化。";
  }
  if (type === "highlight") {
    return "補上來源與情境，確保未來回看時知道為何重要。";
  }
  if (type === "idea") {
    return "用一句話定義價值與使用場景，再決定是否升級成任務。";
  }
  if (content.length > 200) {
    return "抽出最關鍵的一句觀察，避免資訊沉沒。";
  }
  return null;
}

export function classifyCaptureInput(
  input: CaptureInput,
  now: CaptureDateParts,
  context: CaptureClassifierContext = {},
): CaptureInference {
  const content = input.content.trim();
  const recentContext = normalizeSearchKey(context.recentText ?? "");
  const hardNoTask = containsAny(content, HARD_NO_TASK_TERMS);
  const hardTask = containsAny(content, HARD_FORCE_TASK_TERMS);
  const longTerm = containsAny(content, HARD_LONG_TERM_TERMS);
  const convertToTask = hardTask ? true : hardNoTask ? false : false;
  const priority = extractPriority(content);
  const due = extractDue(content, now.ymd);
  const timelineSignal = hasTimelineSignal(content);
  const personSignal = hasPersonSignal(content);
  const beliefSignal = containsAny(content, BELIEF_TERMS);
  const highlightSignal = containsAny(content, HIGHLIGHT_TERMS);
  const questionSignal = hasQuestionSignal(content);
  const referenceSignal = URL_RE.test(content) || containsAny(content, REFERENCE_TERMS);
  const ideaSignal = containsAny(content, IDEA_TERMS);

  const type = inferType({
    convertToTask,
    due,
    hasNoTaskSignal: hardNoTask,
    timelineSignal,
    personSignal,
    beliefSignal,
    highlightSignal,
    questionSignal,
    referenceSignal,
    ideaSignal,
  });
  const title = normalizeTitle(content, type);
  const confidenceBase = inferConfidence({
    type,
    convertToTask,
    hardTask,
    hardNoTask,
    due,
  });
  const contextHit = hasContextHit({
    content,
    title,
    contextText: recentContext,
  });
  const confidence = Math.max(0.55, confidenceBase - (contextHit ? 0.08 : 0));
  const dedupeHint = contextHit || confidence < 0.65 ? "possible_duplicate" : "new";

  const tagSet = new Set<string>();
  if (referenceSignal) {
    tagSet.add("link");
  }
  if (due) {
    tagSet.add("deadline");
  }
  if (type === "action") {
    tagSet.add("execution");
  }
  if (type === "watch") {
    tagSet.add("watch");
  }
  if (type === "question") {
    tagSet.add("question");
  }
  if (type === "timeline") {
    tagSet.add("timeline");
  }
  if (type === "person") {
    tagSet.add("people");
  }
  if (type === "belief") {
    tagSet.add("belief");
  }
  if (type === "highlight") {
    tagSet.add("highlight");
  }
  if (type === "idea") {
    tagSet.add("idea");
  }
  const contextTags = matchContextTags(content, context.knownTags ?? []);
  for (const tag of contextTags) {
    tagSet.add(tag);
  }

  const platform = input.metadata.platform.trim().toLowerCase();
  const source =
    platform === "feishu" || platform === "lark"
      ? "feishu"
      : platform === "whatsapp"
        ? "whatsapp"
        : platform === "wechat" || platform === "weixin" || platform === "wechatbot"
          ? "wechat"
        : platform === "email" || platform === "mail"
          ? "email"
        : platform === "telegram"
          ? "telegram"
          : "generic";

  return {
    type,
    priority,
    due,
    convertToTask,
    longTermMemory: longTerm,
    confidence,
    dedupeHint,
    nextBestAction: inferNextAction({ type, due, content }),
    title,
    tags: [...tagSet].slice(0, 8),
    attachments: buildAttachmentDescriptions(input),
    source,
    rawInput: input,
  };
}

function toDateOnly(input: string): string {
  return input.slice(0, 10);
}

function dayDiff(fromYmd: string, toYmd: string): number {
  const from = parseYmd(fromYmd);
  const to = parseYmd(toYmd);
  const diffMs = to.getTime() - from.getTime();
  return Math.round(diffMs / (24 * 60 * 60 * 1000));
}

function shiftDate(ymd: string, days: number): string {
  const base = parseYmd(ymd);
  base.setUTCDate(base.getUTCDate() + days);
  const year = base.getUTCFullYear();
  const month = String(base.getUTCMonth() + 1).padStart(2, "0");
  const day = String(base.getUTCDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

export function inferRemindSchedule(params: {
  type: CaptureInference["type"];
  due: string | null;
  todayYmd: string;
}): CaptureRemindSchedule {
  const { type, due, todayYmd } = params;
  if (type !== "watch" && type !== "person" && type !== "action") {
    return {
      mode: "none",
      checkpoints: [],
      autoArchiveAfter: null,
    };
  }

  if (!due) {
    return {
      mode: "none",
      checkpoints: [],
      autoArchiveAfter: null,
    };
  }

  const dueYmd = toDateOnly(due);
  const days = dayDiff(todayYmd, dueYmd);
  const offsets =
    days > 30
      ? [14]
      : days >= 15
        ? [14, 3]
        : days >= 7
          ? [7, 3, 1]
          : [-3, -1, 0];
  const checkpoints = offsets
    .map((offset) => (offset >= 0 ? shiftDate(dueYmd, -offset) : shiftDate(dueYmd, offset)))
    .filter((value, index, all) => all.indexOf(value) === index)
    .sort();

  return {
    mode: "auto",
    checkpoints,
    autoArchiveAfter: dueYmd,
  };
}
