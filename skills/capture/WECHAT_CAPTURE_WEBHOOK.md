# WeChat Capture Webhook Runbook

## Goal

Run the WeChat sidecar webhook capture path without wiring long-running service yet.

## Entry script

- `scripts/capture/wechat-capture-webhook.ts`

## Default endpoints

- Webhook: `POST /wechat/webhook`
- Health: `GET /healthz`

## Required env

Minimum (capture only):

- `MOLTBOT_CAPTURE_ENABLED=1`

Recommended runtime env:

- `WECHAT_CAPTURE_HOST=127.0.0.1`
- `WECHAT_CAPTURE_PORT=8789`
- `WECHAT_CAPTURE_APPLY_WRITES=1`
- `WECHAT_CAPTURE_SEND_ACK=0` (set `1` only when reply API is ready)
- `OUTPUT_MODE=json`

Optional filtering/auth:

- `WECHAT_CAPTURE_SELF_WXID=<your_wxid>`
- `WECHAT_CAPTURE_REQUIRE_MENTION_IN_GROUP=1`
- `WECHAT_CAPTURE_WEBHOOK_TOKEN=<token>` (header: `x-wechat-capture-token`)

Optional ack relay to wechatbot:

- `WECHATBOT_HOST=http://<wechatbot-host>`
- `WECHATBOT_REPLY_PATH=/webhook/msg/v2`
- `WECHATBOT_TOKEN=<token-if-needed>`

## Start command

When dependencies are installed:

```bash
pnpm moltbot:capture:wechat-webhook
```

Backward-compatible alias:

```bash
pnpm moltbot:wechat-capture-webhook
```

Fallback without workspace install:

```bash
npx -y -p tsx tsx scripts/capture/wechat-capture-webhook.ts
```

## Quick smoke

Health:

```bash
curl -fsS "http://127.0.0.1:8789/healthz"
```

Webhook payload (nested `data`):

```bash
curl -sS -X POST "http://127.0.0.1:8789/wechat/webhook" \
  -H 'content-type: application/json' \
  -d '{
    "data": {
      "content": "2026-03-01 19:30 提醒我上線",
      "wxid": "msg-demo-1",
      "roomid": "room-demo-1",
      "sender": "wx-self",
      "isMentioned": true
    }
  }'
```

Expected response shape:

```json
{
  "ok": true,
  "handled": true,
  "messageId": "msg-demo-1",
  "itemCount": 1,
  "ack": {
    "attempted": false,
    "sent": false,
    "target": "room-demo-1"
  }
}
```

## Notes

- Group chat is filtered by mention/self rules before capture.
- DM mode can be restricted to self sender by setting `WECHAT_CAPTURE_SELF_WXID`.
- Ack send failures are logged and do not rollback capture handling.
