#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
WORKSPACE="/Users/lachlan/.openclaw/workspace"
PROMPT_DIR="$REPO_DIR/orchestral/prompt_tools"
NOTES_ROOT="$WORKSPACE/AutoLife/MetaNotes/Companies/LazyingArt"
ARTIFACT_BASE="$WORKSPACE/AutoLife/MetaNotes/Companies/LazyingArt/pipeline_runs"
PIPELINE_LOCK_FILE="$ARTIFACT_BASE/.la_pipeline.lock"

DEFAULT_TO="lachchen@qq.com"
DEFAULT_FROM="lachlan.miao.chen@gmail.com"
MODEL="gpt-5.3-codex-spark"
REASONING="xhigh"
SAFETY="${CODEX_SAFETY:-danger-full-access}"
APPROVAL="${CODEX_APPROVAL:-never}"
SEND_EMAIL=1
RUN_WEB_SEARCH=1
RUN_LIFE_REMINDER=1
TO_ADDR="$DEFAULT_TO"
FROM_ADDR="$DEFAULT_FROM"
ACADEMIC_RESEARCH=1
ACADEMIC_MAX_RESULTS=5
WEB_SEARCH_TOP_RESULTS=3
WEB_SEARCH_HOLD_SECONDS="15"
WEB_SEARCH_SCROLL_STEPS="3"
WEB_SEARCH_SCROLL_PAUSE="0.9"
ACADEMIC_QUERIES=(
  "Nature AI multimodal memory systems"
  "Science AI memory indexing and retrieval"
  "Cell memory and long context language models"
  "Optica photonic AI memory"
  "TIPAMI AI and optics publications"
  "CVPR multimodal foundation models"
  "ICML memory-augmented AI systems"
)
ACADEMIC_RSS_SOURCES=(
  "Nature:https://www.nature.com/nature.rss"
  "Science:https://www.science.org/action/showFeed?type=site&jc=science"
  "Cell:https://www.cell.com/cell/rss"
  "Nature Machine Intelligence:https://www.nature.com/natmachintell.rss"
)
LA_WEB_SEARCH_QUERIES=(
  "auto:Lazying.art latest public updates"
  "news:AI startups, creator tools, and product launch updates"
  "scholar:multimodal memory indexing and retrieval"
)
MARKET_CONTEXT_FILE=""
WEB_SEARCH_OUTPUT_DIR="$WORKSPACE/AutoLife/MetaNotes/web_search"
WEB_OUTPUT_DIR="$WEB_SEARCH_OUTPUT_DIR"
LIFEPATH_BASE="$HOME/Documents/LazyingArtBotIO/LazyingArt"
LIFE_INPUT_MD="$LIFEPATH_BASE/Input/LazyingArtCompanyInput.md"
LIFE_STATE_MD="$LIFEPATH_BASE/Output/LazyingArtLifeReminderState.md"
RUN_RESOURCE_ANALYSIS=1
RESOURCE_OUTPUT_DIR="$LIFEPATH_BASE/Output/ResourceAnalysis"
RESOURCE_LABEL="lazyingart-resource-analysis"
FUNDING_LANGUAGE_POLICY="EN:中文:JP = 5:4:1 for operational updates and analysis."
MONEY_REVENUE_LANGUAGE_POLICY="EN:中文:JP = 5:4:1"
ITIN_COMPANY_ROOT="/Users/lachlan/Documents/ITIN+Company"
RESOURCE_ROOTS=(
  "$LIFEPATH_BASE/Input"
  "$LIFEPATH_BASE/Output"
  "$ITIN_COMPANY_ROOT"
)

