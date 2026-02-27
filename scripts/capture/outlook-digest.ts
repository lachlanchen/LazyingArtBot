#!/usr/bin/env -S node --import tsx
/**
 * IMAP Email Digest (Outlook / 163 / Hotmail / QQ / Yahoo / iCloud / …)
 *
 * Auto-detects IMAP host from email domain — no manual host config needed.
 *
 * Config (env vars):
 *   CAPTURE_OUTLOOK_USER            - Email address (required)
 *   CAPTURE_OUTLOOK_PASSWORD_FILE   - Path to file containing password / app-password
 *   CAPTURE_OUTLOOK_PASSWORD        - Password directly (fallback if no file)
 *   CAPTURE_OUTLOOK_HOST            - Override IMAP host (optional; auto-detected by default)
 *   CAPTURE_OUTLOOK_PORT            - Override IMAP port (optional; default 993)
 *   CAPTURE_OUTLOOK_MAILBOX         - Mailbox to fetch (default: INBOX)
 *   CAPTURE_OUTLOOK_LOOKBACK_HOURS  - Hours to look back (default: 24)
 *   CAPTURE_OUTLOOK_OUTPUT_FILE     - Output .md filename under 02_work/ (auto-detected by default)
 *   CAPTURE_OUTLOOK_PUSH_ENABLED    - "1" to push digest via openclaw message
 *   CAPTURE_OUTLOOK_PUSH_CHANNEL    - Channel for push (default: telegram)
 *   CAPTURE_OUTLOOK_PUSH_TO         - Target for push
 *   CAPTURE_OUTLOOK_PUSH_ACCOUNT_ID - Account id for push
 */

import { ImapFlow } from "/opt/LazyingArtBot/node_modules/imapflow/lib/imapflow.js";
import { simpleParser } from "/opt/LazyingArtBot/node_modules/mailparser/lib/simple-parser.js";
import { spawnSync } from "node:child_process";
import fs from "node:fs/promises";
import path from "node:path";
import { initHub, tokyoYmd, writeText } from "./_utils.js";

// ─── Types ────────────────────────────────────────────────────────────────────

type PriorityLabel = "P0" | "P1" | "P2" | "P3";
type Bucket = "important" | "useful" | "ignored";

type MailItem = {
  id: string;
  from: string;
  subject: string;
  snippet: string;
  receivedAt: number;
};

type ClassifiedItem = MailItem & {
  priority: PriorityLabel;
  bucket: Bucket;
  score: number;
};

type ImapConfig = {
  host: string;
  port: number;
  secure: boolean;
  providerLabel: string; // human-readable, e.g. "Outlook"
  outputFile: string; // filename under 02_work/, e.g. "outlook-mail.md"
};

// ─── Auto-detect IMAP config from email domain ───────────────────────────────

function resolveImapConfig(
  email: string,
  overrideHost?: string,
  overridePort?: number,
): ImapConfig {
  const domain = email.split("@")[1]?.toLowerCase() ?? "";

  // Microsoft personal (Outlook / Hotmail / Live / MSN)
  if (
    [
      "outlook.com",
      "hotmail.com",
      "hotmail.co.uk",
      "live.com",
      "live.cn",
      "msn.com",
      "outlook.com.cn",
      "outlook.jp",
      "hotmail.fr",
      "hotmail.de",
      "hotmail.es",
      "hotmail.it",
    ].includes(domain)
  ) {
    return {
      host: "imap-mail.outlook.com",
      port: 993,
      secure: true,
      providerLabel: "Outlook",
      outputFile: "outlook-mail.md",
    };
  }

  // Microsoft 365 / Exchange Online (enterprise custom domain)
  if (domain.endsWith(".onmicrosoft.com")) {
    return {
      host: "outlook.office365.com",
      port: 993,
      secure: true,
      providerLabel: "Microsoft 365",
      outputFile: "outlook-mail.md",
    };
  }

  // NetEase 163
  if (domain === "163.com") {
    return {
      host: "imap.163.com",
      port: 993,
      secure: true,
      providerLabel: "163",
      outputFile: "163-mail.md",
    };
  }

  // NetEase 126
  if (domain === "126.com") {
    return {
      host: "imap.126.com",
      port: 993,
      secure: true,
      providerLabel: "126",
      outputFile: "163-mail.md",
    };
  }

  // NetEase Yeah
  if (domain === "yeah.net") {
    return {
      host: "imap.yeah.net",
      port: 993,
      secure: true,
      providerLabel: "Yeah.net",
      outputFile: "163-mail.md",
    };
  }

  // Gmail (useful if user wants IMAP parallel to webhook)
  if (domain === "gmail.com" || domain === "googlemail.com") {
    return {
      host: "imap.gmail.com",
      port: 993,
      secure: true,
      providerLabel: "Gmail",
      outputFile: "gmail-imap-mail.md",
    };
  }

  // Yahoo
  if (
    [
      "yahoo.com",
      "yahoo.co.jp",
      "yahoo.co.uk",
      "yahoo.fr",
      "yahoo.de",
      "ymail.com",
      "rocketmail.com",
    ].includes(domain)
  ) {
    return {
      host: "imap.mail.yahoo.com",
      port: 993,
      secure: true,
      providerLabel: "Yahoo",
      outputFile: "yahoo-mail.md",
    };
  }

  // QQ Mail
  if (domain === "qq.com" || domain === "foxmail.com") {
    return {
      host: "imap.qq.com",
      port: 993,
      secure: true,
      providerLabel: "QQ Mail",
      outputFile: "qq-mail.md",
    };
  }

  // iCloud
  if (["icloud.com", "me.com", "mac.com"].includes(domain)) {
    return {
      host: "imap.mail.me.com",
      port: 993,
      secure: true,
      providerLabel: "iCloud",
      outputFile: "icloud-mail.md",
    };
  }

  // Zoho
  if (domain === "zoho.com" || domain === "zohomail.com") {
    return {
      host: "imappro.zoho.com",
      port: 993,
      secure: true,
      providerLabel: "Zoho",
      outputFile: "zoho-mail.md",
    };
  }

  // Sina
  if (domain === "sina.com" || domain === "sina.cn") {
    return {
      host: "imap.sina.com",
      port: 993,
      secure: true,
      providerLabel: "Sina",
      outputFile: "sina-mail.md",
    };
  }

  // Sohu
  if (domain === "sohu.com") {
    return {
      host: "imap.sohu.com",
      port: 993,
      secure: true,
      providerLabel: "Sohu",
      outputFile: "sohu-mail.md",
    };
  }

  // Aliyun Mail
  if (domain === "aliyun.com" || domain === "alibaba-inc.com") {
    return {
      host: "imap.aliyun.com",
      port: 993,
      secure: true,
      providerLabel: "Aliyun",
      outputFile: "aliyun-mail.md",
    };
  }

  // Enterprise Office 365 fallback (any unknown corporate domain likely uses Exchange)
  return {
    host: overrideHost ?? "outlook.office365.com",
    port: overridePort ?? 993,
    secure: true,
    providerLabel: domain,
    outputFile: `${domain.replace(/\./g, "-")}-mail.md`,
  };
}

