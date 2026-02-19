#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

ACCOUNTS="lachlan.miao.chen@gmail.com,lachen@connect.hku.hk"
TARGET_CAL="LazyingArt"
TARGET_LIST="LazyingArt"
APPLY=0
MODEL="gpt-5.3-codex-spark"
REASONING="high"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --accounts)
      shift
      ACCOUNTS="$1"
      ;;
    --calendar)
      shift
      TARGET_CAL="$1"
      ;;
    --list)
      shift
      TARGET_LIST="$1"
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

DRYRUN_OUT=$(orchestral/scripts/move_account_calendar_reminders_to_lazyingart.sh \
  --accounts "$ACCOUNTS" \
  --source-named-calendars "$ACCOUNTS" \
  --target-calendar "$TARGET_CAL" \
  --target-list "$TARGET_LIST" \
  --dry-run)

TMP=$(mktemp)
export ACCOUNTS TARGET_CAL TARGET_LIST DRYRUN_OUT APPLY
python3 - "$TMP" <<'PY'
import json, os, sys
path = sys.argv[1]
payload = {
    "accounts": os.environ["ACCOUNTS"],
    "target_calendar": os.environ["TARGET_CAL"],
    "target_list": os.environ["TARGET_LIST"],
    "apply_requested": os.environ["APPLY"] == "1",
    "dry_run_output": os.environ["DRYRUN_OUT"],
    "script_references": [
        "orchestral/scripts/move_account_calendar_reminders_to_lazyingart.sh",
        "orchestral/scripts/search_account_calendar_reminder_summary.sh"
    ]
}
with open(path, "w", encoding="utf-8") as fh:
    json.dump(payload, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY

python3 orchestral/prompt_tools/codex-json-runner.py \
  --input-json "$TMP" \
  --output-dir /tmp/codex-lazyingart-migration \
  --prompt-file orchestral/prompt_tools/lazyingart_migration_move_prompt.md \
  --schema orchestral/prompt_tools/lazyingart_migration_move_schema.json \
  --model "$MODEL" \
  --reasoning "$REASONING" \
  --label lazyingart-migration-move \
  --skip-git-check

cat /tmp/codex-lazyingart-migration/latest-result.json

if [[ "$APPLY" == "1" ]]; then
  echo
  echo "[apply] running migration"
  orchestral/scripts/move_account_calendar_reminders_to_lazyingart.sh \
    --accounts "$ACCOUNTS" \
    --source-named-calendars "$ACCOUNTS" \
    --target-calendar "$TARGET_CAL" \
    --target-list "$TARGET_LIST"
  echo
  echo "[post-check]"
  orchestral/scripts/search_account_calendar_reminder_summary.sh \
    --accounts "$ACCOUNTS" \
    --named-calendars "$ACCOUNTS" \
    --target-calendar "$TARGET_CAL" \
    --target-list "$TARGET_LIST"
fi

rm -f "$TMP"
