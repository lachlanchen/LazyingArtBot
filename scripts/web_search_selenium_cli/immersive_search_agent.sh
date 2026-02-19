#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_TOOL="${SCRIPT_DIR}/immersive_search.sh"
CODEX_BIN="${CODEX_BIN:-codex}"

ENV_NAME="${WEB_SEARCH_ENV:-clawbot}"
ENGINE="google"
RESULTS=6
RUN_ID="$(date +%Y%m%d-%H%M%S)"
OUTPUT_ROOT="${HOME}/.openclaw/workspace/AutoLife/MetaNotes/web_search_runs"
PROFILE_DIR="${HOME}/.local/share/web-search-selenium/browser-profile"
DEBUG_PORT="9222"
SUMMARY_MAX_CHARS="2200"
KEEP_OPEN=0
HOLD_SECONDS="0"
USE_CODEX_CLICK=0
CODEX_MODEL="${CODEX_MODEL:-gpt-5.3-codex-spark}"
CODEX_REASONING="${CODEX_REASONING:-high}"
CODEX_SAFETY="${CODEX_SAFETY:-danger-full-access}"
CODEX_APPROVAL="${CODEX_APPROVAL:-never}"
MANUAL_CLICK=""
DISMISS_COOKIES=1
QUERY=""

usage() {
  cat <<'USAGE'
Usage: immersive_search_agent.sh [options]

Run an immersive, non-headless Google UI search, capture screenshots, and optionally
ask Codex (with the screenshot) for a click coordinate.

Options:
  --query <text>                Required query string.
  --engine <google|google-scholar|google-news|duckduckgo|bing>
  --results <n>                 Max results (default: 6)
  --run-id <id>                 Override run folder name.
  --output-dir <path>           Base output directory.
  --env <conda-env>             Conda environment for selenium tool (default: clawbot)
  --profile-dir <path>          Chrome profile path (cookie/session cache)
  --debug-port <port>           Chrome remote debug port (default: 9222)
  --summary-max-chars <n>       Max chars for open-page summary.
  --keep-open                    Keep browser open after click.
  --hold-seconds <n>            Keep-open duration (default: 0)
  --click-at <x,y>              Manual coordinate click (skip Codex decision)
  --codex-click                  Ask Codex from screenshot to pick coordinates
  --model <name>                 Codex model (default: gpt-5.3-codex-spark)
  --reasoning <low|medium|high|extra_high>
  --safety <danger-full-access|workspace-write|read-only>
  --approval <never|on-request|on-failure|untrusted>
  --no-dismiss-cookies           Do not auto-dismiss cookie overlays
  --help

Examples:
  scripts/web_search_selenium_cli/immersive_search_agent.sh --query "wearable glass paper" --codex-click
  scripts/web_search_selenium_cli/immersive_search_agent.sh --query "nature paper" --click-at "1180,390"
USAGE
  exit 1
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
    --summary-max-chars)
      shift
      [[ "$#" -gt 0 ]] || { echo "--summary-max-chars requires value" >&2; exit 1; }
      SUMMARY_MAX_CHARS="$1"
      ;;
    --keep-open)
      KEEP_OPEN=1
      ;;
    --hold-seconds)
      shift
      [[ "$#" -gt 0 ]] || { echo "--hold-seconds requires value" >&2; exit 1; }
      HOLD_SECONDS="$1"
      ;;
    --click-at)
      shift
      [[ "$#" -gt 0 ]] || { echo "--click-at requires value" >&2; exit 1; }
      MANUAL_CLICK="$1"
      ;;
    --codex-click)
      USE_CODEX_CLICK=1
      ;;
    --model)
      shift
      [[ "$#" -gt 0 ]] || { echo "--model requires value" >&2; exit 1; }
      CODEX_MODEL="$1"
      ;;
    --reasoning)
      shift
      [[ "$#" -gt 0 ]] || { echo "--reasoning requires value" >&2; exit 1; }
      CODEX_REASONING="$1"
      ;;
    --safety)
      shift
      [[ "$#" -gt 0 ]] || { echo "--safety requires value" >&2; exit 1; }
      CODEX_SAFETY="$1"
      ;;
    --approval)
      shift
      [[ "$#" -gt 0 ]] || { echo "--approval requires value" >&2; exit 1; }
      CODEX_APPROVAL="$1"
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

if [[ -z "${QUERY}" ]]; then
  echo "--query is required" >&2
  usage
fi

if ! command -v conda >/dev/null 2>&1; then
  echo "conda not found in PATH" >&2
  exit 1
fi

