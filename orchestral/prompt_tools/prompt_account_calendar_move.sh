#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

SOURCE_ACCOUNT="lachen@connect.hku.hk"
SOURCE_CALENDAR="Calendar"
TARGET_CALENDAR="LazyingArt"
KEEP_SOURCE=0
APPLY=0
MODEL="gpt-5.3-codex-spark"
REASONING="high"

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
    --keep-source)
      KEEP_SOURCE=1
      ;;
    --apply)
      APPLY=1
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

DRYRUN_CMD=(orchestral/scripts/move_events_from_account_calendar_to_lazyingart.sh
  --source-account "$SOURCE_ACCOUNT"
  --source-calendar "$SOURCE_CALENDAR"
  --target-calendar "$TARGET_CALENDAR"
  --dry-run)

if [[ "$KEEP_SOURCE" == "1" ]]; then
  DRYRUN_CMD+=(--keep-source)
fi

DRYRUN_OUT="$("${DRYRUN_CMD[@]}")"

TMP="$(mktemp)"
export SOURCE_ACCOUNT SOURCE_CALENDAR TARGET_CALENDAR KEEP_SOURCE APPLY DRYRUN_OUT
python3 - "$TMP" <<'PY'
import json, os, sys
path = sys.argv[1]
payload = {
    "source_account": os.environ["SOURCE_ACCOUNT"],
    "source_calendar": os.environ["SOURCE_CALENDAR"],
    "target_calendar": os.environ["TARGET_CALENDAR"],
    "keep_source": os.environ["KEEP_SOURCE"] == "1",
    "apply_requested": os.environ["APPLY"] == "1",
    "dry_run_output": os.environ["DRYRUN_OUT"],
    "script_references": [
        "orchestral/scripts/move_events_from_account_calendar_to_lazyingart.sh",
        "orchestral/scripts/search_account_calendar_events.sh"
    ]
}
with open(path, "w", encoding="utf-8") as fh:
    json.dump(payload, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY

python3 orchestral/prompt_tools/codex-json-runner.py \
  --input-json "$TMP" \
  --output-dir /tmp/codex-account-calendar-move \
  --prompt-file orchestral/prompt_tools/account_calendar_move_prompt.md \
  --schema orchestral/prompt_tools/account_calendar_move_schema.json \
  --model "$MODEL" \
  --reasoning "$REASONING" \
  --label account-calendar-move \
  --skip-git-check

cat /tmp/codex-account-calendar-move/latest-result.json

if [[ "$APPLY" == "1" ]]; then
  APPLY_CMD=(orchestral/scripts/move_events_from_account_calendar_to_lazyingart.sh
    --source-account "$SOURCE_ACCOUNT"
    --source-calendar "$SOURCE_CALENDAR"
    --target-calendar "$TARGET_CALENDAR")
  if [[ "$KEEP_SOURCE" == "1" ]]; then
    APPLY_CMD+=(--keep-source)
  fi
  echo
  echo "[apply] running account calendar move"
  "${APPLY_CMD[@]}"
  echo
  echo "[post-check]"
  orchestral/scripts/search_account_calendar_events.sh \
    --source-account "$SOURCE_ACCOUNT" \
    --source-calendar "$SOURCE_CALENDAR" \
    --target-calendar "$TARGET_CALENDAR" \
    --keywords "anniversary"
fi

rm -f "$TMP"