usage() {
  cat <<'USAGE'
Usage: run_la_pipeline.sh [options]

Runs the Lazying.art chain:
  market research -> milestone plan draft -> monetization strategy ->
  entrepreneurship mentor -> life reverse reminder planning ->
  save notes under AutoLife -> compose/send HTML email

Options:
  --to <email>              Email recipient (default: lachchen@qq.com)
  --from <email>            Sender hint for Apple Mail (default: lachlan.miao.chen@gmail.com)
  --no-send-email           Build email draft only, do not send
  --send-email              Send email (default)
  --model <name>            Codex model (default: gpt-5.3-codex-spark)
  --reasoning <level>       Reasoning level (default: xhigh)
  --market-context <path>   Optional extra context file for market step
  --resource-output-dir <p> Resource analysis markdown output directory
  --resource-label <name>   Resource analysis marker/label
  --resource-root <path>    Add resource root (repeatable; default LazyingArt roots)
  --skip-resource-analysis   Skip upfront resource analysis stage
  --academic-query <text>    Add/override an academic query (repeatable)
  --no-academic-research    Disable academic research stage
  --academic-max-results <n> Max web results per academic query (default: 5)
  --no-web-search            Disable keyword web search stage
  --web-search-top-results <n> Max search results per keyword (default: 3)
  --web-search-scroll-steps <n> Number of scroll steps for opened pages (default: 3)
  --web-search-scroll-pause <sec> Seconds between scroll steps for opened pages (default: 0.9)
  --web-search-hold-seconds <sec> Keep browser open for N seconds per query (default: 15)
  --web-search-query <text>  Add/override a web search query (repeatable)
  --life-input-md <path>    Input markdown for life reminder planner
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
    --web-search-scroll-steps)
      shift
      WEB_SEARCH_SCROLL_STEPS="${1:-3}"
      ;;
    --web-search-scroll-pause)
      shift
      WEB_SEARCH_SCROLL_PAUSE="${1:-0.9}"
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

  if [[ "$raw" == *:* ]]; then
    local kind_candidate="${raw%%:*}"
    local rest="${raw#*:}"
    case "$kind_candidate" in
      auto|general|scholar|news)
        parsed_kind="$kind_candidate"
        parsed_query="$rest"
        ;;
      *)
        parsed_kind="auto"
        parsed_query="$raw"
        ;;
    esac
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
    summary.write(f"  - result_json: {result_json}\n")
    if result_txt is not None:
        summary.write(f"  - result_txt: {result_txt}\n")
    summary.write(f"  - result_dir: {result_dir}\n")
    if search_screenshots:
        summary.write("  - results_page_screenshots:\n")
        for shot in search_screenshots[:6]:
            summary.write(f"    - {shot}\n")
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
        f"<p><strong>result_json:</strong> {html.escape(str(result_json))}</p>"
        f"<p><strong>result_dir:</strong> {html.escape(str(result_dir))}</p>"
        f"<p><strong>result_txt:</strong> {html.escape(str(result_txt)) if result_txt else 'n/a'}</p>"
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
            html_out.write(f"<p><strong>Screenshot:</strong> {html.escape(screenshot)}</p>")
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
            for item in search_screenshots[:6]:
                html_out.write(f"<p><strong>Search screenshot:</strong> {html.escape(str(item))}</p>")
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
                html_out.write(f"<p><strong>Opened screenshot:</strong> {html.escape(str(shot))}</p>")
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

    mkdir -p "$query_result_dir"
  if ! "$PROMPT_DIR/prompt_web_search_immersive.sh" \
      --query "$query_text" \
      --engine "$(web_search_engine_from_kind "$query_kind")" \
      --results "$top_n" \
      --open-top-results "$top_n" \
      --summarize-open-url \
      --output-dir "$run_output_dir" \
      --run-id "$query_run_id" \
      --scroll-steps "$WEB_SEARCH_SCROLL_STEPS" \
      --scroll-pause "$WEB_SEARCH_SCROLL_PAUSE" \
      --keep-open \
      --hold-seconds "$WEB_SEARCH_HOLD_SECONDS" \
      >"$query_log_file" 2>&1; then
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
    academic_queries=(
      "site:nature.com multimodal memory"
      "site:science.org multimodal memory"
      "site:cell.com memory systems"
      "Nature and ICML multimodal AI"
      "Optica and TIPAMI memory AI"
      "site:arxiv.org multimodal memory models"
    )
  fi

  if [[ "$max_results" == [1-9][0-9]* ]]; then
    open_limit="$max_results"
  else
    open_limit=3
  fi
  (( open_limit > 3 )) && open_limit=3
  (( open_limit < 1 )) && open_limit=3

  if ! run_web_search_queries "academic" "$academic_output_root" "$open_limit" "$MODEL" "$REASONING" "$SAFETY" "$APPROVAL" "$RUN_ID" "${academic_queries[@]}"; then
    : > "$out_path"
    {
      echo "[academic] mode=web_search_research"
      echo "[academic] status=web_search_failed"
      echo "[academic] top_results_per_query=$open_limit"
      echo "[academic] query_root=$academic_output_root"
      echo "[academic] summary_file=$WEB_SEARCH_SUMMARY_FILE"
      echo "[academic] html_file=$WEB_SEARCH_HTML_FILE"
      echo "[academic] query_file_root=$academic_output_root"
      echo "[academic] query_file_pattern=query-*.json"
      echo "[academic] query_file_pattern_txt=query-*.txt"
      echo "[academic] query_file_pattern_screenshots=screenshots/*.png"
    } > "$out_path"
    return 0
  fi

  {
    echo "[academic] mode=web_search_research"
    echo "[academic] top_results_per_query=$open_limit"
    echo "[academic] query_count=${#academic_queries[@]}"
    echo "[academic] context_source=prompt_web_search_immersive"
    echo "[academic] summary_file=$WEB_SEARCH_SUMMARY_FILE"
    echo "[academic] html_file=$WEB_SEARCH_HTML_FILE"
    echo "[academic] query_root=$academic_output_root"
    echo "[academic] query_file_root=$academic_output_root"
    echo "[academic] query_file_pattern=query-*.json"
    echo "[academic] query_file_pattern_txt=query-*.txt"
    echo "[academic] query_file_pattern_screenshots=screenshots/*.png"
    echo "[academic] queries:"
    for q in "${academic_queries[@]}"; do
      echo "  - $q"
    done
    echo
    if [[ -f "$WEB_SEARCH_SUMMARY_FILE" ]]; then
      cat "$WEB_SEARCH_SUMMARY_FILE"
    else
      echo "[academic] no academic web search summary found"
    fi
  } > "$out_path"
}

