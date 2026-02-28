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


**LazyingArtBot** 是我為 **lazying.art** 打造的個人 AI 助手系統。
它以 OpenClaw 為基礎，並針對我日常流程做了客製化調整：多通道聊天、本機優先控管，以及 email → 行事曆/提醒/筆記自動化。

| 🔗 Link | URL |
| --- | --- |
| 🌐 Website | https://lazying.art |
| 🤖 Bot domain | https://lazying.art |
| 🧱 Upstream base | https://github.com/openclaw/openclaw |
| 📦 This repo | https://github.com/lachlanchen/LazyingArtBot |

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
- [❤️ Support](#-support)
- [Acknowledgements](#acknowledgements)
- [License](#license)

---

## Overview

LAB 的目標是落實可執行、可持續的個人生產力：

- ✅ 在你已在使用的聊天通道上，運行同一個助理。
- 🔐 將資料與控制權保留在自己的機器或伺服器上。
- 📬 將進站郵件轉為結構化動作（Calendar、Reminders、Notes）。
- 🛡️ 透過安全護欄，讓自動化既實用又可控。

一句話總結：少一些瑣事，多一點執行。

---

## At a glance

| Area | Current baseline in this repo |
| --- | --- |
| Runtime | Node.js `>=22.12.0` |
| Package manager | `pnpm@10.23.0` |
| Core CLI | `openclaw` |
| Default local gateway | `127.0.0.1:18789` |
| Default bridge port | `127.0.0.1:18790` |
| Primary docs | `docs/`（Mintlify） |
| Primary LAB orchestration | `orchestral/` + `scripts/prompt_tools/` |
| README i18n location | `i18n/README.*.md` |

---

## Features

- 🌐 具備本機 Gateway 的多通道助理執行時環境。
- 🖥️ 可在瀏覽器上進行本機化操作的儀表板／聊天界面。
- 🧰 具備工具調用的自動化流程（scripts + prompt-tools）。
- 📨 將郵件分流並轉為 Notes、Reminders、Calendar 的可執行動作。
- 🧩 插件與擴充生態（`extensions/*`）支援各種通道、供應者與整合。
- 📱 專案內建跨平台界面（`apps/macos`、`apps/ios`、`apps/android`、`ui`）。

---

## Core capabilities

| Capability | What it means in practice |
| --- | --- |
| Multi-channel assistant runtime | 在你啟用的通道上，跨 gateway + agent sessions 運作 |
| Web dashboard / chat | 針對本機操作的瀏覽器控制介面 |
| Tool-enabled workflows | Shell + 檔案 + 自動化腳本串接為可執行流程 |
| Email automation pipeline | 解析郵件、分類動作類型、路由至 Notes/Reminders/Calendar，並記錄所有動作以便回顧與除錯 |

Pipeline steps preserved from current workflow:

- parse inbound mail
- classify action type
- save to Notes / Reminders / Calendar
- log every action for review and debugging

---

## Project structure

高層的專案目錄結構如下：

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

Notes:

- `scripts/prompt_tools` 指向 orchestral 的 prompt-tool 實作。
- 專案根目錄的 `i18n/` 放置本地化 README。
- `.github/workflows.disabled/` 在目前快照中可見；在採信 CI 行為前，請先以實際環境確認。

---

## Prerequisites

本專案的執行與工具基線如下：

- Node.js `>=22.12.0`
- pnpm `10.23.0` baseline（見 `package.json` 的 `packageManager`）
- 已設定模型供應商金鑰（`OPENAI_API_KEY`、`ANTHROPIC_API_KEY`、`GEMINI_API_KEY` 等）
- 選用：Docker + Docker Compose（用於容器化 gateway/CLI）
- 選用：行動端／macOS 打包時依目標平台安裝對應工具鏈

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

完成後打開本機控制台開始聊天：

- http://127.0.0.1:18789

若需遠端存取，請透過自有的安全隧道（例如 ngrok、Tailscale）公開本機 gateway，並保持驗證開啟。

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

專案提供 `docker-compose.yml`，包含：

- `openclaw-gateway`
- `openclaw-cli`

Typical flow:

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

Compose 常見變數：

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

其他常用作業指令：

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

1. 從 `.env.example` 開始。
2. 設定 gateway 認證（建議 `OPENCLAW_GATEWAY_TOKEN`）。
3. 至少配置一個模型供應商金鑰（`OPENAI_API_KEY`、`ANTHROPIC_API_KEY` 等）。
4. 僅設定你實際啟用通道的憑證。

`.env.example` 的重點規則（保留自 repo）：

- 環境變數優先順序：process env -> `./.env` -> `~/.openclaw/.env` -> config `env` block。
- 既有、非空的 process env 值不會被覆寫。
- 像 `gateway.auth.token` 這類設定鍵可優先於 env fallback。

在對外網路暴露前，請先確認安全基線：

- 保持 gateway auth/pairing 開啟。
- 對入站通道維持嚴格 allowlist。
- 將每則入站訊息／郵件視為不可信輸入。
- 使用最小權限，並定期檢閱日誌。

若將 gateway 對外公開，請啟用 token/password 驗證，並使用可信任代理設定。

---

## Deployment modes

| Mode | Best for | Typical command |
| --- | --- | --- |
| Local foreground | 開發與除錯 | `openclaw gateway run --bind loopback --port 18789 --verbose` |
| Local daemon | 日常個人使用 | `openclaw onboard --install-daemon` |
| Docker | 隔離式執行與可重複部署 | `docker compose up -d` |
| Remote host + tunnel | 在外部存取家庭網路服務 | Run gateway + secure tunnel, keep auth enabled |

Assumption: production-grade reverse-proxy hardening, secret rotation, and backup policy are deployment-specific and should be defined per environment.

---

## LazyingArt workflow focus

本 fork 在 **lazying.art** 的優先順序如下：

- 🎨 自訂品牌元素（LAB / 熊貓主題）
- 📱 行動端友善的 dashboard / chat 體驗
- 📨 automail 流程變體（規則觸發、codex 協助儲存模式）
- 🧹 個人化清理與寄件者分類腳本
- 🗂️ 針對實際日常使用調整的 notes / reminders / calendar 路由

本地自動化工作區：

- `~/.openclaw/workspace/automation/`
- 專案內參考文件：`references/lab-scripts-and-philosophy.md`
- 專用 Codex prompt tools：`scripts/prompt_tools/`

---

## Orchestral philosophy

LAB orchestration 採用一項核心設計原則：
將複雜目標拆解為「可預期執行」與「精準 prompt-tool 鏈」。

- 決定性腳本負責穩定基礎流程：排程、檔案路由、執行目錄、重試機制與輸出交接。
- Prompt tools 處理適應性智慧：規劃、分流、上下文彙整、以及在不確定情境下的判斷。
- 每個階段都會輸出可重用成果，讓後續工具能串接組成更完整的 notes/email，避免從頭開始。

核心 orchestral 鏈路：

- Company entrepreneurship chain：
  company context ingestion -> market/funding/academic/legal intelligence -> concrete growth actions。
- Auto mail chain：
  inbound mail triage -> conservative skip policy for low-value mail -> structured Notes/Reminders/Calendar actions。
- Web search chain：
  results-page capture -> targeted deep reads with screenshot/content extraction -> evidence-backed synthesis。

---

## Prompt tools in LAB

Prompt tools 採用模組化、可組合、以 orchestration 為先的設計。
可單獨執行，也可作為較大工作流中的串接階段。

- 讀寫操作：
  為 AutoLife 作業建立與更新 Notes、Reminders、Calendar 輸出。
- 截圖與閱讀操作：
  擷取搜尋頁面與連結頁面，並抽取結構化文字供下游分析。
- 工具連接操作：
  呼叫決定性腳本、跨階段傳遞成果、維持上下文連續性。

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

- Runtime baseline: Node `>=22.12.0`。
- 套件管理 baseline: `pnpm@10.23.0`（`packageManager` 欄位）。
- 常見品質關卡：

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- 開發模式 CLI：`pnpm openclaw ...`
- TS 運行循環：`pnpm dev`
- UI 套件指令由根目錄腳本代理（`pnpm ui:build`、`pnpm ui:dev`）。

倉儲中常用擴充測試指令：

```bash
pnpm test:e2e
pnpm test:live
pnpm test:docker:all
pnpm test:ui
```

補充開發輔助指令：

```bash
pnpm docs:dev
pnpm format:check
pnpm lint
pnpm tsgo:test
```

重要假設：

- `package.json` 內包含 `ios:*`、`android:*`、`mac:*` 指令，但行動／macOS 建置與執行的簽章與簽發需求，皆受各環境限制且本 README 未完整說明。

---

## Troubleshooting

### Gateway not reachable on `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

檢查是否有埠衝突或 daemon 衝突。若使用 Docker，請確認主機對應埠位、服務健康度。

### Auth or channel config issues

- 依 `.env.example` 重新比對 `.env`。
- 確認至少設定一組模型金鑰。
- 僅為實際啟用的通道設定 token。

### Build or install issues

- 重跑 `pnpm install`，並確認 Node `>=22.12.0`。
- 以 `pnpm ui:build && pnpm build` 重建。
- 若缺少可選原生套件，請於安裝日誌中檢查 `@napi-rs/canvas` / `node-llama-cpp` 的相容性。

### General health checks

使用 `openclaw doctor` 檢查 migration/security/config 漂移問題。

### Useful diagnostics

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --deep
```

---

## LAB ecosystem integrations

LAB 將我更廣泛的 AI 產品與研究倉儲整合成同一個作業層，用於創作、成長與自動化。

Profile:

- https://github.com/lachlanchen?tab=repositories

整合倉儲：

- `VoidAbyss`（隙遊之淵）
- `AutoNovelWriter`（automatic novel writing）
- `AutoAppDev`（automatic app development）
- `OrganoidAgent`（organoid research platform with foundation vision models + LLMs）
- `LazyEdit`（AI-assisted video editing: captions/transcription/highlights/metadata/subtitles）
- `AutoPublish`（automatic publication pipeline）

實務整合目標：

- 自動撰寫小說
- 自動開發應用
- 自動剪輯影片
- 自動發布成果
- 自動分析腦類器官資料
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

本 LAB fork 的規劃方向（進行中）：

- 透過更嚴格的寄件者／規則分類，提升 automail 的穩定性。
- 改善 orchestral 階段的可組合性與成果可追溯性。
- 強化行動優先作業與遠端 gateway 管理體驗。
- 深化與 LAB 生態倉儲的整合，達成端到端自動化生產。
- 持續加固無人值守自動化的安全預設值與可觀測性。

---

## Contributing

本專案在沿用 OpenClaw 核心架構的同時，聚焦個人 LAB 的需求。

- 閱讀 [`CONTRIBUTING.md`](../CONTRIBUTING.md)
- 參考上游文件：https://docs.openclaw.ai
- 安全問題請見 [`SECURITY.md`](../SECURITY.md)

若對 LAB 專用行為有疑問，請保留既有行為並在 PR 說明中註明前提假設。

## ❤️ Support

| Donate | PayPal | Stripe |
|---|---|---|
| [![Donate](https://img.shields.io/badge/Donate-LazyingArt-0EA5E9?style=for-the-badge&logo=ko-fi&logoColor=white)](https://chat.lazying.art/donate) | [![PayPal](https://img.shields.io/badge/PayPal-RongzhouChen-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/RongzhouChen) | [![Stripe](https://img.shields.io/badge/Stripe-Donate-635BFF?style=for-the-badge&logo=stripe&logoColor=white)](https://buy.stripe.com/aFadR8gIaflgfQV6T4fw400) |

---

## Acknowledgements

LazyingArtBot 基於 **OpenClaw**：

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

感謝 OpenClaw 維護者與社群提供核心平台。

---

## License

MIT（適用於上游的授權條款）。見 `LICENSE`。
