#!/usr/bin/env -S node --import tsx
import { spawnSync } from "node:child_process";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { envBool, initHub, readText, tokyoYmd, writeText } from "./_utils.js";

type SessionIndexEntry = {
  sessionId?: string;
  updatedAt?: number;
};

type SessionMessageRow = {
  type?: string;
  message?: {
    role?: string;
    content?: Array<{ type?: string; text?: string }>;
  };
};

type GmailItem = {
  id: string;
  sessionId: string;
  updatedAtMs: number;
  from: string;
  subject: string;
  snippet: string;
};

type PriorityLabel = "P0" | "P1" | "P2" | "P3";
type Bucket = "important" | "useful" | "ignored";

type ClassifiedItem = GmailItem & {
  priority: PriorityLabel;
  bucket: Bucket;
  score: number;
  reason: string;
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

type PreferenceLoadStatus = "loaded" | "created_default" | "fallback_default_invalid_json";

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
    importantSenders: normalizeList(
      raw?.importantSenders,
      DEFAULT_GMAIL_PREFERENCES.importantSenders,
    ),
    importantDomains: normalizeList(
      raw?.importantDomains,
      DEFAULT_GMAIL_PREFERENCES.importantDomains,
    ),
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

function normalizeSpaces(input: string): string {
  return input.replace(/\s+/g, " ").trim();
}

function shorten(input: string, limit: number): string {
  const normalized = normalizeSpaces(input);
  if (normalized.length <= limit) {
    return normalized;
  }
  return `${normalized.slice(0, Math.max(0, limit - 3)).trim()}...`;
}

function runOpenclawMessageSend(params: {
  pushChannel: string;
  pushTo: string;
  text: string;
  pushAccountId?: string;
  pushDryRun: boolean;
}) {
  const cliBin = (process.env.CAPTURE_GMAIL_DIGEST_PUSH_CLI_BIN ?? "openclaw").trim() || "openclaw";
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

async function readJson<T>(filePath: string): Promise<T | null> {
  const raw = await readText(filePath);
  if (!raw.trim()) {
    return null;
  }
  try {
    return JSON.parse(raw) as T;
  } catch {
    return null;
  }
}

async function loadPreferences(metaPath: string): Promise<{
  preferences: GmailDigestPreferences;
  preferencePath: string;
  status: PreferenceLoadStatus;
}> {
  const envPath = (process.env.CAPTURE_GMAIL_PREFERENCES_FILE ?? "").trim();
  const preferencePath = envPath || path.join(metaPath, "gmail_preferences.json");
  const rawText = await readText(preferencePath);

  if (!rawText.trim()) {
    const preferences = normalizePreferences(null);
    await writeText(preferencePath, `${JSON.stringify(preferences, null, 2)}\n`);
    return {
      preferences,
      preferencePath,
      status: "created_default",
    };
  }

  try {
    const parsed = JSON.parse(rawText) as Partial<GmailDigestPreferences>;
    return {
      preferences: normalizePreferences(parsed),
      preferencePath,
      status: "loaded",
    };
  } catch {
    return {
      preferences: normalizePreferences(null),
      preferencePath,
      status: "fallback_default_invalid_json",
    };
  }
}

function parseExternalEmailBlock(
  rawText: string,
): { from: string; subject: string; snippet: string } | null {
  const blockMatch = rawText.match(
    /<<<EXTERNAL_UNTRUSTED_CONTENT>>>\n([\s\S]*?)\n<<<END_EXTERNAL_UNTRUSTED_CONTENT>>>/,
  );
  if (!blockMatch?.[1]) {
    return null;
  }

  const lines = blockMatch[1]
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line.length > 0 && line !== "---" && line !== "Source: Email");

  const fromLine = lines.find((line) => line.startsWith("New email from ")) ?? "";
  const subjectLine = lines.find((line) => line.startsWith("Subject:")) ?? "";

  const from = fromLine.replace(/^New email from\s+/i, "").trim();
  const subject = subjectLine.replace(/^Subject:\s*/i, "").trim();

  let snippet = "";
  const subjectIndex = lines.findIndex((line) => line.startsWith("Subject:"));
  if (subjectIndex >= 0) {
    snippet = lines
      .slice(subjectIndex + 1)
      .join(" ")
      .trim();
  }

  if (!from && !subject && !snippet) {
    return null;
  }

  return {
    from,
    subject,
    snippet,
  };
}

async function parseGmailItemFromSession(params: {
  sessionsDir: string;
  id: string;
  sessionId: string;
  updatedAtMs: number;
}): Promise<GmailItem | null> {
  const filePath = path.join(params.sessionsDir, `${params.sessionId}.jsonl`);
  let raw = "";
  try {
    raw = await fs.readFile(filePath, "utf8");
  } catch {
    return null;
  }
  if (!raw.trim()) {
    return null;
  }

  let userText = "";
  for (const line of raw.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed) {
      continue;
    }
    try {
      const row = JSON.parse(trimmed) as SessionMessageRow;
      if (row.type !== "message" || row.message?.role !== "user") {
        continue;
      }
      const textPart = row.message.content?.find(
        (part) => part?.type === "text" && typeof part.text === "string",
      )?.text;
      if (!textPart || !textPart.includes("Task: Gmail")) {
        continue;
      }
      userText = textPart;
      break;
    } catch {
      // ignore malformed rows
    }
  }

  if (!userText) {
    return null;
  }

  const parsed = parseExternalEmailBlock(userText);
  if (!parsed) {
    return null;
  }

  return {
    id: params.id,
    sessionId: params.sessionId,
    updatedAtMs: params.updatedAtMs,
    from: parsed.from || "(unknown)",
    subject: parsed.subject || "(no subject)",
    snippet: parsed.snippet || "(no snippet)",
  };
}