merge_market_and_academic_summaries() {
  local market_path="$1"
  local academic_path="$2"
  local merged_path="$3"
  if [[ -f "$market_path" ]] && [[ -f "$academic_path" ]]; then
    python3 - "$market_path" "$academic_path" "$merged_path" <<'PY'
from pathlib import Path
import sys

market_path = Path(sys.argv[1])
academic_path = Path(sys.argv[2])
output_path = Path(sys.argv[3])

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
if not parts:
    parts.append("No market or academic summary available.")
output_path.write_text("\\n\\n".join(parts) + "\\n", encoding="utf-8")
PY
  elif [[ -f "$market_path" ]]; then
    cp "$market_path" "$merged_path"
  elif [[ -f "$academic_path" ]]; then
    cp "$academic_path" "$merged_path"
  else
    printf '%s\n' "No market or academic summary available." > "$merged_path"
  fi
}

log "Pipeline start run_id=$RUN_ID model=$MODEL reasoning=$REASONING"

acquire_pipeline_lock

RESOURCE_ANALYSIS_RUN_DIR="$ARTIFACT_DIR/resource_analysis"
RESOURCE_ANALYSIS_RESULT=""
RESOURCE_ANALYSIS_MARKDOWN_DIR="$RESOURCE_OUTPUT_DIR/$RUN_ID"
HAS_RESOURCE_CACHE=0
if [[ "$RUN_RESOURCE_ANALYSIS" == "1" ]]; then
  mkdir -p "$RESOURCE_ANALYSIS_RUN_DIR" "$RESOURCE_OUTPUT_DIR" "$RESOURCE_ANALYSIS_MARKDOWN_DIR"
  RESOURCE_ANALYSIS_ARGS=()
  for root in "${RESOURCE_ROOTS[@]}"; do
    RESOURCE_ANALYSIS_ARGS+=(--resource-root "$root")
  done

  log "Step 0/8: analyze resources and build reference summary"
  set +e
  "$PROMPT_DIR/prompt_resource_analysis.sh" \
    --company "LazyingArt" \
    --output-dir "$RESOURCE_ANALYSIS_RUN_DIR" \
    --markdown-output "$RESOURCE_ANALYSIS_MARKDOWN_DIR" \
    --label "$RESOURCE_LABEL" \
    --model "$MODEL" \
    --reasoning "$REASONING" \
    --max-manifest-files 500 \
    --max-text-snippets 50000 \
    --prompt-file "$PROMPT_DIR/resource_analysis_prompt.md" \
    --schema-file "$PROMPT_DIR/resource_analysis_schema.json" \
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
  log "Step 0/8: use latest cached resource analysis markdown."
    HAS_RESOURCE_CACHE=1
  else
    log "Step 0/8: resource analysis skipped."
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
  echo "Primary brand: Lazying.art"
  echo "Must inspect https://lazying.art and https://github.com/lachlanchen?tab=repositories"
  echo "Personal context: based in Hong Kong, can travel to Shenzhen, and LazyingArt LLC is in the US."
  echo "Input/state files are under ~/Documents/LazyingArtBotIO/LazyingArt."
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
PLAN_RESULT="$ARTIFACT_DIR/plan.result.json"
MENTOR_RESULT="$ARTIFACT_DIR/mentor.result.json"
FUNDING_RESULT="$ARTIFACT_DIR/funding.result.json"
MONEY_REVENUE_RESULT="$ARTIFACT_DIR/money_revenue.result.json"

