#!/usr/bin/env zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

PLAYLIST_URL=""
TARGET_PLAYLIST="鹿鼎記"
OUTPUT_DIR="/tmp/codex-youtube-playlist-reorder"
MODEL="gpt-5.3-codex-spark"
REASONING="high"
SAFETY="${CODEX_SAFETY:-danger-full-access}"
APPROVAL="${CODEX_APPROVAL:-never}"
PROMPT_FILE="orchestral/prompt_tools/prompt_youtube_playlist_reorder_prompt.md"
SCHEMA_FILE="orchestral/prompt_tools/youtube_playlist_reorder_schema.json"
MAX_VIDEOS=0
SCROLL_PASSES=10
SCROLL_STEP_SECONDS=1.0
OPEN_LOGIN_SESSION=0
PROFILE_DIR="${HOME}/.local/share/web-search-selenium/browser-profile"
DEBUG_PORT="9222"
HOLD_SECONDS=900
ATTACH_SESSION=0
AUTO_ATTACH=1

usage() {
  cat <<'USAGE'
Usage: prompt_youtube_playlist_reorder.sh [options]

Options:
  --playlist-url <url>           Target YouTube playlist URL (required)
  --target-playlist <name>       Target playlist name (default: 鹿鼎記)
  --output-dir <path>            Output root for codex artifacts (default: /tmp/codex-youtube-playlist-reorder)
  --max-videos <n>               Process up to N videos, 0 means all
  --scroll-passes <n>            How many bottom-loading scroll cycles (default: 10)
  --scroll-step-seconds <seconds> Wait between scroll cycles (default: 1.0)
  --model <name>                 Codex model (default: gpt-5.3-codex-spark)
  --reasoning <low|medium|high>  Codex reasoning level
  --safety <mode>                Codex safety mode
  --approval <policy>            Codex approval policy
  --open-login-session           Open target URL in fixed cache and keep browser open for manual login
  --profile-dir <path>           Chrome profile path for cache reuse
  --debug-port <port>            Chrome remote debug port (default: 9222)
  --attach                      Attach to an existing Selenium browser on debug port (default: auto)
  --no-attach                   Force new session, do not attach
  --no-auto-attach              Disable auto attach detection
  --hold-seconds <seconds>       Keep login session open seconds (default: 900)
  -h, --help
USAGE
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --playlist-url)
      shift
      [[ "${1:-}" != "" ]] || { echo "--playlist-url requires a value" >&2; exit 1; }
      PLAYLIST_URL="$1"
      ;;
    --target-playlist)
      shift
      [[ "${1:-}" != "" ]] || { echo "--target-playlist requires a value" >&2; exit 1; }
      TARGET_PLAYLIST="$1"
      ;;
    --output-dir)
      shift
      [[ "${1:-}" != "" ]] || { echo "--output-dir requires a value" >&2; exit 1; }
      OUTPUT_DIR="$1"
      ;;
    --max-videos)
      shift
      [[ "${1:-}" != "" ]] || { echo "--max-videos requires a value" >&2; exit 1; }
      MAX_VIDEOS="$1"
      ;;
    --scroll-passes)
      shift
      [[ "${1:-}" != "" ]] || { echo "--scroll-passes requires a value" >&2; exit 1; }
      SCROLL_PASSES="$1"
      ;;
    --scroll-step-seconds)
      shift
      [[ "${1:-}" != "" ]] || { echo "--scroll-step-seconds requires a value" >&2; exit 1; }
      SCROLL_STEP_SECONDS="$1"
      ;;
    --model)
      shift
      [[ "${1:-}" != "" ]] || { echo "--model requires a value" >&2; exit 1; }
      MODEL="$1"
      ;;
    --reasoning)
      shift
      [[ "${1:-}" != "" ]] || { echo "--reasoning requires a value" >&2; exit 1; }
      REASONING="$1"
      ;;
    --safety)
      shift
      [[ "${1:-}" != "" ]] || { echo "--safety requires a value" >&2; exit 1; }
      SAFETY="$1"
      ;;
    --approval)
      shift
      [[ "${1:-}" != "" ]] || { echo "--approval requires a value" >&2; exit 1; }
      APPROVAL="$1"
      ;;
    --open-login-session)
      OPEN_LOGIN_SESSION=1
      ;;
    --profile-dir)
      shift
      [[ "${1:-}" != "" ]] || { echo "--profile-dir requires a value" >&2; exit 1; }
      PROFILE_DIR="$1"
      ;;
    --debug-port)
      shift
      [[ "${1:-}" != "" ]] || { echo "--debug-port requires a value" >&2; exit 1; }
      DEBUG_PORT="$1"
      ;;
    --attach)
      ATTACH_SESSION=1
      ;;
    --no-attach)
      ATTACH_SESSION=0
      AUTO_ATTACH=0
      ;;
    --no-auto-attach)
      AUTO_ATTACH=0
      ;;
    --hold-seconds)
      shift
      [[ "${1:-}" != "" ]] || { echo "--hold-seconds requires a value" >&2; exit 1; }
      HOLD_SECONDS="$1"
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      ;;
  esac
  shift
