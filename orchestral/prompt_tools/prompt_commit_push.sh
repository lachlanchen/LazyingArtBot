#!/bin/zsh
set -euo pipefail

cd /Users/lachlan/Local/Clawbot

usage() {
  echo "Usage: $0 --reason <description> [--push]" >&2
  exit 1
}

REASON=""
DO_PUSH=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --reason)
      shift
      REASON="$1"
      ;;
    --push)
      DO_PUSH=1
      ;;
    *)
      usage
      ;;
  esac
  shift
done

if [[ -z "$REASON" ]]; then
  usage
fi

TMP_JSON=$(mktemp)
cat > "$TMP_JSON" <<JSON
{
  "task": "git-commit-and-summary",
  "reason": "$REASON"
}
JSON

OUTPUT_DIR="/tmp/codex-commit-runs"
mkdir -p "$OUTPUT_DIR"

python3 scripts/prompt_tools/codex-json-runner.py \
  --input-json "$TMP_JSON" \
  --output-dir "$OUTPUT_DIR" \
  --model gpt-5.1-codex-mini \
  --reasoning medium

LATEST=$(cat "$OUTPUT_DIR/latest-result.json")
SUMMARY=$(python3 -c 'import sys, json; data=json.load(sys.stdin); print(data.get("commit_summary",""))' <<<"$LATEST")

if [[ -z "$SUMMARY" ]]; then
  echo "No commit summary generated" >&2
  exit 1
fi

git add -A
git commit -m "$SUMMARY"

if [[ $DO_PUSH -eq 1 ]]; then
  git push origin main
fi

echo "Committed with message: $SUMMARY"
