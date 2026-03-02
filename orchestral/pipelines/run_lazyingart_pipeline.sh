#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
WORKSPACE="/Users/lachlan/.openclaw/workspace"
PROMPT_DIR="$REPO_DIR/orchestral/prompt_tools"
NOTES_ROOT="$WORKSPACE/AutoLife/MetaNotes/Companies/LazyingArt"
ARTIFACT_BASE="$WORKSPACE/AutoLife/MetaNotes/Companies/LazyingArt/pipeline_runs"
PIPELINE_LOCK_FILE="$ARTIFACT_BASE/.lazyingart_pipeline.lock"

DEFAULT_TO="lachchen@qq.com"
DEFAULT_FROM="lachlan.miao.chen@gmail.com"
MODEL="gpt-5.3-codex"
REASONING="medium"
SAFETY="${CODEX_SAFETY:-danger-full-access}"
APPROVAL="${CODEX_APPROVAL:-never}"
SEND_EMAIL=1
RUN_WEB_SEARCH=1
RUN_LEGAL_DEPT=1
RUN_LIFE_REMINDER=1
WRITE_REMINDER=1
TO_ADDR="$DEFAULT_TO"
FROM_ADDR="$DEFAULT_FROM"
ACADEMIC_RESEARCH=1
ACADEMIC_MAX_RESULTS=5
WEB_SEARCH_TOP_RESULTS=3
WEB_SEARCH_HOLD_SECONDS="15"
WEB_SEARCH_SCROLL_STEPS="3"
WEB_SEARCH_SCROLL_PAUSE="0.9"
WEB_SEARCH_HEADLESS="0"
LA_WEB_QUERY_BUDGET=6
LA_WEB_QUERY_PLANNER_PROMPT="$PROMPT_DIR/company/la_web_search_query_planner_prompt.md"
LA_LEGAL_PROMPT_FILE="$PROMPT_DIR/company/la_legal_dept_prompt.md"
LA_PRIMARY_BRAND="Lazying.art"
LA_WEBSITE="https://lazying.art"
LA_GITHUB_PROFILE="https://github.com/lachlanchen?tab=repositories"
ACADEMIC_QUERIES=()
ACADEMIC_QUERY_BUDGET=5
ACADEMIC_RSS_SOURCES=(
  "Nature:https://www.nature.com/nature.rss"
  "Science:https://www.science.org/action/showFeed?type=site&jc=science"
  "Cell:https://www.cell.com/cell/rss"
  "Nature Machine Intelligence:https://www.nature.com/natmachintell.rss"
)
LA_WEB_SEARCH_QUERIES=()
MARKET_CONTEXT_FILE=""
WEB_SEARCH_OUTPUT_DIR="$WORKSPACE/AutoLife/MetaNotes/web_search"
WEB_OUTPUT_DIR="$WEB_SEARCH_OUTPUT_DIR"
LIFEPATH_BASE="$HOME/Documents/LazyingArtBotIO/LazyingArt"
LIFE_INPUT_MD="$LIFEPATH_BASE/Input/LazyingArtCompanyInput.md"
LIFE_STATE_MD="$LIFEPATH_BASE/Output/LazyingArtLifeReminderState.md"
LEGAL_INPUT_ROOT="$LIFEPATH_BASE/Input/Legal"
RUN_RESOURCE_ANALYSIS=1
RESOURCE_OUTPUT_DIR="$LIFEPATH_BASE/Output/ResourceAnalysis"
RESOURCE_LABEL="lazyingart-resource-analysis"
FUNDING_LANGUAGE_POLICY="Chinese-first with concise EN/JP labels for operations and analysis."
MONEY_REVENUE_LANGUAGE_POLICY="Chinese-first with concise EN/JP labels."
ITIN_COMPANY_ROOT="/Users/lachlan/Documents/ITIN+Company"
RESOURCE_ROOTS=(
  "$LIFEPATH_BASE/Input"
  "$LIFEPATH_BASE/Output"
  "$ITIN_COMPANY_ROOT"
)

usage() {
  cat <<'USAGE'
Usage: run_lazyingart_pipeline.sh [options]

Runs the Lazying.art chain:
  market research -> academic -> legal/compliance -> funding ->
  monetization -> milestone plan -> entrepreneurship mentor ->
  life reverse reminder planning -> save notes under AutoLife ->
  compose/send HTML email

Options:
  --to <email>              Email recipient (default: lachchen@qq.com)
  --from <email>            Sender hint for Apple Mail (default: lachlan.miao.chen@gmail.com)
  --no-send-email           Build email draft only, do not send
  --send-email              Send email (default)
  --model <name>            Codex model (default: gpt-5.3-codex)
  --reasoning <level>       Reasoning level (default: medium)
  --market-context <path>   Optional extra context file for market step
  --legal-dept              Enable legal/compliance stage (default: on)
  --no-legal-dept           Disable legal/compliance stage
  --legal-root <path>       Legal materials root override
  --resource-output-dir <p> Resource analysis markdown output directory
  --resource-label <name>   Resource analysis marker/label
  --resource-root <path>    Add resource root (repeatable; default LazyingArt roots)
  --skip-resource-analysis   Skip upfront resource analysis stage
  --academic-query <text>    Add/override an academic query (repeatable)
  --academic-query-budget <n> Number of auto-generated academic queries (default: 5)
  --no-academic-research    Disable academic research stage
  --academic-max-results <n> Max web results per academic query (default: 5)
  --no-web-search            Disable keyword web search stage
  --web-search-query-budget <n> Number of auto-generated web queries (default: 6)
  --web-search-top-results <n> Max search results per keyword (default: 3)
  --web-search-scroll-steps <n> Number of scroll steps for opened pages (default: 3)
  --web-search-scroll-pause <sec> Seconds between scroll steps for opened pages (default: 0.9)
  --web-search-hold-seconds <sec> Keep browser open for N seconds per query (default: 15)
  --web-search-headless       Force web search browser mode to be headless
  --web-search-query <text>  Add/override a web search query (repeatable)
                      If none is provided, a context-driven query set is auto-generated.
  --life-input-md <path>    Input markdown for life reminder planner
  --no-write-reminder         Generate life reverse plan only; do not write reminders
  --life-reminder           Run life reminder planner (default)
  --no-life-reminder        Disable life reminder planner
  -h, --help                Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --to)
      shift
      TO_ADDR="${1:-}"
      ;;
    --from)
      shift
      FROM_ADDR="${1:-}"
      ;;
    --no-send-email)
      SEND_EMAIL=0
      ;;
    --send-email)
      SEND_EMAIL=1
      ;;
    --model)
      shift
      MODEL="${1:-}"
      ;;
    --reasoning)
      shift
      REASONING="${1:-}"
      ;;
    --market-context)
      shift
      MARKET_CONTEXT_FILE="${1:-}"
      ;;
    --legal-dept)
      RUN_LEGAL_DEPT=1
      ;;
    --no-legal-dept)
      RUN_LEGAL_DEPT=0
      ;;
    --legal-root)
      shift
      LEGAL_INPUT_ROOT="${1:-}"
      ;;
    --resource-output-dir)
      shift
      RESOURCE_OUTPUT_DIR="${1:-}"
      ;;
    --resource-label)
      shift
      RESOURCE_LABEL="${1:-}"
      ;;
    --resource-root)
      shift
      RESOURCE_ROOTS+=("${1:-}")
      ;;
    --academic-query)
      shift
      ACADEMIC_QUERIES+=("${1:-}")
      ;;
    --academic-query-budget)
      shift
      ACADEMIC_QUERY_BUDGET="${1:-5}"
      ;;
    --no-academic-research)
      ACADEMIC_RESEARCH=0
      ;;
    --academic-max-results)
      shift
      ACADEMIC_MAX_RESULTS="${1:-5}"
      ;;
    --no-web-search)
      RUN_WEB_SEARCH=0
      ;;
    --web-search-query-budget)
      shift
      LA_WEB_QUERY_BUDGET="${1:-6}"
      ;;
    --web-search-scroll-steps)
      shift
      WEB_SEARCH_SCROLL_STEPS="${1:-3}"
      ;;
    --web-search-scroll-pause)
      shift
      WEB_SEARCH_SCROLL_PAUSE="${1:-0.9}"
      ;;
    --web-search-headless)
      WEB_SEARCH_HEADLESS=1
      ;;
    --web-search-hold-seconds)
      shift
      WEB_SEARCH_HOLD_SECONDS="${1:-15}"
      ;;
    --web-search-query)
      shift
      LA_WEB_SEARCH_QUERIES+=("${1:-}")
      ;;
    --web-search-top-results)
      shift
      WEB_SEARCH_TOP_RESULTS="${1:-3}"
      ;;
    --skip-resource-analysis)
      RUN_RESOURCE_ANALYSIS=0
      ;;
    --life-input-md)
      shift
      LIFE_INPUT_MD="${1:-}"
      ;;
    --life-reminder)
      RUN_LIFE_REMINDER=1
      ;;
    --no-life-reminder)
      RUN_LIFE_REMINDER=0
      ;;
    --no-write-reminder)
      WRITE_REMINDER=0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/Library/pnpm:$PATH"
cd "$REPO_DIR"

RUN_ID="$(TZ=Asia/Hong_Kong date '+%Y%m%d-%H%M%S')"
ARTIFACT_DIR="$ARTIFACT_BASE/$RUN_ID"
mkdir -p "$ARTIFACT_DIR" "$NOTES_ROOT"
LOG_FILE="$ARTIFACT_DIR/pipeline.log"

log() {
  printf '[%s] %s\n' "$(TZ=Asia/Hong_Kong date '+%Y-%m-%d %H:%M:%S %Z')" "$1" | tee -a "$LOG_FILE"
}

