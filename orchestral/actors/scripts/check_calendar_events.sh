#!/usr/bin/env bash
set -euo pipefail

named_calendars_csv="lachlan.miao.chen@gmail.com"
ambiguous_calendar_name="Calendar"
keyword_csv="agentic,microscopy,anniversary"

usage() {
  cat <<'USAGE'
Usage: check_calendar_events.sh [options]

Options:
  --named-calendars <csv>   Exact calendar names to dump (default: lachlan.miao.chen@gmail.com)
  --ambiguous-name <name>   Common calendar name to inspect as candidates (default: Calendar)
  --keywords <csv>          Keyword sweep across all calendars (default: agentic,microscopy,anniversary)
  -h, --help                Show help

Examples:
  check_calendar_events.sh
  check_calendar_events.sh --named-calendars "lachlan.miao.chen@gmail.com,lachen@connect.hku.hk" --ambiguous-name "Calendar"
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --named-calendars)
      named_calendars_csv="${2:-}"
      shift 2
      ;;
    --ambiguous-name)
      ambiguous_calendar_name="${2:-}"
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

echo "[calendar-check] named_calendars=${named_calendars_csv} ambiguous_name=${ambiguous_calendar_name} keywords=${keyword_csv}"

osascript - "$named_calendars_csv" "$ambiguous_calendar_name" <<'APPLESCRIPT'
on splitCSV(csvText)
  if csvText is "" then return {}
  set AppleScript's text item delimiters to ","
  set parts to text items of csvText
  set AppleScript's text item delimiters to ""
  set outList to {}
  repeat with p in parts
    set t to (p as text)
    set t to my trimText(t)
    if t is not "" then set end of outList to t
  end repeat
  return outList
end splitCSV

on trimText(t)
  set s to t as text
  set s to do shell script "printf %s " & quoted form of s & " | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'"
  return s
end trimText

on dumpCalendar(calRef, labelText)
  set outText to "## " & labelText
  tell application "Calendar"
    try
      set evs to every event of calRef
      set outText to outText & " (count=" & (count of evs) & ")" & linefeed
      repeat with e in evs
        set titleText to ""
        set startText to ""
        set endText to ""
        try
          set titleText to summary of e as text
        end try
        try
          set startText to start date of e as text
          set endText to end date of e as text
        end try
        set outText to outText & "- " & titleText & " | " & startText & " -> " & endText & linefeed
      end repeat
    on error errMsg number errNum
      set outText to outText & " error=" & errNum & " " & errMsg & linefeed
    end try
  end tell
  return outText
end dumpCalendar

on run argv
  set namedCSV to item 1 of argv
  set ambiguousName to item 2 of argv
  set namedList to my splitCSV(namedCSV)
  set outText to ""

  tell application "Calendar"
    set allCalendars to calendars
  end tell

  repeat with wantedName in namedList
    set wanted to wantedName as text
    set matches to {}
    tell application "Calendar"
      repeat with c in allCalendars
        if (name of c as text) is wanted then set end of matches to c
      end repeat
    end tell
    if (count of matches) is 0 then
      set outText to outText & "## named: " & wanted & " (not found)" & linefeed & linefeed
    else
      set n to 0
      repeat with mc in matches
        set n to n + 1
        set outText to outText & my dumpCalendar(mc, "named: " & wanted & " #" & n) & linefeed
      end repeat
    end if
  end repeat

  set ambCandidates to {}
  tell application "Calendar"
    repeat with c in allCalendars
      if (name of c as text) is ambiguousName then set end of ambCandidates to c
    end repeat
  end tell

  set outText to outText & "## ambiguous group: " & ambiguousName & " (candidates=" & (count of ambCandidates) & ")" & linefeed
  set idx to 0
  repeat with ac in ambCandidates
    set idx to idx + 1
    tell application "Calendar" to set n to count of events of ac
    if n > 0 then
      set outText to outText & my dumpCalendar(ac, "ambiguous: " & ambiguousName & " #" & idx)
    else
      set outText to outText & "## ambiguous: " & ambiguousName & " #" & idx & " (count=0)" & linefeed
    end if
    set outText to outText & linefeed
  end repeat

  return outText
end run
APPLESCRIPT

if [ -n "$keyword_csv" ]; then
  echo
  echo "[keyword-scan]"
  osascript - "$keyword_csv" <<'APPLESCRIPT'
on splitCSV(csvText)
  if csvText is "" then return {}
  set AppleScript's text item delimiters to ","
  set parts to text items of csvText
  set AppleScript's text item delimiters to ""
  set outList to {}
  repeat with p in parts
    set t to (p as text)
    set t to do shell script "printf %s " & quoted form of t & " | tr '[:upper:]' '[:lower:]' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'"
    if t is not "" then set end of outList to t
  end repeat
  return outList
end splitCSV

on run argv
  set kws to my splitCSV(item 1 of argv)
  set outText to ""
  tell application "Calendar"
    repeat with c in calendars
      set calName to name of c as text
      try
        set evs to every event of c
        repeat with e in evs
          set titleText to ""
          set titleLower to ""
          try
            set titleText to summary of e as text
            set titleLower to do shell script "printf %s " & quoted form of titleText & " | tr '[:upper:]' '[:lower:]'"
          end try
          set matched to false
          repeat with kw in kws
            if titleLower contains (kw as text) then
              set matched to true
              exit repeat
            end if
          end repeat
          if matched then
            set startText to ""
            set endText to ""
            try
              set startText to start date of e as text
              set endText to end date of e as text
            end try
            set outText to outText & calName & " | " & startText & " | " & endText & " | " & titleText & linefeed
          end if
        end repeat
      end try
    end repeat
  end tell
  if outText is "" then return "NO_KEYWORD_MATCH"
  return outText
end run
APPLESCRIPT
fi
