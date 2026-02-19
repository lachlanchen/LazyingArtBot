#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_TOOL="${SCRIPT_DIR}/run_search.sh"
ENV_NAME="${WEB_SEARCH_ENV:-clawbot}"
ENGINE="google"
RESULTS=5
START_PAGE=1
END_PAGE=1
SCROLL_STEPS=3
SCROLL_PAUSE=0.9
RUN_ID="$(date +%Y%m%d-%H%M%S)"
OUTPUT_ROOT="${HOME}/.openclaw/workspace/AutoLife/MetaNotes/web_search_runs"
PROFILE_DIR="${HOME}/.local/share/web-search-selenium/browser-profile"
DEBUG_PORT="9222"
ATTACH_SESSION=0
AUTO_ATTACH=1
HEADLESS=0
KEEP_OPEN=0
HOLD_SECONDS=0
DISMISS_COOKIES="${WEB_SEARCH_DISMISS_COOKIES:-1}"
SUMMARY_MAX_CHARS=2500
QUERY=""
CLICK_AT=""
RESULT_INDEX=1
OPEN_RESULT=0
OPEN_TOP_RESULTS=0
SUMMARIZE_OPEN=0
OPEN_URL=""

usage() {
  cat <<'USAGE'
Usage: immersive_search.sh [options]

Perform a non-headless Google UI (immersive) search and capture screenshots.

Options:
  --query <text>                Required query string (can be used once)
  --engine <google|google-scholar|google-news|duckduckgo|bing>
                                Search engine (default: google)
  --results <n>                 Max results (default: 5)
  --run-id <id>                 Override run folder name
  --output-dir <path>           Base output directory (default: ~/.openclaw/workspace/AutoLife/MetaNotes/web_search_runs)
  --env <conda-env>             Conda environment for run_search.sh (default: clawbot)
  --profile-dir <path>          Chrome profile path (default: ~/.local/share/web-search-selenium/browser-profile)
  --debug-port <port>           Remote debugging port used for attach mode (default: 9222)
  --attach                      Reuse an existing Chrome debugger session
  --no-attach                   Force new session
  --headless                    Run browser headless (default: off)
  --open-result                 Click selected result index instead of coordinate click
  --result-index <n>            Result index for --open-result (default: 1)
  --open-top-results <n>        Open and summarize the first N results (default: 0)
  --click-at <x,y>              Click absolute browser coords before summary
  --summarize-open-url          Extract visible-page text after open/click
  --summary-max-chars <n>       Max chars from open page summary (default: 2500)
  --start-page <n>              Search page start index (default: 1)
  --end-page <n>                Search page end index (default: 1)
  --scroll-steps <n>            How many scroll steps on opened URL (default: 3)
  --scroll-pause <sec>          Delay between scroll steps in seconds (default: 0.9)
  --open-url <url>              Open URL directly, skipping search
  --dismiss-cookies              Try common cookie consent dismissals
  --no-dismiss-cookies           Skip cookie consent dismissals
  --keep-open                   Keep browser open after run
  --hold-seconds <n>            Seconds to keep browser when --keep-open (default: 0)
  --help
USAGE
  exit 1
}

safe_slug() {
  local raw="$1"
  raw="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')"
  raw="$(printf '%s' "$raw" | tr -cs '[:alnum:]' '-' | sed -E 's/^-+//; s/-+$//')"
  raw="${raw:0:80}"
  echo "${raw:-search}"
}

