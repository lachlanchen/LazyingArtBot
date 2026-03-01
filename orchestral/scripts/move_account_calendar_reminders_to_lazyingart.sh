#!/usr/bin/env bash
set -euo pipefail

accounts_csv="lachlan.miao.chen@gmail.com,lachen@connect.hku.hk"
source_named_calendars_csv="lachlan.miao.chen@gmail.com,lachen@connect.hku.hk"
ambiguous_calendar_name="Calendar"
include_nonempty_ambiguous=1
target_calendar="LazyingArt"
target_list="LazyingArt"
dry_run=0

usage() {
  cat <<'USAGE'
Usage: move_account_calendar_reminders_to_lazyingart.sh [options]

Moves reminders and calendar events into LazyingArt targets.

Options:
  --accounts <csv>              Reminder source accounts (default: lachlan.miao.chen@gmail.com,lachen@connect.hku.hk)
  --source-named-calendars <csv>Exact calendar names to move (default: lachlan.miao.chen@gmail.com,lachen@connect.hku.hk)
  --ambiguous-name <name>       Ambiguous calendar name (default: Calendar)
  --no-ambiguous                Do not move non-empty ambiguous-name calendars
  --target-calendar <name>      Target calendar name (default: LazyingArt)
  --target-list <name>          Target reminder list name (default: LazyingArt)
  --dry-run                     Print plan only, no changes
  -h, --help                    Show help
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --accounts)
      accounts_csv="${2:-}"
      shift 2
      ;;
    --source-named-calendars)
      source_named_calendars_csv="${2:-}"
      shift 2
      ;;
    --ambiguous-name)
      ambiguous_calendar_name="${2:-}"
      shift 2
      ;;
    --no-ambiguous)
      include_nonempty_ambiguous=0
      shift
      ;;
    --target-calendar)
      target_calendar="${2:-}"
      shift 2
      ;;
    --target-list)
      target_list="${2:-}"
      shift 2
      ;;
    --dry-run)
      dry_run=1
      shift
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

echo "[move] accounts=${accounts_csv} source_named_calendars=${source_named_calendars_csv} ambiguous_name=${ambiguous_calendar_name} include_nonempty_ambiguous=${include_nonempty_ambiguous} target_calendar=${target_calendar} target_list=${target_list} dry_run=${dry_run}"

# Reminders move
osascript - "$accounts_csv" "$target_list" "$dry_run" <<'APPLESCRIPT'
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
  set dryRunFlag to (item 3 of argv as integer)
  set accountNames to my splitCSV(accountsCSV)

  set scannedCount to 0
  set movedCount to 0
  set outText to ""

  tell application "Reminders"
    if not (exists account "iCloud") then error "iCloud reminders account not found"
    set iCloudAcc to account "iCloud"

    if not (exists list targetListName of iCloudAcc) then
      if dryRunFlag is 1 then
        set outText to outText & "REMINDER_INFO" & tab & "iCloud" & tab & targetListName & tab & "missing_would_create" & linefeed
      else
        make new list at end of lists of iCloudAcc with properties {name:targetListName}
        set outText to outText & "REMINDER_INFO" & tab & "iCloud" & tab & targetListName & tab & "created" & linefeed
      end if
    end if

    set targetList to list targetListName of iCloudAcc

    repeat with acc in accounts
      set accName to name of acc as text
      if accountNames contains accName then
        repeat with lst in lists of acc
          set listName to name of lst as text
          if not (accName is "iCloud" and listName is targetListName) then
            set itemsToMove to every reminder of lst
            set n to count of itemsToMove
            set scannedCount to scannedCount + n
            if n > 0 then
              if dryRunFlag is 1 then
                set movedCount to movedCount + n
                set outText to outText & "REMINDER_DRYRUN" & tab & accName & tab & listName & tab & targetListName & tab & n & linefeed
              else
                repeat with r in itemsToMove
                  move r to end of reminders of targetList
                  set movedCount to movedCount + 1
                end repeat
                set outText to outText & "REMINDER_MOVED" & tab & accName & tab & listName & tab & targetListName & tab & n & linefeed
              end if
            end if
          end if
        end repeat
      end if
    end repeat
  end tell

  set outText to outText & "REMINDER_SUMMARY" & tab & scannedCount & tab & movedCount & tab & dryRunFlag & linefeed
  return outText
