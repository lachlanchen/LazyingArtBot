#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

usage() {
  echo "Usage: $0 [--scope <daily|weekly|monthly>] [--context <text>]" >&2
  echo "       Provide --context or pipe text via stdin." >&2
  exit 1
}

SCOPE="daily"
CONTEXT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope)
      shift
      SCOPE="$1"
      ;;
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

export SCOPE CONTEXT

TMP=$(mktemp)
python3 - "$TMP" <<'PY'
import json, os, sys
path = sys.argv[1]
payload = {
    "scope": os.environ.get("SCOPE"),
    "context": os.environ.get("CONTEXT")
}
with open(path, "w", encoding="utf-8") as fh:
    json.dump(payload, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY

RESULT=$(scripts/prompt_tools/run_auto_ops.sh --prompt scripts/prompt_tools/making_plan_prompt.md --label plan --payload "$TMP")
rm -f "$TMP"

echo "$RESULT"
