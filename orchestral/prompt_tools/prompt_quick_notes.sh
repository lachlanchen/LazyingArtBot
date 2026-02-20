#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

usage() {
  cat <<'USAGE'
Usage: prompt_quick_notes.sh --context <text> [options]

Options:
  --context <text>        Note context text to process
  --note <name>           Target note title (default: Quick Notes)
  --folder <name>         Notes folder (default: 🌱 Life)
  --output-dir <path>     Codex artifact directory (default: /tmp/codex-quick-notes)
  --model <name>          Codex model (default: gpt-5.3-codex-spark)
  --reasoning <level>     Reasoning level (default: high)
USAGE
}

CONTEXT=""
TARGET_NOTE="Quick Notes"
FOLDER="🌱 Life"
OUTPUT_DIR="/tmp/codex-quick-notes"
MODEL="gpt-5.3-codex-spark"
REASONING="high"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --context)
      shift
      CONTEXT="$1"
      ;;
    --note)
      shift
      TARGET_NOTE="$1"
      ;;
    --folder)
      shift
      FOLDER="$1"
      ;;
    --output-dir)
      shift
      OUTPUT_DIR="$1"
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
      exit 1
      ;;
  esac
  shift
done

if [[ -z "$CONTEXT" ]]; then
  if [[ -t 0 ]]; then
    usage
    exit 1
  fi
  CONTEXT="$(cat)"
fi

TMP=$(mktemp)
export CONTEXT TARGET_NOTE FOLDER
python3 - "$TMP" <<'PY'
import json
import os
import sys

payload = {
    "context": os.environ["CONTEXT"],
    "target_note": os.environ["TARGET_NOTE"],
    "folder": os.environ["FOLDER"],
}

with open(sys.argv[1], "w", encoding="utf-8") as fh:
    json.dump(payload, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY

python3 scripts/prompt_tools/codex-json-runner.py \
  --input-json "$TMP" \
  --output-dir "$OUTPUT_DIR" \
  --prompt-file orchestral/prompt_tools/prompt_quick_notes_prompt.md \
  --schema orchestral/prompt_tools/quick_reminder_schema.json \
  --model "$MODEL" \
  --reasoning "$REASONING" \
  --label quick-notes \
  --skip-git-check

rm -f "$TMP"
cat "$OUTPUT_DIR/latest-result.json"
