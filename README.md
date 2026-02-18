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
