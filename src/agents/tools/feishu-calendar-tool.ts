import { Type } from "@sinclair/typebox";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import type { AnyAgentTool } from "./common.js";
import { jsonResult, readStringParam } from "./common.js";

const FEISHU_BASE = "https://open.feishu.cn/open-apis";
const TOKEN_FILE = path.join(os.homedir(), ".openclaw", "feishu_user_token.json");

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
  await fs.writeFile(TOKEN_FILE, JSON.stringify(token, null, 2));
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

async function getValidToken(): Promise<{ token: string; calendarId: string } | null> {
  const stored = await loadToken();
  if (!stored?.access_token || !stored?.calendar_id) {
    return null;
  }

  const ageSeconds = (Date.now() - new Date(stored.obtained_at).getTime()) / 1000;
  const isExpired = ageSeconds > stored.expires_in - 120;

  if (isExpired) {
    const refreshed = await refreshToken(stored);
    if (!refreshed) {
      return null;
    }
    stored.access_token = refreshed.access_token;
    stored.refresh_token = refreshed.refresh_token;
    stored.obtained_at = new Date().toISOString();
    await saveToken(stored);
  }

  return { token: stored.access_token, calendarId: stored.calendar_id };
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
