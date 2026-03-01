use scripting additions

property globalSenderExact : {"its_boc@bochk.com", "e-statement@bochk.com", "ealert@bochk.com", "no_reply@stmt.futuhk.com", "no_reply@notification.futuhk.com", "enotices.daily.digest@hku.hk", "noreply@medium.com", "noreply@news.paypal.com", "notify@mox.com", "no-reply@mailer.mox.com", "trip.com@newsletter.trip.com", "notifications-noreply@linkedin.com", "updates-noreply@linkedin.com"}
property globalSenderContains : {"googlealerts"}
property globalSubjectContains : {"daily digest", "weekly digest", "e-statement", "new mox account statement available", "direct payment successful", "money transfer unsuccessful", "paypal credit", "google alert", "newsletter"}
property accountSpecificSenderExact : {{"lachen@connect.hku.hk", {"enotices.daily.digest@hku.hk", "careers@cedars.hku.hk", "cedars-cybercampus@hku.hk", "hkuip@hku.hk", "ivanhwc@hku.hk", "psychiatry-events@hku.hk", "events@mail.opticacommunications.org", "events@eee.hku.hk", "enggfac@hku.hk", "cedarspe@hku.hk", "ip0122@hku.hk", "semin@hku.hk", "garyhkl@hku.hk", "hkutec@hku.hk", "libis@hku.hk", "pgsa@connect.hku.hk", "kyduen@hku.hk", "geogevnt@hku.hk"}}}
property targetAccounts : {"lachen@connect.hku.hk", "lachlan.mia.chan", "lachlan.mia.chan@gmail.com", "lachlan.miao.chen@gmail.com"}
property lookbackDays : 3650
property chunkDays : 30
property logPath : "/tmp/move_useless_emails_all.log"

on normalizedText(rawText)
	if rawText is missing value then return ""
	try
		return (rawText as text)
	on error
		return ""
	end try
end normalizedText

on lowerText(rawText)
	set t to my normalizedText(rawText)
	return do shell script "printf %s " & quoted form of t & " | tr '[:upper:]' '[:lower:]'"
end lowerText

on appendLog(lineText)
	do shell script "printf '%s %s\\n' " & quoted form of (do shell script "date '+%Y-%m-%d %H:%M:%S'") & quoted form of lineText & " >> " & quoted form of logPath
end appendLog

on listContainsMatch(theList, valueText)
	repeat with itemText in theList
		if valueText is (my lowerText(itemText as text)) then return true
	end repeat
	return false
end listContainsMatch

on listContainsFragment(theList, valueText)
	repeat with itemText in theList
		set needle to my lowerText(itemText as text)
		if needle is not "" and valueText contains needle then return true
	end repeat
	return false
end listContainsFragment

on extractSenderEmail(senderLine)
	set rawLine to my normalizedText(senderLine)
	set senderLower to my lowerText(rawLine)
	set openPos to (offset of "<" in senderLower)
	set closePos to (offset of ">" in senderLower)
	if openPos > 0 and closePos > openPos then
		return text (openPos + 1) thru (closePos - 1) of senderLower
	end if
	return senderLower
end extractSenderEmail

on accountSpecificList(accountName)
	set accountLower to my lowerText(accountName)
	repeat with pairItem in accountSpecificSenderExact
		if accountLower is my lowerText(item 1 of pairItem) then return item 2 of pairItem
	end repeat
	return {}
end accountSpecificList

on shouldProcessAccount(accountName)
	return my listContainsMatch(targetAccounts, my lowerText(accountName))
end shouldProcessAccount

on shouldMoveMessage(accountName, senderLine, subjectLine)
	set senderEmail to my extractSenderEmail(senderLine)
	set subjectLower to my lowerText(subjectLine)
	if my listContainsMatch(globalSenderExact, senderEmail) then return true
	if my listContainsFragment(globalSenderContains, senderEmail) then return true
	if my listContainsFragment(globalSubjectContains, subjectLower) then return true
	set accountList to my accountSpecificList(accountName)
	if my listContainsMatch(accountList, senderEmail) then return true
	return false
end shouldMoveMessage

on ensureUselessMailbox(acc)
	tell application "Mail"
		set accountMailboxes to every mailbox of acc
		repeat with mb in accountMailboxes
			try
				if (name of mb as text) is "Useless" then return mb
			end try
		end repeat
		return (make new mailbox at acc with properties {name:"Useless"})
	end tell
end ensureUselessMailbox

on ensureLocalUselessMailbox(accountName)
	set localBoxName to "Useless-" & accountName
	tell application "Mail"
		set allBoxes to every mailbox
		repeat with mb in allBoxes
			try
				if (name of mb as text) is localBoxName then return mb
			end try
		end repeat
		return (make new mailbox with properties {name:localBoxName})
	end tell
end ensureLocalUselessMailbox

on deleteInboxCopies(inboxMailbox, msgId)
	set removedCount to 0
	set remainingCount to 0
	tell application "Mail"
		try
			set inboxCopies to (messages of inboxMailbox whose message id is msgId)
		on error
			set inboxCopies to {}
		end try
		set copyCount to count inboxCopies
		if copyCount > 0 then
			repeat with ix from copyCount to 1 by -1
				try
					delete (item ix of inboxCopies)
					set removedCount to removedCount + 1
				end try
			end repeat
		end if
		try
			set remainingCount to count of (messages of inboxMailbox whose message id is msgId)
		on error
			set remainingCount to 0
		end try
	end tell
	return {removedCount, remainingCount}