check_debugger_port() {
  local port="$1"
  local out
  out="$(python3 - "$port" <<'PY'
import socket
import sys

port = int(sys.argv[1])
sock = socket.socket()
sock.settimeout(0.5)
try:
    open_ok = sock.connect_ex(("127.0.0.1", port)) == 0
finally:
    sock.close()
print("1" if open_ok else "0")
PY
)"
  [[ "$out" == "1" ]]
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --query)
      shift
      [[ "$#" -gt 0 ]] || { echo "--query requires value" >&2; exit 1; }
      QUERY="$1"
      ;;
    --engine)
      shift
      [[ "$#" -gt 0 ]] || { echo "--engine requires value" >&2; exit 1; }
      ENGINE="$1"
      ;;
    --results)
      shift
      [[ "$#" -gt 0 ]] || { echo "--results requires value" >&2; exit 1; }
      RESULTS="$1"
      ;;
    --run-id)
      shift
      [[ "$#" -gt 0 ]] || { echo "--run-id requires value" >&2; exit 1; }
      RUN_ID="$1"
      ;;
    --output-dir)
      shift
      [[ "$#" -gt 0 ]] || { echo "--output-dir requires value" >&2; exit 1; }
      OUTPUT_ROOT="$1"
      ;;
    --env)
      shift
      [[ "$#" -gt 0 ]] || { echo "--env requires value" >&2; exit 1; }
      ENV_NAME="$1"
      ;;
    --profile-dir)
      shift
      [[ "$#" -gt 0 ]] || { echo "--profile-dir requires value" >&2; exit 1; }
      PROFILE_DIR="$1"
      ;;
    --debug-port)
      shift
      [[ "$#" -gt 0 ]] || { echo "--debug-port requires value" >&2; exit 1; }
      DEBUG_PORT="$1"
      ;;
    --attach)
      ATTACH_SESSION=1
      ;;
    --no-attach)
      ATTACH_SESSION=0
      AUTO_ATTACH=0
      ;;
    --headless)
      HEADLESS=1
      ;;
    --open-result)
      OPEN_RESULT=1
      ;;
    --result-index)
      shift
      [[ "$#" -gt 0 ]] || { echo "--result-index requires value" >&2; exit 1; }
      RESULT_INDEX="$1"
      ;;
    --open-top-results)
      shift
      [[ "$#" -gt 0 ]] || { echo "--open-top-results requires value" >&2; exit 1; }
      OPEN_TOP_RESULTS="$1"
      ;;
    --click-at)
      shift
      [[ "$#" -gt 0 ]] || { echo "--click-at requires value" >&2; exit 1; }
      CLICK_AT="$1"
      ;;
    --summarize-open-url)
      SUMMARIZE_OPEN=1
      ;;
    --summary-max-chars)
      shift
      [[ "$#" -gt 0 ]] || { echo "--summary-max-chars requires value" >&2; exit 1; }
      SUMMARY_MAX_CHARS="$1"
      ;;
    --start-page)
      shift
      [[ "$#" -gt 0 ]] || { echo "--start-page requires value" >&2; exit 1; }
      START_PAGE="$1"
      ;;
    --end-page)
      shift
      [[ "$#" -gt 0 ]] || { echo "--end-page requires value" >&2; exit 1; }
      END_PAGE="$1"
      ;;
    --scroll-steps)
      shift
      [[ "$#" -gt 0 ]] || { echo "--scroll-steps requires value" >&2; exit 1; }
      SCROLL_STEPS="$1"
      ;;
    --scroll-pause)
      shift
      [[ "$#" -gt 0 ]] || { echo "--scroll-pause requires value" >&2; exit 1; }
      SCROLL_PAUSE="$1"
      ;;
    --open-url)
      shift
      [[ "$#" -gt 0 ]] || { echo "--open-url requires value" >&2; exit 1; }
      OPEN_URL="$1"
      ;;
    --dismiss-cookies)
      DISMISS_COOKIES=1
      ;;
    --no-dismiss-cookies)
      DISMISS_COOKIES=0
      ;;
    --keep-open)
      KEEP_OPEN=1
      ;;
    --hold-seconds)
      shift
      [[ "$#" -gt 0 ]] || { echo "--hold-seconds requires value" >&2; exit 1; }
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

if [[ -z "$QUERY" && -z "$OPEN_URL" ]]; then
  echo "--query (or --open-url) is required" >&2
  usage
fi

if ! command -v conda >/dev/null 2>&1; then
  echo "conda not found in PATH" >&2
  exit 1
fi

if [[ ! -x "$RUN_TOOL" ]]; then
  echo "search tool is not executable: $RUN_TOOL" >&2
  exit 1
