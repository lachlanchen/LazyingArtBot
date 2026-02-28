[English](../README.md) · [العربية](README.ar.md) · [Español](README.es.md) · [Français](README.fr.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Tiếng Việt](README.vi.md) · [中文 (简体)](README.zh-Hans.md) · [中文（繁體）](README.zh-Hant.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)




[![LazyingArt banner](https://github.com/lachlanchen/lachlanchen/raw/main/figs/banner.png)](https://github.com/lachlanchen/lachlanchen/blob/main/figs/banner.png)

# 🐼 LazyingArtBot (LAB)

[![License: MIT](https://img.shields.io/badge/License-MIT-1f6feb.svg)](../LICENSE)
[![Node >= 22.12.0](https://img.shields.io/badge/Node-%3E%3D22.12.0-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![pnpm workspace](https://img.shields.io/badge/pnpm-workspace-F69220?logo=pnpm&logoColor=white)](../pnpm-workspace.yaml)
[![Upstream: openclaw/openclaw](https://img.shields.io/badge/upstream-openclaw%2Fopenclaw-111827?logo=github)](https://github.com/openclaw/openclaw)
[![Gateway Default Port](https://img.shields.io/badge/Gateway-18789-0ea5e9)](#quick-start)
[![Version](https://img.shields.io/badge/version-2026.2.10-16a34a)](../package.json)
[![i18n README](https://img.shields.io/badge/i18n-10_languages-8b5cf6)](../i18n)
[![Docs](https://img.shields.io/badge/docs-Mintlify-06b6d4)](../docs)
[![GitHub stars](https://img.shields.io/badge/GitHub-stars-0ea5e9?logo=github&logoColor=white)](https://github.com/lachlanchen/LazyingArtBot/stargazers)
[![GitHub issues](https://img.shields.io/badge/GitHub-issues-ef4444?logo=github&logoColor=white)](https://github.com/lachlanchen/LazyingArtBot/issues)


**LazyingArtBot** 是我為 **lazying.art** 打造的個人 AI 助手系統：

**LazyingArtBot** 建立於 OpenClaw 之上，並針對我日常工作流程做了客製化：多通道聊天、local-first 控制，以及 email → 行事曆/提醒/筆記自動化。

| 🔗 Link | URL | Focus |
| --- | --- | --- |
| 🌐 Website | https://lazying.art | 主網域與狀態儀表板 |
| 🤖 Bot domain | https://lazying.art | 聊天與助手入口 |
| 🧱 Upstream base | https://github.com/openclaw/openclaw | OpenClaw 平台基礎 |
| 📦 This repo | https://github.com/lachlanchen/LazyingArtBot | LAB 專屬客製化 |

---

## Table of contents

- [Overview](#overview)
- [At a glance](#at-a-glance)
- [Features](#features)
- [Core capabilities](#core-capabilities)
- [Project structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Quick start](#quick-start)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Deployment modes](#deployment-modes)
- [LazyingArt workflow focus](#lazyingart-workflow-focus)
- [Orchestral philosophy](#orchestral-philosophy)
- [Prompt tools in LAB](#prompt-tools-in-lab)
- [Examples](#examples)
- [Development notes](#development-notes)
- [Troubleshooting](#troubleshooting)
- [LAB ecosystem integrations](#lab-ecosystem-integrations)
- [Install from source (quick reference)](#install-from-source-quick-reference)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [Acknowledgements](#acknowledgements)
- [❤️ Support](#-support)
- [Contact](#contact)
- [License](#license)

---

## Overview

LAB 聚焦於務實的個人效率：

- ✅ 在你已在使用的聊天通道中運作同一位助理。
- 🔐 將資料與控制保留在你自己的機器或伺服器上。
- 📬 將收件信件轉換為結構化動作（Calendar、Reminders、Notes）。
- 🛡️ 加上防護欄位，讓自動化既實用又安全。

一句話總結：少做瑣事，多做好執行。

---

## At a glance

| 領域 | 本儲存庫目前基線 |
| --- | --- |
| Runtime | Node.js `>=22.12.0` |
| 套件管理員 | `pnpm@10.23.0` |
| 核心 CLI | `openclaw` |
| 預設本地閘道器 | `127.0.0.1:18789` |
| 預設橋接埠 | `127.0.0.1:18790` |
| 主要文件 | `docs/`（Mintlify） |
| 主要 LAB 編排 | `orchestral/` + `scripts/prompt_tools/` |
| README i18n 位置 | `i18n/README.*.md` |

---

## Features

- 🌐 具備本地閘道的多通道助理執行時。
- 🖥️ 提供用於本地操作的瀏覽器儀表板／聊天介面。
- 🧰 工具驅動的自動化管線（scripts + prompt-tools）。
- 📨 收件信件分流並轉為 Notes、Reminders、Calendar 的可執行動作。
- 🧩 外掛/延伸模組生態（`extensions/*`）支援通道、供應商與整合。
- 📱 倉庫內多平台介面（`apps/macos`、`apps/ios`、`apps/android`、`ui`）。

---

## Core capabilities

| 能力 | 實際意思 |
| --- | --- |
| 多通道助理執行時 | 透過閘道在你啟用的通道上統一運行 agent session |
| Web dashboard / chat | 用瀏覽器做本地操作的控制介面 |
| 工具驅動工作流 | Shell、檔案與自動化腳本執行鏈 |
| 電子郵件自動化管線 | 解析信件、分類動作類型、路由到 Notes/Reminders/Calendar，並記錄每次動作供後續檢視／除錯 |

本專案保留的流程如下：

- parse inbound mail
- classify action type
- save to Notes / Reminders / Calendar
- log every action for review and debugging

---

## Project structure

高階儲存庫版面：

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

補充說明：

- `scripts/prompt_tools` 指向 orchestral 的 prompt-tool 實作。
- 根目錄 `i18n/` 存放在地化 README 變體。
- 本快照仍保留 `.github/workflows.disabled/`；若依賴 CI 行為，請在使用前先確認實際是否啟用。

---

## Prerequisites

本儲存庫的執行與工具基線：

- Node.js `>=22.12.0`
- pnpm `10.23.0`（請參考 `package.json` 的 `packageManager`）
- 至少設定一個模型供應商金鑰（`OPENAI_API_KEY`、`ANTHROPIC_API_KEY`、`GEMINI_API_KEY` 等）
- 選用：Docker + Docker Compose，用於容器化閘道與 CLI
- 選用於行動端／macOS 打包：依目標平臺準備 Apple / Android 工具鏈

選配的全域 CLI 安裝（與快速開始流程一致）：

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## Quick start

本專案執行基線：**Node >= 22.12.0**（見 `package.json` engine）。

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

接著開啟本地儀表板與聊天介面：

- http://127.0.0.1:18789

若需遠端存取，請用你自己的安全隧道（例如 ngrok / Tailscale）公開本地閘道，並持續啟用驗證。

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

本專案包含 `docker-compose.yml`，內容包含：

- `openclaw-gateway`
- `openclaw-cli`

典型流程：

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

常見 Compose 變數：

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

開發迴圈（watch mode）：

```bash
pnpm gateway:watch
```

UI 開發：

```bash
pnpm ui:dev
```

補充常用營運指令：

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

環境與設定參考分散於 `.env` 與 `~/.openclaw/openclaw.json`。

1. 從 `.env.example` 開始。
2. 設定閘道驗證（建議 `OPENCLAW_GATEWAY_TOKEN`）。
3. 至少設定一個模型供應商金鑰（`OPENAI_API_KEY`、`ANTHROPIC_API_KEY` 等）。
4. 只為啟用的通道設定對應憑證。

保留自 `.env.example` 的重點：

- 環境優先順序：process env -> `./.env` -> `~/.openclaw/.env` -> config `env` 區塊。
- 已存在且非空的 process env 不會被覆蓋。
- 像 `gateway.auth.token` 這類設定鍵可優先於環境變數 fallback。

對外網暴露前的安全基線：

- 保留閘道驗證與配對。
- 針對入站通道使用嚴格 allowlist。
- 將每筆入站訊息／郵件視為不可信輸入。
- 以最小權限原則執行，並定期檢視日誌。

若將閘道暴露到網際網路，請要求 token/password 驗證並配置可信 proxy。

---

## Deployment modes

| 模式 | 最適用情境 | 典型指令 |
| --- | --- | --- |
| 本地前景 | 開發與除錯 | `openclaw gateway run --bind loopback --port 18789 --verbose` |
| 本地 daemon | 日常個人使用 | `openclaw onboard --install-daemon` |
| Docker | 隔離式執行與可重現部署 | `docker compose up -d` |
| 遠端主機 + 隧道 | 從外部網路存取 | 運行閘道 + 安全隧道，並持續啟用驗證 |

預設假設：生產級反向代理防護、金鑰輪替與備份策略皆屬各環境專屬設計。

---

## LazyingArt workflow focus

這個分支針對 **lazying.art** 的個人流程進行優化：

- 🎨 客製化品牌（LAB / 熊貓主題）
- 📱 行動裝置友善的儀表板與聊天體驗
- 📨 automail 管線變體（規則觸發、codex 輔助儲存模式）
- 🧹 個人清理與寄件者分類腳本
- 🗂️ 為實際日常使用最佳化 notes/reminders/calendar 路由

自動化工作區（本地）：

- `~/.openclaw/workspace/automation/`
- 相關腳本請見 `references/lab-scripts-and-philosophy.md`
- 專屬 Codex prompt tools：`scripts/prompt_tools/`

---

## Orchestral philosophy

LAB 編排遵循一條核心規則：
將複雜目標拆解為「確定性執行 + 專注的 prompt-tool 連鎖」。

- 確定性腳本負責可靠的基礎流程：
  排程、檔案路由、執行目錄、重試，以及輸出交接。
- Prompt tools 負責適應式智慧：
  規劃、分流、上下文整合，以及不確定情境下的決策。
- 每個階段都會輸出可重複使用的成果物，讓下游工具可在其上組合出更完整的 notes/email，而不必從零開始。

核心編排鏈路：

- 企業創業鏈：
  company context ingestion -> market/funding/academic/legal intelligence -> 具體成長行動。
- 自動郵件鏈：
  inbound mail triage -> 對低價值郵件採取保守略過策略 -> 結構化 Notes/Reminders/Calendar 動作。
- 網頁搜尋鏈：
  results-page capture -> 有目標的深度閱讀與截圖/內容擷取 -> 以證據為基礎的綜合分析。

---

## Prompt tools in LAB

Prompt tools 在 LAB 中為模組化、可組合、以編排為先的設計。
它們可獨立運行，也可作為更大工作流中的串接階段。

- 讀取／儲存操作：
  為 AutoLife 流程建立與更新 Notes、Reminders 與 Calendar 輸出。
- 截圖／閱讀操作：
  擷取搜尋頁與目標頁，再抽取結構化文字供下游分析。
- 工具連接操作：
  呼叫確定性腳本、在各階段交換產物，並維持上下文延續性。

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

- Runtime 基線：Node `>=22.12.0`。
- 套件管理基線：`pnpm@10.23.0`（`packageManager` 欄位）。
- 常見品質門檻：

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- 開發模式 CLI：`pnpm openclaw ...`
- TypeScript 迴圈：`pnpm dev`
- UI 套件指令由根腳本代理（`pnpm ui:build`、`pnpm ui:dev`）。

在本專案中常見的擴充測試指令：

```bash
pnpm test:e2e
pnpm test:live
pnpm test:docker:all
pnpm test:ui
```

額外開發輔助：

```bash
pnpm docs:dev
pnpm format:check
pnpm lint
pnpm tsgo:test
```

補充說明：

- 移動端／macOS 的建置與執行指令在 `package.json` 中有 `ios:*`、`android:*`、`mac:*`，但平台簽章與授權需求視環境而異，本 README 無法完整列出。

---

## Troubleshooting

### Gateway not reachable on `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

請檢查埠衝突與守護行程衝突。若使用 Docker，請確認對應主機埠映射與服務健康狀態。

### Auth or channel config issues

- 依據 `.env.example` 重新核對 `.env` 設定。
- 確保至少設定一組模型金鑰。
- 僅為實際啟用的通道設定 token。

### Build or install issues

- 使用 Node `>=22.12.0` 重新執行 `pnpm install`。
- 以 `pnpm ui:build && pnpm build` 重新建置。
- 若缺少可選原生 peer 依賴，請檢查安裝日誌中的 `@napi-rs/canvas` / `node-llama-cpp` 相容性訊息。

### General health checks

使用 `openclaw doctor` 來偵測 migration/security/config 漂移問題。

### Useful diagnostics

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --deep
```

---

## LAB ecosystem integrations

LAB 將我更廣泛的 AI 產品與研究倉庫整合為一個共同運行層，用於創作、成長與自動化。

Profile:

- https://github.com/lachlanchen?tab=repositories

已整合倉庫：

- `VoidAbyss`（隙遊之淵）
- `AutoNovelWriter`（自動寫小說）
- `AutoAppDev`（自動 app 開發）
- `OrganoidAgent`（以基礎視覺模型搭配 LLM 的類器官研究平台）
- `LazyEdit`（AI 輔助影片編輯：字幕、逐字稿、精彩片段、元資料、字幕）
- `AutoPublish`（自動發佈管線）

實際整合目標：

- 自動寫小說
- 自動開發 App
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

開發迴圈：

```bash
pnpm gateway:watch
```

---

## Roadmap

本 LAB 分支（持續更新）的規劃方向：

- 透過更嚴格的寄件者／規則分類，提升 automail 的可靠度。
- 改善 orchestral 階段可組合性與產物可追溯性。
- 強化移動優先操作與遠端閘道管理體驗。
- 深化與 LAB 生態倉庫的整合，建構端到端自動化生產。
- 持續強化無人值守自動化的安全預設值與可觀測性。

---

## Contributing

此儲存庫在沿用 OpenClaw 核心架構的同時，也保留個人 LAB 的優先順序。

- 參考 [`CONTRIBUTING.md`](../CONTRIBUTING.md)
- 檢視上游文件：https://docs.openclaw.ai
- 安全議題請見 [`SECURITY.md`](../SECURITY.md)

若對 LAB 特定行為有疑問，請保留既有行為並在 PR 筆記中說明假設。

---

## Acknowledgements

LazyingArtBot 基於 **OpenClaw**：

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

感謝 OpenClaw 維護者與社群提供的核心平台支援。

## ❤️ Support

| Donate | PayPal | Stripe |
| --- | --- | --- |
| [![Donate](https://camo.githubusercontent.com/24a4914f0b42c6f435f9e101621f1e52535b02c225764b2f6cc99416926004b7/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f446f6e6174652d4c617a79696e674172742d3045413545393f7374796c653d666f722d7468652d6261646765266c6f676f3d6b6f2d6669266c6f676f436f6c6f723d7768697465)](https://chat.lazying.art/donate) | [![PayPal](https://camo.githubusercontent.com/d0f57e8b016517a4b06961b24d0ca87d62fdba16e18bbdb6aba28e978dc0ea21/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f50617950616c2d526f6e677a686f754368656e2d3030343537433f7374796c653d666f722d7468652d6261646765266c6f676f3d70617970616c266c6f676f436f6c6f723d7768697465)](https://paypal.me/RongzhouChen) | [![Stripe](https://camo.githubusercontent.com/1152dfe04b6943afe3a8d2953676749603fb9f95e24088c92c97a01a897b4942/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f5374726970652d446f6e6174652d3633354246463f7374796c653d666f722d7468652d6261646765266c6f676f3d737472697065266c6f676f436f6c6f723d7768697465)](https://buy.stripe.com/aFadR8gIaflgfQV6T4fw400) |

## Contact

- Website: https://lazying.art
- Repository: https://github.com/lachlanchen/LazyingArtBot
- Issue tracker: https://github.com/lachlanchen/LazyingArtBot/issues
- Security or safety concerns: https://github.com/lachlanchen/LazyingArtBot/blob/main/SECURITY.md

---

## License

MIT（與上游相同，於適用情況下）。參見 `LICENSE`。
