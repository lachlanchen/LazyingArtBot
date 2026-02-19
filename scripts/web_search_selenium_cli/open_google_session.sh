#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_NAME="${WEB_SEARCH_ENV:-clawbot}"
FORCE_NEW="${WEB_SEARCH_FORCE_NEW_BROWSER:-0}"
TARGET_URL="${1:-https://accounts.google.com/}"
PROFILE_DIR="${2:-$HOME/.local/share/web-search-selenium/browser-profile}"
DEBUG_PORT="${3:-9222}"
HOLD_SECONDS="${4:-120}"
DISMISS_COOKIES="${WEB_SEARCH_DISMISS_COOKIES:-1}"

ATTACH_ARGS=()
COOKIE_ARGS=()

check_debugger_port() {
  local port="$1"
  local out
  out="$(python3 - "$port" <<'PY'
import socket
import sys

port = int(sys.argv[1])
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
try:
    sock.settimeout(0.5)
    available = sock.connect_ex(("127.0.0.1", port)) == 0
finally:
    sock.close()
print("1" if available else "0")
PY)"
  [[ "$out" == "1" ]]
}

if [[ "$FORCE_NEW" != "1" ]] && check_debugger_port "$DEBUG_PORT"; then
  ATTACH_ARGS+=(--attach --debugger-address "127.0.0.1:${DEBUG_PORT}")
fi

if [[ "$DISMISS_COOKIES" == "1" ]]; then
  COOKIE_ARGS=(--dismiss-cookies)
fi

"$SCRIPT_DIR/run_search.sh" \
  --env "$ENV_NAME" \
  --engine google \
  --profile-dir "$PROFILE_DIR" \
  --remote-debugging-port "$DEBUG_PORT" \
  --open-url "$TARGET_URL" \
  "${COOKIE_ARGS[@]-}" \
  "${ATTACH_ARGS[@]-}" \
  --keep-open \
  --hold-seconds "$HOLD_SECONDS"
