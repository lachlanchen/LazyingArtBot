#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

CONTEXT_FILE=""
MODEL="gpt-5.1-codex-mini"
REASONING="medium"
OUTPUT_DIR="/tmp/codex-la-pipeline"
LABEL="la-market"
PROMPT_FILE="orchestral/prompt_tools/la_market_research_prompt.md"
SCHEMA_FILE="orchestral/prompt_tools/la_ops_schema.json"
COMPANY_FOCUS="Lazying.art"
REFERENCE_SOURCES=(
  "https://lazying.art"
  "https://github.com/lachlanchen?tab=repositories"
  "https://github.com/lachlanchen"
)
CUSTOM_REFERENCE_SOURCES=0

usage() {
  cat <<'USAGE'
Usage: prompt_la_market.sh [options]

Options:
  --context-file <path>   Optional JSON/text context file
  --model <name>          Codex model (default: gpt-5.1-codex-mini)
  --reasoning <level>     Reasoning level (default: medium)
  --output-dir <path>     Artifact directory (default: /tmp/codex-la-pipeline)
  --label <name>          Run label (default: la-market)
  --company-focus <text>  Company focus label (default: Lazying.art)
  --reference-source <u>  Reference source URL/text (repeatable)
  --prompt-file <path>    Prompt template (default: orchestral/prompt_tools/la_market_research_prompt.md)
  --schema-file <path>    Output schema (default: orchestral/prompt_tools/la_ops_schema.json)
  -h, --help              Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --context-file)
      shift
      CONTEXT_FILE="${1:-}"
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

TMP_PAYLOAD="$(mktemp)"

REF_SOURCES_JSON="$(python3 - <<'PY' "${REFERENCE_SOURCES[@]}"
import json
import sys
items = [x for x in sys.argv[1:] if x.strip()]
print(json.dumps(items, ensure_ascii=False))
PY
)"

python3 - "$TMP_PAYLOAD" "$CONTEXT_FILE" "$COMPANY_FOCUS" "$REF_SOURCES_JSON" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

payload_path = Path(sys.argv[1])
context_path = sys.argv[2]
company_focus = sys.argv[3]
reference_sources = json.loads(sys.argv[4]) if len(sys.argv) > 4 else []

extra_context = ""
if context_path:
    p = Path(context_path).expanduser()
    if p.exists():
        extra_context = p.read_text(encoding="utf-8")
    else:
        extra_context = context_path

payload = {
    "run_local_iso": datetime.now().astimezone().isoformat(timespec="seconds"),
    "run_utc_iso": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    "company_focus": company_focus or "Company",
    "priority_sources": reference_sources,
    "extra_context": extra_context,
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
