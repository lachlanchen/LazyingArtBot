import { html, nothing, type TemplateResult } from "lit";
import type { GatewayHelloOk } from "../gateway.ts";
import type { UiSettings } from "../storage.ts";
import type {
  ChannelsStatusSnapshot,
  GatewaySessionRow,
  CronJob,
  PresenceEntry,
} from "../types.ts";
import { formatRelativeTimestamp, formatDurationHuman } from "../format.ts";
import { formatNextRun } from "../presenter.ts";

export type OverviewProps = {
  connected: boolean;
  hello: GatewayHelloOk | null;
  settings: UiSettings;
  password: string;
  lastError: string | null;
  presenceCount: number;
  sessionsCount: number | null;
  cronEnabled: boolean | null;
  cronJobsCount: number | null;
  cronNext: number | null;
  lastChannelsRefresh: number | null;
  channelsSnapshot: ChannelsStatusSnapshot | null;
  recentSessions: GatewaySessionRow[];
  cronJobs: CronJob[];
  presenceEntries: PresenceEntry[];
  onSettingsChange: (next: UiSettings) => void;
  onPasswordChange: (next: string) => void;
  onSessionKeyChange: (next: string) => void;
  onConnect: () => void;
  onRefresh: () => void;
};

/* ── helpers ── */

function helpIcon(title: string, body: TemplateResult | string) {
  return html`
    <div class="help-wrap">
      <button class="help-btn" type="button" aria-label="Explain: ${title}">?</button>
      <div class="help-popup">
        <div class="help-popup__title">${title}</div>
        <div class="help-popup__body">${body}</div>
      </div>
    </div>
  `;
}

function statusDot(ok: boolean | null) {
  if (ok === null) {
    return html`
      <span class="arch-status-dot arch-status-dot--muted"></span>
    `;
  }
  return ok
    ? html`
        <span class="arch-status-dot arch-status-dot--ok"></span>
      `
    : html`
        <span class="arch-status-dot arch-status-dot--warn"></span>
      `;
}

function channelEmoji(id: string): string {
  const map: Record<string, string> = {
    telegram: "✈️",
    whatsapp: "📱",
    discord: "🎮",
    slack: "💼",
    feishu: "🪶",
    signal: "🔐",
    imessage: "💬",
    nostr: "⚡",
    matrix: "🔷",
    teams: "🟦",
  };
  return map[id.toLowerCase()] ?? "📡";
}

function fmtTokens(n: number | undefined): string {
  if (!n) {
    return "";
  }
  if (n >= 1000) {
    return `${(n / 1000).toFixed(1)}k tok`;
  }
  return `${n} tok`;
}

/* ── arch diagram ── */

