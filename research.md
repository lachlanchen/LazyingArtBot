# Notification System Research

## Overview

The openclaw notification system is multi-layered and event-driven. At its core, notifications are delivered through two complementary pipelines:

1. **Heartbeat pipeline** — a periodic or on-demand LLM run that proactively pushes content to users
2. **System event pipeline** — an in-memory queue that buffers ephemeral events (reactions, exec completions, cron firings, node events) and injects them into the next LLM prompt

These two pipelines intersect: system events trigger heartbeats that relay content. Together they cover every proactive outbound message the bot sends without the user initiating a conversation.

---

## 1. Heartbeat System

### 1.1 What Is a Heartbeat?

A heartbeat is a scheduled background LLM run that reads `HEARTBEAT.md` from the agent workspace and decides whether to send a message to the user. If nothing needs attention, the model replies with the sentinel token `HEARTBEAT_OK` (defined in `src/auto-reply/tokens.ts`) and the run is silent. If there is actionable content, the reply is delivered to the user's last active channel.

The heartbeat system separates _when to run_ (scheduling) from _how to run_ (execution) from _where to deliver_ (routing) from _what to show_ (visibility).

### 1.2 Core Files

| File                                         | Role                                                                               |
| -------------------------------------------- | ---------------------------------------------------------------------------------- |
| `src/infra/heartbeat-runner.ts`              | Orchestrates execution: validates gating, invokes LLM, deduplicates, delivers      |
| `src/infra/heartbeat-wake.ts`                | Coalescing wake signal: `requestHeartbeatNow()` triggers a debounced heartbeat run |
| `src/infra/heartbeat-events.ts`              | Pub/sub for heartbeat status events; feeds the UI indicator                        |
| `src/infra/heartbeat-visibility.ts`          | Resolves per-channel, per-account visibility settings                              |
| `src/infra/heartbeat-active-hours.ts`        | Time-window gating (active hours)                                                  |
| `src/auto-reply/heartbeat.ts`                | Default prompt, `isHeartbeatContentEffectivelyEmpty()`, `stripHeartbeatToken()`    |
| `src/web/auto-reply/heartbeat-runner.ts`     | Separate WhatsApp-specific heartbeat runner (legacy path)                          |
| `src/channels/plugins/whatsapp-heartbeat.ts` | WhatsApp recipient resolution from sessions/allowFrom                              |

### 1.3 Configuration Schema

All fields live under `agents.defaults.heartbeat` (or per-agent `agents.list[n].heartbeat`). Per-agent config is merged on top of defaults (`{ ...defaults, ...overrides }`).

```yaml
agents:
  defaults:
    heartbeat:
      every: "30m" # Duration string, default unit: minutes. Default: "30m"
      model: "" # Optional model override (e.g. "claude-opus-4-6")
      prompt: "" # Override the default HEARTBEAT.md prompt
      ackMaxChars: 300 # Max chars allowed after HEARTBEAT_OK before delivery. Default: 300
      includeReasoning: false # Deliver reasoning payload as separate message. Default: false
      target: "last" # "last" | "none" | channel-id (e.g. "telegram")
      to: "" # Optional explicit recipient (E.164 for WhatsApp, chat ID for Telegram)
      accountId: "" # Optional account ID for multi-account channels
      session: "main" # Session key for heartbeat runs ("main" or explicit key)
      activeHours:
        start: "09:00" # Inclusive start (HH:MM 24h)
        end: "18:00" # Exclusive end (HH:MM). "24:00" = end of day
        timezone: "user" # "user" | "local" | IANA TZ id. Default: "user"
```

**Multi-agent heartbeats:** If any agent in `agents.list` has a `heartbeat` key, the runner only runs heartbeats for agents that explicitly declare one. Otherwise it runs for the single default agent.

### 1.4 Scheduling: `startHeartbeatRunner`

`startHeartbeatRunner()` creates a `HeartbeatRunner` that:

1. Parses all heartbeat agents from config via `resolveHeartbeatAgents()`
2. For each agent, tracks `intervalMs`, `lastRunMs`, `nextDueMs` in an in-memory `Map<string, HeartbeatAgentState>`
3. Arms a `setTimeout` until the nearest `nextDueMs` across all agents
4. On timer fire, calls `requestHeartbeatNow({ reason: "interval", coalesceMs: 0 })`
5. Registers `setHeartbeatWakeHandler()` so external callers (exec tool, cron, node events) can trigger immediate runs

`updateConfig()` can be called live to reconfigure intervals without losing in-progress timing state.

### 1.5 Wake System: `heartbeat-wake.ts`

The wake system decouples "something wants a heartbeat now" from the actual execution. It provides:

```typescript
requestHeartbeatNow({ reason?: string; coalesceMs?: number })
```

Key behaviors:

- **Coalescing**: Multiple concurrent calls within `DEFAULT_COALESCE_MS` (250ms) are batched into a single run
- **Retry on in-flight**: If the main lane is busy (`requests-in-flight`), the wake reschedules with `DEFAULT_RETRY_MS` (1000ms) backoff
- **Single concurrency**: Only one heartbeat runs at a time (`running` flag); additional requests queue via `pendingReason`
- **Reason propagation**: The `reason` string propagates to `runHeartbeatOnce()` to select the right prompt

### 1.6 Execution: `runHeartbeatOnce`

Full step-by-step execution path:

```
1.  Global kill-switch: heartbeatsEnabled?
2.  Per-agent enabled: isHeartbeatEnabledForAgent()?
3.  Interval configured: resolveHeartbeatIntervalMs()?
4.  Active hours: isWithinActiveHours()?
5.  Queue idle: getQueueSize(CommandLane.Main) === 0?
6.  HEARTBEAT.md content:
    - Read file at {workspaceDir}/HEARTBEAT.md
    - Skip if isHeartbeatContentEffectivelyEmpty() AND not exec/cron event
7.  Session resolution: resolveHeartbeatSession()
8.  Delivery target: resolveHeartbeatDeliveryTarget()
9.  Visibility: resolveHeartbeatVisibility()
10. Sender context: resolveHeartbeatSenderContext()
11. Prompt selection:
    - Has exec completion pending? → EXEC_EVENT_PROMPT
    - Has cron events pending?    → CRON_EVENT_PROMPT
    - Otherwise                   → config prompt or HEARTBEAT_PROMPT
12. LLM invocation: getReplyFromConfig(ctx, { isHeartbeat: true })
13. Payload extraction: resolveHeartbeatReplyPayload() (last non-empty payload in array)
14. HEARTBEAT_OK stripping: stripHeartbeatToken()
    - Strips token from edges even through HTML/markdown wrappers
    - If remaining text <= ackMaxChars: shouldSkip=true
15. Duplicate detection:
    - Compare with entry.lastHeartbeatText
    - Skip if same text within 24 hours
16. Delivery check: channel !== "none" && delivery.to exists?
17. Alerts enabled: visibility.showAlerts?
18. Channel readiness: plugin.heartbeat.checkReady()?
19. deliverOutboundPayloads() with [reasoningPayloads..., mainPayload]
20. Save lastHeartbeatText, lastHeartbeatSentAt to session store
21. emitHeartbeatEvent() with status + indicatorType
```

**Special case — `shouldSkip=true` (HEARTBEAT_OK token)**: if `visibility.showOk` is true, sends raw `HEARTBEAT_OK` text (or `{responsePrefix} HEARTBEAT_OK`) before returning. This is the "ping" mode for debugging.

**Session updatedAt restoration**: When a heartbeat is a no-op (ok-empty, ok-token, duplicate), the session's `updatedAt` is restored to its pre-heartbeat value so idle-expiry timers aren't reset by silent runs.

### 1.7 HEARTBEAT_OK Token Stripping Details

`stripHeartbeatToken()` in `src/auto-reply/heartbeat.ts`:

