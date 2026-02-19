#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

SOURCE_ACCOUNT="lachen@connect.hku.hk"
SOURCE_CALENDAR="Calendar"
TARGET_CALENDAR="LazyingArt"
KEYWORDS="anniversary"
MODEL="gpt-5.1-codex-mini"
REASONING="medium"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-account)
      shift
      SOURCE_ACCOUNT="$1"
      ;;
    --source-calendar)
      shift
      SOURCE_CALENDAR="$1"
      ;;
    --target-calendar)
      shift
      TARGET_CALENDAR="$1"
      ;;
    --keywords)
      shift
      KEYWORDS="$1"
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
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
  shift
done

SEARCH_OUT="$(orchestral/scripts/search_account_calendar_events.sh \
  --source-account "$SOURCE_ACCOUNT" \
  --source-calendar "$SOURCE_CALENDAR" \
  --target-calendar "$TARGET_CALENDAR" \
  --keywords "$KEYWORDS")"

SUMMARY_OUT="$(orchestral/scripts/search_account_calendar_reminder_summary.sh)"

TMP="$(mktemp)"
export SOURCE_ACCOUNT SOURCE_CALENDAR TARGET_CALENDAR KEYWORDS SEARCH_OUT SUMMARY_OUT
python3 - "$TMP" <<'PY'
import json, os, sys
path = sys.argv[1]
payload = {
    "source_account": os.environ["SOURCE_ACCOUNT"],
    "source_calendar": os.environ["SOURCE_CALENDAR"],
    "target_calendar": os.environ["TARGET_CALENDAR"],
    "keywords": os.environ["KEYWORDS"],
    "search_output": os.environ["SEARCH_OUT"],
    "summary_output": os.environ["SUMMARY_OUT"],
    "script_references": [
        "orchestral/scripts/search_account_calendar_events.sh",
        "orchestral/scripts/search_account_calendar_reminder_summary.sh"
    ]
}
with open(path, "w", encoding="utf-8") as fh:
    json.dump(payload, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY

python3 orchestral/prompt_tools/codex-json-runner.py \
  --input-json "$TMP" \
  --output-dir /tmp/codex-account-calendar-move \
  --prompt-file orchestral/prompt_tools/account_calendar_search_prompt.md \
  --schema orchestral/prompt_tools/account_calendar_search_schema.json \
  --model "$MODEL" \
  --reasoning "$REASONING" \
  --label account-calendar-search \
  --skip-git-check

cat /tmp/codex-account-calendar-move/latest-result.json
rm -f "$TMP"
