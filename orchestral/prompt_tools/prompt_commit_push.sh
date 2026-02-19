#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

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
STATUS_OUTPUT=$(git status -sb)
DIFF_OUTPUT=$(git diff)
export REASON
export STATUS_OUTPUT
export DIFF_OUTPUT

python3 - "$TMP_JSON" <<'PY'
import json, os, sys
path = sys.argv[1]
data = {
    "reason": os.environ.get("REASON"),
    "git_status": os.environ.get("STATUS_OUTPUT"),
    "git_diff": os.environ.get("DIFF_OUTPUT"),
}
with open(path, "w", encoding="utf-8") as fh:
    json.dump(data, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY

OUTPUT_DIR="/tmp/codex-commit-runs"
mkdir -p "$OUTPUT_DIR"
PROMPT_FILE="scripts/prompt_tools/commit_summary_prompt.md"
SCHEMA_FILE="scripts/prompt_tools/commit_summary_schema.json"

python3 scripts/prompt_tools/codex-json-runner.py \
  --input-json "$TMP_JSON" \
  --output-dir "$OUTPUT_DIR" \
  --prompt-file "$PROMPT_FILE" \
  --schema "$SCHEMA_FILE" \
  --model gpt-5.3-codex-spark \
  --reasoning high \
  --label commit-summary

LATEST=$(cat "$OUTPUT_DIR/latest-result.json")
SUMMARY=$(python3 -c 'import sys, json; data=json.load(sys.stdin); print(data.get("commit_summary",""))' <<<"$LATEST")

if [[ -z "$SUMMARY" ]]; then
  echo "No commit summary generated" >&2
  rm -f "$TMP_JSON"
  exit 1
fi

rm -f "$TMP_JSON"

git add -A
git commit -m "$SUMMARY"

if [[ $DO_PUSH -eq 1 ]]; then
  git push origin main
fi

echo "Committed with message: $SUMMARY"
