<div align="center">

<picture>
  <img alt="Kairo" src="./assets/kairo-banner.svg" width="100%" height="auto">
</picture>

### Kairo: The Proactive AI Secretary for Knowledge Workers

[中文](./README.md) / English

<a href="./QUICKSTART.md">Quick Start</a> · <a href="https://github.com/sou350121/Kairo-KenVersion">GitHub</a> · <a href="https://github.com/sou350121/Kairo-KenVersion/issues">Issues</a> · <a href="./docs/">Docs</a>

[![][github-stars-shield]][github-stars-link]
[![][github-issues-shield]][github-issues-link]
[![][github-contributors-shield]][github-contributors-link]
[![][license-shield]][license-link]
[![][node-shield]][node-link]
[![][last-commit-shield]][last-commit-link]

👋 Join the community

💬 <a href="#">WeChat Group</a> · 🎮 <a href="#">Discord</a> · 🐦 <a href="#">X (Twitter)</a>

</div>

---

## Overview

### Six Pain Points Every Knowledge Worker Knows

In the age of AI tool explosion, the productivity problem isn't a lack of tools — it's that tools are too passive, too fragmented, too isolated:

- **Fragmented input**: Ideas live in group chats, tasks in Notion, emails in Gmail, schedules in calendar apps, contacts in the address book. Five apps, no single place to see the whole picture
- **Tools only wait**: Every tool waits for you to open it. Your note app won't remind you on Friday afternoon that you still haven't done something. Your to-do list won't tell you every morning what the three most important things are today
- **Capture friction causes forgetting**: Good ideas strike on the subway, at a café, right before sleep. Open app → find the right page → choose a format → type — those four steps are enough to make you give up
- **Tasks pile in, nothing comes out**: You did capture it. But there's no system to follow up, remind you, or proactively find you when it's overdue. Tasks accumulate quietly in the list
- **Email and calendar are islands**: Every morning you switch between Gmail, your calendar, and group chats to piece together "what do I need to do today"
- **Data sovereignty lost**: The notes, tasks, and contacts you've built over years all live on someone else's server. They raise prices, shut down, or get acquired — and your assets no longer belong to you

### How Kairo Solves This

Kairo is not another note app, nor another AI assistant. It is a **proactive AI secretary system running on your own server**, interacting through the IM apps you already use every day (Telegram / Feishu / Lark):

- **Unified capture → solves fragmentation**: Your Telegram or Feishu is the single entry point. Natural language input, Kairo auto-classifies into 10 intent types and creates cards
- **Heartbeat proactive delivery → solves passive waiting**: Kairo periodically scans your tasks, emails, and schedule, and reaches out to you at the right time — you don't need to remember to check
- **Zero-friction capture → solves forgetting**: Say it, it's captured. 1-second input, Kairo automatically creates the right type of card, stored in the local filesystem, never lost
- **Complete task loop → solves pile-up**: From capture to card creation, from scheduling to reminders, from follow-up to marking done — every step is automated by Kairo
- **Email + calendar auto-integration → solves information silos**: Every day at 07:00, Kairo automatically reads your Feishu calendar and Gmail, consolidates into a morning briefing and pushes it to you
- **Local Markdown + self-hosted → solves data sovereignty**: All data is Markdown files stored on your own machine. Zero subscription fees, never locked in

---

## Quick Start

### Prerequisites

Before getting started with Kairo, make sure your environment meets these requirements:

