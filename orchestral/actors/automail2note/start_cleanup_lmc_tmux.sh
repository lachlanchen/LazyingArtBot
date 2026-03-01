#!/usr/bin/env bash
set -euo pipefail

SESSION_NAME="${1:-lmc-cleanup}"
AUTOMAIL_DIR="${AUTOMAIL_DIR:-$HOME/.openclaw/workspace/automation/automail2note}"
DATA_DIR="${AUTOMAIL_DATA_DIR:-$HOME/.openclaw/workspace/automation/data/automail2note}"
SENDER_LIST_DIR="${DATA_DIR}/non_important_senders"
SENDER_LIST="${2:-$SENDER_LIST_DIR/lmc_non_important_senders_2026-02-17.txt}"
CLEANUP_SCRIPT="${3:-$AUTOMAIL_DIR/cleanup_lmc_sender_list.sh}"

if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux not found in PATH" >&2
  exit 1
fi

if [ ! -f "$SENDER_LIST" ]; then
  echo "sender list not found: $SENDER_LIST" >&2
  exit 1
fi

if [ ! -x "$CLEANUP_SCRIPT" ]; then
  echo "cleanup script not found or not executable: $CLEANUP_SCRIPT" >&2
  exit 1
fi

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  SESSION_NAME="${SESSION_NAME}-$(date +%H%M%S)"
fi

RUN_ID="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="/tmp/lmc_sender_cleanup_tmux-${RUN_ID}.log"

tmux new-session -d -s "$SESSION_NAME" -n cleanup "zsh"

CMD="echo 'start lmc cleanup run_id=${RUN_ID}'; \"$CLEANUP_SCRIPT\" \"$SENDER_LIST\" 2>&1 | tee \"$LOG_FILE\"; echo 'cleanup finished; log=$LOG_FILE'"
tmux send-keys -t "${SESSION_NAME}:cleanup" "$CMD" C-m

echo "session=$SESSION_NAME"
echo "log=$LOG_FILE"
echo "attach: tmux attach -t $SESSION_NAME"
