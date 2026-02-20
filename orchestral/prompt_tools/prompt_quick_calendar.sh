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

RESULT_JSON="$OUTPUT_DIR/latest-result.json"
CREATE_CALENDAR_SCRIPT="$HOME/.openclaw/workspace/automation/create_calendar_event.applescript"
CREATE_REMINDER_SCRIPT="$HOME/.openclaw/workspace/automation/create_reminder.applescript"

if [[ ! -f "$RESULT_JSON" ]]; then
  echo "No result file from Codex prompt" >&2
  exit 1
fi

python3 "$RESULT_JSON" "$CREATE_CALENDAR_SCRIPT" "$CREATE_REMINDER_SCRIPT" "$DEFAULT_CALENDAR" "$DEFAULT_LIST" <<'PY'
import json
import subprocess
import sys
from datetime import datetime
from pathlib import Path

PLAN_JSON = Path(sys.argv[1]).expanduser()
CREATE_CALENDAR_SCRIPT = Path(sys.argv[2]).expanduser()
CREATE_REMINDER_SCRIPT = Path(sys.argv[3]).expanduser()
DEFAULT_CALENDAR = sys.argv[4]
DEFAULT_LIST = sys.argv[5]


def run_osascript(script_path: str, *args: str) -> str:
    proc = subprocess.run(
        ["osascript", str(script_path), *args],
        text=True,
        capture_output=True,
        timeout=60,
    )
    if proc.returncode != 0:
        raise RuntimeError((proc.stderr or proc.stdout or "osascript failed").strip())
    return proc.stdout.strip()


def to_str(value: object, default: str = "") -> str:
    return str(value).strip() if isinstance(value, str) else default


def parse_existing_reminders(list_name: str) -> set[tuple[str, str]]:
    if not list_name:
        return set()
    script = r'''
use framework "Foundation"
use scripting additions

property isoFormatter : missing value

on ensureISOFormatter()
	if isoFormatter is missing value then
		set isoFormatter to current application's NSISO8601DateFormatter's alloc()'s init()
		isoFormatter's setFormatOptions_(current application's NSISO8601DateFormatWithInternetDateTime)
	end if
end ensureISOFormatter

on isoStringFromDate(theDate)
	my ensureISOFormatter()
	return (isoFormatter's stringFromDate_(theDate)) as text
end isoStringFromDate

on run argv
	set listName to item 1 of argv
	set fs to character id 31
	set rs to character id 30
	set outText to ""
	tell application "Reminders"
		if not (exists list listName) then return ""
		set targetList to list listName
		repeat with r in reminders of targetList
			set rid to ""
			set rname to ""
			set doneText to "0"
			set dueText to ""
			try
				set rid to id of r as text
			on error
				set rid to ""
			end try
			try
				set rname to name of r as text
			on error
				set rname to ""
			end try
			try
				if completed of r then set doneText to "1"
			on error
				set doneText to "0"
			end try
			try
				if due date of r is not missing value then
					set dueText to my isoStringFromDate(due date of r)
				else
					set dueText to ""
				end if
			end try
			set outText to outText & rid & fs & rname & fs & doneText & fs & dueText & rs
		end repeat
	end tell
	return outText
end run
'''
    try:
        out = run_osascript(script, list_name)
    except Exception:
        return set()

    fs = chr(31)
    rs = chr(30)
    items: set[tuple[str, str]] = set()

    for rec in out.split(rs):
        rec = rec.strip()
        if not rec:
            continue
        parts = rec.split(fs)
        if len(parts) < 4:
            continue
        title = parts[1].strip()
        done = parts[2] == "1"
        due_iso = parts[3].strip()
        if not done and due_iso:
            items.add((title.lower(), due_iso[:16]))

    return items


def is_iso_text(value: object) -> bool:
    if not isinstance(value, str):
        return False
    text = value.strip()
    try:
        datetime.fromisoformat(text.replace("Z", "+00:00"))
        return True
    except Exception:
        return False


