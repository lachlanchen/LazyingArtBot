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

- Canonical runner/command map: `scripts/capture/README.md`

- daily calendar rebuild:
  - `pnpm moltbot:capture:daily-calendar`
- watch checkpoint scan:
  - `pnpm moltbot:capture:watch-checker`
- stale action scan:
  - `pnpm moltbot:capture:stale-checker`
- weekly reflection generation:
  - `pnpm moltbot:capture:weekly-reflection`
- NotebookLM request enqueue:
  - `pnpm moltbot:capture:notebooklm-enqueue -- "你的問題"`
- NotebookLM queue worker:
  - `pnpm moltbot:capture:notebooklm-worker`

Fallback (without workspace install) for each runner:

- `npx -y -p tsx tsx scripts/capture/<runner>.ts`

NotebookLM queue/worker quick run:

- enqueue request:
  - `pnpm moltbot:capture:notebooklm-enqueue -- "幫我整理這週 AI agent framework 變化重點"`
- run worker (tool command required):
  - `CAPTURE_NOTEBOOKLM_TOOL_CMD='pnpm moltbot:capture:notebooklm-tool-mock' pnpm moltbot:capture:notebooklm-worker`

NotebookLM isolation principle:

- `Moltbot` 只做三件事：`調度`（queue + worker）、`記錄`（assistant_hub markdown/jsonl）、`推送`（OpenClaw send）。
- 登入、cookies、瀏覽器不穩定等問題全部留在外部工具命令（`CAPTURE_NOTEBOOKLM_TOOL_CMD`）內部處理。
- worker 對外部工具契約固定為：`stdin JSON -> stdout JSON`，避免把工具細節污染到 capture 核心。

NotebookLM trigger (Telegram/Feishu inbound):

- Enable:
  - `MOLTBOT_NOTEBOOKLM_ENABLED=1`
- Keyword list (comma-separated):
  - `MOLTBOT_NOTEBOOKLM_KEYWORDS="/nb,/notebooklm,notebooklm,nb:,交給notebooklm"`
- Mode:
  - `MOLTBOT_NOTEBOOKLM_MODE=queue_only` (只排隊，不跑 capture)
  - `MOLTBOT_NOTEBOOKLM_MODE=queue_and_capture` (排隊 + capture ack，預設)
  - `MOLTBOT_NOTEBOOKLM_MODE=queue_capture_and_model` (排隊 + capture 寫盤，同時讓核心模型回覆)
  - `MOLTBOT_NOTEBOOKLM_MODE=auto` (根據語句自動決定是否讓核心模型回覆)

NotebookLM worker env:

- `CAPTURE_NOTEBOOKLM_TOOL_CMD` (required)
- `CAPTURE_NOTEBOOKLM_MAX_PER_RUN` (default `2`)
- `CAPTURE_NOTEBOOKLM_TOOL_TIMEOUT_MS` (default `180000`)
- `CAPTURE_NOTEBOOKLM_TOOL_MAX_ATTEMPTS` (default `2`)
- `CAPTURE_NOTEBOOKLM_RETRY_FAILED` (default `false`)
- `CAPTURE_NOTEBOOKLM_REQUEST_PUSH_DEFAULT` (default `true`)
- Push:
  - `CAPTURE_NOTEBOOKLM_PUSH_ENABLED`
  - `CAPTURE_NOTEBOOKLM_PUSH_DRY_RUN` / `CAPTURE_NOTEBOOKLM_PUSH_DRY_RUN_CLI`
  - `CAPTURE_NOTEBOOKLM_PUSH_CHANNEL` / `CAPTURE_NOTEBOOKLM_PUSH_TO` / `CAPTURE_NOTEBOOKLM_PUSH_ACCOUNT_ID`
  - `CAPTURE_NOTEBOOKLM_PUSH_CLI_BIN`

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
- `05_meta/` (`reasoning_queue.jsonl`, `notebooklm_requests.jsonl`, `notebooklm_results.jsonl`)

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
- NotebookLM worker writes:
  - `05_meta/notebooklm_worker_results.md`
  - `05_meta/notebooklm_push_preview.md`
  - `05_meta/notebooklm_push_results.md`
  - `04_knowledge/references/notebooklm/*.md`
- If capture fails, normal reply pipeline continues.

## Known limits

- Classifier remains heuristic and model-free.
- Full repo-wide vitest/typecheck coverage may depend on local workspace dependency readiness.
- WeChat sidecar auth header shape may need adjustment for specific wechatbot deployments.
