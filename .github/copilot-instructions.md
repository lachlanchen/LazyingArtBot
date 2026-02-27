# Kairo — Copilot 指引

Kairo 是自托管 AI 秘書系統，TypeScript/Node.js，通過 Telegram/飛書 IM 與用戶交互。

**加新 LLM 工具**：在 `src/agents/tools/` 建文件，`src/agents/openclaw-tools.ts` 中 import 並加入 createOpenClawTools() 數組。

**修改 capture 邏輯**：`src/auto-reply/reply/maybe-run-capture.ts`

**修改每次對話的背景上下文**：`src/auto-reply/reply/hub-context.ts` 的 `buildHubContext()`

**構建**：`pnpm build`（本地）或 `openclaw-restart`（伺服器）。Config 在 `~/.openclaw/openclaw.json`。