function archDiagram(props: OverviewProps) {
  const snapshot = props.hello?.snapshot as
    | { uptimeMs?: number; policy?: { tickIntervalMs?: number } }
    | undefined;
  const uptime = snapshot?.uptimeMs ? formatDurationHuman(snapshot.uptimeMs) : null;
  const tick = snapshot?.policy?.tickIntervalMs ? `${snapshot.policy.tickIntervalMs}ms` : null;
  const cronLabel = props.cronEnabled == null ? "n/a" : props.cronEnabled ? "Enabled" : "Disabled";
  const cronNextLabel = props.cronNext ? formatNextRun(props.cronNext) : null;
  const channelsRefreshLabel = props.lastChannelsRefresh
    ? formatRelativeTimestamp(props.lastChannelsRefresh)
    : null;

  return html`
    <div class="arch-flow">
      <div class="arch-node">
        <div class="arch-node__icon">📱</div>
        <div class="arch-node__label">Channels</div>
        <div class="arch-channels" style="margin-top:3px">
          <span class="arch-channel-pill">Telegram</span>
          <span class="arch-channel-pill">WhatsApp</span>
          <span class="arch-channel-pill">Discord</span>
          <span class="arch-channel-pill">Feishu</span>
          <span class="arch-channel-pill">+more</span>
        </div>
        ${
          channelsRefreshLabel
            ? html`<div class="arch-node__status arch-node__status--muted" style="margin-top:4px">
              ${statusDot(true)} refreshed ${channelsRefreshLabel}
            </div>`
            : nothing
        }
      </div>

      <div class="arch-arrow">
        <div class="arch-arrow__line"></div>
        <div class="arch-arrow__label">messages</div>
      </div>

      <div class="arch-node ${props.connected ? "arch-node--active" : ""}">
        <div class="arch-node__icon">⚡</div>
        <div class="arch-node__label">Gateway</div>
        <div class="arch-node__sub">routing · auth · config</div>
        <div
          class="arch-node__status ${props.connected ? "arch-node__status--ok" : "arch-node__status--warn"}"
          style="margin-top:4px"
        >
          ${statusDot(props.connected)} ${props.connected ? "Connected" : "Disconnected"}
        </div>
        ${uptime ? html`<div class="arch-node__sub">up ${uptime}</div>` : nothing}
        ${tick ? html`<div class="arch-node__sub">tick ${tick}</div>` : nothing}
      </div>

      <div class="arch-arrow">
        <div class="arch-arrow__line"></div>
        <div class="arch-arrow__label">LLM turn</div>
      </div>

      <div class="arch-node arch-node--accent">
        <div class="arch-node__icon">🤖</div>
        <div class="arch-node__label">Agent</div>
        <div class="arch-node__sub">LLM · tools · memory</div>
        <div class="arch-node__status arch-node__status--muted" style="margin-top:4px">
          ${statusDot(props.connected)} heartbeat · capture
        </div>
      </div>

      <div class="arch-arrow">
        <div class="arch-arrow__line"></div>
        <div class="arch-arrow__label">stores to</div>
      </div>

      <div class="arch-node arch-node--teal">
        <div class="arch-node__icon">💬</div>
        <div class="arch-node__label">Sessions</div>
        <div class="arch-node__sub">context · history</div>
        ${
          props.sessionsCount != null
            ? html`<div class="arch-node__status arch-node__status--ok" style="margin-top:4px">
              ${statusDot(true)} ${props.sessionsCount} active
            </div>`
            : html`<div class="arch-node__status arch-node__status--muted" style="margin-top:4px">
              ${statusDot(null)} loading…
            </div>`
        }
        <div class="arch-node__sub">
          ${props.presenceCount} instance${props.presenceCount !== 1 ? "s" : ""}
        </div>
      </div>

      <div class="arch-arrow">
        <div class="arch-arrow__line"></div>
        <div class="arch-arrow__label">triggers</div>
      </div>

      <div class="arch-node arch-node--info">
        <div class="arch-node__icon">⏰</div>
        <div class="arch-node__label">Cron</div>
        <div class="arch-node__sub">scheduled jobs · delivery</div>
        <div
          class="arch-node__status ${props.cronEnabled ? "arch-node__status--ok" : "arch-node__status--muted"}"
          style="margin-top:4px"
        >
          ${statusDot(props.cronEnabled)} ${cronLabel}
          ${props.cronJobsCount != null ? html` · ${props.cronJobsCount} jobs` : nothing}
        </div>
        ${cronNextLabel ? html`<div class="arch-node__sub">${cronNextLabel}</div>` : nothing}
      </div>
    </div>
  `;
}

/* ── channel health panel ── */

