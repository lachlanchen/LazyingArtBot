#!/usr/bin/env -S node --import tsx
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";

type PriorityLabel = "P0" | "P1" | "P2" | "P3";
type Bucket = "important" | "useful" | "ignored";

type GmailMessage = {
  id: string;
  from?: string;
  subject?: string;
  snippet?: string;
  labels?: string[];
};

type GmailSearchResponse = {
  messages?: GmailMessage[];
  nextPageToken?: string;
};

type GmailDigestPreferences = {
  profileName: string;
  role: string;
  focus: string[];
  importantSenders: string[];
  importantDomains: string[];
  mutedSenders: string[];
  mutedDomains: string[];
  boostKeywords: string[];
  muteKeywords: string[];
};

const URGENT_KEYWORDS = [
  "urgent",
  "asap",
  "immediately",
  "today",
  "tonight",
  "overdue",
  "deadline",
  "action required",
  "confirm by",
  "payment due",
  "invoice due",
  "security alert",
  "verification code",
  "2fa",
  "緊急",
  "紧急",
  "盡快",
  "尽快",
  "今天",
  "今晚",
  "逾期",
  "截止",
  "需回覆",
  "需要回覆",
  "付款",
  "發票",
  "发票",
  "安全",
  "驗證碼",
  "验证码",
];

const ACTION_KEYWORDS = [
  "meeting",
  "schedule",
  "appointment",
  "interview",
  "contract",
  "proposal",
  "follow up",
  "review",
  "approve",
  "request",
  "會議",
  "会议",
  "面試",
  "面试",
  "安排",
  "確認",
  "确认",
  "回覆",
  "回复",
  "審核",
  "审核",
  "申請",
  "申请",
  "合作",
];

const USEFUL_KEYWORDS = [
  "receipt",
  "invoice",
  "statement",
  "subscription",
  "bill",
  "report",
  "summary",
  "update",
  "agenda",
  "minutes",
  "收據",
  "收据",
  "賬單",
  "账单",
  "報告",
  "报告",
  "摘要",
  "更新",
  "議程",
  "议程",
  "紀要",
  "纪要",
];

const IGNORE_KEYWORDS = [
  "newsletter",
  "promotion",
  "promotional",
  "discount",
  "sale",
  "unsubscribe",
  "marketing",
  "ad",
  "coupon",
  "deal",
  "促銷",
  "促销",
  "優惠",
  "优惠",
  "折扣",
  "廣告",
  "广告",
  "退訂",
  "退订",
  "電子報",
  "电子报",
];

const DEFAULT_GMAIL_PREFERENCES: GmailDigestPreferences = {
  profileName: "developer-default",
  role: "software_developer",
  focus: ["交付", "代碼審查", "上線告警", "會議", "付款合約"],
  importantSenders: [],
  importantDomains: [
    "github.com",
    "gitlab.com",
    "atlassian.com",
    "linear.app",
    "sentry.io",
    "stripe.com",
    "aws.amazon.com",
    "google.com",
  ],
  mutedSenders: [],
  mutedDomains: [],
  boostKeywords: [
    "action required",
    "production",
    "incident",
    "outage",
    "deploy",
    "rollback",
    "build failed",
    "ci failed",
    "security alert",
    "code review",
    "pull request",
    "deadline",
    "meeting",
    "invoice",
    "contract",
    "需要回覆",
    "需回覆",
    "故障",
    "告警",
    "上線",
    "部署",
    "回滾",
    "審核",
    "審批",
    "會議",
    "發票",
    "付款",
    "截止",
  ],
  muteKeywords: [
    "newsletter",
    "promotion",
    "discount",
    "sale",
    "unsubscribe",
    "marketing",
    "電子報",
    "促銷",
    "優惠",
    "折扣",
    "廣告",
    "退訂",
  ],
};

function safeLower(value: string): string {
  return value.toLowerCase();
}

function hitKeywords(haystack: string, keywords: string[]): string[] {
  return keywords.filter((kw) => haystack.includes(kw.toLowerCase()));
}

function normalizeList(value: unknown, fallback: string[]): string[] {
  if (!Array.isArray(value)) {
    return [...fallback];
  }
  const out = value
    .map((item) => (typeof item === "string" ? item.trim().toLowerCase() : ""))
    .filter((item) => item.length > 0);
  return Array.from(new Set(out));
}

function normalizeFocusList(value: unknown, fallback: string[]): string[] {
  if (!Array.isArray(value)) {
    return [...fallback];
  }
  const out = value
    .map((item) => (typeof item === "string" ? item.trim() : ""))
    .filter((item) => item.length > 0);
  return Array.from(new Set(out));
}

