<div align="center">

<img src="./assets/kairo-banner.svg" alt="Kairo — 个人全能 AI 秘书" width="100%"/>

<h1>Kairo · 个人全能 AI 秘书</h1>

<p><b>你思考。Kairo 记忆、整理、跟进 — 在恰好的时刻主动找到你。</b><br/>
<i>You think. Kairo remembers, organizes, and follows up — finding you at exactly the right moment.</i></p>

<a href="https://github.com/sou350121/Kairo-KenVersion"><img src="https://img.shields.io/github/stars/sou350121/Kairo-KenVersion?style=flat-square&logo=github" alt="Stars"/></a>
<a href="https://github.com/sou350121/Kairo-KenVersion/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="License"/></a>
<img src="https://img.shields.io/badge/node-%3E%3D22-green?style=flat-square&logo=node.js" alt="Node"/>
<img src="https://img.shields.io/badge/channels-Telegram%20%7C%20Feishu%20%7C%20Discord-blueviolet?style=flat-square" alt="Channels"/>
<img src="https://img.shields.io/badge/data-local--first-success?style=flat-square" alt="Local First"/>
<img src="https://img.shields.io/badge/proactive-Heartbeat-orange?style=flat-square" alt="Proactive"/>

</div>

---

## 项目概览

### 知识工作者面临的六大困境

我们每天都生活在信息的漩涡里。在 AI 工具爆炸的今天，效率问题不是工具不够多，而是工具太被动、太碎散、太孤立：

- **输入碎片化**：想法在微信群，任务在 Notion，邮件在 Gmail，行程在飞书，联系人在通讯录。碎散在 5 个 App 里的信息，没有任何一个地方让你看清全局
- **工具只能被动等待**：所有工具都在等你去找它们。记事本不会在周五下午提醒你「这件事你还没做」，待办清单不会在早上告诉你「今天最重要的三件事是什么」。你的记忆负担，没有任何人帮你分担
- **捕捉阻力导致遗忘**：好想法发生在地铁、咖啡馆、刚入睡前。打开 App → 找到页面 → 选格式 → 输入——这四步足以让你放弃。你说「等一下再记」，然后永远忘了
- **待办只有进，没有出**：你确实记了，但没有系统去跟进它、提醒它、在逾期时主动找你。任务静静躺在清单里，一条一条堆积，最后你连打开都不想
- **邮件与行程形同孤岛**：每天早上要切换 Gmail、飞书日历、微信群三个地方，才能拼出「今天要做什么」。任何一个遗漏，就是错过的会议或没回的重要邮件
- **数据主权丧失**：你花几年积累的笔记、任务、人脉，全部住在别人的服务器上。他们涨价、关服、或被收购，你的资产就不再属于你

### Kairo 的解法

Kairo 不是又一个笔记 App，也不是又一个 AI 助手。它是一套**主动运行在你服务器上的个人 AI 秘书系统**，通过你每天本来就在用的 IM（Telegram / 飞书）与你互动：

- **统一捕捉入口 → 解决碎片化**：你的 Telegram 或飞书就是唯一入口。自然语言输入，Kairo 自动识别 10 种意图并分类建卡，无需打开任何其他 App
- **Heartbeat 主动推送 → 解决被动等待**：Kairo 定时扫描你的任务、邮件、行程，到时间主动找你。你不需要记得去查，它会在恰好的时刻出现
- **零摩擦捕捉 → 解决遗忘问题**：说话即捕捉。1 秒输入，Kairo 自动建立正确类型的卡片，存入本地文件系统，永不丢失
- **完整任务闭环 → 解决待办堆积**：从捕捉到建卡，从排程到提醒，从跟进到标记完成——每一步由 Kairo 自动完成，你只需要决策
- **邮件 + 日历自动接入 → 解决信息孤岛**：每日 07:00 自动读取飞书日历和 Gmail，汇整成一条晨报推送给你，早上一条消息看完全局
- **本地 Markdown + 自托管 → 解决数据主权**：所有数据是 Markdown 文件，存在你自己的机器上。零订阅费，永不被锁定，人类可读，随时可迁移

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

成功运行后，让我们深入了解 Kairo 的设计理念。六大核心理念与前面提到的解法一一对应：

### 1. 自然语言捕捉管道 → 解决碎片化与遗忘

Kairo 不要求你学任何格式或语法。你说话，它理解。支持 **10 种意图类型**，每一种都有对应的卡片格式：

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

置信度 ≥ 85% 自动建卡并静默确认；低于时显示菜单让你选择，避免误判。

### 2. Heartbeat 主动推送系统 → 解决被动等待

这是 Kairo 与所有其他工具最根本的区别。Heartbeat 是一个持续运行的后台系统，定时扫描你的任务状态、逾期事项、待跟进清单，在恰好的时刻主动把信息推到你的 IM 里：

```
07:00  → 读取飞书日历，汇整今日行程
07:10  → 读取 Gmail，整理重要邮件
08:00  → 晨报推送：今日行程 + 逾期任务 + 邮件摘要
09:00  → 「你说过今天要跟 Jason 确认合同，现在是个好时机」
20:30  → 「这周有 3 件事还没完成，要我帮你重新排程吗？」
```