function renderChannelHealth(snapshot: ChannelsStatusSnapshot | null) {
  if (!snapshot) {
    return html`
      <div class="muted" style="padding: 8px 0">No channel data — click Refresh.</div>
    `;
  }

  const order = snapshot.channelMeta?.map((m) => m.id) ?? snapshot.channelOrder ?? [];
  if (order.length === 0) {
    return html`
      <div class="muted" style="padding: 8px 0">No channels configured.</div>
    `;
  }

  return html`
    <div class="overview-channel-grid">
      ${order.map((chId) => {
        const label = snapshot.channelLabels?.[chId] ?? chId;
        const accounts = snapshot.channelAccounts?.[chId] ?? [];
        const connectedCount = accounts.filter((a) => a.connected).length;
        const runningCount = accounts.filter((a) => a.running).length;
        const errorCount = accounts.filter((a) => a.lastError).length;
        const lastInbound = accounts
          .map((a) => a.lastInboundAt ?? 0)
          .filter(Boolean)
          .toSorted((a, b) => b - a)[0];
        const firstError = accounts.find((a) => a.lastError)?.lastError;
        const allOk = accounts.length > 0 && connectedCount === accounts.length;
        const someOk = connectedCount > 0;
        const statusClass = allOk ? "ok" : someOk ? "warn" : "danger";

        return html`
          <div class="overview-channel-card">
            <div class="overview-channel-card__header">
              <span class="overview-channel-card__icon">${channelEmoji(chId)}</span>
              <span class="overview-channel-card__name">${label}</span>
              <span class="status-badge ${statusClass}">
                <span class="status-dot"></span>
                ${
                  accounts.length === 0
                    ? "no accounts"
                    : allOk
                      ? "connected"
                      : someOk
                        ? `${connectedCount}/${accounts.length}`
                        : runningCount > 0
                          ? "running"
                          : "offline"
                }
              </span>
            </div>
            ${
              lastInbound
                ? html`<div class="overview-channel-card__meta">
                  last msg ${formatRelativeTimestamp(lastInbound)}
                </div>`
                : nothing
            }
            ${
              firstError
                ? html`<div class="overview-channel-card__error" title="${firstError}">
                  ⚠ ${firstError.length > 60 ? firstError.slice(0, 60) + "…" : firstError}
                </div>`
                : nothing
            }
          </div>
        `;
      })}
    </div>
  `;
}

/* ── recent sessions panel ── */

function parseSessionKey(key: string): { channel: string | null; rawId: string } {
  // Key formats: "agentId/channel:sender", "channel:sender", "global", custom
  const main = key.includes("/") ? key.split("/").pop()! : key;
  const colon = main.indexOf(":");
  if (colon === -1) {
    return { channel: null, rawId: main };
  }
  return { channel: main.slice(0, colon), rawId: main.slice(colon + 1) };
}

function formatRawId(rawId: string): string {
  // WhatsApp JID: strip @s.whatsapp.net / @g.us
  if (rawId.includes("@")) {
    rawId = rawId.split("@")[0];
  }
  // Phone number: +8613800138000 → +86 138 0013 8000 (simple truncate for now)
  if (/^\+?\d{7,15}$/.test(rawId)) {
    // Show last 4 digits masked: +86 ··· 8000
    return rawId.slice(0, rawId.startsWith("+") ? 3 : 2) + " ···" + rawId.slice(-4);
  }
  // Long opaque ID: keep start + end
  if (rawId.length > 20) {
    return rawId.slice(0, 8) + "…" + rawId.slice(-4);
  }
  return rawId;
}

function sessionDisplayLabel(s: GatewaySessionRow): { primary: string; secondary: string | null } {
  // Best readable name first
  const name = s.displayName ?? s.subject ?? s.room ?? s.label ?? null;
  const { channel, rawId } = parseSessionKey(s.key);
  const idLabel = formatRawId(rawId);

  if (name) {
    // Have a human name — show name + channel:id as secondary
    return { primary: name, secondary: channel ? `${channel}:${idLabel}` : idLabel };
  }
  // No name — show channel prominently + formatted id
  if (channel) {
    return { primary: idLabel, secondary: channel };
  }
  return { primary: idLabel, secondary: null };
}

