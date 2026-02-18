<p align="center">
  <img src="https://github.com/lachlanchen/lachlanchen/raw/main/figs/banner.png" alt="LazyingArtBot banner" />
</p>

# 🐼 LazyingArtBot (LAB)

**LazyingArtBot** is my personal AI assistant stack for **lazying.art**.
It is built on top of OpenClaw and adapted for my own daily workflows: multi-channel chat, local-first control, and email → calendar/reminder/notes automation.

- Website: https://lazying.art
- Bot domain: https://lazying.art
- Upstream base: https://github.com/openclaw/openclaw
- This repo: https://github.com/lachlanchen/LazyingArtBot

---

## What LAB is for

LAB focuses on practical personal productivity:

- Run one assistant across chat channels you already use.
- Keep data and control on your own machine/server.
- Convert incoming email into structured actions (Calendar, Reminders, Notes).
- Add guardrails so automation is useful but still safe.

In short: less busywork, better execution.

### Who is this for?

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   Knowledge workers whose minds run faster than their hands │
│                                                             │
│   · Tracking 5-15 directions simultaneously                  │
│     (research / projects / relationships / self)            │
│   · Lots of fragmented time, little deep work time          │
│   · Ideas come quickly, disappear even faster               │
│   · Hate formatting, but regret not recording later         │
│   · Believe "System > Willpower"                            │
│                                                             │
│   Current pain points:                                      │
│   Thought of it ──→ Didn't record ──→ Gone                  │
│   Recorded  ──→ Didn't organize ──→ Dead in notes          │
│   Organized ──→ Didn't follow up ──→ Forever in TODO       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Typical Behavior Patterns:**

```
Coffee Shop          Office               Before Bed
─────────            ─────────            ─────────
Saw a paper          After meeting        Mind racing
  ↓                    ↓                    ↓
Want to save it      Need to follow up    Many things undone
  ↓                    ↓                    ↓
Too lazy for Notion  Forgot to record     Anxious, can't sleep
  ↓                    ↓                    ↓
Telegram myself      Remember next meeting Rely on memory
```

---

## Core capabilities

- Multi-channel assistant runtime (Gateway + agent sessions).
- Web dashboard / web chat control surface.
- Tool-enabled agent workflows (shell, files, automation scripts).
- Email automation pipeline for personal operations:
  - parse inbound mail
  - classify action type
  - save to Notes / Reminders / Calendar
  - log every action for review and debugging

### How it works: Input → Processing → Storage

**INPUT Layer - Capture from anywhere:**

```
[User's World]

  🗣  Voice         📝  Text          📸  Image         🎬  Video
  ─────────        ─────────        ─────────        ─────────
  "I think this    "Paper seen,     Screenshot /     Video demo +
   direction is     deadline 3/15    photo of         voice explanation
   interesting"     → task"          whiteboard

  Colloquial/      Multi-line/       4 subtypes       Screen + audio
  pause words      mixed Chinese     OCR/semantic     Timeline markers
  Emotional cues   Hard command detect description

                  ↓  ↓  ↓  ↓
            ┌──────────────────────┐
            │   Telegram / Feishu   │
            │   (LAB Gateway)       │
            └──────────┬───────────┘
                       │
                       ▼
```

---

## Quick start

Runtime: **Node >= 22**

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

Then open the local dashboard and chat:

- http://127.0.0.1:18789

For remote access, expose your local gateway through your own secure tunnel (for example ngrok/Tailscale) and keep authentication enabled.

---

## LazyingArt workflow focus

This fork prioritizes my personal flow at **lazying.art**:

- custom branding (LAB / panda theme)
- mobile-friendly dashboard/chat experience
- automail pipeline variants (rule-triggered, codex-assisted save modes)
- personal cleanup and sender-classification scripts
- notes/reminders/calendar routing tuned for real daily use

Automation workspace (local):

- `~/.openclaw/workspace/automation/`
- Script references in repo: `references/lab-scripts-and-philosophy.md`
- Dedicated Codex prompt tools: `scripts/prompt_tools/`

### System Architecture

**BRAIN · Capture Agent Inference Layer:**

```
┌─────────────────────────────────────────────────────────────────────┐
│                     CAPTURE AGENT (Inference Core)                   │
│                                                                     │
│  ① Multimodal Preprocessing                                          │
│     Voice transcription  │  Image subtype 判断  │  Video timeline     │
│                                                                     │
│  ② Merge Judgment                                                    │
│     Same media_group_id? ──→ Must merge                             │
│     Highly consistent semantics? ──→ append_existing                │
│     Uncertain? ──→ New + possible_duplicate                         │
│                                                                     │
│  ③ Intent Inference (10 types)                                       │
│     action / timeline / watch / idea / question /                   │
│     belief / memory / highlight / reference / person                │
│                                                                     │
│  ④ Confidence Governance                                             │
│     ≥ 0.85  ──→ Structured card, hide menu                          │
│     0.65~   ──→ Structured card, show menu                          │
│     < 0.65  ──→ Only daily_log, no independent card                 │
│                                                                     │
│  ⑤ Time Structure Detection                                          │
│     Has deadline + No task command ──→ watch + remind_schedule      │
│                                                                     │
└──────────────────────────┬──────────────────────────────────────────┘
                           │
                           ▼
```

**STORAGE · assistant_hub File System:**

```
assistant_hub/
│
├── 00_inbox/          ◀─── All original text, never deleted
│   └── 2026-02-18_telegram_inbox.md
│
├── 02_work/           ◀─── Action Layer
│   ├── tasks/         ·  ⚡ action cards
│   ├── projects/      ·  📍 timeline cards
│   ├── waiting.md     ·  👀 watch summary (with checkpoints)
│   ├── today.md       ·  Today's tasks (Cron auto-merge)
│   ├── calendar.md    ·  Weekly/Monthly calendar (Cron daily rebuild)
│   ├── tasks_master.md·  action index
│   └── done.md        ·  Completion archive
│
├── 03_life/           ◀─── Life Layer
│   ├── daily_logs/    ·  📝 memory (by day)
│   ├── ideas/         ·  💡 idea cards
│   └── highlights/    ·  ✨ highlight cards
│
├── 04_knowledge/      ◀─── Knowledge Layer
│   ├── references/    ·  📖 Papers/materials/URLs
│   └── questions/     ·  ❓ Cognitive gaps (AI research orders)
│
└── 05_meta/           ◀─── System Itself
    ├── reasoning_queue.jsonl      Capture→Reasoning interface
    ├── feedback_signals.jsonl     All feedback events
    └── capture_agent_weekly_review.md  Self-reflection output
```

---

## Security baseline

Before enabling broad automation:

- Keep gateway auth/pairing enabled.
- Keep allowlists strict for inbound channels.
- Treat every inbound message/email as untrusted input.
- Run with least privilege and review logs regularly.

If you expose the gateway to the internet, require token/password auth and trusted proxy config.

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

## Support / Sponsor

If LAB helps your workflow, support ongoing development:

- GitHub Sponsors: https://github.com/sponsors/lachlanchen
- Donate page: https://chat.lazying.art/donate
- Website: https://lazying.art

---

## Acknowledgements

LazyingArtBot is based on **OpenClaw**:

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

Thanks to the OpenClaw maintainers and community for the core platform.

---

## License

MIT (same as upstream where applicable). See `LICENSE`.
