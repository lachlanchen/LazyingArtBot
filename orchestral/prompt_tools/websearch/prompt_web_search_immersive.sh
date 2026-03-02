#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="/Users/lachlan/Local/Clawbot/scripts/web_search_selenium_cli"
IMMERSIVE_SCRIPT="${SCRIPT_DIR}/immersive_search.sh"
OUTPUT_ROOT_DEFAULT="${HOME}/.openclaw/workspace/AutoLife/MetaNotes/web_search_runs"
ENV_NAME="${WEB_SEARCH_ENV:-clawbot}"
ENGINE="google"
RESULTS="5"
RUN_ID="$(date +%Y%m%d-%H%M%S)"
QUERY=""
KEEP_OPEN=0
HOLD_SECONDS=0
HEADLESS=0
START_PAGE=1
END_PAGE=1
SCROLL_STEPS=3
SCROLL_PAUSE=0.9
AUTO_ATTACH=1
ATTACH_SESSION=0
DEBUG_PORT="9222"
HAS_DEBUG_PORT=0

usage() {
  cat <<'USAGE'
Usage: prompt_web_search_immersive.sh [options]

Immersive (UI) Google flow with screenshot capture.

Options:
  --query <text>             Search query (required).
  --engine <google|google-scholar|google-news|duckduckgo|bing> (default: google)
  --results <n>              Max result count (default: 5)
  --run-id <id>              Output folder suffix
  --output-dir <path>        Base output directory (default: ~/.openclaw/workspace/AutoLife/MetaNotes/web_search_runs)
  --env <conda-env>          Conda env for Selenium tool (default: clawbot)
  --profile-dir <path>       Chrome profile directory
  --debug-port <port>        Debug port for attach mode (default: 9222)
  --attach                   Attach to running Chrome session (port must be active)
  --no-attach                Force a fresh Chrome session
  --no-auto-attach           Disable auto-attach when a reusable debug session exists
  --headless                  Force headless mode (not default)
  --open-result              Click selected result index (same as search wrapper behavior)
  --result-index <n>         If --open-result, index of clicked result (default: 1)
  --open-top-results <n>     Open and summarize top N results (default: 0)
  --click-at <x,y>           Click absolute browser coordinate before extraction
  --summarize-open-url        Capture page summary after open/click
  --start-page <n>           Search page start index (default: 1)
  --end-page <n>             Search page end index (default: 1)
  --scroll-steps <n>         Number of scroll steps while summarizing opened page (default: 3)
  --scroll-pause <seconds>   Delay between scroll steps (default: 0.9)
  --open-url <url>           Open URL directly and skip search
  --keep-open                Keep browser open after run
  --hold-seconds <n>         Keep-open duration in seconds
  --help

Default behavior:
- visible browser (non-headless)
- screenshot capture enabled
- Google immersive UI flow when using --query + --engine google

Output:
- Query JSON: <output-dir>/<run-id>/query-<query>.json
- Query text: <output-dir>/<run-id>/query-<query>.txt
- Screenshot PNGs: <output-dir>/<run-id>/screenshots/
USAGE
  exit 1
}