acquire_pipeline_lock() {
  mkdir -p "$ARTIFACT_BASE"
  if [[ -f "$PIPELINE_LOCK_FILE" ]]; then
    local lock_content
    local lock_pid
    local lock_ts
    lock_content="$(cat "$PIPELINE_LOCK_FILE")"
    lock_pid="${lock_content%%|*}"
    lock_ts="${lock_content##*|}"
    if [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" >/dev/null 2>&1; then
      log "Another Lazying.art pipeline run is active (pid=$lock_pid, started=$lock_ts). Exiting."
      exit 0
    fi
    rm -f "$PIPELINE_LOCK_FILE"
  fi

  local lock_epoch
  lock_epoch="$(TZ=Asia/Hong_Kong date '+%Y%m%d-%H%M%S')"
  printf '%s|%s' "$$" "$lock_epoch" > "$PIPELINE_LOCK_FILE"
  chmod 600 "$PIPELINE_LOCK_FILE"
}

release_pipeline_lock() {
  if [[ ! -f "$PIPELINE_LOCK_FILE" ]]; then
    return 0
  fi
  local lock_content
  local lock_pid
  lock_content="$(cat "$PIPELINE_LOCK_FILE")"
  lock_pid="${lock_content%%|*}"
  if [[ "$lock_pid" == "$$" ]]; then
    rm -f "$PIPELINE_LOCK_FILE"
  fi
}

trap release_pipeline_lock EXIT INT TERM

extract_note_html() {
  local result_json="$1"
  local output_html="$2"
  python3 - "$result_json" "$output_html" <<'PY'
import json
import sys
from pathlib import Path

result_path = Path(sys.argv[1])
out_path = Path(sys.argv[2])
result = json.loads(result_path.read_text(encoding="utf-8"))
notes = result.get("notes") or []
html = ""
if notes and isinstance(notes, list):
    first = notes[0]
    if isinstance(first, dict):
        html = first.get("html_body", "") or ""
out_path.write_text(html, encoding="utf-8")
PY
}

extract_summary() {
  local result_json="$1"
  local output_txt="$2"
  python3 - "$result_json" "$output_txt" <<'PY'
import json
import sys
from pathlib import Path

result = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
summary = result.get("summary", "")
Path(sys.argv[2]).write_text(summary.strip() + "\n", encoding="utf-8")
PY
}

update_incremental_email() {
  local stage_label="$1"
  "$PROMPT_DIR/email/prompt_email_writer_incremental.sh" \
    --company-focus "$LA_PRIMARY_BRAND" \
    --stage "$stage_label" \
    --output-dir "$EMAIL_INCREMENTAL_DIR" \
    --output-html "$EMAIL_INCREMENTAL_HTML" \
    --market-summary-file "$MARKET_SUMMARY" \
    --web-summary-file "$WEB_SUMMARY_FILE" \
    --academic-summary-file "$ACADEMIC_SUMMARY" \
    --legal-summary-file "$LEGAL_SUMMARY" \
    --funding-summary-file "$FUNDING_SUMMARY" \
    --money-summary-file "$MONEY_REVENUE_SUMMARY" \
    --plan-summary-file "$PLAN_SUMMARY" \
    --mentor-summary-file "$MENTOR_SUMMARY" \
    --life-summary-file "$LIFE_SUMMARY" \
    --model "$MODEL" \
    --reasoning "$REASONING" \
    --safety "$SAFETY" \
    --approval "$APPROVAL" \
    >/dev/null || true
}

append_resource_summary() {
  local result_path="$1"
  local output_txt="$2"
  if [[ -z "${result_path}" || ! -e "$result_path" ]]; then
    printf '%s\n' "No resource-analysis result available." > "$output_txt"
    return 0
  fi

  if [[ -f "$result_path" ]]; then
    python3 - "$result_path" "$output_txt" <<'PY'
import json
import sys
from pathlib import Path

result_path = Path(sys.argv[1])
output_path = Path(sys.argv[2])
try:
    result = json.loads(result_path.read_text(encoding="utf-8"))
except Exception:
    output_path.write_text("No resource-analysis result available.\n", encoding="utf-8")
    raise SystemExit(0)

overview = result.get("resource_overview", {})
summary_lines = [
  "Resource analysis:",
  f"Manifest files: {overview.get('manifest_count', 0)}",
  f"Text snippets: {overview.get('text_snippet_count', 0)}",
]

for item in result.get("source_breakdown", []):
  source = item.get("source", "unknown")
  manifests = item.get("manifest_count", 0)
  snippets = item.get("text_snippets", 0)
  summary_lines.append(f"- {source}: {manifests} manifests, {snippets} snippets")

for row in result.get("notes", []):
  if isinstance(row, str):
    summary_lines.append(f"- {row}")

output_path.write_text("\\n".join(summary_lines).strip() + "\\n", encoding="utf-8")
PY
    return 0
  fi

  if [[ -d "$result_path" ]]; then
    python3 - "$result_path" "$output_txt" <<'PY'
import re
from pathlib import Path
import sys

md_root = Path(sys.argv[1])
out = Path(sys.argv[2])

md_files = sorted(md_root.glob("*.md"))
if not md_files:
  out.write_text("No resource-analysis markdown outputs available.\n", encoding="utf-8")
  raise SystemExit(0)

def _pick(patterns):
  for pattern in patterns:
    matches = sorted(md_root.glob(pattern))
    if matches:
      return matches[0]
  return None

summary_file = _pick(["*summary*.md", "*Summary*.md"])
if summary_file is None:
  summary_file = md_files[0]

lines = [
  "Resource analysis:",
  f"Loaded from markdown folder: {md_root}",
]

lines.append(f"- summary source: {summary_file.name}")
try:
  summary_text = summary_file.read_text(encoding="utf-8").strip()
except Exception:
  summary_text = ""
if summary_text:
  lines.append(summary_text)

recommendation_file = _pick(["*recommendations*.md", "*Recommendation*.md"])
if recommendation_file is not None:
  lines.append("")
  lines.append("Resource recommendations:")
  try:
    for row in recommendation_file.read_text(encoding="utf-8").splitlines():
      if row.strip():
        lines.append(f"- {row.strip()}")
  except Exception:
    pass

out.write_text("\\n".join(lines).strip() + "\\n", encoding="utf-8")
PY
    return 0
  fi

  printf '%s\n' "No resource-analysis result available." > "$output_txt"
}

parse_web_query() {
  local raw="$1"
  local parsed_kind="auto"
  local parsed_query="$raw"
  local kind_normalized=""

  if [[ "$raw" == *:* ]]; then
    local kind_candidate="${raw%%:*}"
    local rest="${raw#*:}"
    kind_normalized="${kind_candidate:l}"
    case "$kind_normalized" in
      auto|general|scholar|news)
        parsed_kind="$kind_normalized"
        parsed_query="$rest"
        ;;
      google)
        parsed_kind="auto"
        parsed_query="$rest"
        ;;
      google-scholar)
        parsed_kind="scholar"
        parsed_query="$rest"
        ;;
      google-news)
        parsed_kind="news"
        parsed_query="$rest"
        ;;
      *)
        parsed_kind="auto"
        parsed_query="$raw"
        ;;
    esac
  fi
  parsed_query="$(printf '%s' "$parsed_query" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
  if [[ -z "$parsed_query" ]]; then
    parsed_query="$raw"
  fi

  printf '%s|%s\n' "$parsed_kind" "$parsed_query"
}

slugify_query() {
  local raw="$1"
  local value
  value="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' | cut -c1-24)"
  if [[ -z "$value" ]]; then
    echo "query"
  else
    echo "$value"
  fi
}


web_search_engine_from_kind() {
  local kind="$1"
  case "$kind" in
    scholar)
      echo "google-scholar"
      ;;
    news)
      echo "google-news"
      ;;
    auto|general)
      echo "google"
      ;;
    *)
      echo "google"
      ;;
  esac
}

