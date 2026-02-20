#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

usage() {
  cat <<'USAGE'
Usage: prompt_quick_reminder.sh --context <text> [options]

Options:
  --context <text>         Reminder context text to process (required unless piped via stdin)
  --list-name <name>       Reminder list name (default: AutoLife)
  --note <name>            Target note title (default: Quick Notes)
  --folder <name>          Notes folder (default: 🌱 Life)
  --calendar <name>        Calendar name (default: AutoLife)
  --timezone <tz>          Timezone for date parsing (default: Asia/Shanghai)
  --output-dir <path>      Output directory for Codex artifacts
  --model <name>           Codex model (default: gpt-5.3-codex-spark)
  --reasoning <level>      Reasoning level (default: high)
  --state-json <path>      Reminder state file for history
  --report-json <path>     Report path (default: <output-dir>/quick_reminder_report.json)
  -h, --help               Show this help
USAGE
}

CONTEXT=""
LIST_NAME="AutoLife"
TARGET_NOTE="Quick Notes"
NOTE_FOLDER="🌱 Life"
CALENDAR_NAME="AutoLife"
TIMEZONE="Asia/Shanghai"
OUTPUT_DIR="/tmp/codex-quick-reminder"
MODEL="gpt-5.3-codex-spark"
REASONING="high"
STATE_JSON="$HOME/.openclaw/workspace/AutoLife/MetaNotes/quick_reminder_state.json"
REPORT_JSON=""

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
    --note)
      shift
      TARGET_NOTE="${1:?}"
      ;;
    --folder)
      shift
      NOTE_FOLDER="${1:?}"
      ;;
    --calendar)
      shift
      CALENDAR_NAME="${1:?}"
      ;;
    --timezone)
      shift
      TIMEZONE="${1:?}"
      ;;
    --output-dir)
      shift
      OUTPUT_DIR="${1:?}"
      ;;
    --model)
      shift
      MODEL="${1:?}"
      ;;
    --reasoning)
      shift
      REASONING="${1:?}"
      ;;
    --state-json)
      shift
      STATE_JSON="${1:?}"
      ;;
    --report-json)
      shift
      REPORT_JSON="${1:?}"
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

mkdir -p "$OUTPUT_DIR" "$(dirname "$STATE_JSON")"

if [[ -z "$REPORT_JSON" ]]; then
  REPORT_JSON="$OUTPUT_DIR/quick_reminder_report.json"
fi

TMP_PAYLOAD="$(mktemp)"
python3 - "$TMP_PAYLOAD" "$CONTEXT" "$LIST_NAME" "$TIMEZONE" "$TARGET_NOTE" "$NOTE_FOLDER" "$CALENDAR_NAME" "$STATE_JSON" <<'PY'
import json
import os
import sys
from datetime import datetime
from zoneinfo import ZoneInfo

payload_path = sys.argv[1]
context = sys.argv[2]
default_list = sys.argv[3]
tz_name = sys.argv[4]
default_note = sys.argv[5]
default_folder = sys.argv[6]
default_calendar = sys.argv[7]
state_path = sys.argv[8]
tz = ZoneInfo(tz_name)

previous = ""
if os.path.exists(state_path):
    with open(state_path, "r", encoding="utf-8") as fh:
        previous = fh.read()

payload = {
    "run_local_iso": datetime.now(tz).isoformat(timespec="seconds"),
    "timezone": tz_name,
    "reminder_list": default_list,
    "target_note": default_note,
    "folder": default_folder,
    "default_calendar": default_calendar,
    "context": context,
    "previous_state_json": previous,
}