1. Normalizes markup: strips HTML tags, `&nbsp;`, markdown edge wrappers (`**`, `` ` ``, `~`, `_`)
2. Strips `HEARTBEAT_OK` from start/end iteratively
3. If remaining text is empty → `shouldSkip: true`
4. In `"heartbeat"` mode: if `rest.length <= ackMaxChars` → `shouldSkip: true`
5. In `"message"` mode: token is stripped but content is always delivered

`ackMaxChars` defaults to 300. Setting it to 0 means any text after `HEARTBEAT_OK` causes delivery.

### 1.8 HEARTBEAT.md Content Check

`isHeartbeatContentEffectivelyEmpty()` in `src/auto-reply/heartbeat.ts`:

A file is considered "effectively empty" (and heartbeat skipped) when all lines are:

- Empty/whitespace
- Markdown headers (`# Foo`, `## Bar`)
- Empty list items (`- [ ]`, `* `, `- `)

This avoids expensive LLM API calls when no actionable tasks are present. Exception: exec and cron events bypass this check because they carry their content in system events, not HEARTBEAT.md.

### 1.9 Delivery Target Resolution

`resolveHeartbeatDeliveryTarget()` in `src/infra/outbound/targets.ts`:

Priority order for `target` config:

1. `"none"` → always skip delivery (useful with `useIndicator: true` for UI-only heartbeats)
2. explicit channel id (e.g., `"telegram"`) → use that channel
3. `"last"` (default) → use last channel from session store entry

For `accountId` config:

- If specified, validates against `plugin.config.listAccountIds(cfg)`
- Returns `{ channel: "none", reason: "unknown-account" }` if account not found

For `to` config:

- Explicit override of the recipient address
- Otherwise uses `entry.lastTo` from session store

`resolveHeartbeatSenderContext()` resolves the `From` field for the LLM context by matching delivery target against the channel's `allowFrom` list.

### 1.10 Visibility Configuration

`resolveHeartbeatVisibility()` in `src/infra/heartbeat-visibility.ts`:

Four-layer precedence (most specific wins):

```
per-account > per-channel > channel-defaults > built-in defaults
```

Built-in defaults:

```
showOk: false        — silent HEARTBEAT_OK by default
showAlerts: true     — actual content messages shown
useIndicator: true   — emit HeartbeatEvent for UI
```

For `webchat` channel: only `channels.defaults.heartbeat` applies (no per-channel/per-account).

If all three are `false`: heartbeat is skipped entirely (reason: `"alerts-disabled"`).

### 1.11 Active Hours

`isWithinActiveHours()` in `src/infra/heartbeat-active-hours.ts`:

- Parses `start` and `end` as `HH:MM` in configured timezone
- `end > start`: normal range (e.g., 09:00–18:00)
- `end < start`: overnight range (e.g., 22:00–06:00)
- `start === end`: always active
- Missing or invalid times: always active
- Timezone: `"user"` → `cfg.agents.defaults.userTimezone`, `"local"` → host timezone

### 1.12 HeartbeatEvent Pub/Sub

`src/infra/heartbeat-events.ts` exposes a simple event bus:

```typescript
type HeartbeatEventPayload = {
  ts: number;
  status: "sent" | "ok-empty" | "ok-token" | "skipped" | "failed";
  to?: string;
  accountId?: string;
  preview?: string; // First 200 chars of the message
  durationMs?: number;
  hasMedia?: boolean;
  reason?: string;
  channel?: string;
  silent?: boolean; // showOk=false, nothing actually sent
  indicatorType?: "ok" | "alert" | "error";
};
```

`indicatorType` mapping:

- `"ok-empty"` / `"ok-token"` → `"ok"` (green)
- `"sent"` → `"alert"` (yellow/orange)
- `"failed"` → `"error"` (red)
- `"skipped"` → `undefined` (no indicator update)

API:

- `emitHeartbeatEvent()` — publish (called by runner)
- `onHeartbeatEvent(listener)` — subscribe (returns unsubscribe function)
- `getLastHeartbeatEvent()` — get last event (no listener needed)

### 1.13 WhatsApp Legacy Heartbeat

`src/web/auto-reply/heartbeat-runner.ts` provides `runWebHeartbeatOnce()`, a parallel WhatsApp-specific implementation of the same heartbeat logic. It is simpler (no multi-agent, no active hours, no cron/exec events) and was the original WhatsApp heartbeat path. It shares:

- `stripHeartbeatToken()`
- `resolveHeartbeatVisibility()`
- `emitHeartbeatEvent()`
- `resolveWhatsAppHeartbeatRecipients()` for recipient discovery

`resolveWhatsAppHeartbeatRecipients()` in `src/channels/plugins/whatsapp-heartbeat.ts` finds recipients by:

1. Explicit `--to` flag
2. Single recent WhatsApp session entry
3. All session entries (with `--all`)
4. Fallback to `allowFrom` config

### 1.14 Heartbeat Prompts

Three distinct prompts are used:

**Default (`HEARTBEAT_PROMPT`)**:

```
Read HEARTBEAT.md if it exists (workspace context). Follow it strictly. Do not infer
or repeat old tasks from prior chats. If nothing needs attention, reply HEARTBEAT_OK.
```

**Exec event (`EXEC_EVENT_PROMPT`)**:

```
An async command you ran earlier has completed. The result is shown in the system messages
above. Please relay the command output to the user in a helpful way. If the command
succeeded, share the relevant output. If it failed, explain what went wrong.
```

**Cron event (`CRON_EVENT_PROMPT`)**:

```
A scheduled reminder has been triggered. The reminder message is shown in the system
messages above. Please relay this reminder to the user in a helpful and friendly way.
```

Prompt selection in `runHeartbeatOnce()`:

1. Check `peekSystemEvents(sessionKey)` for pending events
2. If any event text contains `"Exec finished"` → EXEC_EVENT_PROMPT
3. If reason starts with `"cron:"` and has pending events → CRON_EVENT_PROMPT
4. Otherwise → configured prompt or HEARTBEAT_PROMPT

The current time is always appended in cron-style format via `appendCronStyleCurrentTimeLine()`.

---

## 2. System Events

### 2.1 What Are System Events?

System events are human-readable strings queued per-session and injected as context into the next LLM run (typically via the next heartbeat). They represent things the user didn't directly say but the agent needs to know: emoji reactions, exec completions, cron reminders, node exec events.

Key design decisions:

- **Ephemeral**: not persisted to disk; lost on process restart
- **Session-scoped**: each session has its own queue
- **Max 20 events per session**: oldest are evicted when full
- **No consecutive duplicates**: same text twice in a row → second is dropped
- **Context key deduplication**: same `contextKey` skips re-enqueue until the key changes

### 2.2 API

`src/infra/system-events.ts`:

```typescript
enqueueSystemEvent(text: string, { sessionKey, contextKey? })
drainSystemEvents(sessionKey: string): string[]      // Consume all, clear queue
drainSystemEventEntries(sessionKey): SystemEvent[]   // Same, with timestamps
peekSystemEvents(sessionKey: string): string[]        // Read without consuming
hasSystemEvents(sessionKey: string): boolean
isSystemEventContextChanged(sessionKey, contextKey?): boolean
```

`contextKey` prevents re-enqueuing the same event class (e.g., same reaction from same user). If the new `contextKey` differs from the last one, the event is always enqueued.

### 2.3 Event Text Formats by Source

```
// Telegram reaction
"Telegram reaction added: 👍 by @username on msg 12345"

// Slack reaction
"Slack reaction added: :thumbsup: by alice in #general msg 1234567890.123456"
"Slack reaction added: :thumbsup: by alice in #general msg ... from bob"

// Discord reaction
"Discord reaction added: 👍 by alice#1234 on ServerName #channel msg 987654321"

// Signal reaction
"Signal reaction added: 👍 by +15551234567 on msg abc123"

// Discord system events (pin, join, boost, etc.)
"Discord system: alice#1234 pinned a message in ServerName #channel"
"Discord system: user joined in ServerName #channel"
"Discord system: alice#1234 boosted the server in ServerName #channel"

// Local exec tool background completion (bash-tools.exec.ts)
"Exec completed (abc12345, code 0) :: last N chars of output..."
"Exec failed (abc12345, signal SIGKILL)"

// Node exec events from paired devices (server-node-events.ts)
"Exec started (node=node-abc123 id=run-xyz): ls -la"
"Exec finished (node=node-abc123 id=run-xyz, code 0)\noutput..."
"Exec denied (node=node-abc123 id=run-xyz, reason): command"

// Cron job (main session target)
"Cron: {agent summary}"
"Cron (error): {error summary}"
```

---

## 3. Reaction Notifications

### 3.1 Architecture

Reactions are not delivered as direct messages. They are translated into system events, which then surface in the next heartbeat run. This means:

- Reaction notification latency = up to heartbeat interval (default: 30 minutes)
- Multiple reactions before a heartbeat fire all appear as separate system context lines

### 3.2 Modes

All channels support modes for `reactionNotifications`:

| Mode          | Behavior                                                             |
| ------------- | -------------------------------------------------------------------- |
| `"off"`       | Ignore all reactions                                                 |
| `"own"`       | (Default) Only reactions to messages the bot sent                    |
| `"all"`       | All reactions in monitored channels                                  |
| `"allowlist"` | Only from users in `reactionAllowlist` (Slack, Discord, Signal only) |

Telegram supports only `"off" | "own" | "all"` (no allowlist mode).

### 3.3 Telegram (`src/telegram/bot.ts`)

- Listens for `message_reaction` updates via `bot.on("message_reaction")`
- Default mode: `"own"` (config: `channels.telegram.reactionNotifications`)
- `"own"` mode: calls `wasSentByBot(chatId, messageId)` to check authorship
- Skips reactions from bots
- Detects _added_ reactions by diffing `old_reaction` vs `new_reaction` emoji sets
- **Forum threading note**: Telegram reaction events do not include `message_thread_id`, so reactions always route to the main thread session key
- Context key: `telegram:reaction:add:{chatId}:{messageId}:{userId}:{emoji}`

Additional config: `reactionLevel: "off" | "ack" | "minimal" | "extensive"` controls whether the _bot_ sends reaction acknowledgements back (separate from receiving reactions).

### 3.4 Slack (`src/slack/monitor/events/reactions.ts`)

- Handles `reaction_added` and `reaction_removed`
- Only processes `item.type === "message"` (ignores file/file_comment reactions)
- Channel allowlist check via `ctx.isChannelAllowed()`
- Resolves channel name, actor name, author name via Slack API calls
- System event text includes channel label, actor, emoji, message timestamp, author
- Context key: `slack:reaction:{action}:{channelId}:{messageTs}:{userId}:{emoji}`
- Mode config: `channels.slack.reactionNotifications` or per-account
- Allowlist: `channels.slack.reactionAllowlist: Array<string | number>`

### 3.5 Discord (`src/discord/monitor/listeners.ts`)

- Handles `MessageReactionAdd` and `MessageReactionRemove` Carbon events
- `shouldEmitDiscordReactionNotification()` evaluates mode against guild config
- In `"allowlist"` mode: checks user ID/username against `reactionAllowlist`
- Handles custom emoji formatting (`:name:` for standard, `<:name:id>` for custom)
- Context key: `discord:reaction:{action}:{messageId}:{userId}:{emoji}`
- Also processes Discord _system_ message types (pin, join, boost, stage, poll, etc.) via `resolveDiscordSystemEvent()` in `src/discord/monitor/system-events.ts`

Discord user allowlist normalization (`src/discord/monitor/allow-list.ts`):

- Numeric strings = Discord user IDs
- `"@username"` or plain username = Discord usernames
- `"pk:{id}"` = PluralKit proxy identities
- `"*"` = wildcard (all users)

### 3.6 Signal (`src/signal/monitor.ts`)

- Mode config: `channels.signal.reactionNotifications` (default: `"own"`)
- Allowlist: `channels.signal.reactionAllowlist`
- Also supports `reactionLevel` for bot-sent reactions

---

## 4. Exec Completion Notifications

### 4.1 Background Exec

When the exec tool runs with `background: true` (or times out and yields), the process is tracked in `BashProcessRegistry`. On exit, `maybeNotifyOnExit()` is called.

**File**: `src/agents/bash-tools.exec.ts`

```typescript
function maybeNotifyOnExit(session: ProcessSession, status: "completed" | "failed") {
  // Guards: session.backgrounded && session.notifyOnExit && !session.exitNotified
  session.exitNotified = true;

  // Text format: "Exec {status} ({id.slice(0,8)}, {exitLabel}) :: {tail output}"
  enqueueSystemEvent(summary, { sessionKey });
  requestHeartbeatNow({ reason: `exec:${session.id}:exit` });
}
```

`notifyOnExit` defaults to `true` (controlled by `defaults.notifyOnExit !== false` in the tool factory).

Tail output: last `DEFAULT_NOTIFY_TAIL_CHARS` characters of output, with trailing whitespace stripped.

### 4.2 Remote Exec (via Paired Node)

When exec events arrive from paired iOS/macOS nodes via WebSocket, `handleNodeEvent()` in `src/gateway/server-node-events.ts` processes them:

- `exec.started` → enqueues `"Exec started (node=...) : command"`
- `exec.finished` → enqueues `"Exec finished (node=..., code N)\noutput"`
- `exec.denied` → enqueues `"Exec denied (node=..., reason): command"`

All three call `enqueueSystemEvent()` + `requestHeartbeatNow({ reason: "exec-event" })`.

### 4.3 Heartbeat Integration

The heartbeat runner checks `peekSystemEvents()` for `"Exec finished"` text when reason starts with `"exec:"` or equals `"exec-event"`. If found, uses `EXEC_EVENT_PROMPT` instead of the standard prompt, ensuring the model relays results rather than just checking HEARTBEAT.md.

**Exec fallback**: if `EXEC_EVENT_PROMPT` is used but `stripHeartbeatToken()` returns empty text (model returned HEARTBEAT_OK), the raw reply text is used as a fallback to prevent exec output from being swallowed.

---

## 5. Cron Job Notifications

### 5.1 Cron Job Types

**File**: `src/cron/types.ts`

```typescript
type CronSchedule =
  | { kind: "at"; at: string }                      // One-shot: ISO 8601 or human date
  | { kind: "every"; everyMs: number }               // Repeating: interval in ms
  | { kind: "cron"; expr: string; tz?: string }      // Cron expression with optional timezone

type CronSessionTarget = "main" | "isolated";
type CronWakeMode = "next-heartbeat" | "now";

type CronPayload =
  | { kind: "systemEvent"; text: string }            // Inject text into main session
  | { kind: "agentTurn"; message: string; ... }      // Run isolated agent turn
```

### 5.2 Main Session Jobs (systemEvent payload)

For `sessionTarget: "main"` with `payload.kind: "systemEvent"`:

1. Text is enqueued into the main session via `enqueueSystemEvent(text, { agentId })`
2. If `wakeMode: "now"`: calls `runHeartbeatOnce({ reason: "cron:{jobId}" })` directly, with up to 2-minute wait on in-flight requests
3. If `wakeMode: "next-heartbeat"`: calls `requestHeartbeatNow({ reason: "cron:{jobId}" })` (coalesced)

### 5.3 Isolated Agent Jobs (agentTurn payload)

For `sessionTarget: "isolated"` with `payload.kind: "agentTurn"`:

1. `runCronIsolatedAgentTurn()` runs the agent in a separate `cron:{jobId}` session
2. The agent's response summary is posted back to the main session as: `"Cron: {summary}"` or `"Cron (error): {summary}"`
3. If `wakeMode: "now"`, an immediate heartbeat is requested to relay the summary

### 5.4 Cron Job Lifecycle

**Scheduling**: `armTimer()` sleeps until the nearest `nextRunAtMs`, capped at 60 seconds to handle clock drift. Timer re-arms itself even while a job is running (prevents silent scheduler death on long-running jobs).

**Backoff on error**:

```
1st error  →  30s
2nd error  →   1m
3rd error  →   5m
4th error  →  15m
5th+ error →  60m
```

**One-shot jobs** (`schedule.kind: "at"`): disabled after any terminal status (ok/error/skipped). If `deleteAfterRun: true`, the job record is deleted on success.

**Missed jobs**: On gateway restart, jobs with `nextRunAtMs` in the past are run immediately via `runMissedJobs()`.

### 5.5 CronService Architecture

`CronService` in `src/cron/service.ts` accepts injectable dependencies:

- `enqueueSystemEvent()` — wires to infra system events queue
- `requestHeartbeatNow()` — wires to heartbeat wake
- `runHeartbeatOnce()` — wires to heartbeat runner
- `runIsolatedAgentJob()` — wires to isolated agent execution
- `onEvent()` — events broadcast to WebSocket clients via `params.broadcast("cron", evt)`

Cron events are also logged to `{cronStorePath}/runs/{jobId}.jsonl` via `appendCronRunLog()`.

---

## 6. Node/Device Notifications

### 6.1 Local System Notifications (CLI)

**File**: `src/cli/nodes-cli/register.notify.ts`

**CLI command**: `openclaw nodes notify`

```
--node <idOrNameOrIp>      Required: target node
--title <text>             Notification title
--body <text>              Notification body
--sound <name>             Notification sound name
--priority <passive|active|timeSensitive>
--delivery <system|overlay|auto>   Default: "system"
--invoke-timeout <ms>      Default: 15000ms
```

Calls `node.invoke` RPC with command `"system.notify"` via the gateway. macOS only.

### 6.2 Node Event Handling

**File**: `src/gateway/server-node-events.ts`

Processes WebSocket events from paired nodes:

| Event              | Action                                     |
| ------------------ | ------------------------------------------ |
| `voice.transcript` | Runs agent turn with voice transcript text |
| `agent.request`    | Runs agent turn via deep link              |
| `chat.subscribe`   | Subscribes node to session updates         |
| `chat.unsubscribe` | Unsubscribes node from session             |
| `exec.started`     | Enqueues system event + triggers heartbeat |
| `exec.finished`    | Enqueues system event + triggers heartbeat |
| `exec.denied`      | Enqueues system event + triggers heartbeat |

---

## 7. Outbound Delivery System

### 7.1 Architecture

`deliverOutboundPayloads()` in `src/infra/outbound/deliver.ts` is the universal delivery layer used by both heartbeats and agent replies.

Parameters:

```typescript
{
  cfg: OpenClawConfig,
  channel: DeliverableMessageChannel,
  to: string,
  accountId?: string,
  payloads: ReplyPayload[],
  deps?: OutboundSendDeps,
}
```

### 7.2 Supported Channels

WhatsApp, Telegram, Discord, Slack, Signal, iMessage, Matrix, Microsoft Teams.

### 7.3 Payload Types

```typescript
type ReplyPayload = {
  text?: string;
  mediaUrl?: string;
  mediaUrls?: string[];
};
```

Reasoning payloads are identified by `text.trimStart().startsWith("Reasoning:")`. When `includeReasoning: true`, they are delivered as separate messages before the main payload.

---

## 8. Gating and Suppression Reference

### 8.1 Complete Heartbeat Skip Reasons

| Reason                   | Condition                                                                     |
| ------------------------ | ----------------------------------------------------------------------------- |
| `"disabled"`             | Global kill-switch or agent not enabled or no interval configured             |
| `"quiet-hours"`          | Outside `activeHours` window                                                  |
| `"requests-in-flight"`   | Main lane has pending requests (will retry in 1s)                             |
| `"empty-heartbeat-file"` | HEARTBEAT.md exists but has no actionable content                             |
| `"alerts-disabled"`      | All three visibility flags (`showOk`, `showAlerts`, `useIndicator`) are false |
| `"no-target"`            | No delivery target found in session store                                     |
| `"unknown-account"`      | `heartbeat.accountId` doesn't match any configured account                    |
| `"target-none"`          | `heartbeat.target: "none"` explicitly configured                              |
| `"duplicate"`            | Same text as previous heartbeat within 24 hours                               |
| `"{readiness.reason}"`   | Channel plugin `checkReady()` returned not-ok                                 |

### 8.2 Heartbeat Event Status Values

| Status       | Meaning                               | Indicator |
| ------------ | ------------------------------------- | --------- |
| `"sent"`     | Message delivered to user             | `"alert"` |
| `"ok-empty"` | LLM returned no content (empty reply) | `"ok"`    |
| `"ok-token"` | LLM returned HEARTBEAT_OK token       | `"ok"`    |
| `"skipped"`  | Run was gated out before LLM call     | none      |
| `"failed"`   | LLM call or delivery threw an error   | `"error"` |

### 8.3 Session updatedAt Restoration

To prevent heartbeat runs from keeping sessions "alive" (which would block idle-expiry), the session `updatedAt` is restored to its pre-heartbeat value when the run is a no-op (ok-empty, ok-token, duplicate). This is done via `restoreHeartbeatUpdatedAt()` which does a careful atomic update via `updateSessionStore()`.

---

## 9. Integration Points

### 9.1 How Exec Completions Flow

```
exec tool runs command in background
  │
  └─ process exits
       │
       ├─ maybeNotifyOnExit() [bash-tools.exec.ts]
       │    ├─ enqueueSystemEvent("Exec completed ... :: output")
       │    └─ requestHeartbeatNow({ reason: "exec:{id}:exit" })
       │
       └─ heartbeat-wake coalesces → runHeartbeatOnce({ reason: "exec-event" })
            │
            ├─ peekSystemEvents() → finds "Exec finished" text
            ├─ selects EXEC_EVENT_PROMPT
            ├─ getReplyFromConfig() with system events injected as context
            └─ delivers LLM response to user
```

### 9.2 How Cron Reminders Flow

```
armTimer() fires for due job
  │
  └─ executeJobCore() [cron/service/timer.ts]
       │
       ├─ (systemEvent payload, main session)
       │    ├─ enqueueSystemEvent(text, { agentId })
       │    └─ requestHeartbeatNow({ reason: "cron:{jobId}" })
       │         └─ heartbeat selects CRON_EVENT_PROMPT
       │
       └─ (agentTurn payload, isolated session)
            ├─ runCronIsolatedAgentTurn()
            │    └─ agent runs, generates summary
            └─ enqueueSystemEvent("Cron: {summary}")
                 └─ requestHeartbeatNow({ reason: "cron:{jobId}" })
```

### 9.3 How Reaction Events Flow

```
Channel receives reaction event
  │
  └─ [telegram|slack|discord|signal] monitor
       │
       ├─ filter by reactionNotifications mode
       ├─ check channel allowlist
       │
       └─ enqueueSystemEvent(text, { sessionKey, contextKey })
            │
            └─ next heartbeat tick
                 ├─ drainSystemEvents() during LLM context build
                 └─ LLM sees reaction text in system context
                      └─ responds and delivers via heartbeat
```

### 9.4 Gateway-Level Orchestration

`src/gateway/server-cron.ts` (`buildGatewayCronService()`):

- Wires `CronService` to `enqueueSystemEvent`, `requestHeartbeatNow`, `runHeartbeatOnce`
- Broadcasts cron events to WebSocket clients via `params.broadcast("cron", evt)`
- Logs finished jobs to `{storePath}/runs/{jobId}.jsonl`

`startHeartbeatRunner()` is called once at gateway startup with the initial config. `updateConfig()` is available for live reconfiguration.

---

## 10. Key Constants

| Constant                             | Value                    | Location                            |
| ------------------------------------ | ------------------------ | ----------------------------------- |
| `DEFAULT_HEARTBEAT_EVERY`            | `"30m"`                  | `src/auto-reply/heartbeat.ts`       |
| `DEFAULT_HEARTBEAT_ACK_MAX_CHARS`    | `300`                    | `src/auto-reply/heartbeat.ts`       |
| `DEFAULT_COALESCE_MS`                | `250`                    | `src/infra/heartbeat-wake.ts`       |
| `DEFAULT_RETRY_MS`                   | `1000`                   | `src/infra/heartbeat-wake.ts`       |
| `MAX_EVENTS` (system events queue)   | `20`                     | `src/infra/system-events.ts`        |
| `MAX_TIMER_DELAY_MS` (cron tick cap) | `60000`                  | `src/cron/service/timer.ts`         |
| `DEFAULT_JOB_TIMEOUT_MS` (cron job)  | `600000` (10 min)        | `src/cron/service/timer.ts`         |
| `HEARTBEAT_TOKEN`                    | `"HEARTBEAT_OK"`         | `src/auto-reply/tokens.ts`          |
| Duplicate suppression window         | `24 * 60 * 60 * 1000` ms | `src/infra/heartbeat-runner.ts:629` |
| Cron immediate-mode wait timeout     | `2 * 60_000` ms          | `src/cron/service/timer.ts:456`     |

---

## 11. Test Coverage

| Test File                                                                | Coverage                               |
| ------------------------------------------------------------------------ | -------------------------------------- |
| `src/infra/heartbeat-runner.scheduler.test.ts`                           | Scheduler timing, multi-agent          |
| `src/infra/heartbeat-runner.model-override.test.ts`                      | Model override config                  |
| `src/infra/heartbeat-runner.respects-ackmaxchars-heartbeat-acks.test.ts` | ackMaxChars behavior                   |
| `src/infra/heartbeat-runner.returns-default-unset.test.ts`               | Default config values                  |
| `src/infra/heartbeat-runner.sender-prefers-delivery-target.test.ts`      | Sender resolution                      |
| `src/infra/heartbeat-visibility.test.ts`                                 | Visibility precedence rules            |
| `src/infra/heartbeat-active-hours.test.ts`                               | Time window gating                     |
| `src/infra/system-events.test.ts`                                        | Queue dedup, drain, peek               |
| `src/auto-reply/heartbeat.test.ts`                                       | Token stripping, empty content check   |
| `src/auto-reply/reply.heartbeat-typing.test.ts`                          | Heartbeat typing indicator integration |
| `src/web/auto-reply/heartbeat-runner.timestamp.test.ts`                  | WhatsApp heartbeat                     |
| `src/gateway/server-node-events.test.ts`                                 | Node exec event handling               |
| `src/cron/service*.test.ts`                                              | Cron scheduling, delivery, backoff     |

---

## 12. Configuration Examples

### Minimal heartbeat (every 30 minutes, default)

```yaml
agents:
  defaults:
    heartbeat:
      every: "30m"
```

### Quiet hours heartbeat (work hours only)

```yaml
agents:
  defaults:
    heartbeat:
      every: "15m"
      activeHours:
        start: "09:00"
        end: "18:00"
        timezone: "America/New_York"
```

### Debug mode — show HEARTBEAT_OK pings

```yaml
channels:
  telegram:
    heartbeat:
      showOk: true
      showAlerts: true
```

### UI-only heartbeat (indicator updates, no messages sent)

```yaml
agents:
  defaults:
    heartbeat:
      target: "none"
channels:
  defaults:
    heartbeat:
      useIndicator: true
      showAlerts: false
      showOk: false
```

### Multi-account Telegram with per-account visibility

```yaml
channels:
  telegram:
    accounts:
      personal:
        heartbeat:
          showOk: false
          showAlerts: true
      work:
        heartbeat:
          showOk: true
          showAlerts: true
```

### Include reasoning in heartbeat delivery

```yaml
agents:
  defaults:
    heartbeat:
      includeReasoning: true
      model: "claude-opus-4-6"
```

### Reaction notifications from specific users only (Discord)

```yaml
channels:
  discord:
    guilds:
      my-guild-id:
        reactionNotifications: "allowlist"
        reactionAllowlist: ["12345678901234567", "alice"]
```

---

## 13. Capture Agent & Memory Closed Loop

> Added 2026-02-26. Documents the capture pipeline, assistant_hub structure, and the write→read closed loop built in this session.

### 13.1 Overview: The Gap That Was Closed

Before this work, the system had a **write-only memory**: the capture agent stored all inbound messages into `assistant_hub/` but the LLM never read it back. Every conversation started fresh with no memory of what was captured.

The closed loop now works as follows:

```
User message
  ↓
[capture agent] classifies & writes → assistant_hub/
  ↓ [Plan A]
  action/watch/timeline → appended to HEARTBEAT.md (pending list)
  ↓
LLM responds — system prompt NOW includes:
  • Today's daily log (what user said today)
  • Unchecked tasks from tasks_master.md
  • Watching/waiting items
  ↓ [Plan C]
LLM has short-term memory of recent events
  ↓
Heartbeat triggers → reads HEARTBEAT.md → proactive follow-up
```

### 13.2 Capture Agent Architecture

**Entry point**: `src/auto-reply/reply/maybe-run-capture.ts` → `maybeRunCapture()`

**Core logic**: `src/capture-agent/run.ts` → `runCaptureAgent()`

**Enable flags**:

- `MOLTBOT_CAPTURE_ENABLED=1` (env) or `capture.enabled: true` (config)
- `MOLTBOT_CAPTURE_ALSO_REPLY=1` (env) or `capture.alsoReply: true` (config) — capture silently, LLM also responds (default mode)

**Flow**:

1. Inbound message → `maybeRunCapture()` called before LLM dispatch
2. `runCaptureAgent()` classifies the message via `classifyCaptureInput()` (rule-based, no LLM)
3. Writes card/log to `assistant_hub/` via `applyFileOps()`
4. Returns ACK text (suppressed when `alsoReply=true`)
5. LLM continues to respond normally

### 13.3 assistant_hub Directory Structure

Location: `~/.openclaw/workspace/automation/assistant_hub/` (or `CAPTURE_HUB_ROOT` env)

```
assistant_hub/
  00_inbox/           # Raw inbox: YYYY-MM-DD_<source>_inbox.md (one per day per channel)
  02_work/
    tasks_master.md   # All action/watch items as markdown checkboxes
    waiting.md        # Watch-type items pending outcome
    calendar.md       # Timeline/deadline entries (markdown table)
    done.md           # Archived completions
    tasks/            # Individual task cards (YYYY-MM-DD-NNN_slug.md)
    projects/         # Project timeline cards
  03_life/
    daily_logs/       # Memory-type entries: YYYY-MM-DD.md (append-only)
    ideas/            # Idea cards + _ideas_index.md
    highlights/       # Highlight cards
  04_knowledge/
    people/           # Person cards
    questions/        # Question cards + _index.md
    beliefs/          # Belief cards + _index.md
    references/       # Reference cards
  05_meta/
    reasoning_queue.jsonl       # Capture inference metadata (JSONL)
    feedback_signals.jsonl      # Feedback loop signals
    capture_agent_weekly_review.md
  TAGS.md             # Tag registry
  index.md            # Directory map
```

### 13.4 Capture Types

| Type        | Emoji | Storage location                     | Heartbeat?              |
| ----------- | ----- | ------------------------------------ | ----------------------- |
| `action`    | ⚡    | `02_work/tasks/` + `tasks_master.md` | ✅ always               |
| `watch`     | 👀    | `02_work/tasks/` + `waiting.md`      | ✅ always               |
| `timeline`  | 📍    | `02_work/projects/` + `calendar.md`  | ✅ always               |
| `idea`      | 💡    | `03_life/ideas/` + `_ideas_index.md` | if `nextBestAction` set |
| `memory`    | 📝    | `03_life/daily_logs/YYYY-MM-DD.md`   | if `nextBestAction` set |
| `question`  | ❓    | `04_knowledge/questions/`            | if `nextBestAction` set |
| `belief`    | 🧠    | `04_knowledge/beliefs/`              | if `nextBestAction` set |
| `highlight` | ✨    | `03_life/highlights/`                | if `nextBestAction` set |
| `reference` | 📖    | `04_knowledge/references/`           | if `nextBestAction` set |
| `person`    | 👤    | `04_knowledge/people/`               | if `nextBestAction` set |

### 13.5 Plan A — HEARTBEAT.md Bridge

**File**: `src/auto-reply/reply/maybe-run-capture.ts` → `maybeUpdateHeartbeat()`

**Trigger**: Called after every successful `runCaptureAgent()` call.

**Logic**:

- If item `type` is `action`, `watch`, or `timeline` → always append
- If item has a non-null, non-empty `nextBestAction` → append as `[跟進]` item
- Otherwise (e.g. pure `memory` log) → skip

**Format appended to `~/.openclaw/workspace/HEARTBEAT.md`**:

```
- [ ] [action] 任務標題 (id:2026-02-26-001) due:2026-03-01 · 02/26 09:00
- [ ] [watch]  追蹤中項目 (id:2026-02-26-002) · 02/26 09:01
- [ ] [跟進]   下一步行動 (ref:2026-02-26-003) · 02/26 09:02
```

**LLM behavior**: On next heartbeat, LLM reads HEARTBEAT.md, sees pending `[ ]` items, takes action (reminds, escalates, marks done). LLM is responsible for cleaning up completed items (marking `[x]` or deleting).

**Path calculation**: `resolveHubRoot()` → go 2 levels up → `workspace/` → `HEARTBEAT.md`

### 13.6 Plan C — Inbound Context Injection

**Files**:

- `src/auto-reply/reply/hub-context.ts` → `buildHubContext()`
- `src/auto-reply/reply/get-reply-run.ts` (patched at `extraSystemPrompt` assembly)

**Trigger**: Every inbound user message (skipped during heartbeat runs to avoid noise).

**What is injected** (max ~3000 chars total, appended to `extraSystemPrompt`):

```
## 近期記憶 (capture 記憶系統)
以下是自動從 assistant_hub 讀取的近期背景資料，供你了解最近發生的事：

## 今日記錄 (YYYY-MM-DD)
[last ~1500 chars of daily_logs/YYYY-MM-DD.md]

## 待辦
[last 8 unchecked items from tasks_master.md]

## 追蹤中
[last ~800 chars of waiting.md]
```

**Fallback**: If today's daily log is empty, yesterday's log is used instead.

**Injection point** in `get-reply-run.ts` (line ~189):

```typescript
const hubContext = !isHeartbeat ? await buildHubContext() : "";
const extraSystemPrompt = [inboundMetaPrompt, groupIntro, groupSystemPrompt, hubContext]
  .filter(Boolean)
  .join("\n\n");
```

### 13.7 Heartbeat as Proactive Agent (Step 2)

> Added 2026-02-26. Documents the HEARTBEAT.md playbook that turns the heartbeat from a passive task list into an active patrol loop.

#### Tool Availability During Heartbeat (confirmed by code audit)

| Capability             | Available? | Notes                                          |
| ---------------------- | ---------- | ---------------------------------------------- |
| `read` tool            | ✅ Yes     | Full file read                                 |
| `find` / `grep` tools  | ✅ Yes     | Shell-level search                             |
| `write` tool           | ✅ Yes     | Can update HEARTBEAT.md itself                 |
| `exec` tool            | ✅ Yes     | Full shell access                              |
| Lite / restricted mode | ❌ No      | `isHeartbeat` flag does NOT affect tool policy |

The `isHeartbeat` flag is only used for: typing animation skip, hub context injection skip (`buildHubContext()`), memory flush skip. **Tools are identical to normal inbound runs.**

Key file references:

- `src/infra/heartbeat-runner.ts:548` — invokes `getReplyFromConfig` with `{ isHeartbeat: true }`
- `src/agents/pi-tools.ts:115` — `createOpenClawCodingTools()` has no `isHeartbeat` parameter
- `src/agents/pi-embedded-runner/run/params.ts` — `RunEmbeddedPiAgentParams` has no `isHeartbeat` field

#### HEARTBEAT.md Playbook Format

`~/.openclaw/workspace/HEARTBEAT.md` serves dual purpose:

1. **Task list** — auto-appended by capture agent (Plan A)
2. **Behavior spec** — playbook instructions the LLM follows every heartbeat

Current playbook (as of 2026-02-26):

```markdown
## 每次心跳執行流程

1. 掃描最近新增的 capture（上一個心跳週期內）：
   find ~/.openclaw/workspace/automation/assistant*hub -mmin -65 -name "*.md" \
    -not -path "*/*\*" -not -name "index.md" -not -name "TAGS.md"
   讀取新增文件，判斷是否有需要主動通知 Ken 的事項

2. 處理下方「待跟進」清單中的 [ ] 條目：
   - 對比今天日期，判斷是否到期或接近截止
   - 採取行動後將 [ ] 改為 [x]

3. 清理：刪除所有 [x] 條目，保持此文件整潔

4. 若無任何需要通知的事項 → 回覆 HEARTBEAT_OK
```

#### End-to-End Examples

**Example 1 — 任務到期提醒**

1. Ken says: 「明天下午3點要打電話給投資人 David」
2. Capture → `action`, due:tomorrow → HEARTBEAT.md appended
3. Next heartbeat near due time → LLM sees `[ ]` item → sends reminder

**Example 2 — 主動掃描發現新事項**

1. Ken stores a `timeline` item via capture
2. 30 min later heartbeat runs → `find -mmin -65` returns the new file
3. LLM reads it, checks if it's already in HEARTBEAT.md pending list → avoids duplicate

**Example 3 — 自清理 + 連貫追蹤**

1. Old `[ ] [watch]` item for "waiting for Eric's reply"
2. Ken says Eric replied → capture adds `[ ] [跟進]` for next step
3. Heartbeat LLM sees both entries → marks old watch `[x]` → acts on new 跟進 → self-cleans

#### Why No Code Changes Needed

The entire Step 2 capability is driven by:

- LLM's existing `find`/`read`/`write` tool access (always had it)
- HEARTBEAT.md content as executable playbook
- Plan A already populating HEARTBEAT.md with actionable items

Zero new code. Heartbeat interval default: `30m` (configurable via `agents.defaults.heartbeat.every`).

---

### 13.8 Deployment Notes

- **Service**: systemd user service at `/root/.config/systemd/user/openclaw-gateway.service`
- **Restart script**: `/usr/local/bin/openclaw-restart` — restarts service, waits for build, kills zombie processes automatically
- **Key env vars** in service file:
  - `MOLTBOT_CAPTURE_ENABLED=1`
  - `MOLTBOT_CAPTURE_ALSO_REPLY=1`
- **Zombie process issue**: On restart, old `openclaw-gateway` processes survive and continue serving old code. Always use `openclaw-restart` to clean up.
- **Build detection**: `run-node.mjs` compares `src/` mtime vs `dist/.buildstamp`. Force rebuild: `sudo rm dist/.buildstamp`
- **Capture logic compiles to**: `dist/reply-*.js` bundles (NOT `dist/index.js`)

---

### 13.9 Step 3A — Capture → Auto Cron Reminder

**目標**：秘書不只記錄，還能執行——分類到有 due date 的任務時自動排程提醒，到期主動回報。

#### 設計決策

- 直接呼叫 `CronService.add()` 而非 HTTP RPC，避免 auth token 問題
- 採用 singleton 模式（同 system-events.ts），gateway 啟動時注入 CronService 實例
- 只針對 `action` / `timeline` 類型且有 due date 的 capture 項目
- 使用 `agentTurn` payload（孤立 LLM session）+ `deliver: true`，到期後主動推回 Telegram
- `deleteAfterRun: true` 一次性 job，執行完自動清除

#### 新增/修改檔案

| 檔案                                        | 說明                                                           |
| ------------------------------------------- | -------------------------------------------------------------- |
| `src/cron/global-cron.ts`                   | **新建**：singleton `registerGlobalCron()` / `getGlobalCron()` |
| `src/gateway/server-cron.ts`                | 新增 `registerGlobalCron(cron)` 在 CronService 建立後          |
| `src/auto-reply/reply/maybe-run-capture.ts` | 新增 `parseDueToIso()` + `maybeScheduleCronReminder()`         |

#### 關鍵程式碼

**`src/cron/global-cron.ts`**:

```typescript
let _cronService: CronService | null = null;
export function registerGlobalCron(service: CronService): void {
  _cronService = service;
}
export function getGlobalCron(): CronService | null {
  return _cronService;
}
```

**`maybe-run-capture.ts`** — 在 `maybeUpdateHeartbeat(out)` 之後呼叫：

```typescript
await maybeScheduleCronReminder(out, ctx);
```

`maybeScheduleCronReminder()` 邏輯：

1. 只處理 `type === "action" || type === "timeline"` 且有 `due` 的 item
2. `parseDueToIso(due)` → 解析 YYYY-MM-DD → 排到當天 09:00 Asia/Shanghai
3. 如果 due date 已過去 → 返回 null → 跳過（交給 heartbeat 處理 overdue）
4. `cron.add({ schedule: { kind: "at" }, sessionTarget: "isolated", deleteAfterRun: true, payload: { kind: "agentTurn", deliver: true } })`
5. delivery target: `ctx.OriginatingChannel` / `ctx.OriginatingTo`（優先），fallback `ctx.Surface/Provider` / `ctx.From/SenderId`

#### Cron Job 到期觸發流程

```
due date 09:00 (Asia/Shanghai)
  → cron timer fires
  → isolated LLM session starts
  → prompt: "【到期任務追蹤】任務：{title}（id:{id}）\n請確認狀態，採取行動，向用戶回報"
  → LLM reads assistant_hub task card, checks status, may exec/web_fetch
  → deliver: true → pushes reply to Telegram
  → job deleted (deleteAfterRun)
```

#### 已知限制

- 只排到期當天 09:00；若 due 已過（overdue）→ 不排，由 heartbeat playbook 處理
- `watch` 類型不排 cron（只靠 Ken 手動轉 action 或 heartbeat 追）
- 無 due date 的 action 項目不排 cron（只靠 HEARTBEAT.md playbook 追）
- 重複 capture 同一任務會建多個 cron jobs → 待改進（可查重 job name）

#### Cron Jobs 存放路徑

```
~/.config/openclaw/cron/jobs.json
~/.config/openclaw/cron/runs/<jobId>.jsonl
```

---

### 13.11 Step 3C — 孤立 LLM 執行 + 主動推送

**目標**：cron job 到點觸發時，孤立 LLM session 能讀取完整任務上下文、實際執行（exec/web_fetch）、並自動推送結果回 Ken，無需 Ken 發起。

#### 關鍵發現（從 `isolated-agent/run.ts` 讀取）

1. **`disableMessageTool: deliveryRequested`**：當 `deliver: true` 時，message 工具被禁用。LLM 只需返回純文字，系統自動收集最後一個 deliverable payload 推送出去
2. **Announce flow**：非結構化文字 → `runSubagentAnnounceFlow` 推送（含任務標籤、時長等）；結構化媒體 → `deliverOutboundPayloads` 直接推
3. **`channel: "last"` 最可靠**：使用主 agent session store 的 `lastChannel`/`lastTo` 決定送達目標，比在 capture 時記錄 `ctx.From` 更穩定（避免 session 切換後送錯地方）

#### 改動：豐富 agentTurn message（`maybeScheduleCronReminder`）

**之前（Step 3A）**：

```
【到期任務追蹤】
任務：{title}（id:{id}）
到期：{due}
建議行動：{nba}

請確認任務狀態，採取行動，並向用戶回報。
```

**之後（Step 3C）**：

```
【到期任務追蹤】
任務：{title}（id:{id}）
到期：{due}
建議行動：{nba}

執行指引：
1. 找任務卡片：find ~/.openclaw/.../assistant_hub/tasks -name "{id}_*" -type f
2. read 卡片取得完整上下文與最新狀態
3. 按建議行動執行（可用 exec/web_fetch/cron 等工具）
4. 用繁體中文向 Ken 簡短回報結果或需要確認的事項
```

#### 改動：delivery 改用 `channel: "last"`

**之前**：嘗試從 `ctx.OriginatingChannel`, `ctx.From`, `ctx.SenderId` 提取 channel/to（可能格式不對）
**之後**：`channel: "last"` + `deliver: true` + `bestEffortDeliver: true`

`channel: "last"` 的解析：

```
resolveDeliveryTarget(cfg, agentId, { channel: "last" })
  → loadSessionStore(mainSessionStorePath)
  → store[mainSessionKey].lastChannel / .lastTo
  → Telegram chat ID of Ken's last conversation
```

#### 無 ctx 參數殘留

`maybeScheduleCronReminder(out, ctx)` 的 `ctx` 參數改為 `_ctx`（已不使用），保留簽名相容性。

---

### 13.10 Step 3B — Heartbeat 主動排程

**目標**：Heartbeat LLM 在掃描 HEARTBEAT.md 待跟進清單時，對有未來 due date 但尚未有 cron job 的項目，主動呼叫 `cron` 工具建立一次性提醒。同時處理 overdue 項目（Step 3A 跳過的過期任務）。

#### 與 Step 3A 的分工

| 情境                             | Step 3A (capture 即時) | Step 3B (heartbeat 補漏)      |
| -------------------------------- | ---------------------- | ----------------------------- |
| capture 當下 due 在未來          | ✅ 自動建 cron         | —                             |
| capture 當下 due 已過（overdue） | ❌ 跳過                | ✅ 立即通知 Ken               |
| watch/跟進（無 due date）        | ❌ 跳過                | ✅ 判斷是否需提醒             |
| capture 後服務重啟（cron 未建）  | ❌ 已錯過              | ✅ 補建 cron                  |
| 重複建 cron 防護                 | ❌ 無查重              | ✅ `cron(action="list")` 先查 |

#### HEARTBEAT.md 步驟 2 新增邏輯

```
對每個 [ ] 條目：
  if due date 在過去 → 立即通知 Ken（message 工具）→ 標 [x]
  if due date 在未來 且 type == action/timeline:
    1. cron(action="list") 取得現有 jobs
    2. 找是否有 job.name 包含 id 或 title
    3. 若無 → cron(action="add", schedule: { kind: "at", at: due_date 09:00 +08:00 },
                  payload: { kind: "agentTurn", deliver: true, channel: "telegram" })
    4. 成功 → 標 [x]（已交給 cron，heartbeat 不再追）
  if watch/跟進（無 due date）→ 判斷語境決定是否 message 通知
```

#### 覆蓋的 Gap

- **服務重啟後 cron 未建**：若 Step 3A 在建立 cron 前服務崩潰，下次 heartbeat 看到 `[ ]` 項目後補建
- **過期任務**：Step 3A `parseDueToIso()` 對過去日期返回 null → heartbeat 直接處理
- **重複防護**：`cron(action="list")` 先查 job name，避免為同一任務建多個 job

#### 無需程式碼改動

Step 3B 完全靠 HEARTBEAT.md playbook 驅動。Heartbeat LLM 本身已有完整工具存取（`cron`、`message`、`read`、`write`）。

---

#### 現在的完整閉環（Steps 1–3B）

```
[Telegram inbound]
  → capture agent classifies (10 types)
  → writes to assistant_hub/ (daily_logs, tasks, waiting)
  → maybeUpdateHeartbeat() → HEARTBEAT.md (Plan A)
  → maybeScheduleCronReminder() → cron job if action/timeline + future due date (Step 3A)
  → LLM responds (alsoReply mode)

[Every 30 min heartbeat]
  → reads HEARTBEAT.md playbook
  → scans assistant_hub/ for new captures (find -mmin -65)
  → processes [ ] items:
      overdue → message 通知 Ken immediately
      future due + no cron job → cron(action="add") 補建 (Step 3B)
      watch/跟進 → 判斷是否需主動提醒
  → self-cleans [x] items

[At due date 09:00]
  → cron agentTurn fires
  → isolated LLM receives rich prompt (task card path + action instructions)
  → LLM: find task card → read → exec/web_fetch if needed → plain text reply
  → system auto-delivers last payload to channel:"last" (main agent's last chat)
  → job auto-deleted (deleteAfterRun)

[inbound message context]
  → buildHubContext() injects recent daily_log + unchecked tasks + waiting.md (Plan C)
  → LLM always knows current state
```

---

### 13.12 Step 4 — 任務閉環：去重 + 執行後狀態更新 + watch→action 補 cron

**目標**：任務執行後 LLM 自主更新狀態，Ken 不需要手動標記任何東西；防止重複 cron job；watch 轉 action 後自動排程。

#### 4A — 去重（`maybeScheduleCronReminder`）

建 cron 前先 `cron.list()` 查重：

```typescript
const existing = await cron.list({ includeDisabled: false });
const isDuplicate = existing.jobs.some(
  (j) => j.description?.includes(`capture id:${id}`) || j.name === `到期提醒：${title}`,
);
if (isDuplicate) return;
```

防止 capture 重複訊息或服務重啟後為同一任務建多個 jobs。

#### 4B — agentTurn 執行後自主更新狀態

agentTurn message 新增指引段：

```
執行後自主更新狀態（Ken 不需要手動標記任何東西）：
- 任務完成 → edit 卡片 frontmatter：status: done, completed_at: <yyyy-mm-dd>
  → 在 tasks_master.md 找 (id:{id}) 那行，把 [ ] 改為 [x]
- 任務未完成/需繼續追蹤 → cron 工具重排提醒（3天後），並在卡片加一行進度備註
```

**設計原則**：Ken 不需要手動標記任何東西。LLM 問問題是可以的，但所有狀態更新（done/in-progress）由 LLM 自主完成。

#### 4C — watch→action 補建 cron

在 `maybeHandleCaptureControlCommand` 的 `watch_converted` 分支，轉換後自動呼叫 `maybeScheduleCronReminder`：

```typescript
if (action === "watch_converted") {
  await maybeScheduleCronReminder(
    {
      items: [
        {
          type: "action",
          title: target.title,
          id: target.id,
          due: target.due,
          nextBestAction: null,
        },
      ],
    },
    {} as FinalizedMsgContext,
  );
  return { text: `✅ 已轉任務：${target.title}...` };
}
```

當 Ken 輸入 `1`（轉任務）且 watch 卡有 due date → 自動補排 cron。

#### HEARTBEAT.md 更新

新增原則標注：`Ken 不需要手動標記任何東西，狀態更新由 LLM 自主完成`

#### 完整任務生命週期（Step 4 後）

```
[capture] type:action/timeline + due date
  ↓ 4A: dedup check
  ↓ cron.add({ kind: "at" })
  ↓ (3B backup: heartbeat補漏)

[due date 09:00]
  ↓ isolated LLM runs
  ↓ read task card → exec/web_fetch
  ↓ deliver result to Telegram

[post-execution — 4B]
  done → status:done + tasks_master [x]
  not done → cron reschedule +3 days

[watch→action — 4C]
  Ken: "1" → watch_converted → maybeScheduleCronReminder auto-runs
```

---

### 13.13 Step 5 — 主動晨報 (Proactive Morning Briefing)

**目標**：秘書不只等 Ken 說話，每天早上主動推送今日工作摘要（任務追蹤角度）。

#### 設計

- 新建 `src/cron/bootstrap-jobs.ts` — gateway 啟動時 `ensureBootstrapJobs(cron)` 確保「每日晨報」job 存在（idempotent）
- Job 名：`每日晨報`，schedule：`0 7 10 * * *`（07:10 Asia/Shanghai）
- 檢查邏輯：`cron.list({ includeDisabled: true })` 查是否已有同名 job，有則跳過
- 觸發位置：`server-cron.ts` → `registerGlobalCron(cron)` 後，`void ensureBootstrapJobs(cron).catch(...)`

#### 與現有晨報分工

系統原本已有：

```
07:00  capture-daily-calendar-0700   → 今日 Google Calendar 事件
07:10  每日晨報（Step 5 新建）       → tasks_master.md 待辦摘要
08:00  capture-watch-checker-0800    → Watch 卡片狀態檢查
```

`capture-daily-calendar-0700` 跑 shell script 推送日曆；`每日晨報` 讀 assistant_hub 任務資料，兩者互補。

#### agentTurn message 結構

```
【每日工作晨報】
1. read tasks_master.md → 找所有 [ ] 條目
2. 按 due date 分類：逾期 / 今日到期 / 本週到期 / 無 due date
3. 發送簡潔摘要：⚠️逾期N項 / 📅今日N項 / 📆本週N項，每項一行
4. 逾期且可直接執行的 → 自主執行 + 更新狀態
```

#### 新增檔案

- `src/cron/bootstrap-jobs.ts` — `ensureBootstrapJobs(cron: CronService)`
- `src/gateway/server-cron.ts` — import + 呼叫 `ensureBootstrapJobs`

#### 注意事項

- Jobs 持久化在 `~/.openclaw/cron/jobs.json`，服務重啟後不重複建立
- 若日後需要調整時間，直接修改 `jobs.json` 中的 schedule + `bootstrap-jobs.ts` 中的 expr
- `capture-gmail-digest-0710` 也在 07:10，但 job 名不同，不影響

---

### 13.14 秘書行為準則：何時自主，何時問

**原則**：

- Ken 不需要手動標記任何東西（done/in-progress/[x] 全由 LLM 自主更新）
- 但 LLM 可以、也應該在需要 Ken 決策時提問

#### 自主 vs 詢問 判斷規則

| 情境                                      | 行為                                           |
| ----------------------------------------- | ---------------------------------------------- |
| 金額、日期、純提醒類任務                  | 直接執行並回報，不問                           |
| 需要 Ken 判斷意向（去或不去、繼續或放棄） | 問                                             |
| 對外溝通（發郵件、打電話）未明確授權      | 問                                             |
| 任務完成確認                              | 自主 edit 卡片 status: done + tasks_master [x] |
| 任務未完成                                | 自主 cron 重排 3 天後，不等 Ken                |

#### End-to-End Examples（Steps 1–5 完整流程）

**Example 1 — 可直接執行，不問**

Ken 說：「下週三記得交房租 8000」

```
Capture → type: action, due: 2026-03-04, title: "交房租 8000"
→ cron.add({ at: "2026-03-04T01:00:00Z" })

3月4日 07:10 晨報：
  📋 今日工作摘要
  📅 今日到期 1 項：交房租 8000

3月4日 09:00 cron fires → isolated LLM：
  1. read 任務卡片 → 確認金額、收款方
  2. 行動明確 → 直接回報：「📌 今天要交房租 8000。請確認已轉帳。」
  3. Ken 不回應 → 3天後重排 cron（未確認視為未完成）
  4. Ken 說「已交」→ heartbeat 掃到 → edit status:done + tasks_master [x]
```

**Example 2 — 需要決策，問**

Ken 說：「考慮要不要參加 3 月底的投資人晚宴」

```
Capture → type: watch, due: null
→ HEARTBEAT.md 追加 [ ] watch 條目（無 cron，watch 無 due date）

下次 heartbeat：
  LLM 判斷：需要 Ken 決策，無法自主處理
  → message 推送：
    「投資人晚宴（3月底）還沒決定。要參加嗎？
     如果決定去，我幫你排行程和準備事項。」
```

**Example 3 — 部分自主，部分問**

Ken 說：「幫我跟進陳宇恒的提案，截止日 3 月 10 號」

```
Capture → type: action, due: 2026-03-10
→ cron.add({ at: "2026-03-10T01:00:00Z" })

3月10日 09:00 cron fires → isolated LLM：
  1. read 任務卡片
  2. exec/web_fetch 查是否有相關郵件/文件
  3. 無法判斷提案狀態 → 回報 + 問：
     「陳宇恒提案今天截止，查無回覆記錄。
      要我起草催促郵件，還是你已經有消息？」

  [自主] → edit 卡片加備註：「2026-03-10 查無回覆，已通知 Ken」
  [詢問] → 等 Ken 決定是否對外溝通（不自動發郵件）
```

---

### 13.15 Step 6 — 人脈/聯絡人記憶卡片

**目標**：讓秘書記得每個重要人物的背景與互動歷史，在對話中自動帶入。

#### 目錄結構

```
04_knowledge/people/
├── alex-chen.md        # 投資人
├── sam-lee.md          # 律師/合約方
└── ...                 # 每人一檔
```

#### 卡片格式

```markdown
---
name: Alex Chen
relationship: investor
updated: 2026-02-26
---

# Alex Chen

## 基本資料

- 關係：投資人（A 輪洽談中）

## 互動記錄

- 2026-02-26：討論 A 輪融資條款，下週開會
```

#### 自動維護（HEARTBEAT.md 規則）

Heartbeat LLM 掃描新 capture：

1. 若 frontmatter 有 `people:` 欄位，或內文提到人名
2. 檢查 `04_knowledge/people/` 是否已有該人卡片
3. **無卡片** → 靜默建立（不通知 Ken）
4. **有卡片** → 在「互動記錄」section 追加一行

#### Context 注入（hub-context.ts）

```typescript
// 最近3個修改的人脈卡片，每卡最多400字
const peopleContext = await readDirRecent(hubPaths.people, 3, 400);
if (peopleContext) {
  sections.push(`## 相關聯絡人\n${peopleContext}`);
}
```

- 排序：mtime 降序（最近互動的人優先）
- 每次 LLM 對話都能知道最近涉及的3個人是誰

#### 關鍵檔案

- `src/auto-reply/reply/hub-context.ts` — `readDirRecent()` 新增函數
- `~/.openclaw/workspace/automation/assistant_hub/04_knowledge/people/` — 卡片目錄（初始為空，由 LLM 自動建立）
- `~/.openclaw/workspace/HEARTBEAT.md` — 人脈卡片維護規則 section

---

### 13.16 Step 9 — 決策智慧框架

**目標**：把頂級投資人/思想家的框架注入每次 LLM 對話，讓秘書做出更有智慧的建議。

#### 目錄結構

```
04_knowledge/beliefs/
├── naval-ravikant.md   # 財富與人生哲學
├── warren-buffett.md   # 長期價值投資
├── charlie-munger.md   # 心智模型與逆向思維
├── ray-dalio.md        # 宏觀週期與原則化決策
├── peter-lynch.md      # 成長股與消費洞察
├── howard-marks.md     # 風險框架與二階思維
└── peter-thiel.md      # 零對一與壟斷思維
```

#### 各人框架貢獻

| 人物           | 核心貢獻                        | 互補點              |
| -------------- | ------------------------------- | ------------------- |
| Naval Ravikant | 特定知識、槓桿、平靜            | 人生哲學層面        |
| Warren Buffett | 能力圈、安全邊際、護城河        | 長期價值投資        |
| Charlie Munger | 逆向、心理偏誤清單、格柵        | 避免愚蠢            |
| Ray Dalio      | 宏觀週期、原則化決策、分散化    | 系統思維 + 宏觀視角 |
| Peter Lynch    | 投你所知、PEG、十倍股識別       | 實操成長股框架      |
| Howard Marks   | 二階思維、風險=永久虧損、不對稱 | 風險管理核心        |
| Peter Thiel    | 零對一、壟斷、秘密、10倍優勢    | 創業/科技決策       |

#### Context 注入（hub-context.ts）

```typescript
// 全部 beliefs 文件，每個最多600字，按檔名排序
const beliefsContext = await readAllBelief(hubPaths.beliefs, 600);
if (beliefsContext) {
  sections.push(`## 決策智慧\n${beliefsContext}`);
}
```

- 7個文件 × 600字 ≈ 4200字，加上其他 section 剛好在 5000字上限內
- 文件是純 markdown，無需重新編譯，可隨時新增/修改

#### hub-context.ts 完整 Section 結構（最終版）

| Section       | 來源                                   | 更新時間   | 字數上限 |
| ------------- | -------------------------------------- | ---------- | -------- |
| 今日/昨日記錄 | `03_life/daily_logs/`                  | 即時       | 1500     |
| 郵件          | `02_work/gmail.md`                     | 07:10 cron | 600      |
| 日曆          | `02_work/calendar.md`                  | 07:00 cron | 1200     |
| 待辦          | `02_work/tasks_master.md` 未完成       | 即時       | 8行      |
| 追蹤中        | `02_work/waiting.md`                   | 即時       | 800      |
| 近期月摘要    | `04_knowledge/monthly_digest/` 最近2個 | 每月1日    | 300×2    |
| 行為模式      | `04_knowledge/patterns.md`             | 週一更新   | 400      |
| 相關聯絡人    | `04_knowledge/people/` 最近3個         | 即時       | 400×3    |
| 決策智慧      | `04_knowledge/beliefs/` 全部7個        | 靜態       | 300×7    |

`HUB_CONTEXT_MAX_CHARS`：3000 → **5000**

#### 新增輔助函數

```typescript
// readDir: 列出目錄下所有非 _ 開頭的 .md 文件
async function readDir(dirPath: string): Promise<string[]>;

