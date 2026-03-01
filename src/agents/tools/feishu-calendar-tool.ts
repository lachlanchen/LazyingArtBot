import { Type } from "@sinclair/typebox";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import type { AnyAgentTool } from "./common.js";
import { jsonResult, readStringParam } from "./common.js";

const FEISHU_BASE = "https://open.feishu.cn/open-apis";
const STATE_DIR =
  process.env.OPENCLAW_STATE_DIR?.trim() ||
  process.env.KAIRO_HOME?.trim() ||
  path.join(os.homedir(), ".openclaw");
const TOKEN_FILE = path.join(STATE_DIR, "feishu_user_token.json");

type FeishuToken = {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  refresh_expires_in: number;
  calendar_id: string;
  obtained_at: string;
};

async function loadToken(): Promise<FeishuToken | null> {
  try {
    const raw = await fs.readFile(TOKEN_FILE, "utf8");
    return JSON.parse(raw) as FeishuToken;
  } catch {
    return null;
  }
}

async function saveToken(token: FeishuToken): Promise<void> {
  const tmp = `${TOKEN_FILE}.${process.pid}.tmp`;
  await fs.writeFile(tmp, JSON.stringify(token, null, 2));
  await fs.rename(tmp, TOKEN_FILE);
}

async function getAppAccessToken(appId: string, appSecret: string): Promise<string | null> {
  try {
    const res = await fetch(`${FEISHU_BASE}/auth/v3/app_access_token/internal`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ app_id: appId, app_secret: appSecret }),
      signal: AbortSignal.timeout(10_000),
    });
    const d = (await res.json()) as Record<string, unknown>;
    return (d.code === 0 ? (d.app_access_token as string) : null) ?? null;
  } catch {
    return null;
  }
}

