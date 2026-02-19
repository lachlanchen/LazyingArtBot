#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

usage() {
  echo "Usage: $0 --context <markdown table>" >&2
  exit 1
}

CONTEXT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --context)
      shift
      CONTEXT="$1"
      ;;
    *)
      usage
      ;;
  esac
  shift
done

if [[ -z "$CONTEXT" ]]; then
  if [[ -t 0 ]]; then
    usage
  else
    CONTEXT=$(cat)
  fi
fi

TMP=$(mktemp)
python3 - "$TMP" <<'PY'
import json, os, sys
payload = {"context": os.environ.get("CONTEXT")}
with open(sys.argv[1], "w", encoding="utf-8") as fh:
    json.dump(payload, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY

OUTPUT_DIR="/tmp/codex-purchases"
mkdir -p "$OUTPUT_DIR"

python3 scripts/prompt_tools/codex-json-runner.py \
  --input-json "$TMP" \
  --output-dir "$OUTPUT_DIR" \
  --prompt-file orchestral/prompt_tools/purchases_sort_prompt.md \
  --schema orchestral/prompt_tools/purchases_sort_schema.json \
  --model gpt-5.1-codex-mini \
  --reasoning medium \
  --label purchases-sort \
  --skip-git-check

rm -f "$TMP"

cat "$OUTPUT_DIR/latest-result.json"
