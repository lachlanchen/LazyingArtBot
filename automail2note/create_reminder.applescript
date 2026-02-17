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
	if nsDate is missing value then error "Invalid ISO date: " & isoString
	return nsDate as date
end dateFromISO

on run argv
	if (count of argv) < 1 then error "Expected args: title [dueISO] [notes] [list] [reminderMinutes]"
	set titleValue to (item 1 of argv) as text
	if (count of argv) ≥ 2 then
		set dueString to (item 2 of argv) as text
	else
		set dueString to ""
	end if
	if (count of argv) ≥ 3 then
		set notesValue to (item 3 of argv) as text
	else
		set notesValue to ""
	end if
	if (count of argv) ≥ 4 then
		set listName to (item 4 of argv) as text
	else
		set listName to "Reminders"
	end if
	if (count of argv) ≥ 5 then
		set reminderMinutes to (item 5 of argv) as integer
	else
		set reminderMinutes to 0
	end if

	if titleValue is "" then set titleValue to "Lazyingart reminder"
	if listName is "" then set listName to "Reminders"

	set reminderBody to notesValue
	if reminderMinutes > 0 then
		set reminderBody to notesValue & return & "[alert: " & reminderMinutes & " minutes before]"
	end if

	tell application "Reminders"
		if (exists list listName) then
			set targetList to list listName
		else
			set targetList to make new list with properties {name:listName}
		end if

		if dueString is "" then
			set newReminder to make new reminder at end of reminders of targetList with properties {name:titleValue, body:reminderBody}
		else
			set dueDate to my dateFromISO(dueString)
			set newReminder to make new reminder at end of reminders of targetList with properties {name:titleValue, body:reminderBody, due date:dueDate}
		end if
		return (id of newReminder) as text
	end tell
end run
