[English](../README.md) · [العربية](README.ar.md) · [Español](README.es.md) · [Français](README.fr.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Tiếng Việt](README.vi.md) · [中文 (简体)](README.zh-Hans.md) · [中文（繁體）](README.zh-Hant.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)


<p align="center">
  <img src="https://github.com/lachlanchen/lachlanchen/raw/main/figs/banner.png" alt="LazyingArtBot banner" />
</p>

# 🐼 LazyingArtBot (LAB)

[![License: MIT](https://img.shields.io/badge/License-MIT-1f6feb.svg)](LICENSE)
[![Node >= 22.12.0](https://img.shields.io/badge/Node-%3E%3D22.12.0-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![pnpm workspace](https://img.shields.io/badge/pnpm-workspace-F69220?logo=pnpm&logoColor=white)](pnpm-workspace.yaml)
[![Upstream: openclaw/openclaw](https://img.shields.io/badge/upstream-openclaw%2Fopenclaw-111827?logo=github)](https://github.com/openclaw/openclaw)
[![Gateway Default Port](https://img.shields.io/badge/Gateway-18789-0ea5e9)](#-quick-start)
[![Version](https://img.shields.io/badge/version-2026.2.10-16a34a)](package.json)

>
> 注意：`i18n/` 目錄已存在，目前包含阿拉伯語版本。其他語系的 README 會逐一處理，以確保與來源更新保持一致。

**LazyingArtBot** 是我在 **lazying.art** 上使用的個人 AI 助理技術棧。  
它建立在 OpenClaw 之上，並依照我的日常流程進行調整：多通道聊天、本機優先控制，以及 Email → 行事曆／提醒事項／筆記的自動化。

| Link | URL |
| --- | --- |
| Website | https://lazying.art |
| Bot domain | https://lazying.art |
| Upstream base | https://github.com/openclaw/openclaw |
| This repo | https://github.com/lachlanchen/LazyingArtBot |

---

## Table of contents

- [🧭 Overview](#-overview)
- [⚡ At a glance](#-at-a-glance)
- [⚙️ Core capabilities](#️-core-capabilities)
- [🧱 Project structure](#-project-structure)
- [📋 Prerequisites](#-prerequisites)
- [🚀 Quick start](#-quick-start)
- [🧱 Installation](#-installation)
- [🛠️ Usage](#️-usage)
- [🔐 Configuration](#-configuration)
- [🧩 LazyingArt workflow focus](#-lazyingart-workflow-focus)
- [🎼 Orchestral philosophy](#-orchestral-philosophy)
- [🧰 Prompt tools in LAB](#-prompt-tools-in-lab)
- [💡 Examples](#-examples)
- [🧪 Development notes](#-development-notes)
- [🩺 Troubleshooting](#-troubleshooting)
- [🌐 LAB ecosystem integrations](#-lab-ecosystem-integrations)
- [Install from source](#install-from-source)
- [🗺️ Roadmap](#️-roadmap)
- [🤝 Contributing](#-contributing)
- [❤️ Support / Sponsor](#️-support--sponsor)
- [🙏 Acknowledgements](#-acknowledgements)
- [📄 License](#-license)

---

## 🧭 Overview

LAB 專注於實用的個人生產力：

- 在你已經使用的聊天通道上，運行同一個助理。
- 將資料與控制權保留在你自己的機器／伺服器上。
- 將收到的 Email 轉換為結構化行動（Calendar、Reminders、Notes）。
- 加上安全護欄，讓自動化既有用又可控。

一句話：減少瑣務，提高執行效率。

---

## ⚡ At a glance

| Area | Current baseline in this repo |
| --- | --- |
| Runtime | Node.js `>=22.12.0` |
| Package manager | `pnpm@10.23.0` |
| Core CLI | `openclaw` |
| Default local gateway | `127.0.0.1:18789` |
| Primary docs | `docs/` (Mintlify) |
| Primary LAB orchestration | `orchestral/` + `scripts/prompt_tools/` |

---

## ⚙️ Core capabilities

- 多通道助理執行環境（Gateway + agent sessions）。
- Web 儀表板／網頁聊天控制介面。
- 支援工具呼叫的助理工作流（shell、檔案、自動化腳本）。
- 用於個人作業的 Email 自動化流程：
  - 解析入站郵件
  - 分類行動類型
  - 儲存到 Notes / Reminders / Calendar
  - 記錄每一步操作，方便審核與除錯

---

## 🧱 Project structure

儲存庫高階結構：

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
├─ .env.example         # environment template
├─ docker-compose.yml   # gateway + CLI containers
├─ README_OPENCLAW.md   # larger upstream-style reference README
└─ README.md            # this LAB-focused README
```

備註：

- `scripts/prompt_tools` 指向 orchestral 的 prompt-tool 實作。
- 在此快照中，根目錄 `i18n/` 已存在但內容仍較精簡；本地化文件主要位於 `docs/`。

---

## 📋 Prerequisites

本儲存庫的執行與工具基線：

- Node.js `>=22.12.0`
- pnpm `10.23.0` 基線（見 `package.json` 的 `packageManager`）
- 已設定的模型供應商金鑰（`OPENAI_API_KEY`、`ANTHROPIC_API_KEY`、`GEMINI_API_KEY` 等）
- 可選：Docker + Docker Compose（用於容器化 gateway/CLI）

可選的全域 CLI 安裝（與 quick-start 流程一致）：

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## 🚀 Quick start

本儲存庫的執行基線：**Node >= 22.12.0**（`package.json` engine）。

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

接著開啟本機儀表板並開始聊天：

- http://127.0.0.1:18789

若需遠端存取，請透過你自己的安全隧道（例如 ngrok/Tailscale）暴露本機 gateway，並保持啟用驗證。

---

## 🧱 Installation

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

內含 `docker-compose.yml`，包含：

- `openclaw-gateway`
- `openclaw-cli`

典型流程：

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

注意：掛載路徑與連接埠由 compose 變數控制，例如 `OPENCLAW_CONFIG_DIR`、`OPENCLAW_WORKSPACE_DIR`、`OPENCLAW_GATEWAY_PORT`、`OPENCLAW_BRIDGE_PORT`。

---

## 🛠️ Usage

常用命令：

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

---

## 🔐 Configuration

環境與設定參考分散在 `.env` 與 `~/.openclaw/openclaw.json`。

1. 由 `.env.example` 開始。
2. 設定 gateway 驗證（建議 `OPENCLAW_GATEWAY_TOKEN`）。
3. 至少設定一組模型供應商金鑰（`OPENAI_API_KEY`、`ANTHROPIC_API_KEY` 等）。
4. 僅為你實際啟用的通道設定對應憑證。

從儲存庫保留的重要 `.env.example` 說明：

- Env 優先序：process env → `./.env` → `~/.openclaw/.env` → config `env` block。
- 現有且非空的 process env 值不會被覆蓋。
- 如 `gateway.auth.token` 等設定鍵，可能優先於 env fallback。

對外網暴露前的安全基線：

- 保持啟用 gateway auth/pairing。
- 對入站通道維持嚴格 allowlist。
- 將每一封入站訊息／Email 視為不受信任輸入。
- 以最小權限運行，並定期檢視日誌。

若你將 gateway 對外開放，請強制啟用 token/password 驗證與可信代理設定。

---

## 🧩 LazyingArt workflow focus

此 fork 優先支援我在 **lazying.art** 的個人流程：

- 自訂品牌（LAB / 熊貓主題）
- 行動裝置友善的 dashboard/chat 體驗
- automail 流程變體（規則觸發、codex 輔助儲存模式）
- 個人清理與寄件者分類腳本
- 針對日常實際使用調校的 notes/reminders/calendar 路由

自動化工作區（本機）：

- `~/.openclaw/workspace/automation/`
- 儲存庫中的腳本參考：`references/lab-scripts-and-philosophy.md`
- 專用 Codex prompt tools：`scripts/prompt_tools/`

---

## 🎼 Orchestral philosophy

LAB orchestration 遵循一條設計原則：  
把困難目標拆成可確定執行的流程 + 聚焦的 prompt-tool 鏈。

- 確定性腳本負責可靠的管線基礎：
  排程、檔案路由、執行目錄、重試、輸出交接。
- Prompt tools 負責適應式智慧：
  規劃、分流、上下文綜整，以及在不確定情境下做決策。
- 每個階段都輸出可重用產物，讓下游工具能組合出更強的最終筆記／Email，而不是每次從零開始。

核心 orchestral 鏈：

- Company entrepreneurship 鏈：
  company context ingestion → market/funding/academic/legal intelligence → concrete growth actions。
- Auto mail 鏈：
  inbound mail triage → conservative skip policy for low-value mail → structured Notes/Reminders/Calendar actions。
- Web search 鏈：
  results-page capture → targeted deep reads with screenshot/content extraction → evidence-backed synthesis。

---

## 🧰 Prompt tools in LAB

Prompt tools 採模組化、可組合、以 orchestration 為先。  
它們可以獨立運行，也可以作為更大型工作流中的串接階段。

- 讀寫操作：
  為 AutoLife 作業建立與更新 Notes、Reminders、Calendar 輸出。
- 截圖／讀取操作：
  擷取搜尋頁面與連結頁面，再抽取結構化文字供下游分析。
- 工具連接操作：
  呼叫確定性腳本、跨階段交換產物，並維持上下文連續性。

主要位置：

- `scripts/prompt_tools/`

---

## 💡 Examples

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

---

## 🧪 Development notes

- 執行基線：Node `>=22.12.0`。
- 套件管理基線：`pnpm@10.23.0`（`packageManager` 欄位）。
- 常用品質檢查：

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- 開發環境執行 CLI：`pnpm openclaw ...`
- TS 執行迴圈：`pnpm dev`
- UI 套件命令透過根目錄 scripts 代理（`pnpm ui:build`、`pnpm ui:dev`）。

---

## 🩺 Troubleshooting

### Gateway not reachable on `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

請檢查連接埠衝突與 daemon 衝突。若使用 Docker，請確認主機映射連接埠與服務健康狀態。

### Auth or channel config issues

- 依照 `.env.example` 重新檢查 `.env` 值。
- 確認至少設定一組模型金鑰。
- 僅為實際啟用的通道設定對應 token。

### General health checks

使用 `openclaw doctor` 來檢測 migration/security/config drift 問題。

---

## 🌐 LAB ecosystem integrations

LAB 將我更廣泛的 AI 產品與研究儲存庫整合到同一個運作層，支援創作、成長與自動化。

Profile:

- https://github.com/lachlanchen?tab=repositories

Integrated repos:

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (automatic novel writing)
- `AutoAppDev` (automatic app development)
- `OrganoidAgent` (organoid research platform with foundation vision models + LLMs)
- `LazyEdit` (AI-assisted video editing: captions/transcription/highlights/metadata/subtitles)
- `AutoPublish` (automatic publication pipeline)

Practical LAB integration goals:

- Auto write novels
- Auto develop apps
- Auto edit videos
- Auto publish outputs
- Auto analyze organoids
- Auto handle email operations

---

## Install from source

```bash
git clone https://github.com/lachlanchen/LazyingArtBot.git
cd LazyingArtBot
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw onboard --install-daemon
```

Dev loop:

```bash
pnpm gateway:watch
```

---

## 🗺️ Roadmap

此 LAB fork 的規劃方向（工作中 roadmap）：

- 以更嚴格的寄件者／規則分類提升 automail 可靠性。
- 改善 orchestral 階段的可組合性與產物可追溯性。
- 強化行動優先操作與遠端 gateway 管理 UX。
- 深化與 LAB 生態儲存庫的整合，形成端到端自動化產出。
- 持續強化無人值守自動化的安全預設與可觀測性。

---

## 🤝 Contributing

此儲存庫追蹤個人 LAB 優先事項，同時繼承 OpenClaw 的核心架構。

- 閱讀 [`CONTRIBUTING.md`](CONTRIBUTING.md)
- 參閱上游文件：https://docs.openclaw.ai
- 若為安全問題，請見 [`SECURITY.md`](SECURITY.md)

若不確定 LAB 專屬行為，請保留既有行為，並在 PR 備註中記錄你的假設。

---

## ❤️ Support / Sponsor

若 LAB 對你的工作流有幫助，歡迎支持持續開發：

- GitHub Sponsors: https://github.com/sponsors/lachlanchen
- Donate page: https://chat.lazying.art/donate
- Website: https://lazying.art

---

## 🙏 Acknowledgements

LazyingArtBot 基於 **OpenClaw**：

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

感謝 OpenClaw 維護者與社群提供核心平台。

---

## 📄 License

MIT（適用處與上游相同）。詳見 `LICENSE`。