function renderRecentSessions(sessions: GatewaySessionRow[]) {
  if (sessions.length === 0) {
    return html`
      <div class="muted" style="padding: 8px 0">No recent sessions.</div>
    `;
  }

  return html`
    <div class="overview-session-list">
      ${sessions.map((s) => {
        const { primary, secondary } = sessionDisplayLabel(s);
        const { channel } = parseSessionKey(s.key);
        const emoji = channel ? channelEmoji(channel) : "💬";
        const tokens = fmtTokens(s.totalTokens);
        const model = s.model
          ? s.model
              .split("/")
              .pop()
              ?.replace(/^(claude|gpt|gemini)-?/, "")
              .split("-")
              .slice(0, 2)
              .join("-")
          : null;
        return html`
          <div class="overview-session-row" title="${s.key}">
            <span class="overview-session-row__emoji">${emoji}</span>
            <span class="overview-session-row__info">
              <span class="overview-session-row__name">${primary}</span>
              ${
                secondary
                  ? html`<span class="overview-session-row__sub">${secondary}</span>`
                  : nothing
              }
            </span>
            <span class="overview-session-row__meta">
              ${s.updatedAt ? formatRelativeTimestamp(s.updatedAt) : "—"}
            </span>
            ${tokens ? html`<span class="overview-session-row__tokens">${tokens}</span>` : nothing}
            ${model ? html`<span class="overview-session-row__model">${model}</span>` : nothing}
          </div>
        `;
      })}
    </div>
  `;
}

/* ── upcoming cron jobs ── */

function cronScheduleLabel(job: CronJob): string {
  const s = job.schedule as {
    kind?: string;
    cron?: string;
    every?: number;
    unit?: string;
    at?: string;
  };
  if (s.kind === "cron") {
    return s.cron ?? "cron";
  }
  if (s.kind === "every") {
    return `every ${s.every ?? "?"} ${s.unit ?? ""}`;
  }
  if (s.kind === "at") {
    return `at ${s.at ?? "?"}`;
  }
  return JSON.stringify(s).slice(0, 30);
}

function renderCronJobs(jobs: CronJob[], cronEnabled: boolean | null) {
  if (!cronEnabled) {
    return html`
      <div class="muted" style="padding: 8px 0">Cron scheduler is disabled.</div>
    `;
  }
  if (jobs.length === 0) {
    return html`
      <div class="muted" style="padding: 8px 0">No enabled jobs scheduled.</div>
    `;
  }

  return html`
    <div class="overview-cron-list">
      ${jobs.map((job) => {
        const lastStatus = job.state?.lastStatus;
        const nextRun = job.state?.nextRunAtMs;
        const lastDur = job.state?.lastDurationMs;
        const statusClass =
          lastStatus === "ok" ? "ok" : lastStatus === "error" ? "danger" : "muted";
        return html`
          <div class="overview-cron-row">
            <div class="overview-cron-row__left">
              <span class="overview-cron-row__name">${job.name}</span>
              <span class="overview-cron-row__schedule">${cronScheduleLabel(job)}</span>
            </div>
            <div class="overview-cron-row__right">
              ${
                nextRun
                  ? html`<span class="overview-cron-row__next">${formatRelativeTimestamp(nextRun)}</span>`
                  : nothing
              }
              ${
                lastStatus
                  ? html`<span class="status-badge ${statusClass}">
                    <span class="status-dot"></span>
                    ${lastStatus}${lastDur ? ` ${lastDur}ms` : ""}
                  </span>`
                  : html`
                      <span class="status-badge muted"><span class="status-dot"></span>never run</span>
                    `
              }
            </div>
          </div>
        `;
      })}
    </div>
  `;
}

/* ── contextual hints ── */

type HintLevel = "danger" | "warn" | "info" | "ok";

type Hint = {
  level: HintLevel;
  icon: string;
  text: string;
  tip?: string;
};

