#!/usr/bin/env -S node --import tsx
/**
 * feishu-calendar.ts
 * Reads user's Feishu primary calendar via user_access_token (OAuth).
 * Token stored at ~/.openclaw/feishu_user_token.json (auto-refreshed).
 * Writes to 02_work/calendar.md (consumed by hub-context.ts).
 */

import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { escapeCell, initHub, readJsonl, tokyoYmd, writeText, type QueueEntry } from "./_utils.js";

const TZ = "Asia/Shanghai";
const TOKEN_FILE = path.join(os.homedir(), ".openclaw", "feishu_user_token.json");
const FEISHU_BASE = "https://open.feishu.cn/open-apis";

// ── Token management ──────────────────────────────────────────────────────────

type TokenData = {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  refresh_expires_in: number;
  calendar_id: string;
  obtained_at: string;
};

async function loadToken(): Promise<TokenData | null> {
  try {
    const raw = await fs.readFile(TOKEN_FILE, "utf8");
    return JSON.parse(raw) as TokenData;
  } catch {
    return null;
  }
}

async function saveToken(data: TokenData): Promise<void> {
  await fs.writeFile(TOKEN_FILE, JSON.stringify(data, null, 2));
}

async function refreshAccessToken(
  appId: string,
  appSecret: string,
  refreshToken: string,
): Promise<string | null> {
  try {
    const res = await fetch(`${FEISHU_BASE}/authen/v1/oidc/refresh_access_token`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: "Basic " + Buffer.from(`${appId}:${appSecret}`).toString("base64"),
      },
      body: JSON.stringify({ grant_type: "refresh_token", refresh_token: refreshToken }),
    });
    const data = (await res.json()) as Record<string, unknown>;
    if (data.code !== 0) {
      // Fallback: older endpoint
      const res2 = await fetch(`${FEISHU_BASE}/authen/v1/refresh_access_token`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          app_id: appId,
          app_secret: appSecret,
          grant_type: "refresh_token",
          refresh_token: refreshToken,
        }),
      });
      const d2 = (await res2.json()) as Record<string, unknown>;
      return ((d2?.data as Record<string, unknown>)?.access_token as string) ?? null;
    }
    return ((data?.data as Record<string, unknown>)?.access_token as string) ?? null;
  } catch (err) {
    console.error("[feishu-calendar] refresh error:", String(err));
    return null;
  }
}

async function getValidToken(
  appId: string,
  appSecret: string,
): Promise<{ token: string; calendarId: string } | null> {
  const stored = await loadToken();
  if (!stored) {
    console.error("[feishu-calendar] No token file found at", TOKEN_FILE);
    return null;
  }

  const obtainedAt = new Date(stored.obtained_at).getTime();
  const ageSeconds = (Date.now() - obtainedAt) / 1000;
  const isExpired = ageSeconds > stored.expires_in - 300; // refresh 5 min early

  if (isExpired) {
    console.log("[feishu-calendar] access_token expired, refreshing...");
    const newToken = await refreshAccessToken(appId, appSecret, stored.refresh_token);
    if (!newToken) {
      console.error("[feishu-calendar] Token refresh failed. Re-run OAuth setup.");
      return null;
    }
    stored.access_token = newToken;
    stored.obtained_at = new Date().toISOString();
    await saveToken(stored);
    console.log("[feishu-calendar] token refreshed OK");
  }

  return { token: stored.access_token, calendarId: stored.calendar_id };
}

// ── Calendar fetch ────────────────────────────────────────────────────────────

type CalRow = {
  source: "feishu";
  summary: string;
  ymd: string;
  hm: string | null;
  location: string;
  attendees: string;
};

function unixToLocal(ts: number): { ymd: string; hm: string } {
  const fmt = new Intl.DateTimeFormat("en-CA", {
    timeZone: TZ,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  });
  const parts = fmt.formatToParts(new Date(ts * 1000));
  const g = (t: string) => parts.find((p) => p.type === t)?.value ?? "";
  return { ymd: `${g("year")}-${g("month")}-${g("day")}`, hm: `${g("hour")}:${g("minute")}` };
}

function shorten(s: string, n: number): string {
  const t = s.replace(/\s+/g, " ").trim();
  return t.length <= n ? t : `${t.slice(0, n - 1)}…`;
}

