use framework "Foundation"
use scripting additions

property isoFormatter : missing value

on ensureISOFormatter()
	if isoFormatter is missing value then
		set isoFormatter to current application's NSISO8601DateFormatter's alloc()'s init()
		isoFormatter's setFormatOptions_(current application's NSISO8601DateFormatWithInternetDateTime)
	end if
end ensureISOFormatter

on dateFromISO(isoString)
	my ensureISOFormatter()
	set nsDate to isoFormatter's dateFromString_(isoString)
	return nsDate
end dateFromISO

on run argv
	if (count of argv) < 3 then error "Expected args: title startISO endISO [notes] [calendar] [alertMinutes]"
	set titleValue to (item 1 of argv) as text
	set startString to (item 2 of argv) as text
	set endString to (item 3 of argv) as text
	if (count of argv) ≥ 4 then
		set notesValue to (item 4 of argv) as text
	else
		set notesValue to ""
	end if
	if (count of argv) ≥ 5 then
		set calendarText to (item 5 of argv) as text
	else
		set calendarText to ""
	end if
	if (count of argv) ≥ 6 then
		set alertValue to (item 6 of argv) as integer
	else
		set alertValue to 0
	end if
	set startNSDate to my dateFromISO(startString)
	set endNSDate to my dateFromISO(endString)
	set startDate to startNSDate as date
	set endDate to endNSDate as date
	if titleValue is "" then set titleValue to "MAIL follow-up"
	set titleText to titleValue as text
	set notesText to notesValue as text
	tell application "Calendar"
		if calendarText is "" then
			set targetCal to first calendar
		else if (exists calendar calendarText) then
			set targetCal to calendar calendarText
		else
			set targetCal to first calendar
		end if
		tell targetCal
			set newEvent to make new event with properties {summary:titleText, start date:startDate, end date:endDate, description:notesText}
			if alertValue is not equal to 0 then
				set triggerSeconds to alertValue * -60
				tell newEvent to make new display alarm at end of display alarms with properties {trigger interval:triggerSeconds}
			end if
		end tell
		return (uid of newEvent) as text
	end tell
end run