你不需要打开任何 App，Kairo 在你需要的时候出现。

### 3. Hub Context 注入 → 解决信息孤岛

每一次你发消息给 Kairo，它都不是在对话一个空白的 AI。系统自动将 **9 个信息来源**注入 LLM 上下文，让秘书在回应你之前，已经知道：

```
┌─────────────────────────────────────────────────┐
│  今日 / 昨日记录      最近的行动与思考            │
│  未完成待办          tasks_master.md 未完成项目   │
│  今日邮件            Gmail + Outlook 自动摘要      │
│  今日行程            飞书日历自动同步              │
│  长期路线图          你的季度目标与里程碑          │
│  追踪中              waiting.md 所有跟进事项       │
│  近期月摘要          最近两个月的记忆压缩          │
│  相关联系人          对话中涉及的人名卡片          │
│  决策智慧            7位思想家的核心框架           │
└─────────────────────────────────────────────────┘
```

这意味着你说「帮我想想怎么回复 Jason」，Kairo 已经知道 Jason 是谁、你们上次说了什么、你目前的处境与目标。

### 4. 完整任务闭环 → 解决待办堆积

大多数工具在「捕捉」这一步就停止了。Kairo 的闭环从捕捉开始，一直延伸到完成：

```
你说话  →  意图识别  →  建立任务卡片  →  自动排程 cron
                                              │
你确认完成  ←  自动更新状态  ←  跟进追踪  ←  时间到主动找你
```

每个有截止日期的任务，Kairo 在建卡时就自动在 cron 系统里排好提醒。到期前它来找你，不需要你记得。

### 5. 邮件 + 日历自动接入 → 解决信息孤岛

| 数据源                  | 接入方式                    | 更新频率   | 输出                  |
| ----------------------- | --------------------------- | ---------- | --------------------- |
| Gmail                   | OAuth Pub/Sub webhook       | 每日 07:10 | `02_work/gmail.md`    |
| 飞书个人日历            | OAuth user token + 自动刷新 | 每日 07:00 | `02_work/calendar.md` |
| Outlook / 163 / QQ Mail | IMAP（自动识别域名）        | 可配置     | `02_work/*-mail.md`   |

所有数据汇整后，Hub Context 自动注入，LLM 每次对话都有最新的邮件与行程背景。

### 6. 本地 Markdown + 自托管 → 解决数据主权

所有信息以 Markdown 文件形式存于本地，结构清晰，人类可读，永不锁定：

```
~/.openclaw/workspace/
├── 00_inbox/              ← 所有原始输入，永不删除
├── 02_work/
│   ├── tasks/             ← 任务卡片（每个任务一个文件）
│   ├── tasks_master.md    ← 任务总索引
│   ├── waiting.md         ← 跟进中清单（含 checkpoint）
│   ├── calendar.md        ← 每日行程（飞书自动同步）
│   └── gmail.md           ← 邮件摘要（每日自动写入）
├── 03_life/
│   └── daily_logs/        ← 每日记忆（LLM 自动汇整）
└── 04_knowledge/
    ├── people/            ← 联系人卡片（对话中自动更新）
    ├── beliefs/           ← 决策智慧（Naval/Munger/Dalio 等7位）
    ├── roadmap.md         ← 长期路线图
    └── monthly_digest/    ← 月度记忆压缩
```

明天 Notion 涨价，你的数据在你自己的机器上，一行代码都不会丢。

---

## 📰 情报中心 — Kairo 每日推送

> Kairo 自动抓取、整理并推送至你的 Telegram / 飞书，无需主动查看。

| 栏目                | 说明                              | 文件路径规则                                                          | 排程（北京时间）          |
| ------------------- | --------------------------------- | --------------------------------------------------------------------- | ------------------------- |
| 📋 **工具日报**     | 今日值得关注的 AI 工具速览        | [`content/daily/YYYY-MM-DD-tools.md`](./content/daily/)               | 每日 07:00                |
| ⭐ **编辑精选**     | 跨域重要事件，附编辑观点          | [`content/daily/YYYY-MM-DD-picks.md`](./content/daily/)               | 每日 07:15                |
| 🔥 **社交情报**     | 大 V 观点 · 社区争议 · Viral 内容 | [`content/daily/YYYY-MM-DD-social.md`](./content/daily/)              | 每日 07:45                |
| 🔍 **架构深评**     | 生产踩坑 + AI 代码盲点分析        | [`content/frameworks/YYYY-MM-DD-review.md`](./content/frameworks/)    | 周二 / 四 / 六 15:30      |
| 💡 **工作流灵感**   | 「我用 AI 自动化了 X」真实案例    | [`content/daily/YYYY-MM-DD-workflow.md`](./content/daily/)            | 周一 / 三 / 五 / 日 15:45 |
| 📊 **双周推理报告** | 趋势预测 + 历史准确率追踪         | [`content/reports/biweekly/YYYY-WNN.md`](./content/reports/biweekly/) | 隔周一 08:00              |

> 📁 所有输出文件存于 `content/`，Markdown 格式，完整可搜索，不依赖任何云服务。

