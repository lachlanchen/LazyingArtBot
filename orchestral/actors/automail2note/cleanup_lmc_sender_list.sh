#!/usr/bin/env bash
set -euo pipefail

AUTOMAIL_DIR="${AUTOMAIL_DIR:-$HOME/.openclaw/workspace/automation/automail2note}"
DATA_DIR="${AUTOMAIL_DATA_DIR:-$HOME/.openclaw/workspace/automation/data/automail2note}"
SENDER_LIST_DIR="${DATA_DIR}/non_important_senders"
BASE_SCRIPT="$AUTOMAIL_DIR/cleanup_hku_sender_list.sh"
SENDER_LIST_PATH="${1:-$SENDER_LIST_DIR/lmc_non_important_senders_2026-02-17.txt}"

if [[ ! -x "$BASE_SCRIPT" ]]; then
  echo "missing base cleanup script: $BASE_SCRIPT" >&2
  exit 1
fi

HKU_CLEANUP_ACCOUNT="lachlan.mia.chan" \
HKU_CLEANUP_MAILBOX="INBOX" \
HKU_CLEANUP_LOG="$HOME/.openclaw/workspace/logs/lmc_sender_cleanup.log" \
"$BASE_SCRIPT" "$SENDER_LIST_PATH"
