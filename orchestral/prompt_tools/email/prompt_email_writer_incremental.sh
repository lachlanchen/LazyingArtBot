#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

COMPANY_FOCUS="Lightmind"
STAGE="unknown"
OUTPUT_DIR="/tmp/codex-email-incremental"
OUTPUT_HTML=""
MARKET_SUMMARY_FILE=""
WEB_SUMMARY_FILE=""
ACADEMIC_SUMMARY_FILE=""
LEGAL_SUMMARY_FILE=""
FUNDING_SUMMARY_FILE=""
MONEY_SUMMARY_FILE=""
PLAN_SUMMARY_FILE=""
MENTOR_SUMMARY_FILE=""
LIFE_SUMMARY_FILE=""
MODEL="gpt-5.3-codex"
REASONING="medium"
SAFETY="${CODEX_SAFETY:-danger-full-access}"
APPROVAL="${CODEX_APPROVAL:-never}"
PROMPT_FILE="orchestral/prompt_tools/email/email_writer_incremental_prompt.md"
SCHEMA_FILE="orchestral/prompt_tools/email/email_writer_incremental_schema.json"

usage() {
  cat <<'USAGE'
Usage: prompt_email_writer_incremental.sh [options]

Options:
  --company-focus <text>
  --stage <name>
  --output-dir <path>
  --output-html <path>
  --market-summary-file <path>
  --web-summary-file <path>
  --academic-summary-file <path>
  --legal-summary-file <path>
  --funding-summary-file <path>
  --money-summary-file <path>
  --plan-summary-file <path>
  --mentor-summary-file <path>
  --life-summary-file <path>
  --model <name>
  --reasoning <level>
  --safety <mode>
  --approval <policy>
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --company-focus) shift; COMPANY_FOCUS="${1:-}" ;;
    --stage) shift; STAGE="${1:-unknown}" ;;
    --output-dir) shift; OUTPUT_DIR="${1:-}" ;;
    --output-html) shift; OUTPUT_HTML="${1:-}" ;;
    --market-summary-file) shift; MARKET_SUMMARY_FILE="${1:-}" ;;
    --web-summary-file) shift; WEB_SUMMARY_FILE="${1:-}" ;;
    --academic-summary-file) shift; ACADEMIC_SUMMARY_FILE="${1:-}" ;;
    --legal-summary-file) shift; LEGAL_SUMMARY_FILE="${1:-}" ;;
    --funding-summary-file) shift; FUNDING_SUMMARY_FILE="${1:-}" ;;
    --money-summary-file) shift; MONEY_SUMMARY_FILE="${1:-}" ;;
    --plan-summary-file) shift; PLAN_SUMMARY_FILE="${1:-}" ;;
    --mentor-summary-file) shift; MENTOR_SUMMARY_FILE="${1:-}" ;;
    --life-summary-file) shift; LIFE_SUMMARY_FILE="${1:-}" ;;
    --model) shift; MODEL="${1:-}" ;;
    --reasoning) shift; REASONING="${1:-}" ;;
    --safety) shift; SAFETY="${1:-}" ;;
    --approval) shift; APPROVAL="${1:-}" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

mkdir -p "$OUTPUT_DIR"

TMP_PAYLOAD="$(mktemp)"
python3 - "$TMP_PAYLOAD" "$COMPANY_FOCUS" "$STAGE" "$OUTPUT_HTML" \
  "$MARKET_SUMMARY_FILE" "$WEB_SUMMARY_FILE" "$ACADEMIC_SUMMARY_FILE" "$LEGAL_SUMMARY_FILE" \
  "$FUNDING_SUMMARY_FILE" "$MONEY_SUMMARY_FILE" "$PLAN_SUMMARY_FILE" "$MENTOR_SUMMARY_FILE" "$LIFE_SUMMARY_FILE" <<'PY'
import json
import sys
from datetime import datetime
from pathlib import Path

out = Path(sys.argv[1]).expanduser()
company_focus = sys.argv[2]
stage = sys.argv[3]
output_html = sys.argv[4]
paths = {
    "market_summary": sys.argv[5],
    "web_summary": sys.argv[6],
    "academic_summary": sys.argv[7],
    "legal_summary": sys.argv[8],
    "funding_summary": sys.argv[9],
    "money_summary": sys.argv[10],
    "plan_summary": sys.argv[11],
    "mentor_summary": sys.argv[12],
    "life_summary": sys.argv[13],
}

def read_text(path: str, limit: int = 6000) -> str:
    if not path:
        return ""
    p = Path(path).expanduser()
    if not p.exists() or not p.is_file():
        return ""
    try:
        return p.read_text(encoding="utf-8", errors="ignore")[:limit]
    except Exception:
        return ""

existing_html = read_text(output_html, 200000)
payload = {
    "run_local_iso": datetime.now().astimezone().isoformat(timespec="seconds"),
    "company_focus": company_focus,
    "stage": stage,
    "existing_html": existing_html,
}
for key, path in paths.items():
    payload[key] = read_text(path, 12000)

out.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY

python3 orchestral/prompt_tools/runtime/codex-json-runner.py \
  --input-json "$TMP_PAYLOAD" \
  --output-dir "$OUTPUT_DIR" \
  --prompt-file "$PROMPT_FILE" \
  --schema "$SCHEMA_FILE" \
  --model "$MODEL" \
  --reasoning "$REASONING" \
  --safety "$SAFETY" \
  --approval "$APPROVAL" \
  --label "email-incremental" \
  --skip-git-check \
  >/dev/null

RESULT_JSON="$OUTPUT_DIR/latest-result.json"
if [[ ! -f "$RESULT_JSON" ]]; then
  rm -f "$TMP_PAYLOAD"
  exit 1
fi

python3 - "$RESULT_JSON" "$OUTPUT_HTML" <<'PY'
import json
import sys
from pathlib import Path

result = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
html_body = str(result.get("html_body", "")).strip()
if not html_body:
    raise SystemExit(1)
Path(sys.argv[2]).expanduser().write_text(html_body, encoding="utf-8")
PY

rm -f "$TMP_PAYLOAD"
echo "$OUTPUT_HTML"
