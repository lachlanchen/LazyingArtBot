#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

NOTE_HTML=""
MARKET_SUMMARY_FILE=""
ACADEMIC_SUMMARY_FILE=""
MODEL="gpt-5.1-codex-mini"
REASONING="medium"
OUTPUT_DIR="/tmp/codex-la-pipeline"
LABEL="la-plan"
PROMPT_FILE="orchestral/prompt_tools/la_plan_draft_prompt.md"
SCHEMA_FILE="orchestral/prompt_tools/la_ops_schema.json"
COMPANY_FOCUS="Lazying.art"
REFERENCE_SOURCES=(
  "https://lazying.art"
  "https://github.com/lachlanchen?tab=repositories"
)
CUSTOM_REFERENCE_SOURCES=0

usage() {
  cat <<'USAGE'
Usage: prompt_la_plan.sh --note-html <path> [options]

Options:
  --note-html <path>          Required. Existing milestones HTML file
  --market-summary-file <p>     Optional. Market summary text file
  --academic-summary-file <p>   Optional. Merged market+academic summary file
  --model <name>              Codex model (default: gpt-5.1-codex-mini)
  --reasoning <level>         Reasoning level (default: medium)
  --output-dir <path>         Artifact directory (default: /tmp/codex-la-pipeline)
  --label <name>              Run label (default: la-plan)
  --company-focus <text>      Company focus label (default: Lazying.art)
  --reference-source <u>      Reference source URL/text (repeatable)
  --prompt-file <path>        Prompt template (default: orchestral/prompt_tools/la_plan_draft_prompt.md)
  --schema-file <path>        Output schema (default: orchestral/prompt_tools/la_ops_schema.json)
  -h, --help                  Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --note-html)
      shift
      NOTE_HTML="${1:-}"
      ;;
    --market-summary-file)
      shift
      MARKET_SUMMARY_FILE="${1:-}"
      ;;
    --academic-summary-file)
      shift
      ACADEMIC_SUMMARY_FILE="${1:-}"
      ;;
    --model)
      shift
      MODEL="${1:-}"
      ;;
    --reasoning)
      shift
      REASONING="${1:-}"
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

if [[ -z "$NOTE_HTML" ]]; then
  usage >&2
  exit 1
fi

if [[ ! -f "$NOTE_HTML" ]]; then
  echo "Missing --note-html file: $NOTE_HTML" >&2
  exit 1
fi

TMP_PAYLOAD="$(mktemp)"

REF_SOURCES_JSON="$(python3 - <<'PY' "${REFERENCE_SOURCES[@]}"
import json
import sys
items = [x for x in sys.argv[1:] if x.strip()]
print(json.dumps(items, ensure_ascii=False))
PY
)"

python3 - "$TMP_PAYLOAD" "$NOTE_HTML" "$MARKET_SUMMARY_FILE" "$ACADEMIC_SUMMARY_FILE" "$COMPANY_FOCUS" "$REF_SOURCES_JSON" <<'PY'
import json
import sys
from datetime import datetime
from pathlib import Path

payload_path = Path(sys.argv[1])
note_html_path = Path(sys.argv[2]).expanduser()
market_summary_path = sys.argv[3]
academic_summary_path = sys.argv[4]
company_focus = sys.argv[5]
reference_sources = json.loads(sys.argv[6]) if len(sys.argv) > 6 else []

market_summary = ""
if market_summary_path:
    p = Path(market_summary_path).expanduser()
    if p.exists():
        market_summary = p.read_text(encoding="utf-8")

academic_summary = ""
if academic_summary_path:
    p = Path(academic_summary_path).expanduser()
    if p.exists():
        academic_summary = p.read_text(encoding="utf-8")

payload = {
    "run_local_iso": datetime.now().astimezone().isoformat(timespec="seconds"),
    "note_html": note_html_path.read_text(encoding="utf-8"),
    "market_summary": market_summary,
    "academic_summary": academic_summary,
    "company_focus": company_focus or "Company",
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
  --label "$LABEL" \
  --skip-git-check \
  >/dev/null

cat "$OUTPUT_DIR/latest-result.json"
rm -f "$TMP_PAYLOAD"
