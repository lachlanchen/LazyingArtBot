# Kairo — AI 秘書系統 · Claude Code 上下文

## 項目定位
Kairo 是一套自托管的**主動 AI 秘書系統**，通過 Telegram / 飛書等 IM 頻道與用戶交互。
核心理念：零摩擦捕捉 → 閉環跟蹤 → 主動推送。所有數據為本地 Markdown，無訂閱費。

## 代碼庫結構
```
src/
  agents/           # LLM agent 執行邏輯
    tools/          # LLM 可調用工具（feishu_calendar、cron 等）
    openclaw-tools.ts  # 工具註冊入口（生產路徑）
  auto-reply/reply/ # 消息處理管道
    maybe-run-capture.ts   # Capture agent + cron 調度
    hub-context.ts         # 每次對話注入的背景上下文
    dispatch-from-config.ts # 消息分發邏輯
  cron/             # 定時任務系統
    global-cron.ts         # CronService singleton
    bootstrap-jobs.ts      # 啟動時確保晨報等 job 存在
  gateway/          # HTTP 服務器 + 啟動入口
  infra/            # heartbeat、system-events 等基礎設施
extensions/feishu/  # 飛書 channel plugin（WebSocket 模式）
scripts/capture/    # 定時採集腳本（郵件/日曆/熱榜）
dist/               # tsdown 編譯輸出（reply-*.js = capture 邏輯）
```

## 關鍵運行方式
```bash
# 開發：強制重建 + 重啟
sudo rm /opt/LazyingArtBot/dist/.buildstamp && openclaw-restart

# 快速重啟（不重建）
sudo XDG_RUNTIME_DIR=/run/user/0 systemctl --user restart openclaw-gateway.service

# 查看日誌
sudo XDG_RUNTIME_DIR=/run/user/0 journalctl --user -u openclaw-gateway.service -f

# 服務狀態 / 確認 port
sudo bash -c 'XDG_RUNTIME_DIR=/run/user/0 systemctl --user status openclaw-gateway.service'
sudo ss -tlnp | grep 18789
```

## 重要約定
- **工具註冊**：新 LLM tool 加到 `src/agents/openclaw-tools.ts`（`moltbot-tools.ts` 僅測試用）
- **dist 結構**：`reply-*.js` bundle 包含 capture/reply 邏輯；`index.js` 是 gateway 入口
- **root 寫入**：`/opt/LazyingArtBot/` 由 root 擁有，需 `sudo` 寫文件
- **Config**：`~/.openclaw/openclaw.json`；Cron jobs：`~/.openclaw/cron/jobs.json`
- **Token 刷新**：Feishu user token → `~/.openclaw/feishu_user_token.json`（自動刷新）

## 常見任務
- **加新 LLM tool**：在 `src/agents/tools/` 新建文件，export `createXxxTool()`，在 `openclaw-tools.ts` import 並加入數組
- **加新 cron job**：直接編輯 `~/.openclaw/cron/jobs.json`，或通過 `getGlobalCron().add()`
- **加新 hub-context 段落**：在 `src/auto-reply/reply/hub-context.ts` 的 `buildHubContext()` 加 section
- **debug capture 邏輯**：在 `src/auto-reply/reply/maybe-run-capture.ts` 加 log，重建後看 dist/reply-*.js

## 環境變量（systemd service）
```
FEISHU_APP_ID=cli_a92aeaf256389cd3
FEISHU_APP_SECRET=hXdW0z6oMt4jShvylSwesggRSyEaUdnM
TOPHUB_API_KEY=<your_key>
MOLTBOT_CAPTURE_ALSO_REPLY=1
```
