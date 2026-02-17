use scripting additions

on replaceText(sourceText, findText, replText)
	set savedTIDs to AppleScript's text item delimiters
	set AppleScript's text item delimiters to findText
	set parts to text items of sourceText
	set AppleScript's text item delimiters to replText
	set joined to parts as text
	set AppleScript's text item delimiters to savedTIDs
	return joined
end replaceText

on replaceFirstText(sourceText, findText, replText)
	set sourceValue to sourceText as text
	set findValue to findText as text
	set pos to offset of findValue in sourceValue
	if pos is 0 then return sourceValue

	set headText to ""
	if pos > 1 then set headText to text 1 thru (pos - 1) of sourceValue

	set tailStart to pos + (length of findValue)
	set tailText to ""
	if tailStart ≤ (length of sourceValue) then set tailText to text tailStart thru -1 of sourceValue

	return headText & replText & tailText
end replaceFirstText

on trimText(inputText)
	set t to inputText as text
	repeat while (t is not "") and ((character 1 of t is space) or (character 1 of t is tab) or (character 1 of t is return) or (character 1 of t is linefeed))
		if (length of t) = 1 then
			set t to ""
		else
			set t to text 2 thru -1 of t
		end if
	end repeat
	repeat while (t is not "") and ((character -1 of t is space) or (character -1 of t is tab) or (character -1 of t is return) or (character -1 of t is linefeed))
		if (length of t) = 1 then
			set t to ""
		else
			set t to text 1 thru -2 of t
		end if
	end repeat
	return t
end trimText

on parseFolderPath(folderPath)
	set normalizedPath to my replaceText(folderPath as text, ">", "/")
	set normalizedPath to my replaceText(normalizedPath, "\\", "/")
	set savedTIDs to AppleScript's text item delimiters
	set AppleScript's text item delimiters to "/"
	set rawParts to text items of normalizedPath
	set AppleScript's text item delimiters to savedTIDs

	set cleanedParts to {}
	repeat with p in rawParts
		set partName to my trimText(p as text)
		if partName is not "" then set end of cleanedParts to partName
	end repeat
	return cleanedParts
end parseFolderPath

on ensureNestedFolder(folderPath)
	set parts to my parseFolderPath(folderPath)
	if (count of parts) is 0 then set parts to {"Lazyingart", "Inbox"}

	tell application "Notes"
		set parentFolder to missing value
		repeat with p in parts
			set partName to p as text
			set targetFolder to missing value
			if parentFolder is missing value then
				set topMatches to every folder whose name is partName
				repeat with f in topMatches
					set folderRef to contents of f
					try
						set containerObj to container of folderRef
						if (class of containerObj) is account then
							set targetFolder to folderRef
							exit repeat
						end if
					on error
						-- Fall back to first match when container cannot be inspected.
						set targetFolder to folderRef
						exit repeat
					end try
				end repeat
				if targetFolder is missing value then
					set targetFolder to make new folder with properties {name:partName}
				end if
			else
				set parentID to id of parentFolder as text
				set childMatches to every folder whose name is partName
				repeat with f in childMatches
					set folderRef to contents of f
					try
						set containerObj to container of folderRef
						if (id of containerObj as text) is parentID then
							set targetFolder to folderRef
							exit repeat
						end if
					end try
				end repeat
				if targetFolder is missing value then
					set targetFolder to make new folder at parentFolder with properties {name:partName}
				end if
			end if
			set parentFolder to targetFolder
		end repeat
		return parentFolder
	end tell
end ensureNestedFolder

on run argv
	if (count of argv) < 2 then error "Expected args: title notes [folderPath] [insertMode]"
	set titleValue to (item 1 of argv) as text
	set notesValue to (item 2 of argv) as text
	if (count of argv) ≥ 3 then
		set folderPath to (item 3 of argv) as text
	else
		set folderPath to "Lazyingart/Inbox"
	end if
	if (count of argv) ≥ 4 then
		set insertMode to my trimText(item 4 of argv)
	else
		set insertMode to "prepend"
	end if

	if titleValue is "" then set titleValue to "Lazyingart note"
	if folderPath is "" then set folderPath to "Lazyingart/Inbox"
	if insertMode is "" then set insertMode to "prepend"

	set targetFolder to my ensureNestedFolder(folderPath)

	tell application "Notes"
		set existingNote to missing value
		try
			set matchedNotes to (every note of targetFolder whose name is titleValue)
			if (count of matchedNotes) > 0 then set existingNote to item 1 of matchedNotes
		end try

		if existingNote is missing value then
			set noteBody to "<html><body><h3>" & titleValue & "</h3><p>" & notesValue & "</p></body></html>"
			set newNote to make new note at targetFolder with properties {name:titleValue, body:noteBody}
			return (id of newNote) as text
		else
			set stampText to do shell script "date '+%Y-%m-%d %H:%M:%S'"
			set newEntry to "<div><p><b>" & stampText & "</b></p><p>" & notesValue & "</p><hr/></div>"
			set oldBody to body of existingNote as text
			if insertMode is "append" then
				set updatedBody to oldBody & newEntry
			else
				if oldBody contains "</h3>" then
					set updatedBody to my replaceFirstText(oldBody, "</h3>", "</h3>" & newEntry)
				else
					set updatedBody to newEntry & oldBody
				end if
			end if
			set body of existingNote to updatedBody
			return (id of existingNote) as text
		end if
	end tell
end run
