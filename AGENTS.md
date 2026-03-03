# Kairo — AI Installation & Troubleshooting Prompt

> **For AI assistants (Claude, GPT, Gemini, etc.)**
>
> Read this document in full before starting. You are an installation agent helping a user
> set up Kairo on their cloud server. Work step by step, run each verification command,
> and fix problems before moving on. Never skip a step.
>
> **Your job**: get the user's Telegram bot online and responding. Done means the user sends
> a message to their bot and gets a reply.

---

## What Kairo Is

Kairo is a self-hosted AI secretary. It runs on the user's server and connects to Telegram
(and optionally Feishu). Three AI agents handle daily tasks: Planner (direct conversation),
Executor (scheduled tasks), Reviewer (health checks + weekly reflection).

After setup:

- `https://USERNAME.github.io/kairo-brain/` — the user's permanent control page
- `http://SERVER_IP:18789` — the live gateway (must stay running)
- Telegram bot responds to messages 24/7

---

## Before You Begin

Ask the user for:

1. SSH access to their server (or they share a terminal session with you)
2. Their Telegram account (to receive bot messages)

You will guide them to create:

- A GitHub account (if they don't have one) — free at github.com
- A Telegram bot — free via @BotFather in Telegram
- An LLM API key — DashScope (free quota, recommended) or OpenAI/Anthropic

---

## Phase 0: Server Check

Run these. Fix anything that fails before proceeding.

```bash
# Operating system
uname -a
cat /etc/os-release | grep PRETTY_NAME

# Required tools
node --version    # Need >= v20
git --version     # Required
curl --version    # Required
jq --version      # Required

# Server reachability
curl -s ifconfig.me   # Public IP address
hostname -I           # LAN IP (internal)

# Port availability
sudo ss -tlnp | grep 18789   # Should be empty (nothing running yet)
```

**Fix node if missing:**

```bash
# Debian/Ubuntu
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

# Alibaba Cloud Linux / CentOS / RHEL
curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
sudo yum install -y nodejs
```

**Fix git/curl/jq if missing:**

```bash
sudo apt-get install -y git curl jq    # Debian/Ubuntu
sudo yum install -y git curl jq        # CentOS/RHEL/Alibaba Linux
```

**Verify after fixing:**

```bash
node --version && git --version && jq --version && echo "ALL OK"
```

---

## Phase 1: Install Kairo

```bash
cd /opt
sudo git clone https://github.com/lachlanchen/LazyingArtBot.git
cd LazyingArtBot
sudo npm install -g pnpm
sudo pnpm install
sudo pnpm build
```

**Expected**: build ends with `Build complete`. The step that says
`Command failed with exit code 137` for `build:plugin-sdk:dts` is normal (OOM on small servers)
— it only generates TypeScript declaration files, not needed at runtime.

**If `pnpm install` hangs > 3 min**: Network issue. Try:

```bash
sudo pnpm install --registry https://registry.npmmirror.com
```

**If `pnpm build` fails with TS errors**: Check if the error is in `src/gateway/` —
those are critical. Errors in `scripts/` or `ui/` can be ignored.

---

## Phase 2: GitHub Setup

This creates the user's permanent management page at `https://USERNAME.github.io/kairo-brain/`.

### 2a. Get a GitHub token

**Tell the user:** Open this URL in a browser:

```
https://github.com/settings/tokens/new?description=Kairo-Brain&scopes=repo,workflow
```

Steps:

1. Log in to GitHub (create free account at github.com if needed)
2. Scroll down on that page, click **[Generate token]**
3. Copy the token (starts with `ghp_...`)

**Test the token:**

```bash
GH_TOKEN="ghp_PASTE_TOKEN_HERE"
curl -sf -H "Authorization: token $GH_TOKEN" https://api.github.com/user | grep login
```

**Expected**: shows `"login": "their-username"`

**If empty/error**: Token is wrong, expired, or network to GitHub is blocked.
Ask user to regenerate. If GitHub itself is unreachable from the server:

```bash
curl -v https://api.github.com 2>&1 | head -20
```

Some servers block GitHub API — if so, skip GitHub Pages.
The user can access the wizard directly via `http://SERVER_IP:18789/app/#setup`.

### 2b. Run setup script

```bash
sudo bash /opt/LazyingArtBot/scripts/setup.sh --github-first
```

When prompted for GitHub token, paste the `ghp_...` token.

**Expected output at the end:**

```
✅ GitHub repo created: https://github.com/USERNAME/kairo-brain
✅ Setup wizard pushed to GitHub Pages

Your SETUP PIN: A1B2C3
(Save this PIN — you'll enter it in the wizard)

⏳ GitHub Pages takes 1–5 min to activate.
```

**If "Token 無效或網絡不通"**: The token is wrong OR GitHub is blocked. Re-check 2a.

**If "repo already exists"**: That's fine. Script continues.

**If script exits without a PIN**: Run:

```bash
NEWPIN=$(LC_ALL=C tr -dc A-Z0-9 </dev/urandom | head -c6)
echo $NEWPIN | sudo tee /root/.openclaw/setup.pin
echo $(($(date +%s) + 86400)) | sudo tee /root/.openclaw/setup.pin.expiry
echo "Your PIN: $NEWPIN"
```

---

## Phase 3: Start the Gateway

```bash
sudo bash /opt/LazyingArtBot/scripts/setup.sh --start-service
```

**Verify it's running:**

```bash
sudo ss -tlnp | grep 18789
curl -s http://localhost:18789/api/setup/status
```

**Expected**: port shows `LISTEN`, API returns `{"ok":true,...}`

**If port never opens (wait 60 sec):**

```bash
# Kill any zombie processes
sudo lsof -ti:18789 | xargs sudo kill -9 2>/dev/null; sleep 2

# Restart
sudo XDG_RUNTIME_DIR=/run/user/0 systemctl --user restart openclaw-gateway.service
sleep 15
sudo ss -tlnp | grep 18789

# If still nothing, check logs
sudo XDG_RUNTIME_DIR=/run/user/0 journalctl --user -u openclaw-gateway.service -n 40
```

**If systemctl --user fails**: Always use `XDG_RUNTIME_DIR=/run/user/0` prefix when running as root.

---

## Phase 4: Complete Setup via Wizard

### Open the wizard

| Situation                              | URL                                       |
| -------------------------------------- | ----------------------------------------- |
| GitHub Pages is working                | `https://USERNAME.github.io/kairo-brain/` |
| GitHub Pages not working / server-side | `http://SERVER_LAN_IP:18789/app/#setup`   |

**Note**: GitHub Pages is HTTPS. Opening it and calling an HTTP server causes "Mixed Content"
browser errors. The wizard will show a banner with the correct local URL to use instead.

**If GitHub Pages shows 404 after 5 min:**

- Go to `https://github.com/USERNAME/kairo-brain/settings/pages`
- Set Source = "Deploy from branch" → Branch = "main" → "/ (root)" → Save

### Enter the PIN

```bash
sudo cat /root/.openclaw/setup.pin    # Show current PIN
```

**If PIN expired or missing:**

```bash
NEWPIN=$(LC_ALL=C tr -dc A-Z0-9 </dev/urandom | head -c6)
echo $NEWPIN | sudo tee /root/.openclaw/setup.pin
echo $(($(date +%s) + 86400)) | sudo tee /root/.openclaw/setup.pin.expiry
echo "New PIN: $NEWPIN"
```

### Wizard steps

**Step 1 — Telegram Bot**

Create a bot via Telegram:

1. Open Telegram → search `@BotFather` → send `/newbot`
2. Choose a name and username (must end in `bot`)
3. BotFather gives a token like `7123456789:AAF...` — paste into wizard

Get User ID:

1. Telegram → search `@userinfobot` → send any message
2. It replies with `Id: 1234567890` — paste into wizard

The wizard validates the token live (shows ✅ with bot name on success).

**If token validation times out:**

```bash
TOKEN="7123456789:AAF..."
curl -s "https://api.telegram.org/bot${TOKEN}/getMe"
# Must return {"ok":true,...}
```

If that fails: server can't reach api.telegram.org. Check firewall or use a proxy.

**Step 2 — LLM API Key**

Recommended: **DashScope** (Alibaba, free quota, best for China servers)

- Sign up: `https://dashscope.console.aliyun.com`
- Go to "API-KEY 管理" → create key (looks like `sk-xxxxxxxx...`)

The wizard tests the key against the provider's `/models` endpoint.

**If validation fails from a China server**: Only DashScope works without a proxy.
OpenAI and Anthropic require the server to have overseas network access.

**Step 3 — Optional (Feishu, GitHub, TTS)**

Safe to skip all. Click "跳過" / "Skip".

**Step 4 — Launch**

Click "Launch Kairo". When the celebration screen appears, run the restart command it shows:

```bash
sudo XDG_RUNTIME_DIR=/run/user/0 systemctl --user restart openclaw-gateway.service
```

**Verify after restart:**

```bash
curl -s http://localhost:18789/api/setup/status | python3 -m json.tool
```

Look for `"telegram": "ok"` and `"llm": "ok"`.

---

## Phase 5: Test the Bot

Tell the user: Open Telegram, find your bot, send "你好".

**Expected**: Reply within 30 seconds.

**If no reply:**

```bash
# Watch logs while user sends a message
sudo XDG_RUNTIME_DIR=/run/user/0 journalctl --user -u openclaw-gateway.service -f
```

Look for lines showing the message received and LLM response.

**If logs show "allowFrom" rejection**: User ID not in allowlist.

```bash
cat /root/.openclaw/openclaw.json | python3 -m json.tool | grep -A10 telegram
```

The `allowFrom` array must contain the user's numeric ID.

---

## Common Errors Reference

| Error                        | Cause                                    | Fix                                                                                          |
| ---------------------------- | ---------------------------------------- | -------------------------------------------------------------------------------------------- |
| `ENOENT: models.json`        | models.json not copied to agent dirs     | `sudo cp /opt/LazyingArtBot/src/agents/tools/models.json /root/.openclaw/agents/main/agent/` |
| Port 18789 in use            | Old process still running                | `sudo lsof -ti:18789 \| xargs sudo kill -9`                                                  |
| `Failed to connect to bus`   | systemctl --user without XDG_RUNTIME_DIR | Always use `sudo XDG_RUNTIME_DIR=/run/user/0 systemctl --user ...`                           |
| Bot token 401                | Token deleted or invalid                 | Re-create bot via @BotFather                                                                 |
| LLM `Connection refused`     | Provider unreachable                     | Switch to DashScope; check firewall                                                          |
| `plugin id mismatch` in logs | Feishu plugin config                     | Harmless warning, ignore                                                                     |
| `PIN 不存在` in wizard       | PIN expired (24h) or never created       | Run the PIN regeneration command above                                                       |
| Config JSON invalid          | Incomplete write                         | `sudo cp /root/.openclaw/openclaw.json.bak.setup /root/.openclaw/openclaw.json`              |

---

## Key Files

| File                                         | Purpose                                           |
| -------------------------------------------- | ------------------------------------------------- |
| `/root/.openclaw/openclaw.json`              | Main config (channels, agents, models)            |
| `/root/.openclaw/setup.pin`                  | Wizard PIN — deleted after first successful apply |
| `/root/.openclaw/cron/jobs.json`             | Scheduled jobs                                    |
| `/root/.secrets/telegram.token`              | Telegram bot token                                |
| `/root/.secrets/github-kairo.token`          | GitHub token                                      |
| `/root/.openclaw/feishu_user_token.json`     | Feishu OAuth token (auto-refreshed)               |
| `/root/.openclaw/agents/*/agent/models.json` | LLM config per agent                              |

**Quick commands:**

```bash
# Force rebuild + restart
sudo rm /opt/LazyingArtBot/dist/.buildstamp
sudo XDG_RUNTIME_DIR=/run/user/0 systemctl --user restart openclaw-gateway.service

# Quick restart (no rebuild)
sudo XDG_RUNTIME_DIR=/run/user/0 systemctl --user restart openclaw-gateway.service

# Watch logs
sudo XDG_RUNTIME_DIR=/run/user/0 journalctl --user -u openclaw-gateway.service -f

# Check port
sudo ss -tlnp | grep 18789

# API health check
curl -s http://localhost:18789/api/health | python3 -m json.tool
```

---

## Architecture

```
Cloud Server
├── openclaw-gateway.service  :18789
│   ├── /api/setup/status    — service health
│   ├── /api/setup/apply     — write config (local-only, PIN required)
│   └── /app/                — PWA control panel
├── Planner (main)     ← Telegram main bot + Feishu → direct user chat
├── Executor           ← Telegram channel2 → cron jobs, lessons, 晨報
└── Reviewer           ← background → heartbeat every 30m, weekly reflection

GitHub: USERNAME/kairo-brain
├── main → GitHub Pages (wizard UI)
└── workspace/* → agent memory backups

~/.openclaw/
├── openclaw.json         config
├── workspace/            Planner memory
├── workspace-executor/   Executor memory
├── workspace-reviewer/   Reviewer memory
└── agents/               per-agent model config
```

---

## Ken's 3-Agent Deployment (Reference)

| Agent    | ID         | Channel                | Heartbeat                  |
| -------- | ---------- | ---------------------- | -------------------------- |
| Planner  | `main`     | `@ken_MB2Bot` + Feishu | none                       |
| Executor | `executor` | `@KensRF_AssistantBot` | none                       |
| Reviewer | `reviewer` | background             | every 30m, 07:00–23:30 CST |

Routing: lessons/captures/晨報 → executor; conversation → main; 週反思/月壓縮 → reviewer.

**Rollback:**

```bash
sudo cp /root/.openclaw/openclaw.json.bak.pre-3agent /root/.openclaw/openclaw.json
sudo cp /root/.openclaw/cron/jobs.json.bak.pre-3agent /root/.openclaw/cron/jobs.json
sudo XDG_RUNTIME_DIR=/run/user/0 systemctl --user restart openclaw-gateway.service
```
