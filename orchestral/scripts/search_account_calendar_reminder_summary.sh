#!/usr/bin/env bash
set -euo pipefail

accounts_csv="lachlan.miao.chen@gmail.com,lachen@connect.hku.hk"
named_calendars_csv="lachlan.miao.chen@gmail.com,lachen@connect.hku.hk"
ambiguous_calendar_name="Calendar"
target_calendar="LazyingArt"
target_list="LazyingArt"

usage() {
  cat <<'USAGE'
Usage: search_account_calendar_reminder_summary.sh [options]

Options:
  --accounts <csv>          Reminder source accounts (default: lachlan.miao.chen@gmail.com,lachen@connect.hku.hk)
  --named-calendars <csv>   Exact calendar names to inspect (default: lachlan.miao.chen@gmail.com,lachen@connect.hku.hk)
  --ambiguous-name <name>   Ambiguous calendar name candidates (default: Calendar)
  --target-calendar <name>  Target calendar name (default: LazyingArt)
  --target-list <name>      Target reminder list name (default: LazyingArt)
  -h, --help                Show help
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --accounts)
      accounts_csv="${2:-}"
      shift 2
      ;;
    --named-calendars)
      named_calendars_csv="${2:-}"
      shift 2
      ;;
    --ambiguous-name)
      ambiguous_calendar_name="${2:-}"
      shift 2
      ;;
    --target-calendar)
      target_calendar="${2:-}"
      shift 2
      ;;
    --target-list)
      target_list="${2:-}"
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

echo "[summary] accounts=${accounts_csv} named_calendars=${named_calendars_csv} ambiguous_name=${ambiguous_calendar_name} target_calendar=${target_calendar} target_list=${target_list}"

osascript - "$named_calendars_csv" "$ambiguous_calendar_name" "$target_calendar" <<'APPLESCRIPT'
on splitCSV(csvText)
  if csvText is "" then return {}
  set AppleScript's text item delimiters to ","
  set parts to text items of csvText
  set AppleScript's text item delimiters to ""
  set outList to {}
  repeat with p in parts
    set t to do shell script "printf %s " & quoted form of (p as text) & " | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'"
    if t is not "" then set end of outList to t
  end repeat
  return outList
end splitCSV

on run argv
  set namedCSV to item 1 of argv
  set ambiguousName to item 2 of argv
  set targetCalendarName to item 3 of argv
  set namedList to my splitCSV(namedCSV)
  set outText to ""

  tell application "Calendar"
    if (exists calendar targetCalendarName) then
      set outText to outText & "CALENDAR_TARGET" & tab & targetCalendarName & tab & (count of events of (first calendar whose name is targetCalendarName)) & linefeed
    else
      set outText to outText & "CALENDAR_TARGET" & tab & targetCalendarName & tab & "missing" & linefeed
    end if

    repeat with wantedName in namedList
      set wanted to wantedName as text
      set matches to every calendar whose name is wanted
      if (count of matches) is 0 then
        set outText to outText & "CALENDAR_NAMED" & tab & wanted & tab & "not_found" & tab & "0" & linefeed
      else
        set idx to 0
        repeat with c in matches
          set idx to idx + 1
          set n to count of events of c
          set outText to outText & "CALENDAR_NAMED" & tab & wanted & tab & idx & tab & n & linefeed
        end repeat
      end if
    end repeat

    set ambCandidates to every calendar whose name is ambiguousName
    set outText to outText & "CALENDAR_AMBIGUOUS_TOTAL" & tab & ambiguousName & tab & (count of ambCandidates) & linefeed
    set aidx to 0
    repeat with c in ambCandidates
      set aidx to aidx + 1
      set n to count of events of c
      set outText to outText & "CALENDAR_AMBIGUOUS" & tab & ambiguousName & tab & aidx & tab & n & linefeed
    end repeat
  end tell

  return outText
end run
APPLESCRIPT

osascript - "$accounts_csv" "$target_list" <<'APPLESCRIPT'
on splitCSV(csvText)
  if csvText is "" then return {}
  set AppleScript's text item delimiters to ","
  set parts to text items of csvText
  set AppleScript's text item delimiters to ""
  set outList to {}
  repeat with p in parts
    set t to do shell script "printf %s " & quoted form of (p as text) & " | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'"
    if t is not "" then set end of outList to t
  end repeat
  return outList
end splitCSV

on run argv
  set accountsCSV to item 1 of argv
  set targetListName to item 2 of argv
  set accountNames to my splitCSV(accountsCSV)
  set outText to ""
  tell application "Reminders"
    if (exists account "iCloud") then
      set iCloudAcc to account "iCloud"
      if (exists list targetListName of iCloudAcc) then
        set outText to outText & "REMINDER_TARGET" & tab & targetListName & tab & (count of reminders of list targetListName of iCloudAcc) & linefeed
      else
        set outText to outText & "REMINDER_TARGET" & tab & targetListName & tab & "missing" & linefeed
      end if
    else
      set outText to outText & "REMINDER_TARGET" & tab & targetListName & tab & "icloud_missing" & linefeed
    end if

    repeat with acc in accounts
      set accName to name of acc as text
      if accountNames contains accName then
        repeat with lst in lists of acc
          set listName to name of lst as text
          set n to count of reminders of lst
          set outText to outText & "REMINDER_SOURCE" & tab & accName & tab & listName & tab & n & linefeed
        end repeat
      end if
    end repeat
  end tell
  return outText
end run
APPLESCRIPT