MARKET_HTML="$ARTIFACT_DIR/market.html"
ACADEMIC_CONTEXT="$ARTIFACT_DIR/academic_context.txt"
ACADEMIC_HTML="$ARTIFACT_DIR/academic.html"
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
PLAN_INPUT_SUMMARY="$ARTIFACT_DIR/plan_input_summary.txt"
LIFE_RESULT="$ARTIFACT_DIR/life.result.json"
LIFE_SUMMARY="$ARTIFACT_DIR/life.summary.txt"
LIFE_HTML="$ARTIFACT_DIR/life.html"
LIFE_MD="$ARTIFACT_DIR/life.md"
WEB_SUMMARY_FILE="$ARTIFACT_DIR/web_search.summary.txt"
WEB_HTML_FILE="$ARTIFACT_DIR/web_search_digest.html"

CURRENT_MILESTONE_HTML="$ARTIFACT_DIR/current_milestones.html"
: > "$CURRENT_MILESTONE_HTML"

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
"$PROMPT_DIR/prompt_la_note_reader.sh" \
  --account "iCloud" \
  --root-folder "AutoLife" \
  --folder-path "🏢 Companies/🐼 Lazying.art" \
  --note "🎨 Lazying.art · Milestones / 里程碑 / マイルストーン" \
  --out "$CURRENT_MILESTONE_HTML" || true

if [[ "$RUN_WEB_SEARCH" == "1" ]]; then
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
    echo "  query_file_root: $WEB_OUTPUT_DIR/lazyingart"
    echo "  summary_file: $WEB_SUMMARY_FILE"
    echo "  html_file: $WEB_HTML_FILE"
    echo "  top_results_per_query: $WEB_SEARCH_TOP_RESULTS"
    echo "  query_file_pattern: query-*.json"
    echo "  query_file_pattern_txt: query-*.txt"
    echo "  query_file_pattern_screenshots: screenshots/*.png"
    cat "$WEB_SUMMARY_FILE"
  } >> "$CONTEXT_FILE"
  "$PROMPT_DIR/prompt_la_note_save.sh" \
    --account "iCloud" \
    --root-folder "AutoLife" \
    --folder-path "🏢 Companies/🐼 Lazying.art" \
    --note "🕸️ Web Search Signals / 网页信号 / ウェブシグナル" \
    --mode append \
    --html-file "$WEB_HTML_FILE"
