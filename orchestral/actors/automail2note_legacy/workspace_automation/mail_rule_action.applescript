use framework "Foundation"
use scripting additions

property keywordList : {"meeting", "meet", "call", "deadline", "due", "action required", "follow up", "follow-up", "schedule", "appointment", "interview", "confirm", "reminder", "deliverable", "submission", "invoice", "payment"}
property pythonPath : "/Users/lachlan/.openclaw/workspace/.venv/bin/python"
property automationScript : "/Users/lachlan/.openclaw/workspace/automation/mail_to_calendar.py"
property monitorLogPath : "/Users/lachlan/.openclaw/workspace/logs/mail_rule_trigger.log"

on escapedForShell(rawText)
	set cleanText to my sanitizedText(rawText)
	set cleanText to my replaceText(cleanText, return, " ")
	set cleanText to my replaceText(cleanText, linefeed, " ")
	set cleanText to my replaceText(cleanText, tab, " ")
	return quoted form of cleanText
end escapedForShell

on replaceText(theText, searchText, replacementText)
	set AppleScript's text item delimiters to searchText
	set textItems to every text item of theText
	set AppleScript's text item delimiters to replacementText
	set joinedText to textItems as text
	set AppleScript's text item delimiters to ""
	return joinedText
end replaceText

on appendMonitorLog(eventName, detailText)
	do shell script "mkdir -p " & quoted form of "/Users/lachlan/.openclaw/workspace/logs"
	set ts to do shell script "date -u +%Y-%m-%dT%H:%M:%SZ"
	set shellLine to "printf '%s\\t%s\\t%s\\n' " & quoted form of ts & " " & quoted form of eventName & " " & my escapedForShell(detailText) & " >> " & quoted form of monitorLogPath
	do shell script shellLine
end appendMonitorLog

on safeRuleName(theRule)
	try
		tell application "Mail"
			return (name of theRule) as text
		end tell
	on error
		return "<unknown-rule>"
	end try
end safeRuleName

on safeMessageID(theMessage)
	try
		tell application "Mail"
			return (message id of theMessage) as text
		end tell
	on error
		return "<unknown-message-id>"
	end try
end safeMessageID

on sanitizedText(rawText)
	if rawText is missing value then return ""
	try
		return rawText as text
	on error
		return ""
	end try
end sanitizedText

on lowercaseText(rawText)
	set cleaned to my sanitizedText(rawText)
	set nsText to current application's NSString's stringWithString_(cleaned)
	return (nsText's lowercaseString()) as text
end lowercaseText

on clippedContent(rawText, limitLength)
	set cleaned to my sanitizedText(rawText)
	set textLength to (count cleaned)
	if textLength = 0 then return ""
	if textLength > limitLength then
		return text 1 thru limitLength of cleaned
	else
		return cleaned
	end if
end clippedContent

on stringEndsWith(rawText, suffixText)
	set supplied to my sanitizedText(rawText)
	set suffixLength to (count suffixText)
	if suffixLength = 0 then return true
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
	try
		tell application "Mail"
			set attachmentList to mail attachments of theMessage
		end tell
	on error
		return false
	end try
	if (count attachmentList) is 0 then return false
	repeat with att in attachmentList
		tell application "Mail"
			set attName to name of att as text
		end tell
		if my stringEndsWith(my lowercaseText(attName), ".ics") then return true
	end repeat
	return false
end hasICSAttachment

on recipientSummary(theMessage)
	try
		tell application "Mail"
			set recipientList to to recipients of theMessage
		end tell
	on error
		return ""
	end try
	if (count recipientList) is 0 then return ""
	set nameList to {}
	repeat with rec in recipientList
		tell application "Mail"
			set recAddress to address of rec
			set recName to name of rec
		end tell
		if recAddress is missing value then set recAddress to ""
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

on isoStringFromDate(theDate)
	set isoFormatter to current application's NSISO8601DateFormatter's alloc()'s init()
	isoFormatter's setFormatOptions_(current application's NSISO8601DateFormatWithInternetDateTime)
	return (isoFormatter's stringFromDate_(theDate)) as text
end isoStringFromDate

on messageRecord(theMessage)
	set messageID to my safeMessageID(theMessage)
	set recipientLine to my recipientSummary(theMessage)
	set inviteState to my hasICSAttachment(theMessage)
	set subjectLine to ""
	set senderLine to ""
	set dateReceived to (current date)
	set flaggedState to false
	set mailboxName to ""
	set bodySnippet to ""
	set accountName to ""
	try
		tell application "Mail"
			set subjectLine to my sanitizedText(subject of theMessage)
		end tell
	on error errMsg number errNum
		my appendMonitorLog("message_field_error", "messageID=" & messageID & " field=subject code=" & errNum & " error=" & errMsg)
	end try
	try
		tell application "Mail"
			set senderLine to my sanitizedText(sender of theMessage)
		end tell
	on error errMsg number errNum
		my appendMonitorLog("message_field_error", "messageID=" & messageID & " field=sender code=" & errNum & " error=" & errMsg)
	end try
	try
		tell application "Mail"
			set dateReceived to date received of theMessage
		end tell
	on error errMsg number errNum
		my appendMonitorLog("message_field_error", "messageID=" & messageID & " field=date_received code=" & errNum & " error=" & errMsg)
	end try
	try
		tell application "Mail"
			set flaggedState to flagged status of theMessage
		end tell
	on error errMsg number errNum
		my appendMonitorLog("message_field_error", "messageID=" & messageID & " field=flagged_status code=" & errNum & " error=" & errMsg)
	end try
	try
		tell application "Mail"
			set mailboxName to my sanitizedText(name of mailbox of theMessage)
		end tell
	on error errMsg number errNum
		my appendMonitorLog("message_field_error", "messageID=" & messageID & " field=mailbox code=" & errNum & " error=" & errMsg)
	end try
	try
		tell application "Mail"
			set bodySnippet to my clippedContent(content of theMessage, 1500)
		end tell
	on error errMsg number errNum
		my appendMonitorLog("message_field_error", "messageID=" & messageID & " field=content code=" & errNum & " error=" & errMsg)
	end try
	try
		tell application "Mail"
			set accountName to my sanitizedText(name of account of mailbox of theMessage)
		end tell
	on error errMsg number errNum
		my appendMonitorLog("message_field_error", "messageID=" & messageID & " field=account code=" & errNum & " error=" & errMsg)
	end try
	set isoDateString to my isoStringFromDate(dateReceived)
	return {messageID:messageID, subject:subjectLine, sender:senderLine, recipients:recipientLine, receivedAt:isoDateString, flagged:flaggedState, mailbox:mailboxName, account:accountName, body:bodySnippet, hasInvite:inviteState}
end messageRecord

on isActionableMessage(theMessage)
	set messageID to my safeMessageID(theMessage)
	set flaggedState to false
	set subjectLine to ""
	set bodySnippet to ""
	try
		tell application "Mail"
			set flaggedState to flagged status of theMessage
		end tell
	on error errMsg number errNum
		my appendMonitorLog("message_field_error", "messageID=" & messageID & " field=flagged_status_precheck code=" & errNum & " error=" & errMsg)
	end try
	try
		tell application "Mail"
			set subjectLine to my sanitizedText(subject of theMessage)
		end tell
	on error errMsg number errNum
		my appendMonitorLog("message_field_error", "messageID=" & messageID & " field=subject_precheck code=" & errNum & " error=" & errMsg)
	end try
	try
		tell application "Mail"
			set bodySnippet to my clippedContent(content of theMessage, 1500)
		end tell
	on error errMsg number errNum
		my appendMonitorLog("message_field_error", "messageID=" & messageID & " field=content_precheck code=" & errNum & " error=" & errMsg)
	end try
	if flaggedState is true then return true
	if my containsKeyword(subjectLine, bodySnippet) then return true
	if my hasICSAttachment(theMessage) then return true
	return false
end isActionableMessage

on encodeRecords(recordList)
	set jsonData to current application's NSJSONSerialization's dataWithJSONObject_options_error_(recordList, 0, missing value)
	set jsonString to current application's NSString's alloc()'s initWithData_encoding_(jsonData, current application's NSUTF8StringEncoding)
	return jsonString as text
