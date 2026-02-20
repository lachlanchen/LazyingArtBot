#!/usr/bin/env -S node --import tsx
import { spawnSync } from "node:child_process";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { buildCardIndex, envBool, escapeCell, initHub, readJsonl, readText, tokyoYmd, type QueueEntry, writeText } from "./_utils.js";

type ItemSource = "queue" | "reminder";
type DisplayCategory = "agenda" | "watch" | "action" | "note";
type PriorityLabel = "P0" | "P1" | "P2" | "P3";

type DisplayItem = {
  source: ItemSource;
  ref: string;
  date: string;
  hm: string | null;
  priority: PriorityLabel;
  category: DisplayCategory;
  summary: string;
  rawType: string;
  dueText: string;
};

type CronSchedule = {
  kind?: string;
  at?: string;
};

type CronPayload = {
  text?: string;
  message?: string;
};

type CronJob = {
  id?: string;
  name?: string;
  enabled?: boolean;
  schedule?: CronSchedule;
  payload?: CronPayload;
};

type CronFile = {
  jobs?: CronJob[];
};

type DateParts = {
  ymd: string;
  hm: string;
};

function resolveDate(entry: QueueEntry): string {
  const dueRaw = typeof entry.due === "string" ? entry.due.trim() : "";
  if (dueRaw) {
    const parsed = Date.parse(dueRaw);
    if (Number.isFinite(parsed)) {
      return localDateParts(parsed).ymd;
    }
    return dueRaw.slice(0, 10);
  }

  const checkpoints = Array.isArray(entry.checkpoints) ? entry.checkpoints : [];
  if (checkpoints.length > 0) {
    return String(checkpoints[0]).slice(0, 10);
  }

  const tsRaw = typeof entry.ts === "string" ? entry.ts.trim() : "";
  if (tsRaw) {
    const parsed = Date.parse(tsRaw);
    if (Number.isFinite(parsed)) {
      return localDateParts(parsed).ymd;
    }
    return tsRaw.slice(0, 10);
  }

  return "1970-01-01";
}

function parseYmd(input: string): string {
  return input.slice(0, 10);
}

function dayDiff(fromYmd: string, toYmd: string): number {
  const [fy, fm, fd] = fromYmd.split("-").map(Number);
  const [ty, tm, td] = toYmd.split("-").map(Number);
  const from = new Date(Date.UTC(fy, fm - 1, fd));
  const to = new Date(Date.UTC(ty, tm - 1, td));
  return Math.round((to.getTime() - from.getTime()) / (24 * 60 * 60 * 1000));
}

function runOpenclawMessageSend(params: {
  pushChannel: string;
  pushTo: string;
  text: string;
  pushAccountId?: string;
  pushDryRun: boolean;
}) {
  const cliBin = (process.env.CAPTURE_DAILY_PUSH_CLI_BIN ?? "openclaw").trim() || "openclaw";
  const sendArgs = ["message", "send", "--channel", params.pushChannel, "--target", params.pushTo, "--message", params.text];
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

function localDateParts(ts: number): DateParts {
  const formatter = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Shanghai",
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
  };
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
  if (/(telegram|wechat|weixin|whatsapp)/.test(lower)) {
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

function cleanQueueSummary(input: string): string {
  let out = normalizeSpaces(input);
  out = out.replace(/^\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}\s*/g, "");
  out = out.replace(/\(id:[^)]+\)/g, "");
  out = out.replace(/\btype:[^\s]+\b/gi, "");
  out = out.replace(/\bdue:[^\s]+\b/gi, "");
  out = out.replace(/\bcheckpoint:[^\s]+\b/gi, "");
  return normalizeSpaces(out);
}

function stripReminderPrefix(input: string): string {
  let out = normalizeSpaces(input);
  out = out.replace(/^提醒(?:（[^）]*）|\([^)]*\))?[：:]\s*/u, "");
  out = out.replace(/^提醒[：:]\s*/u, "");
  out = out.replace(/^提醒\s*/u, "");
  out = out.replace(/。+$/u, "");
  return normalizeSpaces(out);
}