append_web_search_reports() {
  local query_label="$1"
  local query_kind="$2"
  local result_json="$3"
  local summary_file="$4"
  local html_file="$5"
  local result_dir="$6"

  python3 - "$query_label" "$query_kind" "$result_json" "$summary_file" "$html_file" "$result_dir" <<'PY'
import html
import json
import sys
from pathlib import Path

query_label = sys.argv[1]
query_kind = sys.argv[2]
result_json = Path(sys.argv[3]).expanduser()
summary_path = Path(sys.argv[4]).expanduser()
html_path = Path(sys.argv[5]).expanduser()
result_dir = Path(sys.argv[6]).expanduser()


def as_list(value):
    return value if isinstance(value, list) else []


def to_str(value):
    return str(value).strip()


def truncate(value, limit=280):
    text = to_str(value)
    return text[:limit]

if not result_json.is_file():
    line = f"- ❌ {query_label} ({query_kind}): no results (search did not return JSON)."
    with summary_path.open("a", encoding="utf-8") as summary:
        summary.write(line + "\n")
    with html_path.open("a", encoding="utf-8") as html_out:
        html_out.write(f"<h3>❌ {html.escape(query_label)} ({html.escape(query_kind)})</h3><p>no results (search error)</p>")
    raise SystemExit(0)

try:
    payload = json.loads(result_json.read_text(encoding="utf-8"))
except Exception as exc:  # noqa: BLE001
    with summary_path.open("a", encoding="utf-8") as summary:
        summary.write(f"- ⚠️ {query_label} ({query_kind}): failed to read results ({exc}).\n")
    with html_path.open("a", encoding="utf-8") as html_out:
        html_out.write(
            f"<h3>⚠️ {html.escape(query_label)} ({html.escape(query_kind)})</h3>"
            f"<p>Failed to parse search results: {html.escape(str(exc))}</p>"
        )
    raise SystemExit(0)

items = payload.get("items") if isinstance(payload, dict) else []
if not isinstance(items, list):
    items = []
search_overview = []
search_screenshots = []
opened_items = []
clicked = {}
if isinstance(payload, dict):
    search_overview = as_list(payload.get("search_overviews"))
    if not search_overview:
        search_overview = as_list(payload.get("search_page_overviews"))
    search_screenshots = as_list(payload.get("search_screenshots"))
    if not search_screenshots:
        search_screenshots = as_list(payload.get("search_page_screenshots"))
    opened_items = as_list(payload.get("opened_items"))
    clicked = payload.get("clicked", {})
    if not isinstance(clicked, dict):
        clicked = {}

if not result_dir.is_dir():
    result_dir = result_json.parent

txt_candidates = sorted(result_dir.glob("query-*.txt"), key=lambda p: p.name)
result_txt = txt_candidates[0] if txt_candidates else None

opened_count = payload.get("opened_count")
if not isinstance(opened_count, int):
    opened_count = len(opened_items)
opened_display_count = max(0, min(opened_count, len(opened_items)))

if not search_overview:
    fallback_summary = ""
    if isinstance(payload.get("search_summary"), str):
        fallback_summary = to_str(payload.get("search_summary"))
    elif isinstance(payload.get("summary"), str):
        fallback_summary = to_str(payload.get("summary"))
    if fallback_summary:
        search_overview = [{"page": "1", "summary": fallback_summary}]

with summary_path.open("a", encoding="utf-8") as summary:
    summary.write(f"- ✅ {query_label} ({query_kind}): {len(items)} result(s)\n")
    if result_txt is not None:
        summary.write("  - result snapshot text available\n")
    summary.write(f"  - opened candidates: {len(opened_items)}\n")
    if search_screenshots:
        summary.write(f"  - results_page_screenshot_count: {len(search_screenshots)}\n")
    if search_overview:
        summary.write("  - search result page scan:\n")
        for row in search_overview:
            if not isinstance(row, dict):
                continue
            page = row.get("page", "")
            row_summary = str(row.get("summary", "")).strip()
            if row_summary:
                summary.write(f"    - page {page}: {row_summary[:280]}\n")
    if opened_display_count:
      summary.write(f"  - opened result details: {opened_display_count}\n")
      for item in opened_items[:opened_display_count]:
        title = to_str(item.get("title", "")) or "(untitled)"
        url = to_str(item.get("url", ""))
        item_summary = to_str(item.get("summary", ""))
        summary.write(f"    - {title} | {url}\n")
        if item_summary:
          summary.write(f"      - summary: {truncate(item_summary, 320)}\n")
    elif clicked:
      title = to_str(clicked.get("title", "")) or "(untitled)"
      url = to_str(clicked.get("url", ""))
      clicked_summary = to_str(clicked.get("summary", ""))
      summary.write(f"  - clicked: {title} | {url}\n")
      if clicked_summary:
        summary.write(f"    - summary: {truncate(clicked_summary, 320)}\n")

with html_path.open("a", encoding="utf-8") as html_out:
    html_out.write(
        f"<h3>✅ {html.escape(query_label)} ({html.escape(query_kind)})</h3>"
        f"<p><strong>source:</strong> {html.escape(payload.get('query', ''))}</p>"
        f"<p><strong>result_count:</strong> {len(items)}</p>"
    )
    for item in items:
        title = str(item.get("title", "")).strip() or "(untitled)"
        url = str(item.get("url", "")).strip()
        snippet = str(item.get("snippet", "")).strip()
        codex_summary = str(item.get("codex_summary", "")).strip()
        screenshot = str(item.get("screenshot", "")).strip()
        center_x = item.get("center_x", "")
        center_y = item.get("center_y", "")
        elem_x = item.get("element_x", "")
        elem_y = item.get("element_y", "")
        elem_w = item.get("element_width", "")
        elem_h = item.get("element_height", "")

        with summary_path.open("a", encoding="utf-8") as summary:
            summary.write(f"  - {title} | {url}\n")
            if snippet:
                summary.write(f"    - snippet: {snippet}\n")

        html_out.write("<div style=\"margin-left: 0.8rem; margin-bottom: 1rem;\">")
        if url:
            html_out.write(
                f"<p><strong>{html.escape(title)}</strong><br/>"
                f"<a href=\"{html.escape(url)}\">{html.escape(url)}</a></p>"
            )
        else:
            html_out.write(f"<p><strong>{html.escape(title)}</strong></p>")
        if snippet:
            html_out.write(f"<p>{html.escape(snippet)}</p>")
        if center_x != "" and center_y != "":
            html_out.write(
                f"<p><strong>location:</strong> center=({html.escape(str(center_x))},{html.escape(str(center_y))})</p>"
            )
        if elem_x != "" and elem_y != "" and elem_w != "" and elem_h != "":
            html_out.write(
                f"<p><strong>element:</strong> "
                f"{html.escape(str(elem_x))},{html.escape(str(elem_y))} "
                f"{html.escape(str(elem_w))}x{html.escape(str(elem_h))}</p>"
            )
        if screenshot:
            html_out.write("<p><strong>Screenshot:</strong> captured</p>")
        if codex_summary:
            html_out.write(f"<p><strong>Codex summary:</strong> {html.escape(codex_summary)}</p>")
        html_out.write("</div>")
    if search_overview:
        html_out.write("<div style=\"margin-left: 0.8rem; margin-bottom: 1rem;\">")
        html_out.write("<p><strong>Search results page scan:</strong></p>")
        for row in search_overview:
            if not isinstance(row, dict):
                continue
            page = row.get("page", "")
            row_summary = str(row.get("summary", "")).strip()
            if row_summary:
                html_out.write(f"<p>- page {html.escape(str(page))}: {html.escape(row_summary[:400])}</p>")
        if search_screenshots:
            html_out.write(f"<p><strong>Search screenshot count:</strong> {len(search_screenshots)}</p>")
        html_out.write("</div>")

    opened_render = opened_items if opened_items else ([clicked] if clicked else [])
    opened_render_count = len(opened_render)
    if opened_items:
        opened_render_count = min(opened_display_count, opened_render_count)
        opened_render = opened_render[:opened_render_count]
    if opened_render:
        html_out.write("<div style=\"margin-left: 0.8rem; margin-bottom: 1rem;\">")
        html_out.write(f"<p><strong>Opened result details (top {opened_render_count}):</strong></p>")
        for item in opened_render:
            if not isinstance(item, dict):
                continue
            idx = html.escape(to_str(item.get("result_index", "")))
            title = html.escape(to_str(item.get("title", "")) or "(untitled)")
            url = html.escape(to_str(item.get("url", "")))
            item_summary = html.escape(truncate(item.get("summary", ""), 1800))
            html_out.write(f"<p><strong>#{idx}</strong> {title}</p>")
            if url:
                html_out.write(f"<p><a href=\"{url}\">{url}</a></p>")
            if item.get("center_x", "") != "" and item.get("center_y", "") != "":
                html_out.write(
                    f"<p><strong>location:</strong> center=({html.escape(str(item.get('center_x')))},{html.escape(str(item.get('center_y')) )})</p>"
                )
            if item_summary:
                html_out.write(f"<p>{item_summary}</p>")
            screenshots = as_list(item.get("opened_screenshots"))
            for shot in screenshots:
                html_out.write("<p><strong>Opened screenshot:</strong> captured</p>")
        html_out.write("</div>")
PY
}

