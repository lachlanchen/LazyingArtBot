import { html, nothing } from "lit";
import type { CronJob, CronRunLogEntry, CronStatus } from "../types.ts";
import { formatRelativeTimestamp, formatMs } from "../format.ts";
import { pathForTab } from "../navigation.ts";
import { formatCronSchedule, formatNextRun } from "../presenter.ts";

const ORCHESTRAL_KEYWORDS = ["pipeline", "run_"];

type OrchestralProps = {
  basePath: string;
  loading: boolean;
  status: CronStatus | null;
  jobs: CronJob[];
  error: string | null;
  busy: boolean;
  selectedRunJobId: string | null;
  runs: CronRunLogEntry[];
  onRefresh: () => void;
  onRun: (job: CronJob) => void;
  onToggle: (job: CronJob, enabled: boolean) => void;
  onLoadRuns: (jobId: string) => void;
  onOpenCronManager: () => void;
};

export function renderOrchestral(props: OrchestralProps) {
  const orchestralJobs = props.jobs.filter(isOrchestralCronJob);
  const selectedJob =
    props.selectedRunJobId == null
      ? undefined
      : props.jobs.find((job) => job.id === props.selectedRunJobId);
  const selectedRunTitle = selectedJob?.name ?? props.selectedRunJobId ?? "(select a job)";
  const orderedRuns = props.runs.toSorted((a, b) => b.ts - a.ts);

  return html`
    <section class="grid">
      <div class="card">
        <div class="card-title">Orchestral Pipelines</div>
        <div class="card-sub">Curated cron jobs for automation workflows and one-click execution.</div>
        <div class="stat-grid" style="margin-top: 16px;">
          <div class="stat">
            <div class="stat-label">Detected pipelines</div>
            <div class="stat-value">${orchestralJobs.length}</div>
          </div>
          <div class="stat">
            <div class="stat-label">Gateway status</div>
            <div class="stat-value">${props.status ? (props.status.enabled ? "On" : "Off") : "n/a"}</div>
          </div>
          <div class="stat">
            <div class="stat-label">Next wake</div>
            <div class="stat-value">${formatNextRun(props.status?.nextWakeAtMs ?? null)}</div>
          </div>
        </div>
        <div class="row" style="margin-top: 12px; gap: 8px; flex-wrap: wrap;">
          <button class="btn" ?disabled=${props.loading} @click=${props.onRefresh}>
            ${props.loading ? "Refreshing…" : "Refresh"}
          </button>
          <button class="btn" @click=${props.onOpenCronManager}>
            Open cron manager
          </button>
          ${props.error ? html`<span class="muted">${props.error}</span>` : nothing}
        </div>
      </div>

      <div class="card">
        <div class="card-title">Pipelines</div>
        <div class="card-sub">Jobs matching orchestral pipeline patterns.</div>
        ${
          orchestralJobs.length === 0
            ? html`
                <div class="muted" style="margin-top: 12px">
                  No orchestral pipeline jobs detected. Open Cron Jobs to add one.
                </div>
              `
            : html`
              <div class="list" style="margin-top: 12px;">
                ${orchestralJobs.map((job) =>
                  renderOrchestralJob(job, props, props.selectedRunJobId === job.id),
                )}
              </div>
            `
        }
      </div>

      <div class="card">
        <div class="card-title">Run history</div>
        <div class="card-sub">Latest runs for ${selectedRunTitle}.</div>
        ${
          props.selectedRunJobId == null
            ? html`
                <div class="muted" style="margin-top: 12px">Select a job to inspect recent runs.</div>
              `
            : orderedRuns.length === 0
              ? html`
                  <div class="muted" style="margin-top: 12px">No runs yet.</div>
                `
              : html`
                <div class="list" style="margin-top: 12px;">
                  ${orderedRuns.map((entry) => renderOrchestralRun(entry, props.basePath))}
                </div>
              `
        }
      </div>
    </section>
  `;
}

function isOrchestralCronJob(job: CronJob): boolean {
  const payloadText = job.payload.kind === "systemEvent" ? job.payload.text : job.payload.message;
  const haystack = [job.name, job.description, job.agentId, payloadText]
    .filter((entry): entry is string => typeof entry === "string")
    .join(" ")
    .toLowerCase();
  return ORCHESTRAL_KEYWORDS.some((keyword) => haystack.includes(keyword));
}

