#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

usage() {
  cat <<'USAGE'
Usage: prompt_groceries.sh --context <text> [options]

Options:
  --context <text>           Grocery description / shopping intent (required unless piped via stdin)
  --list-name <name>         Reminder list name (default: Groceries)
  --timezone <tz>            Timezone for parsing times (default: Asia/Shanghai)
  --default-location <text>  Default shopping location (default: Supermarket)
  --default-time <HH:MM>     Default time-of-day ("17:00")
  --default-flag <text>      Default flag/priority (default: moderate)
  --model <name>             Codex model (default: gpt-5.3-codex-spark)
  --reasoning <level>        Reasoning level (default: high)
  --output-dir <path>        Artifact directory (default: /tmp/codex-groceries)
  -h, --help                 Show this help
USAGE
}

CONTEXT=""
LIST_NAME="Groceries"
TIMEZONE="Asia/Shanghai"
DEFAULT_LOCATION="Supermarket"
DEFAULT_TIME="17:00"
DEFAULT_FLAG="moderate"
MODEL="gpt-5.3-codex-spark"
REASONING="high"
OUTPUT_DIR="/tmp/codex-groceries"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --context)
      shift
      CONTEXT="${1:?}"
      ;;
    --list-name)
      shift
      LIST_NAME="${1:?}"
      ;;
    --timezone)
      shift
      TIMEZONE="${1:?}"
      ;;
    --default-location)
      shift
      DEFAULT_LOCATION="${1:?}"
      ;;
    --default-time)
      shift
      DEFAULT_TIME="${1:?}"
      ;;
    --default-flag)
      shift
      DEFAULT_FLAG="${1:?}"
      ;;
    --model)
      shift
      MODEL="${1:?}"
      ;;
    --reasoning)
      shift
      REASONING="${1:?}"
      ;;
    --output-dir)
      shift
      OUTPUT_DIR="${1:?}"
      ;;
    -h|--help)
      usage
      exit 0
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
    usage >&2
    exit 1
  fi
  CONTEXT="$(cat)"
fi

mkdir -p "$OUTPUT_DIR"

TMP_PAYLOAD=$(mktemp)
python3 - "$TMP_PAYLOAD" "$CONTEXT" "$LIST_NAME" "$TIMEZONE" "$DEFAULT_LOCATION" "$DEFAULT_TIME" "$DEFAULT_FLAG" <<'PY'
import json
import sys
from datetime import datetime

payload_path = sys.argv[1]
context = sys.argv[2]
list_name = sys.argv[3]
tz = sys.argv[4]
default_location = sys.argv[5]
default_time = sys.argv[6]
default_flag = sys.argv[7]

payload = {
    "timestamp": datetime.now().isoformat(timespec="seconds"),
    "timezone": tz,
    "list_name": list_name,
    "context": context,
    "default_location": default_location,
    "default_time": default_time,
    "default_flag": default_flag,
}

with open(payload_path, "w", encoding="utf-8") as fh:
    json.dump(payload, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY

python3 orchestral/prompt_tools/runtime/codex-json-runner.py \
  --input-json "$TMP_PAYLOAD" \
  --output-dir "$OUTPUT_DIR" \
  --prompt-file "$REPO_DIR/orchestral/prompt_tools/reminders/grocery_prompt.md" \
  --schema "$REPO_DIR/orchestral/prompt_tools/reminders/grocery_schema.json" \
  --model "$MODEL" \
  --reasoning "$REASONING" \
  --label "groceries" \
  --skip-git-check

rm -f "$TMP_PAYLOAD"

RESULT="$OUTPUT_DIR/latest-result.json"
if [[ ! -f "$RESULT" ]]; then
  echo "groceries prompt produced no result" >&2
  exit 1
fi

cat "$RESULT"