- **Node.js**: version 22 or higher (`node -v` to confirm)
- **Package manager**: pnpm 9 or higher (`npm install -g pnpm`)
- **OS**: Linux / macOS (Windows requires WSL2)
- **Network**: Stable internet connection (for AI model API access)
- **Telegram Bot**: Create a bot via [@BotFather](https://t.me/BotFather) and save the token

### 1. Clone and Install

```bash
git clone https://github.com/sou350121/Kairo-KenVersion.git
cd Kairo-KenVersion
pnpm install && pnpm ui:build && pnpm build
```

### 2. Choose a Model

Kairo supports multiple AI model providers — you only need one:

- **OpenAI**: GPT-4o, GPT-4.1, etc. — API key from [platform.openai.com](https://platform.openai.com)
- **Anthropic Claude**: Claude Sonnet / Opus — API key from [console.anthropic.com](https://console.anthropic.com)
- **Any OpenAI-compatible API**: Any provider with OpenAI-format endpoints

<details>
<summary><b>Option 1: OpenAI (recommended for new users)</b></summary>

The simplest setup. Create an API key at [platform.openai.com/api-keys](https://platform.openai.com/api-keys). Pay per use, no monthly fee.

```bash
# Set environment variable (add to ~/.bashrc or ~/.zshrc to persist)
export OPENAI_API_KEY="sk-proj-YOUR_API_KEY"
```

In `~/.openclaw/openclaw.json`, set the default model:

```jsonc
"agents": {
  "defaults": {
    "model": { "primary": "openai/gpt-4o-mini" }
  }
}
```

Estimated cost: ~$1–5/month for daily use (gpt-4o-mini is cheaper)

</details>

<details>
<summary><b>Option 2: Anthropic Claude</b></summary>

Create an API key at [console.anthropic.com](https://console.anthropic.com). Claude excels at long-context understanding and instruction following.

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
<summary><b>Option 3: Local Ollama (fully offline)</b></summary>

Install [Ollama](https://ollama.ai) and pull a model:

```bash
ollama pull llama3.3
```

Register the local provider in `~/.openclaw/agents/main/agent/models.json`:

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

Fully local, no API key required, no cost. Ideal for high-privacy scenarios.

</details>

### 3. Configure

#### Config File Template

Create `~/.openclaw/openclaw.json`:

```jsonc
{
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "<your-bot-token>", // from @BotFather
      // dmPolicy defaults to "pairing" (first chat requires pairing); set to "open" to skip
    },
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "openai/gpt-4o", // replace with the model you configured above
      },
    },
  },
  "gateway": {
    "port": 18789,
    "auth": {
      "token": "<random-secret-string>", // protects the control console
    },
  },
}
```

<details>
<summary><b>Example 1: Minimal config (Telegram + OpenAI, 5-minute setup)</b></summary>

```jsonc
{
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "1234567890:ABCdefGHIjklMNOpqrSTUvwxYZ",
      "dmPolicy": "open", // use "open" when running for yourself only
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
<summary><b>Example 2: Full config (Telegram + Feishu + Gmail + Feishu Calendar)</b></summary>

```jsonc
{
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "YOUR_BOT_TOKEN",
      "dmPolicy": "pairing",
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

Gmail and Feishu Calendar require additional OAuth steps — see [QUICKSTART.md](./QUICKSTART.md).

</details>

#### Initialize Workspace

```bash
mkdir -p ~/.openclaw/workspace/automation/assistant_hub/{00_inbox,02_work/tasks,03_life/daily_logs,04_knowledge/{people,beliefs,monthly_digest}}
```

### 4. Run Your First Example

#### Start the Gateway

```bash
node scripts/run-node.mjs gateway --port 18789
```

#### Send Your First Command

Open Telegram and send your bot:

```
Remind me tomorrow at 10am to confirm the contract progress with Jason
```

#### Expected Output

```
✅ Task card created
📋 Type: timeline
📅 Due: tomorrow 10:00
⏰ Reminder scheduled

Got it — I'll proactively remind you tomorrow at 10:00 to confirm the contract progress with Jason.
```

Kairo is running!

---

## Production Deployment

For production use, we recommend running Kairo as a systemd service for auto-start on boot, crash recovery, and a stable runtime for the Heartbeat proactive delivery engine.

👉 **[Full setup guide: QUICKSTART.md](./QUICKSTART.md)**

---

## Why Kairo, Not Something Else

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   Every tool waits for you to open it.                         │
│   Kairo reaches you when you need it.                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

| Capability                                         |   **Kairo**   |  ChatGPT Pulse   |    Notion AI    |    Mem.ai     |     Lindy.ai      |   n8n (DIY)   |
| -------------------------------------------------- | :-----------: | :--------------: | :-------------: | :-----------: | :---------------: | :-----------: |
| Push to your IM (Telegram / Feishu)                |      ✅       |   ❌ App only    |   ❌ App only   |  ❌ App only  |    ⚠️ Partial     |  🔧 Build it  |
| Morning briefing + scheduled reminders (Heartbeat) |      ✅       | ⚠️ Briefing only |       ❌        |      ❌       |        ❌         |  🔧 Build it  |
| Natural language → auto-classified capture         | ✅ 10 intents |        ❌        |       ❌        | ⚠️ Notes only |        ❌         |  🔧 Build it  |
| Full task loop (capture→remind→follow-up→done)     |      ✅       |        ❌        |       ❌        |      ❌       | ⚠️ Business flows |  🔧 Build it  |
| Local-first, data on your machine                  |  ✅ Markdown  | ❌ OpenAI cloud  | ❌ Notion cloud | ❌ Mem cloud  |  ❌ Lindy cloud   |      ✅       |
| Self-hosted, zero subscription                     |      ✅       |    ❌ $200/mo    | ❌ $20/user/mo  |   ❌ $12/mo   |   ❌ $30–200/mo   | ✅ but DevOps |
| Decision wisdom injection (Naval / Munger / Dalio) | ✅ Every turn |        ❌        |       ❌        |      ❌       |        ❌         |      ❌       |
| Email + calendar auto-digest delivery              |      ✅       |  ⚠️ Gmail only   |       ❌        |  ⚠️ No push   |    ⚠️ Business    |  🔧 Build it  |

> 💡 **The closest alternative to Kairo is n8n** — it's also self-hosted and can integrate with Telegram. But you'd spend hundreds of hours building each feature yourself, with no built-in mental model for personal productivity. Kairo is a complete, pre-built system.

---

## Core Design

### 1. Natural Language Capture Pipeline → Solves Fragmentation & Forgetting

No format required. No tags. No app switching. You speak, Kairo understands.

Kairo supports **10 intent types**, each with its own card format and follow-up workflow. Confidence ≥ 85% → silent card creation. Below threshold → confirmation menu shown to prevent misclassification.

| Type        | Description                  | Example Input                                                      |
| ----------- | ---------------------------- | ------------------------------------------------------------------ |
| `action`    | Task to execute              | "Note to reply to Alex's email"                                    |
| `timeline`  | Item with a deadline         | "Report due to Alex by Friday"                                     |
| `watch`     | Something to keep tracking   | "Keep an eye on Jason's contract status"                           |
| `idea`      | Idea / inspiration           | "Note: could use AI to automate reconciliation"                    |
| `memory`    | Something to remember        | "Remember: Client A is sensitive about red colors"                 |
| `belief`    | Principle / mental framework | "Naval's leverage theory is worth studying"                        |
| `reference` | Resource / link / paper      | "This article is great, save it"                                   |
| `question`  | Unanswered question          | "Why is GPT-4o weaker than Claude on code?"                        |
| `highlight` | Quotable insight             | "Feynman: If you can't explain it simply, you don't understand it" |
| `person`    | Contact info                 | "Jason, ex-Baidu PM, now doing AI education"                       |

### 2. Heartbeat Proactive Delivery → Solves Passive Waiting

This is the most fundamental difference between Kairo and every other tool.

Traditional AI assistants are reactive — you ask, they respond; you don't ask, they're silent. Heartbeat inverts this completely: Kairo has a continuously-running background scheduling engine that proactively scans information, organizes output, and delivers to your IM on your rhythm.

```
07:00  → Read Feishu calendar, compile today's schedule → write 02_work/calendar.md
07:10  → Read Gmail, organize important emails → write 02_work/gmail.md
07:10  → Morning briefing: schedule + overdue tasks + email digest → push to Telegram
09:00  → "You said you'd confirm the contract with Jason today — now's a good time"
20:30  → "3 things this week still unfinished — want me to reschedule them?"
Periodic → Heartbeat scans HEARTBEAT.md, proactively handles pending items
```

You don't need to open any app. Kairo shows up when you need it.

### 3. Hub Context Injection → AI That Actually Knows You

Every time you message Kairo, it's not talking to a blank AI. The system automatically injects **9 information sources** into the LLM context, so your secretary already knows your full picture before responding:

```
┌─────────────────────────────────────────────────────────┐
│  Today / Yesterday's log  ← Recent actions & thoughts   │
│  Open tasks               ← tasks_master.md (8 lines)   │
│  Today's emails           ← Gmail + mailbox auto-digest  │
│  Today's schedule         ← Feishu calendar sync         │
│  Long-term roadmap        ← Your quarterly goals         │
│  Watching                 ← waiting.md follow-up items   │
│  Recent monthly digest    ← Last 2 months compressed     │
│  Relevant contacts        ← People cards (people/)       │
│  Decision wisdom          ← 7 thinkers' frameworks       │
└─────────────────────────────────────────────────────────┘
```

When you say "help me think about how to reply to Jason," Kairo already knows who Jason is, what you last discussed, and your current situation and goals.

### 4. Complete Task Loop → Solves Pile-Up

Most tools stop at "capture." Kairo's loop extends from capture all the way to completion, with no manual management required:

```
You speak
  │
  ▼
Intent recognition (Capture Agent)
  │  type=timeline, due=tomorrow 10:00
  ▼
Task card created (tasks/XXXXX_contract-check.md)
  │
  ▼
Cron auto-scheduled (triggers tomorrow 09:50)
  │
  ▼
Time arrives → Heartbeat proactive push
  │  "You said you'd confirm the contract with Jason — now's the time"
  ▼
You confirm done → LLM auto-updates card status:done
  │
  ▼
tasks_master.md auto-marked [x]
```

Every task with a deadline — from the moment of capture, Kairo has already arranged all the follow-up actions in the background.

### 5. Email + Calendar Integration → Solves Information Silos

Kairo uses cron jobs to pull external data and writes it to the local filesystem, ready for Hub Context injection into every conversation. You don't need to check your email — your secretary will proactively surface relevant information in conversation:

| Source                   | Integration                     | Update Time  | Output File           |
| ------------------------ | ------------------------------- | ------------ | --------------------- |
| Gmail                    | OAuth Pub/Sub webhook           | Daily 07:10  | `02_work/gmail.md`    |
| Feishu personal calendar | OAuth user token + auto-refresh | Daily 07:00  | `02_work/calendar.md` |
| Outlook / 163 / QQ Mail  | IMAP (auto-detect domain)       | Configurable | `02_work/*-mail.md`   |

Adding a new mailbox requires no code changes — `hub-context.ts` auto-scans all `*-mail.md` files.

### 6. Local Markdown + Self-Hosted → Solves Data Sovereignty

All information is stored as Markdown files on your local machine. Structured, human-readable, never locked in. Even if Kairo stopped being maintained tomorrow, all your data would remain complete and usable:

```
~/.openclaw/workspace/automation/assistant_hub/
├── 00_inbox/              ← All raw inputs, never deleted
├── 02_work/
│   ├── tasks/             ← Task cards (one Markdown file per task)
│   ├── tasks_master.md    ← Task index ([ ] open / [x] done)
│   ├── waiting.md         ← Follow-up list (with checkpoint dates)
│   ├── calendar.md        ← Daily schedule (Feishu 07:00 auto-sync)
│   └── gmail.md           ← Email digest (daily 07:10 auto-write)
├── 03_life/
│   └── daily_logs/        ← Daily memory (LLM auto-compiled, YYYY-MM-DD.md)
└── 04_knowledge/
    ├── people/            ← Contact cards (auto-created & updated in conversation)
    ├── beliefs/           ← Decision wisdom (Naval/Munger/Dalio and 4 others)
    ├── roadmap.md         ← Long-term roadmap (LLM auto-updates)
    └── monthly_digest/    ← Monthly memory compression (auto-generated 1st of month)
```

---

## Architecture

```
Kairo-KenVersion/
├── src/
│   ├── auto-reply/         ← Core AI reply engine
│   │   └── reply/
│   │       ├── maybe-run-capture.ts    ← Capture Agent (intent recognition, cron scheduling)
│   │       ├── hub-context.ts          ← Hub Context injection (9 sources)
│   │       └── dispatch-from-config.ts ← Message routing & capture alsoReply mode
│   ├── cron/               ← Cron engine
│   │   ├── global-cron.ts  ← CronService singleton
│   │   └── bootstrap-jobs.ts           ← Ensures morning briefing jobs exist on startup
│   ├── gateway/            ← Multi-channel gateway (Telegram · Feishu · Discord · Slack)
│   │   └── server-cron.ts  ← Register CronService + start bootstrap jobs
│   └── infra/              ← Heartbeat proactive delivery · system events
│       ├── heartbeat-runner.ts         ← Heartbeat scan engine
│       └── system-events.ts            ← System event queue
├── scripts/capture/        ← Data collection scripts
│   ├── gmail-digest.ts     ← Gmail digest (daily 07:10)
│   ├── feishu-calendar.ts  ← Feishu calendar sync (daily 07:00)
│   ├── outlook-digest.ts   ← IMAP generic email digest (Outlook/163/QQ)
│   ├── watch-checker.ts    ← Follow-up check (daily 08:00)
│   └── stale-checker.ts    ← Overdue task scan (daily 20:30)
├── extensions/feishu/      ← Feishu channel plugin (full implementation, WebSocket mode)
├── ui/                     ← Control console Web UI (Lit + Vite)
├── QUICKSTART.md           ← Full setup guide
└── docs/                   ← Detailed documentation
```

---

## Further Reading

- 📖 [QUICKSTART.md](./QUICKSTART.md) — 7-step full setup: systemd, Gmail OAuth, Feishu Calendar
- 🔧 [systemd Production Service](./QUICKSTART.md)
- 📧 [Gmail OAuth Integration](./QUICKSTART.md)
- 📅 [Feishu Calendar OAuth Integration](./QUICKSTART.md)
- 🤖 [Model Selection & Configuration](./QUICKSTART.md)

---

## Supported Channels

| Channel       | Status     | Notes                            |
| ------------- | ---------- | -------------------------------- |
| Telegram      | ✅ Stable  | Recommended, most mature         |
| Feishu / Lark | ✅ Stable  | WebSocket, no public IP required |
| Discord       | ✅ Stable  |                                  |
| Slack         | ✅ Stable  |                                  |
| WhatsApp      | 🚧 Beta    |                                  |
| WeChat        | 🚧 Planned |                                  |

---

## Roadmap

> **"Every AI tool is something you use. Kairo's direction is to become infrastructure you depend on."**

What's the difference? When you use a tool, it's off when you're not using it. When you depend on infrastructure, it keeps running for you whether you're there or not.

**A phone is a tool. The power grid is infrastructure.**

Every existing AI — ChatGPT, Claude, Notion AI, every agent framework — is fundamentally a phone: you dial, someone answers; you hang up, the connection drops. No matter how smart, it only has value when you actively call.

Kairo aims to be the power grid: **a personal AI coordination layer running persistently on your server**. It processes email digests while you sleep, tracks deadlines while you're in meetings, and reminds you of that thing you forgot three days ago when you're distracted.

---

### Verified Core Assumptions

Kairo v0.9 is running in Ken's production environment. Three key things have been verified:

1. **Proactive delivery works** — The 07:10 morning briefing arrives reliably to Telegram every day. Ken does nothing.
2. **Complete loop works** — Say something → card auto-created → auto-scheduled → proactively reminded at the right time → LLM auto-updates status. Zero manual intervention throughout.
3. **Persistent context works** — Every conversation, Kairo already knows today's calendar, open tasks, and relevant contacts — without you re-introducing yourself.

Together these mean: **an AI secretary that comes to you already exists and is running.**

The question now isn't "can this be done?" — it's "how far can it go?"

---

### The Transformation Path

Each Phase is not "adding a feature" — it's a crossing point: **previously impossible, then taken for granted**:

```
Phase 0 ✅  You don't need to remember to check  → AI proactively finds you for the first time
Phase 1 🔄  Information comes to you             → Researchers no longer manage information flow
Phase 2     Your context is everywhere           → Every AI tool knows who you are
Phase 3     Entire tasks can be delegated        → You become the approver, not the executor
Phase 4     Anyone can have this                 → Private AI secretary is no longer a tech privilege
Phase 5     It starts improving itself           → A partner that knows you better over time, not a tool
```

---

#### ✅ Phase 0 — You Don't Need to Remember to Check

**Problem**: Todo apps wait for you to open them. Calendars wait for you to check. Emails wait for you to refresh. Every tool is waiting. If you forget to open it, nothing happens.

**Breakthrough Moment**: The first time you receive the right information at the right time without actively checking anything.

**Completed**:

- Heartbeat proactive delivery (07:10 morning briefing / deadline reminders / 20:30 overdue scan)
- Capture Agent: 10 intent types auto-classified into cards, confidence ≥ 85% silent processing
- Complete task loop: say something → card → schedule → remind → auto-update status, fully automatic
- Hub Context: 9 information sources injected every conversation (calendar / email / tasks / contacts / decision wisdom)
- Gmail + Feishu Calendar auto-sync, silent daily update at 07:00

---

#### 🔄 Phase 1 — Information Comes to You

**Problem**: Knowledge workers spend enormous time "managing information flow" — actively searching arXiv, organizing experiment results, tracking field developments. These actions create no thinking value, yet consume massive attention.

**Breakthrough Moment**:

> At 7:15 AM, today's relevant new papers appear in your Telegram — already translated, already annotated with their relevance to your research. You searched for nothing.
>
> You say "deep-research Video World Models for me" — a complete report is written to your knowledge base 3 minutes later.
>
> After running experiments, Kairo automatically compares all historical results and tells you "Exp-C is 2.3% better than Exp-A, possible reason: ..."

**Core Capabilities**:

| Capability                                                         | World after completion                                                                |
| ------------------------------------------------------------------ | ------------------------------------------------------------------------------------- |
| arXiv daily monitoring + LLM-curated push                          | New field developments appear in front of you — you just decide what's worth reading  |
| `research_deep` LLM tool (native TypeScript, no external services) | One sentence triggers deep research, report written to `04_knowledge/research_notes/` |
| Experiment tracking (`experiment_log` / `experiment_compare`)      | Every experiment auto-logged, anomalies auto-flagged, trends proactively reported     |
| Docker one-click deploy                                            | `docker compose up`, lower the barrier to getting started                             |

---

#### Phase 2 — Your Context Is Everywhere

**Problem**: You use 5 AI tools and none of them know you. Your deadlines are in Kairo but Claude Desktop doesn't know; your research direction is here but GPT-4 doesn't know. **You're the employer of 5 strangers who need a full re-introduction every single conversation.**

**Breakthrough Moment**:

> Open Claude Desktop — it already knows your tasks, deadlines, and what you're tracking. You didn't tell it — Kairo is in the background, using MCP protocol to make your context ubiquitous.

**Core Capabilities**:

| Capability       | World after completion                                                                                        |
| ---------------- | ------------------------------------------------------------------------------------------------------------- |
| Kairo MCP Server | Your calendar / tasks / people become a standard interface any AI tool can read                               |
| MCP Client       | Kairo calls community MCP servers (GitHub / web search), no reinventing the wheel                             |
| Self-Improving   | Weekly analysis of own judgment errors → auto-update behavioral patterns, system gets more accurate over time |

---

#### Phase 3 — Entire Tasks Can Be Delegated

**Problem**: The best result today is "AI helps you with one step." Help you research, you still have to synthesize; help you write a draft, you still have to feed content; help you analyze, you still have to conclude. Every time it's linear, not multiplicative.

**Breakthrough Moment**:

> You say: "Prepare this week's group meeting slides — topic: latest advances in Video Understanding."
>
> Three hours later, a ready-to-use slide draft is delivered to your Telegram. You did nothing — just said one sentence.

**Core Capabilities**:

| Capability                                                   | World after completion                                                                                               |
| ------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------- |
| Swarm orchestration layer (OpenAI Agents SDK / agency-swarm) | Kairo as orchestrator, decomposes and delegates to Research / Code / Writing specialist agents                       |
| Bounded Autonomy                                             | High-risk operations (send email / delete files / commit code) require your confirmation; everything else autonomous |
| Audit Trail                                                  | All agent actions written to `audit.jsonl`, full replayability at any time                                           |

---

#### Phase 4 — Anyone Can Have This

**Problem**: Data directory currently hardcoded to `/opt/LazyingArtBot/`, requires root access. **No technical background means no deployment. Private AI secretary has become a tech privilege.**

**Breakthrough Moment**:

> A non-technical user runs `./install.sh` and in 5 minutes has a personal AI secretary running on their own machine — data fully private, zero subscription fee.

**Core Capabilities**:

- Remove root dependency, `$KAIRO_HOME` configurable (**current top priority, blocking public release**)
- `install.sh` + AI-guided interactive setup
- `openclaw.example.json` complete template + GitHub Release v1.0

```
./install.sh

[1/5] Checking dependencies (Node 22+)... ✅
[2/5] Choose channel: Telegram / Feishu / Both? > Telegram
[3/5] Paste Bot Token: > 1234567890:ABC...
[4/5] Choose model: OpenAI / Anthropic / Local Ollama? > OpenAI
[5/5] Generating config + starting service... ✅

Send @YourBot a message: "Remind me tomorrow morning to reply to Jason"
```

---

#### Phase 5 — It Starts Improving Itself (Long-term Vision)

> **At this point, Kairo is not "a tool I use" — it's "a partner that knows me better over time."**

- **Self-Improving** (deepened from Phase 2): weekly analysis of judgment errors → update rules → more accurate next time
- **Computer Use**: not just text suggestions — directly operates browser to complete tasks (fill forms, download reports, web interactions)
- **Relationship Graph**: contact cards upgrade to network graph, automatically discovers "Jason and Tom are both in AI education — worth introducing"
- **Long-term Memory**: monthly compression → annual highlights, every thought you accumulate never fades with memory
- **Cross-device Context**: phone / laptop / server, same Kairo context everywhere

---

### Community Projects to Integrate

| Project                                                                                 | Purpose                                        | Phase |
| --------------------------------------------------------------------------------------- | ---------------------------------------------- | :---: |
| [SakanaAI/AI-Scientist-v2](https://github.com/SakanaAI/AI-Scientist-v2)                 | Autonomous paper generation pipeline reference |   1   |
| [SamuelSchmidgall/AgentLaboratory](https://github.com/SamuelSchmidgall/AgentLaboratory) | Literature → experiment → writing pipeline     |   1   |
| [openai/openai-agents-python](https://github.com/openai/openai-agents-python)           | Official Swarm successor framework             |   3   |
| [VRSEN/agency-swarm](https://github.com/VRSEN/agency-swarm)                             | Multi-agent execution layer alternative        |   3   |
| [browser-use/browser-use](https://github.com/browser-use/browser-use)                   | Browser automation capability                  |   5   |

---

## Community & Team

### About Kairo

Kairo is a personal AI secretary system built by **Ken** from his own needs, developed over several months, built on top of the open-source [OpenClaw](https://github.com/openclaw/openclaw) project.

The core motivation: in the age of AI tool explosion, Ken found himself spending more and more time _managing tools_ rather than _completing work_. Kairo's goal is to make AI a true secretary — not a tool that waits for questions, but a partner that understands your full situation and shows up proactively at the right moment.

**Kairo's evolution timeline:**

- **Early 2025**: Built Telegram multi-channel foundation on OpenClaw gateway
- **Mid 2025**: Implemented Capture Agent with 10-intent auto-classification
- **Late 2025**: Built Heartbeat proactive delivery system — true "proactive secretary"
- **Early 2026**: Integrated Gmail + Feishu Calendar; Hub Context 9-source injection; contact memory and decision wisdom framework live
- **2026 (ongoing)**: v1 stabilization, planning public-friendly release

---

### Join the Community

Kairo is currently in personal production use, with much to refine and explore. We welcome every developer passionate about "proactive AI secretaries":

- Give us a **Star** — it means a lot
- Run it on your machine via [**QUICKSTART.md**](./QUICKSTART.md) and share real feedback
- Join the community:
  - 💬 **WeChat Group**: Add WeChat with note "Kairo" → [QR code](#)
  - 🎮 **Discord**: [Join Discord server](#)
  - 🐦 **X (Twitter)**: [Follow for updates](#)
- **Contribute**: Bug fixes, new intent types, new channel adapters — every line of code is part of Kairo's growth

---

### Star History

[![Star History Chart](https://api.star-history.com/svg?repos=sou350121/Kairo-KenVersion&type=timeline&legend=top-left)](https://www.star-history.com/#sou350121/Kairo-KenVersion&type=timeline&legend=top-left)

---

## 🤖 AI-Assisted Development (Cursor · Claude Code · ChatGPT)

Kairo provides out-of-the-box context prompts for popular AI coding tools — they activate automatically after cloning:

| Tool                 | Config File                                                            | Notes                                                   |
| -------------------- | ---------------------------------------------------------------------- | ------------------------------------------------------- |
| **Claude Code**      | [`CLAUDE.md`](./CLAUDE.md)                                             | Auto-loaded: architecture, key files, common tasks      |
| **Cursor**           | [`.cursorrules`](./.cursorrules)                                       | Auto-loaded: directory structure, conventions, pitfalls |
| **GitHub Copilot**   | [`.github/copilot-instructions.md`](./.github/copilot-instructions.md) | Auto-loaded                                             |
| **ChatGPT / Others** | Manually paste `CLAUDE.md` content                                     | Copy into system prompt or first message                |

No extra setup needed after cloning — open the project and you have an AI coding assistant that already understands Kairo's architecture.

---

## Acknowledgements

Kairo is built on **[OpenClaw](https://github.com/openclaw/openclaw)**. Thanks to the OpenClaw team for providing a solid multi-channel AI gateway foundation.

Special thanks to **[LazyingArtBot](https://github.com/lachlanchen/LazyingArtBot)** — Kairo's predecessor and source of inspiration. The real-world experience, hard-learned lessons, and patterns discovered in LazyingArtBot gave birth to Kairo today. Without LazyingArtBot, there would be no Kairo.

---

## License

This project is licensed under the MIT License — see [LICENSE](./LICENSE)

<!-- Link definitions -->

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
