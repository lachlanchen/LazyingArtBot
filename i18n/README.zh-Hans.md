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

**LazyingArtBot** 是我为 **lazying.art** 打造的个人 AI 助手体系：

**LazyingArtBot** 基于 OpenClaw 构建，并针对我的日常工作流做了定制：多渠道聊天、local-first 控制，以及 email → 日历/提醒/笔记自动化。

| 🔗 链接     | URL                                          | 关注点            |
| ----------- | -------------------------------------------- | ----------------- |
| 🌐 网站     | https://lazying.art                          | 主域名与状态看板  |
| 🤖 Bot 域名 | https://lab.lazying.art                      | 聊天与助手入口    |
| 🧱 上游基座 | https://github.com/openclaw/openclaw         | OpenClaw 平台基础 |
| 📦 本仓库   | https://github.com/lachlanchen/LazyingArtBot | LAB 专属适配      |

---

## Table of contents

- [概览](#overview)
- [速览](#at-a-glance)
- [功能特性](#features)
- [核心能力](#core-capabilities)
- [项目结构](#project-structure)
- [先决条件](#prerequisites)
- [快速开始](#quick-start)
- [安装](#installation)
- [使用方式](#usage)
- [配置](#configuration)
- [部署模式](#deployment-modes)
- [LazyingArt 工作流聚焦](#lazyingart-workflow-focus)
- [编排理念](#orchestral-philosophy)
- [LAB 中的提示词工具](#prompt-tools-in-lab)
- [示例](#examples)
- [开发说明](#development-notes)
- [故障排查](#troubleshooting)
- [LAB 生态系统集成](#lab-ecosystem-integrations)
- [源码安装（快速参考）](#install-from-source-quick-reference)
- [路线图](#roadmap)
- [贡献方式](#contributing)
- [鸣谢](#acknowledgements)
- [❤️ Support](#-support)
- [Contact](#contact)
- [License](#license)

---

## Overview

LAB 主要关注的是务实的个人生产力：

- ✅ 在你已经在用的聊天渠道中运行一个统一助手。
- 🔐 将数据和控制权保留在你的机器/服务器上。
- 📬 将入站邮件转换为结构化动作（Calendar、Reminders、Notes）。
- 🛡️ 在保持自动化有用性的同时加入安全护栏。

一句话总结：减少杂务，更高效执行。

---

## At a glance

| 模块              | 本仓库当前基线                             |
| ----------------- | ------------------------------------------ |
| 运行时            | Node.js `>=22.12.0`                        |
| 包管理器          | `pnpm@10.23.0`                             |
| 核心 CLI          | `openclaw`                                 |
| 默认本地网关      | `127.0.0.1:18789`                          |
| 默认桥接端口      | `127.0.0.1:18790`                          |
| 主要文档          | `docs/`（Mintlify）                        |
| 主要 LAB 编排     | `orchestral/` + `orchestral/prompt_tools/` |
| README 多语言位置 | `i18n/README.*.md`                         |

---

## Features

- 🌐 带本地网关的多渠道助手运行时。
- 🖥️ 用于本地操作的浏览器仪表盘/聊天界面。
- 🧰 基于工具的自动化流水线（scripts + prompt-tools）。
- 📨 邮件分流并转换成 Notes、Reminders 与 Calendar 的可执行动作。
- 🧩 插件/扩展生态（`extensions/*`）覆盖渠道、提供商和集成。
- 📱 仓库内多平台界面（`apps/macos`、`apps/ios`、`apps/android`、`ui`）。

---

## Core capabilities

| 能力              | 实际含义                                                                              |
| ----------------- | ------------------------------------------------------------------------------------- |
| 多渠道助手运行时  | 在你启用的渠道上，通过网关与智能体会话协同运行                                        |
| Web 仪表盘 / 聊天 | 用于本地运维的浏览器控制界面                                                          |
| 工具驱动工作流    | Shell + 文件 + 自动化脚本执行链                                                       |
| 邮件自动化流水线  | 解析邮件、分类动作类型、路由到 Notes/Reminders/Calendar，并记录每次动作以便复核和调试 |

当前仓库中的流水线步骤：

- 解析入站邮件
- 分类动作类型
- 保存到 Notes / Reminders / Calendar
- 记录每次动作以便复核和调试

---

## Project structure

高层仓库结构：

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

补充说明：

- `orchestral/prompt_tools` 指向 orchestral 的 prompt-tool 实现。
- 根目录下 `i18n/` 存放本地化 README 变体。
- `.github/workflows.disabled/` 在当前快照中仍存在；若依赖 CI 行为，请在使用前确认当前仓库中的实际运行状态。

---

## Prerequisites

本仓库的运行与工具基线：

- Node.js `>=22.12.0`
- pnpm `10.23.0`（见 `package.json` 中的 `packageManager`）
- 至少配置一个模型提供方 Key（`OPENAI_API_KEY`、`ANTHROPIC_API_KEY`、`GEMINI_API_KEY` 等）
- 可选：用于容器化网关/CLI 的 Docker + Docker Compose
- 移动端/macOS 构建所需：按目标平台准备 Apple/Android 工具链

可选的全局 CLI 安装（与快速开始一致）：

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## Quick start

本仓库运行时基线：**Node >= 22.12.0**（见 `package.json` 的引擎）。

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

然后打开本地仪表盘与聊天界面：

- http://127.0.0.1:18789

如需远程访问，请通过你自己的安全隧道（例如 ngrok/Tailscale）暴露本地网关，并始终开启鉴权。

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

仓库内包含 `docker-compose.yml`，包括：

- `openclaw-gateway`
- `openclaw-cli`

典型流程：

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

Compose 中常见变量：

- `OPENCLAW_CONFIG_DIR`
- `OPENCLAW_WORKSPACE_DIR`
- `OPENCLAW_GATEWAY_PORT`
- `OPENCLAW_BRIDGE_PORT`

---

## Usage

常用命令：

```bash
# 注册并安装用户守护进程
openclaw onboard --install-daemon

# 以前台方式运行网关
openclaw gateway run --bind loopback --port 18789 --verbose

# 通过已配置渠道发送直达消息
openclaw message send --to +1234567890 --message "Hello from LAB"

# 直接向智能体提问
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

补充常用运维命令：

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

配置参考分散在 `.env` 与 `~/.openclaw/openclaw.json` 中。

1. 先从 `.env.example` 开始。
2. 配置网关鉴权（推荐 `OPENCLAW_GATEWAY_TOKEN`）。
3. 至少设置一个模型提供方 Key（`OPENAI_API_KEY`、`ANTHROPIC_API_KEY` 等）。
4. 只为已启用的渠道设置对应凭据。

保留自仓库的 `.env.example` 说明：

- 环境变量优先级：process env -> `./.env` -> `~/.openclaw/.env` -> 配置文件 `env` 区块。
- 已存在且非空的进程环境变量不会被覆盖。
- 像 `gateway.auth.token` 这类配置键可优先于环境变量 fallback。

面向公网前的安全基线：

- 保持网关鉴权与配对开启。
- 对入站渠道使用严格 allowlist。
- 将每条入站消息和邮件都视为不可信输入。
- 采用最小权限原则运行，并定期审阅日志。

如果将网关暴露到互联网，请要求 token/password 鉴权并配置可信代理。

---

## Deployment modes

| 模式            | 适用场景               | 典型命令                                                      |
| --------------- | ---------------------- | ------------------------------------------------------------- |
| 本地前台运行    | 开发与调试             | `openclaw gateway run --bind loopback --port 18789 --verbose` |
| 本地守护进程    | 日常个人使用           | `openclaw onboard --install-daemon`                           |
| Docker          | 隔离式运行与可复现部署 | `docker compose up -d`                                        |
| 远程主机 + 隧道 | 从外部网络访问         | 运行网关 + 安全隧道，并始终开启鉴权                           |

默认假设：生产级反向代理加固、密钥轮换与备份策略应按各环境自行定义。

---

## LazyingArt workflow focus

该分支围绕 **lazying.art** 的个人流程进行优化：

- 🎨 自定义品牌（LAB / 熊猫主题）
- 📱 移动端友好的仪表盘与聊天体验
- 📨 Automail 流程变体（规则触发、codex 辅助保存模式）
- 🧹 个人清理与发件人分类脚本
- 🗂️ 为真实日常使用调优 notes/reminders/calendar 路由

本地自动化工作区：

- `~/.openclaw/workspace/automation/`
- 仓库内脚本说明：`references/lab-scripts-and-philosophy.md`
- 专属 Codex prompt tools：`orchestral/prompt_tools/`

---

## Orchestral philosophy

LAB 编排遵循一条核心规则：
把复杂目标拆解为“确定性执行 + 聚焦 prompt-tool 链”。

- 确定性脚本负责可靠的底层能力：
  调度、文件路由、运行目录、重试与输出交接。
- Prompt tools 负责自适应智能：
  计划、分类、上下文整合，以及不确定条件下的决策。
- 每一阶段都会产出可复用产物，使下游工具可在此基础上合成更强的 notes/email，而无需从零开始。

核心 orchestral 链路：

- 企业创业链：
  company context ingestion -> market/funding/academic/legal intelligence -> 具体增长行动。
- 自动邮件链：
  inbound mail triage -> 对低价值邮件采用保守跳过策略 -> 结构化 Notes/Reminders/Calendar 动作。
- Web 搜索链：
  results-page capture -> 有目标的深度读取与截图/内容提取 -> 基于证据的综合结论。

---

## Prompt tools in LAB

Prompt tools 在 LAB 中采用模块化、可组合、以编排优先的方式设计。
它们可单独运行，也可作为更大工作流中的串联阶段。

- 读写操作：
  为 AutoLife 流程创建并更新 Notes、Reminders 与 Calendar 输出。
- 截图/读取操作：
  抓取搜索页和目标页，然后提取结构化文本供下游分析。
- 工具连接操作：
  调用确定性脚本、在阶段间传递产物，并保持上下文连续性。

主要位置：

- `orchestral/prompt_tools/`

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
- UI 包命令由根脚本代理（`pnpm ui:build`、`pnpm ui:dev`）。

仓库中的常见扩展测试命令：

```bash
pnpm test:e2e
pnpm test:live
pnpm test:docker:all
pnpm test:ui
```

额外开发辅助：

```bash
pnpm docs:dev
pnpm format:check
pnpm lint
pnpm tsgo:test
```

补充说明：

- 移动端/macOS 的构建与运行命令已在 `package.json` 中通过 `ios:*`、`android:*`、`mac:*` 提供，但平台签名与签发要求具有环境依赖，README 中未在此全部展开。

---

## Troubleshooting

### Gateway 无法访问 `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

请检查端口占用和守护进程冲突。若通过 Docker 运行，请确认主机端口映射与服务健康状态。

### 鉴权或渠道配置问题

- 按 `.env.example` 复核 `.env` 配置。
- 确保至少配置了一个模型 Key。
- 只为实际启用的渠道配置 token。

### 构建或安装问题

- 使用 Node `>=22.12.0` 重新运行 `pnpm install`。
- 重新执行 `pnpm ui:build && pnpm build`。
- 若缺少可选原生 peer 依赖，请查阅安装日志中的 `@napi-rs/canvas` / `node-llama-cpp` 兼容性提示。

### 通用健康检查

使用 `openclaw doctor` 检测 migration/security/config 漂移问题。

### 常用诊断命令

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --deep
```

---

## LAB ecosystem integrations

LAB 将我更广泛的 AI 产品和研究仓库整合为一套统一运行层，支持创作、增长与自动化。

Profile:

- https://github.com/lachlanchen?tab=repositories

已集成仓库：

- `VoidAbyss`（隙遊之淵）
- `AutoNovelWriter`（自动小说写作）
- `AutoAppDev`（自动应用开发）
- `OrganoidAgent`（使用基座视觉模型与 LLM 的类器官研究平台）
- `LazyEdit`（AI 辅助视频编辑：字幕、转录、精彩片段、元数据、字幕）
- `AutoPublish`（自动发布流水线）

实际集成目标：

- 自动写小说
- 自动开发应用
- 自动剪辑视频
- 自动发布产出
- 自动分析类器官
- 自动化邮件处理

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

该 LAB 分支的开发路线（进行中）：

- 通过更严格的发件人/规则分类提升 automail 的稳定性。
- 改善 orchestral 阶段可组合性与产物可追溯性。
- 强化移动优先操作体验与远程网关管理体验。
- 深化与 LAB 生态仓库的端到端自动化生产集成。
- 持续加固无人值守自动化所需的安全默认值与可观测性。

---

## Contributing

该仓库在继承 OpenClaw 核心架构的同时，保留了个人 LAB 的优先级导向。

- 查看 [`CONTRIBUTING.md`](../CONTRIBUTING.md)
- 参考上游文档：https://docs.openclaw.ai
- 安全问题请见 [`SECURITY.md`](../SECURITY.md)

若对 LAB 特有行为存在疑问，请保留既有行为并在 PR 说明中写明相关假设。

---

## Acknowledgements

LazyingArtBot 基于 **OpenClaw**：

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

感谢 OpenClaw 的维护者与社区。

## ❤️ Support

| Donate                                                                                                                                                                                                                                                                                                                                                     | PayPal                                                                                                                                                                                                                                                                                                                                                          | Stripe                                                                                                                                                                                                                                                                                                                                                              |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [![Donate](https://camo.githubusercontent.com/24a4914f0b42c6f435f9e101621f1e52535b02c225764b2f6cc99416926004b7/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f446f6e6174652d4c617a79696e674172742d3045413545393f7374796c653d666f722d7468652d6261646765266c6f676f3d6b6f2d6669266c6f676f436f6c6f723d7768697465)](https://chat.lazying.art/donate) | [![PayPal](https://camo.githubusercontent.com/d0f57e8b016517a4b06961b24d0ca87d62fdba16e18bbdb6aba28e978dc0ea21/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f50617950616c2d526f6e677a686f754368656e2d3030343537433f7374796c653d666f722d7468652d6261646765266c6f676f3d70617970616c266c6f676f436f6c6f723d7768697465)](https://paypal.me/RongzhouChen) | [![Stripe](https://camo.githubusercontent.com/1152dfe04b6943afe3a8d2953676749603fb9f95e24088c92c97a01a897b4942/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f5374726970652d446f6e6174652d3633354246463f7374796c653d666f722d7468652d6261646765266c6f676f3d737472697065266c6f676f436f6c6f723d7768697465)](https://buy.stripe.com/aFadR8gIaflgfQV6T4fw400) |

## Contact

- Website: https://lazying.art
- Repository: https://github.com/lachlanchen/LazyingArtBot
- Issue tracker: https://github.com/lachlanchen/LazyingArtBot/issues
- Security or safety concerns: https://github.com/lachlanchen/LazyingArtBot/blob/main/SECURITY.md

---

## License

MIT（与上游一致，在适用范围内）。见 `LICENSE`。
