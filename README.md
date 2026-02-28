<div align="center">

<picture>
  <img alt="Kairo" src="./assets/kairo-banner.svg" width="100%" height="auto">
</picture>

### Kairo：为知识工作者而生的主动 AI 秘书

[English](#) / 中文

<a href="./QUICKSTART.md">快速上手</a> · <a href="https://github.com/sou350121/Kairo-KenVersion">GitHub</a> · <a href="https://github.com/sou350121/Kairo-KenVersion/issues">问题反馈</a> · <a href="./docs/">文档</a>

[![][github-stars-shield]][github-stars-link]
[![][github-issues-shield]][github-issues-link]
[![][github-contributors-shield]][github-contributors-link]
[![][license-shield]][license-link]
[![][node-shield]][node-link]
[![][last-commit-shield]][last-commit-link]

👋 加入我们的社区讨论

💬 <a href="#">微信群</a> · 🎮 <a href="#">Discord</a> · 🐦 <a href="#">X (Twitter)</a>

</div>

---

## 项目概览

### 知识工作者面临的六大困境

在 AI 工具爆炸的今天，效率问题不是工具不够多，而是工具太被动、太碎散、太孤立：

- **输入碎片化**：想法在微信群，任务在 Notion，邮件在 Gmail，行程在飞书，联系人在通讯录。碎散在 5 个 App 里的信息，没有任何一个地方让你看清全局
- **工具只能被动等待**：所有工具都在等你去找它们。记事本不会在周五下午提醒你「这件事你还没做」，待办清单不会在早上告诉你「今天最重要的三件事是什么」
- **捕捉阻力导致遗忘**：好想法发生在地铁、咖啡馆、刚入睡前。打开 App → 找到页面 → 选格式 → 输入——这四步足以让你放弃
- **待办只有进，没有出**：你确实记了，但没有系统去跟进它、提醒它、在逾期时主动找你。任务静静躺在清单里，一条一条堆积
- **邮件与行程形同孤岛**：每天早上要切换 Gmail、飞书日历、微信群三个地方，才能拼出「今天要做什么」
- **数据主权丧失**：你花几年积累的笔记、任务、人脉，全部住在别人的服务器上。他们涨价、关服、或被收购，你的资产就不再属于你

### Kairo 的解法

Kairo 不是又一个笔记 App，也不是又一个 AI 助手。它是一套**主动运行在你服务器上的个人 AI 秘书系统**，通过你每天本来就在用的 IM（Telegram / 飞书）与你互动：

- **统一捕捉入口 → 解决碎片化**：你的 Telegram 或飞书就是唯一入口。自然语言输入，Kairo 自动识别 10 种意图并分类建卡
- **Heartbeat 主动推送 → 解决被动等待**：Kairo 定时扫描你的任务、邮件、行程，到时间主动找你，你不需要记得去查
- **零摩擦捕捉 → 解决遗忘问题**：说话即捕捉，1 秒输入，Kairo 自动建立正确类型的卡片，存入本地文件系统，永不丢失
- **完整任务闭环 → 解决待办堆积**：从捕捉到建卡，从排程到提醒，从跟进到标记完成——每一步由 Kairo 自动完成
- **邮件 + 日历自动接入 → 解决信息孤岛**：每日 07:00 自动读取飞书日历和 Gmail，汇整成一条晨报推送给你
- **本地 Markdown + 自托管 → 解决数据主权**：所有数据是 Markdown 文件，存在你自己的机器上，零订阅费，永不被锁定

---

## 快速上手

### 前置要求

在开始使用 Kairo 之前，请确保你的环境满足以下要求：

- **Node.js 版本**：22 或更高版本（`node -v` 确认）
- **包管理器**：pnpm 9 或更高版本（`npm install -g pnpm`）
- **操作系统**：Linux / macOS（Windows 需 WSL2）
- **网络连接**：需要稳定的网络连接（用于访问 AI 模型 API）
- **Telegram Bot**：在 [@BotFather](https://t.me/BotFather) 创建一个 Bot，保存 Token

### 1. 克隆并安装

```bash
git clone https://github.com/sou350121/Kairo-KenVersion.git
cd Kairo-KenVersion
pnpm install && pnpm ui:build && pnpm build
```

### 2. 模型准备

Kairo 支持多种 AI 模型服务，你只需要其中一种：

- **OpenAI 系列**：GPT-4o、GPT-4.1 等，API Key 从 [platform.openai.com](https://platform.openai.com) 获取
- **Anthropic Claude**：Claude Sonnet / Opus，API Key 从 [console.anthropic.com](https://console.anthropic.com) 获取
- **其他兼容 OpenAI 格式的服务**：任何支持 OpenAI API 格式的模型服务均可接入

👇 根据你选择的模型服务，展开查看对应的配置说明：

<details>
<summary><b>选项 1：使用 OpenAI 模型（推荐新手）</b></summary>

最简单的接入方式。在 [platform.openai.com/api-keys](https://platform.openai.com/api-keys) 创建 API Key，按量计费，无月费。

```bash
# 设置环境变量（加入 ~/.bashrc 或 ~/.zshrc 以持久化）
export OPENAI_API_KEY="sk-proj-YOUR_API_KEY"
```

在 `~/.openclaw/openclaw.json` 的 agents 段配置默认模型：

```jsonc
"agents": {
  "defaults": {
    "model": { "primary": "openai/gpt-4o-mini" }
  }
}
```

预估费用：日常使用约 $1–5 /月（gpt-4o-mini 更省钱）

</details>

<details>
<summary><b>选项 2：使用 Anthropic Claude</b></summary>

在 [console.anthropic.com](https://console.anthropic.com) 创建 API Key。Claude 在长文本理解和指令遵循上表现优秀。

```bash
export ANTHROPIC_API_KEY="sk-ant-YOUR_API_KEY"
```

```jsonc
"agents": {
  "defaults": {
    "model": { "primary": "anthropic/claude-sonnet-4-5" }
  }
}
```

</details>

<details>
<summary><b>选项 3：使用本地 Ollama 模型（完全离线）</b></summary>

先安装 [Ollama](https://ollama.ai) 并拉取模型：

```bash
ollama pull llama3.3
```

在 `~/.openclaw/agents/main/agent/models.json` 中注册本地 provider（Ollama 无内建 provider，需手动配置）：

```json
{
  "providers": {
    "ollama": {
      "baseUrl": "http://localhost:11434/v1",
      "apiKey": "n/a",
      "api": "openai-completions",
      "models": [
        {
          "id": "llama3.3",
          "name": "llama3.3",
          "api": "openai-completions",
          "input": ["text"],
          "contextWindow": 128000,
          "maxTokens": 8192
        }
      ]
    }
  }
}
```

```jsonc
"agents": {
  "defaults": {
    "model": { "primary": "ollama/llama3.3" }
  }
}
```

完全本地运行，无需 API Key，无费用，适合隐私要求高的场景。

</details>

### 3. 配置环境

#### 配置文件模板

创建主配置文件 `~/.openclaw/openclaw.json`：

```jsonc
{
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "<your-bot-token>", // 从 @BotFather 获取
      // dmPolicy 默认为 "pairing"（首次对话需扫码配对），改为 "open" 可跳过配对
    },
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "openai/gpt-4o", // 替换为你在步骤 2 配置的模型
      },
    },
  },
  "gateway": {
    "port": 18789,
    "auth": {
      "token": "<random-secret-string>", // 随机字符串，保护控制台
    },
  },
}
```

#### 配置示例

👇 根据你要接入的功能，展开查看完整配置：

<details>
<summary><b>示例 1：最小配置（Telegram + OpenAI，5 分钟上手）</b></summary>

```jsonc
{
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "1234567890:ABCdefGHIjklMNOpqrSTUvwxYZ",
      "dmPolicy": "open", // 仅自用时可设为 open 跳过配对
    },
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "openai/gpt-4o-mini",
      },
    },
  },
  "gateway": {
    "port": 18789,
  },
}
```

</details>

<details>
<summary><b>示例 2：完整配置（Telegram + 飞书 + Gmail + 飞书日历）</b></summary>

```jsonc
{
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "YOUR_BOT_TOKEN",
      "dmPolicy": "pairing", // 默认：首次对话需配对
    },
    "feishu": {
      "enabled": true,
      "appId": "YOUR_FEISHU_APP_ID",
      "appSecret": "YOUR_FEISHU_APP_SECRET",
      "encryptKey": "YOUR_ENCRYPT_KEY",
      "verificationToken": "YOUR_VERIFICATION_TOKEN",
    },
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "openai/gpt-4o",
      },
    },
  },
  "gateway": {
    "port": 18789,
    "auth": {
      "token": "your-random-secret",
    },
  },
}
```

Gmail 和飞书日历的接入需要额外的 OAuth 步骤，详见 [QUICKSTART.md — Gmail OAuth 配置](./QUICKSTART.md#可选gmail-oauth-接入) 和 [QUICKSTART.md — 飞书日历配置](./QUICKSTART.md#可选飞书日历接入)。

</details>

#### 初始化工作空间

```bash
mkdir -p ~/.openclaw/workspace/automation/assistant_hub/{00_inbox,02_work/tasks,03_life/daily_logs,04_knowledge/{people,beliefs,monthly_digest}}
```

### 4. 运行你的第一个示例

> 📝 **前提**：请确保已完成上面三步的环境配置

现在让我们运行 Kairo，体验主动 AI 秘书的核心功能。

#### 启动网关

```bash
node scripts/run-node.mjs gateway --port 18789
```

#### 发送你的第一条指令

打开 Telegram，向你的 Bot 发送：

```
提醒我明天上午 10 点跟 Jason 确认合同进度
```

#### 预期输出

```
✅ 已建立任务卡片
📋 类型：timeline
📅 截止：明天 10:00
⏰ 已排程提醒

好的，明天上午 10:00 我会主动提醒你跟 Jason 确认合同进度。
```

恭喜！你已成功启动 Kairo 🎉

---

## 常驻服务部署

在生产环境中，我们推荐将 Kairo 作为 systemd 服务常驻运行，以确保开机自启、崩溃自恢复，并为 Heartbeat 主动推送提供稳定的运行环境。

🚀 **systemd 常驻部署**：我们准备了完整的配置教程，包括服务文件模板、环境变量配置、日志查看方式，以及 Gmail / 飞书日历 OAuth 的详细配置步骤。

👉 **[点击查看：完整上手指南 QUICKSTART.md](./QUICKSTART.md)**

---

## 为什么是 Kairo，不是其他工具

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   所有工具都在等你去找它们。                                       │
│   Kairo 在你需要的时候，主动找到你。                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

| 能力                                   |  **Kairo**  | ChatGPT Pulse |  Notion AI   |    Mem.ai     |   Lindy.ai    |   n8n (DIY)   |
| -------------------------------------- | :---------: | :-----------: | :----------: | :-----------: | :-----------: | :-----------: |
| 推送到你常用的 IM（Telegram / 飞书）   |     ✅      |  ❌ App only  | ❌ App only  |  ❌ App only  |    ⚠️ 部分    |   🔧 自己搭   |
| 主动晨报 + 定时提醒（Heartbeat）       |     ✅      |   ⚠️ 仅晨报   |      ❌      |      ❌       |      ❌       |   🔧 自己搭   |
| 自然语言 → 自动分类捕捉                | ✅ 10种意图 |      ❌       |      ❌      |  ⚠️ 笔记only  |      ❌       |   🔧 自己搭   |
| 完整任务闭环（捕捉→提醒→跟进→完成）    |     ✅      |      ❌       |      ❌      |      ❌       |  ⚠️ 商业流程  |   🔧 自己搭   |
| 本地优先，数据在你手上                 | ✅ Markdown |  ❌ OpenAI云  | ❌ Notion云  |   ❌ Mem云    |  ❌ Lindy云   |      ✅       |
| 自托管，零订阅费                       |     ✅      |  ❌ $200/月   | ❌ $20/人/月 |   ❌ $12/月   | ❌ $30~200/月 | ✅ 但需DevOps |
| 决策智慧注入（Naval / Munger / Dalio） | ✅ 每次对话 |      ❌       |      ❌      |      ❌       |      ❌       |      ❌       |
| 邮件 + 日历自动摘要推送                |     ✅      | ⚠️ Gmail only |      ❌      | ⚠️ 有但不推送 |  ⚠️ 商业场景  |   🔧 自己搭   |

> 💡 **最接近 Kairo 的竞品是 n8n** — 它也自托管也能接 Telegram，但你要花几百小时自己搭建每一个功能，且没有任何个人生产力的内建心智模型。Kairo 是一个已经搭好的系统，开箱即用。

---

## 核心理念

在成功运行第一个示例后，让我们深入了解 Kairo 的设计理念。六大核心理念与前面提到的解法一一对应，共同构建了一套完整的个人 AI 秘书体系：

### 1. 自然语言捕捉管道 → 解决碎片化与遗忘

我们不要求你记格式、不要求你打标签、不要求你切换应用。你说话，Kairo 理解。

Kairo 支持 **10 种意图类型**，每一种都有对应的卡片格式和后续工作流。置信度 ≥ 85% 时自动静默建卡；低于时显示菜单让你确认，避免误判。了解更多：[Capture Agent 工作流](./QUICKSTART.md) | [意图类型说明](./QUICKSTART.md)

| 类型        | 说明                   | 范例输入                                             |
| ----------- | ---------------------- | ---------------------------------------------------- |
| `action`    | 需要执行的任务         | 「帮我记一下要回复王总的邮件」                       |
| `timeline`  | 有 deadline 的事项     | 「周五前要把报告发给王总」                           |
| `watch`     | 需要持续跟进的事       | 「关注一下 Jason 那边合同的进度」                    |
| `idea`      | 灵感 / 想法            | 「记一下：可以用 AI 自动化对账流程」                 |
| `memory`    | 要记住的人或事         | 「记住：客户 A 对红色很敏感」                        |
| `belief`    | 认知 / 原则 / 思维框架 | 「Naval 说的 Leverage 理论值得深入研究」             |
| `reference` | 资料 / 链接 / 论文     | 「这篇文章很好，记下来」                             |
| `question`  | 待解答的问题           | 「为什么 GPT-4o 在代码上比 Claude 弱？」             |
| `highlight` | 值得摘录的金句         | 「费曼说：如果你不能简单解释它，你就没有真正理解它」 |
| `person`    | 联系人信息             | 「Jason，前百度 PM，现在在做 AI 教育」               |

### 2. Heartbeat 主动推送系统 → 解决被动等待

这是 Kairo 与所有其他工具最根本的区别。

传统 AI 助手是「被动响应」模式——你不问，它不动。Heartbeat 将这一模式彻底翻转：Kairo 有一套持续运行的后台调度引擎，按照你设定的节奏主动扫描信息、组织输出、推送到你的 IM。了解更多：[Heartbeat 原理](./QUICKSTART.md) | [自定义推送节奏](./QUICKSTART.md)

```
07:00  → 读取飞书日历，汇整今日行程 → 写入 02_work/calendar.md
07:10  → 读取 Gmail，整理重要邮件  → 写入 02_work/gmail.md
07:10  → 晨报推送：今日行程 + 逾期任务 + 邮件摘要 → 发送到 Telegram
09:00  → 「你说过今天要跟 Jason 确认合同，现在是个好时机」
20:30  → 「这周有 3 件事还没完成，要我帮你重新排程吗？」
定期   → Heartbeat 扫描 HEARTBEAT.md，主动处理待办项
```

你不需要打开任何 App，Kairo 在你需要的时候出现。

### 3. Hub Context 注入 → 让 AI 秘书真正了解你

每一次你发消息给 Kairo，它都不是在对话一个空白的 AI。系统自动将 **9 个信息来源**注入 LLM 上下文，让秘书在回应你之前，已经知道你的全局情况：

了解更多：[Hub Context 配置](./QUICKSTART.md) | [信息注入原理](./QUICKSTART.md)

```
┌─────────────────────────────────────────────────────────┐
│  今日 / 昨日记录    ← 最近的行动与思考（daily_logs/）    │
│  未完成待办        ← tasks_master.md 未完成项目（8行）   │
│  今日邮件          ← Gmail + 各邮箱自动摘要              │
│  今日行程          ← 飞书日历自动同步                    │
│  长期路线图        ← 你的季度目标与里程碑（roadmap.md）   │
│  追踪中            ← waiting.md 所有跟进事项             │
│  近期月摘要        ← 最近两个月的记忆压缩                │
│  相关联系人        ← 对话中涉及的人名卡片（people/）      │
│  决策智慧          ← 7位思想家的核心框架（beliefs/）      │
└─────────────────────────────────────────────────────────┘
```

这意味着你说「帮我想想怎么回复 Jason」，Kairo 已经知道 Jason 是谁、你们上次说了什么、你目前的处境与目标。

### 4. 完整任务闭环 → 解决待办堆积

大多数工具在「捕捉」这一步就停止了。Kairo 的闭环从捕捉开始，一直延伸到最终完成。整个过程无需你手动管理：

了解更多：[任务闭环原理](./QUICKSTART.md) | [Cron 排程配置](./QUICKSTART.md)

```
你说话
  │
  ▼
意图识别（Capture Agent）
  │  type=timeline, due=明天10:00
  ▼
建立任务卡片（tasks/XXXXX_合同确认.md）
  │
  ▼
自动排程 cron（明天09:50触发）
  │
  ▼
时间到 → Heartbeat 主动推送
  │  「你说过要跟 Jason 确认合同，现在是个好时机」
  ▼
你确认完成 → LLM 自动更新卡片 status:done
  │
  ▼
tasks_master.md 自动标记 [x]
```

每个有截止日期的任务，从建卡那一刻起，Kairo 就已经在后台安排好了所有后续动作。

### 5. 邮件 + 日历自动接入 → 解决信息孤岛

Kairo 通过 cron 定时抓取外部数据，并自动写入本地文件系统，供 Hub Context 注入每次对话。你不需要主动去看邮件，秘书会在对话中主动告诉你相关信息：

了解更多：[Gmail OAuth 接入](./QUICKSTART.md) | [飞书日历 OAuth 接入](./QUICKSTART.md) | [IMAP 邮箱接入](./QUICKSTART.md)

| 数据源                  | 接入方式                    | 更新时间   | 写入文件              |
| ----------------------- | --------------------------- | ---------- | --------------------- |
| Gmail                   | OAuth Pub/Sub webhook       | 每日 07:10 | `02_work/gmail.md`    |
| 飞书个人日历            | OAuth user token + 自动刷新 | 每日 07:00 | `02_work/calendar.md` |
| Outlook / 163 / QQ Mail | IMAP（自动识别域名）        | 可配置     | `02_work/*-mail.md`   |

新增邮箱无需改代码，`hub-context.ts` 自动扫描所有 `*-mail.md` 文件。

### 6. 本地 Markdown + 自托管 → 解决数据主权

所有信息以 Markdown 文件形式存于本地，结构清晰，人类可读，永不锁定。即使明天 Kairo 停止维护，你的所有数据依然完整可用：

了解更多：[工作空间结构](./QUICKSTART.md) | [数据迁移指南](./QUICKSTART.md)

```
~/.openclaw/workspace/automation/assistant_hub/
├── 00_inbox/              ← 所有原始输入，永不删除
├── 02_work/
│   ├── tasks/             ← 任务卡片（每个任务一个 Markdown 文件）
│   ├── tasks_master.md    ← 任务总索引（[ ] 未完成 / [x] 已完成）
│   ├── waiting.md         ← 跟进中清单（含 checkpoint 日期）
│   ├── calendar.md        ← 每日行程（飞书日历 07:00 自动同步）
│   └── gmail.md           ← 邮件摘要（每日 07:10 自动写入）
├── 03_life/
│   └── daily_logs/        ← 每日记忆（LLM 自动汇整，YYYY-MM-DD.md）
└── 04_knowledge/
    ├── people/            ← 联系人卡片（对话中自动建立与更新）
    ├── beliefs/           ← 决策智慧（Naval/Munger/Dalio 等 7 位）
    ├── roadmap.md         ← 长期路线图（LLM 自动更新）
    └── monthly_digest/    ← 月度记忆压缩（每月 1 日自动生成）
```

---

## 项目架构

Kairo 采用清晰的模块化架构设计，主要目录结构如下：

```
Kairo-KenVersion/
├── src/
│   ├── auto-reply/         ← 核心 AI 回复引擎
│   │   └── reply/
│   │       ├── maybe-run-capture.ts    ← Capture Agent（意图识别、cron 排程）
│   │       ├── hub-context.ts          ← Hub Context 注入（9个信息源）
│   │       └── dispatch-from-config.ts ← 消息分发与 capture alsoReply 模式
│   ├── cron/               ← 定时任务引擎
│   │   ├── global-cron.ts  ← CronService 单例
│   │   └── bootstrap-jobs.ts           ← 启动时确保晨报等核心 Job 存在
│   ├── gateway/            ← 多频道网关（Telegram · 飞书 · Discord · Slack）
│   │   └── server-cron.ts  ← 注册 CronService + 启动 bootstrap jobs
│   └── infra/              ← Heartbeat 主动推送 · 系统事件
│       ├── heartbeat-runner.ts         ← Heartbeat 定时扫描引擎
│       └── system-events.ts            ← 系统事件队列
├── scripts/capture/        ← 数据采集脚本
│   ├── gmail-digest.ts     ← Gmail 摘要（每日 07:10）
│   ├── feishu-calendar.ts  ← 飞书日历同步（每日 07:00）
│   ├── outlook-digest.ts   ← IMAP 通用邮件摘要（支持 Outlook/163/QQ）
│   ├── watch-checker.ts    ← 跟进事项检查（每日 08:00）
│   └── stale-checker.ts    ← 逾期任务扫描（每日 20:30）
├── extensions/feishu/      ← 飞书 channel plugin（完整实现，WebSocket 模式）
├── content/                ← 情报中心输出目录
│   ├── daily/              ← 工具日报 · 编辑精选 · 社交情报 · 工作流灵感
│   ├── frameworks/         ← 架构深评（周二 / 四 / 六）
│   └── reports/biweekly/   ← 双周推理报告
├── ui/                     ← 控制台 Web UI（Lit + Vite）
├── QUICKSTART.md           ← 完整上手指南
└── docs/                   ← 详细文档
```

---

## 进阶阅读

如需了解更多详细配置与使用方式，请访问我们的完整上手指南：

- 📖 [QUICKSTART.md](./QUICKSTART.md) — 7 步完整上手，含 systemd、Gmail OAuth、飞书日历
- 🔧 [systemd 常驻服务配置](./QUICKSTART.md#第六步systemd-常驻运行推荐)
- 📧 [Gmail OAuth 接入](./QUICKSTART.md#可选gmail-oauth-接入)
- 📅 [飞书日历 OAuth 接入](./QUICKSTART.md#可选飞书日历接入)
- 🤖 [模型选择与配置](./QUICKSTART.md#第二步选择-ai-模型)

---

## 支持频道

| 频道        | 状态      | 备注                   |
| ----------- | --------- | ---------------------- |
| Telegram    | ✅ 稳定   | 推荐，最成熟           |
| 飞书 / Lark | ✅ 稳定   | WebSocket，无需公网 IP |
| Discord     | ✅ 稳定   |                        |
| Slack       | ✅ 稳定   |                        |
| WhatsApp    | 🚧 测试中 |                        |
| WeChat      | 🚧 规划中 |                        |

---

## 路线图

> **核心命题**：所有现有 AI 工具都是 **Pull** 模式——你问，它答；你不问，它沉默。
> Kairo 的方向是 **Push**：在你开口之前行动，在你遗忘之前提醒，在你分心之前闭环。

### 当前状态（v0.9，生产运行中）

核心功能已稳定运行，正在向易用性与 agent 协作能力演进：

| 模块                                      |   状态    | 说明                                        |
| ----------------------------------------- | :-------: | ------------------------------------------- |
| 多频道网关（Telegram / 飞书）             |  ✅ 稳定  | WebSocket，无需公网 IP                      |
| 意图识别 + 自动建卡（10 种类型）          |  ✅ 稳定  | 置信度 ≥ 85% 自动静默建卡                   |
| Heartbeat 主动推送                        |  ✅ 稳定  | 定时扫描 + 事件触发，5 分钟超时保护         |
| 完整任务闭环（捕捉 → 排程 → 提醒 → 更新） |  ✅ 稳定  | LLM 自主完成全流程，无需 Ken 手动标记       |
| Hub Context（9 个信息源注入）             |  ✅ 稳定  | 每次对话已感知日历 / 邮件 / 任务 / 人脈全局 |
| Gmail + 飞书日历 + Outlook IMAP           |  ✅ 稳定  | 飞书 token 30 天自动滚动刷新，无需手动续期  |
| 联系人记忆卡片 + 决策智慧框架             |  ✅ 稳定  | 7 位思想家原则，每次对话注入                |
| 飞书日历写入（LLM tool）                  |  ✅ 稳定  | create_event / list_events，含并发 mutex    |
| 系统稳定性（原子写入 / 超时 / 错误日志）  | ✅ 已完成 | 2026-02 专项修复                            |
| 去除 root 依赖 + `$KAIRO_HOME` 可配置     | 🔲 未开始 | **当前 hardcoded 路径，阻塞其他用户部署**   |

### 开发优先级

> **P0** 阻塞他人使用 · **P1** 高价值近期 · **P2** 架构演进 · **P3** 长期愿景

| 优先级 | 功能                                                                                      |   分类   | 说明                                                                                |
| :----: | ----------------------------------------------------------------------------------------- | :------: | ----------------------------------------------------------------------------------- |
| **P0** | 去除 root 依赖，`$KAIRO_HOME` 可配置                                                      | 基础设施 | 现在 hardcoded `/opt/LazyingArtBot/`，其他人无法部署                                |
| **P0** | `install.sh` + AI 引导式 setup                                                            | 基础设施 | 非技术用户 5 分钟上手，解锁开源受众                                                 |
| **P1** | arXiv 每日监控 → 推送 + 写入知识库                                                        |   研究   | 每天自动推送相关方向新论文，秘书主动喂信息                                          |
| **P1** | [gpt-researcher](https://github.com/assafelovic/gpt-researcher) 集成为 LLM tool           |   研究   | 一句话触发深度文献调研，结果写入 `research_notes/`                                  |
| **P1** | 实验结果追踪工具                                                                          |   研究   | `experiments/` 目录 + LLM tool，自动对比多轮结果、标注异常                          |
| **P1** | Docker 一键启动                                                                           | 基础设施 | 大幅降低部署门槛，`docker compose up` 即可运行                                      |
| **P2** | Kairo MCP Server                                                                          |   架构   | calendar / tasks / people 暴露为标准 MCP resource，任何 agent 可直接调用 Ken 的数据 |
| **P2** | MCP Client                                                                                |   架构   | Kairo 调用外部 MCP server（filesystem、github、web-search），不重造轮子             |
| **P2** | Swarm 调度层（[agency-swarm](https://github.com/VRSEN/agency-swarm) / OpenAI Agents SDK） |   架构   | Kairo 作为 orchestrator，复杂任务分派给 Research / Code / Email 等专职 worker agent |
| **P2** | [AgentLaboratory](https://github.com/SamuelSchmidgall/AgentLaboratory) 写作集成           |   研究   | 文献 → 实验 → 初稿三段式，Kairo 统一入口                                            |
| **P2** | Bounded autonomy + Audit trail                                                            |   架构   | 高风险操作（对外发信 / 删文件）必须 Ken 确认；所有 agent 行动可回溯                 |
| **P3** | Computer use agent                                                                        |   愿景   | 不只出建议，Kairo 直接操作浏览器与桌面完成任务                                      |
| **P3** | Self-improving                                                                            |   愿景   | 每周分析自身错误 → 更新行为模式，下次更准                                           |
| **P3** | 关系图谱                                                                                  |   愿景   | `people/` 卡片升级为网络图，自动发现潜在协作机会                                    |
| **P3** | 跨设备 context sync                                                                       |   愿景   | phone / laptop / server 共享同一个 Kairo 上下文                                     |

---

## 社区与团队

### 关于 Kairo

Kairo 是由 **Ken** 从自身需求出发、历经数月打磨的个人 AI 秘书系统，基于开源项目 [OpenClaw](https://github.com/openclaw/openclaw) 构建。

构建 Kairo 的核心动因：在 AI 工具爆炸的今天，Ken 发现自己越来越多的时间花在「管理工具」而不是「完成工作」上。Kairo 的目标是让 AI 真正成为秘书——不是一个等你发问的工具，而是一个了解你的全局、在恰好的时刻主动出现的伙伴。

**Kairo 的进化时间线：**

- **2025 年初**：基于 OpenClaw 网关，搭建 Telegram 多频道基础
- **2025 年中**：实现 Capture Agent，支持 10 种意图自动分类建卡
- **2025 年下半年**：构建 Heartbeat 主动推送系统，真正做到「主动秘书」
- **2026 年初**：接入 Gmail + 飞书日历，Hub Context 9个信息源注入，联系人记忆与决策智慧框架上线
- **2026 年（进行中）**：v1 稳定化，规划公开易用版

---

### 加入社区

Kairo 目前处于个人生产环境阶段，有许多需要完善和探索的地方。欢迎每一位对「主动 AI 秘书」充满热情的开发者：

- 为我们点亮一颗宝贵的 **Star**，给予前行的动力
- 访问 [**QUICKSTART.md**](./QUICKSTART.md)，在你的机器上跑起来，并向我们反馈真实体验
- 加入社区讨论，分享你的使用场景与改进建议：
  - 💬 **微信群**：添加微信并备注「Kairo」→ [查看二维码](#)
  - 🎮 **Discord**：[加入 Discord 服务器](#)
  - 🐦 **X (Twitter)**：[关注动态](#)
- 成为**贡献者**：无论是 Bug 修复、新的捕捉意图类型，还是新的频道适配器，每一行代码都是 Kairo 成长的基石

---

### Star 趋势

[![Star History Chart](https://api.star-history.com/svg?repos=sou350121/Kairo-KenVersion&type=timeline&legend=top-left)](https://www.star-history.com/#sou350121/Kairo-KenVersion&type=timeline&legend=top-left)

---

## 🤖 AI 辅助开发（Cursor · Claude Code · ChatGPT）

Kairo 为主流 AI 编程工具提供开箱即用的上下文 prompt，克隆仓库后即自动生效：

| 工具               | 配置文件                                                               | 说明                                   |
| ------------------ | ---------------------------------------------------------------------- | -------------------------------------- |
| **Claude Code**    | [`CLAUDE.md`](./CLAUDE.md)                                             | 自动加载，包含架构、关键文件、常见任务 |
| **Cursor**         | [`.cursorrules`](./.cursorrules)                                       | 自动加载，包含目录结构、约定、禁忌     |
| **GitHub Copilot** | [`.github/copilot-instructions.md`](./.github/copilot-instructions.md) | 自动加载                               |
| **ChatGPT / 其他** | 手动粘贴 `CLAUDE.md` 内容                                              | 复制到系统 prompt 或首条消息           |

克隆后无需任何额外配置，打开项目即可获得「了解 Kairo 架构」的 AI 编程助手。

---

## 致谢

Kairo 基于 **[OpenClaw](https://github.com/openclaw/openclaw)** 构建。感谢 OpenClaw 团队提供坚实的多频道 AI 网关基础。

特别感谢 **[LazyingArtBot](https://github.com/lachlanchen/LazyingArtBot)** —— Kairo 的前身与灵感来源。正是 LazyingArtBot 积累的实战经验、踩过的坑与探索出的模式，才孕育了今天的 Kairo。没有 LazyingArtBot，就没有 Kairo。

---

## 许可证

本项目采用 MIT 开源协议 — 详见 [LICENSE](./LICENSE)

<!-- 链接定义 -->

[github-stars-shield]: https://img.shields.io/github/stars/sou350121/Kairo-KenVersion?labelColor=black&style=flat-square&color=ffcb47&logo=github
[github-stars-link]: https://github.com/sou350121/Kairo-KenVersion
[github-issues-shield]: https://img.shields.io/github/issues/sou350121/Kairo-KenVersion?labelColor=black&style=flat-square&color=ff80eb
[github-issues-link]: https://github.com/sou350121/Kairo-KenVersion/issues
[github-contributors-shield]: https://img.shields.io/github/contributors/sou350121/Kairo-KenVersion?color=c4f042&labelColor=black&style=flat-square
[github-contributors-link]: https://github.com/sou350121/Kairo-KenVersion/graphs/contributors
[license-shield]: https://img.shields.io/badge/license-MIT-white?labelColor=black&style=flat-square
[license-link]: https://github.com/sou350121/Kairo-KenVersion/blob/main/LICENSE
[node-shield]: https://img.shields.io/badge/node-%3E%3D22-green?labelColor=black&style=flat-square&logo=node.js
[node-link]: https://nodejs.org
[last-commit-shield]: https://img.shields.io/github/last-commit/sou350121/Kairo-KenVersion?color=369eff&labelColor=black&style=flat-square
[last-commit-link]: https://github.com/sou350121/Kairo-KenVersion/commits/main