done

if [[ -z "$PLAYLIST_URL" ]]; then
  echo "--playlist-url is required" >&2
  usage
fi

if [[ "$OPEN_LOGIN_SESSION" -eq 1 ]]; then
  if [[ -z "$PLAYLIST_URL" ]]; then
    echo "--playlist-url is required when --open-login-session is set" >&2
    usage
  fi
  echo "Opening fixed-cache browser session for login..."
  echo "Profile: $PROFILE_DIR"
  echo "Debug port: $DEBUG_PORT"
  echo "Keep-open seconds: $HOLD_SECONDS"
  scripts/web_search_selenium_cli/open_google_session.sh \
    "$PLAYLIST_URL" \
    "$PROFILE_DIR" \
    "$DEBUG_PORT" \
    "$HOLD_SECONDS"
  exit 0
fi

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
    print("1" if sock.connect_ex(("127.0.0.1", port)) == 0 else "0")
finally:
    sock.close()
PY
)"
  [[ "$out" == "1" ]]
}

if [[ "$AUTO_ATTACH" -eq 1 ]] && [[ "$ATTACH_SESSION" -eq 0 ]] && check_debugger_port "$DEBUG_PORT"; then
  ATTACH_SESSION=1
fi

TMP_PAYLOAD="$(mktemp)"
python3 - "$TMP_PAYLOAD" "$PLAYLIST_URL" "$TARGET_PLAYLIST" "$MAX_VIDEOS" "$SCROLL_PASSES" "$SCROLL_STEP_SECONDS" "$PROFILE_DIR" "$DEBUG_PORT" "$ATTACH_SESSION" <<'PY'
import json
import sys
from datetime import datetime
from pathlib import Path

payload_path, playlist_url, target_playlist, max_videos, scroll_passes, scroll_step_seconds = sys.argv[1:7]

payload = {
    "run_local_iso": datetime.now().astimezone().isoformat(timespec="seconds"),
    "playlist_url": playlist_url,
    "target_playlist_name": target_playlist,
    "max_videos": int(max_videos),
    "scroll_passes": int(scroll_passes),
    "scroll_step_seconds": float(scroll_step_seconds),
    "profile_dir": sys.argv[7] if len(sys.argv) > 7 else "",
    "debug_port": sys.argv[8] if len(sys.argv) > 8 else "",
    "fixed_cache_mode": True,
    "attach_session": bool(int(sys.argv[9])) if len(sys.argv) > 9 else False,
    "operation_notes": "Use Selenium/driver-style browser automation, visible mode, screenshots + HTML inspection, process from bottom-to-top.",
}

Path(payload_path).write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY

python3 orchestral/prompt_tools/codex-json-runner.py \
  --input-json "$TMP_PAYLOAD" \
  --output-dir "$OUTPUT_DIR" \
  --prompt-file "$PROMPT_FILE" \
  --schema "$SCHEMA_FILE" \
  --model "$MODEL" \
  --reasoning "$REASONING" \
  --safety "$SAFETY" \
  --approval "$APPROVAL" \
  --label youtube-playlist-reorder \
  --skip-git-check

rm -f "$TMP_PAYLOAD"