fi

RUN_DIR="${OUTPUT_ROOT%/}/${RUN_ID}"
mkdir -p "$RUN_DIR/screenshots"
QUERY_SLUG="$(safe_slug "${QUERY:-open-url}")"
JSON_FILE="${RUN_DIR}/query-${QUERY_SLUG}.json"
TXT_FILE="${RUN_DIR}/query-${QUERY_SLUG}.txt"
ERR_FILE="${RUN_DIR}/query-${QUERY_SLUG}.err"

if [[ "$AUTO_ATTACH" -eq 1 ]] && [[ "$ATTACH_SESSION" -eq 0 ]] && check_debugger_port "$DEBUG_PORT"; then
  ATTACH_SESSION=1
fi

if [[ -n "$OPEN_URL" ]]; then
  SRC_ARGS=(--open-url "$OPEN_URL")
else
  SRC_ARGS=(--query "$QUERY")
  if [[ "$ENGINE" == "google" || "$ENGINE" == "google-scholar" || "$ENGINE" == "google-news" ]]; then
    SRC_ARGS+=(--immersive)
  fi
fi

CLI_ARGS=(
  --env "$ENV_NAME"
  --engine "$ENGINE"
  --results "$RESULTS"
  --start-page "$START_PAGE"
  --end-page "$END_PAGE"
  --output json
  --capture-screenshots
  --screenshot-dir "${RUN_DIR}/screenshots"
  --screenshot-prefix "$RUN_ID"
  --profile-dir "$PROFILE_DIR"
  --remote-debugging-port "$DEBUG_PORT"
  "${SRC_ARGS[@]}"
)

if [[ -n "$CLICK_AT" ]]; then
  CLI_ARGS+=(--click-at "$CLICK_AT")
fi

if [[ "$OPEN_RESULT" -eq 1 ]]; then
  CLI_ARGS+=(--open-result --result-index "$RESULT_INDEX")
fi
if [[ "$OPEN_TOP_RESULTS" -gt 0 ]]; then
  CLI_ARGS+=(--open-top-results "$OPEN_TOP_RESULTS")
fi

if [[ "$SUMMARIZE_OPEN" -eq 1 ]]; then
  CLI_ARGS+=(--summarize-open-url --summary-max-chars "$SUMMARY_MAX_CHARS" --scroll-steps "$SCROLL_STEPS" --scroll-pause "$SCROLL_PAUSE")
fi

if [[ "$HEADLESS" -eq 1 ]]; then
  CLI_ARGS+=(--headless)
fi

if [[ "$KEEP_OPEN" -eq 1 ]]; then
  CLI_ARGS+=(--keep-open --hold-seconds "$HOLD_SECONDS")
fi

if [[ "$DISMISS_COOKIES" -eq 1 ]]; then
  CLI_ARGS+=(--dismiss-cookies)
fi

if [[ "$ATTACH_SESSION" -eq 1 ]]; then
  CLI_ARGS+=(--attach --debugger-address "127.0.0.1:${DEBUG_PORT}")
fi

echo "launching: $RUN_TOOL ${CLI_ARGS[*]}"
set +e
"$RUN_TOOL" "${CLI_ARGS[@]}" >"$JSON_FILE" 2>"$ERR_FILE"
rc=$?
set -e

python3 - "$JSON_FILE" "$TXT_FILE" "$QUERY" "$ENGINE" <<'PY'
import json
import sys
from pathlib import Path

payload_path = Path(sys.argv[1])
txt_path = Path(sys.argv[2])
query = sys.argv[3]
engine = sys.argv[4]

txt_lines = [
    "# immersive_search result",
    f"query={query}",
    f"engine={engine}",
]

if not payload_path.exists():
    txt_lines.append(f"json_missing={payload_path}")