function classifyItem(item: GmailItem, preferences: GmailDigestPreferences): ClassifiedItem {
  const haystack = safeLower(`${item.from} ${item.subject} ${item.snippet}`);
  const urgentHits = hitKeywords(haystack, URGENT_KEYWORDS);
  const actionHits = hitKeywords(haystack, ACTION_KEYWORDS);
  const usefulHits = hitKeywords(haystack, USEFUL_KEYWORDS);
  const ignoreHits = hitKeywords(haystack, IGNORE_KEYWORDS);
  const prefBoostHits = hitKeywords(haystack, preferences.boostKeywords);
  const prefMuteHits = hitKeywords(haystack, preferences.muteKeywords);
  const senderEmail = parseEmailFromHeader(item.from);
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
  if (/\b(no-?reply|noreply)\b/i.test(item.from)) {
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

  const reasonParts: string[] = [];
  if (urgentHits.length > 0) {
    reasonParts.push(`urgent:${urgentHits.slice(0, 3).join(",")}`);
  }
  if (actionHits.length > 0) {
    reasonParts.push(`action:${actionHits.slice(0, 3).join(",")}`);
  }
  if (usefulHits.length > 0) {
    reasonParts.push(`useful:${usefulHits.slice(0, 3).join(",")}`);
  }
  if (ignoreHits.length > 0) {
    reasonParts.push(`ignore:${ignoreHits.slice(0, 2).join(",")}`);
  }
  if (prefBoostHits.length > 0) {
    reasonParts.push(`pref_boost:${prefBoostHits.slice(0, 3).join(",")}`);
  }
  if (prefMuteHits.length > 0) {
    reasonParts.push(`pref_mute:${prefMuteHits.slice(0, 3).join(",")}`);
  }
  if (preferences.importantSenders.includes(senderEmail)) {
    reasonParts.push(`pref_sender:+:${senderEmail}`);
  }
  if (senderDomain && preferences.importantDomains.includes(senderDomain)) {
    reasonParts.push(`pref_domain:+:${senderDomain}`);
  }
  if (preferences.mutedSenders.includes(senderEmail)) {
    reasonParts.push(`pref_sender:-:${senderEmail}`);
  }
  if (senderDomain && preferences.mutedDomains.includes(senderDomain)) {
    reasonParts.push(`pref_domain:-:${senderDomain}`);
  }

  return {
    ...item,
    priority,
    bucket,
    score,
    reason: reasonParts.join(" | ") || "heuristic",
  };
}

function formatLocalDateTime(ts: number): string {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Shanghai",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  }).format(new Date(ts));
}

function renderLine(item: ClassifiedItem): string {
  return [
    `• (${item.priority}) ${shorten(item.subject, 56)}`,
    `  來自：${shorten(item.from, 40)}`,
    `  摘要：${shorten(item.snippet, 58)}`,
    `  編號：${item.id}`,
  ].join("\n");
}

function buildPushText(params: {
  today: string;
  lookbackHours: number;
  important: ClassifiedItem[];
  useful: ClassifiedItem[];
  ignoredCount: number;
  preferences: GmailDigestPreferences;
}): string {
  const { today, lookbackHours, important, useful, ignoredCount, preferences } = params;
  const lines: string[] = [];
  lines.push(`📮 郵件日摘要（${today}）`);
  lines.push(
    `窗口：近 ${lookbackHours} 小時｜重要 ${important.length}｜有用 ${useful.length}｜忽略 ${ignoredCount}`,
  );
  if (preferences.focus.length > 0) {
    lines.push(`偏好：${preferences.focus.slice(0, 4).join(" / ")}`);
  }
  lines.push("");

  lines.push("【重要】");
  if (important.length === 0) {
    lines.push("• 今天暫無高優先郵件。\n");
  } else {
    for (const item of important.slice(0, 8)) {
      lines.push(renderLine(item));
    }
    if (important.length > 8) {
      lines.push(`• 另外 ${important.length - 8} 封重要郵件已收起。`);
    }
  }

  lines.push("");
  lines.push("【有用】");
  if (useful.length === 0) {
    lines.push("• 今天暫無需留檔跟進的郵件。\n");
  } else {
    for (const item of useful.slice(0, 6)) {
      lines.push(renderLine(item));
    }
    if (useful.length > 6) {
      lines.push(`• 另外 ${useful.length - 6} 封有用郵件已收起。`);
    }
  }

  lines.push("");
  lines.push("回覆我：`轉任務 <編號>`，我可直接幫你落到待辦。\n");
  return lines.join("\n");
}

async function main() {
  const today = tokyoYmd();
  const lookbackHoursRaw = Number(process.env.CAPTURE_GMAIL_DIGEST_LOOKBACK_HOURS ?? "24");
  const lookbackHours =
    Number.isFinite(lookbackHoursRaw) && lookbackHoursRaw > 0 ? Math.floor(lookbackHoursRaw) : 24;
  const pushEnabled = envBool("CAPTURE_GMAIL_DIGEST_PUSH_ENABLED", false);
  const pushDryRun = envBool("CAPTURE_GMAIL_DIGEST_PUSH_DRY_RUN", true);
  const pushDryRunCli = envBool("CAPTURE_GMAIL_DIGEST_PUSH_DRY_RUN_CLI", false);
  const pushChannel =
    (process.env.CAPTURE_GMAIL_DIGEST_PUSH_CHANNEL ?? "telegram").trim() || "telegram";
  const pushTo = (process.env.CAPTURE_GMAIL_DIGEST_PUSH_TO ?? "").trim();
  const pushAccountId =
    (process.env.CAPTURE_GMAIL_DIGEST_PUSH_ACCOUNT_ID ?? "").trim() || undefined;

  const sessionsDir = (
    process.env.CAPTURE_GMAIL_SESSIONS_DIR ??
    path.join(os.homedir(), ".openclaw", "agents", "main", "sessions")
  ).trim();
  const sessionsIndexPath = path.join(sessionsDir, "sessions.json");

  const paths = await initHub();
  const preferenceState = await loadPreferences(paths.meta);
  const sinceMs = Date.now() - lookbackHours * 60 * 60 * 1000;

  const index = (await readJson<Record<string, SessionIndexEntry>>(sessionsIndexPath)) ?? {};
  const prefix = "agent:main:hook:gmail:";

  const candidates = Object.entries(index)
    .filter(([key]) => key.startsWith(prefix))
    .map(([key, value]) => {
      const id = key.slice(prefix.length);
      const sessionId = String(value?.sessionId ?? "").trim();
      const updatedAtMs = Number(value?.updatedAt ?? 0);
      return {
        id,
        sessionId,
        updatedAtMs,
      };
    })
    .filter((row) => row.id && row.sessionId)
    .filter((row) => row.updatedAtMs === 0 || row.updatedAtMs >= sinceMs)
    .toSorted((a, b) => b.updatedAtMs - a.updatedAtMs);

  const parsedItems = (
    await Promise.all(
      candidates.map((row) =>
        parseGmailItemFromSession({
          sessionsDir,
          id: row.id,
          sessionId: row.sessionId,
          updatedAtMs: row.updatedAtMs,
        }),
      ),
    )
  ).filter((item): item is GmailItem => Boolean(item));

  const deduped = Array.from(new Map(parsedItems.map((item) => [item.id, item])).values());
  const classified = deduped.map((item) => classifyItem(item, preferenceState.preferences));

  const important = classified.filter((item) => item.bucket === "important");
  const useful = classified.filter((item) => item.bucket === "useful");
  const ignored = classified.filter((item) => item.bucket === "ignored");

  important.sort((a, b) => b.score - a.score || b.updatedAtMs - a.updatedAtMs);
  useful.sort((a, b) => b.score - a.score || b.updatedAtMs - a.updatedAtMs);

  const detailPath = path.join(paths.meta, "gmail_daily_digest.md");
  const detailLines = [
    "# gmail_daily_digest",
    "",
    `date: ${today}`,
    `lookback_hours: ${lookbackHours}`,
    `total_candidates: ${candidates.length}`,
    `parsed: ${classified.length}`,
    `important: ${important.length}`,
    `useful: ${useful.length}`,
    `ignored: ${ignored.length}`,
    `preferences_profile: ${preferenceState.preferences.profileName}`,
    `preferences_role: ${preferenceState.preferences.role}`,
    `preferences_file: ${preferenceState.preferencePath}`,
    `preferences_status: ${preferenceState.status}`,
    "",
    "| updated_at | id | priority | bucket | from | subject | snippet | reason | session_id |",
    "| --- | --- | --- | --- | --- | --- | --- | --- | --- |",
  ];
  for (const item of classified) {
    detailLines.push(
      `| ${formatLocalDateTime(item.updatedAtMs || Date.now())} | ${item.id} | ${item.priority} | ${item.bucket} | ${item.from.replace(/\|/g, "\\|")} | ${item.subject.replace(/\|/g, "\\|")} | ${shorten(item.snippet, 80).replace(/\|/g, "\\|")} | ${item.reason.replace(/\|/g, "\\|")} | ${item.sessionId} |`,
    );
  }
  detailLines.push("");
  await writeText(detailPath, `${detailLines.join("\n")}\n`);

  const pushText = buildPushText({
    today,
    lookbackHours,
    important,
    useful,
    ignoredCount: ignored.length,
    preferences: preferenceState.preferences,
  });

  const previewPath = path.join(paths.meta, "gmail_digest_push_preview.md");
  await writeText(
    previewPath,
    [
      "# gmail_digest_push_preview",
      "",
      `date: ${today}`,
      `lookback_hours: ${lookbackHours}`,
      "",
      "```text",
      pushText,
      "```",
      "",
    ].join("\n"),
  );

  // Write concise inbox summary to work/ so LLM hub-context can read it
  const inboxLines: string[] = [
    `# gmail (${today}，重要 ${important.length} / 有用 ${useful.length})`,
  ];
  for (const item of important.slice(0, 6)) {
    inboxLines.push(
      `- (${item.priority}) ${shorten(item.subject, 50)} | ${shorten(item.from, 30)}`,
    );
  }
  if (useful.length > 0) {
    inboxLines.push(
      `_有用 ${useful.length} 封（${useful
        .slice(0, 3)
        .map((i) => shorten(i.subject, 30))
        .join(" / ")}${useful.length > 3 ? " …" : ""}）_`,
    );
  }
  await writeText(path.join(paths.work, "gmail.md"), inboxLines.join("\n") + "\n");

  let pushed = 0;
  let pushError: string | null = null;
  let pushMode = "skipped";
  let pushPayloadPath: string | null = null;

  if (pushEnabled) {
    if (!pushTo) {
      pushError = "missing CAPTURE_GMAIL_DIGEST_PUSH_TO";
    } else {
      pushPayloadPath = path.join(paths.meta, "gmail_digest_push_payload.md");
      await writeText(
        pushPayloadPath,
        [
          "# gmail_digest_push_payload",
          "",
          `date: ${today}`,
          `channel: ${pushChannel}`,
          `target: ${pushTo}`,
          "",
          "```text",
          pushText,
          "```",
          "",
        ].join("\n"),
      );

      if (pushDryRun && !pushDryRunCli) {
        pushMode = "simulated_dry_run";
        pushed = 1;
      } else {
        pushMode = "cli";
        try {
          const run = runOpenclawMessageSend({
            pushChannel,
            pushTo,
            text: pushText,
            pushAccountId,
            pushDryRun,
          });
          if (run.status === 0) {
            pushed = 1;
          } else {
            pushError = (run.stderr || run.stdout || `exit_${run.status ?? "unknown"}`).trim();
          }
        } catch (err) {
          pushError = err instanceof Error ? err.message : String(err);
        }
      }
    }
  }

  const resultPath = path.join(paths.meta, "gmail_digest_push_results.md");
  await writeText(
    resultPath,
    [
      "# gmail_digest_push_results",
      "",
      `date: ${today}`,
      `lookback_hours: ${lookbackHours}`,
      `total_candidates: ${candidates.length}`,
      `parsed: ${classified.length}`,
      `important: ${important.length}`,
      `useful: ${useful.length}`,
      `ignored: ${ignored.length}`,
      `preferences_profile: ${preferenceState.preferences.profileName}`,
      `preferences_role: ${preferenceState.preferences.role}`,
      `preferences_file: ${preferenceState.preferencePath}`,
      `preferences_status: ${preferenceState.status}`,
      `push_enabled: ${pushEnabled ? "1" : "0"}`,
      `push_mode: ${pushMode}`,
      `channel: ${pushChannel}`,
      `target: ${pushTo || "(unset)"}`,
      `account: ${pushAccountId ?? "(default)"}`,
      `pushed: ${pushed}`,
      `error: ${pushError ?? "none"}`,
      `payload: ${pushPayloadPath ?? "(none)"}`,
      `preview: ${previewPath}`,
      `detail: ${detailPath}`,
      "",
    ].join("\n"),
  );

  console.log(
    `capture:gmail-digest parsed=${classified.length} important=${important.length} useful=${useful.length} push=${pushMode} pushed=${pushed} error=${pushError ?? "none"}`,
  );
}

await main();