if ! command -v "$CODEX_BIN" >/dev/null 2>&1; then
  echo "codex binary not found: ${CODEX_BIN}" >&2
  exit 1
fi

if [[ ! -x "$RUN_TOOL" ]]; then
  echo "missing web search wrapper: ${RUN_TOOL}" >&2
  exit 1
fi

safe_slug() {
  local raw="$1"
  raw="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')"
  raw="$(printf '%s' "$raw" | tr -cs 'a-z0-9' '-' | sed -E 's/^-+//; s/-+$//')"
  echo "${raw:-query}"
}

run_json_path() {
  local phase="$1"
  local phase_run_id="${RUN_ID}-${phase}"
  local slug
  slug="$(safe_slug "$QUERY")"
  echo "${OUTPUT_ROOT%/}/${phase_run_id}/query-${slug}.json"
}

run_pass() {
  local phase="$1"
  local click_at="$2"
  local phase_run_id="${RUN_ID}-${phase}"
  local args=(
    --query "$QUERY"
    --engine "$ENGINE"
    --results "$RESULTS"
    --run-id "$phase_run_id"
    --output-dir "$OUTPUT_ROOT"
    --env "$ENV_NAME"
    --profile-dir "$PROFILE_DIR"
    --debug-port "$DEBUG_PORT"
    --summarize-open-url
    --summary-max-chars "$SUMMARY_MAX_CHARS"
  )

  if [[ -n "$click_at" ]]; then
    args+=(--click-at "$click_at")
  fi

  if [[ "$DISMISS_COOKIES" -eq 1 ]]; then
    args+=(--dismiss-cookies)
  else
    args+=(--no-dismiss-cookies)
  fi

  if [[ "$KEEP_OPEN" -eq 1 ]]; then
    args+=(--keep-open --hold-seconds "$HOLD_SECONDS")
  fi

  echo "launching search: scripts/web_search_selenium_cli/immersive_search.sh ${args[*]}"
  set +e
  "$RUN_TOOL" "${args[@]}"
  local rc=$?
  set -e
  if [[ $rc -ne 0 ]]; then
    echo "immersive search failed rc=${rc}" >&2
    exit "$rc"
  fi

  local json_path
  json_path="$(run_json_path "$phase")"
  if [[ ! -f "$json_path" ]]; then
    echo "missing result file after phase=${phase}: ${json_path}" >&2
    exit 1
  fi
}

print_run_summary() {
  local json_path="$1"
  local phase="$2"
  python3 - "$json_path" "$phase" <<'PY'
import json
import sys

path = sys.argv[1]
phase = sys.argv[2]
payload = json.loads(open(path, "r", encoding="utf-8").read())

if phase == "initial":
    items = payload.get("items", [])
    print(f"[{phase}] results={len(items)}")
    print(f"[{phase}] screenshots={len(payload.get('screenshots', []))}")
    for item in items[:8]:
        title = (item.get("title") or "").strip()
        url = (item.get("url") or "").strip()
        if title or url:
            print(f"  - {title} | {url}")
    return

clicked = payload.get("clicked")
if isinstance(clicked, dict):
    print(f"[{phase}] clicked_result_index={clicked.get('result_index')}")
    print(f"[{phase}] clicked_title={(clicked.get('title') or '').strip()}")
    print(f"[{phase}] clicked_url={(clicked.get('url') or '').strip()}")
    print(f"[{phase}] clicked_summary={(clicked.get('summary') or '').strip()}")
else:
    print(f"[{phase}] no clicked result in payload")
PY
}

select_click_with_codex() {
  local screenshot="$1"
  local query="$2"
  local output
  local parsed
  local coord
  local reason
  local hint

  if [[ ! -f "$screenshot" ]]; then
    echo "screenshot not found: ${screenshot}" >&2
    return 1
  fi

  local prompt_file
  prompt_file="$(mktemp)"
  cat > "$prompt_file" <<EOF
You are a browser automation assistant.
I captured a Google search page screenshot after running a query.

Task:
1) Choose the best click target for this query.
2) Return STRICT JSON only with fields:
{
  "x": <integer>,
  "y": <integer>,
  "reason": "<short reason>",
  "result_hint": "<short selected link hint>"
}

Rules:
- Choose a point where the target link is visibly clickable.
- Use actual integer coordinates in browser coordinate space.
- Prefer the first high-confidence result matching the query.
- If you cannot find any target, return:
  {"x": -1, "y": -1, "reason":"not_found","result_hint":"no_confident_target"}