with open(payload_path, "w", encoding="utf-8") as fh:
    json.dump(payload, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY

python3 scripts/prompt_tools/codex-json-runner.py \
  --input-json "$TMP_PAYLOAD" \
  --output-dir "$OUTPUT_DIR" \
  --prompt-file "$REPO_DIR/orchestral/prompt_tools/quick_reminder_prompt.md" \
  --schema "$REPO_DIR/orchestral/prompt_tools/quick_reminder_schema.json" \
  --model "$MODEL" \
  --reasoning "$REASONING" \
  --label "quick-reminder" \
  --skip-git-check \
  >/tmp/prompt_quick_reminder_run.log \
  2>/tmp/prompt_quick_reminder_run.err
rm -f "$TMP_PAYLOAD"

PLAN_JSON="$OUTPUT_DIR/latest-result.json"
if [[ ! -f "$PLAN_JSON" ]]; then
  echo "No result file from Codex prompt" >&2
  exit 1
fi

python3 - "$PLAN_JSON" "$STATE_JSON" "$REPORT_JSON" "$LIST_NAME" "$TARGET_NOTE" "$NOTE_FOLDER" "$CALENDAR_NAME" <<'PY'
import json
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Any

PLAN_JSON = Path(sys.argv[1]).expanduser()
STATE_JSON = Path(sys.argv[2]).expanduser()
REPORT_JSON = Path(sys.argv[3]).expanduser()
DEFAULT_LIST = sys.argv[4]
DEFAULT_NOTE = sys.argv[5]
DEFAULT_FOLDER = sys.argv[6]
DEFAULT_CALENDAR = sys.argv[7]
CREATE_NOTE_SCRIPT = str(Path.home() / ".openclaw/workspace/automation/create_note.applescript")
CREATE_CALENDAR_SCRIPT = str(Path.home() / ".openclaw/workspace/automation/create_calendar_event.applescript")
CREATE_REMINDER_SCRIPT = str(Path.home() / ".openclaw/workspace/automation/create_reminder.applescript")


def run_osascript_with_args(script: str, *args: str) -> str:
    proc = subprocess.run(
        ["osascript", "-e", script, "--", *args],
        text=True,
        capture_output=True,
    )
    if proc.returncode != 0:
        raise RuntimeError((proc.stderr or proc.stdout or "osascript failed").strip())
    return proc.stdout.strip()


def parse_existing(list_name: str) -> set[tuple[str, str]]:
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
      set doneText to "0"
      set dueText to ""
      try
        if completed of r then set doneText to "1"
      end try
      try
        if due date of r is not missing value then
          set dueText to my isoStringFromDate(due date of r)
        end if
      end try
      set outText to outText & (name of r as text) & fs & doneText & fs & dueText & rs
    end repeat
  end tell
  return outText
end run
'''
    try:
        out = run_osascript_with_args(script, list_name)
    except Exception:
        return set()

    fs = chr(31)
    rs = chr(30)
    keys: set[tuple[str, str]] = set()
    for rec in out.split(rs):
        rec = rec.strip()
        if not rec:
            continue
        parts = rec.split(fs)
        if len(parts) < 3:
            continue
        title = parts[0].strip().lower()
        done = parts[1] == "1"
        due_iso = parts[2].strip()
        if done or not due_iso:
            continue
        keys.add((title, due_iso[:16]))
    return keys


def create_reminder(title: str, due_iso: str, notes: str, list_name: str, minutes: int) -> str:
    proc = subprocess.run(
        ["/usr/bin/osascript", CREATE_REMINDER_SCRIPT, title, due_iso, notes, list_name, str(minutes)],
        text=True,
        capture_output=True,
    )
    if proc.returncode != 0:
        raise RuntimeError((proc.stderr or proc.stdout or "osascript failed").strip())
    return proc.stdout.strip()


def create_note(target_note: str, html_body: str, folder: str) -> str:
    proc = subprocess.run(
        ["/usr/bin/osascript", CREATE_NOTE_SCRIPT, target_note, html_body, folder, "replace"],
        text=True,
        capture_output=True,
    )
    if proc.returncode != 0:
        raise RuntimeError((proc.stderr or proc.stdout or "osascript failed").strip())
    return proc.stdout.strip()


def create_calendar_event(title: str, start_iso: str, end_iso: str, notes_text: str, calendar: str) -> str:
    proc = subprocess.run(
        ["/usr/bin/osascript", CREATE_CALENDAR_SCRIPT, title, start_iso, end_iso, notes_text, calendar, "0"],
        text=True,
        capture_output=True,
    )
    if proc.returncode != 0:
        raise RuntimeError((proc.stderr or proc.stdout or "osascript failed").strip())
    return proc.stdout.strip()


def to_str(value: Any, default: str = "") -> str:
    return value.strip() if isinstance(value, str) else default


def is_iso_text(value: object) -> bool:
    if not isinstance(value, str):
        return False
    try:
        datetime.fromisoformat(value.replace("Z", "+00:00"))
        return True
    except Exception:
        return False


def parse_notes(raw: object) -> list[dict[str, Any]]:
    if not isinstance(raw, list):
        return []
    out: list[dict[str, Any]] = []
    for item in raw:
        if not isinstance(item, dict):
            continue
        target_note = to_str(item.get("target_note"), DEFAULT_NOTE)
        folder = to_str(item.get("folder"), DEFAULT_FOLDER)
        html_body = item.get("html_body")
        if not isinstance(html_body, str):
            html_body = ""
        if not target_note:
            target_note = DEFAULT_NOTE
        if not folder:
            folder = DEFAULT_FOLDER
        out.append({"target_note": target_note, "folder": folder, "html_body": html_body})
    return out


def parse_calendar_events(raw: object) -> list[dict[str, Any]]:
    if not isinstance(raw, list):
        return []
    out: list[dict[str, Any]] = []
    for item in raw:
        if not isinstance(item, dict):
            continue
        title = to_str(item.get("title"))
        start_iso = to_str(item.get("start_iso"))
        end_iso = to_str(item.get("end_iso"))
        if not title or not is_iso_text(start_iso) or not is_iso_text(end_iso):
            continue
        try:
            if datetime.fromisoformat(start_iso.replace("Z", "+00:00")) >= datetime.fromisoformat(end_iso.replace("Z", "+00:00")):
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


def parse_reminders(raw: object) -> list[dict[str, Any]]:
    if not isinstance(raw, list):
        return []
    out: list[dict[str, Any]] = []
    for item in raw:
        if not isinstance(item, dict):
            continue
        title = to_str(item.get("title"), "Reminder")
        due_iso = to_str(item.get("due_iso"))
        if not title or not is_iso_text(due_iso):
            continue
        out.append(
            {
                "title": title,
                "due_iso": due_iso,
                "list": to_str(item.get("list"), DEFAULT_LIST) or DEFAULT_LIST,
                "notes": to_str(item.get("notes")),
            }
        )
    return out


plan = json.loads(PLAN_JSON.read_text(encoding="utf-8"))
summary = to_str(plan.get("summary"), "Quick reminder plan")
note_items = parse_notes(plan.get("notes", []))
calendar_items = parse_calendar_events(plan.get("calendar_events", []))
reminder_items = parse_reminders(plan.get("reminders", []))

existing_reminders = parse_existing(DEFAULT_LIST)
seen_reminder_keys: set[tuple[str, str]] = set()
seen_note_keys: set[tuple[str, str]] = set()
seen_event_keys: set[tuple[str, str, str]] = set()

results: list[dict[str, Any]] = []
created_notes = 0
created_events = 0
created_reminders = 0

for item in note_items:
    key = (item["target_note"].strip().lower(), item["folder"].strip().lower(), item["html_body"].strip()[:120])
    if key in seen_note_keys:
        results.append(
            {
                "status": "skipped_duplicate",
                "action": "note",
                "target_note": item["target_note"],
                "folder": item["folder"],
            }
        )
        continue
    seen_note_keys.add(key)
    try:
        note_id = create_note(item["target_note"], item["html_body"], item["folder"])
        created_notes += 1
        results.append(
            {
                "status": "created",
                "action": "note",
                "target_note": item["target_note"],
                "folder": item["folder"],
                "note_id": note_id,
            }
        )
    except Exception as exc:
        results.append(
            {
                "status": "failed",
                "action": "note",
                "target_note": item["target_note"],
                "folder": item["folder"],
                "error": str(exc),
            }
        )

for item in calendar_items:
    key = (item["title"].strip().lower(), item["start_iso"], item["end_iso"])
    if key in seen_event_keys:
        results.append(
            {
                "status": "skipped_duplicate",
                "action": "calendar_event",
                "title": item["title"],
                "start_iso": item["start_iso"],
                "end_iso": item["end_iso"],
            }
        )
        continue
    seen_event_keys.add(key)
    try:
        event_uid = create_calendar_event(
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
                "event_uid": event_uid,
            }
        )
    except Exception as exc:
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

for item in reminder_items:
    key = (item["title"].strip().lower(), item["due_iso"][:16], item["list"])
    if (item["title"].strip().lower(), item["due_iso"][:16]) in existing_reminders or key in seen_reminder_keys:
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
        reminder_id = create_reminder(item["title"], item["due_iso"], item["notes"], item["list"], 20)
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
    except Exception as exc:
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
    "created_notes": created_notes,
    "created_events": created_events,
    "created_reminders": created_reminders,
    "results": results,
}

STATE_JSON.parent.mkdir(parents=True, exist_ok=True)
STATE_JSON.write_text(
    json.dumps(
        {
            "updated_at": datetime.now().isoformat(timespec="seconds"),
            "summary": summary,
            "results": results,
        },
        ensure_ascii=False,
        indent=2,
    )
    + "\n",
    encoding="utf-8",
)
REPORT_JSON.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(json.dumps(report, ensure_ascii=False))
PY
