#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

usage() {
  cat <<'USAGE'
Usage: prompt_quick_calendar.sh --context <text> [options]

Options:
  --context <text>        Context text to process
  --calendar <name>       Default calendar name (default: AutoLife)
  --list <name>           Default reminder list (default: AutoLife)
  --output-dir <path>     Codex artifact directory (default: /tmp/codex-quick-calendar)
  --model <name>          Codex model (default: gpt-5.3-codex-spark)
  --reasoning <level>     Reasoning level (default: high)
USAGE
}

CONTEXT=""
DEFAULT_CALENDAR="AutoLife"
DEFAULT_LIST="AutoLife"
OUTPUT_DIR="/tmp/codex-quick-calendar"
MODEL="gpt-5.3-codex-spark"
REASONING="high"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --context)
      shift
      CONTEXT="$1"
      ;;
    --calendar)
      shift
      DEFAULT_CALENDAR="$1"
      ;;
    --list)
      shift
      DEFAULT_LIST="$1"
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
export CONTEXT DEFAULT_CALENDAR DEFAULT_LIST
python3 - "$TMP" <<'PY'
import json
import os
import sys

payload = {
    "context": os.environ["CONTEXT"],
    "default_calendar": os.environ["DEFAULT_CALENDAR"],
    "default_list": os.environ["DEFAULT_LIST"],
}

with open(sys.argv[1], "w", encoding="utf-8") as fh:
    json.dump(payload, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY

python3 scripts/prompt_tools/codex-json-runner.py \
  --input-json "$TMP" \
  --output-dir "$OUTPUT_DIR" \
  --prompt-file orchestral/prompt_tools/prompt_quick_calendar_prompt.md \
  --schema orchestral/prompt_tools/quick_reminder_schema.json \
  --model "$MODEL" \
  --reasoning "$REASONING" \
  --label quick-calendar \
  --skip-git-check

rm -f "$TMP"
cat "$OUTPUT_DIR/latest-result.json"
