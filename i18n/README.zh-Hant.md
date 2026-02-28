[English](../README.md) · [العربية](README.ar.md) · [Español](README.es.md) · [Français](README.fr.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Tiếng Việt](README.vi.md) · [中文 (简体)](README.zh-Hans.md) · [中文（繁體）](README.zh-Hant.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)



[![LazyingArt banner](https://github.com/lachlanchen/lachlanchen/raw/main/figs/banner.png)](https://github.com/lachlanchen/lachlanchen/blob/main/figs/banner.png)

# 🐼 LazyingArtBot (LAB)

[![License: MIT](https://img.shields.io/badge/License-MIT-1f6feb.svg)](../LICENSE)
[![Node >= 22.12.0](https://img.shields.io/badge/Node-%3E%3D22.12.0-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![pnpm workspace](https://img.shields.io/badge/pnpm-workspace-F69220?logo=pnpm&logoColor=white)](../pnpm-workspace.yaml)
[![Upstream: openclaw/openclaw](https://img.shields.io/badge/upstream-openclaw%2Fopenclaw-111827?logo=github)](https://github.com/openclaw/openclaw)
[![Gateway Default Port](https://img.shields.io/badge/Gateway-18789-0ea5e9)](#quick-start)
[![Version](https://img.shields.io/badge/version-2026.2.10-16a34a)](../package.json)
[![i18n README](https://img.shields.io/badge/i18n-10_languages-8b5cf6)](..)
[![Docs](https://img.shields.io/badge/docs-Mintlify-06b6d4)](../docs)
[![GitHub stars](https://img.shields.io/badge/GitHub-stars-0ea5e9?logo=github&logoColor=white)](https://github.com/lachlanchen/LazyingArtBot/stargazers)
[![GitHub issues](https://img.shields.io/badge/GitHub-issues-ef4444?logo=github&logoColor=white)](https://github.com/lachlanchen/LazyingArtBot/issues)


**LazyingArtBot** 是我為 **lazying.art** 打造的個人 AI 助理套件：

**LazyingArtBot** 建立在 OpenClaw 之上，並針對我每日工作流程做了客製化調整：多通道聊天、local-first 控制，以及 email → 行事曆/提醒/筆記自動化。

| 🔗 連結 | 網址 | 重點 |
| --- | --- | --- |
| 🌐 網站 | https://lazying.art | 主要網域與狀態儀表板 |
| 🤖 Bot 網域 | https://lazying.art | 聊天與助手入口 |
| 🧱 上游基礎 | https://github.com/openclaw/openclaw | OpenClaw 平台基礎 |
| 📦 本儲存庫 | https://github.com/lachlanchen/LazyingArtBot | LAB 專屬調整 |

---

## Table of contents

- [總覽](#overview)
- [快速檢視](#at-a-glance)
- [功能](#features)
- [核心能力](#core-capabilities)
- [專案結構](#project-structure)
- [先決條件](#prerequisites)
- [快速開始](#quick-start)
- [安裝](#installation)
- [使用方式](#usage)
- [設定](#configuration)
- [部署模式](#deployment-modes)
- [LazyingArt 工作流重點](#lazyingart-workflow-focus)
- [編排哲學](#orchestral-philosophy)
- [LAB 中的提示工具](#prompt-tools-in-lab)
- [範例](#examples)
- [開發備註](#development-notes)
- [疑難排解](#troubleshooting)
- [LAB 生態整合](#lab-ecosystem-integrations)
- [安裝源碼（快速參考）](#install-from-source-quick-reference)
- [路線圖](#roadmap)
- [貢獻指南](#contributing)
- [❤️ 支援](#-support)
- [致謝](#acknowledgements)
- [授權](#license)

---

## Overview

LAB 的核心是務實的個人生產力：

- ✅ 在你已經使用的聊天通道中，統一啟用一個助手。
- 🔐 資料與控制權保留在自己的機器或伺服器。
- 📬 將進站郵件轉為結構化動作（Calendar、Reminders、Notes）。
- 🛡️ 加入安全護欄，讓自動化兼具實用與可控。

簡單來說：更少瑣事、更快執行。

---

## At a glance

| 項目 | 本儲存庫基準 |
| --- | --- |
| 運行環境 | Node.js `>=22.12.0` |
| 套件管理工具 | `pnpm@10.23.0` |
| 核心 CLI | `openclaw` |
| 預設本機 Gateway | `127.0.0.1:18789` |
| 預設橋接埠 | `127.0.0.1:18790` |
| 主要文件 | `docs/`（Mintlify） |
| 主要 LAB 編排 | `orchestral/` + `scripts/prompt_tools/` |
| README i18n 位置 | `i18n/README.*.md` |

---

## Features

- 🌐 具備本機 Gateway 的多通道助手執行時環境。
- 🖥️ 可在瀏覽器使用的本機操作儀表板／聊天介面。
- 🧰 以工具驅動的自動化流程（scripts + prompt-tools）。
- 📨 將電子郵件分流並轉為 Notes、Reminders、Calendar 的可執行動作。
- 🧩 外掛與擴充生態系統（`extensions/*`）涵蓋通道、提供者與整合。
- 📱 專案內建多平台介面（`apps/macos`、`apps/ios`、`apps/android`、`ui`）。

---

## Core capabilities

| 能力 | 實務意義 |
| --- | --- |
| Multi-channel assistant runtime | 在你啟用的通道上，透過 gateway 與 agent sessions 協同運作 |
| Web dashboard / chat | 用於本機作業的瀏覽器控制介面 |
| Tool-enabled workflows | Shell + 檔案 + 自動化腳本的執行鏈 |
| Email automation pipeline | 解析郵件、分類動作類型、路由到 Notes/Reminders/Calendar，並保留操作紀錄便於複查與除錯 |

目前流程步驟如下：

- parse inbound mail
- classify action type
- save to Notes / Reminders / Calendar
- log every action for review and debugging

---

## Project structure

高層目錄架構如下：

```text
.
├─ src/                 # core runtime, gateway, channels, CLI, infra
├─ extensions/          # optional channel/provider/auth plugins
├─ orchestral/          # LAB orchestration pipelines + prompt tools
├─ scripts/             # build/dev/test/release helpers
├─ ui/                  # web dashboard UI package
├─ apps/                # macOS / iOS / Android apps
├─ docs/                # Mintlify documentation
├─ references/          # LAB references and operating notes
├─ test/                # test suites
├─ i18n/                # localized README files
├─ .env.example         # environment template
├─ docker-compose.yml   # gateway + CLI containers
├─ README_OPENCLAW.md   # larger upstream-style reference README
└─ README.md            # this LAB-focused README
```

補充：

- `scripts/prompt_tools` 指向 orchestrated 的 prompt-tool 實作。
- 專案根目錄的 `i18n/` 放置各語系 README。
- 此快照仍包含 `.github/workflows.disabled/`；若你要依賴 CI 行為，請先以當前環境再驗證。

---

## Prerequisites

本儲存庫的執行與工具基線：

- Node.js `>=22.12.0`
- pnpm `10.23.0`（見 `package.json` 中的 `packageManager`）
- 已設定模型提供商金鑰（`OPENAI_API_KEY`、`ANTHROPIC_API_KEY`、`GEMINI_API_KEY` 等）
- 選用：Docker + Docker Compose（用於容器化 gateway/CLI）
- 選用：行動與 macOS 建置，依目標平台準備對應工具鏈

可選的全域 CLI 安裝（與快速開始一致）：

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## Quick start

本儲存庫建議的 runtime 基線：**Node >= 22.12.0**（見 `package.json` 的 engine）。

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

完成後開啟本機儀表板與聊天介面：

- http://127.0.0.1:18789

若需要遠端存取，請透過你自己的安全隧道（例如 ngrok/Tailscale）對外提供本機 gateway，並保持驗證開啟。

---

## Installation

### Install from source

```bash
git clone https://github.com/lachlanchen/LazyingArtBot.git
cd LazyingArtBot
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw onboard --install-daemon
```

### Optional Docker workflow

專案內有 `docker-compose.yml`，包含：

- `openclaw-gateway`
- `openclaw-cli`

典型流程：

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

常見 `compose` 變數：

- `OPENCLAW_CONFIG_DIR`
- `OPENCLAW_WORKSPACE_DIR`
- `OPENCLAW_GATEWAY_PORT`
- `OPENCLAW_BRIDGE_PORT`

---

## Usage

常用指令：

```bash
# Onboard and install user daemon
openclaw onboard --install-daemon

# Run gateway in foreground
openclaw gateway run --bind loopback --port 18789 --verbose

# Send a direct message via configured channels
openclaw message send --to +1234567890 --message "Hello from LAB"

# Ask the agent directly
openclaw agent --message "Create today checklist" --thinking high
```

開發循環（watch mode）：

```bash
pnpm gateway:watch
```

UI 開發：

```bash
pnpm ui:dev
```

其他常用操作指令：

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --all
openclaw status --deep
openclaw health
openclaw doctor
```

---

## Configuration

環境與設定參考分散在 `.env` 與 `~/.openclaw/openclaw.json`。

1. 以 `.env.example` 為起點。
2. 設定 gateway 認證（建議 `OPENCLAW_GATEWAY_TOKEN`）。
3. 至少設定一個模型提供商金鑰（`OPENAI_API_KEY`、`ANTHROPIC_API_KEY` 等）。
4. 僅新增你實際啟用通道的憑證。

`/ .env.example` 的重點規則（保留原始規格）：

- 環境變數優先順序：process env -> `./.env` -> `~/.openclaw/.env` -> 設定檔 `env` 區塊。
- 既有非空 process env 值不會被覆寫。
- 像 `gateway.auth.token` 這類設定鍵，可優先於環境變數 fallback。

在對外網路暴露前的安全基線：

- 保持 gateway auth/pairing 開啟。
- 對入站通道使用嚴格 allowlist。
- 將每則入站訊息與郵件視為不受信任輸入。
- 以最小權限執行，並定期檢視日誌。

若你要把 gateway 暴露到網際網路，請啟用 token/password 驗證並使用受信任代理設定。

---

## Deployment modes

| 模式 | 適用情境 | 典型指令 |
| --- | --- | --- |
| 本機前景模式 | 開發與除錯 | `openclaw gateway run --bind loopback --port 18789 --verbose` |
| 本機 daemon | 日常個人使用 | `openclaw onboard --install-daemon` |
| Docker | 隔離式執行與可重複部署 | `docker compose up -d` |
| 遠端主機 + 隧道 | 外部網路存取本機服務 | 啟動 gateway + 安全隧道，並保持 auth 開啟 |

假設：生產等級反向代理加固、金鑰輪替與備份策略需依部署環境自行定義。

---

## LazyingArt workflow focus

這個分支在 **lazying.art** 的重點：

- 🎨 客製化品牌（LAB / 熊貓主題）
- 📱 手機友善的 dashboard／聊天體驗
- 📨 automail 流程變體（規則觸發、codex 協助儲存模式）
- 🧹 個人化清理與寄件者分類腳本
- 🗂️ 為日常作業優化 Notes / Reminders / Calendar 路由

本機自動化工作區：

- `~/.openclaw/workspace/automation/`
- 專案參考文件：`references/lab-scripts-and-philosophy.md`
- 專屬 Codex prompt tools：`scripts/prompt_tools/`

---

## Orchestral philosophy

LAB 的編排邏輯遵循一條核心原則：

將複雜目標拆成「可預期執行」與「以 prompt-tool 鏈彈性調整」兩種能力。

- 決定性腳本負責穩定的基礎工程：排程、檔案路由、執行目錄、重試與輸出交接。
- Prompt tools 負責適應性智慧：規劃、分類、上下文整合、以及不確定條件下的決策。
- 每個階段都會輸出可重複使用的產物，讓下游工具可直接接續產出更完整的 notes/email。

核心 orchestral 鏈路：

- Company entrepreneurship chain：
  company context ingestion -> market/funding/academic/legal intelligence -> concrete growth actions。
- Auto mail chain：
  inbound mail triage -> low-value mail 的保守跳過策略 -> 結構化 Notes/Reminders/Calendar 動作。
- Web search chain：
  results-page capture -> 目標式深度閱讀與 screenshot/content extraction -> 有證據的總結。

---

## Prompt tools in LAB

Prompt tools 採用模組化、可組合、以編排為先的設計。
它們可單獨執行，也可作為大型工作流中的串接階段。

- 讀寫作業：
  為 AutoLife 流程建立與更新 Notes、Reminders 與 Calendar 輸出。
- 擷取與閱讀作業：
  擷取搜尋結果頁與連結頁，並抽取結構化文字供下游分析。
- 工具連線作業：
  呼叫決定性腳本、跨階段傳遞產物、保持上下文連續性。

主要位置：

- `scripts/prompt_tools/`

---

## Examples

### Example: local-only gateway

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

### Example: ask agent to process daily planning

```bash
openclaw agent --message "Review today inbox and build a prioritized task plan" --thinking high
```

### Example: source build + watch loop

```bash
pnpm install
pnpm ui:build
pnpm build
pnpm gateway:watch
```

### Example: run in Docker

```bash
cp .env.example .env
docker compose up -d
docker compose logs -f openclaw-gateway
```

---

## Development notes

- 運行基線：Node `>=22.12.0`。
- 套件管理基線：`pnpm@10.23.0`（`packageManager` 欄位）。
- 常見品質關卡：

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- 開發模式 CLI：`pnpm openclaw ...`
- TS 運行循環：`pnpm dev`
- UI 套件指令透過根目錄腳本代理（`pnpm ui:build`、`pnpm ui:dev`）。

常見進階測試指令：

```bash
pnpm test:e2e
pnpm test:live
pnpm test:docker:all
pnpm test:ui
```

其他開發輔助：

```bash
pnpm docs:dev
pnpm format:check
pnpm lint
pnpm tsgo:test
```

補充假設：

- `package.json` 中的 `ios:*`、`android:*`、`mac:*` 提供了 iOS/macOS/Android 建置與執行指令，但平台簽章與佈署需求高度依賴環境，README 未完整涵蓋。

---

## Troubleshooting

### Gateway 無法存取 `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

檢查是否有連接埠衝突或 daemon 衝突。若使用 Docker，請確認映射主機埠與服務健康狀態。

### 驗證或通道設定問題

- 依 `.env.example` 重新比對 `.env`。
- 確認至少有一組模型金鑰。
- 只為實際啟用的通道設定 token。

### 建置或安裝問題

- 使用 Node `>=22.12.0` 重新執行 `pnpm install`。
- 以 `pnpm ui:build && pnpm build` 重新打包。
- 若缺少可選原生 peer 依賴，請檢查安裝日誌中 `@napi-rs/canvas` / `node-llama-cpp` 的相容性。

### 通用健康檢查

使用 `openclaw doctor` 檢查 migration/security/config 漂移問題。

### 常用診斷指令

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --deep
```

---

## LAB ecosystem integrations

LAB 將我更廣泛的 AI 產品與研究儲存庫整合為一個操作層，用於創作、成長與自動化。

Profile:

- https://github.com/lachlanchen?tab=repositories

整合倉儲：

- `VoidAbyss`（隙遊之淵）
- `AutoNovelWriter`（自動小說寫作）
- `AutoAppDev`（自動應用開發）
- `OrganoidAgent`（以基礎視覺模型與 LLM 為核心的類器官研究平台）
- `LazyEdit`（AI 輔助影片剪輯：字幕、轉錄、重點片段、metadata、字幕）
- `AutoPublish`（自動發布流程）

實務整合目標：

- 自動撰寫小說
- 自動開發應用
- 自動剪輯影片
- 自動發佈成果
- 自動分析類器官
- 自動處理郵件作業

---

## Install from source (quick reference)

```bash
git clone https://github.com/lachlanchen/LazyingArtBot.git
cd LazyingArtBot
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw onboard --install-daemon
```

開發循環：

```bash
pnpm gateway:watch
```

---

## Roadmap

本 LAB 分支的規劃方向（持續更新）：

- 以更嚴格的寄件者／規則分類，提升 automail 穩定度。
- 改善 orchestral 階段的可組合性與成果可追溯性。
- 強化行動優先作業與遠端 gateway 管理體驗。
- 深化與 LAB 生態系儲存庫的整合，實現端對端自動化生產。
- 持續加強無人值守自動化的安全預設與可觀測性。

---

## Contributing

本儲存庫沿用 OpenClaw 核心架構，同時保留個人 LAB 優先順序。

- 先閱讀 [`CONTRIBUTING.md`](../CONTRIBUTING.md)
- 參考上游文件：https://docs.openclaw.ai
- 安全問題請參閱 [`SECURITY.md`](../SECURITY.md)

若你對 LAB 專屬行為有疑問，請維持現有行為並在 PR 說明中記錄假設。

---

## Acknowledgements

LazyingArtBot 基於 **OpenClaw**：

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

感謝 OpenClaw 維護者與社群提供核心平台。

## ❤️ Support

| Donate | PayPal | Stripe |
| --- | --- | --- |
| [![Donate](https://camo.githubusercontent.com/24a4914f0b42c6f435f9e101621f1e52535b02c225764b2f6cc99416926004b7/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f446f6e6174652d4c617a79696e674172742d3045413545393f7374796c653d666f722d7468652d6261646765266c6f676f3d6b6f2d6669266c6f676f436f6c6f723d7768697465)](https://chat.lazying.art/donate) | [![PayPal](https://camo.githubusercontent.com/d0f57e8b016517a4b06961b24d0ca87d62fdba16e18bbdb6aba28e978dc0ea21/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f50617950616c2d526f6e677a686f754368656e2d3030343537433f7374796c653d666f722d7468652d6261646765266c6f676f3d70617970616c266c6f676f436f6c6f723d7768697465)](https://paypal.me/RongzhouChen) | [![Stripe](https://camo.githubusercontent.com/1152dfe04b6943afe3a8d2953676749603fb9f95e24088c92c97a01a897b4942/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f5374726970652d446f6e6174652d3633354246463f7374796c653d666f722d7468652d6261646765266c6f676f3d737472697065266c6f676f436f6c6f723d7768697465)](https://buy.stripe.com/aFadR8gIaflgfQV6T4fw400) |

## License

MIT（與上游一致，依適用範圍）。見 `LICENSE`。