def parse_calendar_events(raw: list[object]) -> list[dict[str, object]]:
    if not isinstance(raw, list):
        return []
    out: list[dict[str, object]] = []
    for item in raw:
        if not isinstance(item, dict):
            continue
        title = to_str(item.get("title"))
        start_iso = to_str(item.get("start_iso"))
        end_iso = to_str(item.get("end_iso"))
        if not title or not is_iso_text(start_iso) or not is_iso_text(end_iso):
            continue
        try:
            if datetime.fromisoformat(start_iso.replace("Z", "+00:00")) >= datetime.fromisoformat(
                end_iso.replace("Z", "+00:00")
            ):
                continue
        except Exception:
            continue
        out.append(
            {
                "title": title,
                "start_iso": start_iso,
                "end_iso": end_iso,
                "calendar": to_str(item.get("calendar"), DEFAULT_CALENDAR) or DEFAULT_CALENDAR,
                "notes": to_str(item.get("notes")),
            }
        )
    return out


def parse_reminders(raw: list[object]) -> list[dict[str, object]]:
    if not isinstance(raw, list):
        return []
    out: list[dict[str, object]] = []
    for item in raw:
        if not isinstance(item, dict):
            continue
        title = to_str(item.get("title"))
        due_iso = to_str(item.get("due_iso"))
        if not title or not is_iso_text(due_iso):
            continue
        out.append(
            {
                "title": title,
                "due_iso": due_iso,
                "list": to_str(item.get("list"), DEFAULT_LIST) or DEFAULT_LIST,
                "notes": to_str(item.get("notes")),
                "reminderMinutes": int(item.get("reminderMinutes", 20)) if isinstance(item.get("reminderMinutes", 20), int) else 20,
            }
        )
    return out


plan = json.loads(PLAN_JSON.read_text(encoding="utf-8"))
summary = to_str(plan.get("summary"), "Quick calendar/reminder capture")
calendar_events = parse_calendar_events(plan.get("calendar_events", []))
reminders = parse_reminders(plan.get("reminders", []))

existing_reminders = parse_existing_reminders(DEFAULT_LIST)
results: list[dict[str, object]] = []
created_events = 0
created_reminders = 0
seen_reminder_keys: set[tuple[str, str]] = set()
seen_event_keys: set[tuple[str, str, str]] = set()

for item in calendar_events:
    key = (item["title"].lower(), item["start_iso"], item["end_iso"])
    if key in seen_event_keys:
        continue
    seen_event_keys.add(key)
    try:
        uid = run_osascript(
            str(CREATE_CALENDAR_SCRIPT),
            item["title"],
            item["start_iso"],
            item["end_iso"],
            item["notes"],
            item["calendar"],
        )
        created_events += 1
        results.append(
            {
                "status": "created",
                "action": "calendar_event",
                "title": item["title"],
                "start_iso": item["start_iso"],
                "end_iso": item["end_iso"],
                "calendar": item["calendar"],
                "event_uid": uid,
            }
        )
    except Exception as exc:  # noqa: BLE001
        results.append(
            {
                "status": "failed",
                "action": "calendar_event",
                "title": item["title"],
                "start_iso": item["start_iso"],
                "end_iso": item["end_iso"],
                "error": str(exc),
            }
        )

for item in reminders:
    key = (item["title"].lower(), item["due_iso"][:16], item.get("list", DEFAULT_LIST))
    if key in seen_reminder_keys or (item["title"].lower(), item["due_iso"][:16]) in existing_reminders:
        results.append(
            {
                "status": "skipped_duplicate",
                "action": "reminder",
                "title": item["title"],
                "due_iso": item["due_iso"],
                "list": item["list"],
            }
        )
        continue
    seen_reminder_keys.add(key)

    try:
        reminder_id = run_osascript(
            str(CREATE_REMINDER_SCRIPT),
            item["title"],
            item["due_iso"],
            item["notes"],
            item["list"],
            str(int(item.get("reminderMinutes", 20))),
        )
        created_reminders += 1
        results.append(
            {
                "status": "created",
                "action": "reminder",
                "title": item["title"],
                "due_iso": item["due_iso"],
                "list": item["list"],
                "reminder_id": reminder_id,
            }
        )
    except Exception as exc:  # noqa: BLE001
        results.append(
            {
                "status": "failed",
                "action": "reminder",
                "title": item["title"],
                "due_iso": item["due_iso"],
                "list": item["list"],
                "error": str(exc),
            }
        )

report = {
    "summary": summary,
    "created_events": created_events,
    "created_reminders": created_reminders,
    "results": results,
}

print(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
PY

rm -f "$TMP"
