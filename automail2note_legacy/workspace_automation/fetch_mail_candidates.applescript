use framework "Foundation"
use scripting additions

property isoFormatter : missing value
property keywordList : {"meeting", "meet", "call", "deadline", "due", "action required", "follow up", "follow-up", "schedule", "appointment", "interview", "confirm", "reminder", "deliverable", "submission", "invoice", "payment"}
property maxBodyLength : 600
property lookbackDays : 0.25
property maxPerAccount : 5

on ensureISOFormatter()
	if isoFormatter is missing value then
		set isoFormatter to current application's NSISO8601DateFormatter's alloc()'s init()
		isoFormatter's setFormatOptions_(current application's NSISO8601DateFormatWithInternetDateTime)
	end if
end ensureISOFormatter

on isoStringFromDate(theDate)
	my ensureISOFormatter()
	set isoString to (isoFormatter's stringFromDate_(theDate)) as text
	return isoString
end isoStringFromDate

on lowercaseText(rawText)
	set safeText to my sanitizedText(rawText)
	set nsText to current application's NSString's stringWithString_(safeText)
	set lowered to nsText's lowercaseString()
	return lowered as text
end lowercaseText

on sanitizedText(rawText)
	if rawText is missing value then return ""
	try
		return rawText as text
	on error
		return ""
	end try
end sanitizedText

on clippedContent(rawText)
	set cleaned to my sanitizedText(rawText)
	set textLength to (count cleaned)
	if textLength is 0 then return ""
	if textLength > maxBodyLength then
		return text 1 thru maxBodyLength of cleaned
	else
		return cleaned
	end if
end clippedContent

on stringEndsWith(rawText, suffixText)
	set supplied to my sanitizedText(rawText)
	set suffixLength to (count suffixText)
	if suffixLength is 0 then return true
	set totalLength to (count supplied)
	if totalLength < suffixLength then return false
	set tailText to text (totalLength - suffixLength + 1) thru totalLength of supplied
	return (tailText as text) is suffixText
end stringEndsWith

on containsKeyword(subjectText, bodyText)
	set loweredSubject to my lowercaseText(subjectText)
	set loweredBody to my lowercaseText(bodyText)
	repeat with kw in keywordList
		set currentKeyword to kw as text
		if (loweredSubject contains currentKeyword) or (loweredBody contains currentKeyword) then return true
	end repeat
	return false
end containsKeyword

on hasICSAttachment(theMessage)
	tell application "Mail"
		set attachmentList to mail attachments of theMessage
	end tell
	if (count attachmentList) is 0 then return false
	repeat with att in attachmentList
		tell application "Mail"
			set attName to name of att as text
		end tell
		if my stringEndsWith(my lowercaseText(attName), ".ics") then return true
	end repeat
	return false
end hasICSAttachment

on isActionableMessage(theMessage)
	tell application "Mail"
		try
			if flagged status of theMessage is true then return true
		end try
		try
			set subjectLine to subject of theMessage as text
		on error
			set subjectLine to ""
		end try
	end tell
	if my containsKeyword(subjectLine, "") then return true
	tell application "Mail"
		try
			set bodySnippet to my clippedContent(content of theMessage)
		on error
			set bodySnippet to ""
		end try
	end tell
	if my containsKeyword("", bodySnippet) then return true
	if my hasICSAttachment(theMessage) then return true
	return false
end isActionableMessage

on recipientSummary(theMessage)
	tell application "Mail"
		set recipientList to to recipients of theMessage
	end tell
	if (count recipientList) is 0 then return ""
	set nameList to {}
	repeat with rec in recipientList
		tell application "Mail"
			set recAddress to address of rec
			set recName to name of rec
		end tell
		if recName is missing value or recName is "" then
			set end of nameList to recAddress
		else
			set end of nameList to (recName & " <" & recAddress & ">")
		end if
	end repeat
	set AppleScript's text item delimiters to ", "
	set summaryText to nameList as text
	set AppleScript's text item delimiters to ""
	return summaryText
end recipientSummary

on messageRecord(theMessage, accountName)
	tell application "Mail"
		set messageID to message id of theMessage
		set subjectLine to subject of theMessage as text
		set senderLine to sender of theMessage as text
		set recipientLine to my recipientSummary(theMessage)
		set dateReceived to date received of theMessage
		set flaggedState to flagged status of theMessage
		set mailboxName to name of mailbox of theMessage
		set bodySnippet to my clippedContent(content of theMessage)
		set inviteState to my hasICSAttachment(theMessage)
	end tell
	set isoDateString to my isoStringFromDate(dateReceived)
	set recordDict to {messageID:messageID, subject:subjectLine, sender:senderLine, recipients:recipientLine, receivedAt:isoDateString, flagged:flaggedState, mailbox:mailboxName, account:accountName, body:bodySnippet, hasInvite:inviteState}
	return recordDict
end messageRecord

on encodeToJSON(someList)
	set jsonData to current application's NSJSONSerialization's dataWithJSONObject_options_error_(someList, 0, missing value)
	set jsonString to current application's NSString's alloc()'s initWithData_encoding_(jsonData, current application's NSUTF8StringEncoding)
	return jsonString as text
end encodeToJSON

on inboxMailboxesForAccount(acc)
	set resultBoxes to {}
	tell application "Mail"
		try
			set mailboxList to every mailbox of acc
		on error
			set mailboxList to {}
		end try
	end tell
	repeat with mb in mailboxList
		try
			tell application "Mail"
				set mbName to name of mb as text
			end tell
		on error
			set mbName to ""
		end try
		if my lowercaseText(mbName) is "inbox" then set end of resultBoxes to mb
	end repeat
	return resultBoxes
end inboxMailboxesForAccount

on run
	set collected to {}
	set lookbackDuration to (lookbackDays * days)
	try
		set envMinutesText to do shell script "printenv OPENCLAW_MAIL_LOOKBACK_MINUTES"
		if envMinutesText is not "" then set lookbackDuration to ((envMinutesText as integer) * minutes)
	end try
	set cutoffDate to (current date) - lookbackDuration
	tell application "Mail"
		set accountList to accounts
	end tell
	repeat with acc in accountList
		tell application "Mail"
			set accName to name of acc as text
		end tell
		set inboxes to my inboxMailboxesForAccount(acc)
		repeat with inboxMailbox in inboxes
			try
				tell application "Mail"
					set messagePool to (messages of inboxMailbox whose date received >= cutoffDate)
				end tell
			on error
				set messagePool to {}
			end try
			set poolCount to (count messagePool)
			if poolCount > maxPerAccount then
				set startIndex to poolCount - maxPerAccount + 1
				set messagePool to items startIndex thru poolCount of messagePool
			end if
			repeat with eachMsg in messagePool
				if my isActionableMessage(eachMsg) then
					set recordDict to my messageRecord(eachMsg, accName)
					set end of collected to recordDict
				end if
			end repeat
		end repeat
	end repeat
	return my encodeToJSON(collected)
end run
