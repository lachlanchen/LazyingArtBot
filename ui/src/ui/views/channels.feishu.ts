import { html, nothing } from "lit";
import type { FeishuStatus } from "../types.ts";
import type { ChannelsProps } from "./channels.types.ts";
import { formatRelativeTimestamp } from "../format.ts";
import { renderChannelConfigSection } from "./channels.config.ts";

function badge(
  value: boolean | null | undefined,
  labelYes = "Connected",
  labelNo = "Disconnected",
) {
  if (value == null) {
    return html`
      <span class="status-badge muted">n/a</span>
    `;
  }
  return value
    ? html`<span class="status-badge ok">${labelYes}</span>`
    : html`<span class="status-badge danger">${labelNo}</span>`;
}

function yesNo(value: boolean | null | undefined) {
  if (value == null) {
    return html`
      <span class="status-badge muted">n/a</span>
    `;
  }
  return value
    ? html`
        <span class="status-badge ok">Yes</span>
      `
    : html`
        <span class="status-badge muted">No</span>
      `;
}

export function renderFeishuCard(params: {
  props: ChannelsProps;
  feishu?: FeishuStatus | null;
  accountCountLabel: unknown;
}) {
  const { props, feishu, accountCountLabel } = params;
  const domainLabel = feishu?.domain === "lark" ? "Lark (International)" : "Feishu (China)";
  const overallOk = feishu?.configured && feishu?.running;

  return html`
    <div class="card">
      <div class="card-title-row">
        <div class="card-title">
          Feishu / Lark
        </div>
        ${
          feishu
            ? badge(overallOk, "Running", "Stopped")
            : html`
                <span class="status-badge muted">n/a</span>
              `
        }
      </div>
      <div class="card-sub">WebSocket connection status and channel configuration.</div>
      ${accountCountLabel}

      <div class="status-list" style="margin-top: 10px;">
        <div>
          <span class="label">Configured</span>
          ${yesNo(feishu?.configured)}
        </div>
        <div>
          <span class="label">Running</span>
          ${yesNo(feishu?.running)}
        </div>
        <div>
          <span class="label">Connected</span>
          ${badge(feishu?.connected)}
        </div>
        ${
          feishu?.appId
            ? html`
              <div>
                <span class="label">App ID</span>
                <span style="font-family: var(--mono); font-size: 12px;">${feishu.appId}</span>
              </div>
            `
            : nothing
        }
        ${
          feishu?.domain
            ? html`
              <div>
                <span class="label">Domain</span>
                <span>${domainLabel}</span>
              </div>
            `
            : nothing
        }
        ${
          feishu?.connectionMode
            ? html`
              <div>
                <span class="label">Mode</span>
                <span class="status-badge muted">${feishu.connectionMode}</span>
              </div>
            `
            : nothing
        }
        <div>
          <span class="label">Last start</span>
          <span>${feishu?.lastStartAt ? formatRelativeTimestamp(feishu.lastStartAt) : "—"}</span>
        </div>
        <div>
          <span class="label">Last inbound</span>
          <span>${feishu?.lastInboundAt ? formatRelativeTimestamp(feishu.lastInboundAt) : "—"}</span>
        </div>
      </div>

      ${
        feishu?.lastError
          ? html`<div class="callout danger" style="margin-top: 8px;">
            ${feishu.lastError}
          </div>`
          : nothing
      }

      ${renderChannelConfigSection({ channelId: "feishu", props })}
    </div>
  `;
}