fi

log "Step ${MARKET_STEP}/$TOTAL_STEPS: market research"
"$PROMPT_DIR/prompt_la_market.sh" \
  --context-file "$CONTEXT_FILE" \
  --model "$MODEL" \
  --reasoning "$REASONING" \
  --safety "$SAFETY" \
  --approval "$APPROVAL" \
  > "$MARKET_RESULT"

extract_note_html "$MARKET_RESULT" "$MARKET_HTML"
extract_summary "$MARKET_RESULT" "$MARKET_SUMMARY"
cp "$MARKET_RESULT" "$NOTES_ROOT/last_market_result.json"
cp "$MARKET_HTML" "$NOTES_ROOT/last_market.html"

"$PROMPT_DIR/prompt_la_note_save.sh" \
  --account "iCloud" \
  --root-folder "AutoLife" \
  --folder-path "🏢 Companies/🐼 Lazying.art" \
  --note "🧠 Market Intel Digest / 市場情報ログ" \
  --mode append \
  --html-file "$MARKET_HTML"

if [[ "$ACADEMIC_RESEARCH" == "1" ]]; then
  log "Step ${ACADEMIC_STEP}/$TOTAL_STEPS: academic research (high-impact)"

  ACADEMIC_QUERIES_JSON="$(python3 - <<'PY' "${ACADEMIC_QUERIES[@]}"
import json
import sys

print(json.dumps([q for q in sys.argv[1:] if q.strip()], ensure_ascii=False))
PY
)"
  build_academic_context_websearch "$ACADEMIC_CONTEXT" "$ACADEMIC_QUERIES_JSON" "$ACADEMIC_MAX_RESULTS" "${ACADEMIC_RSS_SOURCES[@]}"

  "$PROMPT_DIR/prompt_la_market.sh" \
    --context-file "$ACADEMIC_CONTEXT" \
    --company-focus "Lazying.art" \
    --reference-source "https://arxiv.org" \
    --reference-source "Nature" \
    --reference-source "Science" \
    --reference-source "Cell" \
    --reference-source "Nature Machine Intelligence" \
    --prompt-file "$PROMPT_DIR/la_academic_research_prompt.md" \
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

  "$PROMPT_DIR/prompt_la_note_save.sh" \
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

merge_market_and_academic_summaries "$MARKET_SUMMARY" "$ACADEMIC_SUMMARY" "$PLAN_INPUT_SUMMARY"

log "Step ${FUNDING_STEP}/$TOTAL_STEPS: funding and VC opportunities"
"$PROMPT_DIR/prompt_funding_vc.sh" \
  --context-file "$CONTEXT_FILE" \
  --market-summary-file "$PLAN_INPUT_SUMMARY" \
  --resource-summary-file "$RESOURCE_APPEND_PATH" \
  --company-focus "Lazying.art" \
  --language-policy "$FUNDING_LANGUAGE_POLICY" \
  --reference-source "https://lazying.art" \
  --reference-source "https://github.com/lachlanchen?tab=repositories" \
  --reference-source "Hong Kong startup competitions, VC and grant updates" \
  --model "$MODEL" \
  --reasoning "$REASONING" \
  --safety "$SAFETY" \
  --approval "$APPROVAL" \
  > "$FUNDING_RESULT"

extract_note_html "$FUNDING_RESULT" "$FUNDING_HTML"
extract_summary "$FUNDING_RESULT" "$FUNDING_SUMMARY"
cp "$FUNDING_RESULT" "$NOTES_ROOT/last_funding_result.json"
cp "$FUNDING_HTML" "$NOTES_ROOT/last_funding.html"

"$PROMPT_DIR/prompt_la_note_save.sh" \
  --account "iCloud" \
  --root-folder "AutoLife" \
  --folder-path "🏢 Companies/🐼 Lazying.art" \
  --note "🏦 Funding & VC Opportunities / 融资与VC机会 / 融資与VC機会" \
  --mode append \
  --html-file "$FUNDING_HTML"