function normalizePreferences(raw: Partial<GmailDigestPreferences> | null): GmailDigestPreferences {
  return {
    profileName:
      typeof raw?.profileName === "string" && raw.profileName.trim().length > 0
        ? raw.profileName.trim()
        : DEFAULT_GMAIL_PREFERENCES.profileName,
    role:
      typeof raw?.role === "string" && raw.role.trim().length > 0
        ? raw.role.trim()
        : DEFAULT_GMAIL_PREFERENCES.role,
    focus: normalizeFocusList(raw?.focus, DEFAULT_GMAIL_PREFERENCES.focus),
    importantSenders: normalizeList(raw?.importantSenders, DEFAULT_GMAIL_PREFERENCES.importantSenders),
    importantDomains: normalizeList(raw?.importantDomains, DEFAULT_GMAIL_PREFERENCES.importantDomains),
    mutedSenders: normalizeList(raw?.mutedSenders, DEFAULT_GMAIL_PREFERENCES.mutedSenders),
    mutedDomains: normalizeList(raw?.mutedDomains, DEFAULT_GMAIL_PREFERENCES.mutedDomains),
    boostKeywords: normalizeList(raw?.boostKeywords, DEFAULT_GMAIL_PREFERENCES.boostKeywords),
    muteKeywords: normalizeList(raw?.muteKeywords, DEFAULT_GMAIL_PREFERENCES.muteKeywords),
  };
}

function parseEmailFromHeader(from: string): string {
  const hit = from.match(/[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}/i);
  if (hit?.[0]) {
    return hit[0].toLowerCase();
  }
  return from.trim().toLowerCase();
}

function parseDomainFromEmail(email: string): string {
  const idx = email.lastIndexOf("@");
  if (idx < 0 || idx === email.length - 1) {
    return "";
  }
  return email.slice(idx + 1).toLowerCase();
}

function classifyMessage(
  msg: GmailMessage,
  preferences: GmailDigestPreferences,
): { bucket: Bucket; priority: PriorityLabel; score: number } {
  const from = msg.from ?? "";
  const subject = msg.subject ?? "";
  const snippet = msg.snippet ?? "";
  const haystack = safeLower(`${from} ${subject} ${snippet}`);

  const urgentHits = hitKeywords(haystack, URGENT_KEYWORDS);
  const actionHits = hitKeywords(haystack, ACTION_KEYWORDS);
  const usefulHits = hitKeywords(haystack, USEFUL_KEYWORDS);
  const ignoreHits = hitKeywords(haystack, IGNORE_KEYWORDS);
  const prefBoostHits = hitKeywords(haystack, preferences.boostKeywords);
  const prefMuteHits = hitKeywords(haystack, preferences.muteKeywords);

  const senderEmail = parseEmailFromHeader(from);
  const senderDomain = parseDomainFromEmail(senderEmail);

  let score = 0;
  if (urgentHits.length > 0) {
    score += 3;
  }
  if (actionHits.length > 0) {
    score += 2;
  }
  if (usefulHits.length > 0) {
    score += 1;
  }
  if (ignoreHits.length > 0) {
    score -= 2;
  }
  if (/\b(no-?reply|noreply)\b/i.test(from)) {
    score -= 1;
  }
  if (prefBoostHits.length > 0) {
    score += Math.min(4, prefBoostHits.length);
  }
  if (prefMuteHits.length > 0) {
    score -= Math.min(4, prefMuteHits.length + 1);
  }
  if (preferences.importantSenders.includes(senderEmail)) {
    score += 4;
  }
  if (senderDomain && preferences.importantDomains.includes(senderDomain)) {
    score += 2;
  }
  if (preferences.mutedSenders.includes(senderEmail)) {
    score -= 4;
  }
  if (senderDomain && preferences.mutedDomains.includes(senderDomain)) {
    score -= 3;
  }

  let bucket: Bucket = "ignored";
  let priority: PriorityLabel = "P3";
  if (score >= 5) {
    bucket = "important";
    priority = "P0";
  } else if (score >= 3) {
    bucket = "important";
    priority = "P1";
  } else if (score >= 1) {
    bucket = "useful";
    priority = "P2";
  }

  return { bucket, priority, score };
}

const RETRY_COUNT_RAW = Number(process.env.CAPTURE_GMAIL_CLASSIFY_RETRY_COUNT ?? "6");
const RETRY_COUNT =
  Number.isFinite(RETRY_COUNT_RAW) && RETRY_COUNT_RAW >= 0
    ? Math.min(12, Math.floor(RETRY_COUNT_RAW))
    : 6;