end deleteInboxCopies

on run argv
	set nowDate to current date
	set runAccountFilter to ""
	set effectiveLookbackDays to lookbackDays
	if (count of argv) ≥ 1 then set runAccountFilter to my lowerText(item 1 of argv)
	if (count of argv) ≥ 2 then
		try
			set effectiveLookbackDays to (item 2 of argv) as integer
		end try
	end if
	set movedCount to 0
	set deletedCount to 0
	set fallbackCount to 0
	set noopCount to 0
	set scannedCount to 0
	set matchedCount to 0
	set reportLines to {}
	do shell script "rm -f " & quoted form of logPath
	my appendLog("start lookbackDays=" & effectiveLookbackDays & " chunkDays=" & chunkDays & " accountFilter=" & runAccountFilter)
	tell application "Mail"
		set accountList to every account
	end tell
	repeat with acc in accountList
		tell application "Mail"
			set accName to name of acc as text
			set inboxes to (every mailbox of acc whose name is "INBOX" or name is "Inbox")
		end tell
		if runAccountFilter is not "" and my lowerText(accName) is not runAccountFilter then
			my appendLog("skip_account " & accName)
		else if my shouldProcessAccount(accName) is false then
			my appendLog("skip_account " & accName)
		else
			my appendLog("begin_account " & accName & " inboxes=" & (count inboxes))
			set accountMoved to 0
				if (count inboxes) is 0 then
					set end of reportLines to (accName & ": no inbox")
				else
					set targetMailbox to my ensureUselessMailbox(acc)
					set fallbackMailbox to my ensureLocalUselessMailbox(accName)
					repeat with inboxMailbox in inboxes
						set processedDays to 0
						repeat while processedDays < effectiveLookbackDays
							set windowEnd to nowDate - (processedDays * days)
							set nextProcessedDays to processedDays + chunkDays
							if nextProcessedDays > effectiveLookbackDays then set nextProcessedDays to effectiveLookbackDays
						set windowStart to nowDate - (nextProcessedDays * days)
						try
							tell application "Mail"
								set msgList to (messages of inboxMailbox whose date received ≥ windowStart and date received < windowEnd)
							end tell
						on error
							set msgList to {}
						end try
							my appendLog("scan_mailbox " & accName & " windowDays=" & processedDays & "-" & nextProcessedDays & " messages=" & (count msgList))
							-- Process newest first by iterating backward through the mailbox message list.
							repeat with i from (count msgList) to 1 by -1
								set m to item i of msgList
								try
									tell application "Mail"
									set msgId to message id of m as text
										set senderLine to sender of m as text
										set subjectLine to subject of m as text
										set receivedLine to date received of m as text
									end tell
									set scannedCount to scannedCount + 1
									if my shouldMoveMessage(accName, senderLine, subjectLine) then
										set matchedCount to matchedCount + 1
										tell application "Mail"
											move m to targetMailbox
										end tell
										set landedCount to 0
										try
										tell application "Mail"
											set landedCount to count of (messages of targetMailbox whose message id is msgId)
											end tell
										on error
											set landedCount to 0
										end try
										set usedFallback to false
										if landedCount = 0 then
											tell application "Mail"
												move m to fallbackMailbox
											end tell
											try
												tell application "Mail"
													set landedCount to count of (messages of fallbackMailbox whose message id is msgId)
												end tell
											on error
												set landedCount to 0
											end try
											if landedCount > 0 then
												set usedFallback to true
												set fallbackCount to fallbackCount + 1
											end if
										end if
										if landedCount > 0 then
											set movedCount to movedCount + 1
											set accountMoved to accountMoved + 1
											set deleteResult to my deleteInboxCopies(inboxMailbox, msgId)
											set removedFromInbox to item 1 of deleteResult
											set remainingInInbox to item 2 of deleteResult
											set deletedCount to deletedCount + removedFromInbox
											set destLabel to "account_useless"
											if usedFallback then set destLabel to "local_fallback"
											my appendLog("moved " & accName & " | dest=" & destLabel & " | inbox_deleted=" & removedFromInbox & " | inbox_remaining=" & remainingInInbox & " | " & receivedLine & " | " & senderLine & " | " & subjectLine)
										else
											set noopCount to noopCount + 1
											my appendLog("move_noop " & accName & " | " & receivedLine & " | " & senderLine & " | " & subjectLine)
										end if
									end if
								end try
							end repeat
							my appendLog("window_done " & accName & " windowDays=" & processedDays & "-" & nextProcessedDays & " scanned_total=" & scannedCount & " matched_total=" & matchedCount & " moved_total=" & movedCount & " deleted_total=" & deletedCount & " fallback_total=" & fallbackCount & " noop_total=" & noopCount)
							set processedDays to nextProcessedDays
						end repeat
					end repeat
					set end of reportLines to (accName & ": moved " & accountMoved)
				end if
			my appendLog("end_account " & accName & " moved=" & accountMoved)
		end if
	end repeat
	set AppleScript's text item delimiters to linefeed
	set reportText to reportLines as text
	set AppleScript's text item delimiters to ""
	my appendLog("done moved_total=" & movedCount & " deleted_total=" & deletedCount & " fallback_total=" & fallbackCount & " noop_total=" & noopCount)
	return "Moved total: " & movedCount & linefeed & "Deleted from inbox: " & deletedCount & linefeed & "Fallback moved: " & fallbackCount & linefeed & "No-op moves: " & noopCount & linefeed & reportText
end run