// readDirRecent: 按 mtime 降序，取前 N 個，每個截取 maxCharsEach
async function readDirRecent(dirPath, maxFiles, maxCharsEach): Promise<string | null>;

// readAllBelief: 按檔名排序，全部讀取，每個截取 maxCharsEach
async function readAllBelief(dirPath, maxCharsEach): Promise<string | null>;
```

#### Example 應用場景

**Example 1 — Dalio 介入週期判斷**

Ken 問：「美股最近一直跌，我要不要補倉？」

LLM context 帶入 ray-dalio.md + howard-marks.md，自動輸出：

- Dalio：判斷現在是去槓桿週期還是情緒性回調（看央行/信貸/債券利差三信號）
- Marks：上漲空間 vs 下跌風險比是多少？新聞是恐慌還是樂觀？

**Example 2 — Lynch 識別身邊機會**

Ken 描述一個新連鎖品牌排隊40分鐘，LLM 自動套用 Lynch 框架：

- 一句話能說清楚成長邏輯嗎？
- 機構還沒追進去嗎？
- 創辦人持股狀況？

**Example 3 — Thiel 判斷創業投資**

朋友邀投 AI 財務 SaaS，LLM 自動套用 Thiel 框架：

- 0→1 還是 1→N？（已有競爭者 = 1→N，警示）
- 壟斷四特徵哪個具備？
- 創辦人有什麼別人不知道的秘密？
- Munger 補充逆向：大廠直接內建如何防守？

---

### 13.17 被動觀察管道 — Gmail + Calendar 自動注入 hub-context

**背景**：Ken 不會主動把所有事情告訴秘書。系統必須從外部數據源被動觀察，讓 LLM 在每次對話時已知道郵件和行程，無需 Ken 重複說明。

#### 問題根源

原有流程：

```
Gmail digest cron → Telegram（Ken 看）→ Ken 不說 → LLM 不知道
Calendar cron    → Telegram（Ken 看）→ Ken 不說 → LLM 不知道
```

修正後：

```
Gmail digest cron → Telegram（Ken 看）+ 02_work/gmail.md（LLM 自動讀）
Calendar cron    → Telegram（Ken 看）+ 02_work/calendar.md（已有）→ hub-context 新增讀取
```

#### 已有基礎（無需改動）

- `capture-daily-calendar-0700`（07:00）→ 已寫 `02_work/calendar.md`（markdown table）
- `capture-gmail-digest-0710`（07:10）→ 讀 Gmail sessions，分類 important/useful/ignored

#### 改動 1 — `scripts/capture/gmail-digest.ts`

在 `buildPushText()` 之後、推送 Telegram 之前，額外寫精簡版到 `paths.work/gmail.md`：

```typescript
const inboxLines = [`# gmail (${today}，重要 ${important.length} / 有用 ${useful.length})`];
for (const item of important.slice(0, 6)) {
  inboxLines.push(`- (${item.priority}) ${shorten(item.subject, 50)} | ${shorten(item.from, 30)}`);
}
if (useful.length > 0) {
  inboxLines.push(
    `_有用 ${useful.length} 封（${useful
      .slice(0, 3)
      .map((i) => shorten(i.subject, 30))
      .join(" / ")}…）_`,
  );
}
await writeText(path.join(paths.work, "gmail.md"), inboxLines.join("\n") + "\n");
```

輸出格式範例：

```
# gmail (2026-02-26，重要 2 / 有用 4)
- (P0) 合約修訂意見 | alex@example.com
- (P1) 下週會議確認 | sam@corp.com
_有用 4 封（收據 / 訂閱更新 / 月結單 …）_
```

#### 改動 2 — `src/auto-reply/reply/hub-context.ts`

新增兩個 section，在「待辦」之前注入：

```typescript
// Gmail inbox (written by gmail-digest cron at 07:10)
const gmail = await readTail(path.join(hubPaths.work, "gmail.md"), 600);
if (gmail && gmail.split("\n").filter((l) => l.trim()).length > 1) {
  sections.push(`## 郵件\n${gmail}`);
}

