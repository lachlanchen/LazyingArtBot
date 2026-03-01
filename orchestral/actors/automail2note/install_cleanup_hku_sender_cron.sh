#!/usr/bin/env bash
set -euo pipefail

AUTOMAIL_DIR="${AUTOMAIL_DIR:-$HOME/.openclaw/workspace/automation/automail2note}"
SCRIPT_PATH="$AUTOMAIL_DIR/cleanup_hku_sender_list.sh"
CRON_LOG="$HOME/.openclaw/workspace/logs/hku_sender_cleanup_cron.log"
CRON_TAG="# hku_sender_cleanup"
CRON_LINE="0 19 * * * $SCRIPT_PATH >> $CRON_LOG 2>&1 $CRON_TAG"

if [[ ! -x "$SCRIPT_PATH" ]]; then
  echo "missing executable script: $SCRIPT_PATH" >&2
  exit 1
fi

mkdir -p "$HOME/.openclaw/workspace/logs"

current="$(crontab -l 2>/dev/null || true)"
updated="$(printf '%s\n' "$current" | grep -v "$CRON_TAG" || true)"
{
  printf '%s\n' "$updated"
  printf '%s\n' "$CRON_LINE"
} | sed '/^$/N;/^\n$/D' | crontab -

echo "Installed cron job: $CRON_LINE"
crontab -l | grep "$CRON_TAG"
