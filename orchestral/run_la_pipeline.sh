#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
WORKSPACE="/Users/lachlan/.openclaw/workspace"
PROMPT_DIR="$REPO_DIR/orchestral/prompt_tools"
NOTES_ROOT="$WORKSPACE/AutoLife/MetaNotes/Companies/LazyingArt"
ARTIFACT_BASE="$WORKSPACE/AutoLife/MetaNotes/Companies/LazyingArt/pipeline_runs"

DEFAULT_TO="lachchen@qq.com"
DEFAULT_FROM="lachlan.miao.chen@gmail.com"
MODEL="gpt-5.3-codex-spark"
REASONING="high"
SAFETY="${CODEX_SAFETY:-danger-full-access}"
APPROVAL="${CODEX_APPROVAL:-never}"
SEND_EMAIL=1
RUN_LIFE_REMINDER=1
TO_ADDR="$DEFAULT_TO"
FROM_ADDR="$DEFAULT_FROM"
MARKET_CONTEXT_FILE=""
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
  --reasoning <level>       Reasoning level (default: high)
  --market-context <path>   Optional extra context file for market step
  --resource-output-dir <p> Resource analysis markdown output directory
  --resource-label <name>   Resource analysis marker/label
  --resource-root <path>    Add resource root (repeatable; default LazyingArt roots)
  --skip-resource-analysis   Skip upfront resource analysis stage
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

log "Pipeline start run_id=$RUN_ID model=$MODEL reasoning=$REASONING"

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
PLAN_RESULT="$ARTIFACT_DIR/plan.result.json"
MENTOR_RESULT="$ARTIFACT_DIR/mentor.result.json"
FUNDING_RESULT="$ARTIFACT_DIR/funding.result.json"
MONEY_REVENUE_RESULT="$ARTIFACT_DIR/money_revenue.result.json"

MARKET_HTML="$ARTIFACT_DIR/market.html"
PLAN_HTML="$ARTIFACT_DIR/milestones.html"
MENTOR_HTML="$ARTIFACT_DIR/mentor.html"
FUNDING_HTML="$ARTIFACT_DIR/funding.html"
MONEY_REVENUE_HTML="$ARTIFACT_DIR/money_revenue.html"

MARKET_SUMMARY="$ARTIFACT_DIR/market.summary.txt"
PLAN_SUMMARY="$ARTIFACT_DIR/plan.summary.txt"
MENTOR_SUMMARY="$ARTIFACT_DIR/mentor.summary.txt"
FUNDING_SUMMARY="$ARTIFACT_DIR/funding.summary.txt"
MONEY_REVENUE_SUMMARY="$ARTIFACT_DIR/money_revenue.summary.txt"
LIFE_RESULT="$ARTIFACT_DIR/life.result.json"
LIFE_SUMMARY="$ARTIFACT_DIR/life.summary.txt"
LIFE_HTML="$ARTIFACT_DIR/life.html"
LIFE_MD="$ARTIFACT_DIR/life.md"

CURRENT_MILESTONE_HTML="$ARTIFACT_DIR/current_milestones.html"
: > "$CURRENT_MILESTONE_HTML"

TOTAL_STEPS=8
if [[ "$HAS_RESOURCE_CACHE" == "1" ]]; then
  TOTAL_STEPS=9
fi
TOTAL_STEPS=$((TOTAL_STEPS + 1))

BASE_STEP=0
if [[ "$HAS_RESOURCE_CACHE" == "1" ]]; then
  BASE_STEP=1
  log "Step 0/$TOTAL_STEPS: analyze resources and create reference summary"
fi

READ_NOTE_STEP=$((BASE_STEP + 1))
MARKET_STEP=$((BASE_STEP + 2))
FUNDING_STEP=$((BASE_STEP + 3))
MONEY_STEP=$((BASE_STEP + 4))
PLAN_STEP=$((BASE_STEP + 5))
MENTOR_STEP=$((BASE_STEP + 6))
if [[ "$RUN_LIFE_REMINDER" == "1" ]]; then
  LIFE_STEP=$((BASE_STEP + 7))
  LOG_STEP=$((BASE_STEP + 8))
  EMAIL_STEP=$((BASE_STEP + 9))