log "Step ${MONEY_STEP}/$TOTAL_STEPS: monetization and revenue strategy"
"$PROMPT_DIR/prompt_money_revenue.sh" \
  --context-file "$CONTEXT_FILE" \
  --market-summary-file "$PLAN_INPUT_SUMMARY" \
  --funding-summary-file "$FUNDING_SUMMARY" \
  --resource-summary-file "$RESOURCE_APPEND_PATH" \
  --academic-summary-file "$ACADEMIC_SUMMARY" \
  --company-focus "Lazying.art" \
  --language-policy "$MONEY_REVENUE_LANGUAGE_POLICY" \
  --reference-source "https://lazying.art" \
  --reference-source "https://github.com/lachlanchen?tab=repositories" \
  --reference-source "Light company monetization and operating context" \
  --model "$MODEL" \
  --reasoning "$REASONING" \
  --safety "$SAFETY" \
  --approval "$APPROVAL" \
  > "$MONEY_REVENUE_RESULT"

extract_note_html "$MONEY_REVENUE_RESULT" "$MONEY_REVENUE_HTML"
extract_summary "$MONEY_REVENUE_RESULT" "$MONEY_REVENUE_SUMMARY"
cp "$MONEY_REVENUE_RESULT" "$NOTES_ROOT/last_money_revenue_result.json"
cp "$MONEY_REVENUE_HTML" "$NOTES_ROOT/last_money_revenue.html"

"$PROMPT_DIR/prompt_la_note_save.sh" \
  --account "iCloud" \
  --root-folder "AutoLife" \
  --folder-path "🏢 Companies/🐼 Lazying.art" \
  --note "💰 Monetization & Revenue Strategy / 變現與收益 / 収益化戦略" \
  --mode append \
  --html-file "$MONEY_REVENUE_HTML"

log "Step ${PLAN_STEP}/$TOTAL_STEPS: milestone plan draft"
"$PROMPT_DIR/prompt_la_plan.sh" \
  --note-html "$CURRENT_MILESTONE_HTML" \
  --market-summary-file "$PLAN_INPUT_SUMMARY" \
  --academic-summary-file "$PLAN_INPUT_SUMMARY" \
  --funding-summary-file "$FUNDING_SUMMARY" \
  --model "$MODEL" \
  --reasoning "$REASONING" \
  --safety "$SAFETY" \
  --approval "$APPROVAL" \
  > "$PLAN_RESULT"

extract_note_html "$PLAN_RESULT" "$PLAN_HTML"
extract_summary "$PLAN_RESULT" "$PLAN_SUMMARY"
cp "$PLAN_RESULT" "$NOTES_ROOT/last_plan_result.json"
cp "$PLAN_HTML" "$NOTES_ROOT/last_plan.html"

"$PROMPT_DIR/prompt_la_note_save.sh" \
  --account "iCloud" \
  --root-folder "AutoLife" \
  --folder-path "🏢 Companies/🐼 Lazying.art" \
  --note "🎨 Lazying.art · Milestones / 里程碑 / マイルストーン" \
  --mode replace \
  --html-file "$PLAN_HTML"

log "Step ${MENTOR_STEP}/$TOTAL_STEPS: entrepreneurship mentor"
"$PROMPT_DIR/prompt_entrepreneurship_mentor.sh" \
  --market-summary-file "$PLAN_INPUT_SUMMARY" \
  --plan-summary-file "$PLAN_SUMMARY" \
  --academic-summary-file "$PLAN_INPUT_SUMMARY" \
  --funding-summary-file "$FUNDING_SUMMARY" \
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

"$PROMPT_DIR/prompt_la_note_save.sh" \
  --account "iCloud" \
  --root-folder "AutoLife" \
  --folder-path "🏢 Companies/🐼 Lazying.art" \
  --note "🧭 Entrepreneurship Mentor / 創業メンター / 創業導航" \
  --mode append \
  --html-file "$MENTOR_HTML"