run_web_search_queries() {
  local context_label="$1"
  local output_dir="$2"
  local top_n="$3"
  local model="$4"
  local reasoning="$5"
  local safety="$6"
  local approval="$7"
  local run_id="$8"
  shift 8
  local query_list=("$@")
  mkdir -p "$output_dir"

  local query_summary_file="${output_dir}/${context_label}.summary.txt"
  local query_html_file="${output_dir}/${context_label}.html"
  : > "$query_summary_file"
  : > "$query_html_file"

  if [[ ${#query_list[@]} -eq 0 ]]; then
    printf '%s\n' "No web search queries configured." >> "$query_summary_file"
    printf '<p>No web search queries configured.</p>' > "$query_html_file"
    WEB_SEARCH_SUMMARY_FILE="$query_summary_file"
    WEB_SEARCH_HTML_FILE="$query_html_file"
    return 0
  fi

  local idx=1
  for raw_query in "${query_list[@]}"; do
    local parse
    parse="$(parse_web_query "$raw_query")"
    local query_kind="${parse%%|*}"
    local query_text="${parse#*|}"
    local query_slug
    query_slug="$(slugify_query "$query_text")"
    local query_run_id="$run_id-${context_label}-${idx}-${query_slug}"
    local run_output_dir="${output_dir}/${context_label}"
    local query_result_dir="${run_output_dir}/${query_run_id}"
    mkdir -p "$run_output_dir"

    local query_result_file=""
    local query_log_file="$query_result_dir/search.log"
    local web_search_args

    mkdir -p "$query_result_dir"
    web_search_args=(
      "--query" "$query_text"
      "--engine" "$(web_search_engine_from_kind "$query_kind")"
      "--results" "$top_n"
      "--open-top-results" "$top_n"
      "--summarize-open-url"
      "--output-dir" "$run_output_dir"
      "--run-id" "$query_run_id"
      "--scroll-steps" "$WEB_SEARCH_SCROLL_STEPS"
      "--scroll-pause" "$WEB_SEARCH_SCROLL_PAUSE"
      "--keep-open"
      "--hold-seconds" "$WEB_SEARCH_HOLD_SECONDS"
    )
    if [[ "$WEB_SEARCH_HEADLESS" == "1" ]]; then
      web_search_args+=(--headless)
    fi
    if ! "$PROMPT_DIR/websearch/prompt_web_search_immersive.sh" "${web_search_args[@]}" >"$query_log_file" 2>&1; then
      printf '%s\n' "- ❌ Web search failed for: $query_text" >> "$query_summary_file"
      printf '<p>⚠️ %s (%s): failed, see query log.</p>' "$query_text" "$query_kind" >> "$query_html_file"
      idx=$((idx + 1))
      continue
    fi

    for candidate in \
      "$query_result_dir"/query-*.json \
      "$query_result_dir"/search_batch_result.json; do
      if [[ -f "$candidate" ]]; then
        query_result_file="$candidate"
        break
      fi
    done

    if [[ ! -f "$query_result_file" ]]; then
      if ! ls "$query_result_dir"/query-*.json >/dev/null 2>&1; then
        printf '%s\n' "- ⚠️ Web search result file missing for: $query_text" >> "$query_summary_file"
        printf '<p>⚠️ %s (%s): result missing.</p>' "$query_text" "$query_kind" >> "$query_html_file"
        idx=$((idx + 1))
        continue
      fi
      query_result_file="$query_result_dir/search_batch_result.json"
    fi

    append_web_search_reports "$query_text" "$query_kind" "$query_result_file" "$query_summary_file" "$query_html_file" "$query_result_dir"
    idx=$((idx + 1))
  done

  WEB_SEARCH_SUMMARY_FILE="$query_summary_file"
  WEB_SEARCH_HTML_FILE="$query_html_file"
  }


build_default_web_search_queries() {
  local brand="$1"
  local website="$2"
  local profile_url="$3"
  local query_budget="${4:-4}"
  local context_path="${5:-}"
  local planner_output_dir="${ARTIFACT_DIR}/query_planner"
  local planner_input
  local planner_result

  mkdir -p "$planner_output_dir"
  planner_input="$(mktemp "${planner_output_dir}/web-planner-XXXXXX.json")"
  planner_result="$planner_output_dir/latest-result.json"

  python3 - "$planner_input" "$brand" "$query_budget" "$context_path" <<'PY'
import json
import sys
from pathlib import Path

def read_snippet(path: str, limit: int) -> str:
  p = Path(path).expanduser()
  if not p.exists() or not p.is_file():
    return ""
  try:
    return p.read_text(encoding="utf-8", errors="ignore")[:limit]
  except Exception:
    return ""

brand = (sys.argv[1] or "").strip()
try:
  budget = int(sys.argv[2]) if str(sys.argv[2]).strip() else 4
except Exception:
  budget = 4
context_path = (sys.argv[3] or "").strip()

if budget < 3:
  budget = 3
if budget > 8:
  budget = 8

source_text = read_snippet(context_path, 7000)

payload = {
  "company_focus": brand or "target company",
  "search_kind": "web",
  "query_budget": budget,
  "reference_sources": [s for s in [context_path] if s and s.strip()],
  "source_text": source_text,
  "context_file": context_path,
  "resource_context_hint": "Build queries from provided context, not fixed presets.",
}

Path(sys.argv[1]).write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY

  if ! python3 orchestral/prompt_tools/runtime/codex-json-runner.py \
    --input-json "$planner_input" \
    --output-dir "$planner_output_dir" \
    --prompt-file "$LA_WEB_QUERY_PLANNER_PROMPT" \
    --schema "$PROMPT_DIR/websearch/web_search_query_planner_schema.json" \
    --model "$MODEL" \
    --reasoning "$REASONING" \
    --safety "$SAFETY" \
    --approval "$APPROVAL" \
    --label "web-query-planner" \
    --skip-git-check >/dev/null 2>&1; then
    true
  fi

if [[ ! -f "$planner_result" ]]; then
  rm -f "$planner_input"
  if [[ -n "$context_path" && -f "$context_path" ]]; then
    python3 - "$context_path" "$brand" "$website" "$profile_url" <<'PY'
import re
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
brand = sys.argv[2] if len(sys.argv) > 2 else ""
website = sys.argv[3] if len(sys.argv) > 3 else ""
profile = sys.argv[4] if len(sys.argv) > 4 else ""

def collect_block_terms(raw: str):
  if not raw:
    return set()
  cleaned = re.sub(r"[^a-z0-9]+", " ", raw.lower())
  return {w for w in cleaned.split() if len(w) >= 4}

blocked_terms = set()
for source in (brand, website, profile):
  blocked_terms.update(collect_block_terms(source))

try:
    text = path.read_text(encoding="utf-8", errors="ignore")
except Exception:
    text = ""
words = [w for w in re.findall(r"[A-Za-z][A-Za-z0-9+\\-&]{2,}", text.lower()) if len(w) > 2]
stop = {"the", "and", "for", "with", "from", "that", "this", "company", "market", "product", "business"}
stop.update(blocked_terms)
terms = [w for w in words if w not in stop]
if terms:
    base = " ".join(dict.fromkeys(terms[:3]))
    print(f"news:{base} funding updates")
    print(f"general:{base} competitors")
    print(f"general:{base} policy updates")
else:
    print("news:ai startup funding hong kong")
    print("general:ai memory assistant competitors")
    print("general:ai workflow automation market trends")
PY
  else
    printf '%s\n' "news:ai startup funding hong kong"
    printf '%s\n' "general:ai memory assistant competitors"
    printf '%s\n' "general:ai workflow automation market trends"
  fi
  return 0
fi

  python3 - "$planner_result" "$query_budget" <<'PY'
import json
import re
import sys
from pathlib import Path

def simplify_query(text: str, max_terms: int = 8) -> str:
  text = re.sub(r"\s+", " ", text).strip().replace(":", " -")
  if not text:
    return ""
  out = []
  seen = set()
  for token in text.split():
    t = token.strip(" ,;|")
    key = t.lower()
    if not t or key in seen:
      continue
    seen.add(key)
    out.append(t)
    if len(out) >= max_terms:
      break
  return " ".join(out).strip()

def parse_queries(payload_path: str, budget: int):
  try:
    payload = json.loads(Path(payload_path).read_text(encoding="utf-8"))
  except Exception:
    return []

  general = []
  news = []
  seen = set()
  for row in payload.get("queries", []) if isinstance(payload, dict) else []:
    if isinstance(row, str):
      kind = "general"
      text = row.strip()
    elif isinstance(row, dict):
      kind = str(row.get("kind", "general")).strip().lower()
      text = str(row.get("query", "")).strip()
    else:
      continue
    if kind not in {"auto", "general", "scholar", "news"}:
      kind = "general"
    if kind in {"auto", "scholar"}:
      kind = "general"
    text = simplify_query(text, 8)
    if not text:
      continue
    key = (kind, text.lower())
    if key in seen:
      continue
    seen.add(key)
    if kind == "news":
      news.append((kind, text))
    else:
      general.append((kind, text))

  queries = []
  if news:
    queries.append(news.pop(0))
  while len(queries) < budget and (general or news):
    if general:
      queries.append(general.pop(0))
      if len(queries) >= budget:
        break
    if news:
      queries.append(news.pop(0))
  return queries[:budget]

queries = parse_queries(sys.argv[1], int(sys.argv[2]))

if not queries:
  queries = [
    ("news", "ai startup funding hong kong"),
    ("general", "ai memory assistant competitors"),
    ("general", "ai workflow automation market trends"),
  ]

for kind, text in queries:
  if kind in {"auto", "general"}:
    print(text)
  else:
    print(f"{kind}:{text}")
PY

  rm -f "$planner_input"
}

build_website_snapshot() {
  local site_url="$1"
  local out_path="$2"
  python3 - "$site_url" "$out_path" <<'PY'
import re
import sys
import urllib.request
from html import unescape
from pathlib import Path

url = sys.argv[1]
out = Path(sys.argv[2])
out.parent.mkdir(parents=True, exist_ok=True)

try:
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=20) as resp:
        raw = resp.read()
    html_text = raw.decode("utf-8", errors="ignore")
except Exception as exc:  # noqa: BLE001
    out.write_text(f"[website] fetch_failed url={url} err={exc}\n", encoding="utf-8")
    raise SystemExit(0)

title_match = re.search(r"<title[^>]*>(.*?)</title>", html_text, flags=re.IGNORECASE | re.DOTALL)
title = unescape(title_match.group(1).strip()) if title_match else ""
text = re.sub(r"(?is)<script.*?>.*?</script>", " ", html_text)
text = re.sub(r"(?is)<style.*?>.*?</style>", " ", text)
text = re.sub(r"(?is)<[^>]+>", " ", text)
text = unescape(text)
text = re.sub(r"\s+", " ", text).strip()
snapshot = text[:12000]

lines = [f"[website] url={url}"]
if title:
    lines.append(f"[website] title={title}")
lines.append("[website] text_snapshot:")
lines.append(snapshot)
out.write_text("\n".join(lines).strip() + "\n", encoding="utf-8")
PY
}

build_default_academic_queries() {
  local brand="$1"
  local query_budget="${2:-5}"
  local context_path="${3:-}"
  local planner_output_dir="${ARTIFACT_DIR}/query_planner"
  local planner_input
  local planner_result
  shift 3
  local -a sources=("$@")

  mkdir -p "$planner_output_dir"
  planner_input="$(mktemp "${planner_output_dir}/academic-planner-XXXXXX.json")"
  planner_result="$planner_output_dir/latest-result.json"

  python3 - "$planner_input" "$brand" "$query_budget" "$context_path" "${sources[@]}" <<'PY'
import json
import sys
from pathlib import Path

def read_snippet(path: str, limit: int) -> str:
  p = Path(path).expanduser()
  if not p.exists() or not p.is_file():
    return ""
  try:
    return p.read_text(encoding="utf-8", errors="ignore")[:limit]
  except Exception:
    return ""

brand = (sys.argv[1] or "").strip()
try:
  budget = int(sys.argv[2]) if str(sys.argv[2]).strip() else 5
except Exception:
  budget = 5
context_path = (sys.argv[3] or "").strip()
sources = [s.strip() for s in sys.argv[4:] if s and s.strip()]
if budget < 3:
  budget = 3
if budget > 10:
  budget = 10

payload = {
  "company_focus": brand or "target company",
  "search_kind": "academic",
  "query_budget": budget,
  "reference_sources": [s for s in sources if s],
  "source_text": read_snippet(context_path, 7000),
  "context_file": context_path,
  "resource_context_hint": "Prioritize high-impact and field-anchored scholarly signals.",
}

Path(sys.argv[1]).write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY

  if ! python3 orchestral/prompt_tools/runtime/codex-json-runner.py \
    --input-json "$planner_input" \
    --output-dir "$planner_output_dir" \
    --prompt-file "$PROMPT_DIR/websearch/web_search_query_planner_prompt.md" \
    --schema "$PROMPT_DIR/websearch/web_search_query_planner_schema.json" \
    --model "$MODEL" \
    --reasoning "$REASONING" \
    --safety "$SAFETY" \
    --approval "$APPROVAL" \
    --label "academic-query-planner" \
    --skip-git-check >/dev/null 2>&1; then
    true
  fi

if [[ ! -f "$planner_result" ]]; then
  rm -f "$planner_input"
  if [[ -n "$context_path" && -f "$context_path" ]]; then
    python3 - "$context_path" "$brand" "$query_budget" "${sources[@]}" <<'PY'
import re
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
brand = (sys.argv[2] or "").strip()
query_budget = sys.argv[3] if len(sys.argv) > 3 else "5"

def collect_block_terms(raw: str):
  if not raw:
    return set()
  cleaned = re.sub(r"[^a-z0-9]+", " ", raw.lower())
  return {w for w in cleaned.split() if len(w) >= 4}

blocked_terms = collect_block_terms(brand)

try:
    text = path.read_text(encoding="utf-8", errors="ignore")
except Exception:
    text = ""
words = [w for w in re.findall(r"[A-Za-z][A-Za-z0-9+\\-&]{2,}", text.lower()) if len(w) > 2]
stop = {"the", "and", "for", "with", "from", "that", "this", "company", "scientific", "research", "paper"}
stop.update(blocked_terms)
terms = [w for w in words if w not in stop]
budget = int(query_budget or 0)
if budget < 3:
  budget = 3
if budget > 8:
  budget = 8

theme_words = list(dict.fromkeys(terms[:3]))
theme = " ".join(theme_words).strip() if theme_words else "ai memory assistant"
queries = [
  f"general:{theme} nature science papers",
  f"news:{theme} research breakthroughs",
  f"general:{theme} benchmark study",
  f"scholar:{theme} multimodal memory",
]
for q in queries[:budget]:
  print(q)
PY
    else
      printf '%s\n' "general:ai memory assistant nature science papers"
      printf '%s\n' "news:ai memory assistant research breakthroughs"
      printf '%s\n' "general:ai wearable memory benchmark study"
    fi
    return 0
  fi

  python3 - "$planner_result" "$query_budget" <<'PY'
import json
import re
import sys
from pathlib import Path

try:
  payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
except Exception:
  payload = {}

budget = int(sys.argv[2]) if len(sys.argv) > 2 else 5
if budget < 2:
  budget = 2

queries = []
scholar_count = 0
seen = set()
for row in payload.get("queries", []) if isinstance(payload, dict) else []:
  if isinstance(row, str):
    kind = "general"
    text = row.strip()
  elif isinstance(row, dict):
    kind = str(row.get("kind", "general")).strip().lower()
    text = str(row.get("query", "")).strip()
  else:
    continue
  if kind not in {"auto", "general", "scholar", "news"}:
    kind = "general"
  if kind == "auto":
    kind = "general"
  text = re.sub(r"\\s+", " ", text).strip().replace(":", " -")
  if not text:
    continue
  terms = []
  seen_terms = set()
  for token in text.split():
    clean = token.strip(" ,;|")
    key = clean.lower()
    if not clean or key in seen_terms:
      continue
    seen_terms.add(key)
    terms.append(clean)
    if len(terms) >= 8:
      break
  text = " ".join(terms).strip()
  if not text:
    continue
  if kind == "scholar":
    if scholar_count >= 1:
      kind = "general"
    else:
      scholar_count += 1
  key = (kind, text.lower())
  if key in seen:
    continue
  seen.add(key)
  queries.append((kind, text))
  if len(queries) >= budget:
    break

if not queries:
  queries.extend(
    [
      ("general", "ai memory assistant nature science papers"),
      ("news", "ai memory wearable research updates"),
      ("general", "ai wearable memory benchmark study"),
    ]
  )
for kind, text in queries[:budget]:
  if kind in {"general", "auto"}:
    print(text)
  else:
    print(f"{kind}:{text}")
PY

  rm -f "$planner_input"
}

find_latest_resource_markdown_dir() {
  local base_dir="$1"
  python3 - "$base_dir" <<'PY'
import sys
from pathlib import Path

base = Path(sys.argv[1]).expanduser()
if not base.is_dir():
  raise SystemExit(0)

dirs = [p for p in base.iterdir() if p.is_dir()]
if not dirs:
  raise SystemExit(0)

dirs.sort(key=lambda p: p.stat().st_mtime, reverse=True)
print(dirs[0].as_posix())
PY
}

build_academic_context_websearch() {
  local out_path="$1"
  local queries_json="$2"
  local max_results="$3"
  shift 3
  local -a academic_queries
  local -i open_limit
  local academic_output_root="$ARTIFACT_DIR/academic_search"

  if [[ "$max_results" == [1-9][0-9]* ]]; then
    open_limit="$max_results"
  else
    open_limit=3
  fi
  (( open_limit < 1 )) && open_limit=1

  academic_queries=("${(@f)$(python3 - "$queries_json" <<'PY'
import json
import sys

raw = sys.argv[1]
try:
    values = json.loads(raw)
except Exception:
    values = []

for item in values:
    if isinstance(item, str):
        q = item.strip()
        if q:
            print(q)
PY
  )}") 

  if [[ "${#academic_queries[@]}" -eq 0 ]]; then
    academic_queries=("${(@f)$(build_default_academic_queries "$LA_PRIMARY_BRAND" "$open_limit" "$CONTEXT_FILE" "${ACADEMIC_RSS_SOURCES[@]}")}")
  fi

  local academic_summary_file="$academic_output_root/academic.search.summary.txt"
  local academic_html_file="$academic_output_root/academic.search_digest.html"
  mkdir -p "$academic_output_root"
  WEB_SEARCH_SUMMARY_FILE="$academic_summary_file"
  WEB_SEARCH_HTML_FILE="$academic_html_file"
  : > "$academic_summary_file"
  : > "$academic_html_file"

  if ! run_web_search_queries "academic" "$academic_output_root" "$open_limit" "$MODEL" "$REASONING" "$SAFETY" "$APPROVAL" "$RUN_ID" "${academic_queries[@]}"; then
    : > "$out_path"
    {
      echo "[academic] mode=web_search_research"
      echo "[academic] status=web_search_failed"
      echo "[academic] summary_file=$academic_summary_file"
      echo "[academic] html_file=$academic_html_file"
      echo "[academic] top_results_per_query=$open_limit"
    } > "$out_path"
    return 0
  fi

  {
    echo "[academic] mode=web_search_research"
    echo "[academic] top_results_per_query=$open_limit"
    echo "[academic] query_count=${#academic_queries[@]}"
    echo "[academic] context_source=prompt_web_search_immersive"
    echo "[academic] summary_file=$academic_summary_file"
    echo "[academic] html_file=$academic_html_file"
    echo "[academic] queries:"
    for q in "${academic_queries[@]}"; do
      echo "  - $q"
    done
    echo
    if [[ -f "$academic_summary_file" ]]; then
      cat "$academic_summary_file"
    else
      echo "[academic] no academic web search summary found"
    fi
  } > "$out_path"
}

merge_market_and_academic_summaries() {
  local market_path="$1"
  local academic_path="$2"
  local merged_path="$3"
  local web_path="${4:-}"
  if [[ -f "$market_path" ]] && [[ -f "$academic_path" ]]; then
    python3 - "$market_path" "$academic_path" "$merged_path" "$web_path" <<'PY'
from pathlib import Path
import sys

market_path = Path(sys.argv[1])
academic_path = Path(sys.argv[2])
output_path = Path(sys.argv[3])
web_path = Path(sys.argv[4]) if len(sys.argv) > 4 and sys.argv[4].strip() else None

parts = []
if market_path.exists():
    m = market_path.read_text(encoding="utf-8").strip()
    if m:
        parts.append("[market]")
        parts.append(m)
if academic_path.exists():
    a = academic_path.read_text(encoding="utf-8").strip()
    if a:
        parts.append("[academic]")
        parts.append(a)
if web_path is not None and web_path.exists():
    w = web_path.read_text(encoding="utf-8").strip()
    if w:
        parts.append("[web_search]")
        parts.append(w)
if not parts:
    parts.append("No market or academic summary available.")
output_path.write_text("\\n\\n".join(parts) + "\\n", encoding="utf-8")
PY
  elif [[ -f "$market_path" ]]; then
    if [[ -f "$web_path" ]]; then
      cat "$market_path" > "$merged_path"
      echo "" >> "$merged_path"
      echo "[web_search]" >> "$merged_path"
      cat "$web_path" >> "$merged_path"
    else
      cp "$market_path" "$merged_path"
    fi
  elif [[ -f "$academic_path" ]]; then
    if [[ -f "$web_path" ]]; then
      cat "$academic_path" > "$merged_path"
      echo "" >> "$merged_path"
      echo "[web_search]" >> "$merged_path"
      cat "$web_path" >> "$merged_path"
    else
      cp "$academic_path" "$merged_path"
    fi
  else
    if [[ -f "$web_path" ]]; then
      if [[ -s "$web_path" ]]; then
        cat "$web_path" > "$merged_path"
      else
        printf '%s\n' "No market or academic summary available." > "$merged_path"
      fi
    else
      printf '%s\n' "No market or academic summary available." > "$merged_path"
    fi
  fi
}

log "Pipeline start run_id=$RUN_ID model=$MODEL reasoning=$REASONING"

acquire_pipeline_lock

RESOURCE_ANALYSIS_RUN_DIR="$ARTIFACT_DIR/resource_analysis"
RESOURCE_ANALYSIS_RESULT=""
RESOURCE_ANALYSIS_MARKDOWN_DIR="$RESOURCE_OUTPUT_DIR/$RUN_ID"
WEBSITE_SNAPSHOT_FILE="$ARTIFACT_DIR/lazyingart_website_snapshot.txt"
build_website_snapshot "$LA_WEBSITE" "$WEBSITE_SNAPSHOT_FILE"
HAS_RESOURCE_CACHE=0
if [[ "$RUN_RESOURCE_ANALYSIS" == "1" ]]; then
  mkdir -p "$RESOURCE_ANALYSIS_RUN_DIR" "$RESOURCE_OUTPUT_DIR" "$RESOURCE_ANALYSIS_MARKDOWN_DIR"
  RESOURCE_ANALYSIS_ARGS=()
  for root in "${RESOURCE_ROOTS[@]}"; do
    RESOURCE_ANALYSIS_ARGS+=(--resource-root "$root")
  done

  log "Step 0: analyze resources and build reference summary"
  set +e
  "$PROMPT_DIR/company/prompt_resource_analysis.sh" \
    --company "LazyingArt" \
    --output-dir "$RESOURCE_ANALYSIS_RUN_DIR" \
    --markdown-output "$RESOURCE_ANALYSIS_MARKDOWN_DIR" \
    --label "$RESOURCE_LABEL" \
    --model "$MODEL" \
    --reasoning "$REASONING" \
    --max-manifest-files 500 \
    --max-text-snippets 50000 \
    --prompt-file "$PROMPT_DIR/company/resource_analysis_prompt.md" \
    --schema-file "$PROMPT_DIR/company/resource_analysis_schema.json" \
    "${RESOURCE_ANALYSIS_ARGS[@]}" \
    > "$ARTIFACT_DIR/resource_analysis.log" 2>&1
  RC=$?
  set -e
  if [[ "$RC" -ne 0 ]]; then
    log "Resource analysis codex command failed with rc=$RC; continuing with available artifacts."
  fi
  latest_ra="$(ls -1 "$RESOURCE_ANALYSIS_RUN_DIR/${RESOURCE_LABEL}"-* 2>/dev/null | head -n 1 || true)"
  if [[ -n "$latest_ra" ]]; then
    RESOURCE_ANALYSIS_RESULT="$latest_ra/latest-result.json"
  fi
  HAS_RESOURCE_CACHE=1
else
  RESOURCE_ANALYSIS_MARKDOWN_DIR="$(find_latest_resource_markdown_dir "$RESOURCE_OUTPUT_DIR" || true)"
  if [[ -n "$RESOURCE_ANALYSIS_MARKDOWN_DIR" ]]; then
  log "Step 0: use latest cached resource analysis markdown."
    HAS_RESOURCE_CACHE=1
  else
    log "Step 0: resource analysis skipped."
  fi
fi

CONTEXT_FILE="$ARTIFACT_DIR/market_context.txt"
RESOURCE_APPEND_PATH="$ARTIFACT_DIR/resource_analysis.txt"
: > "$RESOURCE_APPEND_PATH"
if [[ "$RUN_RESOURCE_ANALYSIS" == "1" ]]; then
  append_resource_summary "$RESOURCE_ANALYSIS_RESULT" "$RESOURCE_APPEND_PATH"
else
  append_resource_summary "$RESOURCE_ANALYSIS_MARKDOWN_DIR" "$RESOURCE_APPEND_PATH"
fi
{
  echo "Run time: $(TZ=Asia/Hong_Kong date '+%Y-%m-%d %H:%M:%S %Z')"
  echo "Primary brand: $LA_PRIMARY_BRAND"
  echo "Must inspect $LA_WEBSITE and $LA_GITHUB_PROFILE"
  echo "Website snapshot:"
  cat "$WEBSITE_SNAPSHOT_FILE"
  echo
  echo "Personal context: based in Hong Kong, can travel to Shenzhen, and LazyingArt LLC is in the US."
  echo "Input/state files are under ~/Documents/LazyingArtBotIO/LazyingArt."
  echo "Output language preference: Chinese-first with concise EN labels."
  echo
  echo "Resource analysis roots:"
  for root in "${RESOURCE_ROOTS[@]}"; do
    echo "- ${root}"
  done
  if [[ -n "$RESOURCE_ANALYSIS_RESULT" && -f "$RESOURCE_ANALYSIS_RESULT" ]]; then
    echo
    echo "Resource analysis summary:"
    cat "$RESOURCE_APPEND_PATH"
    echo
    echo "Resource analysis markdown outputs:"
    find "$RESOURCE_ANALYSIS_MARKDOWN_DIR" -maxdepth 1 -type f -print
  elif [[ -n "$RESOURCE_ANALYSIS_MARKDOWN_DIR" && -d "$RESOURCE_ANALYSIS_MARKDOWN_DIR" ]]; then
    echo
    echo "Resource analysis markdown outputs:"
    find "$RESOURCE_ANALYSIS_MARKDOWN_DIR" -maxdepth 1 -type f -print
  fi
  echo "Output notes target: AutoLife"
  if [[ -n "$MARKET_CONTEXT_FILE" && -f "$MARKET_CONTEXT_FILE" ]]; then
    echo
    echo "User extra context:"
    cat "$MARKET_CONTEXT_FILE"
  fi
} > "$CONTEXT_FILE"

MARKET_RESULT="$ARTIFACT_DIR/market.result.json"
ACADEMIC_RESULT="$ARTIFACT_DIR/academic.result.json"
LEGAL_RESULT="$ARTIFACT_DIR/legal.result.json"
PLAN_RESULT="$ARTIFACT_DIR/plan.result.json"
MENTOR_RESULT="$ARTIFACT_DIR/mentor.result.json"
FUNDING_RESULT="$ARTIFACT_DIR/funding.result.json"
MONEY_REVENUE_RESULT="$ARTIFACT_DIR/money_revenue.result.json"

MARKET_HTML="$ARTIFACT_DIR/market.html"
ACADEMIC_CONTEXT="$ARTIFACT_DIR/academic_context.txt"
ACADEMIC_HTML="$ARTIFACT_DIR/academic.html"
LEGAL_HTML="$ARTIFACT_DIR/legal.html"
PLAN_HTML="$ARTIFACT_DIR/milestones.html"
MENTOR_HTML="$ARTIFACT_DIR/mentor.html"
FUNDING_HTML="$ARTIFACT_DIR/funding.html"
MONEY_REVENUE_HTML="$ARTIFACT_DIR/money_revenue.html"

MARKET_SUMMARY="$ARTIFACT_DIR/market.summary.txt"
ACADEMIC_SUMMARY="$ARTIFACT_DIR/academic.summary.txt"
PLAN_SUMMARY="$ARTIFACT_DIR/plan.summary.txt"
MENTOR_SUMMARY="$ARTIFACT_DIR/mentor.summary.txt"
FUNDING_SUMMARY="$ARTIFACT_DIR/funding.summary.txt"
MONEY_REVENUE_SUMMARY="$ARTIFACT_DIR/money_revenue.summary.txt"
LEGAL_SUMMARY="$ARTIFACT_DIR/legal.summary.txt"
PLAN_INPUT_SUMMARY="$ARTIFACT_DIR/plan_input_summary.txt"
LIFE_RESULT="$ARTIFACT_DIR/life.result.json"
LIFE_SUMMARY="$ARTIFACT_DIR/life.summary.txt"
LIFE_HTML="$ARTIFACT_DIR/life.html"
LIFE_MD="$ARTIFACT_DIR/life.md"
WEB_SUMMARY_FILE="$ARTIFACT_DIR/web_search.summary.txt"
WEB_HTML_FILE="$ARTIFACT_DIR/web_search_digest.html"
EMAIL_INCREMENTAL_DIR="$ARTIFACT_DIR/email_incremental"
EMAIL_INCREMENTAL_HTML="$ARTIFACT_DIR/email_incremental.html"

CURRENT_MILESTONE_HTML="$ARTIFACT_DIR/current_milestones.html"
: > "$CURRENT_MILESTONE_HTML"

if [[ "$RUN_LEGAL_DEPT" != "1" ]]; then
  printf '%s\n' "Legal compliance stage disabled for this run." > "$LEGAL_SUMMARY"
  printf '%s\n' "<p>Legal compliance stage skipped for this run.</p>" > "$LEGAL_HTML"
fi
if [[ ! -s "$WEB_SUMMARY_FILE" ]]; then
  printf '%s\n' "Web search disabled for this run." > "$WEB_SUMMARY_FILE"
  printf '<p>Web search disabled for this run.</p>' > "$WEB_HTML_FILE"
fi

TOTAL_STEPS=8
if [[ "$HAS_RESOURCE_CACHE" == "1" ]]; then
  TOTAL_STEPS=$((TOTAL_STEPS + 1))
fi
if [[ "$RUN_WEB_SEARCH" == "1" ]]; then
  TOTAL_STEPS=$((TOTAL_STEPS + 1))
fi
if [[ "$ACADEMIC_RESEARCH" == "1" ]]; then
  TOTAL_STEPS=$((TOTAL_STEPS + 1))
fi
if [[ "$RUN_LEGAL_DEPT" == "1" ]]; then
  TOTAL_STEPS=$((TOTAL_STEPS + 1))
fi
if [[ "$RUN_LIFE_REMINDER" == "1" ]]; then
  TOTAL_STEPS=$((TOTAL_STEPS + 1))
fi

BASE_STEP=0
if [[ "$HAS_RESOURCE_CACHE" == "1" ]]; then
  BASE_STEP=1
  log "Step 0/$TOTAL_STEPS: analyze resources and create reference summary"
fi

STEP_CURSOR=$((BASE_STEP + 1))
READ_NOTE_STEP=$STEP_CURSOR
STEP_CURSOR=$((STEP_CURSOR + 1))

if [[ "$RUN_WEB_SEARCH" == "1" ]]; then
  WEB_STEP=$STEP_CURSOR
  STEP_CURSOR=$((STEP_CURSOR + 1))
else
  WEB_STEP="$BASE_STEP"
fi

MARKET_STEP=$STEP_CURSOR
STEP_CURSOR=$((STEP_CURSOR + 1))

if [[ "$ACADEMIC_RESEARCH" == "1" ]]; then
  ACADEMIC_STEP=$STEP_CURSOR
  STEP_CURSOR=$((STEP_CURSOR + 1))
else
  ACADEMIC_STEP="$BASE_STEP"
fi

if [[ "$RUN_LEGAL_DEPT" == "1" ]]; then
  LEGAL_STEP=$STEP_CURSOR
  STEP_CURSOR=$((STEP_CURSOR + 1))
else
  LEGAL_STEP="$BASE_STEP"
fi

FUNDING_STEP=$STEP_CURSOR
STEP_CURSOR=$((STEP_CURSOR + 1))
MONEY_STEP=$STEP_CURSOR
STEP_CURSOR=$((STEP_CURSOR + 1))
PLAN_STEP=$STEP_CURSOR
STEP_CURSOR=$((STEP_CURSOR + 1))
MENTOR_STEP=$STEP_CURSOR
STEP_CURSOR=$((STEP_CURSOR + 1))

if [[ "$RUN_LIFE_REMINDER" == "1" ]]; then
  LIFE_STEP=$STEP_CURSOR
  STEP_CURSOR=$((STEP_CURSOR + 1))
else
  LIFE_STEP="$BASE_STEP"
fi

LOG_STEP=$STEP_CURSOR
STEP_CURSOR=$((STEP_CURSOR + 1))
EMAIL_STEP=$STEP_CURSOR

log "Step ${READ_NOTE_STEP}/$TOTAL_STEPS: read current milestone note from AutoLife"
"$PROMPT_DIR/notes/prompt_la_note_reader.sh" \
  --account "iCloud" \
  --root-folder "AutoLife" \
  --folder-path "🏢 Companies/🐼 Lazying.art" \
  --note "🎨 Lazying.art · Milestones / 里程碑 / マイルストーン" \
  --out "$CURRENT_MILESTONE_HTML" || true

if [[ "$RUN_WEB_SEARCH" == "1" ]]; then
  if [[ "${#LA_WEB_SEARCH_QUERIES[@]}" -eq 0 ]]; then
    LA_WEB_SEARCH_QUERIES=("${(@f)$(build_default_web_search_queries "$LA_PRIMARY_BRAND" "$LA_WEBSITE" "$LA_GITHUB_PROFILE" "$LA_WEB_QUERY_BUDGET" "$CONTEXT_FILE")}")
  fi
  log "Step ${WEB_STEP}/$TOTAL_STEPS: immersive web search triage"
  : > "$WEB_SUMMARY_FILE"
  : > "$WEB_HTML_FILE"
  if ! run_web_search_queries "lazyingart" "$WEB_OUTPUT_DIR" "$WEB_SEARCH_TOP_RESULTS" "$MODEL" "$REASONING" "$SAFETY" "$APPROVAL" "$RUN_ID" "${LA_WEB_SEARCH_QUERIES[@]}"; then
    printf '%s\n' "Web search stage failed; continuing with available context." > "$WEB_SUMMARY_FILE"
    printf '%s\n' "<p>Web search stage failed; continuing with other sources.</p>" > "$WEB_HTML_FILE"
  fi

  cp "$WEB_SUMMARY_FILE" "$NOTES_ROOT/last_web_search.summary.txt"
  cp "$WEB_HTML_FILE" "$NOTES_ROOT/last_web_search.html"
  {
    echo "Web search summary:"
    echo "  output_dir: $WEB_OUTPUT_DIR"
    echo "  top_results_per_query: $WEB_SEARCH_TOP_RESULTS"
    cat "$WEB_SUMMARY_FILE"
  } >> "$CONTEXT_FILE"
  "$PROMPT_DIR/notes/prompt_la_note_save.sh" \
    --account "iCloud" \
    --root-folder "AutoLife" \
    --folder-path "🏢 Companies/🐼 Lazying.art" \
    --note "🕸️ Web Search Signals / 网页信号 / ウェブシグナル" \
    --mode append \
    --html-file "$WEB_HTML_FILE"
fi
update_incremental_email "web_search"

LA_MARKET_REFERENCE_ARGS=(
  --reference-source "$LA_WEBSITE"
  --reference-source "$WEBSITE_SNAPSHOT_FILE"
  --reference-source "$LA_GITHUB_PROFILE"
  --reference-source "$LIFEPATH_BASE/Input"
  --reference-source "$LIFEPATH_BASE/Output"
  --reference-source "$RESOURCE_OUTPUT_DIR"
)
LA_ACADEMIC_REFERENCE_ARGS=(
  "${LA_MARKET_REFERENCE_ARGS[@]}"
)
for source in "${ACADEMIC_RSS_SOURCES[@]}"; do
  LA_ACADEMIC_REFERENCE_ARGS+=(--reference-source "$source")
done

log "Step ${MARKET_STEP}/$TOTAL_STEPS: market research"
"$PROMPT_DIR/company/prompt_la_market.sh" \
  --context-file "$CONTEXT_FILE" \
  --company-focus "$LA_PRIMARY_BRAND" \
  "${LA_MARKET_REFERENCE_ARGS[@]}" \
  --model "$MODEL" \
  --reasoning "$REASONING" \
  --safety "$SAFETY" \
  --approval "$APPROVAL" \
  > "$MARKET_RESULT"

extract_note_html "$MARKET_RESULT" "$MARKET_HTML"
extract_summary "$MARKET_RESULT" "$MARKET_SUMMARY"
cp "$MARKET_RESULT" "$NOTES_ROOT/last_market_result.json"
cp "$MARKET_HTML" "$NOTES_ROOT/last_market.html"

"$PROMPT_DIR/notes/prompt_la_note_save.sh" \
  --account "iCloud" \
  --root-folder "AutoLife" \
  --folder-path "🏢 Companies/🐼 Lazying.art" \
  --note "🧠 Market Intel Digest / 市場情報ログ" \
  --mode append \
  --html-file "$MARKET_HTML"
update_incremental_email "market"

if [[ "$ACADEMIC_RESEARCH" == "1" ]]; then
  if [[ "${#ACADEMIC_QUERIES[@]}" -eq 0 ]]; then
    ACADEMIC_QUERIES=("${(@f)$(build_default_academic_queries "$LA_PRIMARY_BRAND" "$ACADEMIC_QUERY_BUDGET" "$CONTEXT_FILE" "${ACADEMIC_RSS_SOURCES[@]}")}")
  fi

  log "Step ${ACADEMIC_STEP}/$TOTAL_STEPS: academic research (high-impact)"

  ACADEMIC_QUERIES_JSON="$(python3 - <<'PY' "${ACADEMIC_QUERIES[@]}"
import json
import sys

print(json.dumps([q for q in sys.argv[1:] if q.strip()], ensure_ascii=False))
PY
)"
  build_academic_context_websearch "$ACADEMIC_CONTEXT" "$ACADEMIC_QUERIES_JSON" "$ACADEMIC_MAX_RESULTS" "${ACADEMIC_RSS_SOURCES[@]}"

  "$PROMPT_DIR/company/prompt_la_market.sh" \
    --context-file "$ACADEMIC_CONTEXT" \
    --company-focus "$LA_PRIMARY_BRAND" \
    "${LA_ACADEMIC_REFERENCE_ARGS[@]}" \
    --prompt-file "$PROMPT_DIR/company/la_academic_research_prompt.md" \
    --model "$MODEL" \
    --reasoning "$REASONING" \
    --safety "$SAFETY" \
    --approval "$APPROVAL" \
    --label "la-academic" \
    > "$ACADEMIC_RESULT"

  extract_note_html "$ACADEMIC_RESULT" "$ACADEMIC_HTML"
  extract_summary "$ACADEMIC_RESULT" "$ACADEMIC_SUMMARY"
  cp "$ACADEMIC_RESULT" "$NOTES_ROOT/last_academic_result.json"
  cp "$ACADEMIC_HTML" "$NOTES_ROOT/last_academic.html"

  "$PROMPT_DIR/notes/prompt_la_note_save.sh" \
    --account "iCloud" \
    --root-folder "AutoLife" \
    --folder-path "🏢 Companies/🐼 Lazying.art" \
    --note "📚 Lazying.art Academic Research / 论文追踪 / 論文追蹤" \
    --mode append \
    --html-file "$ACADEMIC_HTML"
