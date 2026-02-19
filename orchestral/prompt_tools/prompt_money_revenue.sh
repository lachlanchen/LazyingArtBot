#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

COMPANY_FOCUS="Company"
LANGUAGE_POLICY="Chinese-first with concise bilingual EN/JP support."
CONTEXT_FILE=""
MARKET_SUMMARY_FILE=""
FUNDING_SUMMARY_FILE=""
RESOURCE_SUMMARY_FILE=""
ACADEMIC_SUMMARY_FILE=""
WEB_SUMMARY_FILE=""
MODEL="gpt-5.3-codex-spark"
REASONING="high"
SAFETY="${CODEX_SAFETY:-danger-full-access}"
APPROVAL="${CODEX_APPROVAL:-never}"
OUTPUT_DIR="/tmp/codex-la-pipeline"
LABEL="money-revenue"
PROMPT_FILE="orchestral/prompt_tools/money_revenue_prompt.md"
SCHEMA_FILE="orchestral/prompt_tools/la_ops_schema.json"
REFERENCE_SOURCES=(
  "https://github.com/lachlanchen?tab=repositories"
)
CUSTOM_REFERENCE_SOURCES=0

usage() {
  cat <<'USAGE'
Usage: prompt_money_revenue.sh [options]

Options:
  --company-focus <text>       Company focus label (default: Company)
  --language-policy <text>     Language style override for output
  --context-file <p>           Market + funding context text file
  --market-summary-file <p>     Market summary text file
  --funding-summary-file <p>   Funding/opportunities summary text file
  --resource-summary-file <p>   Resource analysis summary text file
  --academic-summary-file <p>   Optional academic research summary text file
  --web-summary-file <p>       Optional web-search summary file
  --model <name>               Codex model (default: gpt-5.3-codex-spark)
  --reasoning <level>          Reasoning level (default: high)
  --safety <level>             Codex safety mode (default: danger-full-access)
  --approval <policy>          Codex approval policy (default: never)
  --output-dir <path>          Artifact directory (default: /tmp/codex-la-pipeline)
  --label <name>               Run label (default: money-revenue)
  --prompt-file <path>         Prompt template (default: orchestral/prompt_tools/money_revenue_prompt.md)
  --schema-file <path>         Output schema (default: orchestral/prompt_tools/la_ops_schema.json)
  --reference-source <u>       Reference source URL/text (repeatable)
  -h, --help                  Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --company-focus)
      shift
      COMPANY_FOCUS="${1:-}"
      ;;
    --language-policy)
      shift
      LANGUAGE_POLICY="${1:-}"
      ;;
    --context-file)
      shift
      CONTEXT_FILE="${1:-}"
      ;;
    --market-summary-file)
      shift
      MARKET_SUMMARY_FILE="${1:-}"
      ;;
    --funding-summary-file)
      shift
      FUNDING_SUMMARY_FILE="${1:-}"
      ;;
    --resource-summary-file)
      shift
      RESOURCE_SUMMARY_FILE="${1:-}"
      ;;
    --academic-summary-file)
      shift
      ACADEMIC_SUMMARY_FILE="${1:-}"
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
    --prompt-file)
      shift
      PROMPT_FILE="${1:-}"
      ;;
    --schema-file)
      shift
      SCHEMA_FILE="${1:-}"
      ;;
    --reference-source)
      shift
      if [[ "$CUSTOM_REFERENCE_SOURCES" == "0" ]]; then
        REFERENCE_SOURCES=()
        CUSTOM_REFERENCE_SOURCES=1
      fi
      REFERENCE_SOURCES+=("${1:-}")
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

python3 - "$TMP_PAYLOAD" "$CONTEXT_FILE" "$MARKET_SUMMARY_FILE" "$FUNDING_SUMMARY_FILE" "$RESOURCE_SUMMARY_FILE" "$ACADEMIC_SUMMARY_FILE" "$WEB_SUMMARY_FILE" "$COMPANY_FOCUS" "$LANGUAGE_POLICY" "$REF_SOURCES_JSON" <<'PY'
import json
import sys
from datetime import datetime
from pathlib import Path

payload_path = Path(sys.argv[1])
context_path = sys.argv[2]
market_summary_path = sys.argv[3]
funding_summary_path = sys.argv[4]
resource_summary_path = sys.argv[5]
academic_summary_path = sys.argv[6]
web_summary_path = sys.argv[7]
company_focus = sys.argv[8]
language_policy = sys.argv[9]
reference_sources = json.loads(sys.argv[10]) if len(sys.argv) > 10 else []

def read_file(path: str) -> str:
    if not path:
        return ""
    p = Path(path).expanduser()
    if not p.exists():
        return ""
    return p.read_text(encoding="utf-8")

payload = {
    "run_local_iso": datetime.now().astimezone().isoformat(timespec="seconds"),
    "company_focus": company_focus or "Company",
    "language_policy": language_policy or "",
    "run_context": read_file(context_path),
    "market_summary": read_file(market_summary_path),
    "funding_summary": read_file(funding_summary_path),
    "resource_summary": read_file(resource_summary_path),
    "academic_summary": read_file(academic_summary_path),
    "web_search_summary": read_file(web_summary_path),
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