function categoryForQueueType(type: string): DisplayCategory {
  const normalized = type.toLowerCase();
  if (normalized === "action") {
    return "action";
  }
  if (normalized === "watch") {
    return "watch";
  }
  if (normalized === "timeline" || normalized === "person") {
    return "agenda";
  }
  return "note";
}

function categoryForReminder(summary: string): DisplayCategory {
  const lower = summary.toLowerCase();
  if (/(會面|见面|會議|会议|面談|面谈|午飯|午饭|聚餐|行程|集合|出發|出发|meeting|trip)/.test(lower)) {
    return "agenda";
  }
  if (/(確認|确认|check|跟進|跟进|準備|准备|安排)/i.test(summary)) {
    return "action";
  }
  return "note";
}

function iconForCategory(category: DisplayCategory): string {
  if (category === "agenda") {
    return "🗓";
  }
  if (category === "action") {
    return "✅";
  }
  if (category === "watch") {
    return "👀";
  }
  return "📝";
}

function categoryLabel(category: DisplayCategory): string {
  if (category === "agenda") {
    return "行程";
  }
  if (category === "action") {
    return "待辦";
  }
  if (category === "watch") {
    return "跟進";
  }
  return "備忘";
}

function priorityRank(priority: PriorityLabel): number {
  if (priority === "P0") {
    return 0;
  }
  if (priority === "P1") {
    return 1;
  }
  if (priority === "P2") {
    return 2;
  }
  return 3;
}

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

function inferQueuePriority(params: {
  type: string;
  priorityRaw?: string | null;
}): PriorityLabel {
  const direct = normalizePriority(params.priorityRaw);
  if (direct) {
    return direct;
  }
  const normalized = params.type.toLowerCase();
  if (normalized === "action" || normalized === "timeline" || normalized === "person") {
    return "P1";
  }
  if (normalized === "watch") {
    return "P2";
  }
  return "P3";
}

function inferReminderPriority(params: {
  text: string;
  category: DisplayCategory;
}): PriorityLabel {
  const direct = normalizePriority(params.text);
  if (direct) {
    return direct;
  }
  if (params.category === "agenda" || params.category === "action") {
    return "P1";
  }
  return "P2";
}

function toTimeFromIso(input: string): string | null {
  const raw = input.trim();
  if (!raw || raw.length <= 10) {
    return null;
  }
  const parsed = Date.parse(raw);
  if (Number.isFinite(parsed)) {
    return localDateParts(parsed).hm;
  }
  const match = raw.match(/(?:T|\s)(\d{2}:\d{2})/);
  return match?.[1] ?? null;
}

function compareItems(a: DisplayItem, b: DisplayItem): number {
  if (a.date !== b.date) {
    return a.date.localeCompare(b.date);
  }
  const ah = a.hm ?? "99:99";
  const bh = b.hm ?? "99:99";
  if (ah !== bh) {
    return ah.localeCompare(bh);
  }
  if (a.priority !== b.priority) {
    return priorityRank(a.priority) - priorityRank(b.priority);
  }
  const rank: Record<DisplayCategory, number> = {
    agenda: 0,
    action: 1,
    watch: 2,
    note: 3,
  };
  if (rank[a.category] !== rank[b.category]) {
    return rank[a.category] - rank[b.category];
  }
  return a.ref.localeCompare(b.ref);
}

function renderItemLine(item: DisplayItem, includeDate: boolean): string {
  const when = includeDate ? `${item.date}${item.hm ? ` ${item.hm}` : ""}` : item.hm ?? "全天";
  return `${when} ${iconForCategory(item.category)} (${item.priority}) ${shorten(item.summary, 52)}`;
}

