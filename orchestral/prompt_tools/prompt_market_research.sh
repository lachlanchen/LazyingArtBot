#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

usage() {
  echo "Usage: $0 [--company <name>] [--focus <topic>] [--context <text>]" >&2
  echo "       Provide --context or pipe text via stdin." >&2
  exit 1
}

COMPANY="Lazying.art"
FOCUS="general"
CONTEXT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --company)
      shift
      COMPANY="$1"
      ;;
    --focus)
      shift
      FOCUS="$1"
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

export COMPANY FOCUS CONTEXT

TMP=$(mktemp)
python3 - "$TMP" <<'PY'
import json, os, sys
path = sys.argv[1]
payload = {
    "company": os.environ.get("COMPANY"),
    "focus": os.environ.get("FOCUS"),
    "context": os.environ.get("CONTEXT")
}
with open(path, "w", encoding="utf-8") as fh:
    json.dump(payload, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY

RESULT=$(scripts/prompt_tools/run_auto_ops.sh --prompt scripts/prompt_tools/market_research_prompt.md --label market-research --payload "$TMP")
rm -f "$TMP"

echo "$RESULT"