else
  printf '%s\n' "Academic research disabled for this run." > "$ACADEMIC_SUMMARY"
  printf '%s\n' "<p>Academic research skipped.</p>" > "$ACADEMIC_HTML"
  printf '%s\n' "{}" > "$ACADEMIC_RESULT"
fi
update_incremental_email "academic"

merge_market_and_academic_summaries "$MARKET_SUMMARY" "$ACADEMIC_SUMMARY" "$PLAN_INPUT_SUMMARY" "$WEB_SUMMARY_FILE"

if [[ "$RUN_LEGAL_DEPT" == "1" ]]; then
  log "Step ${LEGAL_STEP}/$TOTAL_STEPS: legal compliance and tax review (HK + Mainland + US)"
  "$PROMPT_DIR/company/prompt_legal_dept.sh" \
    --company-focus "$LA_PRIMARY_BRAND" \
    --legal-root "$LEGAL_INPUT_ROOT" \
    --context-file "$CONTEXT_FILE" \
    --market-summary-file "$PLAN_INPUT_SUMMARY" \
    --resource-summary-file "$RESOURCE_APPEND_PATH" \
    --web-summary-file "$WEB_SUMMARY_FILE" \
    --reference-source "$LA_WEBSITE" \
    --reference-source "$LA_GITHUB_PROFILE" \
    --legal-web-search \
    --prompt-file "$LA_LEGAL_PROMPT_FILE" \
    --model "$MODEL" \
    --reasoning "$REASONING" \
    --safety "$SAFETY" \
    --approval "$APPROVAL" \
    --label "la-legal" \
    > "$LEGAL_RESULT"

  extract_note_html "$LEGAL_RESULT" "$LEGAL_HTML"
  extract_summary "$LEGAL_RESULT" "$LEGAL_SUMMARY"
  cp "$LEGAL_RESULT" "$NOTES_ROOT/last_legal_result.json"
  cp "$LEGAL_HTML" "$NOTES_ROOT/last_legal.html"

  "$PROMPT_DIR/notes/prompt_la_note_save.sh" \
    --account "iCloud" \
    --root-folder "AutoLife" \
    --folder-path "🏢 Companies/🐼 Lazying.art" \
    --note "⚖️ Lazying.art 法务与税务合规 / 法務與稅務コンプライアンス" \
    --mode append \
    --html-file "$LEGAL_HTML"