function computeHints(props: OverviewProps): Hint[] {
  const hints: Hint[] = [];

  // 1. Not connected
  if (!props.connected) {
    hints.push({
      level: "danger",
      icon: "⚡",
      text: "Not connected to the gateway.",
      tip: "Enter your WebSocket URL and token in Gateway Access, then click Connect.",
    });
    return hints; // downstream hints make no sense without connection
  }

  // 2. Channel errors
  const snapshot = props.channelsSnapshot;
  if (snapshot) {
    const errored: string[] = [];
    const offline: string[] = [];
    const noInbound: string[] = [];
    const staleMs = 24 * 60 * 60 * 1000; // 24h
    const now = Date.now();

    for (const chId of snapshot.channelOrder ?? []) {
      const accounts = snapshot.channelAccounts?.[chId] ?? [];
      if (accounts.length === 0) {
        continue;
      }
      const label = snapshot.channelLabels?.[chId] ?? chId;
      if (accounts.some((a) => a.lastError)) {
        errored.push(label);
      } else if (accounts.every((a) => !a.running)) {
        offline.push(label);
      }

      const lastIn = Math.max(...accounts.map((a) => a.lastInboundAt ?? 0));
      if (lastIn > 0 && now - lastIn > staleMs) {
        noInbound.push(label);
      }
    }

    if (errored.length > 0) {
      hints.push({
        level: "danger",
        icon: "⚠️",
        text: `${errored.length} channel${errored.length > 1 ? "s" : ""} have connection errors: ${errored.join(", ")}.`,
        tip: "Go to the Channels tab to view error details and reconnect.",
      });
    }
    if (offline.length > 0 && errored.length === 0) {
      hints.push({
        level: "warn",
        icon: "📴",
        text: `${offline.length} channel${offline.length > 1 ? "s" : ""} are offline: ${offline.join(", ")}.`,
        tip: "These channels are configured but not running. Check Config or Channels tab.",
      });
    }
    if (noInbound.length > 0) {
      hints.push({
        level: "warn",
        icon: "🔇",
        text: `No inbound messages in 24h on: ${noInbound.join(", ")}.`,
        tip: "The channel may be connected but idle — or messages aren't reaching the gateway.",
      });
    }
    if (snapshot.channelOrder?.length === 0) {
      hints.push({
        level: "info",
        icon: "📱",
        text: "No channels configured yet.",
        tip: "Go to Config → channels to add Telegram, WhatsApp, Discord, or another channel.",
      });
    }
  }

  // 3. Cron disabled but jobs exist
  if (props.cronEnabled === false && props.cronJobsCount && props.cronJobsCount > 0) {
    hints.push({
      level: "warn",
      icon: "⏰",
      text: `Cron scheduler is disabled — ${props.cronJobsCount} job${props.cronJobsCount > 1 ? "s" : ""} won't run.`,
      tip: "Enable cron in Config → gateway.cron.enabled: true.",
    });
  }

  // 4. Cron jobs with recent errors
  const failedJobs = props.cronJobs.filter((j) => j.state?.lastStatus === "error");
  if (failedJobs.length > 0) {
    hints.push({
      level: "warn",
      icon: "🔴",
      text: `${failedJobs.length} cron job${failedJobs.length > 1 ? "s" : ""} failed on last run: ${failedJobs.map((j) => j.name).join(", ")}.`,
      tip: "Go to the Cron tab to view error logs and retry.",
    });
  }

  // 5. No sessions yet
  if (props.sessionsCount === 0 && props.connected) {
    hints.push({
      level: "info",
      icon: "💬",
      text: "No conversations yet.",
      tip: "Send a message from any connected channel — the agent will reply and a session will appear here.",
    });
  }

  // 6. All good
  if (hints.length === 0) {
    hints.push({
      level: "ok",
      icon: "✅",
      text: "Everything looks good.",
      tip: "All channels connected, cron running, no errors detected.",
    });
  }

  return hints;
}

