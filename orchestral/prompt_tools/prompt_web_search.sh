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
HEADLESS=0
KEEP_OPEN=0
HOLD_SECONDS=0
AUTO_ATTACH=1
ATTACH_SESSION=0
CONTEXT_PATH=""
CONDA_ENV="${WEB_SEARCH_ENV:-$DEFAULT_SEARCH_TOOL_ENV}"
PROFILE_DIR="$DEFAULT_PROFILE_DIR"
DEBUG_PORT="$DEFAULT_DEBUG_PORT"
OPEN_URL=""
DISMISS_COOKIES="${WEB_SEARCH_DISMISS_COOKIES:-1}"
QUERIES=()

usage() {
  cat <<'USAGE'
Usage: prompt_web_search.sh [options]

Generate web-search evidence for the configured queries and save evidence files.

Options:
  --query <text>              Add a query (repeatable). Defaults to context-derived terms if --context-path is set.
  --context-path <path>       Optional context file used for deterministic probe query generation.
  --engine <google|duckduckgo|bing>  Search engine (default: google)
  --results <n>               Max results per query (default: 5)
  --output-dir <path>         Base output dir (default: ~/.openclaw/workspace/AutoLife/MetaNotes/web_search_runs)
  --open-url <url>            Open a fixed URL directly (for login/bootstrap) and skip default queries.
  --profile-dir <path>        Chrome profile/cache dir (default: ~/.local/share/web-search-selenium/browser-profile)
  --debug-port <port>         Chrome remote debugging port (default: 9222)
  --run-id <id>               Override run id (subfolder name)
  --env <conda-env>           Conda env for web_search_selenium_cli (default: clawbot)
  --headless                  Run browser in headless mode
  --keep-open                 Keep browser open after each query (for Google sign-in/cache bootstrap)
  --hold-seconds <seconds>    Keep-open duration before close (0 = wait for Enter in tty)
  --attach                    Attach to existing Chrome session on debug port
  --no-attach                 Force creating/using new browser session
  --no-auto-attach            Disable auto-attach when a reusable session exists
  --dismiss-cookies           Force cookie dismissal during searches
  --no-dismiss-cookies        Skip cookie dismissal (default: enabled)
  --search-tool <path>        Override search script path
  -h, --help                  Show help

Output:
  <output-dir>/<run-id>/web_search_results.txt
  <output-dir>/<run-id>/query-<safe-name>.json (raw JSON from search tool)
  <output-dir>/<run-id>/query-<safe-name>.txt (parsed text for each query)
  <output-dir>/<run-id>/screenshots/*.png (search results page capture)
USAGE
  exit 1
}

safe_slug() {
  # Lowercase, remove non-safe chars, collapse separators, trim edges.
  print -n "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --query)
      shift
      if [[ "$#" -eq 0 ]]; then
        echo "--query requires a value" >&2
        exit 1
      fi
      QUERIES+=("$1")
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
    --output-dir)
      shift
      [[ "$#" -gt 0 ]] || { echo "--output-dir requires a value" >&2; exit 1; }
      OUTPUT_ROOT="$1"
      ;;
    --open-url)
      shift
      [[ "$#" -gt 0 ]] || { echo "--open-url requires a value" >&2; exit 1; }
      OPEN_URL="$1"
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
    --context-path)
      shift
      [[ "$#" -gt 0 ]] || { echo "--context-path requires a value" >&2; exit 1; }
      CONTEXT_PATH="$1"
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
    --dismiss-cookies)
      DISMISS_COOKIES=1
      ;;
    --no-dismiss-cookies)
      DISMISS_COOKIES=0
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
    --search-tool)
      shift
      [[ "$#" -gt 0 ]] || { echo "--search-tool requires a value" >&2; exit 1; }
      RUN_TOOL="$1"
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

if [[ ! -x "$RUN_TOOL" ]]; then
  echo "search tool not executable: $RUN_TOOL" >&2
  exit 1
fi

RUN_DIR="${OUTPUT_ROOT}/${RUN_ID}"
mkdir -p "$RUN_DIR"

SUMMARY_FILE="${RUN_DIR}/web_search_results.txt"
: > "$SUMMARY_FILE"

printf '%s\n' "# prompt_web_search run ${RUN_ID}" | tee -a "$SUMMARY_FILE"
printf '%s\n' "run_at_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee -a "$SUMMARY_FILE"
printf '%s\n' "engine=$ENGINE results=$RESULTS" | tee -a "$SUMMARY_FILE"
printf '%s\n' "conda_env=$CONDA_ENV" | tee -a "$SUMMARY_FILE"
printf '%s\n' "open_url=$OPEN_URL" | tee -a "$SUMMARY_FILE"
printf '%s\n' "profile_dir=$PROFILE_DIR" | tee -a "$SUMMARY_FILE"
printf '%s\n' "debug_port=$DEBUG_PORT" | tee -a "$SUMMARY_FILE"
SCREENSHOT_DIR="${RUN_DIR}/screenshots"
mkdir -p "$SCREENSHOT_DIR"
printf '%s\n' "screenshot_dir=$SCREENSHOT_DIR" | tee -a "$SUMMARY_FILE"
if [[ -n "$OPEN_URL" ]]; then
  printf '%s\n\n' "open_url_mode=1" | tee -a "$SUMMARY_FILE"
else
  if [[ "${#QUERIES[@]}" -eq 0 && -n "$CONTEXT_PATH" ]]; then
    while IFS= read -r line; do
      [[ -n "$line" ]] && QUERIES+=("$line")
    done < <(
      python3 - "$CONTEXT_PATH" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1]).expanduser()
if not path.exists() or not path.is_file():
  raise SystemExit(0)

text = path.read_text(encoding="utf-8", errors="ignore")
terms = re.findall(r"[A-Za-z][A-Za-z0-9+.#-]{3,}", text.lower())
stop = {
  "the", "and", "for", "with", "from", "this", "that", "company", "team", "using",
  "about", "their", "there", "your", "will", "which", "also", "into", "have", "been",
  "were", "when", "such", "more",
}
seen = set()
for term in terms:
  if term in stop:
    continue
  if term in seen:
    continue
  seen.add(term)
  print(term)
PY
    )
  fi
  printf '%s\n\n' "queries=${#QUERIES[@]}" | tee -a "$SUMMARY_FILE"
  if [[ "${#QUERIES[@]}" -eq 0 ]]; then
    printf '%s\n' "No query list provided and no context path. Skipping web search." | tee -a "$SUMMARY_FILE"
    printf '<p>Skipped: no query list or context provided.</p>' > "$RUN_DIR/web_search_results.txt"
    exit 0
  fi
fi

if [[ -n "$OPEN_URL" ]]; then
  QUERY_TASKS=( "__open_url__" )
else
  QUERY_TASKS=("${QUERIES[@]}")
fi

check_debugger_port() {
  local port="$1"
  local out
  out="$(python - "$port" <<'PY'
import socket
import sys

port = int(sys.argv[1])
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
try:
    sock.settimeout(0.5)
    open_port = sock.connect_ex(('127.0.0.1', port)) == 0
    print('1' if open_port else '0')
finally:
    sock.close()
PY
)"
  [[ "$out" == "1" ]]
}

if [[ "$ATTACH_SESSION" -eq 1 ]] || { [[ "$AUTO_ATTACH" -eq 1 ]] && check_debugger_port "$DEBUG_PORT"; }; then
  ATTACH_ARGS=(--attach --debugger-address "127.0.0.1:${DEBUG_PORT}")
else
  ATTACH_ARGS=()
fi

for raw_query in "${QUERY_TASKS[@]}"; do
  [[ -n "$raw_query" ]] || continue
  slug="$(safe_slug "$raw_query")"
  query_file_json="${RUN_DIR}/query-${slug}.json"
  query_file_txt="${RUN_DIR}/query-${slug}.txt"

  if [[ -n "$OPEN_URL" ]]; then
    args=(--env "$CONDA_ENV" --engine "$ENGINE" --output text)
  else
    args=(--env "$CONDA_ENV" --engine "$ENGINE" --results "$RESULTS" --output json)
  fi
  args+=(--capture-screenshots --screenshot-dir "$SCREENSHOT_DIR" --screenshot-prefix "${RUN_ID}-${slug}")
  if [[ "$DISMISS_COOKIES" -eq 1 ]]; then
    args+=(--dismiss-cookies)
  fi
  args+=(--profile-dir "$PROFILE_DIR" --remote-debugging-port "$DEBUG_PORT")
  if [[ ${#ATTACH_ARGS[@]} -gt 0 ]]; then
    args+=("${ATTACH_ARGS[@]}")
  fi
  if [[ -n "$OPEN_URL" ]]; then
    args+=(--open-url "$OPEN_URL")
  else
    args+=("$raw_query")
  fi
  if [[ "$HEADLESS" -eq 1 ]]; then
    args+=(--headless)
  fi
  if [[ "$KEEP_OPEN" -eq 1 ]]; then
    args+=(--keep-open --hold-seconds "$HOLD_SECONDS")
  fi
  

  set +e
  "$RUN_TOOL" "${args[@]}" >"$query_file_json" 2>"${RUN_DIR}/query-${slug}.err"
  rc=$?
  set -e

  if [[ -n "$OPEN_URL" ]]; then
    printf '%s\n' "## Open URL: $OPEN_URL" >> "$SUMMARY_FILE"
  else
    printf '%s\n' "## Query: $raw_query" >> "$SUMMARY_FILE"
  fi
  printf '%s\n' "status_code=${rc}" >> "$SUMMARY_FILE"

  if [[ $rc -ne 0 ]]; then
    printf '%s\n' "search failed, see ${RUN_DIR}/query-${slug}.err" >> "$SUMMARY_FILE"
    printf '%s\n' >> "$SUMMARY_FILE"
    cat "${RUN_DIR}/query-${slug}.err" >> "$SUMMARY_FILE"
    printf '%s\n' "" >> "$SUMMARY_FILE"
    continue
  fi

  if [[ -n "$OPEN_URL" ]]; then
    cat "$query_file_json" > "$query_file_txt"
    printf '%s\n' "{\"mode\":\"open-url\",\"url\":\"$OPEN_URL\"}" > "$query_file_json"
    printf '%s\n' "open_url_target=$OPEN_URL" >> "$SUMMARY_FILE"
    printf '%s\n' "text_file=${query_file_txt}" | tee -a "$SUMMARY_FILE"
    printf '%s\n' "json_file=${query_file_json}" | tee -a "$SUMMARY_FILE"
    printf '%s\n' >> "$SUMMARY_FILE"
    cat "$query_file_txt" >> "$SUMMARY_FILE"
    printf '%s\n\n' "---" >> "$SUMMARY_FILE"
  else
    python3 - "$raw_query" "$query_file_json" "$query_file_txt" <<'PY'
import json
import sys
from pathlib import Path

query, json_path, out_path = sys.argv[1:4]

out = []
path = Path(json_path)
raw = path.read_text(encoding="utf-8")
try:
    payload = json.loads(raw)
except json.JSONDecodeError as exc:
    payload = None
    out.append(f"query: {query}")
    out.append(f"json_parse_error={exc}")
    out.append(raw.strip()[:2000])
else:
    out.append(f"query: {payload.get('query', query)}")
    items = payload.get("items", []) if isinstance(payload, dict) else []
    search_overviews = payload.get("search_page_overviews", []) if isinstance(payload, dict) else []
    search_screenshots = payload.get("search_page_screenshots", []) if isinstance(payload, dict) else []
    run_screenshots = payload.get("screenshots", []) if isinstance(payload, dict) else []
    if search_overviews:
        out.append("search_result_page_scan:")
        for row in search_overviews:
            if not isinstance(row, dict):
                continue
            page = row.get("page", "")
            row_summary = str(row.get("summary", "")).strip()
            if row_summary:
                out.append(f"  - page {page}: {row_summary[:320]}")
    if search_screenshots:
        out.append("search_result_page_screenshots:")
        for path in search_screenshots:
            out.append(f"  - {path}")
    if run_screenshots:
        out.append("capture_screenshots:")
        for path in run_screenshots:
            out.append(f"  - {path}")
    out.append(f"count: {len(items)}")
    for idx, item in enumerate(items, 1):
        title = (item.get("title") or "").strip()
        url = (item.get("url") or "").strip()
        snippet = (item.get("snippet") or "").strip()
        out.append(f"[{idx}] {title or '(untitled)'}")
        if url:
            out.append(f"url: {url}")
        if snippet:
            out.append(f"snippet: {snippet}")
        out.append("")

Path(out_path).write_text("\n".join(out).rstrip() + "\n", encoding="utf-8")
PY

  printf '%s\n' "text_file=${query_file_txt}" | tee -a "$SUMMARY_FILE"
  printf '%s\n' "json_file=${query_file_json}" | tee -a "$SUMMARY_FILE"
  printf '%s\n' >> "$SUMMARY_FILE"
  cat "$query_file_txt" >> "$SUMMARY_FILE"
  printf '%s\n\n' "---" >> "$SUMMARY_FILE"
  fi
done

printf '%s\n' "output_dir=${RUN_DIR}" | tee -a "$SUMMARY_FILE"
printf '%s\n' "saved summary: ${SUMMARY_FILE}"