function renderOrchestralJob(job: CronJob, props: OrchestralProps, selected: boolean) {
  const isActive = selected;
  const state = job.state;
  const payloadText = job.payload.kind === "systemEvent" ? job.payload.text : job.payload.message;
  const itemClass = `list-item list-item-clickable cron-job${isActive ? " list-item-selected" : ""}`;
  return html`
    <div class=${itemClass} @click=${() => props.onLoadRuns(job.id)}>
      <div class="list-main">
        <div class="list-title">${job.name}</div>
        <div class="list-sub">${formatCronSchedule(job)}</div>
        ${
          payloadText
            ? html`
              <div class="cron-job-detail">
                <span class="cron-job-detail-label">Payload</span>
                <span class="muted cron-job-detail-value">${payloadText}</span>
              </div>
            `
            : nothing
        }
        ${job.description ? html`<div class="muted cron-job-agent">${job.description}</div>` : nothing}
        ${job.agentId ? html`<div class="muted cron-job-agent">Agent: ${job.agentId}</div>` : nothing}
      </div>
      <div class="list-meta">
        <div class="cron-job-state-row" style="margin-bottom: 6px;">
          <span class="cron-job-state-key">Status</span>
          <span class="cron-job-status-pill ${
            state?.lastStatus === "ok"
              ? "cron-job-status-ok"
              : state?.lastStatus === "error"
                ? "cron-job-status-error"
                : state?.lastStatus === "skipped"
                  ? "cron-job-status-skipped"
                  : "cron-job-status-na"
          }
          >${state?.lastStatus ?? "n/a"}</span>
        </div>
        ${renderOrchestralTiming("Next", state?.nextRunAtMs)}
        ${renderOrchestralTiming("Last", state?.lastRunAtMs)}
      </div>
      <div class="cron-job-footer">
        <div class="chip-row cron-job-chips">
          <span class=${`chip ${job.enabled ? "chip-ok" : "chip-danger"}`}>
            ${job.enabled ? "enabled" : "disabled"}
          </span>
          <span class="chip">${job.sessionTarget}</span>
          <span class="chip">${job.wakeMode}</span>
        </div>
        <div class="row cron-job-actions">
          <button
            class="btn"
            ?disabled=${props.busy}
            @click=${(event: Event) => {
              event.stopPropagation();
              props.onToggle(job, !job.enabled);
            }}
          >
            ${job.enabled ? "Disable" : "Enable"}
          </button>
          <button
            class="btn"
            ?disabled=${props.busy}
            @click=${(event: Event) => {
              event.stopPropagation();
              props.onRun(job);
            }}
          >
            Run now
          </button>
          <button
            class="btn"
            ?disabled=${props.busy}
            @click=${(event: Event) => {
              event.stopPropagation();
              props.onLoadRuns(job.id);
            }}
          >
            History
          </button>
        </div>
      </div>
    </div>
  `;
}

function renderOrchestralTiming(label: string, ms?: number) {
  if (typeof ms !== "number") {
    return html`
      <div class="cron-job-state-row">
        <span class="cron-job-state-key">${label}</span>
        <span class="cron-job-state-value">n/a</span>
      </div>
    `;
  }
  return html`
    <div class="cron-job-state-row">
      <span class="cron-job-state-key">${label}</span>
      <span class="cron-job-state-value" title=${formatMs(ms)}>${formatRelativeTimestamp(ms)}</span>
    </div>
  `;
}

function renderOrchestralRun(entry: CronRunLogEntry, basePath: string) {
  const chatUrl =
    typeof entry.sessionKey === "string" && entry.sessionKey.trim().length > 0
      ? `${pathForTab("chat", basePath)}?session=${encodeURIComponent(entry.sessionKey)}`
      : null;
  return html`
    <div class="list-item">
      <div class="list-main">
        <div class="list-title">${entry.status}</div>
        <div class="list-sub">${entry.summary ?? ""}</div>
      </div>
      <div class="list-meta">
        <div>${formatMs(entry.ts)}</div>
        <div class="muted">${entry.durationMs ?? 0}ms</div>
        ${chatUrl ? html`<div><a class="session-link" href=${chatUrl}>Open run chat</a></div>` : nothing}
        ${entry.error ? html`<div class="muted">${entry.error}</div>` : nothing}
      </div>
    </div>
  `;
}