else
  printf '%s\n' "Legal compliance stage disabled for this run." > "$LEGAL_SUMMARY"
  printf '%s\n' "<p>Legal compliance stage skipped for this run.</p>" > "$LEGAL_HTML"
fi
update_incremental_email "legal"
{
  echo
  echo "Legal summary:"
  cat "$LEGAL_SUMMARY"
} >> "$CONTEXT_FILE"

log "Step ${FUNDING_STEP}/$TOTAL_STEPS: funding and VC opportunities"
"$PROMPT_DIR/company/prompt_funding_vc.sh" \
  --context-file "$CONTEXT_FILE" \
  --market-summary-file "$PLAN_INPUT_SUMMARY" \
  --resource-summary-file "$RESOURCE_APPEND_PATH" \
  --web-summary-file "$WEB_SUMMARY_FILE" \
  --legal-summary-file "$LEGAL_SUMMARY" \
  --company-focus "$LA_PRIMARY_BRAND" \
  --language-policy "$FUNDING_LANGUAGE_POLICY" \
  "${LA_ACADEMIC_REFERENCE_ARGS[@]}" \
  --model "$MODEL" \
  --reasoning "$REASONING" \
  --safety "$SAFETY" \
  --approval "$APPROVAL" \
  > "$FUNDING_RESULT"