if [[ "$RUN_LIFE_REMINDER" == "1" ]]; then
  log "Step ${LIFE_STEP}/$TOTAL_STEPS: life reverse reminder planning"
  "$PROMPT_DIR/prompt_life_reverse_engineering_tool.sh" \
    --input-md "$LIFE_INPUT_MD" \
    --state-md "$LIFE_STATE_MD" \
    --market-summary-file "$MARKET_SUMMARY" \
    --plan-summary-file "$PLAN_SUMMARY" \
    --mentor-summary-file "$MENTOR_SUMMARY" \
    --output-dir "$ARTIFACT_DIR/life-codex" \
    --report-json "$LIFE_RESULT" \
    --report-md "$LIFE_MD" \
    --report-html "$LIFE_HTML" \
    --run-id "$RUN_ID" \
    --model "$MODEL" \
    --reasoning "$REASONING" \
    >/dev/null

  extract_summary "$LIFE_RESULT" "$LIFE_SUMMARY"
  cp "$LIFE_RESULT" "$NOTES_ROOT/last_life_result.json"
  cp "$LIFE_MD" "$NOTES_ROOT/last_life_plan.md"
  cp "$LIFE_HTML" "$NOTES_ROOT/last_life_plan.html"

  "$PROMPT_DIR/prompt_la_note_save.sh" \
    --account "iCloud" \
    --root-folder "AutoLife" \
    --folder-path "🏢 Companies/🐼 Lazying.art" \
    --note "🗓️ Life Reverse Plan / 反向规划 / 逆算計画" \
    --mode replace \
    --html-file "$LIFE_HTML"
else
  log "Step ${LOG_STEP}/$TOTAL_STEPS: life reminder skipped (disabled)"
  printf '%s\n' "Life reminder planner disabled by --no-life-reminder" > "$LIFE_SUMMARY"
  printf '%s\n' "<p>Life reminder planner disabled.</p>" > "$LIFE_HTML"
fi

EMAIL_HTML="$ARTIFACT_DIR/email_digest.html"
python3 - "$MARKET_HTML" "$WEB_HTML_FILE" "$ACADEMIC_HTML" "$FUNDING_HTML" "$MONEY_REVENUE_HTML" "$PLAN_HTML" "$MENTOR_HTML" "$LIFE_HTML" "$EMAIL_HTML" <<'PY'
import html
import sys
from datetime import datetime
from pathlib import Path

market = Path(sys.argv[1]).read_text(encoding="utf-8")
web = Path(sys.argv[2]).read_text(encoding="utf-8")
academic = Path(sys.argv[3]).read_text(encoding="utf-8")
funding = Path(sys.argv[4]).read_text(encoding="utf-8")
money = Path(sys.argv[5]).read_text(encoding="utf-8")
plan = Path(sys.argv[6]).read_text(encoding="utf-8")
mentor = Path(sys.argv[7]).read_text(encoding="utf-8")
life = Path(sys.argv[8]).read_text(encoding="utf-8")
out = Path(sys.argv[9])

run_ts = datetime.now().astimezone().strftime("%Y-%m-%d %H:%M %Z")
digest = (
    f"<h1>🎨 Lazying.art Daily Intelligence Digest</h1>"
    f"<p><strong>Generated:</strong> {html.escape(run_ts)}</p>"
    "<hr/>"
    f"<h2>🧠 Market Research</h2>{market}"
    "<hr/>"
    f"<h2>🕸️ Web Search Signals</h2>{web}"
    "<hr/>"
    f"<h2>📚 Academic Research</h2>{academic}"
    "<hr/>"
    f"<h2>🏦 Funding & VC Opportunities</h2>{funding}"
    "<hr/>"
    f"<h2>💰 Monetization & Revenue Strategy</h2>{money}"
    "<hr/>"
    f"<h2>🗺️ Milestones</h2>{plan}"
    "<hr/>"
    f"<h2>🧭 Entrepreneurship Mentor</h2>{mentor}"
    "<hr/>"
    f"<h2>🗓️ Life Reverse Reminder Plan</h2>{life}"
)
out.write_text(digest, encoding="utf-8")
PY