ARGS=(--env "$ENV_NAME")

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --query)
      shift
      [[ "$#" -gt 0 ]] || { echo "--query requires a value" >&2; exit 1; }
      QUERY="$1"
      ;;
    --engine)
      shift
      [[ "$#" -gt 0 ]] || { echo "--engine requires a value" >&2; exit 1; }
      ENGINE="$1"
      ;;
    --results)
      shift
      [[ "$#" -gt 0 ]] || { echo "--results requires a value" >&2; exit 1; }
      RESULTS="$1"
      ;;
    --run-id)
      shift
      [[ "$#" -gt 0 ]] || { echo "--run-id requires a value" >&2; exit 1; }
      RUN_ID="$1"
      ;;
    --output-dir)
      shift
      [[ "$#" -gt 0 ]] || { echo "--output-dir requires a value" >&2; exit 1; }
      OUTPUT_ROOT_DEFAULT="$1"
      ;;
    --env)
      shift
      [[ "$#" -gt 0 ]] || { echo "--env requires a value" >&2; exit 1; }
      ENV_NAME="$1"
      ;;
    --profile-dir)
      shift
      [[ "$#" -gt 0 ]] || { echo "--profile-dir requires a value" >&2; exit 1; }
      ARGS+=("--profile-dir" "$1")
      ;;
    --debug-port)
      shift
      [[ "$#" -gt 0 ]] || { echo "--debug-port requires a value" >&2; exit 1; }
      DEBUG_PORT="$1"
      ARGS+=("--debug-port" "$1")
      ;;
    --result-index)
      shift
      [[ "$#" -gt 0 ]] || { echo "--result-index requires a value" >&2; exit 1; }
      ARGS+=("--result-index" "$1")
      ;;
    --hold-seconds)
      shift
      [[ "$#" -gt 0 ]] || { echo "--hold-seconds requires a value" >&2; exit 1; }
      HOLD_SECONDS="$1"
      ;;
    --open-url)
      shift
      [[ "$#" -gt 0 ]] || { echo "--open-url requires a value" >&2; exit 1; }
      ARGS+=("--open-url" "$1")
      ;;
    --open-top-results)
      shift
      [[ "$#" -gt 0 ]] || { echo "--open-top-results requires a value" >&2; exit 1; }
      ARGS+=("--open-top-results" "$1")
      ;;
    --click-at)
      shift
      [[ "$#" -gt 0 ]] || { echo "--click-at requires a value" >&2; exit 1; }
      ARGS+=("--click-at" "$1")
      ;;
    --start-page)
      shift
      [[ "$#" -gt 0 ]] || { echo "--start-page requires a value" >&2; exit 1; }
      START_PAGE="$1"
      ;;
    --end-page)
      shift
      [[ "$#" -gt 0 ]] || { echo "--end-page requires a value" >&2; exit 1; }
      END_PAGE="$1"
      ;;
    --scroll-steps)
      shift
      [[ "$#" -gt 0 ]] || { echo "--scroll-steps requires a value" >&2; exit 1; }
      SCROLL_STEPS="$1"
      ;;
    --scroll-pause)
      shift
      [[ "$#" -gt 0 ]] || { echo "--scroll-pause requires a value" >&2; exit 1; }
      SCROLL_PAUSE="$1"
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
    --headless|--open-result|--summarize-open-url|--keep-open)
      ARGS+=("$1")
      if [[ "$1" == --headless ]]; then
        HEADLESS=1
      elif [[ "$1" == --keep-open ]]; then
        KEEP_OPEN=1
      fi
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

if [[ -z "$QUERY" ]]; then
  echo "--query is required" >&2
  usage
fi

if [[ ! -x "$IMMERSIVE_SCRIPT" ]]; then
  echo "missing script: $IMMERSIVE_SCRIPT" >&2
  exit 1
fi

HAS_DEBUG_PORT=0
for arg in "${ARGS[@]}"; do
  if [[ "$arg" == "--debug-port" ]]; then
    HAS_DEBUG_PORT=1
    break
  fi
done
if [[ "$HAS_DEBUG_PORT" -eq 0 ]]; then
  ARGS+=(--debug-port "$DEBUG_PORT")
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

ARGS+=(--query "$QUERY")
ARGS+=(--engine "$ENGINE")
ARGS+=(--results "$RESULTS")
ARGS+=(--run-id "$RUN_ID")
ARGS+=(--output-dir "$OUTPUT_ROOT_DEFAULT")
ARGS+=(--env "$ENV_NAME")

if [[ "${KEEP_OPEN}" == "1" ]]; then
  ARGS+=(--keep-open)
fi
ARGS+=(--start-page "$START_PAGE")
ARGS+=(--end-page "$END_PAGE")
ARGS+=(--scroll-steps "$SCROLL_STEPS")
ARGS+=(--scroll-pause "$SCROLL_PAUSE")
if [[ "${HOLD_SECONDS}" != "0" ]]; then
  ARGS+=(--hold-seconds "$HOLD_SECONDS")
fi
if [[ "$ATTACH_SESSION" -eq 1 ]]; then
  ARGS+=(--attach)
fi
if [[ "${HEADLESS}" == "1" ]]; then
  ARGS+=(--headless)
fi

"$IMMERSIVE_SCRIPT" "${ARGS[@]}"