function renderSection(params: {
  title: string;
  items: DisplayItem[];
  includeDate: boolean;
  empty: string;
  maxItems: number;
}): string[] {
  const lines: string[] = [`【${params.title}】`];
  if (params.items.length === 0) {
    lines.push(`• ${params.empty}`);
    return lines;
  }

  const shown = params.items.slice(0, params.maxItems);
  for (const item of shown) {
    lines.push(`• ${renderItemLine(item, params.includeDate)}`);
  }
  if (params.items.length > shown.length) {
    lines.push(`• 另外 ${params.items.length - shown.length} 項，已為你收起。`);
  }
  return lines;
}

function buildPushVisualization(params: {
  today: string;
  items: DisplayItem[];
}): string {
  const { today, items } = params;
  const overdue: DisplayItem[] = [];
  const todayRows: DisplayItem[] = [];
  const within3Days: DisplayItem[] = [];
  const within7Days: DisplayItem[] = [];
  const within21Days: DisplayItem[] = [];

  for (const item of items) {
    const diff = dayDiff(today, parseYmd(item.date));
    if (diff < 0) {
      overdue.push(item);
      continue;
    }
    if (diff === 0) {
      todayRows.push(item);
      continue;
    }
    if (diff <= 3) {
      within3Days.push(item);
      continue;
    }
    if (diff <= 7) {
      within7Days.push(item);
      continue;
    }
    if (diff <= 21) {
      within21Days.push(item);
    }
  }

  todayRows.sort(compareItems);
  within3Days.sort(compareItems);
  within7Days.sort(compareItems);
  within21Days.sort(compareItems);
  overdue.sort(compareItems);
  const visibleItems = [...todayRows, ...within3Days, ...within7Days, ...within21Days, ...overdue];
  const priorityCounts: Record<PriorityLabel, number> = {
    P0: 0,
    P1: 0,
    P2: 0,
    P3: 0,
  };
  for (const item of visibleItems) {
    priorityCounts[item.priority] += 1;
  }

  const lines: string[] = [];
  lines.push(`🌤 早安，今天我幫你排好重點（${today}）`);
  lines.push(
    `概覽：今天 ${todayRows.length}｜3天內 ${within3Days.length}｜7天內 ${within7Days.length}｜21天內 ${within21Days.length}${overdue.length > 0 ? `｜逾期 ${overdue.length}` : ""}`,
  );
  lines.push(`優先級：P0 ${priorityCounts.P0}｜P1 ${priorityCounts.P1}｜P2 ${priorityCounts.P2}｜P3 ${priorityCounts.P3}`);
  lines.push("");
  lines.push(
    ...renderSection({
      title: "今天",
      items: todayRows,
      includeDate: false,
      empty: "今天沒有硬性到期，先把最重要的一件做完就好。",
      maxItems: 6,
    }),
  );
  lines.push("");
  lines.push(
    ...renderSection({
      title: "3天內（D+1 ~ D+3）",
      items: within3Days,
      includeDate: true,
      empty: "暫無。",
      maxItems: 6,
    }),
  );
  lines.push("");
  lines.push(
    ...renderSection({
      title: "7天內（D+4 ~ D+7）",
      items: within7Days,
      includeDate: true,
      empty: "暫無。",
      maxItems: 6,
    }),
  );
  lines.push("");
  lines.push(
    ...renderSection({
      title: "21天內（D+8 ~ D+21）",
      items: within21Days,
      includeDate: true,
      empty: "暫無。",
      maxItems: 6,
    }),
  );

  if (overdue.length > 0) {
    lines.push("");
    lines.push(
      ...renderSection({
        title: "逾期",
        items: overdue,
        includeDate: true,
        empty: "暫無。",
        maxItems: 4,
      }),
    );
  }

  if (items.some((item) => item.category === "watch")) {
    lines.push("");
    lines.push("小提醒：`👀` 是跟進檢查，不是今天必做；到期日我會再提醒你。");
  }

  lines.push("");
  lines.push("需要的話，我可以把其中 1-3 條直接整理成今天待辦。");
  return lines.join("\n");
}

