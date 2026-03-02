#!/usr/bin/env zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
RUN_TOOL="${REPO_DIR}/scripts/web_search_selenium_cli/run_search.sh"
DEFAULT_SEARCH_TOOL_ENV="clawbot"
DEFAULT_PROFILE_DIR="${HOME}/.local/share/web-search-selenium/browser-profile"
DEFAULT_DEBUG_PORT="9222"
OUTPUT_ROOT="${HOME}/.openclaw/workspace/AutoLife/MetaNotes/web_search_runs"
RUN_ID="$(date +%Y%m%d-%H%M%S)"
ENGINE="google"
RESULTS=5
RESULT_INDEX=1
START_PAGE=1
END_PAGE=1
SCROLL_STEPS=3
SCROLL_PAUSE=0.9
HEADLESS=0
KEEP_OPEN=0
HOLD_SECONDS=0
CONDA_ENV="${WEB_SEARCH_ENV:-$DEFAULT_SEARCH_TOOL_ENV}"
PROFILE_DIR="$DEFAULT_PROFILE_DIR"
DEBUG_PORT="$DEFAULT_DEBUG_PORT"
DISMISS_COOKIES="${WEB_SEARCH_DISMISS_COOKIES:-1}"
SUMMARY_MAX_CHARS=2500
OPEN_QUERIES=()

usage() {
  cat <<'USAGE'
Usage: prompt_web_search_click.sh [options]

Click a selected result in the same Selenium window and summarize the opened page.

Options:
  --engine <google|google-scholar|google-news|duckduckgo|bing>
  --query <text>                  Add one or more queries (default: required)
  --results <n>                   Max results to collect (default: 5)
  --result-index <n>              Which result to click (default: 1)
  --open-result                   Open selected result from current results instead of only returning list
  --start-page <n>                Search page start index (default: 1)
  --end-page <n>                  Search page end index (default: 1)
  --scroll-steps <n>              Open-page scroll steps (default: 3)
  --scroll-pause <seconds>        Seconds to wait between scroll steps (default: 0.9)
  --output-dir <path>             Base output dir
  --run-id <id>                   Output folder suffix
  --env <conda-env>               Conda env for search CLI (default: clawbot)
  --headless                      Run browser headless
  --keep-open                     Keep browser open after run
  --hold-seconds <seconds>        Keep-open seconds (if --keep-open set)
  --profile-dir <path>            Chrome user profile path
  --debug-port <port>             Chrome debug port for reusable login sessions
  --attach                        Attach to existing debug session
  --no-attach                     Force new session
  --summary-max-chars <n>         Opened-page summary size
  --dismiss-cookies               Try auto dismiss cookie consent popups
  --no-dismiss-cookies            Skip automatic cookie dismissal
  --help
USAGE
  exit 1
}

