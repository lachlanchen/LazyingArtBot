#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

usage() {
  echo "Usage: $0 [--context <text>] [--calendar <name>] [--list <name>]" >&2
  echo "       Provide --context or pipe text via stdin." >&2
  exit 1
}

CONTEXT=""
DEFAULT_CAL="AutoLife"
DEFAULT_LIST="AutoLife"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --context)
      shift
      CONTEXT="$1"
      ;;
    --calendar)
      shift
      DEFAULT_CAL="$1"
      ;;
    --list)
      shift
      DEFAULT_LIST="$1"
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

export CONTEXT DEFAULT_CAL DEFAULT_LIST

TMP=$(mktemp)
python3 - "$TMP" <<'PY'
import json, os, sys
path = sys.argv[1]
payload = {
    "context": os.environ.get("CONTEXT"),
    "default_calendar": os.environ.get("DEFAULT_CAL"),
    "default_list": os.environ.get("DEFAULT_LIST")
}
with open(path, "w", encoding="utf-8") as fh:
    json.dump(payload, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY

RESULT=$(scripts/prompt_tools/run_auto_ops.sh --prompt scripts/prompt_tools/calendar_prompt.md --label calendar --payload "$TMP")
rm -f "$TMP"

echo "$RESULT"
