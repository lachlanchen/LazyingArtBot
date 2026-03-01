#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="${AUTOMAIL_DATA_DIR:-$HOME/.openclaw/workspace/automation/data/automail2note}"
IGNORE_DIR="${DATA_DIR}/ignore_lists"
IGNORE_FILE="${1:-$IGNORE_DIR/mail_ignore_list.json}"
LOG_FILE="${2:-/tmp/purge_ignored_emails_fast.log}"
AUTOMAIL_DIR="${AUTOMAIL_DIR:-$HOME/.openclaw/workspace/automation/automail2note}"

: >"$LOG_FILE"
echo "log=$LOG_FILE" >&2

echo "Starting purge_fast (delete to Trash; move only if preferMoveToUseless=true inside script)" | tee -a "$LOG_FILE"
echo "ignore_file=$IGNORE_FILE" | tee -a "$LOG_FILE"

osascript "$AUTOMAIL_DIR/purge_ignored_emails_fast.applescript" "$IGNORE_FILE" 2>&1 | tee -a "$LOG_FILE"

echo "Done. log=$LOG_FILE" | tee -a "$LOG_FILE"
