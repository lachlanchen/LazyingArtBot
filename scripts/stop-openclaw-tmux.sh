#!/usr/bin/env bash
set -euo pipefail

SESSION_NAME="${1:-openclaw}"

if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux is not installed."
  exit 1
fi

if ! tmux has-session -t "${SESSION_NAME}" 2>/dev/null; then
  echo "tmux session '${SESSION_NAME}' is not running."
  exit 0
fi

# Ask the foreground command to exit cleanly first.
tmux send-keys -t "${SESSION_NAME}" C-c || true
sleep 1

if tmux has-session -t "${SESSION_NAME}" 2>/dev/null; then
  tmux kill-session -t "${SESSION_NAME}"
fi

echo "Stopped tmux session '${SESSION_NAME}'."
