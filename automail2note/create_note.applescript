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
	if (count of argv) < 2 then error "Expected args: title notes [folderPath]"
	set titleValue to (item 1 of argv) as text
	set notesValue to (item 2 of argv) as text
	if (count of argv) ≥ 3 then
		set folderPath to (item 3 of argv) as text
	else
		set folderPath to "Lazyingart/Inbox"
	end if

	if titleValue is "" then set titleValue to "Lazyingart note"
	if folderPath is "" then set folderPath to "Lazyingart/Inbox"

	set targetFolder to my ensureNestedFolder(folderPath)

	tell application "Notes"
		set noteBody to "<html><body><h3>" & titleValue & "</h3><p>" & notesValue & "</p></body></html>"
		set newNote to make new note at targetFolder with properties {name:titleValue, body:noteBody}
		return (id of newNote) as text
	end tell
end run
