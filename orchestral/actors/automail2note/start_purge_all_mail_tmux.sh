#!/usr/bin/env bash
set -euo pipefail

SESSION_NAME="${1:-openclaw-purge-all}"
AUTOMAIL_DIR="${AUTOMAIL_DIR:-$HOME/.openclaw/workspace/automation/automail2note}"
DATA_DIR="${AUTOMAIL_DATA_DIR:-$HOME/.openclaw/workspace/automation/data/automail2note}"
IGNORE_DIR="${DATA_DIR}/ignore_lists"
IGNORE_FILE="${2:-$IGNORE_DIR/mail_ignore_list_repetitive.json}"
PURGE_SCRIPT="${3:-$AUTOMAIL_DIR/purge_ignored_emails_fast.applescript}"
LOOKBACK_DAYS="${4:-30}"
ACCOUNT_FILTER="${5:-}"

if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux not found in PATH" >&2
  exit 1
fi

if [ ! -f "$IGNORE_FILE" ]; then
  echo "ignore file not found: $IGNORE_FILE" >&2
  exit 1
fi

if [ ! -f "$PURGE_SCRIPT" ]; then
  echo "purge script not found: $PURGE_SCRIPT" >&2
  exit 1
fi

# Avoid two purge jobs running at the same time.
pkill -KILL -f 'osascript .*purge_ignored_emails_fast\.applescript' || true

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  SESSION_NAME="${SESSION_NAME}-$(date +%H%M%S)"
fi

RUN_ID="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="/tmp/purge_all_mail_tmux-${RUN_ID}.log"

tmux new-session -d -s "$SESSION_NAME" -n purge "zsh"

if [ -n "$ACCOUNT_FILTER" ]; then
  CMD="echo 'start purge run_id=${RUN_ID} lookback_days=${LOOKBACK_DAYS} account=${ACCOUNT_FILTER}'; osascript \"$PURGE_SCRIPT\" \"$IGNORE_FILE\" \"$ACCOUNT_FILTER\" \"$LOOKBACK_DAYS\" 2>&1 | tee \"$LOG_FILE\"; echo 'purge finished; log=$LOG_FILE'"
else
  CMD="echo 'start purge run_id=${RUN_ID} lookback_days=${LOOKBACK_DAYS} all_accounts'; osascript \"$PURGE_SCRIPT\" \"$IGNORE_FILE\" \"\" \"$LOOKBACK_DAYS\" 2>&1 | tee \"$LOG_FILE\"; echo 'purge finished; log=$LOG_FILE'"
fi
tmux send-keys -t "${SESSION_NAME}:purge" "$CMD" C-m

echo "session=$SESSION_NAME"
echo "log=$LOG_FILE"
echo "lookback_days=$LOOKBACK_DAYS"
if [ -n "$ACCOUNT_FILTER" ]; then
  echo "account_filter=$ACCOUNT_FILTER"
fi
echo "attach: tmux attach -t $SESSION_NAME"