async function fetchEvents(
  token: string,
  calendarId: string,
  daysAhead: number,
): Promise<CalRow[]> {
  const now = Math.floor(Date.now() / 1000);
  const url =
    `${FEISHU_BASE}/calendar/v4/calendars/${encodeURIComponent(calendarId)}/events` +
    `?start_time=${now - 86400}&end_time=${now + daysAhead * 86400}&page_size=50`;

  try {
    const res = await fetch(url, { headers: { Authorization: `Bearer ${token}` } });
    const data = (await res.json()) as Record<string, unknown>;
    if ((data.code as number) !== 0) {
      console.error("[feishu-calendar] events API error:", data.code, data.msg);
      return [];
    }
    const items = ((data.data as Record<string, unknown>)?.items ?? []) as Record<
      string,
      unknown
    >[];
    const rows: CalRow[] = [];
    for (const ev of items) {
      if (!ev || ev.status === "cancelled") {
        continue;
      }
      const summary = String(ev.summary ?? "(無標題)").trim();
      const loc = String((ev.location as Record<string, unknown>)?.name ?? "").trim();
      const startRaw = ev.start_time as Record<string, unknown> | undefined;
      const isAllDay = !startRaw?.timestamp && !!startRaw?.date;
      let ts: number | null = null;
      if (startRaw?.timestamp) {
        ts = Number(startRaw.timestamp);
      } else if (startRaw?.date) {
        ts = Math.floor(new Date(`${startRaw.date}T00:00:00+08:00`).getTime() / 1000);
      }
      if (!ts) {
        continue;
      }
      const { ymd, hm } = unixToLocal(ts);
      const att = (Array.isArray(ev.attendees) ? (ev.attendees as Record<string, unknown>[]) : [])
        .filter((a) => a.type === "user" && a.display_name)
        .map((a) => String(a.display_name))
        .slice(0, 3)
        .join(", ");
      rows.push({
        source: "feishu",
        summary,
        ymd,
        hm: isAllDay ? null : hm,
        location: loc,
        attendees: att,
      });
    }
    return rows;
  } catch (err) {
    console.error("[feishu-calendar] fetch error:", String(err));
    return [];
  }
}

// ── Queue entries ─────────────────────────────────────────────────────────────

type QueueRow = { source: "queue"; summary: string; ymd: string; hm: string | null; type: string };

function queueYmd(e: QueueEntry): string {
  const due = typeof e.due === "string" ? e.due.trim() : "";
  if (due) {
    const p = Date.parse(due);
    if (Number.isFinite(p)) {
      return new Intl.DateTimeFormat("en-CA", { timeZone: TZ }).format(new Date(p));
    }
    return due.slice(0, 10);
  }
  const cp = Array.isArray(e.checkpoints) ? e.checkpoints : [];
  return cp.length > 0 ? String(cp[0]).slice(0, 10) : "1970-01-01";
}

function queueHm(e: QueueEntry): string | null {
  const due = typeof e.due === "string" ? e.due.trim() : "";
  if (!due || due.length <= 10) {
    return null;
  }
  const p = Date.parse(due);
  if (!Number.isFinite(p)) {
    return null;
  }
  const { hm } = unixToLocal(Math.floor(p / 1000));
  return hm === "00:00" ? null : hm;
}

// ── Main ──────────────────────────────────────────────────────────────────────

async function main() {
  const today = tokyoYmd();
  const daysAhead = Number.parseInt(process.env.FEISHU_CALENDAR_DAYS_AHEAD ?? "14", 10);
  const appId = (process.env.FEISHU_APP_ID ?? "cli_a92aeaf256389cd3").trim();
  const appSecret = (process.env.FEISHU_APP_SECRET ?? "hXdW0z6oMt4jShvylSwesggRSyEaUdnM").trim();

  const auth = await getValidToken(appId, appSecret);
  if (!auth) {
    process.exit(1);
  }

  const calRows = await fetchEvents(auth.token, auth.calendarId, daysAhead);
  console.log(`[feishu-calendar] fetched ${calRows.length} events`);

  const paths = await initHub();
  const queue = await readJsonl<QueueEntry>(path.join(paths.meta, "reasoning_queue.jsonl"));
  const queueRows: QueueRow[] = queue
    .filter((e) => e.calendar_entry === true && e.consumed !== true)
    .map((e) => ({
      source: "queue" as const,
      summary: String(e.id ?? "queue"),
      ymd: queueYmd(e),
      hm: queueHm(e),
      type: String(e.type ?? "memory"),
    }));

  type Row = CalRow | QueueRow;
  const key = (r: Row) => `${r.ymd}${r.hm ?? "99:99"}`;
  const all = [...calRows, ...queueRows].toSorted((a, b) => key(a).localeCompare(key(b)));

  const lines = [
    "# calendar (飛書日歷)",
    "",
    `updated: ${today}  events:${calRows.length}  queue:${queueRows.length}`,
    "",
    "| date | time | summary | location | attendees | source |",
    "| --- | --- | --- | --- | --- | --- |",
  ];
  for (const r of all) {
    if (r.source === "feishu") {
      lines.push(
        `| ${escapeCell(r.ymd)} | ${escapeCell(r.hm ?? "全天")} | ${escapeCell(shorten(r.summary, 50))} | ${escapeCell(r.location || "-")} | ${escapeCell(r.attendees || "-")} | feishu |`,
      );
    } else {
      lines.push(
        `| ${escapeCell(r.ymd)} | ${escapeCell(r.hm ?? "-")} | ${escapeCell(shorten(r.summary, 50))} | - | - | queue |`,
      );
    }
  }
  lines.push("");

  const outPath = path.join(paths.work, "calendar.md");
  await writeText(outPath, lines.join("\n") + "\n");
  console.log(
    `capture:feishu-calendar events=${calRows.length} queue=${queueRows.length} -> ${outPath}`,
  );
}

await main();
