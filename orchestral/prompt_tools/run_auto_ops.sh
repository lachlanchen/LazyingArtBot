#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

usage() {
  echo "Usage: $0 --prompt <file> --label <name> [--payload <json>] [--model MODEL] [--reasoning LEVEL]" >&2
  exit 1
}

PROMPT_FILE=""
LABEL="auto-ops"
PAYLOAD=""
MODEL="gpt-5.1-codex-mini"
REASONING="medium"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prompt)
      shift
      PROMPT_FILE="$1"
      ;;
    --label)
      shift
      LABEL="$1"
      ;;
    --payload)
      shift
      PAYLOAD="$1"
      ;;
    --model)
      shift
      MODEL="$1"
      ;;
    --reasoning)
      shift
      REASONING="$1"
      ;;
    *)
      usage
      ;;
  esac
  shift
done

if [[ -z "$PROMPT_FILE" ]]; then
  usage
fi

if [[ -z "$PAYLOAD" ]]; then
  TMP_PAYLOAD=$(mktemp)
  cat > "$TMP_PAYLOAD"
  PAYLOAD="$TMP_PAYLOAD"
else
  TMP_PAYLOAD=""
fi

OUTPUT_DIR="/tmp/codex-auto-ops"
mkdir -p "$OUTPUT_DIR"

python3 scripts/prompt_tools/codex-json-runner.py \
  --input-json "$PAYLOAD" \
  --output-dir "$OUTPUT_DIR" \
  --prompt-file "$PROMPT_FILE" \
  --schema scripts/prompt_tools/auto_ops_schema.json \
  --model "$MODEL" \
  --reasoning "$REASONING" \
  --label "$LABEL" \
  --skip-git-check

RESULT_PATH="$OUTPUT_DIR/latest-result.json"
if [[ ! -f "$RESULT_PATH" ]]; then
  echo "No result file produced" >&2
  exit 1
fi

cat "$RESULT_PATH"

if [[ -n "${TMP_PAYLOAD:-}" ]]; then
  rm -f "$TMP_PAYLOAD"
fi