async function readReminderItems(): Promise<DisplayItem[]> {
  const envPath = (process.env.CAPTURE_DAILY_CRON_JOBS_FILE ?? "").trim();
  const jobsPath = envPath || path.join(os.homedir(), ".openclaw", "cron", "jobs.json");
  const raw = await readText(jobsPath);
  if (!raw.trim()) {
    return [];
  }

  let parsed: CronFile;
  try {
    parsed = JSON.parse(raw) as CronFile;
  } catch {
    return [];
  }

  const jobs = Array.isArray(parsed.jobs) ? parsed.jobs : [];
  const items: DisplayItem[] = [];
  for (const job of jobs) {
    if (!job || job.enabled !== true || job.schedule?.kind !== "at") {
      continue;
    }

    const atRaw = typeof job.schedule.at === "string" ? job.schedule.at.trim() : "";
    if (!atRaw) {
      continue;
    }

    const ts = Date.parse(atRaw);
    if (!Number.isFinite(ts)) {
      continue;
    }

    const payloadText =
      typeof job.payload?.text === "string"
        ? job.payload.text
        : typeof job.payload?.message === "string"
          ? job.payload.message
          : typeof job.name === "string"
            ? job.name
            : "提醒事項";

    const summary = shorten(stripReminderPrefix(payloadText), 100);
    const local = localDateParts(ts);
    const ref = String(job.id ?? job.name ?? "reminder").trim() || "reminder";
    const category = categoryForReminder(summary);

    items.push({
      source: "reminder",
      ref,
      date: local.ymd,
      hm: local.hm,
      priority: inferReminderPriority({
        text: payloadText,
        category,
      }),
      category,
      summary,
      rawType: "reminder",
      dueText: atRaw,
    });
  }

  return items;
}

