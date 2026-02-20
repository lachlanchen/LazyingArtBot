#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

usage() {
  cat <<'USAGE'
Usage: prompt_daily_rituals_ping.sh [options]

Run one Codex call to generate tomorrow's daily-ritual reminder and apply it.

Options:
  --list-name <name>        Reminder list name (default: AutoLife)
  --timezone <tz>           Timezone for due time and timestamp formatting (default: Asia/Shanghai)
  --model <name>            Codex model (default: gpt-5.3-codex-spark)
  --reasoning <level>       Codex reasoning level (default: high)
  --output-dir <path>       Codex artifact output directory (default: /tmp/codex-daily-rituals-ping)
  --state-json <path>       Reminder state file for context and history (default: ~/.openclaw/workspace/AutoLife/MetaNotes/daily_ritual_state.json)
  --report-json <path>      Optional final JSON report path (default: <output-dir>/daily_ritual_reminder_report.json)
  -h, --help               Show this help.
USAGE
}

LIST_NAME="AutoLife"
TIMEZONE="Asia/Shanghai"
MODEL="gpt-5.3-codex-spark"
REASONING="high"
OUTPUT_DIR="/tmp/codex-daily-rituals-ping"
STATE_JSON="$HOME/.openclaw/workspace/AutoLife/MetaNotes/daily_ritual_state.json"
REPORT_JSON=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --list-name)
      shift
      LIST_NAME="${1:?}"
      ;;
    --timezone)
      shift
      TIMEZONE="${1:?}"
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

if [[ -z "$REPORT_JSON" ]]; then
  REPORT_JSON="$OUTPUT_DIR/daily_ritual_reminder_report.json"
fi

mkdir -p "$OUTPUT_DIR" "$(dirname "$STATE_JSON")"

TMP_PAYLOAD="$(mktemp)"
python3 - "$TMP_PAYLOAD" "$STATE_JSON" "$LIST_NAME" "$TIMEZONE" <<'PY'
import json
from datetime import datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo
import sys

payload_path = Path(sys.argv[1]).expanduser()
state_path = Path(sys.argv[2]).expanduser()
list_name = sys.argv[3]
tz_name = sys.argv[4]
tz = ZoneInfo(tz_name)

now = datetime.now(tz)
tomorrow = now.date() + timedelta(days=1)
default_due = datetime.combine(tomorrow, datetime.min.time(), tzinfo=tz).replace(hour=7, minute=30, second=0, microsecond=0)
previous_state = state_path.read_text(encoding="utf-8") if state_path.exists() else ""

payload = {
    "run_local_iso": now.isoformat(timespec="seconds"),
    "timezone": tz_name,
    "reminder_list": list_name,
    "tomorrow_label": tomorrow.isoformat(),
    "default_due_iso": default_due.isoformat(timespec="seconds"),
    "ritual_items": ["冥想", "健身", "吉他", "外语", "阅读", "写作"],
    "previous_state_json": previous_state,
}

payload_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY

scripts/prompt_tools/run_auto_ops.sh \
  --prompt "$REPO_DIR/orchestral/prompt_tools/daily_rituals_ping_prompt.md" \
  --label "daily-ritual-ping" \
  --payload "$TMP_PAYLOAD" \
  --output-dir "$OUTPUT_DIR" \
  --model "$MODEL" \
  --reasoning "$REASONING"
rm -f "$TMP_PAYLOAD"

PLAN_JSON="$OUTPUT_DIR/latest-result.json"
if [[ ! -f "$PLAN_JSON" ]]; then
  echo "No plan result found from Codex tool" >&2
  exit 1
fi

python3 - "$PLAN_JSON" "$STATE_JSON" "$REPORT_JSON" "$LIST_NAME" <<'PY'
import json
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Any
import sys

PLAN_JSON = Path(sys.argv[1]).expanduser()
STATE_JSON = Path(sys.argv[2]).expanduser()
REPORT_JSON = Path(sys.argv[3]).expanduser()
LIST_NAME = sys.argv[4]
CREATE_SCRIPT = Path.home() / ".openclaw" / "workspace" / "automation" / "create_reminder.applescript"


def run_osascript(script: str, *args: str) -> str:
  proc = subprocess.run(["osascript", "-", *args], input=script, text=True, capture_output=True)
  if proc.returncode != 0:
    raise RuntimeError((proc.stderr or proc.stdout or "osascript failed").strip())
  return proc.stdout.strip()


