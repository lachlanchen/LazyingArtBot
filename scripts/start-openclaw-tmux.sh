#!/usr/bin/env bash
set -euo pipefail

SESSION_NAME="${1:-openclaw}"
ATTACH_MODE="${2:-attach}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux is not installed."
  exit 1
fi

if tmux has-session -t "${SESSION_NAME}" 2>/dev/null; then
  echo "tmux session '${SESSION_NAME}' already exists."
else
  tmux new-session -d -s "${SESSION_NAME}"

  tmux send-keys -t "${SESSION_NAME}" "cd \"${REPO_DIR}\"" C-m
  tmux send-keys -t "${SESSION_NAME}" "source ~/.zshrc" C-m
  tmux send-keys -t "${SESSION_NAME}" "[ -f \"\$HOME/miniconda3/etc/profile.d/conda.sh\" ] && source \"\$HOME/miniconda3/etc/profile.d/conda.sh\" || true" C-m
  tmux send-keys -t "${SESSION_NAME}" "conda activate clawbot" C-m
  tmux send-keys -t "${SESSION_NAME}" "TOKEN=\$(node -e 'const fs=require(\"fs\");const p=process.env.HOME+\"/.openclaw/openclaw.json\";const j=JSON.parse(fs.readFileSync(p,\"utf8\"));process.stdout.write((j.gateway&&j.gateway.auth&&j.gateway.auth.token)||\"\")') ; if [ -n \"\$TOKEN\" ]; then echo \"Local dashboard:  http://127.0.0.1:18789/#token=\$TOKEN\"; if [ -n \"\${OPENCLAW_PUBLIC_URL:-}\" ]; then echo \"Public dashboard: \${OPENCLAW_PUBLIC_URL%/}/#token=\$TOKEN\"; fi; else echo \"Gateway token not found in ~/.openclaw/openclaw.json\"; fi" C-m
  tmux send-keys -t "${SESSION_NAME}" "if [ -z \"\$OPENAI_API_KEY\" ]; then echo \"OPENAI_API_KEY is missing. Export it in ~/.zshrc and rerun.\"; else pnpm openclaw onboard --non-interactive --accept-risk --auth-choice openai-api-key --openai-api-key \"\$OPENAI_API_KEY\" --skip-channels --skip-ui --skip-daemon --skip-health && pnpm openclaw gateway run --bind loopback --port 18789 --verbose; fi" C-m
fi

if [[ "${ATTACH_MODE}" == "attach" ]]; then
  tmux attach -t "${SESSION_NAME}"
else
  echo "Session '${SESSION_NAME}' started in detached mode."
  echo "Attach with: tmux attach -t ${SESSION_NAME}"
fi