async function main() {
  const today = tokyoYmd();
  const pushEnabled = envBool("CAPTURE_DAILY_PUSH_ENABLED", false);
  const pushDryRun = envBool("CAPTURE_DAILY_PUSH_DRY_RUN", true);
  const pushDryRunCli = envBool("CAPTURE_DAILY_PUSH_DRY_RUN_CLI", false);
  const pushChannel = (process.env.CAPTURE_DAILY_PUSH_CHANNEL ?? "telegram").trim() || "telegram";
  const pushTo = (process.env.CAPTURE_DAILY_PUSH_TO ?? "").trim();
  const pushAccountId = (process.env.CAPTURE_DAILY_PUSH_ACCOUNT_ID ?? "").trim() || undefined;

  const paths = await initHub();
  const queuePath = path.join(paths.meta, "reasoning_queue.jsonl");
  const queue = await readJsonl<QueueEntry>(queuePath);
  const cards = await buildCardIndex(paths.root);
  const reminderItems = await readReminderItems();

  const queueItems = await Promise.all(
    queue
      .filter((entry) => entry.calendar_entry === true && entry.consumed !== true)
      .map(async (entry) => {
        const id = String(entry.id ?? "").trim();
        const card = id ? cards.get(id) : undefined;
        const fallbackTitle = id || "(unknown)";
        const title = card?.title ?? fallbackTitle;
        const summaryRaw = (await readCardSummary(card?.path)) ?? title;
        const summaryCleaned = cleanQueueSummary(summaryRaw);
        const summary = inferFriendlyMeaning(summaryCleaned) ?? summaryCleaned;
        const type = card?.type ?? String(entry.type ?? "memory");
        const category = categoryForQueueType(type);
        const dueRaw = typeof entry.due === "string" ? entry.due : "";
        const dueText =
          typeof entry.due === "string" && entry.due
            ? entry.due
            : Array.isArray(entry.checkpoints) && entry.checkpoints.length > 0
              ? `checkpoints:${entry.checkpoints.join(",")}`
              : "none";

        return {
          source: "queue" as const,
          ref: id || "queue",
          date: resolveDate(entry),
          hm: toTimeFromIso(dueRaw),
          priority: inferQueuePriority({
            type,
            priorityRaw: entry.priority,
          }),
          category,
          summary: shorten(summary || title, 100),
          rawType: type,
          dueText,
        };
      }),
  );

  const merged = [...queueItems, ...reminderItems].sort(compareItems);

  const deduped: DisplayItem[] = [];
  const seen = new Set<string>();
  for (const row of merged) {
    const key = `${row.source}:${row.ref}:${row.date}:${row.hm ?? ""}:${row.priority}:${row.summary}:${row.dueText}`;
    if (seen.has(key)) {
      continue;
    }
    seen.add(key);
    deduped.push(row);
  }

  const lines = [
    "# calendar",
    "",
    "| date | time | priority | item | category | source | ref | due/checkpoints |",
    "| --- | --- | --- | --- | --- | --- | --- | --- |",
  ];
  for (const row of deduped) {
    lines.push(
      `| ${escapeCell(row.date)} | ${escapeCell(row.hm ?? "-")} | ${escapeCell(row.priority)} | ${escapeCell(row.summary)} | ${escapeCell(categoryLabel(row.category))} | ${escapeCell(row.source)} | ${escapeCell(row.ref)} | ${escapeCell(row.dueText)} |`,
    );
  }
  lines.push("");

  const outPath = path.join(paths.work, "calendar.md");
  await writeText(outPath, `${lines.join("\n")}\n`);

  const previewText = buildPushVisualization({
    today,
    items: deduped,
  });
  const previewPath = path.join(paths.meta, "calendar_push_preview.md");
  await writeText(
    previewPath,
    [
      "# calendar_push_preview",
      "",
      `date: ${today}`,
      `rows: ${deduped.length}`,
      "",
      "```text",
      previewText,
      "```",
      "",
    ].join("\n"),
  );

  let pushed = 0;
  let pushError: string | null = null;
  let pushMode = "skipped";
  let pushPayloadPath: string | null = null;

  if (pushEnabled) {
    if (!pushTo) {
      pushError = "missing CAPTURE_DAILY_PUSH_TO";
    } else {
      pushPayloadPath = path.join(paths.meta, "calendar_push_payload.md");
      await writeText(
        pushPayloadPath,
        [
          "# calendar_push_payload",
          "",
          `date: ${today}`,
          `channel: ${pushChannel}`,
          `target: ${pushTo}`,
          "",
          "```text",
          previewText,
          "```",
          "",
        ].join("\n"),
      );

      if (pushDryRun && !pushDryRunCli) {
        pushMode = "simulated_dry_run";
        pushed = deduped.length > 0 ? 1 : 0;
      } else {
        pushMode = "cli";
        try {
          const run = runOpenclawMessageSend({
            pushChannel,
            pushTo,
            text: previewText,
            pushAccountId,
            pushDryRun,
          });
          if (run.status === 0) {
            pushed = deduped.length > 0 ? 1 : 0;
          } else {
            pushError = (run.stderr || run.stdout || `exit_${run.status ?? "unknown"}`).trim();
          }
        } catch (err) {
          pushError = err instanceof Error ? err.message : String(err);
        }
      }
    }
  }

  const resultPath = path.join(paths.meta, "calendar_push_results.md");
  await writeText(
    resultPath,
    [
      "# calendar_push_results",
      "",
      `date: ${today}`,
      `rows: ${deduped.length}`,
      `push_enabled: ${pushEnabled ? "1" : "0"}`,
      `push_mode: ${pushMode}`,
      `channel: ${pushChannel}`,
      `target: ${pushTo || "(unset)"}`,
      `account: ${pushAccountId ?? "(default)"}`,
      `pushed: ${pushed}`,
      `error: ${pushError ?? "none"}`,
      `payload: ${pushPayloadPath ?? "(none)"}`,
      `preview: ${previewPath}`,
      "",
    ].join("\n"),
  );

  console.log(
    `capture:daily-calendar rebuilt ${deduped.length} rows -> ${outPath}; push=${pushMode}; pushed=${pushed}; error=${pushError ?? "none"}`,
  );
}

await main();
