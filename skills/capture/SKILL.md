---
name: capture
description: Multi-platform personal capture workflow for Moltbot. Converts freeform inbound text/media context into structured assistant_hub records with low-interruption acknowledgments.
metadata:
  {
    "openclaw":
      {
        "emoji": "📥",
        "requires": { "env": ["MOLTBOT_CAPTURE_ENABLED"] },
        "install":
          [{ "id": "bundled-local", "kind": "bundled", "label": "Bundled in LazyingArtBot repo" }],
      },
  }
---

# Capture Skill

## Purpose

Enable a reasoning-first capture path for personal assistant usage:

- Accept natural language inbound messages
- Infer minimal structured card type
- Persist to `assistant_hub/` markdown files
- Return 3-line acknowledgement

Current scope:

- `source`: `telegram`, `email`, `feishu`/`lark`, `whatsapp`, `wechat`, `generic` (opt-in)
- `OUTPUT_MODE`: `json` and `agent`
- model-free heuristic classification

## Enable capture

Set either:

- `MOLTBOT_CAPTURE_ENABLED=1`, or
- config key `capture.enabled=true`

Optional:

- `MOLTBOT_CAPTURE_GENERIC_ENABLED=1` to enable unknown-provider generic fallback
- `OUTPUT_MODE=agent` to get agent-oriented return payload

When enabled, inbound messages from supported providers are intercepted before normal agent reply and written to:

- `~/.openclaw/workspace/automation/assistant_hub/`

## WeChat webhook mode (sidecar)

Use script:

- `scripts/capture/wechat-capture-webhook.ts`

Default HTTP endpoints:

- `POST /wechat/webhook`
- `GET /healthz`

Key env vars:

- `WECHAT_CAPTURE_HOST` (default `0.0.0.0`)
- `WECHAT_CAPTURE_PORT` (default `8789`)
- `WECHAT_CAPTURE_PATH` (default `/wechat/webhook`)
- `WECHAT_CAPTURE_HEALTH_PATH` (default `/healthz`)
- `WECHAT_CAPTURE_SELF_WXID` (optional, used for DM/self filtering)
- `WECHAT_CAPTURE_REQUIRE_MENTION_IN_GROUP` (default `true`)
- `WECHAT_CAPTURE_WEBHOOK_TOKEN` (optional; checks header `x-wechat-capture-token`)
- `WECHAT_CAPTURE_APPLY_WRITES` (default `true`)
- `WECHAT_CAPTURE_SEND_ACK` (default `true`)
- `WECHATBOT_HOST` or `WECHATBOT_BASE_URL` (optional; required only when sending ack)
- `WECHATBOT_REPLY_PATH` (default `/webhook/msg/v2`)
- `WECHATBOT_TOKEN` (optional; sent as `x-wechatbot-token`)

Run examples:

- `npx -y -p tsx tsx scripts/capture/wechat-capture-webhook.ts`
- `pnpm moltbot:capture:wechat-webhook` (canonical)
- `pnpm moltbot:wechat-capture-webhook` (compat alias)

## Workflow runners (manual)

The following STEP-6 workflows now have executable runners:

- daily calendar rebuild:
  - `pnpm moltbot:capture:daily-calendar`
- watch checkpoint scan:
  - `pnpm moltbot:capture:watch-checker`
- stale action scan:
  - `pnpm moltbot:capture:stale-checker`
- weekly reflection generation:
  - `pnpm moltbot:capture:weekly-reflection`

Fallback (without workspace install) for each runner:

- `npx -y -p tsx tsx scripts/capture/<runner>.ts`

Watch-checker push env:

- `CAPTURE_WATCH_PUSH_ENABLED=1` enable push.
- `CAPTURE_WATCH_PUSH_DRY_RUN=1` (default) keeps push in dry-run mode.
- `CAPTURE_WATCH_PUSH_DRY_RUN_CLI=1` forces actual CLI dry-run; default behavior is local simulated dry-run (no OpenClaw dist dependency).
- `CAPTURE_WATCH_PUSH_CLI_BIN` sets CLI binary/path for push (default: `openclaw`)
- `CAPTURE_WATCH_PUSH_CHANNEL` (default `telegram`)
- `CAPTURE_WATCH_PUSH_TO` (required when push enabled)
- `CAPTURE_WATCH_PUSH_ACCOUNT_ID` (optional)

Daily-calendar push env:

- `CAPTURE_DAILY_PUSH_ENABLED=1` enable push.
- `CAPTURE_DAILY_PUSH_DRY_RUN=1` (default) keeps push in dry-run mode.
- `CAPTURE_DAILY_PUSH_DRY_RUN_CLI=1` forces actual CLI dry-run.
- `CAPTURE_DAILY_PUSH_CLI_BIN` sets CLI binary/path for push (default: `openclaw`)
- `CAPTURE_DAILY_PUSH_CHANNEL` (default `telegram`, supports `feishu` and other OpenClaw channels)
- `CAPTURE_DAILY_PUSH_TO` (required when push enabled)
- `CAPTURE_DAILY_PUSH_ACCOUNT_ID` (optional)

## Data paths

- `00_inbox/`
- `02_work/` (`tasks/`, `tasks_master.md`, `waiting.md`, `calendar.md`)
- `03_life/` (`daily_logs/`, `ideas/`, `highlights/`)
- `04_knowledge/` (`people/`, `questions/`, `beliefs/`, `references/`)
- `05_meta/` (`reasoning_queue.jsonl`)

## Behavior notes

- Always appends to inbox first.
- Uses conservative default: no auto task conversion unless explicit force terms match.
- Watch schedule is auto-generated when due date exists in ISO format (`YYYY-MM-DD` or `YYYY-MM-DD HH:MM`).
- Telegram adapter now maps upstream `MediaUnderstanding` text into `attachments[].semanticDesc` when available.
- Append/replay dedupe is message-id aware (`append_existing` / replay merge).
- For replay/append flows, queue/calendar duplicate appends are suppressed.
- Watch-checker writes push artifacts to:
  - `05_meta/watch_push_results.md`
  - `05_meta/watch_push_payload.md` (when new due reminders exist)
- Daily-calendar writes visualization + push artifacts to:
  - `05_meta/calendar_push_preview.md`
  - `05_meta/calendar_push_results.md`
  - `05_meta/calendar_push_payload.md` (when push enabled)
- If capture fails, normal reply pipeline continues.

## Known limits

- Classifier remains heuristic and model-free.
- Full repo-wide vitest/typecheck coverage may depend on local workspace dependency readiness.
- WeChat sidecar auth header shape may need adjustment for specific wechatbot deployments.