def fetch_reminders(list_name: str) -> list[dict[str, str]]:
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
      end try
      try
        set rname to my oneLine(name of r)
      end try
      try
        if completed of r then set doneText to "1"
      end try
      try
        set dueValue to due date of r
        if dueValue is not missing value then
          set dueText to my isoStringFromDate(dueValue)
        end if
      end try
      set outText to outText & rid & fs & rname & fs & doneText & fs & dueText & rs
    end repeat
  end tell
  return outText
end run

on oneLine(rawText)
  if rawText is missing value then return ""
  set safeText to rawText as text
  set cleanText to do shell script "printf '%s' " & quoted form of safeText & " | tr '\\r\\n' '  '"
  return cleanText
end oneLine
'''
  out = run_osascript(script, list_name)
  fs = chr(31)
  rs = chr(30)
  reminders = []
  for rec in out.split(rs):
    rec = rec.strip()
    if not rec:
      continue
    parts = rec.split(fs)
    if len(parts) < 4:
      continue
    reminders.append({
      "id": parts[0],
      "name": parts[1],
      "completed": parts[2] == "1",
      "due_iso": parts[3],
    })
  return reminders


def complete_reminder(list_name: str, reminder_id: str) -> str:
  script = r'''
on run argv
  set listName to item 1 of argv
  set rid to item 2 of argv
  tell application "Reminders"
    if not (exists list listName) then return "list_missing"
    set targetList to list listName
    repeat with r in reminders of targetList
      try
        if (id of r as text) is rid then
          set completed of r to true
          return "completed"
        end if
      end try
    end repeat
  end tell
  return "not_found"
end run
'''
  return run_osascript(script, list_name, reminder_id).strip() or "unknown"


def create_reminder(title: str, due_iso: str, notes: str, list_name: str) -> str:
  proc = subprocess.run(
    ["osascript", str(CREATE_SCRIPT), title, due_iso, notes, list_name, "20"],
    text=True,
    capture_output=True,
  )
  if proc.returncode != 0:
    raise RuntimeError((proc.stderr or proc.stdout or "create reminder failed").strip())
  return (proc.stdout or "").strip()


def as_str(value: Any, default: str = "") -> str:
  if isinstance(value, str):
    return value.strip()
  return default


plan = json.loads(PLAN_JSON.read_text(encoding="utf-8"))
summary = as_str(plan.get("summary"), "Daily ritual reminder plan.")
state_json = plan.get("previous_state_json", "")
entries = plan.get("reminders")
if not isinstance(entries, list):
  entries = []

results = []
existing = fetch_reminders(LIST_NAME)
completed_dupes = 0
created = 0
for item in entries:
  if not isinstance(item, dict):
    continue
  title = as_str(item.get("title"), f"Daily Rituals / 每日例行 · {datetime.now().strftime('%Y-%m-%d')}")
  due_iso = as_str(item.get("due_iso"), "")
  notes = as_str(item.get("notes"), "")
  target_list = as_str(item.get("list"), LIST_NAME) or LIST_NAME
  title_short = title.strip()
  if not title_short or not due_iso:
    continue

  target_date = due_iso[:10]
  for existing_item in existing:
    if existing_item.get("name", "").strip() == title_short and not existing_item["completed"]:
      existing_date = existing_item.get("due_iso", "")[:10]
      if existing_date == target_date:
        outcome = complete_reminder(target_list, existing_item["id"])
        if outcome == "completed":
          completed_dupes += 1

  try:
    reminder_id = create_reminder(title_short, due_iso, notes, target_list)
    created += 1
    results.append({
      "status": "created",
      "title": title_short,
      "due_iso": due_iso,
      "list": target_list,
      "notes": notes,
      "reminder_id": reminder_id,
    })
  except Exception as exc:  # noqa: BLE001
    results.append({
      "status": "failed",
      "title": title_short,
      "due_iso": due_iso,
      "list": target_list,
      "error": str(exc),
    })

if not results:
  results.append({
    "status": "skipped",
    "reason": "No reminders returned by model.",
  })

STATE_JSON.parent.mkdir(parents=True, exist_ok=True)
STATE_JSON.write_text(json.dumps({
  "updated_at": datetime.now().isoformat(timespec="seconds"),
  "summary": summary,
  "run_local_iso": plan.get("run_local_iso", ""),
  "previous_state_json": state_json,
  "results": results,
}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

REPORT_JSON.write_text(json.dumps({
  "summary": summary,
  "created": created,
  "completed_duplicates": completed_dupes,
  "results": results,
}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

print(json.dumps({
  "summary": summary,
  "created": created,
  "completed_duplicates": completed_dupes,
  "results": results,
}, ensure_ascii=False))
PY

cat "$REPORT_JSON"
