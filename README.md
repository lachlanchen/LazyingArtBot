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

---

## Orchestral philosophy

LAB orchestration follows one design rule:
break difficult goals into deterministic execution + focused prompt-tool chains.

- Deterministic scripts handle reliable plumbing:
  scheduling, file routing, run directories, retries, and output handoff.
- Prompt tools handle adaptive intelligence:
  planning, triage, context synthesis, and decision-making under uncertainty.
- Every stage emits reusable artifacts so downstream tools can compose stronger final notes/email without starting from zero.

Core orchestral chains:

- Company entrepreneurship chain:
  company context ingestion → market/funding/academic/legal intelligence → concrete growth actions.
- Auto mail chain:
  inbound mail triage → conservative skip policy for low-value mail → structured Notes/Reminders/Calendar actions.
- Web search chain:
  results-page capture → targeted deep reads with screenshot/content extraction → evidence-backed synthesis.

---

## Prompt tools in LAB

Prompt tools are modular, composable, and orchestration-first.
They can run independently or as linked stages in a larger workflow.

- Read/save operations:
  create and update Notes, Reminders, and Calendar outputs for AutoLife operations.
- Screenshot/read operations:
  capture search pages and linked pages, then extract structured text for downstream analysis.
- Tool-connection operations:
  call deterministic scripts, exchange artifacts across stages, and maintain context continuity.

Primary location:

- `scripts/prompt_tools/`

---

## LAB ecosystem integrations

LAB integrates my broader AI product and research repos into one operating layer for creation, growth, and automation.

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
