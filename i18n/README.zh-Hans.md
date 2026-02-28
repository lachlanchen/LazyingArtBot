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


**LazyingArtBot** 是我为 **lazying.art** 打造的个人 AI 助手体系。它基于 OpenClaw，并针对我日常工作流做了适配：多渠道聊天、本地优先控制，以及 email → 日历/提醒/笔记自动化。

| 🔗 链接 | URL |
| --- | --- |
| 🌐 网站 | https://lazying.art |
| 🤖 Bot 域名 | https://lazying.art |
| 🧱 上游基座 | https://github.com/openclaw/openclaw |
| 📦 本仓库 | https://github.com/lachlanchen/LazyingArtBot |

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

LAB 更关注实用性的个人生产力：

- ✅ 在你已经在用的聊天渠道上运行统一的助手。
- 🔐 将数据与控制权保留在你自己的机器或服务器上。
- 📬 将入站邮件转换为结构化动作（Calendar、Reminders、Notes）。
- 🛡️ 加入护栏，让自动化既有用又安全。

简而言之：减少杂务，让执行更顺畅。

---

## At a glance

| 区域 | 本仓库当前基线 |
| --- | --- |
| 运行时 | Node.js `>=22.12.0` |
| 包管理器 | `pnpm@10.23.0` |
| 核心 CLI | `openclaw` |
| 默认本地网关 | `127.0.0.1:18789` |
| 默认桥接端口 | `127.0.0.1:18790` |
| 主要文档 | `docs/`（Mintlify） |
| 主要 LAB 编排 | `orchestral/` + `scripts/prompt_tools/` |
| README 多语言位置 | `i18n/README.*.md` |

---

## Features

- 🌐 带本地网关的多渠道助手运行时。
- 🖥️ 面向本地操作的浏览器仪表盘/聊天界面。
- 🧰 支持工具调用的自动化流水线（scripts + prompt-tools）。
- 📨 邮件分流并转换为 Notes、Reminders 与 Calendar 的动作。
- 🧩 插件/扩展生态（`extensions/*`）支持渠道、提供方和集成。
- 📱 仓库内多平台界面 (`apps/macos`, `apps/ios`, `apps/android`, `ui`)。

---

## Core capabilities

| 能力 | 实际含义 |
| --- | --- |
| 多渠道助手运行时 | 在你启用的渠道上跨 gateway + agent 会话运行 |
| Web 仪表盘 / 聊天 | 用于本地运行的浏览器控制界面 |
| 工具化工作流 | shell + 文件 + 自动化脚本执行链 |
| 邮件自动化流水线 | 解析邮件、分类动作类型、路由到 Notes/Reminders/Calendar，并记录所有动作以供回溯与调试 |

当前工作流保留的流程：

- parse inbound mail
- classify action type
- save to Notes / Reminders / Calendar
- log every action for review and debugging

---

## Project structure

仓库高层结构如下：

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

说明：

- `scripts/prompt_tools` 指向 orchestral prompt tool 的实现。
- 根目录 `i18n/` 存放本地化 README。
- `.github/workflows.disabled/` 在当前快照中存在；若依赖 CI 行为，请按实际仓库状态核实。

---

## Prerequisites

本仓库的运行与工具基线：

- Node.js `>=22.12.0`
- pnpm `10.23.0` 基线（见 `package.json` 中的 `packageManager`）
- 已配置的模型提供方密钥（`OPENAI_API_KEY`、`ANTHROPIC_API_KEY`、`GEMINI_API_KEY` 等）
- 可选：用于容器化网关/CLI 的 Docker + Docker Compose
- 移动端或 macOS 构建所需：按目标平台准备 Apple/Android 工具链

可选的全局 CLI 安装（与快速开始流程一致）：

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## Quick start

本仓库运行时基线：**Node >= 22.12.0**（`package.json` engine）。

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

然后打开本地仪表盘和聊天：

- http://127.0.0.1:18789

远程访问时，请通过你自己的安全隧道（如 ngrok/Tailscale）暴露本地网关，并保持认证开启。

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

仓库自带 `docker-compose.yml`，包含：

- `openclaw-gateway`
- `openclaw-cli`

典型流程：

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

