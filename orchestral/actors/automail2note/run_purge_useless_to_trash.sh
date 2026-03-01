#!/usr/bin/env bash
set -euo pipefail

AUTOMAIL_DIR="${AUTOMAIL_DIR:-$HOME/.openclaw/workspace/automation/automail2note}"
SCRIPT="$AUTOMAIL_DIR/purge_useless_to_trash.applescript"
LOG="/tmp/purge_useless_to_trash.log"
OUT="/tmp/purge_useless_to_trash.out"

echo "Starting purge script..."
: > "$OUT"
osascript "$SCRIPT" "$@" >"$OUT" 2>&1 &
PID=$!
echo "PID: $PID"
echo "Log: $LOG"
echo "Output: $OUT"
echo

touch "$LOG"
tail -f "$LOG" &
TAIL_PID=$!

while kill -0 "$PID" 2>/dev/null; do
  sleep 2
done

kill "$TAIL_PID" 2>/dev/null || true
wait "$TAIL_PID" 2>/dev/null || true
wait "$PID" || true
echo
echo "=== Final Output ==="
cat "$OUT"