end encodeRecords

on dispatchRecords(recordList)
	if (count recordList) = 0 then return
	set jsonString to my encodeRecords(recordList)
	set tempPath to do shell script "mktemp /tmp/lazyingart_mail_rule_XXXXXX.json"
	set nsJSON to current application's NSString's stringWithString_(jsonString)
	set tempNSString to current application's NSString's stringWithString_(tempPath)
	set writeError to missing value
	nsJSON's writeToFile_atomically_encoding_error_(tempNSString, true, current application's NSUTF8StringEncoding, reference to writeError)
	if writeError is not missing value then error (writeError's localizedDescription() as text)
	set commandText to quoted form of pythonPath & " " & quoted form of automationScript & " --trigger-source mail-rule --message-json " & quoted form of tempPath
	my appendMonitorLog("dispatch_started", "actionable=" & (count recordList))
	try
		set commandOutput to do shell script commandText
		my appendMonitorLog("dispatch_finished", "status=ok output=" & commandOutput)
	on error errMsg number errNum
		my appendMonitorLog("dispatch_failed", "status=error code=" & errNum & " error=" & errMsg)
		log "Mail rule pipeline error: " & errMsg & " (" & errNum & ")"
	end try
	do shell script "rm " & quoted form of tempPath
end dispatchRecords

on processMessages(theMessages)
	set totalCount to count theMessages
	my appendMonitorLog("mail_rule_triggered", "totalMessages=" & totalCount)
	set receivedAfterISO to do shell script "date -u -v-20M +%Y-%m-%dT%H:%M:%SZ"
	set commandText to "OPENCLAW_MAIL_LOOKBACK_MINUTES=30 " & quoted form of pythonPath & " " & quoted form of automationScript & " --trigger-source mail-rule --latest-only --received-after " & quoted form of receivedAfterISO
	my appendMonitorLog("dispatch_started", "mode=recent_fetch totalMessages=" & totalCount & " receivedAfter=" & receivedAfterISO)
	try
		set commandOutput to do shell script commandText
		my appendMonitorLog("dispatch_finished", "status=ok mode=recent_fetch output=" & commandOutput)
	on error errMsg number errNum
		my appendMonitorLog("dispatch_failed", "status=error mode=recent_fetch code=" & errNum & " error=" & errMsg)
		error errMsg number errNum
	end try
end processMessages

using terms from application "Mail"
	on perform mail action with messages theMessages for rule theRule
		try
			my appendMonitorLog("mail_rule_invoked", "rule=" & my safeRuleName(theRule))
			my processMessages(theMessages)
		on error errMsg number errNum
			my appendMonitorLog("mail_rule_runtime_error", "error=" & errMsg & " code=" & errNum)
			log "Mail rule runtime error: " & errMsg & " (" & errNum & ")"
		end try
	end perform mail action with messages
end using terms from