Compose 常见变量：

- `OPENCLAW_CONFIG_DIR`
- `OPENCLAW_WORKSPACE_DIR`
- `OPENCLAW_GATEWAY_PORT`
- `OPENCLAW_BRIDGE_PORT`

---

## Usage

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

开发循环（watch mode）：

```bash
pnpm gateway:watch
```

UI 开发：

```bash
pnpm ui:dev
```

常用运维命令：

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

环境与配置参考拆分在 `.env` 和 `~/.openclaw/openclaw.json`。

1. 从 `.env.example` 开始。
2. 设置网关鉴权（推荐 `OPENCLAW_GATEWAY_TOKEN`）。
3. 至少设置一个模型提供方密钥（`OPENAI_API_KEY`、`ANTHROPIC_API_KEY` 等）。
4. 仅配置你已启用渠道的凭证。

从仓库中保留的 `.env.example` 说明：

- 环境变量优先级：进程环境 -> `./.env` -> `~/.openclaw/.env` -> config `env` 区块。
- 非空的进程环境变量不会被覆盖。
- 类似 `gateway.auth.token` 的配置键可以优先于 env fallback。

对外网暴露前的安全基线：

- 保持网关鉴权与配对开启。
- 对入站渠道保持严格 allowlist。
- 将每条入站消息/邮件视作不可信输入。
- 采用最小权限运行，并定期检查日志。

如果你将网关暴露到互联网，请强制要求 token/password 鉴权和可信代理配置。

---

## Deployment modes

| 模式 | 适用场景 | 常见命令 |
| --- | --- | --- |
| 本地前台运行 | 开发与调试 | `openclaw gateway run --bind loopback --port 18789 --verbose` |
| 本地守护进程 | 日常个人使用 | `openclaw onboard --install-daemon` |
| Docker | 隔离式运行与可复现部署 | `docker compose up -d` |
| 远程主机 + 隧道 | 在外网访问家中局域网 |
|  | 运行网关并搭配安全隧道，始终开启鉴权 |

生产级别上，反向代理加固、密钥轮换与备份策略应按各环境单独定义。

---

## LazyingArt workflow focus

该分支在 **lazying.art** 优先满足我的个人流程：

- 🎨 自定义品牌（LAB / 熊猫主题）
- 📱 移动端友好的仪表盘/聊天体验
- 📨 automail 流程变体（规则触发、codex 辅助保存模式）
- 🧹 个人清理和发件人分类脚本
- 🗂️ 按真实日常使用优化 notes/reminders/calendar 路由

本地自动化工作区：

- `~/.openclaw/workspace/automation/`
- 仓库中的脚本说明：`references/lab-scripts-and-philosophy.md`
- 专用 Codex prompt tools：`scripts/prompt_tools/`

---

## Orchestral philosophy

LAB orchestration 遵循一条设计准则：
将复杂目标拆成“确定性执行 + 聚焦 prompt-tool 链”。

- 确定性脚本负责可靠的底层处理：
  调度、文件路由、运行目录、重试与输出交接。
- Prompt tools 负责自适应智能：
  计划、分流、上下文整合，以及在不确定条件下做决策。
- 每个阶段都会输出可复用的产物，下游工具可直接组合生成更强的最终 notes/email，而不是从零开始。

核心 orchestral 链路：

- 企业创业链：
  company context ingestion -> market/funding/academic/legal intelligence -> 具体增长行动。
- 自动邮件链：
  inbound mail triage -> 低价值邮件保守跳过策略 -> 结构化 Notes/Reminders/Calendar 动作。
- Web 搜索链：
  results-page capture -> 目标页深度读取与截图/内容提取 -> 基于证据的综合结论。

---

## Prompt tools in LAB

Prompt tools 以模块化、可组合、以 orchestration 为先进行设计。
它们可以独立运行，也能作为更大工作流的串联阶段。

- 读写操作：
  为 AutoLife 流程创建并更新 Notes、Reminders 和 Calendar 输出。
- 截图/读取操作：
  抓取搜索页与链接页，再提取结构化文本供下游分析。
- 工具连接操作：
  调用确定性脚本、在阶段间交换产物，并保持上下文连续性。

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

