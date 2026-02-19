#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

COMPANY_FOCUS="Company"
LANGUAGE_POLICY="Chinese-first with EN/JP support where useful"
CONTEXT_FILE=""
MARKET_SUMMARY_FILE=""
RESOURCE_SUMMARY_FILE=""
MODEL="gpt-5.3-codex-spark"
REASONING="high"
SAFETY="${CODEX_SAFETY:-danger-full-access}"
APPROVAL="${CODEX_APPROVAL:-never}"
OUTPUT_DIR="/tmp/codex-la-pipeline"
LABEL="funding-vc"
PROMPT_FILE="orchestral/prompt_tools/funding_vc_prompt.md"
SCHEMA_FILE="orchestral/prompt_tools/la_ops_schema.json"
REFERENCE_SOURCES=()
CUSTOM_REFERENCE_SOURCES=0

usage() {
  cat <<'USAGE'
Usage: prompt_funding_vc.sh [options]

Options:
  --company-focus <text>      Company focus label (default: Company)
  --language-policy <text>    Language style override for output
  --context-file <path>       Context JSON/text file
  --market-summary-file <p>   Optional market summary file
  --resource-summary-file <p> Optional resource/resource-analysis summary
  --model <name>              Codex model (default: gpt-5.3-codex-spark)
  --reasoning <level>         Reasoning level (default: high)
  --safety <level>            Codex safety mode (default: danger-full-access)
  --approval <policy>         Codex approval policy (default: never)
  --output-dir <path>         Artifact directory (default: /tmp/codex-la-pipeline)
  --label <name>              Run label (default: funding-vc)
  --reference-source <u>      Reference source URL/text (repeatable)
  --prompt-file <path>        Prompt template (default: orchestral/prompt_tools/funding_vc_prompt.md)
  --schema-file <path>        Output schema (default: orchestral/prompt_tools/la_ops_schema.json)
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
    --resource-summary-file)
      shift
      RESOURCE_SUMMARY_FILE="${1:-}"
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

python3 - "$TMP_PAYLOAD" "$CONTEXT_FILE" "$MARKET_SUMMARY_FILE" "$RESOURCE_SUMMARY_FILE" "$COMPANY_FOCUS" "$LANGUAGE_POLICY" "$REF_SOURCES_JSON" <<'PY'
import json
import sys
from datetime import datetime
from pathlib import Path

payload_path = Path(sys.argv[1])
context_path = sys.argv[2]
market_path = sys.argv[3]
resource_path = sys.argv[4]
company_focus = sys.argv[5]
language_policy = sys.argv[6]
reference_sources = json.loads(sys.argv[7]) if len(sys.argv) > 7 else []

context = ""
if context_path:
    p = Path(context_path).expanduser()
    if p.exists():
        context = p.read_text(encoding="utf-8")
    else:
        context = context_path

market_summary = ""
if market_path:
    p = Path(market_path).expanduser()
    if p.exists():
        market_summary = p.read_text(encoding="utf-8")

resource_summary = ""
if resource_path:
    p = Path(resource_path).expanduser()
    if p.exists():
        resource_summary = p.read_text(encoding="utf-8")

payload = {
    "run_local_iso": datetime.now().astimezone().isoformat(timespec="seconds"),
    "company_focus": company_focus or "Company",
    "language_policy": language_policy,
    "run_context": context,
    "market_summary": market_summary,
    "resource_summary": resource_summary,
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