---

## 系统架构

```
[你的输入：文字 / 图片 / 语音]
         │
         ▼
┌─────────────────────────────┐
│       OpenClaw 网关          │  ← 多频道统一接收
│  Telegram · 飞书 · Discord  │
└─────────────┬───────────────┘
              │
     ┌────────▼─────────┐          ┌────────────────────┐
     │   Capture Agent  │          │    Cron Scheduler  │
     │  意图识别 · 10分类 │          │  晨报·提醒·邮件·日历  │
     └────────┬─────────┘          └──────────┬─────────┘
              │                               │
              └──────────────┬────────────────┘
                             ▼
              ┌──────────────────────────┐
              │    assistant_hub（本地）  │
              │  Markdown · 任务 · 日志  │
              └──────────────┬───────────┘
                             │
              ┌──────────────▼───────────┐
              │       Hub Context        │  ← 9个信息源注入每次对话
              │  邮件·行程·待办·人脉·智慧  │
              └──────────────┬───────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │    Heartbeat    │  ← 定期扫描 → 主动推送
                    └─────────────────┘
```

---

## 快速开始

> ⚠️ **这是 Ken 的个人生产环境版本。** 公开易用版 Kairo 正在规划中。以下为技术用户的参考流程。

### 环境要求

- Node.js ≥ 22 · pnpm ≥ 9 · Linux / macOS

### 1. 克隆并安装

```bash
git clone https://github.com/sou350121/Kairo-KenVersion.git
cd Kairo-KenVersion
pnpm install && pnpm ui:build && pnpm build
```

### 2. 最小配置

创建配置文件 `~/.openclaw/openclaw.json`：

```jsonc
{
  "channels": {
    "telegram": {
      "enabled": true,
      "token": "YOUR_BOT_TOKEN", // 从 @BotFather 申请
    },
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "openai-codex/gpt-5.3-codex", // 或任何 OpenAI-compatible model
      },
    },
  },
  "gateway": {
    "port": 18789,
  },
}
```

<details>
<summary><b>进阶配置：接入 Gmail</b></summary>

```jsonc
{
  "capture": {
    "gmail": {
      "enabled": true,
      "clientId": "YOUR_OAUTH_CLIENT_ID",
      "clientSecret": "YOUR_OAUTH_CLIENT_SECRET",
    },
  },
}
```

</details>

<details>
<summary><b>进阶配置：接入飞书日历</b></summary>

```jsonc
{
  "capture": {
    "feishu": {
      "enabled": true,
      "appId": "YOUR_FEISHU_APP_ID",
      "appSecret": "YOUR_FEISHU_APP_SECRET",
    },
  },
}
```

</details>

### 3. 启动

```bash
node scripts/run-node.mjs gateway --port 18789
```

### 4. 验证

打开 Telegram，向你的 Bot 发送：

```
提醒我明天上午 10 点跟 Jason 确认合同
```

预期结果：

```
✅ 已建立任务卡片
📋 类型：timeline
📅 截止：2026-02-28 10:00
⏰ 已排程提醒

明天上午 10:00 我会主动提醒你。
```

控制台：`http://localhost:18789`

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

## 项目结构

```
Kairo-KenVersion/
├── src/
│   ├── auto-reply/         ← Capture Agent · Hub Context 注入（9个信息源）
│   ├── cron/               ← 定时任务引擎 · Heartbeat 排程
│   ├── gateway/            ← 多频道网关（Telegram · 飞书 · Discord）
│   └── infra/              ← Heartbeat 主动推送 · 系统事件
├── scripts/capture/        ← 邮件摘要 · 飞书日历 · 任务扫描脚本
├── extensions/feishu/      ← 飞书 channel plugin（完整实现）
├── content/                ← 每日情报中心输出目录
│   ├── daily/              ← 工具日报 · 编辑精选 · 社交情报 · 工作流灵感
│   ├── frameworks/         ← 架构深评（周二 / 四 / 六）
│   └── reports/biweekly/   ← 双周推理报告
└── ui/                     ← 控制台 Web UI（Lit + Vite）
```

---

## 路线图

- [x] 多频道捕捉（Telegram / 飞书）
- [x] 智能意图识别（10 种类型）
- [x] 本地 Markdown 文件系统
- [x] Heartbeat 主动推送系统
- [x] 邮件摘要（Gmail / 飞书日历 / Outlook）
- [x] 联系人记忆卡片（自动建立与更新）
- [x] 决策智慧注入（Naval · Munger · Dalio 等 7 位）
- [x] Hub Context 9个信息源注入
- [x] 每日情报中心（content/ 目录结构）
- [ ] **公开易用版** — 5 分钟部署，零配置负担
- [ ] Setup Wizard（CLI 引导式配置）
- [ ] Docker 一键启动
- [ ] 多语言支持（English / 日本語）

---

## 致谢

Kairo 基于 **[OpenClaw](https://github.com/openclaw/openclaw)** 构建。感谢 OpenClaw 团队提供坚实的多频道 AI 网关基础。

---

## License

MIT License — 详见 [LICENSE](./LICENSE)