// ─── Keywords ─────────────────────────────────────────────────────────────────

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

// ─── Classify ─────────────────────────────────────────────────────────────────

function classify(item: MailItem): ClassifiedItem {
  const text = `${item.subject} ${item.snippet}`.toLowerCase();
  const from = item.from.toLowerCase();
  let score = 0;

  const urgentHits = URGENT_KEYWORDS.filter((k) => text.includes(k));
  if (urgentHits.length) {
    score += 4;
  }

  const actionHits = ACTION_KEYWORDS.filter((k) => text.includes(k));
  if (actionHits.length) {
    score += 2;
  }

  const usefulHits = USEFUL_KEYWORDS.filter((k) => text.includes(k));
  if (usefulHits.length) {
    score += 1;
  }

  const ignoreHits = IGNORE_KEYWORDS.filter((k) => text.includes(k));
  if (ignoreHits.length) {
    score -= 3;
  }

  if (from.includes("noreply") || from.includes("no-reply") || from.includes("donotreply")) {
    score -= 1;
  }

  let priority: PriorityLabel = "P3";
  let bucket: Bucket = "ignored";
  if (score >= 4) {
    priority = "P0";
    bucket = "important";
  } else if (score >= 2) {
    priority = "P1";
    bucket = "important";
  } else if (score >= 1) {
    priority = "P2";
    bucket = "useful";
  }

  return { ...item, priority, bucket, score };
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function shorten(s: string, max: number): string {
  const trimmed = (s ?? "").replace(/\s+/g, " ").trim();
  return trimmed.length > max ? trimmed.slice(0, max - 1) + "…" : trimmed;
}

function runOpenclawSend(channel: string, to: string, text: string, accountId?: string): void {
  const args = ["message", "send", "--channel", channel, "--to", to, "--text", text];
  if (accountId) {
    args.push("--account", accountId);
  }
  const result = spawnSync("openclaw", args, { encoding: "utf8" });
  if (result.status !== 0) {
    console.error("push failed:", result.stderr || result.stdout);
  }
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  const user = process.env.CAPTURE_OUTLOOK_USER ?? "";
  const passwordFile = process.env.CAPTURE_OUTLOOK_PASSWORD_FILE ?? "";
  const passwordEnv = process.env.CAPTURE_OUTLOOK_PASSWORD ?? "";
  const overrideHost = process.env.CAPTURE_OUTLOOK_HOST;
  const overridePort = process.env.CAPTURE_OUTLOOK_PORT
    ? parseInt(process.env.CAPTURE_OUTLOOK_PORT, 10)
    : undefined;
  const mailbox = process.env.CAPTURE_OUTLOOK_MAILBOX ?? "INBOX";
  const lookbackHours = parseInt(process.env.CAPTURE_OUTLOOK_LOOKBACK_HOURS ?? "24", 10);
  const outputFileEnv = process.env.CAPTURE_OUTLOOK_OUTPUT_FILE;
  const pushEnabled = process.env.CAPTURE_OUTLOOK_PUSH_ENABLED === "1";
  const pushChannel = process.env.CAPTURE_OUTLOOK_PUSH_CHANNEL ?? "telegram";
  const pushTo = process.env.CAPTURE_OUTLOOK_PUSH_TO ?? "";
  const pushAccountId = process.env.CAPTURE_OUTLOOK_PUSH_ACCOUNT_ID;

  if (!user) {
    console.error("CAPTURE_OUTLOOK_USER is required");
    process.exit(1);
  }

  let password = passwordEnv;
  if (!password && passwordFile) {
    try {
      password = (await fs.readFile(passwordFile, "utf8")).trim();
    } catch {
      console.error(`Cannot read password file: ${passwordFile}`);
      process.exit(1);
    }
  }
  if (!password) {
    console.error("Password required: CAPTURE_OUTLOOK_PASSWORD or CAPTURE_OUTLOOK_PASSWORD_FILE");
    process.exit(1);
  }

  // Auto-detect provider from email domain
  const imap = resolveImapConfig(user, overrideHost, overridePort);
  if (overrideHost) {
    imap.host = overrideHost;
  }
  if (overridePort) {
    imap.port = overridePort;
  }
  const outputFile = outputFileEnv ?? imap.outputFile;

  console.log(`capture:imap-digest provider=${imap.providerLabel} host=${imap.host} user=${user}`);

  const paths = await initHub();
  const today = tokyoYmd();
  const sinceDate = new Date(Date.now() - lookbackHours * 3600 * 1000);

  // Connect to IMAP
  const client = new ImapFlow({
    host: imap.host,
    port: imap.port,
    secure: imap.secure,
    auth: { user, pass: password },
    logger: false,
  });

  const items: MailItem[] = [];

  try {
    await client.connect();
    const lock = await client.getMailboxLock(mailbox);
    try {
      const uids = await client.search({ since: sinceDate }, { uid: true });
      if (uids.length > 0) {
        const fetchUids = uids.slice(-100); // max 100 most recent
        for await (const msg of client.fetch(
          fetchUids,
          { source: true, uid: true },
          { uid: true },
        )) {
          try {
            const parsed = await simpleParser(msg.source);
            items.push({
              id: String(msg.uid),
              from: parsed.from?.text ?? "",
              subject: parsed.subject ?? "(no subject)",
              snippet: (parsed.text ?? "").replace(/\s+/g, " ").trim().slice(0, 200),
              receivedAt: parsed.date?.getTime() ?? Date.now(),
            });
          } catch {
            /* skip unparseable */
          }
        }
      }
    } finally {
      lock.release();
    }
    await client.logout();
  } catch (err) {
    console.error("IMAP error:", err instanceof Error ? err.message : String(err));
    process.exit(1);
  }

  items.sort((a, b) => b.receivedAt - a.receivedAt);

  const classified = items.map(classify);
  const important = classified
    .filter((i) => i.bucket === "important")
    .toSorted((a, b) => b.score - a.score);
  const useful = classified
    .filter((i) => i.bucket === "useful")
    .toSorted((a, b) => b.score - a.score);
  const ignored = classified.filter((i) => i.bucket === "ignored");

  // Write 02_work/{outputFile} for hub-context injection
  const inboxLines = [
    `# ${imap.providerLabel} (${today}，重要 ${important.length} / 有用 ${useful.length})`,
    ...important
      .slice(0, 6)
      .map((i) => `- (${i.priority}) ${shorten(i.subject, 50)} | ${shorten(i.from, 30)}`),
  ];
  if (useful.length > 0) {
    inboxLines.push(
      `_有用 ${useful.length} 封（${useful
        .slice(0, 3)
        .map((i) => shorten(i.subject, 30))
        .join(" / ")}${useful.length > 3 ? " …" : ""}）_`,
    );
  }
  await writeText(path.join(paths.work, outputFile), inboxLines.join("\n") + "\n");

  // Push notification
  if (pushEnabled && pushTo && (important.length > 0 || useful.length > 0)) {
    const lines = [
      `📮 ${imap.providerLabel} 郵件日摘要（${today}）`,
      `窗口：近 ${lookbackHours} 小時｜重要 ${important.length}｜有用 ${useful.length}｜忽略 ${ignored.length}`,
      "",
      "【重要】",
      ...(important.length === 0
        ? ["• 今天暫無高優先郵件。"]
        : important
            .slice(0, 6)
            .flatMap((i) => [
              `• (${i.priority}) ${shorten(i.subject, 56)}`,
              `  來自：${shorten(i.from, 40)}`,
              ...(i.snippet ? [`  摘要：${shorten(i.snippet, 58)}`] : []),
            ])),
      ...(useful.length > 0
        ? [
            "",
            "【有用】",
            ...useful.slice(0, 4).map((i) => `• (${i.priority}) ${shorten(i.subject, 56)}`),
          ]
        : []),
    ];
    try {
      runOpenclawSend(pushChannel, pushTo, lines.join("\n"), pushAccountId);
    } catch {
      /* best-effort */
    }
  }

  console.log(
    `capture:imap-digest done fetched=${items.length} important=${important.length} useful=${useful.length} ignored=${ignored.length} output=${outputFile}`,
  );
}

await main();