extract_note_html "$FUNDING_RESULT" "$FUNDING_HTML"
extract_summary "$FUNDING_RESULT" "$FUNDING_SUMMARY"
cp "$FUNDING_RESULT" "$NOTES_ROOT/last_funding_result.json"
cp "$FUNDING_HTML" "$NOTES_ROOT/last_funding.html"

"$PROMPT_DIR/notes/prompt_la_note_save.sh" \
  --account "iCloud" \
  --root-folder "AutoLife" \
  --folder-path "🏢 Companies/🐼 Lazying.art" \
  --note "🏦 Funding & VC Opportunities / 融资与VC机会 / 融資与VC機会" \
  --mode append \
  --html-file "$FUNDING_HTML"
update_incremental_email "funding"

log "Step ${MONEY_STEP}/$TOTAL_STEPS: monetization and revenue strategy"
"$PROMPT_DIR/company/prompt_money_revenue.sh" \
  --context-file "$CONTEXT_FILE" \
  --market-summary-file "$PLAN_INPUT_SUMMARY" \
  --funding-summary-file "$FUNDING_SUMMARY" \
  --resource-summary-file "$RESOURCE_APPEND_PATH" \
  --academic-summary-file "$ACADEMIC_SUMMARY" \
  --web-summary-file "$WEB_SUMMARY_FILE" \
  --company-focus "$LA_PRIMARY_BRAND" \
  --language-policy "$MONEY_REVENUE_LANGUAGE_POLICY" \
  "${LA_ACADEMIC_REFERENCE_ARGS[@]}" \
  --model "$MODEL" \
  --reasoning "$REASONING" \
  --safety "$SAFETY" \
  --approval "$APPROVAL" \
  > "$MONEY_REVENUE_RESULT"

extract_note_html "$MONEY_REVENUE_RESULT" "$MONEY_REVENUE_HTML"
extract_summary "$MONEY_REVENUE_RESULT" "$MONEY_REVENUE_SUMMARY"
cp "$MONEY_REVENUE_RESULT" "$NOTES_ROOT/last_money_revenue_result.json"
cp "$MONEY_REVENUE_HTML" "$NOTES_ROOT/last_money_revenue.html"

"$PROMPT_DIR/notes/prompt_la_note_save.sh" \
  --account "iCloud" \
  --root-folder "AutoLife" \
  --folder-path "🏢 Companies/🐼 Lazying.art" \
  --note "💰 Monetization & Revenue Strategy / 變現與收益 / 収益化戦略" \
  --mode append \
  --html-file "$MONEY_REVENUE_HTML"
update_incremental_email "money_revenue"

log "Step ${PLAN_STEP}/$TOTAL_STEPS: milestone plan draft"
"$PROMPT_DIR/company/prompt_la_plan.sh" \
  --note-html "$CURRENT_MILESTONE_HTML" \
  --market-summary-file "$PLAN_INPUT_SUMMARY" \
  --academic-summary-file "$PLAN_INPUT_SUMMARY" \
  --funding-summary-file "$FUNDING_SUMMARY" \
  --web-summary-file "$WEB_SUMMARY_FILE" \
  --model "$MODEL" \
  --reasoning "$REASONING" \
  --safety "$SAFETY" \
  --approval "$APPROVAL" \
  > "$PLAN_RESULT"

extract_note_html "$PLAN_RESULT" "$PLAN_HTML"
extract_summary "$PLAN_RESULT" "$PLAN_SUMMARY"
cp "$PLAN_RESULT" "$NOTES_ROOT/last_plan_result.json"
cp "$PLAN_HTML" "$NOTES_ROOT/last_plan.html"

"$PROMPT_DIR/notes/prompt_la_note_save.sh" \
  --account "iCloud" \
  --root-folder "AutoLife" \
  --folder-path "🏢 Companies/🐼 Lazying.art" \
  --note "🎨 Lazying.art · Milestones / 里程碑 / マイルストーン" \
  --mode replace \
  --html-file "$PLAN_HTML"
update_incremental_email "plan"

log "Step ${MENTOR_STEP}/$TOTAL_STEPS: entrepreneurship mentor"
"$PROMPT_DIR/company/prompt_entrepreneurship_mentor.sh" \
  --market-summary-file "$PLAN_INPUT_SUMMARY" \
  --plan-summary-file "$PLAN_SUMMARY" \
  --academic-summary-file "$PLAN_INPUT_SUMMARY" \
  --funding-summary-file "$FUNDING_SUMMARY" \
  --web-summary-file "$WEB_SUMMARY_FILE" \
  --milestone-html-file "$PLAN_HTML" \
  --model "$MODEL" \
  --reasoning "$REASONING" \
  --safety "$SAFETY" \
  --approval "$APPROVAL" \
  > "$MENTOR_RESULT"

extract_note_html "$MENTOR_RESULT" "$MENTOR_HTML"
extract_summary "$MENTOR_RESULT" "$MENTOR_SUMMARY"
cp "$MENTOR_RESULT" "$NOTES_ROOT/last_mentor_result.json"
cp "$MENTOR_HTML" "$NOTES_ROOT/last_mentor.html"

"$PROMPT_DIR/notes/prompt_la_note_save.sh" \
  --account "iCloud" \
  --root-folder "AutoLife" \
  --folder-path "🏢 Companies/🐼 Lazying.art" \
  --note "🧭 Entrepreneurship Mentor / 創業メンター / 創業導航" \
  --mode append \
  --html-file "$MENTOR_HTML"