async function refreshToken(
  stored: FeishuToken,
): Promise<{ access_token: string; refresh_token: string } | null> {
  const appId = process.env.FEISHU_APP_ID ?? "";
  const appSecret = process.env.FEISHU_APP_SECRET ?? "";
  if (!appId || !appSecret) {
    return null;
  }

  try {
    // OIDC endpoint — requires app_access_token Bearer auth
    const appToken = await getAppAccessToken(appId, appSecret);
    if (appToken) {
      const res = await fetch(`${FEISHU_BASE}/authen/v1/oidc/refresh_access_token`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${appToken}` },
        body: JSON.stringify({ grant_type: "refresh_token", refresh_token: stored.refresh_token }),
        signal: AbortSignal.timeout(15_000),
      });
      const d = (await res.json()) as Record<string, unknown>;
      if (d.code === 0) {
        const data = d.data as Record<string, unknown>;
        const at = data.access_token as string | undefined;
        const rt = data.refresh_token as string | undefined;
        if (at) {
          return { access_token: at, refresh_token: rt ?? stored.refresh_token };
        }
      }
    }
    // Fallback: legacy endpoint
    const res2 = await fetch(`${FEISHU_BASE}/authen/v1/refresh_access_token`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        app_id: appId,
        app_secret: appSecret,
        grant_type: "refresh_token",
        refresh_token: stored.refresh_token,
      }),
      signal: AbortSignal.timeout(15_000),
    });
    const d2 = (await res2.json()) as Record<string, unknown>;
    const d2data = d2?.data as Record<string, unknown> | undefined;
    const at2 = d2data?.access_token as string | undefined;
    const rt2 = d2data?.refresh_token as string | undefined;
    return at2 ? { access_token: at2, refresh_token: rt2 ?? stored.refresh_token } : null;
  } catch {
    return null;
  }
}

// Single-flight mutex: at most one refresh HTTP call in flight at a time.
// All concurrent callers that find the token expired share the same Promise instead of each
// firing their own request.  The finally() block unconditionally clears the slot so a later
// failure never permanently blocks future refreshes.
//
// TOCTOU fix: after the in-flight refresh (or immediately when none is running) we re-read the
// token from disk before deciding whether to launch a new refresh.  This prevents a caller that
// loaded a stale `stored` snapshot from kicking off a redundant second refresh once the mutex
// slot has been vacated by the first refresh.
let _activeRefresh: Promise<{ access_token: string; refresh_token: string } | null> | null = null;

function _isTokenExpired(t: FeishuToken): boolean {
  const ageSeconds = (Date.now() - new Date(t.obtained_at).getTime()) / 1000;
  return ageSeconds > t.expires_in - 120;
}

export async function getValidToken(): Promise<{ token: string; calendarId: string } | null> {
  // --- Phase 1: fast-path — read from disk and return immediately if still valid ---
  const initial = await loadToken();
  if (!initial?.access_token || !initial?.calendar_id) {
    console.warn("[feishu-token] token file missing or incomplete");
    return null;
  }
  if (!_isTokenExpired(initial)) {
    return { token: initial.access_token, calendarId: initial.calendar_id };
  }

  // --- Phase 2: token is (or may be) expired — enter the single-flight section ---

  // If a refresh is already in-flight, piggy-back on it.
  if (_activeRefresh) {
    console.log("[feishu-token] reusing in-flight refresh");
    const refreshed = await _activeRefresh;
    if (!refreshed) {
      console.warn("[feishu-token] in-flight refresh returned null (refresh_token may be revoked)");
      return null;
    }
    // The refresh promise writes the token; re-read the latest value from disk.
    const latest = await loadToken();
    if (!latest?.access_token) {
      console.warn("[feishu-token] disk re-read after in-flight refresh returned empty token");
      return null;
    }
    return { token: latest.access_token, calendarId: latest.calendar_id };
  }

  // TOCTOU guard: re-read from disk — a concurrent caller that finished its refresh and already
  // cleared _activeRefresh may have written a fresh token between our initial read and now.
  const preRefreshCheck = await loadToken();
  if (preRefreshCheck?.access_token && !_isTokenExpired(preRefreshCheck)) {
    console.log("[feishu-token] token was refreshed by concurrent caller, reusing");
    return { token: preRefreshCheck.access_token, calendarId: preRefreshCheck.calendar_id };
  }

  // We are the designated refresher — grab the slot.
  const storedForRefresh = preRefreshCheck ?? initial;
  console.log(
    "[feishu-token] starting token refresh (obtained_at:",
    storedForRefresh.obtained_at,
    ")",
  );
  _activeRefresh = refreshToken(storedForRefresh).finally(() => {
    _activeRefresh = null; // always clear, even on failure — never permanently block
  });

  const refreshed = await _activeRefresh;
  if (!refreshed) {
    console.warn(
      "[feishu-token] refresh failed — refresh_token may be expired or revoked; re-authorize via OAuth",
    );
    return null;
  }

  // Write only if the on-disk token has not been updated by someone else in the meantime.
  const current = await loadToken();
  if (current && current.obtained_at === storedForRefresh.obtained_at) {
    current.access_token = refreshed.access_token;
    current.refresh_token = refreshed.refresh_token;
    current.obtained_at = new Date().toISOString();
    await saveToken(current);
    console.log("[feishu-token] token saved successfully");
  } else {
    console.log("[feishu-token] skipping write — disk already updated by another process");
  }

  // Final re-read — return whatever is on disk (ours or a concurrent writer's).
  const latest = await loadToken();
  if (!latest?.access_token) {
    console.warn("[feishu-token] disk re-read after own refresh returned empty token");
    return null;
  }
  return { token: latest.access_token, calendarId: latest.calendar_id };
}

const FeishuCalendarSchema = Type.Object({
  action: Type.Union([Type.Literal("create_event"), Type.Literal("list_events")]),
  title: Type.Optional(Type.String({ description: "Event title (required for create_event)" })),
  date: Type.Optional(Type.String({ description: "Date in YYYY-MM-DD format" })),
  end_date: Type.Optional(
    Type.String({ description: "End date YYYY-MM-DD (defaults to date+1 for all-day)" }),
  ),
  start_time: Type.Optional(
    Type.String({ description: "Start time HH:MM (omit for all-day event)" }),
  ),
  end_time: Type.Optional(Type.String({ description: "End time HH:MM" })),
  description: Type.Optional(Type.String({ description: "Event description or notes" })),
  days_ahead: Type.Optional(
    Type.Number({ description: "For list_events: how many days ahead to fetch (default 7)" }),
  ),
});

export function createFeishuCalendarTool(): AnyAgentTool {
  return {
    label: "Feishu Calendar",
    name: "feishu_calendar",
    description:
      "Create events in or list events from the user's personal Feishu calendar. " +
      "Use action='create_event' to add a new calendar event with title + date. " +
      "Use action='list_events' to fetch upcoming events. " +
      "For all-day events omit start_time/end_time. For timed events provide both start_time and end_time (HH:MM).",
    parameters: FeishuCalendarSchema,
    execute: async (_toolCallId, params) => {
      const action = readStringParam(params, "action", { required: true });

      const auth = await getValidToken();
      if (!auth) {
        return jsonResult({
          ok: false,
          error:
            "Feishu token unavailable or expired. Re-authorize via /onboard → Feishu in Telegram.",
        });
      }

      const { token, calendarId } = auth;
      const calendarIdEnc = encodeURIComponent(calendarId);

      if (action === "create_event") {
        const title = readStringParam(params, "title", { required: true });
        const date = readStringParam(params, "date", { required: true });

        if (!date.match(/^\d{4}-\d{2}-\d{2}$/)) {
          return jsonResult({ ok: false, error: "date must be YYYY-MM-DD" });
        }

        const startTime = readStringParam(params, "start_time");
        const endTime = readStringParam(params, "end_time");
        const description = readStringParam(params, "description");

        let endDate = readStringParam(params, "end_date");
        if (!endDate) {
          const d = new Date(`${date}T00:00:00+08:00`);
          d.setDate(d.getDate() + 1);
          endDate = d.toISOString().slice(0, 10);
        }

        // Build start/end time objects
        let startTimeObj: Record<string, string>;
        let endTimeObj: Record<string, string>;

        if (startTime && endTime) {
          // Timed event — convert to Unix timestamp (Asia/Shanghai)
          const startTs = Math.floor(new Date(`${date}T${startTime}:00+08:00`).getTime() / 1000);
          const endTs = Math.floor(new Date(`${date}T${endTime}:00+08:00`).getTime() / 1000);
          startTimeObj = { timestamp: String(startTs), timezone: "Asia/Shanghai" };
          endTimeObj = { timestamp: String(endTs), timezone: "Asia/Shanghai" };
        } else {
          // All-day event
          startTimeObj = { date };
          endTimeObj = { date: endDate };
        }

        const body: Record<string, unknown> = {
          summary: title,
          start_time: startTimeObj,
          end_time: endTimeObj,
          visibility: "default",
          color: -1,
        };
        if (description) {
          body.description = description;
        }

        const resp = await fetch(`${FEISHU_BASE}/calendar/v4/calendars/${calendarIdEnc}/events`, {
          method: "POST",
          headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
          body: JSON.stringify(body),
          signal: AbortSignal.timeout(15_000),
        });
        const data = (await resp.json()) as {
          code?: number;
          msg?: string;
          data?: { event?: { event_id?: string } };
        };

        if (data.code !== 0) {
          return jsonResult({ ok: false, error: `Feishu API error ${data.code}: ${data.msg}` });
        }

        return jsonResult({
          ok: true,
          event_id: data.data?.event?.event_id,
          title,
          date,
          start_time: startTime ?? "all-day",
          end_time: endTime ?? "all-day",
        });
      }

      if (action === "list_events") {
        const daysAhead = Number((params as Record<string, unknown>).days_ahead ?? 7);
        const now = new Date();
        const end = new Date(now.getTime() + daysAhead * 86400_000);

        const startTs = Math.floor(now.getTime() / 1000);
        const endTs = Math.floor(end.getTime() / 1000);

        const url =
          `${FEISHU_BASE}/calendar/v4/calendars/${calendarIdEnc}/events` +
          `?start_time=${startTs}&end_time=${endTs}&page_size=50`;

        const resp = await fetch(url, {
          headers: { Authorization: `Bearer ${token}` },
          signal: AbortSignal.timeout(15_000),
        });
        const data = (await resp.json()) as {
          code?: number;
          msg?: string;
          data?: {
            items?: Array<{
              summary?: string;
              start_time?: { date?: string; timestamp?: string };
              end_time?: { date?: string };
            }>;
          };
        };

        if (data.code !== 0) {
          return jsonResult({ ok: false, error: `Feishu API error ${data.code}: ${data.msg}` });
        }

        const items = (data.data?.items ?? []).map((e) => ({
          title: e.summary ?? "(无标题)",
          date:
            e.start_time?.date ??
            (e.start_time?.timestamp
              ? new Date(Number(e.start_time.timestamp) * 1000).toISOString().slice(0, 10)
              : "?"),
        }));

        return jsonResult({ ok: true, count: items.length, events: items });
      }

      return jsonResult({ ok: false, error: `Unknown action: ${action}` });
    },
  };
}