- 运行时基线：Node `>=22.12.0`。
- 包管理器基线：`pnpm@10.23.0`（`packageManager` 字段）。
- 常见质量门禁：

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- 开发态 CLI：`pnpm openclaw ...`
- TS 运行循环：`pnpm dev`
- UI 包命令通过根脚本代理（`pnpm ui:build`、`pnpm ui:dev`）。

仓库里常见的扩展测试命令：

```bash
pnpm test:e2e
pnpm test:live
pnpm test:docker:all
pnpm test:ui
```

补充开发辅助命令：

```bash
pnpm docs:dev
pnpm format:check
pnpm lint
pnpm tsgo:test
```

假设说明：

- `ios:*`、`android:*`、`mac:*` 命令存在于 `package.json`，用于移动端/macOS 构建与运行，但签名/签发要求与环境相关，README 中未完整覆盖。

---

## Troubleshooting

### Gateway not reachable on `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

检查端口冲突和守护进程冲突。若使用 Docker，请确认主机端口映射与服务健康状态。

### Auth or channel config issues

- 按 `.env.example` 复核 `.env` 配置。
- 确保至少配置一个模型 key。
- 仅为你实际启用的频道配置 token。

### Build or install issues

- 重新运行 `pnpm install`，并确保 Node `>=22.12.0`。
- 使用 `pnpm ui:build && pnpm build` 重建。
- 若缺少可选原生依赖，请查阅安装日志中的 `@napi-rs/canvas` / `node-llama-cpp` 兼容性提示。

### General health checks

使用 `openclaw doctor` 检查 migration/security/config 漂移问题。

### Useful diagnostics

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --deep
```

---

## LAB ecosystem integrations

LAB 将我更广泛的 AI 产品和研究仓库整合到一个统一运行层，用于创作、增长和自动化。

Profile:

- https://github.com/lachlanchen?tab=repositories

已集成仓库：

- `VoidAbyss`（隙遊之淵）
- `AutoNovelWriter`（automatic novel writing）
- `AutoAppDev`（automatic app development）
- `OrganoidAgent`（organoid research platform with foundation vision models + LLMs）
- `LazyEdit`（AI-assisted video editing: captions/transcription/highlights/metadata/subtitles）
- `AutoPublish`（automatic publication pipeline）

实际集成目标：

- 自动写小说
- 自动开发应用
- 自动剪辑视频
- 自动发布产出
- 自动分析类器官
- 自动处理邮件流程

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

开发循环：

```bash
pnpm gateway:watch
```

---

## Roadmap

该 LAB 分支的规划方向（进行中）：

- 通过更严格的发件人/规则分类提升 automail 的稳定性。
- 提升 orchestral 阶段可组合性与产物可追溯性。
- 强化移动优先操作与远程 gateway 管理体验。
- 深化与 LAB 生态仓库的端到端自动化生产集成。
- 持续加固无人值守自动化所需的安全默认项与可观测性。

---

## Contributing

该仓库在继承 OpenClaw 核心架构的同时，聚焦个人 LAB 的优先需求。

- 阅读 [`CONTRIBUTING.md`](../CONTRIBUTING.md)
- 查阅上游文档：https://docs.openclaw.ai
- 安全问题请参见 [`SECURITY.md`](../SECURITY.md)

若不确定 LAB 特定行为，请保留既有行为并在 PR 说明中写明前提假设。

## ❤️ Support

| Donate | PayPal | Stripe |
|---|---|---|
| [![Donate](https://img.shields.io/badge/Donate-LazyingArt-0EA5E9?style=for-the-badge&logo=ko-fi&logoColor=white)](https://chat.lazying.art/donate) | [![PayPal](https://img.shields.io/badge/PayPal-RongzhouChen-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/RongzhouChen) | [![Stripe](https://img.shields.io/badge/Stripe-Donate-635BFF?style=for-the-badge&logo=stripe&logoColor=white)](https://buy.stripe.com/aFadR8gIaflgfQV6T4fw400) |

---

## Acknowledgements

LazyingArtBot 基于 **OpenClaw**：

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

感谢 OpenClaw 的维护者与社区。

---

## License

MIT（与上游一致，按适用范围）。见 `LICENSE`。