update_incremental_email "mentor"

if [[ "$RUN_LIFE_REMINDER" == "1" ]]; then
  log "Step ${LIFE_STEP}/$TOTAL_STEPS: life reverse reminder planning"
  "$PROMPT_DIR/company/prompt_life_reverse_engineering_tool.sh" \
    --input-md "$LIFE_INPUT_MD" \
    --company-focus "$LA_PRIMARY_BRAND" \
    --state-md "$LIFE_STATE_MD" \
    --state-json "$WORKSPACE/AutoLife/MetaNotes/Companies/LazyingArt/life_reminder_state.json" \
    --market-summary-file "$MARKET_SUMMARY" \
    --plan-summary-file "$PLAN_SUMMARY" \
    --mentor-summary-file "$MENTOR_SUMMARY" \
    --output-dir "$ARTIFACT_DIR/life-codex" \
    --report-json "$LIFE_RESULT" \
    --report-md "$LIFE_MD" \
    --report-html "$LIFE_HTML" \
    --list-name "LazyingArt" \
    --slot-prefix "RevEng" \
    --run-id "$RUN_ID" \
    --model "$MODEL" \
    --reasoning "$REASONING" \
    $( [[ "$WRITE_REMINDER" == "0" ]] && printf '%s\n' "--no-write-reminder" ) \
    >/dev/null

  extract_summary "$LIFE_RESULT" "$LIFE_SUMMARY"
  if [[ "$WRITE_REMINDER" == "1" ]]; then
    cp "$LIFE_RESULT" "$NOTES_ROOT/last_life_result.json"
    cp "$LIFE_MD" "$NOTES_ROOT/last_life_plan.md"
    cp "$LIFE_HTML" "$NOTES_ROOT/last_life_plan.html"

    "$PROMPT_DIR/notes/prompt_la_note_save.sh" \
      --account "iCloud" \
      --root-folder "AutoLife" \
      --folder-path "🏢 Companies/🐼 Lazying.art" \
      --note "🗓️ Life Reverse Plan / 反向规划 / 逆算計画" \
      --mode replace \
      --html-file "$LIFE_HTML"
  else
    log "Step ${LIFE_STEP}/$TOTAL_STEPS: life reverse plan generated only; persistence skipped"
  fi
else
  log "Step ${LOG_STEP}/$TOTAL_STEPS: life reminder skipped (disabled)"
  printf '%s\n' "Life reminder planner disabled by --no-life-reminder" > "$LIFE_SUMMARY"
  printf '%s\n' "<p>Life reminder planner disabled.</p>" > "$LIFE_HTML"
fi
update_incremental_email "life"

EMAIL_HTML="$ARTIFACT_DIR/email_digest.html"
python3 - "$MARKET_HTML" "$WEB_HTML_FILE" "$ACADEMIC_HTML" "$FUNDING_HTML" "$MONEY_REVENUE_HTML" "$LEGAL_HTML" "$PLAN_HTML" "$MENTOR_HTML" "$PLAN_INPUT_SUMMARY" "$LIFE_HTML" "$EMAIL_INCREMENTAL_HTML" "$EMAIL_HTML" <<'PY'
import html
import sys
from datetime import datetime
from pathlib import Path

market = Path(sys.argv[1]).read_text(encoding="utf-8")
web = Path(sys.argv[2]).read_text(encoding="utf-8")
academic = Path(sys.argv[3]).read_text(encoding="utf-8")
funding = Path(sys.argv[4]).read_text(encoding="utf-8")
money = Path(sys.argv[5]).read_text(encoding="utf-8")
legal = Path(sys.argv[6]).read_text(encoding="utf-8")
plan = Path(sys.argv[7]).read_text(encoding="utf-8")
mentor = Path(sys.argv[8]).read_text(encoding="utf-8")
plan_input = Path(sys.argv[9]).read_text(encoding="utf-8").strip()
life = Path(sys.argv[10]).read_text(encoding="utf-8")
incremental_path = Path(sys.argv[11])
incremental = incremental_path.read_text(encoding="utf-8") if incremental_path.exists() else ""
out = Path(sys.argv[12])

run_ts = datetime.now().astimezone().strftime("%Y-%m-%d %H:%M %Z")
parts = [
    f"<h1>🎨 Lazying.art Daily Intelligence Digest</h1>",
    f"<p><strong>Generated:</strong> {html.escape(run_ts)}</p>",
    "<hr/>",
]
if incremental.strip():
    parts.append(f"<h2>🧩 Incremental Digest / 增量摘要 / 増分ダイジェスト</h2>{incremental}")
    parts.append("<hr/>")
parts.extend(
    [
        f"<h2>🧠 Market Research / 市场 / 市場</h2>{market}",
        "<hr/>",
        f"<h2>🕸️ Web Search Signals / 网页信号 / ウェブシグナル</h2>{web}",
        "<hr/>",
        f"<h2>🏦 Funding & VC Opportunities / 融资与VC机会 / 融資與VC機會</h2>{funding}",
        "<hr/>",
        f"<h2>💰 Monetization & Revenue Strategy / 变现与增长 / 収益化戦略</h2>{money}",
        "<hr/>",
        f"<h2>⚖️ Legal / Compliance / Tax / 法务合规税务</h2>{legal}",
        "<hr/>",
        f"<h2>📚 High-Impact Academic Research / 高质量论文追踪 / 高影響論文追跡</h2>{academic}",
        "<hr/>",
        f"<h2>🧭 Executive Note / 运营要点 / 運營要點</h2><p>{html.escape(plan_input)}</p>",
        "<hr/>",
        f"<h2>🗺️ Milestones / 里程碑 / マイルストーン</h2>{plan}",
        "<hr/>",
        f"<h2>🧭 Entrepreneurship Mentor / 创业导师 / 創業メンター</h2>{mentor}",
        "<hr/>",
        f"<h2>🗓️ Life Reverse Reminder Plan / 反向规划 / 逆算計画</h2>{life}",
    ]
)
digest = "".join(parts)
out.write_text(digest, encoding="utf-8")
PY

log "Step ${LOG_STEP}/$TOTAL_STEPS: save daily pipeline log note"
LOG_HTML="$ARTIFACT_DIR/pipeline_log_note.html"
python3 - "$RUN_ID" "$MARKET_SUMMARY" "$WEB_SUMMARY_FILE" "$ACADEMIC_SUMMARY" "$FUNDING_SUMMARY" "$MONEY_REVENUE_SUMMARY" "$LEGAL_SUMMARY" "$PLAN_SUMMARY" "$MENTOR_SUMMARY" "$LIFE_SUMMARY" "$LOG_HTML" <<'PY'
import html
import sys
from pathlib import Path

run_id = sys.argv[1]
market = Path(sys.argv[2]).read_text(encoding="utf-8").strip()
web = Path(sys.argv[3]).read_text(encoding="utf-8").strip()
academic = Path(sys.argv[4]).read_text(encoding="utf-8").strip()
funding = Path(sys.argv[5]).read_text(encoding="utf-8").strip()
money = Path(sys.argv[6]).read_text(encoding="utf-8").strip()
legal = Path(sys.argv[7]).read_text(encoding="utf-8").strip()
plan = Path(sys.argv[8]).read_text(encoding="utf-8").strip()
mentor = Path(sys.argv[9]).read_text(encoding="utf-8").strip()
life = Path(sys.argv[10]).read_text(encoding="utf-8").strip()
out = Path(sys.argv[11])

content = (
    f"<h3>📌 Lazying.art Pipeline Run / 运行 / 実行: {html.escape(run_id)}</h3>"
    "<ul>"
    f"<li><strong>🧠 Market</strong>: {html.escape(market)}</li>"
    f"<li><strong>🕸️ Web Search Signals</strong>: {html.escape(web)}</li>"
    f"<li><strong>📚 Academic</strong>: {html.escape(academic)}</li>"
    f"<li><strong>🏦 Funding</strong>: {html.escape(funding)}</li>"
    f"<li><strong>💰 Revenue</strong>: {html.escape(money)}</li>"
    f"<li><strong>⚖️ Legal / Compliance</strong>: {html.escape(legal)}</li>"
    f"<li><strong>🗺️ Plan</strong>: {html.escape(plan)}</li>"
    f"<li><strong>🧭 Mentor</strong>: {html.escape(mentor)}</li>"
    f"<li><strong>🗓️ Life</strong>: {html.escape(life)}</li>"
    "</ul>"
)
out.write_text(content, encoding="utf-8")
PY

"$PROMPT_DIR/notes/prompt_la_note_save.sh" \
  --account "iCloud" \
  --root-folder "AutoLife" \
  --folder-path "🏢 Companies/🐼 Lazying.art" \
  --note "🪵 Lazying.art Pipeline Log / ログ / 日誌" \
  --mode append \
  --html-file "$LOG_HTML"

log "Step ${EMAIL_STEP}/$TOTAL_STEPS: compose/send email digest"
EMAIL_INSTRUCTION="$ARTIFACT_DIR/email_instruction.txt"
cat > "$EMAIL_INSTRUCTION" <<EOF
Create a beautiful HTML email update for Lazying.art.

Requirements:
- Use the provided digest HTML as the core content.
- Keep sections structured and readable in Apple Mail.
- Use Chinese-first narrative with concise English labels for clarity.
- Subject must include: [AutoLife] Lazying.art 08:00/20:00 Update
- Do not invent facts outside the provided digest.
- Keep the Web Search Signals section evidence-based and link-backed.
- Do not drop evidence rows from digest tables unless they are exact duplicates.
- Preserve complete section coverage across web, legal, funding, and market blocks.

Digest HTML:
$(cat "$EMAIL_HTML")
EOF

EMAIL_LOG="$ARTIFACT_DIR/email.log"
if [[ "$SEND_EMAIL" == "1" ]]; then
  cat "$EMAIL_INSTRUCTION" | python3 "$PROMPT_DIR/runtime/codex-email-cli.py" \
    --to "$TO_ADDR" \
    --from "$FROM_ADDR" \
    --model "$MODEL" \
    --reasoning "$REASONING" \
    --safety "$SAFETY" \
    --approval "$APPROVAL" \
    --prompt-tools-dir "$PROMPT_DIR/runtime" \
    --skip-git-check \
    --send \
    >"$EMAIL_LOG" 2>&1
  log "Email sent to $TO_ADDR"
else
  cat "$EMAIL_INSTRUCTION" | python3 "$PROMPT_DIR/runtime/codex-email-cli.py" \
    --to "$TO_ADDR" \
    --from "$FROM_ADDR" \
    --model "$MODEL" \
    --reasoning "$REASONING" \
    --safety "$SAFETY" \
    --approval "$APPROVAL" \
    --prompt-tools-dir "$PROMPT_DIR/runtime" \
    --skip-git-check \
    >"$EMAIL_LOG" 2>&1
  log "Email draft generated (send disabled)"
fi

log "Pipeline completed. artifacts=$ARTIFACT_DIR"
echo "$ARTIFACT_DIR"