// Calendar (written by daily-calendar cron at 07:00)
const calendarRaw = await readTail(path.join(hubPaths.work, "calendar.md"), 1200);
if (calendarRaw && calendarRaw.includes("|")) {
  sections.push(`## 日曆\n${calendarRaw}`);
}
```

#### hub-context 完整 Section 結構（最終版）

| Section       | 來源                                   | 更新時間   | 字數上限 |
| ------------- | -------------------------------------- | ---------- | -------- |
| 今日/昨日記錄 | `03_life/daily_logs/`                  | 即時       | 1500     |
| 郵件          | `02_work/gmail.md`                     | 07:10 cron | 600      |
| 日曆          | `02_work/calendar.md`                  | 07:00 cron | 1200     |
| 待辦          | `02_work/tasks_master.md` 未完成       | 即時       | 8行      |
| 追蹤中        | `02_work/waiting.md`                   | 即時       | 800      |
| 近期月摘要    | `04_knowledge/monthly_digest/` 最近2個 | 每月1日    | 300×2    |
| 行為模式      | `04_knowledge/patterns.md`             | 週一更新   | 400      |
| 相關聯絡人    | `04_knowledge/people/` 最近3個         | 即時       | 400×3    |
| 決策智慧      | `04_knowledge/beliefs/` 全部7個        | 靜態       | 300×7    |

`HUB_CONTEXT_MAX_CHARS`：5000

#### 設計原則

- **passive over active**：不依賴 Ken 主動說，從外部數據源被動取
- **write once, read everywhere**：cron 腳本負責寫，hub-context 統一讀，兩者解耦
- **每天自動刷新**：gmail.md 和 calendar.md 每天早上被覆蓋寫入，永遠是最新的

---

### 13.18 微信通訊管道接入

**目標**：讓秘書被動觀察 Ken 的微信對話，無需 Ken 主動轉述。

#### 現有基礎

- `scripts/capture/wechat-capture-webhook.ts` — standalone HTTP server（port 8789），接收 wechatbot webhook
- `src/adapters/wechat-capture-webhook.ts` — 核心 adapter，調用 `runCaptureAgent()` 處理 payload
- `src/adapters/wechat-capture-adapter.ts` — payload 正規化

**現有 payload 格式**（`WechatbotWebhookPayload`）：

```typescript
{
  content?: string;      // 消息內容
  type?: string;         // 消息類型
  roomid?: string;       // 群組 ID（有 = 群消息）
  wxid?: string;         // 消息 ID
  sender?: string;       // 發送者 wxid
  isMentioned?: boolean; // 是否 @bot
  timestamp?: string | number;
}
```

**現有過濾邏輯**：

- 群組：只處理 @mention（`requireMentionInGroup=true`）
- DM：只處理 Ken 自己發的（`dm_not_self_sender` 過濾掉別人發給 Ken 的）
- → 需要修改 DM 過濾才能捕獲 incoming 消息

#### 技術方案評估

| 方案                       | Linux           | 協議     | Webhook | 維護        | 封號風險 |
| -------------------------- | --------------- | -------- | ------- | ----------- | -------- |
| **WeChatPadPro + AstrBot** | ✅ Docker       | iPad/861 | ✅      | 活躍(2025)  | 中       |
| GeWeChat (Devo919)         | ✅ Docker       | iPad     | ✅      | ❌ 已停維護 | 中       |
| WeChatFerry (wcf)          | ❌ Windows only | Hook/DLL | 需包裝  | 活躍        | 中       |
| web protocol 方案          | ✅              | Web      | 各異    | 多已死      | 高       |

**推薦**：WeChatPadPro + AstrBot（GeWeChat 已於2025年底停維護）

#### 封號風險管理（重要）

**絕對原則**：

1. **用備用帳號，絕不用主帳號** — 這是最重要的一條
2. **手動養號30天** — 前30天只做真人行為（聊天、朋友圈、微信支付）
3. **中國大陸 IP** — 帳號歷史在哪城市，服務器 IP 就要在哪城市
4. 手機 app 和 bot 不能同時登入同一帳號

**操作限制**：

- 每分鐘發送 ≤30 條，每條間隔 2-3 秒
- 永遠不加陌生人（搖一搖/附近的人 = 最高風險）
- 只做 reply-only 模式：收消息 → capture → 通知 Telegram

**帳號養號時間線**：

- Day 1-30：手動行為，絕不自動化
- Day 30+：開始 passive 監聽
- Day 90+：可以謹慎自動回覆已有聯絡人

#### 實施計劃（待執行）

**Step 1** — 確認前提：服務器 IP 城市、備用帳號準備

**Step 2** — 部署 WeChatPadPro + AstrBot，設置 callback URL 指向 `localhost:8789`

**Step 3** — 修改 DM 過濾邏輯（1行代碼）：

```typescript
// src/adapters/wechat-capture-webhook.ts
// 移除 dm_not_self_sender 過濾，改為捕獲所有 incoming DM
} else if (selfWxid && sender && sender !== selfWxid) {
  return { handled: false, reason: "dm_not_self_sender" }; // ← 移除這段
}
```

**Step 4** — 啟動 webhook server，設置 systemd env vars：

```
WECHAT_CAPTURE_SELF_WXID=<備用帳號wxid>
WECHAT_CAPTURE_APPLY_WRITES=1
WECHAT_CAPTURE_SEND_ACK=0   # 靜默，不自動回覆
WECHAT_CAPTURE_PORT=8789
```

**Step 5** — 驗證 pipeline：微信收一條消息 → `assistant_hub/00_inbox/` 有新文件 → daily_log 有記錄

**狀態**：等待備用帳號養號完成後執行。

---

### 13.19 通知格式 Bug Fix — 內部 ID 不應顯示給 Ken

**問題**：watch-checker 和 stale-checker 推送通知時，直接把內部 capture ID（如 `2026-02-18-2041`）顯示給 Ken，完全看不懂。

**根本原因**：

- `watch-checker.ts` line 347：push block 格式用 `• ${id}（type｜priority）`，把 id 放在最前面
- `stale-checker.ts`：report 寫的是完整 raw line（含 id），heartbeat LLM 讀到後直接轉述
- `HEARTBEAT.md`：沒有明確禁止把 ID 顯示給 Ken 的規則

#### 修改內容

**`scripts/capture/watch-checker.ts`** — 改為用人類可讀標題：

```typescript
// 修改前：
`• ${id}（${type}｜${priority}）`;

// 修改後：
const displayTitle = friendlyMeaning ?? (summary !== title ? summary : title);
`• ${displayTitle}（${priority}）`
// ID 只保留在回覆指令裡（系統識別需要）
`  回覆：1 ${id} = 轉任務；0 ${id} = 停止提醒`;
```

**`scripts/capture/stale-checker.ts`** — 新增 `parseTitleFromLine()`，report 改為：

```
- 任務標題 (id:2026-02-18-2041) age_days:8
```

（標題在前，ID 保留供 LLM 操作用）

**`HEARTBEAT.md`** — 加入通知格式原則：

```
<!-- ⚠️ 通知格式原則：永遠用人類可讀的任務標題，絕不把內部 ID 直接顯示給 Ken -->
```

#### 設計原則

- **對 Ken 顯示**：任務標題（人類語言）
- **對系統操作**：内部 ID（LLM 用於 find/edit/cron 操作）
- 兩者並存，各司其職
