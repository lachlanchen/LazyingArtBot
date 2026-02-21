# Capture Runners (Canonical Map)

This folder contains the Linux-friendly capture runners used by cron and manual operations.

## Canonical runner commands

| Runner file                                 | Canonical pnpm command                      |
| ------------------------------------------- | ------------------------------------------- |
| `scripts/capture/daily-calendar.ts`         | `pnpm moltbot:capture:daily-calendar`       |
| `scripts/capture/watch-checker.ts`          | `pnpm moltbot:capture:watch-checker`        |
| `scripts/capture/stale-checker.ts`          | `pnpm moltbot:capture:stale-checker`        |
| `scripts/capture/weekly-reflection.ts`      | `pnpm moltbot:capture:weekly-reflection`    |
| `scripts/capture/gmail-digest.ts`           | `pnpm moltbot:capture:gmail-digest`         |
| `scripts/capture/gmail-classify-all.ts`     | `pnpm moltbot:capture:gmail-classify-all`   |
| `scripts/capture/notebooklm-enqueue.ts`     | `pnpm moltbot:capture:notebooklm-enqueue`   |
| `scripts/capture/notebooklm-worker.ts`      | `pnpm moltbot:capture:notebooklm-worker`    |
| `scripts/capture/notebooklm-tool-mock.ts`   | `pnpm moltbot:capture:notebooklm-tool-mock` |
| `scripts/capture/wechat-capture-webhook.ts` | `pnpm moltbot:capture:wechat-webhook`       |

## Compatibility alias

- `pnpm moltbot:wechat-capture-webhook` -> forwards to `pnpm moltbot:capture:wechat-webhook`

## Runtime target

- Primary target: Node.js runtime on Linux hosts (cron/server path)
- Not tied to macOS app binaries (`apps/macos/*`)

## NotebookLM worker contract

- Moltbot layer only does queue orchestration, persistence, and push.
- Set `CAPTURE_NOTEBOOKLM_TOOL_CMD` to an external command that handles NotebookLM auth/login/cookies.
- Tool contract is stable:
  - Input: `stdin` JSON request
  - Output: `stdout` JSON (`summary`, `key_points`, `action_items`, `sources`, `confidence`, `raw_text`)
