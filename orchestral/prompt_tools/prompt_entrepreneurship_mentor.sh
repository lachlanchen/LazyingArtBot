#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

MARKET_SUMMARY_FILE=""
PLAN_SUMMARY_FILE=""
MILESTONE_HTML_FILE=""
ACADEMIC_SUMMARY_FILE=""
FUNDING_SUMMARY_FILE=""
WEB_SUMMARY_FILE=""
MODEL="gpt-5.3-codex-spark"
REASONING="high"
SAFETY="${CODEX_SAFETY:-danger-full-access}"
APPROVAL="${CODEX_APPROVAL:-never}"
OUTPUT_DIR="/tmp/codex-la-pipeline"
LABEL="la-mentor"
PROMPT_FILE="orchestral/prompt_tools/entrepreneurship_mentor_prompt.md"
SCHEMA_FILE="orchestral/prompt_tools/la_ops_schema.json"
COMPANY_FOCUS="Lazying.art"
REFERENCE_SOURCES=(
  "https://lazying.art"
  "https://github.com/lachlanchen?tab=repositories"
)
CUSTOM_REFERENCE_SOURCES=0

usage() {
  cat <<'USAGE'
Usage: prompt_entrepreneurship_mentor.sh [options]

Options:
  --market-summary-file <p>  Optional. Market summary text file
  --plan-summary-file <p>    Optional. Plan summary text file
  --milestone-html-file <p>  Optional. Current milestones HTML file
  --academic-summary-file <p> Optional. Merged market+academic summary file
  --funding-summary-file <p> Optional. Funding summary file
  --web-summary-file <p>      Optional. Web-search summary file
  --model <name>             Codex model (default: gpt-5.3-codex-spark)
  --reasoning <level>        Reasoning level (default: high)
  --safety <level>           Codex safety mode (default: danger-full-access)
  --approval <policy>        Codex approval policy (default: never)
  --output-dir <path>        Artifact directory (default: /tmp/codex-la-pipeline)
  --label <name>             Run label (default: la-mentor)
  --company-focus <text>     Company focus label (default: Lazying.art)
  --reference-source <u>     Reference source URL/text (repeatable)
  --prompt-file <path>       Prompt template (default: orchestral/prompt_tools/entrepreneurship_mentor_prompt.md)
  --schema-file <path>       Output schema (default: orchestral/prompt_tools/la_ops_schema.json)
  -h, --help                 Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --market-summary-file)
      shift
      MARKET_SUMMARY_FILE="${1:-}"
      ;;
    --plan-summary-file)
      shift
      PLAN_SUMMARY_FILE="${1:-}"
      ;;
    --milestone-html-file)
      shift
      MILESTONE_HTML_FILE="${1:-}"
      ;;
    --academic-summary-file)
      shift
      ACADEMIC_SUMMARY_FILE="${1:-}"
      ;;
    --funding-summary-file)
      shift
      FUNDING_SUMMARY_FILE="${1:-}"
      ;;
    --web-summary-file)
      shift
      WEB_SUMMARY_FILE="${1:-}"
      ;;
    --model)
      shift
      MODEL="${1:-}"
      ;;
    --reasoning)
      shift
      REASONING="${1:-}"
      ;;
    --safety)
      shift
      SAFETY="${1:-}"
      ;;
    --approval)
      shift
      APPROVAL="${1:-}"
      ;;
    --output-dir)
      shift
      OUTPUT_DIR="${1:-}"
      ;;
    --label)
      shift
      LABEL="${1:-}"
      ;;
    --company-focus)
      shift
      COMPANY_FOCUS="${1:-}"
      ;;
    --reference-source)
      shift
      if [[ "$CUSTOM_REFERENCE_SOURCES" == "0" ]]; then
        REFERENCE_SOURCES=()
        CUSTOM_REFERENCE_SOURCES=1
      fi
      REFERENCE_SOURCES+=("${1:-}")
      ;;
    --prompt-file)
      shift
      PROMPT_FILE="${1:-}"
      ;;
    --schema-file)
      shift
      SCHEMA_FILE="${1:-}"
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

TMP_PAYLOAD="$(mktemp)"

REF_SOURCES_JSON="$(python3 - <<'PY' "${REFERENCE_SOURCES[@]}"
import json
import sys
items = [x for x in sys.argv[1:] if x.strip()]
print(json.dumps(items, ensure_ascii=False))
PY
)"

python3 - "$TMP_PAYLOAD" "$MARKET_SUMMARY_FILE" "$PLAN_SUMMARY_FILE" "$ACADEMIC_SUMMARY_FILE" "$FUNDING_SUMMARY_FILE" "$MILESTONE_HTML_FILE" "$WEB_SUMMARY_FILE" "$COMPANY_FOCUS" "$REF_SOURCES_JSON" <<'PY'
import json
import sys
from datetime import datetime
from pathlib import Path

payload_path = Path(sys.argv[1])
market_path = sys.argv[2]
plan_path = sys.argv[3]
academic_path = sys.argv[4]
funding_path = sys.argv[5]
milestone_path = sys.argv[6]
web_summary_path = sys.argv[7]
company_focus = sys.argv[8]
reference_sources = json.loads(sys.argv[9]) if len(sys.argv) > 9 else []

def read_if_exists(path_str: str) -> str:
    if not path_str:
        return ""
    p = Path(path_str).expanduser()
    if not p.exists():
        return ""
    return p.read_text(encoding="utf-8")

web_summary = read_if_exists(web_summary_path)
payload = {
    "run_local_iso": datetime.now().astimezone().isoformat(timespec="seconds"),
    "company_focus": company_focus or "Company",
    "market_summary": read_if_exists(market_path),
    "plan_summary": read_if_exists(plan_path),
    "academic_summary": read_if_exists(academic_path),
    "funding_summary": read_if_exists(funding_path),
    "milestone_html": read_if_exists(milestone_path),
    "web_search_summary": web_summary,
    "reference_sources": reference_sources,
}

payload_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
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
  --label "$LABEL" \
  --skip-git-check \
  >/dev/null

cat "$OUTPUT_DIR/latest-result.json"
rm -f "$TMP_PAYLOAD"
