[English](README.md) · [العربية](i18n/README.ar.md) · [Español](i18n/README.es.md) · [Français](i18n/README.fr.md) · [日本語](i18n/README.ja.md) · [한국어](i18n/README.ko.md) · [Tiếng Việt](i18n/README.vi.md) · [中文 (简体)](i18n/README.zh-Hans.md) · [中文（繁體）](i18n/README.zh-Hant.md) · [Deutsch](i18n/README.de.md) · [Русский](i18n/README.ru.md)


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
> Note: `i18n/` exists and currently includes Arabic. Additional localized README variants are handled one-by-one to keep content consistent with source updates.

**LazyingArtBot** is my personal AI assistant stack for **lazying.art**.  
It is built on top of OpenClaw and adapted for my own daily workflows: multi-channel chat, local-first control, and email → calendar/reminder/notes automation.

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

LAB focuses on practical personal productivity:

- Run one assistant across chat channels you already use.
- Keep data and control on your own machine/server.
- Convert incoming email into structured actions (Calendar, Reminders, Notes).
- Add guardrails so automation is useful but still safe.

In short: less busywork, better execution.

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

- Multi-channel assistant runtime (Gateway + agent sessions).
- Web dashboard / web chat control surface.
- Tool-enabled agent workflows (shell, files, automation scripts).
- Email automation pipeline for personal operations:
  - parse inbound mail
  - classify action type
  - save to Notes / Reminders / Calendar
  - log every action for review and debugging

---

## 🧱 Project structure

High-level repository layout:

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

Notes:

- `scripts/prompt_tools` points to orchestral prompt-tool implementation.
- Root `i18n/` exists and is currently minimal in this snapshot; localized docs primarily live under `docs/`.

---

## 📋 Prerequisites

Runtime and tooling baselines from this repository:

- Node.js `>=22.12.0`
- pnpm `10.23.0` baseline (see `packageManager` in `package.json`)
- A configured model provider key (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, etc.)
- Optional: Docker + Docker Compose for containerized gateway/CLI

Optional global CLI install (matches quick-start flow):

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## 🚀 Quick start

Runtime baseline in this repo: **Node >= 22.12.0** (`package.json` engine).

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

A `docker-compose.yml` is included with:

- `openclaw-gateway`
- `openclaw-cli`

Typical flow:

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

Note: mount paths and ports are controlled by compose variables like `OPENCLAW_CONFIG_DIR`, `OPENCLAW_WORKSPACE_DIR`, `OPENCLAW_GATEWAY_PORT`, and `OPENCLAW_BRIDGE_PORT`.

---

## 🛠️ Usage

Common commands:

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

Dev loop (watch mode):

```bash
pnpm gateway:watch
```

UI development:

```bash
pnpm ui:dev
```

---

## 🔐 Configuration

Environment and config reference is split between `.env` and `~/.openclaw/openclaw.json`.

1. Start from `.env.example`.
2. Set gateway auth (`OPENCLAW_GATEWAY_TOKEN` recommended).
3. Set at least one model provider key (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, etc.).
4. Only set channel credentials for channels you enable.

Important `.env.example` notes preserved from repo:

- Env precedence: process env → `./.env` → `~/.openclaw/.env` → config `env` block.
- Existing non-empty process env values are not overridden.
- Config keys such as `gateway.auth.token` can take precedence over env fallbacks.

Security-critical baseline before internet exposure:

- Keep gateway auth/pairing enabled.
- Keep allowlists strict for inbound channels.
- Treat every inbound message/email as untrusted input.
- Run with least privilege and review logs regularly.

If you expose the gateway to the internet, require token/password auth and trusted proxy config.

---

## 🧩 LazyingArt workflow focus

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

## 🎼 Orchestral philosophy

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

## 🧰 Prompt tools in LAB

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

- Runtime baseline: Node `>=22.12.0`.
- Package manager baseline: `pnpm@10.23.0` (`packageManager` field).
- Common quality gates:

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- CLI in dev: `pnpm openclaw ...`
- TS run loop: `pnpm dev`
- UI package commands are proxied via root scripts (`pnpm ui:build`, `pnpm ui:dev`).

---

## 🩺 Troubleshooting

### Gateway not reachable on `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

Check for port collisions and daemon conflicts. If using Docker, verify mapped host port and service health.

### Auth or channel config issues

- Re-check `.env` values against `.env.example`.
- Ensure at least one model key is configured.
- Verify channel tokens only for channels you actually enabled.

### General health checks

Use `openclaw doctor` to detect migration/security/config drift issues.

---

## 🌐 LAB ecosystem integrations

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

Planned directions for this LAB fork (working roadmap):

- Expand automail reliability with stricter sender/rule classification.
- Improve orchestral stage composability and artifact traceability.
- Strengthen mobile-first operations and remote gateway management UX.
- Deepen integrations with LAB ecosystem repos for end-to-end automated production.
- Continue hardening security defaults and observability for unattended automation.

---

## 🤝 Contributing

This repository tracks personal LAB priorities while inheriting core architecture from OpenClaw.

- Read [`CONTRIBUTING.md`](CONTRIBUTING.md)
- Review upstream docs: https://docs.openclaw.ai
- For security issues, see [`SECURITY.md`](SECURITY.md)

If uncertain about LAB-specific behavior, preserve existing behavior and document assumptions in PR notes.

---

## ❤️ Support / Sponsor

If LAB helps your workflow, support ongoing development:

- GitHub Sponsors: https://github.com/sponsors/lachlanchen
- Donate page: https://chat.lazying.art/donate
- Website: https://lazying.art

---

## 🙏 Acknowledgements

LazyingArtBot is based on **OpenClaw**:

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

Thanks to the OpenClaw maintainers and community for the core platform.

---

## 📄 License

MIT (same as upstream where applicable). See `LICENSE`.