function renderHints(props: OverviewProps) {
  const hints = computeHints(props);
  const levelClass: Record<HintLevel, string> = {
    danger: "hint-bar--danger",
    warn: "hint-bar--warn",
    info: "hint-bar--info",
    ok: "hint-bar--ok",
  };
  return html`
    <section style="display: flex; flex-direction: column; gap: 5px;">
      ${hints.map(
        (h) => html`
          <div class="hint-bar ${levelClass[h.level]}">
            <span class="hint-bar__icon">${h.icon}</span>
            <div class="hint-bar__body">
              <span class="hint-bar__text">${h.text}</span>
              ${h.tip ? html`<span class="hint-bar__tip"> ${h.tip}</span>` : nothing}
            </div>
          </div>
        `,
      )}
    </section>
  `;
}

/* ── main render ── */

export function renderOverview(props: OverviewProps) {
  const snapshot = props.hello?.snapshot as
    | { uptimeMs?: number; policy?: { tickIntervalMs?: number } }
    | undefined;
  const uptime = snapshot?.uptimeMs ? formatDurationHuman(snapshot.uptimeMs) : "n/a";
  const tick = snapshot?.policy?.tickIntervalMs ? `${snapshot.policy.tickIntervalMs}ms` : "n/a";

  const authHint = (() => {
    if (props.connected || !props.lastError) {
      return null;
    }
    const lower = props.lastError.toLowerCase();
    if (!lower.includes("unauthorized") && !lower.includes("connect failed")) {
      return null;
    }
    const hasToken = Boolean(props.settings.token.trim());
    const hasPassword = Boolean(props.password.trim());
    if (!hasToken && !hasPassword) {
      return html`
        <div class="muted" style="margin-top: 8px">
          This gateway requires auth. Add a token or password, then click Connect.
        </div>
      `;
    }
    return html`
      <div class="muted" style="margin-top: 8px">
        Auth failed. Update the token or password, then click Connect.
      </div>
    `;
  })();

  const insecureContextHint = (() => {
    if (props.connected || !props.lastError) {
      return null;
    }
    const isSecureContext = typeof window !== "undefined" ? window.isSecureContext : true;
    if (isSecureContext) {
      return null;
    }
    const lower = props.lastError.toLowerCase();
    if (!lower.includes("secure context") && !lower.includes("device identity required")) {
      return null;
    }
    return html`
      <div class="muted" style="margin-top: 8px">
        HTTP context — use HTTPS (Tailscale Serve) or open
        <span class="mono">http://127.0.0.1:18789</span> on the gateway host.
      </div>
    `;
  })();

  return html`
    <!-- Architecture diagram with live status -->
    <section class="card" style="padding: 0; overflow: visible;">
      <div class="card-title-row" style="padding: 10px 14px 0;">
        <div class="card-title">How it works</div>
        ${helpIcon(
          "System Architecture",
          html`
            <p>
              OpenClaw bridges messaging apps with LLM agents. Live status indicators show current health of
              each component.
            </p>
            <p>
              <span class="help-popup__tag">Channels</span> send/receive messages (Telegram, WhatsApp,
              Discord…).
            </p>
            <p>
              <span class="help-popup__tag">Gateway</span> routes messages, manages auth, config, and
              scheduling.
            </p>
            <p>
              <span class="help-popup__tag">Agent</span> runs an LLM turn — reads context, calls tools,
              generates reply.
            </p>
            <p>
              <span class="help-popup__tag help-popup__tag--ok">Sessions</span> persist conversation history per
              sender.
            </p>
            <p>
              <span class="help-popup__tag help-popup__tag--muted">Cron</span> triggers proactive agent runs on
              a schedule.
            </p>
          `,
        )}
      </div>
      ${archDiagram(props)}
    </section>

    <!-- Contextual hints -->
    <div style="margin-top: 10px;">
      ${renderHints(props)}
    </div>

    <!-- Channel health + Gateway access side by side -->
    <section class="grid grid-cols-2" style="margin-top: 12px;">
      <!-- Channel Health -->
      <div class="card">
        <div class="card-title-row">
          <div class="card-title">Channel Health</div>
          ${helpIcon(
            "Channel Health",
            html`
              <p>Real-time connection status of every configured channel account.</p>
              <p>
                <span class="help-popup__tag help-popup__tag--ok">connected</span> — WebSocket/API connection
                active, receiving messages.
              </p>
              <p><span class="help-popup__tag">N/M</span> — N of M accounts connected.</p>
              <p>
                <span class="help-popup__tag help-popup__tag--muted">offline</span> — channel is configured but
                not running.
              </p>
              <p>
                Last message timestamps help diagnose stale connections. Go to <strong>Channels</strong> tab for
                full details and to reconnect.
              </p>
            `,
          )}
        </div>
        <div class="card-sub">Connection status of all configured channel accounts.</div>
        <div style="margin-top: 8px">${renderChannelHealth(props.channelsSnapshot)}</div>
      </div>

      <!-- Gateway Access -->
      <div class="card">
        <div class="card-title-row">
          <div class="card-title">Gateway Access</div>
          ${helpIcon(
            "Gateway Access",
            html`
              <p>Connect this Control UI to your running OpenClaw gateway process.</p>
              <p>
                <span class="help-popup__tag">WebSocket URL</span> — address of the gateway, e.g.
                <code>ws://localhost:18789</code>.
              </p>
              <p>
                <span class="help-popup__tag">Token</span> — matches <code>OPENCLAW_GATEWAY_TOKEN</code> env var
                on the gateway.
              </p>
              <p><span class="help-popup__tag">Password</span> — system password, not stored in browser.</p>
              <p>
                <span class="help-popup__tag help-popup__tag--muted">Session Key</span> — default session used
                when chatting from this UI.
              </p>
            `,
          )}
        </div>
        <div class="card-sub">Connection settings and authentication.</div>
        <div class="form-grid" style="margin-top: 10px;">
          <label class="field">
            <span>WebSocket URL</span>
            <input
              .value=${props.settings.gatewayUrl}
              @input=${(e: Event) => {
                const v = (e.target as HTMLInputElement).value;
                props.onSettingsChange({ ...props.settings, gatewayUrl: v });
              }}
              placeholder="ws://100.x.y.z:18789"
            />
          </label>
          <label class="field">
            <span>Gateway Token</span>
            <input
              .value=${props.settings.token}
              @input=${(e: Event) => {
                const v = (e.target as HTMLInputElement).value;
                props.onSettingsChange({ ...props.settings, token: v });
              }}
              placeholder="OPENCLAW_GATEWAY_TOKEN"
            />
          </label>
          <label class="field">
            <span>Password (not stored)</span>
            <input
              type="password"
              .value=${props.password}
              @input=${(e: Event) => {
                const v = (e.target as HTMLInputElement).value;
                props.onPasswordChange(v);
              }}
              placeholder="system or shared password"
            />
          </label>
          <label class="field">
            <span>Default Session Key</span>
            <input
              .value=${props.settings.sessionKey}
              @input=${(e: Event) => {
                const v = (e.target as HTMLInputElement).value;
                props.onSessionKeyChange(v);
              }}
            />
          </label>
        </div>
        <div class="row" style="margin-top: 12px;">
          <button class="btn" @click=${() => props.onConnect()}>Connect</button>
          <button class="btn" @click=${() => props.onRefresh()}>Refresh</button>
          <span class="muted">Click Connect to apply changes.</span>
        </div>
        ${
          props.lastError
            ? html`<div class="callout danger" style="margin-top: 12px;">
              <div>${props.lastError}</div>
              ${authHint ?? ""}${insecureContextHint ?? ""}
            </div>`
            : nothing
        }
      </div>
    </section>

    <!-- Stats row -->
    <section class="grid grid-cols-4" style="margin-top: 12px;">
      <div class="card stat-card">
        <div class="card-title-row" style="margin-bottom: 4px;">
          <div class="stat-label">Status</div>
        </div>
        <div class="stat-value ${props.connected ? "ok" : "warn"}">
          ${props.connected ? "Online" : "Offline"}
        </div>
        <div class="muted">uptime ${uptime}</div>
      </div>
      <div class="card stat-card">
        <div class="card-title-row" style="margin-bottom: 4px;">
          <div class="stat-label">Sessions</div>
          ${helpIcon(
            "Sessions",
            html`
              <p>Each unique sender gets an isolated session storing conversation history and context.</p>
              <p>
                Use <span class="help-popup__tag help-popup__tag--muted">/new</span> in chat to reset a session.
                Manage in the <strong>Sessions</strong> tab.
              </p>
            `,
          )}
        </div>
        <div class="stat-value">${props.sessionsCount ?? "—"}</div>
        <div class="muted">${props.presenceCount} instance${props.presenceCount !== 1 ? "s" : ""}</div>
      </div>
      <div class="card stat-card">
        <div class="card-title-row" style="margin-bottom: 4px;">
          <div class="stat-label">Cron Jobs</div>
          ${helpIcon(
            "Cron Scheduler",
            html`
              <p>Built-in scheduler for recurring or one-shot agent runs.</p>
              <p>
                <span class="help-popup__tag">cron</span> — standard cron expression (e.g.
                <code>0 7 * * *</code>).
              </p>
              <p><span class="help-popup__tag">every</span> — interval-based (e.g. every 30 minutes).</p>
              <p><span class="help-popup__tag">at</span> — run once at a specific time.</p>
            `,
          )}
        </div>
        <div class="stat-value">
          ${props.cronJobsCount ?? "—"}
        </div>
        <div class="muted">${props.cronEnabled ? "enabled" : "disabled"} · next ${formatNextRun(props.cronNext)}</div>
      </div>
      <div class="card stat-card">
        <div class="card-title-row" style="margin-bottom: 4px;">
          <div class="stat-label">Tick Interval</div>
          ${helpIcon(
            "Tick Interval",
            html`
              <p>How often the gateway wakes to process heartbeat checks and scheduled jobs.</p>
              <p>Lower values = more responsive proactive delivery, but slightly higher CPU usage.</p>
            `,
          )}
        </div>
        <div class="stat-value">${tick}</div>
        <div class="muted">heartbeat polling</div>
      </div>
    </section>

    <!-- Recent Sessions + Upcoming Cron side by side -->
    <section class="grid grid-cols-2" style="margin-top: 12px;">
      <div class="card">
        <div class="card-title-row">
          <div class="card-title">Recent Sessions</div>
          ${helpIcon(
            "Recent Sessions",
            html`
              <p>The 5 most recently active conversation sessions, sorted by last activity.</p>
              <p><span class="help-popup__tag">DM</span> — direct message session (one sender).</p>
              <p><span class="help-popup__tag">group</span> — group chat session.</p>
              <p>
                Token counts show accumulated usage for that session context. Go to <strong>Sessions</strong> tab
                to view all and reset contexts.
              </p>
            `,
          )}
        </div>
        <div class="card-sub">Last 5 active conversations by recent activity.</div>
        <div style="margin-top: 8px">${renderRecentSessions(props.recentSessions)}</div>
      </div>

      <div class="card">
        <div class="card-title-row">
          <div class="card-title">Upcoming Cron Jobs</div>
          ${helpIcon(
            "Upcoming Cron Jobs",
            html`
              <p>Next 5 enabled scheduled jobs sorted by their next run time.</p>
              <p>
                <span class="help-popup__tag help-popup__tag--ok">ok</span> — last run completed successfully.
              </p>
              <p>
                <span class="help-popup__tag help-popup__tag--muted">danger</span> — last run errored. Check the
                <strong>Cron</strong> tab for the full log.
              </p>
              <p>Duration (ms) shows how long the last execution took.</p>
            `,
          )}
        </div>
        <div class="card-sub">Next 5 enabled jobs sorted by scheduled run time.</div>
        <div style="margin-top: 8px">
          ${renderCronJobs(props.cronJobs, props.cronEnabled)}
        </div>
      </div>
    </section>
  `;
}