log "Step ${LOG_STEP}/$TOTAL_STEPS: save daily pipeline log note"
LOG_HTML="$ARTIFACT_DIR/pipeline_log_note.html"
python3 - "$RUN_ID" "$MARKET_SUMMARY" "$WEB_SUMMARY_FILE" "$ACADEMIC_SUMMARY" "$FUNDING_SUMMARY" "$MONEY_REVENUE_SUMMARY" "$PLAN_SUMMARY" "$MENTOR_SUMMARY" "$LIFE_SUMMARY" "$LOG_HTML" <<'PY'
import html
import sys
from pathlib import Path

run_id = sys.argv[1]
market = Path(sys.argv[2]).read_text(encoding="utf-8").strip()
web = Path(sys.argv[3]).read_text(encoding="utf-8").strip()
academic = Path(sys.argv[4]).read_text(encoding="utf-8").strip()
funding = Path(sys.argv[5]).read_text(encoding="utf-8").strip()
money = Path(sys.argv[6]).read_text(encoding="utf-8").strip()
plan = Path(sys.argv[7]).read_text(encoding="utf-8").strip()
mentor = Path(sys.argv[8]).read_text(encoding="utf-8").strip()
life = Path(sys.argv[9]).read_text(encoding="utf-8").strip()
out = Path(sys.argv[10])

content = (
    f"<h3>📌 Lazying.art Pipeline Run / 运行 / 実行: {html.escape(run_id)}</h3>"
    "<ul>"
    f"<li><strong>🧠 Market</strong>: {html.escape(market)}</li>"
    f"<li><strong>🕸️ Web Search Signals</strong>: {html.escape(web)}</li>"
    f"<li><strong>📚 Academic</strong>: {html.escape(academic)}</li>"
    f"<li><strong>🏦 Funding</strong>: {html.escape(funding)}</li>"
    f"<li><strong>💰 Revenue</strong>: {html.escape(money)}</li>"
    f"<li><strong>🗺️ Plan</strong>: {html.escape(plan)}</li>"
    f"<li><strong>🧭 Mentor</strong>: {html.escape(mentor)}</li>"
    f"<li><strong>🗓️ Life</strong>: {html.escape(life)}</li>"
    "</ul>"
)
out.write_text(content, encoding="utf-8")
PY

"$PROMPT_DIR/prompt_la_note_save.sh" \
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
- Include bilingual labels (EN/中文/日本語) in headings where natural.
- Subject must include: [AutoLife] Lazying.art 08:00/20:00 Update
- Do not invent facts outside the provided digest.

Digest HTML:
$(cat "$EMAIL_HTML")
EOF

EMAIL_LOG="$ARTIFACT_DIR/email.log"
if [[ "$SEND_EMAIL" == "1" ]]; then
  cat "$EMAIL_INSTRUCTION" | python3 "$PROMPT_DIR/codex-email-cli.py" \
    --to "$TO_ADDR" \
    --from "$FROM_ADDR" \
    --model "$MODEL" \
    --reasoning "$REASONING" \
    --safety "$SAFETY" \
    --approval "$APPROVAL" \
    --prompt-tools-dir "$PROMPT_DIR" \
    --skip-git-check \
    --send \
    >"$EMAIL_LOG" 2>&1
  log "Email sent to $TO_ADDR"
else
  cat "$EMAIL_INSTRUCTION" | python3 "$PROMPT_DIR/codex-email-cli.py" \
    --to "$TO_ADDR" \
    --from "$FROM_ADDR" \
    --model "$MODEL" \
    --reasoning "$REASONING" \
    --safety "$SAFETY" \
    --approval "$APPROVAL" \
    --prompt-tools-dir "$PROMPT_DIR" \
    --skip-git-check \
    >"$EMAIL_LOG" 2>&1
  log "Email draft generated (send disabled)"
fi

log "Pipeline completed. artifacts=$ARTIFACT_DIR"
echo "$ARTIFACT_DIR"