const RETRY_BASE_MS_RAW = Number(process.env.CAPTURE_GMAIL_CLASSIFY_RETRY_BASE_MS ?? "1500");
const RETRY_BASE_MS =
  Number.isFinite(RETRY_BASE_MS_RAW) && RETRY_BASE_MS_RAW > 0
    ? Math.max(250, Math.floor(RETRY_BASE_MS_RAW))
    : 1500;

function sleepMs(ms: number): void {
  if (!(ms > 0)) {
    return;
  }
  const sec = Math.max(0.05, ms / 1000);
  spawnSync("bash", ["-lc", `sleep ${sec.toFixed(3)}`], {
    encoding: "utf8",
    env: process.env,
  });
}

function shouldRetryGogFailure(msg: string): boolean {
  const lower = msg.toLowerCase();
  return (
    lower.includes("client.timeout exceeded") ||
    lower.includes("request canceled") ||
    lower.includes("context deadline exceeded") ||
    lower.includes("connection reset by peer") ||
    lower.includes("temporary failure") ||
    lower.includes("i/o timeout") ||
    lower.includes("tls handshake timeout") ||
    lower.includes("rate limit") ||
    lower.includes("status code 429") ||
    lower.includes("status code 500") ||
    lower.includes("status code 502") ||
    lower.includes("status code 503") ||
    lower.includes("status code 504")
  );
}

function runGogJson(args: string[]): unknown {
  for (let attempt = 0; attempt <= RETRY_COUNT; attempt += 1) {
    const run = spawnSync("gog", args, {
      encoding: "utf8",
      env: process.env,
    });
    if (run.status === 0) {
      const raw = run.stdout.trim();
      if (!raw) {
        return {};
      }
      return JSON.parse(raw) as unknown;
    }

    const msg = (run.stderr || run.stdout || `exit_${run.status ?? "unknown"}`).trim();
    if (attempt < RETRY_COUNT && shouldRetryGogFailure(msg)) {
      const delayMs = RETRY_BASE_MS * 2 ** attempt;
      const cmdHint = args.slice(0, 3).join(" ");
      console.log(
        `classify:retry attempt=${attempt + 1}/${RETRY_COUNT} delay_ms=${delayMs} cmd=${JSON.stringify(cmdHint)} reason=${JSON.stringify(msg.slice(0, 220))}`,
      );
      sleepMs(delayMs);
      continue;
    }

    throw new Error(`gog ${args.join(" ")} failed: ${msg}`);
  }

  throw new Error(`gog ${args.join(" ")} failed: exceeded_retry_limit`);
}

function chunkArray<T>(arr: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < arr.length; i += size) {
    out.push(arr.slice(i, i + size));
  }
  return out;
}

async function loadPreferences(preferencePath: string): Promise<GmailDigestPreferences> {
  try {
    const raw = await fs.readFile(preferencePath, "utf8");
    const parsed = JSON.parse(raw) as Partial<GmailDigestPreferences>;
    return normalizePreferences(parsed);
  } catch {
    return normalizePreferences(null);
  }
}

function ensureLabelExists(account: string, name: string): void {
  const labelsData = runGogJson([
    "gmail",
    "labels",
    "list",
    "--account",
    account,
    "--json",
  ]) as { labels?: Array<{ name?: string }> };
  const exists = (labelsData.labels ?? []).some((label) => String(label.name ?? "") === name);
  if (exists) {
    return;
  }
  runGogJson([
    "gmail",
    "labels",
    "create",
    name,
    "--account",
    account,
    "--json",
  ]);
}

function applyBatchModify(params: {
  account: string;
  ids: string[];
  add: string[];
  remove: string[];
  dryRun: boolean;
}): number {
  const { account, ids, add, remove, dryRun } = params;
  if (ids.length === 0 || (add.length === 0 && remove.length === 0)) {
    return 0;
  }
  if (dryRun) {
    return ids.length;
  }
  let touched = 0;
  for (const chunk of chunkArray(ids, 80)) {
    const args = ["gmail", "batch", "modify", ...chunk, "--account", account, "--json"];
    if (add.length > 0) {
      args.push("--add", add.join(","));
    }
    if (remove.length > 0) {
      args.push("--remove", remove.join(","));
    }
    runGogJson(args);
    touched += chunk.length;
  }
  return touched;
}