safe_slug() {
  # Lowercase, remove non-safe chars, collapse separators, trim edges.
  print -n "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --engine)
      shift
      [[ "$#" -gt 0 ]] || { echo "--engine requires a value" >&2; exit 1; }
      ENGINE="$1"
      ;;
    --query)
      shift
      [[ "$#" -gt 0 ]] || { echo "--query requires a value" >&2; exit 1; }
      OPEN_QUERIES+=("$1")
      ;;
    --results)
      shift
      [[ "$#" -gt 0 ]] || { echo "--results requires a value" >&2; exit 1; }
      RESULTS="$1"
      ;;
    --result-index)
      shift
      [[ "$#" -gt 0 ]] || { echo "--result-index requires a value" >&2; exit 1; }
      RESULT_INDEX="$1"
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
    --output-dir)
      shift
      [[ "$#" -gt 0 ]] || { echo "--output-dir requires a value" >&2; exit 1; }
      OUTPUT_ROOT="$1"
      ;;
    --run-id)
      shift
      [[ "$#" -gt 0 ]] || { echo "--run-id requires a value" >&2; exit 1; }
      RUN_ID="$1"
      ;;
    --env)
      shift
      [[ "$#" -gt 0 ]] || { echo "--env requires a value" >&2; exit 1; }
      CONDA_ENV="$1"
      ;;
    --headless)
      HEADLESS=1
      ;;
    --keep-open)
      KEEP_OPEN=1
      ;;
    --hold-seconds)
      shift
      [[ "$#" -gt 0 ]] || { echo "--hold-seconds requires a value" >&2; exit 1; }
      HOLD_SECONDS="$1"
      ;;
    --profile-dir)
      shift
      [[ "$#" -gt 0 ]] || { echo "--profile-dir requires a value" >&2; exit 1; }
      PROFILE_DIR="$1"
      ;;
    --debug-port)
      shift
      [[ "$#" -gt 0 ]] || { echo "--debug-port requires a value" >&2; exit 1; }
      DEBUG_PORT="$1"
      ;;
    --attach)
      ATTACH_SESSION=1
      ;;
    --no-attach)
      ATTACH_SESSION=0
      AUTO_ATTACH=0
      ;;
    --summary-max-chars)
      shift
      [[ "$#" -gt 0 ]] || { echo "--summary-max-chars requires a value" >&2; exit 1; }
      SUMMARY_MAX_CHARS="$1"
      ;;
    --dismiss-cookies)
      DISMISS_COOKIES=1
      ;;
    --no-dismiss-cookies)
      DISMISS_COOKIES=0
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

if ! command -v conda >/dev/null 2>&1; then
  echo "conda not found in PATH" >&2
  exit 1
fi

if [[ "${#OPEN_QUERIES[@]}" -eq 0 ]]; then
  echo "--query is required" >&2
  usage
fi

if [[ ! -x "$RUN_TOOL" ]]; then
  echo "search tool not executable: $RUN_TOOL" >&2
  exit 1
fi

RUN_DIR="${OUTPUT_ROOT}/${RUN_ID}"
mkdir -p "$RUN_DIR"
SUMMARY_FILE="${RUN_DIR}/web_search_results.txt"
: > "$SUMMARY_FILE"
AUTO_ATTACH=1
ATTACH_SESSION="${ATTACH_SESSION:-0}"

printf '%s\n' "# prompt_web_search_click run ${RUN_ID}" | tee -a "$SUMMARY_FILE"
printf '%s\n' "engine=$ENGINE results=$RESULTS result_index=$RESULT_INDEX" | tee -a "$SUMMARY_FILE"
printf '%s\n' "conda_env=$CONDA_ENV" | tee -a "$SUMMARY_FILE"
printf '%s\n' "profile_dir=$PROFILE_DIR" | tee -a "$SUMMARY_FILE"
printf '%s\n' "debug_port=$DEBUG_PORT" | tee -a "$SUMMARY_FILE"
printf '%s\n' "queries=${#OPEN_QUERIES[@]}" | tee -a "$SUMMARY_FILE"
  printf '%s\n' "summary_max_chars=$SUMMARY_MAX_CHARS" | tee -a "$SUMMARY_FILE"
  printf '%s\n' "dismiss_cookies=${DISMISS_COOKIES}" | tee -a "$SUMMARY_FILE"

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
    print('1' if sock.connect_ex(('127.0.0.1', port)) == 0 else '0')
finally:
    sock.close()
PY
)"
  [[ "$out" == "1" ]]
}

if [[ "$AUTO_ATTACH" -eq 1 ]] && [[ "$ATTACH_SESSION" -eq 0 ]] && check_debugger_port "$DEBUG_PORT"; then
  ATTACH_SESSION=1
fi