end run
APPLESCRIPT

# Calendar move (AppleScript; reliable with current setup)
osascript - "$source_named_calendars_csv" "$ambiguous_calendar_name" "$include_nonempty_ambiguous" "$target_calendar" "$dry_run" <<'APPLESCRIPT'
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

on alreadyIn(refList, calRef)
  repeat with x in refList
    if (contents of x) is (contents of calRef) then return true
  end repeat
  return false
end alreadyIn

on run argv
  set namedCSV to item 1 of argv
  set ambiguousName to item 2 of argv
  set includeAmbiguousFlag to (item 3 of argv as integer)
  set targetCalendarName to item 4 of argv
  set dryRunFlag to (item 5 of argv as integer)

  set namedList to my splitCSV(namedCSV)
  set sourceCalendars to {}
  set outText to ""
  set scannedCount to 0
  set movedCount to 0
  set failedCount to 0
  set dedupedCount to 0

  tell application "Calendar"
    if not (exists calendar targetCalendarName) then error "Target calendar missing: " & targetCalendarName
    set targetCal to first calendar whose name is targetCalendarName

    repeat with nName in namedList
      set wanted to nName as text
      set matches to every calendar whose name is wanted
      repeat with c in matches
        if not my alreadyIn(sourceCalendars, c) then set end of sourceCalendars to c
      end repeat
    end repeat

    if includeAmbiguousFlag is 1 then
      set ambCandidates to every calendar whose name is ambiguousName
      repeat with c in ambCandidates
        set n to count of events of c
        if n > 0 then
          if not my alreadyIn(sourceCalendars, c) then set end of sourceCalendars to c
        end if
      end repeat
    end if

    set outText to outText & "CALENDAR_SOURCE_TOTAL" & tab & (count of sourceCalendars) & linefeed

    repeat with srcCal in sourceCalendars
      set srcName to name of srcCal as text
      set srcEvents to every event of srcCal
      set n to count of srcEvents
      set scannedCount to scannedCount + n

      if n > 0 then
        if dryRunFlag is 1 then
          set movedCount to movedCount + n
          set outText to outText & "CALENDAR_DRYRUN" & tab & srcName & tab & targetCalendarName & tab & n & linefeed
        else
          repeat with ev in srcEvents
            try
              set titleText to ""
              set startText to ""
              set endText to ""
              set notesText to ""
              set isAllDay to false

              try
                set titleText to summary of ev as text
              end try
              try
                set startText to start date of ev
                set endText to end date of ev
              end try
              try
                set notesText to description of ev as text
              end try
              try
                set isAllDay to allday event of ev
              end try

              set newEvent to missing value
              tell targetCal
                set dupMatches to (every event whose summary is titleText and start date is startText and end date is endText)
              end tell
              if (count of dupMatches) is 0 then
                tell targetCal
                  set newEvent to make new event with properties {summary:titleText, start date:startText, end date:endText, description:notesText, allday event:isAllDay}
                end tell
                try
                  set alarmsList to every display alarm of ev
                  repeat with da in alarmsList
                    try
                      set triggerSeconds to trigger interval of da
                      tell newEvent to make new display alarm at end of display alarms with properties {trigger interval:triggerSeconds}
                    end try
                  end repeat
                end try
              else
                set dedupedCount to dedupedCount + 1
              end if

              delete ev
              if newEvent is not missing value then set movedCount to movedCount + 1
            on error
              set failedCount to failedCount + 1
            end try
          end repeat
          set outText to outText & "CALENDAR_MOVED" & tab & srcName & tab & targetCalendarName & tab & n & linefeed
        end if
      end if
    end repeat
  end tell

  set outText to outText & "CALENDAR_SUMMARY" & tab & scannedCount & tab & movedCount & tab & failedCount & tab & dedupedCount & tab & dryRunFlag & linefeed
  return outText
end run
APPLESCRIPT