async function main() {
  const account = (process.env.CAPTURE_GMAIL_CLASSIFY_ACCOUNT ?? "sou350121@gmail.com").trim();
  const pageSizeRaw = Number(process.env.CAPTURE_GMAIL_CLASSIFY_PAGE_SIZE ?? "200");
  const pageSize = Number.isFinite(pageSizeRaw) && pageSizeRaw > 0 ? Math.floor(pageSizeRaw) : 200;
  const maxPagesRaw = Number(process.env.CAPTURE_GMAIL_CLASSIFY_MAX_PAGES ?? "300");
  const maxPages = Number.isFinite(maxPagesRaw) && maxPagesRaw > 0 ? Math.floor(maxPagesRaw) : 300;
  const query =
    (
      process.env.CAPTURE_GMAIL_CLASSIFY_QUERY ??
      "in:anywhere -in:trash -in:spam -in:drafts -in:sent"
    ).trim() || "in:anywhere -in:trash -in:spam -in:drafts -in:sent";
  const dryRun = (process.env.CAPTURE_GMAIL_CLASSIFY_DRY_RUN ?? "0").trim() === "1";
  const importantLabel = (process.env.CAPTURE_GMAIL_CLASSIFY_IMPORTANT_LABEL ?? "重要").trim() || "重要";
  const usefulLabel = (process.env.CAPTURE_GMAIL_CLASSIFY_USEFUL_LABEL ?? "待追踨").trim() || "待追踨";
  const preferencePath =
    (process.env.CAPTURE_GMAIL_PREFERENCES_FILE ?? "").trim() ||
    path.join(
      os.homedir(),
      ".openclaw",
      "workspace",
      "automation",
      "assistant_hub",
      "05_meta",
      "gmail_preferences.json",
    );

  const preferences = await loadPreferences(preferencePath);
  ensureLabelExists(account, importantLabel);
  ensureLabelExists(account, usefulLabel);

  let pageToken = "";
  let page = 0;
  const seenTokens = new Set<string>();

  let seenMessages = 0;
  let importantCount = 0;
  let usefulCount = 0;
  let ignoredCount = 0;
  let touchedMessages = 0;

  console.log(
    `classify:start account=${account} query=${JSON.stringify(query)} page_size=${pageSize} max_pages=${maxPages} dry_run=${dryRun ? 1 : 0}`,
  );
  console.log(`classify:labels important=${importantLabel} useful=${usefulLabel}`);

  while (page < maxPages) {
    const args = ["gmail", "messages", "search", query, "--max", String(pageSize), "--account", account, "--json"];
    if (pageToken) {
      args.push("--page", pageToken);
    }

    const res = runGogJson(args) as GmailSearchResponse;
    const messages = Array.isArray(res.messages) ? res.messages : [];
    if (messages.length === 0) {
      break;
    }

    page += 1;
    seenMessages += messages.length;

    const idsImportant: string[] = [];
    const idsUseful: string[] = [];
    const idsIgnored: string[] = [];

    for (const msg of messages) {
      const cls = classifyMessage(msg, preferences);
      const labelSet = new Set(msg.labels ?? []);
      if (cls.bucket === "important") {
        importantCount += 1;
        const needAddImportant = !labelSet.has(importantLabel);
        const needRemoveUseful = labelSet.has(usefulLabel);
        if (needAddImportant || needRemoveUseful) {
          idsImportant.push(msg.id);
        }
      } else if (cls.bucket === "useful") {
        usefulCount += 1;
        const needAddUseful = !labelSet.has(usefulLabel);
        const needRemoveImportant = labelSet.has(importantLabel);
        if (needAddUseful || needRemoveImportant) {
          idsUseful.push(msg.id);
        }
      } else {
        ignoredCount += 1;
        if (labelSet.has(importantLabel) || labelSet.has(usefulLabel)) {
          idsIgnored.push(msg.id);
        }
      }
    }

    const changedImportant = applyBatchModify({
      account,
      ids: idsImportant,
      add: [importantLabel],
      remove: [usefulLabel],
      dryRun,
    });
    const changedUseful = applyBatchModify({
      account,
      ids: idsUseful,
      add: [usefulLabel],
      remove: [importantLabel],
      dryRun,
    });
    const changedIgnored = applyBatchModify({
      account,
      ids: idsIgnored,
      add: [],
      remove: [importantLabel, usefulLabel],
      dryRun,
    });

    touchedMessages += changedImportant + changedUseful + changedIgnored;

    console.log(
      `classify:page=${page} scanned=${messages.length} important=${idsImportant.length} useful=${idsUseful.length} ignored_clear=${idsIgnored.length} touched=${changedImportant + changedUseful + changedIgnored}`,
    );

    const nextPageToken = String(res.nextPageToken ?? "");
    if (!nextPageToken) {
      break;
    }
    if (seenTokens.has(nextPageToken)) {
      console.log("classify:stop repeated_next_page_token");
      break;
    }
    seenTokens.add(nextPageToken);
    pageToken = nextPageToken;
  }

  console.log(
    `classify:done pages=${page} seen=${seenMessages} important=${importantCount} useful=${usefulCount} ignored=${ignoredCount} touched=${touchedMessages} dry_run=${dryRun ? 1 : 0}`,
  );
}

await main();
