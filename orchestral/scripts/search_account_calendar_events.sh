#!/usr/bin/env bash
set -euo pipefail

source_account="lachen@connect.hku.hk"
source_calendar="Calendar"
target_calendar="LazyingArt"
keyword_csv=""

usage() {
  cat <<'USAGE'
Usage: search_account_calendar_events.sh [options]

Resolve an account calendar by source account + calendar name and print source/target event snapshots.

Options:
  --source-account <name>   Source account/store title (default: lachen@connect.hku.hk)
  --source-calendar <name>  Source calendar name (default: Calendar)
  --target-calendar <name>  Target calendar name (default: LazyingArt)
  --keywords <csv>          Optional keyword sweep in source + target titles (case-insensitive)
  -h, --help                Show help
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --source-account)
      source_account="${2:-}"
      shift 2
      ;;
    --source-calendar)
      source_calendar="${2:-}"
      shift 2
      ;;
    --target-calendar)
      target_calendar="${2:-}"
      shift 2
      ;;
    --keywords)
      keyword_csv="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

echo "[account-search] source_account=${source_account} source_calendar=${source_calendar} target_calendar=${target_calendar} keywords=${keyword_csv}"

source_calendar_id="$(swift - "$source_account" "$source_calendar" <<'SWIFT'
import Foundation
import EventKit

let sourceAccount = CommandLine.arguments[1]
let sourceCalendar = CommandLine.arguments[2]

let sem = DispatchSemaphore(value: 0)
let store = EKEventStore()
var granted = false
store.requestFullAccessToEvents { ok, _ in
  granted = ok
  sem.signal()
}
_ = sem.wait(timeout: .now() + 10)
guard granted else {
  fputs("ERROR:no_calendar_access\n", stderr)
  exit(2)
}

let match = store.calendars(for: .event).first {
  $0.title == sourceCalendar && ($0.source?.title ?? "") == sourceAccount
}
guard let cal = match else {
  fputs("ERROR:calendar_not_found\n", stderr)
  exit(3)
}
print(cal.calendarIdentifier)
SWIFT
)"

echo "[account-search] resolved_source_calendar_id=${source_calendar_id}"

osascript - "$source_calendar_id" "$source_account" "$source_calendar" "$target_calendar" "$keyword_csv" <<'APPLESCRIPT'
on splitCSV(csvText)
  if csvText is "" then return {}
  set AppleScript's text item delimiters to ","
  set parts to text items of csvText
  set AppleScript's text item delimiters to ""
  set outList to {}
  repeat with p in parts
    set t to do shell script "printf %s " & quoted form of (p as text) & " | tr '[:upper:]' '[:lower:]' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'"
    if t is not "" then set end of outList to t
  end repeat
  return outList
end splitCSV

on run argv
  set sourceCalendarId to item 1 of argv
  set sourceAccountName to item 2 of argv
  set sourceCalendarName to item 3 of argv
  set targetCalendarName to item 4 of argv
  set keywordCSV to item 5 of argv
  set keywords to my splitCSV(keywordCSV)
  set outText to ""

  tell application "Calendar"
    set sourceCal to calendar id sourceCalendarId
    if not (exists calendar targetCalendarName) then error "Target calendar missing: " & targetCalendarName
    set targetCal to first calendar whose name is targetCalendarName

    set srcEvents to every event of sourceCal
    set tgtEvents to every event of targetCal

    set outText to outText & "SOURCE" & tab & sourceAccountName & tab & sourceCalendarName & tab & (count of srcEvents) & linefeed
    repeat with e in srcEvents
      set titleText to ""
      set startText to ""
      set endText to ""
      set recurText to ""
      try
        set titleText to summary of e as text
      end try
      try
        set startText to start date of e as text
        set endText to end date of e as text
      end try
      try
        set recurText to recurrence of e as text
      end try
      if recurText is "missing value" then set recurText to ""
      set outText to outText & "SOURCE_EVENT" & tab & titleText & tab & startText & tab & endText & tab & recurText & linefeed
    end repeat

    set outText to outText & "TARGET" & tab & targetCalendarName & tab & (count of tgtEvents) & linefeed

    if (count of keywords) > 0 then
      repeat with e in tgtEvents
        set titleText to ""
        set titleLower to ""
        set startText to ""
        set endText to ""
        try
          set titleText to summary of e as text
          set titleLower to do shell script "printf %s " & quoted form of titleText & " | tr '[:upper:]' '[:lower:]'"
        end try
        try
          set startText to start date of e as text
          set endText to end date of e as text
        end try
        set recurText to ""
        try
          set recurText to recurrence of e as text
        end try
        if recurText is "missing value" then set recurText to ""
        set matched to false
        repeat with kw in keywords
          if titleLower contains (kw as text) then
            set matched to true
            exit repeat
          end if
        end repeat
        if matched then
          set outText to outText & "TARGET_MATCH" & tab & titleText & tab & startText & tab & endText & tab & recurText & linefeed
        end if
      end repeat
    end if
  end tell

  return outText
end run
APPLESCRIPT
