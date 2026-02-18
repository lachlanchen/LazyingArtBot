#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

usage() {
  echo "Usage: $0 [--note <name>] [--folder <name>] [--context <text>]" >&2
  echo "       Provide --context or pipe text via stdin." >&2
  exit 1
}

NOTE="AutoLife Inbox"
FOLDER="AutoLife"
CONTEXT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --note)
      shift
      NOTE="$1"
      ;;
    --folder)
      shift
      FOLDER="$1"
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

export NOTE FOLDER CONTEXT

TMP=$(mktemp)
python3 - "$TMP" <<'PY'
import json, os, sys
path = sys.argv[1]
payload = {
    "target_note": os.environ.get("NOTE"),
    "folder": os.environ.get("FOLDER"),
    "context": os.environ.get("CONTEXT")
}
with open(path, "w", encoding="utf-8") as fh:
    json.dump(payload, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY

RESULT=$(scripts/prompt_tools/run_auto_ops.sh --prompt scripts/prompt_tools/notes_prompt.md --label notes --payload "$TMP")
rm -f "$TMP"

echo "$RESULT"
