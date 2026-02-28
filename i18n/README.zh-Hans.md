[English](../README.md) · [العربية](README.ar.md) · [Español](README.es.md) · [Français](README.fr.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Tiếng Việt](README.vi.md) · [中文 (简体)](README.zh-Hans.md) · [中文（繁體）](README.zh-Hant.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)


<p align="center">
  <img src="https://github.com/lachlanchen/lachlanchen/raw/main/figs/banner.png" alt="LazyingArtBot banner" />
</p>

# 🐼 LazyingArtBot (LAB)

[![License: MIT](https://img.shields.io/badge/License-MIT-1f6feb.svg)](LICENSE)
[![Node >= 22.12.0](https://img.shields.io/badge/Node-%3E%3D22.12.0-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![pnpm workspace](https://img.shields.io/badge/pnpm-workspace-F69220?logo=pnpm&logoColor=white)](pnpm-workspace.yaml)
[![Upstream: openclaw/openclaw](https://img.shields.io/badge/upstream-openclaw%2Fopenclaw-111827?logo=github)](https://github.com/openclaw/openclaw)
[![Gateway Default Port](https://img.shields.io/badge/Gateway-18789-0ea5e9)](#-快速开始)
[![Version](https://img.shields.io/badge/version-2026.2.10-16a34a)](package.json)

**LazyingArtBot** 是我为 **lazying.art** 打造的个人 AI 助手技术栈。  
它基于 OpenClaw 构建，并按我的日常工作流做了适配：多渠道聊天、本地优先控制，以及邮件 → 日历/提醒/笔记自动化。

| 链接 | URL |
| --- | --- |
| Website | https://lazying.art |
| Bot domain | https://lazying.art |
| Upstream base | https://github.com/openclaw/openclaw |
| This repo | https://github.com/lachlanchen/LazyingArtBot |

---

## 目录

- [🧭 概览](#-概览)
- [⚡ 快速一览](#-快速一览)
- [⚙️ 核心能力](#️-核心能力)
- [🧱 项目结构](#-项目结构)
- [📋 前置条件](#-前置条件)
- [🚀 快速开始](#-快速开始)
- [🧱 安装](#-安装)
- [🛠️ 使用方式](#️-使用方式)
- [🔐 配置](#-配置)
- [🧩 LazyingArt 工作流重点](#-lazyingart-工作流重点)
- [🎼 Orchestral 设计理念](#-orchestral-设计理念)
- [🧰 LAB 中的 Prompt Tools](#-lab-中的-prompt-tools)
- [💡 示例](#-示例)
- [🧪 开发说明](#-开发说明)
- [🩺 故障排查](#-故障排查)
- [🌐 LAB 生态集成](#-lab-生态集成)
- [从源码安装](#从源码安装)
- [🗺️ 路线图](#️-路线图)
- [🤝 贡献](#-贡献)
- [❤️ 支持 / 赞助](#️-支持--赞助)
- [🙏 致谢](#-致谢)
- [📄 许可证](#-许可证)

---

## 🧭 概览

LAB 聚焦于实用的个人生产力：

- 在你已经使用的聊天渠道中运行同一个助手。
- 将数据与控制权保留在你自己的机器/服务器上。
- 将收件邮件转换为结构化动作（日历、提醒、笔记）。
- 加入护栏机制，让自动化既有用又安全。

一句话：减少杂务，更好执行。

---

## ⚡ 快速一览

| 领域 | 本仓库当前基线 |
| --- | --- |
| Runtime | Node.js `>=22.12.0` |
| Package manager | `pnpm@10.23.0` |
| Core CLI | `openclaw` |
| Default local gateway | `127.0.0.1:18789` |
| Primary docs | `docs/` (Mintlify) |
| Primary LAB orchestration | `orchestral/` + `scripts/prompt_tools/` |

---

## ⚙️ 核心能力

- 多渠道助手运行时（Gateway + agent sessions）。
- Web dashboard / web chat 控制界面。
- 支持工具调用的 agent 工作流（shell、文件、自动化脚本）。
- 面向个人运营的邮件自动化流水线：
  - 解析入站邮件
  - 分类动作类型
  - 保存到 Notes / Reminders / Calendar
  - 记录每一步操作，便于复盘与调试

---

## 🧱 项目结构

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
├─ .env.example         # environment template
├─ docker-compose.yml   # gateway + CLI containers
├─ README_OPENCLAW.md   # larger upstream-style reference README
└─ README.md            # this LAB-focused README
```

说明：

- `scripts/prompt_tools` 指向 orchestral prompt-tool 实现。
- 根目录 `i18n/` 已存在；当前本地快照中可见多语言 README。若与英文主 README 的说明存在时间差，以仓库当前文件为准。

---

## 📋 前置条件

来自本仓库的运行时与工具基线：

- Node.js `>=22.12.0`
- pnpm `10.23.0` 基线（见 `packageManager` in `package.json`）
- 已配置的模型提供商密钥（`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY` 等）
- 可选：Docker + Docker Compose（用于容器化 gateway/CLI）

可选的全局 CLI 安装（与快速开始流程一致）：

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## 🚀 快速开始

本仓库运行时基线：**Node >= 22.12.0**（`package.json` engine）。

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

然后打开本地 dashboard 并开始聊天：

- http://127.0.0.1:18789

如果要远程访问，请通过你自己的安全隧道暴露本地 gateway（例如 ngrok/Tailscale），并保持认证开启。

---

## 🧱 安装

### 从源码安装

```bash
git clone https://github.com/lachlanchen/LazyingArtBot.git
cd LazyingArtBot
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw onboard --install-daemon
```

### 可选 Docker 工作流

仓库内包含 `docker-compose.yml`，内含：

- `openclaw-gateway`
- `openclaw-cli`

典型流程：

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

说明：挂载路径和端口由 compose 变量控制，例如 `OPENCLAW_CONFIG_DIR`、`OPENCLAW_WORKSPACE_DIR`、`OPENCLAW_GATEWAY_PORT`、`OPENCLAW_BRIDGE_PORT`。

---

## 🛠️ 使用方式

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

开发循环（watch 模式）：

```bash
pnpm gateway:watch
```

UI 开发：

```bash
pnpm ui:dev
```

---

## 🔐 配置

环境与配置参考拆分在 `.env` 与 `~/.openclaw/openclaw.json`。

1. 从 `.env.example` 开始。
2. 设置 gateway 认证（推荐 `OPENCLAW_GATEWAY_TOKEN`）。
3. 至少设置一个模型提供商密钥（`OPENAI_API_KEY`, `ANTHROPIC_API_KEY` 等）。
4. 仅为你启用的渠道设置对应凭据。

仓库中保留的关键 `.env.example` 说明：

- 环境变量优先级：process env → `./.env` → `~/.openclaw/.env` → config `env` block。
- 已存在且非空的 process env 值不会被覆盖。
- `gateway.auth.token` 等 config 键可能优先于 env fallback。

对外网暴露前的安全基线：

- 保持 gateway auth/pairing 启用。
- 对入站渠道维持严格 allowlist。
- 将每条入站消息/邮件视为不可信输入。
- 以最小权限运行，并定期审查日志。

如果将 gateway 暴露到互联网，请强制使用 token/password 认证和可信代理配置。

---

## 🧩 LazyingArt 工作流重点

这个 fork 优先服务我在 **lazying.art** 的个人流程：

- 自定义品牌（LAB / 熊猫主题）
- 移动端友好的 dashboard/chat 体验
- automail 流水线变体（规则触发、codex 辅助保存模式）
- 个人清理与发件人分类脚本
- 针对真实日常使用调优的 notes/reminders/calendar 路由

本地自动化工作区：

- `~/.openclaw/workspace/automation/`
- 仓库中的脚本参考：`references/lab-scripts-and-philosophy.md`
- 专用 Codex prompt tools：`scripts/prompt_tools/`

---

## 🎼 Orchestral 设计理念

LAB orchestration 遵循一条设计规则：  
把复杂目标拆成“确定性执行 + 聚焦的 prompt-tool 链”。

- 确定性脚本负责可靠的基础设施：
  调度、文件路由、运行目录、重试与结果交接。
- Prompt tools 负责自适应智能：
  规划、分流、上下文综合，以及不确定条件下的决策。
- 每个阶段都输出可复用产物，让下游工具无需从零开始即可组合出更强的最终笔记/邮件。

核心 orchestral 链：

- 公司创业链：
  公司上下文摄取 → 市场/融资/学术/法务情报 → 可执行增长动作。
- 自动邮件链：
  入站邮件分流 → 对低价值邮件保守跳过策略 → 结构化 Notes/Reminders/Calendar 动作。
- Web 搜索链：
  结果页抓取 → 对目标页面做截图/内容提取的深入读取 → 基于证据的综合分析。

---

## 🧰 LAB 中的 Prompt Tools

Prompt tools 具备模块化、可组合、以 orchestration 为先的特性。  
它们既可独立运行，也可作为大型工作流中的串联阶段。

- 读写类操作：
  为 AutoLife 流程创建并更新 Notes、Reminders、Calendar 输出。
- 截图/读取类操作：
  抓取搜索页和链接页，并提取结构化文本供下游分析。
- 工具连接类操作：
  调用确定性脚本、在阶段间交换产物、维持上下文连续性。

主要位置：

- `scripts/prompt_tools/`

---

## 💡 示例

### 示例：仅本地 gateway

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

### 示例：让 agent 处理每日规划

```bash
openclaw agent --message "Review today inbox and build a prioritized task plan" --thinking high
```

### 示例：源码构建 + watch 循环

```bash
pnpm install
pnpm ui:build
pnpm build
pnpm gateway:watch
```

---

## 🧪 开发说明

- 运行时基线：Node `>=22.12.0`。
- 包管理器基线：`pnpm@10.23.0`（`packageManager` 字段）。
- 常用质量门禁：

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- 开发态 CLI：`pnpm openclaw ...`
- TS 运行循环：`pnpm dev`
- UI 包命令通过根脚本代理（`pnpm ui:build`, `pnpm ui:dev`）。

---

## 🩺 故障排查

### Gateway 在 `127.0.0.1:18789` 不可达

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

检查端口冲突与 daemon 冲突。如果使用 Docker，请确认主机映射端口与服务健康状态。

### Auth 或渠道配置问题

- 重新对照 `.env.example` 检查 `.env` 值。
- 确保至少配置了一个模型密钥。
- 仅为实际启用的渠道配置对应 token。

### 通用健康检查

使用 `openclaw doctor` 检测迁移/安全/配置漂移问题。

---

## 🌐 LAB 生态集成

LAB 将我更广泛的 AI 产品与研究仓库整合为一个操作层，服务于创作、增长与自动化。

Profile:

- https://github.com/lachlanchen?tab=repositories

已集成仓库：

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (automatic novel writing)
- `AutoAppDev` (automatic app development)
- `OrganoidAgent` (organoid research platform with foundation vision models + LLMs)
- `LazyEdit` (AI-assisted video editing: captions/transcription/highlights/metadata/subtitles)
- `AutoPublish` (automatic publication pipeline)

LAB 的实际集成目标：

- 自动写小说
- 自动开发应用
- 自动剪辑视频
- 自动发布成果
- 自动分析类器官
- 自动处理邮件流程

---

## 从源码安装

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

## 🗺️ 路线图

本 LAB fork 的规划方向（工作路线图）：

- 通过更严格的发件人/规则分类，扩展 automail 可靠性。
- 提升 orchestral 各阶段可组合性与产物可追踪性。
- 强化移动优先操作与远程 gateway 管理体验。
- 深化与 LAB 生态仓库的端到端自动化生产集成。
- 持续加固无人值守自动化所需的安全默认项与可观测性。

---

## 🤝 贡献

本仓库跟踪个人 LAB 优先级，同时继承 OpenClaw 的核心架构。

- 阅读 [`CONTRIBUTING.md`](CONTRIBUTING.md)
- 查阅上游文档：https://docs.openclaw.ai
- 安全问题请见 [`SECURITY.md`](SECURITY.md)

如果你不确定某个 LAB 特定行为，请保留现有行为，并在 PR 说明中写明假设。

---

## ❤️ 支持 / 赞助

如果 LAB 对你的工作流有帮助，欢迎支持持续开发：

- GitHub Sponsors: https://github.com/sponsors/lachlanchen
- Donate page: https://chat.lazying.art/donate
- Website: https://lazying.art

---

## 🙏 致谢

LazyingArtBot 基于 **OpenClaw**：

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

感谢 OpenClaw 维护者与社区提供核心平台。

---

## 📄 许可证

MIT（适用部分与上游一致）。详见 `LICENSE`。