for raw_query in "${OPEN_QUERIES[@]}"; do
  [[ -n "$raw_query" ]] || continue
  slug="$(safe_slug "$raw_query")"
  json_file="${RUN_DIR}/query-${slug}-clicked.json"
  txt_file="${RUN_DIR}/query-${slug}-clicked.txt"
  err_file="${RUN_DIR}/query-${slug}-clicked.err"

  args=(--env "$CONDA_ENV" --engine "$ENGINE" --results "$RESULTS" --result-index "$RESULT_INDEX" --open-result --output json)
  args+=(--profile-dir "$PROFILE_DIR" --remote-debugging-port "$DEBUG_PORT")
  args+=(--start-page "$START_PAGE" --end-page "$END_PAGE" --scroll-steps "$SCROLL_STEPS" --scroll-pause "$SCROLL_PAUSE")
  args+=(--query "$raw_query" --summarize-open-url --summary-max-chars "$SUMMARY_MAX_CHARS")
  if [[ "$HEADLESS" -eq 1 ]]; then
    args+=(--headless)
  fi
  if [[ "$KEEP_OPEN" -eq 1 ]]; then
    args+=(--keep-open --hold-seconds "$HOLD_SECONDS")
  fi
  if [[ "$DISMISS_COOKIES" -eq 1 ]]; then
    args+=(--dismiss-cookies)
  fi
  if [[ "$ATTACH_SESSION" -eq 1 ]]; then
    args+=(--attach --debugger-address "127.0.0.1:${DEBUG_PORT}")
  fi

  set +e
  "$RUN_TOOL" "${args[@]}" >"$json_file" 2>"$err_file"
  rc=$?
  set -e

  printf '%s\n' "## Query: $raw_query" >> "$SUMMARY_FILE"
  printf '%s\n' "status_code=${rc}" >> "$SUMMARY_FILE"
  if [[ $rc -ne 0 ]]; then
    printf '%s\n' "search failed, see ${err_file}" >> "$SUMMARY_FILE"
    printf '%s\n' "" >> "$SUMMARY_FILE"
    cat "$err_file" >> "$SUMMARY_FILE"
    continue
  fi

  python3 - "$raw_query" "$json_file" "$txt_file" <<'PY'
import json
import sys
from pathlib import Path

query, json_path, out_path = sys.argv[1:4]
payload_path = Path(json_path)
text_path = Path(out_path)
raw = payload_path.read_text(encoding="utf-8")
lines = [f"query: {query}"]
try:
  payload = json.loads(raw)
except Exception as exc:
  lines.append(f"json_parse_error={exc}")
  lines.append(raw[:2500])
else:
  mode = payload.get("mode", "search-and-open")
  clicked = payload.get("clicked") or {}
  lines.append(f"mode: {mode}")
  lines.append(f"results_count: {payload.get('count') or payload.get('results_count', 0)}")
  lines.append(f"clicked_index: {clicked.get('result_index','')}")
  lines.append(f"clicked_title: {clicked.get('title','')}")
  lines.append(f"clicked_url: {clicked.get('url','')}")
  summary = clicked.get("summary") or ""
  if summary:
    lines.append("clicked_summary:")
    lines.append(summary.strip())

for item in (payload.get("items") or []):
  if not isinstance(item, dict):
    continue
  title = (item.get("title") or "").strip()
  url = (item.get("url") or "").strip()
  if not title and not url:
    continue
  lines.append(f" - {title or '(untitled)'}")
  if url:
    lines.append(f"   url: {url}")
  snippet = (item.get("snippet") or "").strip()
  if snippet:
    lines.append(f"   snippet: {snippet}")

text_path.write_text("\n".join(lines).strip() + "\n", encoding="utf-8")
PY

  printf '%s\n' "json_file=${json_file}" >> "$SUMMARY_FILE"
  printf '%s\n' "text_file=${txt_file}" >> "$SUMMARY_FILE"
  printf '%s\n' "" >> "$SUMMARY_FILE"
  cat "$txt_file" >> "$SUMMARY_FILE"
  printf '%s\n\n' "---" >> "$SUMMARY_FILE"
done

printf '%s\n' "output_dir=${RUN_DIR}" | tee -a "$SUMMARY_FILE"
printf '%s\n' "saved summary: ${SUMMARY_FILE}"
