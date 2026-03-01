#!/usr/bin/env bash
set -euo pipefail

source_account="lachen@connect.hku.hk"
source_calendar="Calendar"
target_calendar="LazyingArt"
delete_source=1
dry_run=0

usage() {
  cat <<'USAGE'
Usage: move_events_from_account_calendar_to_lazyingart.sh [options]

Moves events from one account calendar (resolved by source account + calendar name)
into target calendar (default: LazyingArt).

Options:
  --source-account <name>   Source account/store title (default: lachen@connect.hku.hk)
  --source-calendar <name>  Source calendar name (default: Calendar)
  --target-calendar <name>  Target calendar name (default: LazyingArt)
  --keep-source             Copy only (do not delete source events)
  --dry-run                 Print plan only, no changes
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
    --keep-source)
      delete_source=0
      shift
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

echo "[account-move] source_account=${source_account} source_calendar=${source_calendar} target_calendar=${target_calendar} delete_source=${delete_source} dry_run=${dry_run}"

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

if [ -z "$source_calendar_id" ]; then
  echo "Failed to resolve source calendar id" >&2
  exit 1
fi

echo "[account-move] resolved_source_calendar_id=${source_calendar_id}"

osascript - "$source_calendar_id" "$target_calendar" "$delete_source" "$dry_run" <<'APPLESCRIPT'
on run argv
  set sourceCalendarId to item 1 of argv
  set targetCalendarName to item 2 of argv
  set deleteSourceFlag to (item 3 of argv as integer)
  set dryRunFlag to (item 4 of argv as integer)

  set scannedCount to 0
  set createdCount to 0
  set dedupedCount to 0
  set recurrenceUpgradeCount to 0
  set deletedCount to 0
  set deleteFailedCount to 0
  set failedCount to 0
  set sourceAfterCount to 0
  set outText to ""

  tell application "Calendar"
    set sourceCal to calendar id sourceCalendarId
    if not (exists calendar targetCalendarName) then error "Target calendar missing: " & targetCalendarName
    set targetCal to first calendar whose name is targetCalendarName

    set srcEvents to every event of sourceCal
    set scannedCount to count of srcEvents

    repeat with ev in srcEvents
      try
        set titleText to ""
        set startDateVal to current date
        set endDateVal to current date
        set notesText to ""
        set isAllDay to false
        set recurRule to ""

        try
          set titleText to summary of ev as text
        end try
        try
          set startDateVal to start date of ev
          set endDateVal to end date of ev
        end try
        try
          set notesText to description of ev as text
        end try
        try
          set isAllDay to allday event of ev
        end try
        set recurRule to ""
        try
          set recurRule to recurrence of ev as text
        end try
        if recurRule is "missing value" then set recurRule to ""

        tell targetCal
          set dupMatches to (every event whose summary is titleText and start date is startDateVal and end date is endDateVal)
        end tell

        set createdEvent to false
        set hasExactRecurringDup to false
        if (count of dupMatches) is 0 then
          if dryRunFlag is 1 then
            set createdEvent to true
          else
            if recurRule is "" then
              tell targetCal
                set newEvent to make new event with properties {summary:titleText, start date:startDateVal, end date:endDateVal, description:notesText, allday event:isAllDay}
              end tell
            else
              tell targetCal
                set newEvent to make new event with properties {summary:titleText, start date:startDateVal, end date:endDateVal, description:notesText, allday event:isAllDay, recurrence:recurRule}
              end tell
            end if

            try
              set alarmsList to every display alarm of ev
              repeat with da in alarmsList
                try
                  set triggerSeconds to trigger interval of da
                  tell newEvent to make new display alarm at end of display alarms with properties {trigger interval:triggerSeconds}
                end try
              end repeat
            end try
            set createdEvent to true
          end if

          if createdEvent then set createdCount to createdCount + 1
        else
          if recurRule is not "" then
            repeat with d in dupMatches
              set dupRecurrence to ""
              try
                set dupRecurrence to recurrence of d as text
              end try
              if dupRecurrence is "missing value" then set dupRecurrence to ""
              if dupRecurrence is recurRule then
                set hasExactRecurringDup to true
                exit repeat
              end if
            end repeat

            if hasExactRecurringDup then
              set dedupedCount to dedupedCount + 1
            else
              if dryRunFlag is 1 then
                set createdEvent to true
              else
                tell targetCal
                  set newEvent to make new event with properties {summary:titleText, start date:startDateVal, end date:endDateVal, description:notesText, allday event:isAllDay, recurrence:recurRule}
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

                repeat with d in dupMatches
                  try
                    set dupRecurrence to ""
                    try
                      set dupRecurrence to recurrence of d as text
                    end try
                    if dupRecurrence is "missing value" then set dupRecurrence to ""
                    if dupRecurrence is "" then delete d
                  end try
                end repeat
                set createdEvent to true
              end if
              if createdEvent then set recurrenceUpgradeCount to recurrenceUpgradeCount + 1
            end if
          else
            set dedupedCount to dedupedCount + 1
          end if
        end if

        if deleteSourceFlag is 1 then
          if dryRunFlag is 1 then
            set deletedCount to deletedCount + 1
          else
            try
              delete ev
              set deletedCount to deletedCount + 1
            on error
              set deleteFailedCount to deleteFailedCount + 1
            end try
          end if
        end if
      on error
        set failedCount to failedCount + 1
      end try
    end repeat

    set sourceAfterCount to count of events of sourceCal
  end tell

  set outText to outText & "ACCOUNT_MOVE_SUMMARY" & tab & scannedCount & tab & createdCount & tab & dedupedCount & tab & recurrenceUpgradeCount & tab & deletedCount & tab & deleteFailedCount & tab & failedCount & tab & sourceAfterCount & tab & dryRunFlag & linefeed
  return outText
end run
APPLESCRIPT