else:
    try:
        payload = json.loads(payload_path.read_text(encoding="utf-8"))
    except Exception as exc:
        txt_lines.append(f"json_parse_error={exc}")
        payload = None

    if payload is not None:
        txt_lines.append(f"mode={payload.get('mode', 'search')}")
        txt_lines.append(
            f"results_count={payload.get('count') if payload.get('count') is not None else payload.get('results_count', 0)}"
        )
        items = payload.get("items")
        if not isinstance(items, list):
            items = payload.get("results", [])
            if not isinstance(items, list):
                items = []
        txt_lines.append(f"screenshots={payload.get('screenshots', [])}")
        viewport = payload.get("viewport") or {}
        if isinstance(viewport, dict) and viewport:
            txt_lines.append(
                "viewport="
                + ",".join(f"{key}={viewport[key]}" for key in sorted(viewport.keys()))
            )
        overviews = payload.get("search_page_overviews", [])
        if isinstance(overviews, list) and overviews:
            txt_lines.append("search_page_overviews:")
            for row in overviews[:3]:
                if not isinstance(row, dict):
                    continue
                page = row.get("page", "")
                row_summary = str(row.get("summary", "")).strip()
                if row_summary:
                    txt_lines.append(f"  page={page} {row_summary[:320]}")
        clicked = payload.get("clicked") if isinstance(payload.get("clicked"), dict) else {}
        if clicked:
            txt_lines.append(f"clicked_index={clicked.get('result_index', '')}")
            txt_lines.append(f"clicked_title={clicked.get('title', '')}")
            txt_lines.append(f"clicked_url={clicked.get('url', '')}")
            clicked_summary = str(clicked.get("summary", "")).strip()
            if clicked_summary:
                txt_lines.append("clicked_summary=" + clicked_summary)
            clicked_screenshots = clicked.get("opened_screenshots")
            if isinstance(clicked_screenshots, list) and clicked_screenshots:
                txt_lines.append("clicked_screenshots=" + str(clicked_screenshots))
            clicked_steps = clicked.get("open_scroll_steps")
            if isinstance(clicked_steps, list) and clicked_steps:
                txt_lines.append(f"clicked_open_scroll_steps={len(clicked_steps)}")
        opened_items = payload.get("opened_items")
        if isinstance(opened_items, list):
            txt_lines.append(f"opened_count={len(opened_items)}")
            for item in opened_items[:8]:
                txt_lines.append("OPENED")
                txt_lines.append(f"  result_index={item.get('result_index', '')}")
                txt_lines.append(f"  title={item.get('title', '')}")
                txt_lines.append(f"  url={item.get('url', '')}")
                item_summary = str(item.get("summary", "")).strip()
                if item_summary:
                    txt_lines.append(f"  summary={item_summary[:2800]}")
                item_screenshots = item.get("opened_screenshots")
                if isinstance(item_screenshots, list) and item_screenshots:
                    txt_lines.append(f"  screenshots={item_screenshots}")
                item_steps = item.get("open_scroll_steps")
                if isinstance(item_steps, list) and item_steps:
                    txt_lines.append(f"  open_scroll_steps={len(item_steps)}")
        for item in items[:8]:
            txt_lines.append("RESULT")
            txt_lines.append(f"  title={item.get('title', '')}")
            txt_lines.append(f"  url={item.get('url', '')}")
            txt_lines.append(f"  snippet={item.get('snippet', '')}")
            if item.get("center_x") is not None:
                txt_lines.append(
                    f"  click_center=({item.get('center_x')},{item.get('center_y')})"
                )
            if item.get("element_width") is not None:
                txt_lines.append(
                    f"  element={item.get('element_x')},{item.get('element_y')} {item.get('element_width')}x{item.get('element_height')}"
                )
        txt_lines.append(f"screenshot_count={len(payload.get('screenshots', []))}")

txt_path.write_text("\n".join(txt_lines) + "\n", encoding="utf-8")
print("\n".join(txt_lines))
PY

if [[ "$rc" -ne 0 ]]; then
  echo "run failed rc=${rc}; details in ${ERR_FILE}"
  exit "$rc"
fi

echo "json=${JSON_FILE}"
echo "txt=${TXT_FILE}"
echo "screenshots:"
find "$RUN_DIR/screenshots" -maxdepth 1 -type f -name '*.png'
