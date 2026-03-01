#!/usr/bin/env bash
set -euo pipefail

SESSION_NAME="${1:-openclaw}"
ATTACH_MODE="${2:-attach}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NGROK_URL="${OPENCLAW_NGROK_URL:-dullish-amee-multiovulate.ngrok-free.dev}"
NGROK_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"

if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux is not installed."
  exit 1
fi

if tmux has-session -t "${SESSION_NAME}" 2>/dev/null; then
  echo "tmux session '${SESSION_NAME}' already exists."
else
  tmux new-session -d -s "${SESSION_NAME}" -n openclaw
  tmux split-window -v -t "${SESSION_NAME}:0"
  tmux select-layout -t "${SESSION_NAME}:0" even-vertical

  # Top pane: gateway
  tmux send-keys -t "${SESSION_NAME}:0.0" "cd \"${REPO_DIR}\"" C-m
  tmux send-keys -t "${SESSION_NAME}:0.0" "source ~/.zshrc" C-m
  tmux send-keys -t "${SESSION_NAME}:0.0" "[ -f \"\$HOME/miniconda3/etc/profile.d/conda.sh\" ] && source \"\$HOME/miniconda3/etc/profile.d/conda.sh\" || true" C-m
  tmux send-keys -t "${SESSION_NAME}:0.0" "conda activate clawbot" C-m
  tmux send-keys -t "${SESSION_NAME}:0.0" "TOKEN=\$(node -e 'const fs=require(\"fs\");const p=process.env.HOME+\"/.openclaw/openclaw.json\";const j=JSON.parse(fs.readFileSync(p,\"utf8\"));process.stdout.write((j.gateway&&j.gateway.auth&&j.gateway.auth.token)||\"\")') ; if [ -n \"\$TOKEN\" ]; then echo \"Local dashboard:  http://127.0.0.1:${NGROK_PORT}/#token=\$TOKEN\"; if [ -n \"\${OPENCLAW_PUBLIC_URL:-}\" ]; then echo \"Public dashboard: \${OPENCLAW_PUBLIC_URL%/}/#token=\$TOKEN\"; fi; else echo \"Gateway token not found in ~/.openclaw/openclaw.json\"; fi" C-m
  tmux send-keys -t "${SESSION_NAME}:0.0" "if [ -z \"\$OPENAI_API_KEY\" ]; then echo \"OPENAI_API_KEY is missing. Export it in ~/.zshrc and rerun.\"; else pnpm openclaw onboard --non-interactive --accept-risk --auth-choice openai-api-key --openai-api-key \"\$OPENAI_API_KEY\" --skip-channels --skip-ui --skip-daemon --skip-health && pnpm openclaw gateway run --bind loopback --port ${NGROK_PORT} --verbose; fi" C-m

  # Bottom pane: ngrok tunnel
  tmux send-keys -t "${SESSION_NAME}:0.1" "source ~/.zshrc" C-m
  tmux send-keys -t "${SESSION_NAME}:0.1" "ngrok http --url=${NGROK_URL} ${NGROK_PORT}" C-m
  # Free-plan default domain; export OPENCLAW_NGROK_URL to revive lab.ngrok.pizza if you switch back
fi

if [[ "${ATTACH_MODE}" == "attach" ]]; then
  tmux attach -t "${SESSION_NAME}"
else
  echo "Session '${SESSION_NAME}' started in detached mode."
  echo "Attach with: tmux attach -t ${SESSION_NAME}"
fi
