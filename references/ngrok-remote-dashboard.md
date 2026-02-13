# OpenClaw Remote Dashboard via ngrok

This runbook covers exposing a local OpenClaw gateway (`127.0.0.1:18789`) through ngrok and fixing common auth errors.

## Prerequisites

- OpenClaw gateway running locally on port `18789`
- ngrok installed and authenticated
- Local tmux launcher script: `scripts/start-openclaw-tmux.sh`

## 1) Start gateway in tmux (with public URL hint)

```bash
cd /Users/lachlan/Local/Clawbot
OPENCLAW_PUBLIC_URL='https://lab.ngrok.pizza' scripts/start-openclaw-tmux.sh openclaw detach
```

The script prints:

- `Local dashboard: http://127.0.0.1:18789/#token=<token>`
- `Public dashboard: https://lab.ngrok.pizza/#token=<token>`

Use the **public** URL with `#token=...`.

## 2) Start ngrok tunnel

```bash
ngrok http --url=lab.ngrok.pizza 18789
```

## 3) Open remote dashboard

Open:

```text
https://lab.ngrok.pizza/#token=<gateway_token>
```

If you open only `https://lab.ngrok.pizza` without `#token=...`, WebSocket auth fails.

## Common errors and fixes

### `unauthorized: gateway token missing`

Cause: URL missing token fragment.

Fix:

1. Read token from `~/.openclaw/openclaw.json` (`gateway.auth.token`), or use script output.
2. Reopen with `#token=<token>`.

### `disconnected (1008): pairing required`

Cause: Remote browser fingerprint is a new device.

Fix:

```bash
cd /Users/lachlan/Local/Clawbot
pnpm openclaw devices list
pnpm openclaw devices approve <requestId>
```

Reload remote page after approval.

### `Proxy headers detected from untrusted address`

This warning is expected behind ngrok unless `gateway.trustedProxies` is configured.
It does not by itself block connection if token and pairing are correct.

## Useful checks

```bash
tmux ls | rg openclaw
lsof -nP -iTCP:18789 -sTCP:LISTEN
pnpm openclaw devices list
```
