[English](README.md) · [العربية](i18n/README.ar.md) · [Español](i18n/README.es.md) · [Français](i18n/README.fr.md) · [日本語](i18n/README.ja.md) · [한국어](i18n/README.ko.md) · [Tiếng Việt](i18n/README.vi.md) · [中文 (简体)](i18n/README.zh-Hans.md) · [中文（繁體）](i18n/README.zh-Hant.md) · [Deutsch](i18n/README.de.md) · [Русский](i18n/README.ru.md)




[![LazyingArt banner](https://github.com/lachlanchen/lachlanchen/raw/main/figs/banner.png)](https://github.com/lachlanchen/lachlanchen/blob/main/figs/banner.png)

# 🐼 LazyingArtBot (LAB)

[![License: MIT](https://img.shields.io/badge/License-MIT-1f6feb.svg)](LICENSE)
[![Node >= 22.12.0](https://img.shields.io/badge/Node-%3E%3D22.12.0-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![pnpm workspace](https://img.shields.io/badge/pnpm-workspace-F69220?logo=pnpm&logoColor=white)](pnpm-workspace.yaml)
[![Upstream: openclaw/openclaw](https://img.shields.io/badge/upstream-openclaw%2Fopenclaw-111827?logo=github)](https://github.com/openclaw/openclaw)
[![Gateway Default Port](https://img.shields.io/badge/Gateway-18789-0ea5e9)](#quick-start)
[![Version](https://img.shields.io/badge/version-2026.2.10-16a34a)](package.json)
[![i18n README](https://img.shields.io/badge/i18n-10_languages-8b5cf6)](i18n)
[![Docs](https://img.shields.io/badge/docs-Mintlify-06b6d4)](docs)
[![GitHub stars](https://img.shields.io/badge/GitHub-stars-0ea5e9?logo=github&logoColor=white)](https://github.com/lachlanchen/LazyingArtBot/stargazers)
[![GitHub issues](https://img.shields.io/badge/GitHub-issues-ef4444?logo=github&logoColor=white)](https://github.com/lachlanchen/LazyingArtBot/issues)

> 🌍 **i18n status:** `i18n/` exists and currently includes localized README files for Arabic, German, Spanish, French, Japanese, Korean, Russian, Vietnamese, Simplified Chinese, and Traditional Chinese. This English draft remains the canonical source for incremental updates.

**LazyingArtBot** is my personal AI assistant stack for **lazying.art**:

**LazyingArtBot** is built on top of OpenClaw and adapted for my daily workflows: multi-channel chat, local-first control, and email → calendar/reminder/notes automation.

| 🔗 Link | URL | Focus |
| --- | --- | --- |
| 🌐 Website | https://lazying.art | Primary domain and status dashboard |
| 🤖 Bot domain | https://lazying.art | Chat and assistant entrypoint |
| 🧱 Upstream base | https://github.com/openclaw/openclaw | OpenClaw platform foundation |
| 📦 This repo | https://github.com/lachlanchen/LazyingArtBot | LAB-specific adaptations |

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
- [Acknowledgements](#acknowledgements)
- [❤️ Support](#-support)
- [Contact](#contact)
- [License](#license)

---

## Overview

LAB focuses on practical personal productivity:

- ✅ Run one assistant across chat channels you already use.
- 🔐 Keep data and control on your own machine/server.
- 📬 Convert incoming email into structured actions (Calendar, Reminders, Notes).
- 🛡️ Add guardrails so automation is useful but still safe.

In short: less busywork, better execution.

---

## At a glance

| Area | Current baseline in this repo |
| --- | --- |
| Runtime | Node.js `>=22.12.0` |
| Package manager | `pnpm@10.23.0` |
| Core CLI | `openclaw` |
| Default local gateway | `127.0.0.1:18789` |
| Default bridge port | `127.0.0.1:18790` |
| Primary docs | `docs/` (Mintlify) |
| Primary LAB orchestration | `orchestral/` + `scripts/prompt_tools/` |
| README i18n location | `i18n/README.*.md` |

---

## Features

- 🌐 Multi-channel assistant runtime with a local gateway.
- 🖥️ Browser dashboard/chat surface for local operations.
- 🧰 Tool-enabled automation pipeline (scripts + prompt-tools).
- 📨 Email triage and conversion into Notes, Reminders, and Calendar actions.
- 🧩 Plugin/extension ecosystem (`extensions/*`) for channels/providers/integrations.
- 📱 Multi-platform surfaces in-repo (`apps/macos`, `apps/ios`, `apps/android`, `ui`).

---

## Core capabilities

| Capability | What it means in practice |
| --- | --- |
| Multi-channel assistant runtime | Gateway + agent sessions across channels you enable |
| Web dashboard / chat | Browser-based control surface for local operations |
| Tool-enabled workflows | Shell + file + automation script execution chains |
| Email automation pipeline | Parse mail, classify action type, route to Notes/Reminders/Calendar, log actions for review/debugging |

Pipeline steps preserved from current workflow:

- parse inbound mail
- classify action type
- save to Notes / Reminders / Calendar
- log every action for review and debugging

---

## Project structure

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
├─ i18n/                # localized README files
├─ .env.example         # environment template
├─ docker-compose.yml   # gateway + CLI containers
├─ README_OPENCLAW.md   # larger upstream-style reference README
└─ README.md            # this LAB-focused README
```

Notes:

- `scripts/prompt_tools` points to orchestral prompt-tool implementation.
- Root `i18n/` contains localized README variants.
- `.github/workflows.disabled/` is present in this snapshot; active CI behavior should be verified before relying on workflow assumptions.

---

## Prerequisites

Runtime and tooling baselines from this repository:

- Node.js `>=22.12.0`
- pnpm `10.23.0` baseline (see `packageManager` in `package.json`)
- A configured model provider key (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, etc.)
- Optional: Docker + Docker Compose for containerized gateway/CLI
- Optional for mobile/mac builds: Apple/Android toolchains depending on target platform

Optional global CLI install (matches quick-start flow):

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## Quick start

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

A `docker-compose.yml` is included with:

- `openclaw-gateway`
- `openclaw-cli`

Typical flow:

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

Compose variables commonly required:

- `OPENCLAW_CONFIG_DIR`
- `OPENCLAW_WORKSPACE_DIR`
- `OPENCLAW_GATEWAY_PORT`
- `OPENCLAW_BRIDGE_PORT`

---

## Usage

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

Additional useful operational commands:

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

Environment and config reference is split between `.env` and `~/.openclaw/openclaw.json`.

1. Start from `.env.example`.
2. Set gateway auth (`OPENCLAW_GATEWAY_TOKEN` recommended).
3. Set at least one model provider key (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, etc.).
4. Only set channel credentials for channels you enable.

Important `.env.example` notes preserved from repo:

- Env precedence: process env -> `./.env` -> `~/.openclaw/.env` -> config `env` block.
- Existing non-empty process env values are not overridden.
- Config keys such as `gateway.auth.token` can take precedence over env fallbacks.

Security-critical baseline before internet exposure:

- Keep gateway auth/pairing enabled.
- Keep allowlists strict for inbound channels.
- Treat every inbound message/email as untrusted input.
- Run with least privilege and review logs regularly.

If you expose the gateway to the internet, require token/password auth and trusted proxy config.

---

## Deployment modes

| Mode | Best for | Typical command |
| --- | --- | --- |
| Local foreground | Development and debugging | `openclaw gateway run --bind loopback --port 18789 --verbose` |
| Local daemon | Everyday personal usage | `openclaw onboard --install-daemon` |
| Docker | Isolated runtime and repeatable deploys | `docker compose up -d` |
| Remote host + tunnel | Access from outside home LAN | Run gateway + secure tunnel, keep auth enabled |

Assumption: production-grade reverse-proxy hardening, secret rotation, and backup policy are deployment-specific and should be defined per environment.

---

## LazyingArt workflow focus

This fork prioritizes my personal flow at **lazying.art**:

- 🎨 custom branding (LAB / panda theme)
- 📱 mobile-friendly dashboard/chat experience
- 📨 automail pipeline variants (rule-triggered, codex-assisted save modes)
- 🧹 personal cleanup and sender-classification scripts
- 🗂️ notes/reminders/calendar routing tuned for real daily use

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
  company context ingestion -> market/funding/academic/legal intelligence -> concrete growth actions.
- Auto mail chain:
  inbound mail triage -> conservative skip policy for low-value mail -> structured Notes/Reminders/Calendar actions.
- Web search chain:
  results-page capture -> targeted deep reads with screenshot/content extraction -> evidence-backed synthesis.

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

Common extended test commands in this repo:

```bash
pnpm test:e2e
pnpm test:live
pnpm test:docker:all
pnpm test:ui
```

Additional dev helpers:

```bash
pnpm docs:dev
pnpm format:check
pnpm lint
pnpm tsgo:test
```

Assumption note:

- Mobile/macOS app build/run commands exist in `package.json` (`ios:*`, `android:*`, `mac:*`) but platform signing/provisioning requirements are environment-specific and not fully documented in this README.

---

## Troubleshooting

### Gateway not reachable on `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

Check for port collisions and daemon conflicts. If using Docker, verify mapped host port and service health.

### Auth or channel config issues

- Re-check `.env` values against `.env.example`.
- Ensure at least one model key is configured.
- Verify channel tokens only for channels you actually enabled.

### Build or install issues

- Re-run `pnpm install` with Node `>=22.12.0`.
- Rebuild with `pnpm ui:build && pnpm build`.
- If optional native peers are missing, review install logs for `@napi-rs/canvas` / `node-llama-cpp` compatibility.

### General health checks

Use `openclaw doctor` to detect migration/security/config drift issues.

### Useful diagnostics

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --deep
```

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

## Install from source (quick reference)

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

## Roadmap

Planned directions for this LAB fork (working roadmap):

- Expand automail reliability with stricter sender/rule classification.
- Improve orchestral stage composability and artifact traceability.
- Strengthen mobile-first operations and remote gateway management UX.
- Deepen integrations with LAB ecosystem repos for end-to-end automated production.
- Continue hardening security defaults and observability for unattended automation.

---

## Contributing

This repository tracks personal LAB priorities while inheriting core architecture from OpenClaw.

- Read [`CONTRIBUTING.md`](CONTRIBUTING.md)
- Review upstream docs: https://docs.openclaw.ai
- For security issues, see [`SECURITY.md`](SECURITY.md)

If uncertain about LAB-specific behavior, preserve existing behavior and document assumptions in PR notes.

---

## Acknowledgements

LazyingArtBot is based on **OpenClaw**:

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

Thanks to the OpenClaw maintainers and community for the core platform.

## ❤️ Support

| Donate | PayPal | Stripe |
| --- | --- | --- |
| [![Donate](https://camo.githubusercontent.com/24a4914f0b42c6f435f9e101621f1e52535b02c225764b2f6cc99416926004b7/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f446f6e6174652d4c617a79696e674172742d3045413545393f7374796c653d666f722d7468652d6261646765266c6f676f3d6b6f2d6669266c6f676f436f6c6f723d7768697465)](https://chat.lazying.art/donate) | [![PayPal](https://camo.githubusercontent.com/d0f57e8b016517a4b06961b24d0ca87d62fdba16e18bbdb6aba28e978dc0ea21/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f50617950616c2d526f6e677a686f754368656e2d3030343537433f7374796c653d666f722d7468652d6261646765266c6f676f3d70617970616c266c6f676f436f6c6f723d7768697465)](https://paypal.me/RongzhouChen) | [![Stripe](https://camo.githubusercontent.com/1152dfe04b6943afe3a8d2953676749603fb9f95e24088c92c97a01a897b4942/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f5374726970652d446f6e6174652d3633354246463f7374796c653d666f722d7468652d6261646765266c6f676f3d737472697065266c6f676f436f6c6f723d7768697465)](https://buy.stripe.com/aFadR8gIaflgfQV6T4fw400) |

## Contact

- Website: https://lazying.art
- Repository: https://github.com/lachlanchen/LazyingArtBot
- Issue tracker: https://github.com/lachlanchen/LazyingArtBot/issues
- Security or safety concerns: https://github.com/lachlanchen/LazyingArtBot/blob/main/SECURITY.md

---

## License

MIT (same as upstream where applicable). See `LICENSE`.