Query:
${query}
EOF

  output="$(mktemp)"
  set +e
  "$CODEX_BIN" exec \
    --model "$CODEX_MODEL" \
    -c "model_reasoning_effort=\"$CODEX_REASONING\"" \
    -s "$CODEX_SAFETY" \
    -a "$CODEX_APPROVAL" \
    --skip-git-repo-check \
    --output-last-message "$output" \
    -i "$screenshot" < "$prompt_file"
  local codex_rc=$?
  set -e

  rm -f "$prompt_file"
  if [[ $codex_rc -ne 0 ]]; then
    rm -f "$output"
    echo "codex coordinate pass failed rc=${codex_rc}" >&2
    return "$codex_rc"
  fi

  parsed="$(mktemp)"
  python3 - "$output" > "$parsed" <<'PY'
import json
import re
import sys

path = sys.argv[1]
text = open(path, "r", encoding="utf-8").read()
match = re.search(r"\{[\s\S]*\}", text)
if not match:
    raise SystemExit("No JSON in codex output")

obj = json.loads(match.group(0))
x = obj.get("x")
y = obj.get("y")
reason = obj.get("reason", "")
hint = obj.get("result_hint", "")
if x is None or y is None:
    raise SystemExit("Missing x/y")

print(f"{int(x)},{int(y)}")
print((reason or "").replace("\n", " "))
print((hint or "").replace("\n", " "))
PY

  readarray -t parsed_lines < "$parsed"
  rm -f "$parsed" "$output"

  coord="${parsed_lines[0]:-}"
  reason="${parsed_lines[1]:-}"
  hint="${parsed_lines[2]:-}"

  if [[ -z "$coord" ]]; then
    echo "codex did not return coordinate" >&2
    return 1
  fi
  if [[ "$coord" == "-1,-1" ]]; then
    echo "codex could not find target, reason=${reason:-n/a}, hint=${hint:-n/a}" >&2
    return 1
  fi

  CLICK_REASON="$reason"
  CLICK_HINT="$hint"
  echo "$coord"
}

run_pass "initial" ""

INITIAL_JSON="$(run_json_path "initial")"
if [[ ! -f "$INITIAL_JSON" ]]; then
  echo "missing initial result file: ${INITIAL_JSON}" >&2
  exit 1
fi

print_run_summary "$INITIAL_JSON" "initial"

if [[ "$USE_CODEX_CLICK" -eq 0 && -z "$MANUAL_CLICK" ]]; then
  echo "No click requested. Add --codex-click or --click-at <x,y> to click."
  exit 0
fi

if [[ -z "$MANUAL_CLICK" ]]; then
  INITIAL_SHOT="$(python3 - "$INITIAL_JSON" <<'PY'
import json
import sys
payload = json.loads(open(sys.argv[1], "r", encoding="utf-8").read())
shots = payload.get("screenshots") or []
if not shots:
    raise SystemExit("")
print(shots[-1])
PY
)"
  if [[ -z "$INITIAL_SHOT" ]]; then
    INITIAL_DIR="$(run_json_path "initial" | sed 's#/query-.*#/#')"
    INITIAL_SHOT="$(find "$INITIAL_DIR/screenshots" -type f -name '*.png' | head -n 1 || true)"
  fi

  if [[ -z "$INITIAL_SHOT" || ! -f "$INITIAL_SHOT" ]]; then
    echo "could not locate initial screenshot for Codex click decision" >&2
    exit 1
  fi

  echo "codex_click_screenshot=${INITIAL_SHOT}"

  CLICK_REASON=""
  CLICK_HINT=""
  CLICK_COORD="$(select_click_with_codex "$INITIAL_SHOT" "$QUERY")" || {
    exit_code=$?
    echo "failed to select click point by codex (rc=${exit_code})" >&2
    exit "$exit_code"
  }
  MANUAL_CLICK="$CLICK_COORD"
  echo "codex_click_reason=${CLICK_REASON:-not_provided}"
  echo "codex_click_hint=${CLICK_HINT:-not_provided}"
  echo "codex_click_point=${MANUAL_CLICK}"
fi

run_pass "clicked" "$MANUAL_CLICK"

CLICK_JSON="$(run_json_path "clicked")"
if [[ ! -f "$CLICK_JSON" ]]; then
  echo "missing clicked result file: ${CLICK_JSON}" >&2
  exit 1
fi

print_run_summary "$CLICK_JSON" "clicked"
echo "initial_json=${INITIAL_JSON}"
echo "clicked_json=${CLICK_JSON}"
echo "run_dir_initial=${OUTPUT_ROOT%/}/${RUN_ID}-initial"
echo "run_dir_clicked=${OUTPUT_ROOT%/}/${RUN_ID}-clicked"