else
  LOG_STEP=$((BASE_STEP + 7))
  EMAIL_STEP=$((BASE_STEP + 8))
fi

log "Step ${READ_NOTE_STEP}/$TOTAL_STEPS: read current milestone note from AutoLife"
"$PROMPT_DIR/prompt_la_note_reader.sh" \
  --account "iCloud" \
  --root-folder "AutoLife" \
  --folder-path "🏢 Companies/🐼 Lazying.art" \
  --note "🎨 Lazying.art · Milestones / 里程碑 / マイルストーン" \
  --out "$CURRENT_MILESTONE_HTML" || true

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

log "Step ${FUNDING_STEP}/$TOTAL_STEPS: funding and VC opportunities"
"$PROMPT_DIR/prompt_funding_vc.sh" \
  --context-file "$CONTEXT_FILE" \
  --market-summary-file "$MARKET_SUMMARY" \
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
  --market-summary-file "$MARKET_SUMMARY" \
  --funding-summary-file "$FUNDING_SUMMARY" \
  --resource-summary-file "$RESOURCE_APPEND_PATH" \
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
  --market-summary-file "$MARKET_SUMMARY" \
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
  --market-summary-file "$MARKET_SUMMARY" \
  --plan-summary-file "$PLAN_SUMMARY" \
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
    --safety "$SAFETY" \
    --approval "$APPROVAL" \
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
python3 - "$MARKET_HTML" "$FUNDING_HTML" "$MONEY_REVENUE_HTML" "$PLAN_HTML" "$MENTOR_HTML" "$LIFE_HTML" "$EMAIL_HTML" <<'PY'
import html
import sys
from datetime import datetime
from pathlib import Path

market = Path(sys.argv[1]).read_text(encoding="utf-8")
funding = Path(sys.argv[2]).read_text(encoding="utf-8")
money = Path(sys.argv[3]).read_text(encoding="utf-8")
plan = Path(sys.argv[4]).read_text(encoding="utf-8")
mentor = Path(sys.argv[5]).read_text(encoding="utf-8")
life = Path(sys.argv[6]).read_text(encoding="utf-8")
out = Path(sys.argv[7])

run_ts = datetime.now().astimezone().strftime("%Y-%m-%d %H:%M %Z")
digest = (
    f"<h1>🎨 Lazying.art Daily Intelligence Digest</h1>"
    f"<p><strong>Generated:</strong> {html.escape(run_ts)}</p>"
    "<hr/>"
    f"<h2>🧠 Market Research</h2>{market}"
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
python3 - "$RUN_ID" "$MARKET_SUMMARY" "$FUNDING_SUMMARY" "$MONEY_REVENUE_SUMMARY" "$PLAN_SUMMARY" "$MENTOR_SUMMARY" "$LIFE_SUMMARY" "$LOG_HTML" <<'PY'
import html
import sys
from pathlib import Path

run_id = sys.argv[1]
market = Path(sys.argv[2]).read_text(encoding="utf-8").strip()
funding = Path(sys.argv[3]).read_text(encoding="utf-8").strip()
money = Path(sys.argv[4]).read_text(encoding="utf-8").strip()
plan = Path(sys.argv[5]).read_text(encoding="utf-8").strip()
mentor = Path(sys.argv[6]).read_text(encoding="utf-8").strip()
life = Path(sys.argv[7]).read_text(encoding="utf-8").strip()
out = Path(sys.argv[8])

content = (
    f"<h3>📌 Lazying.art Pipeline Run / 运行 / 実行: {html.escape(run_id)}</h3>"
    "<ul>"
    f"<li><strong>🧠 Market</strong>: {html.escape(market)}</li>"
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
