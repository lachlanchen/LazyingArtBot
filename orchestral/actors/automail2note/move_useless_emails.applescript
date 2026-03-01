use scripting additions

property globalSenderExact : {"its_boc@bochk.com", "e-statement@bochk.com", "ealert@bochk.com", "no_reply@stmt.futuhk.com", "no_reply@notification.futuhk.com", "enotices.daily.digest@hku.hk", "noreply@medium.com", "noreply@news.paypal.com", "notify@mox.com", "no-reply@mailer.mox.com"}
property globalSenderContains : {"googlealerts"}
property globalSubjectContains : {"daily digest", "e-statement", "new mox account statement available", "direct payment successful", "money transfer unsuccessful", "paypal credit", "google alert"}
property accountSpecificSenderExact : {{"lachen@connect.hku.hk", {"enotices.daily.digest@hku.hk"}}}
property lookbackDays : 7
property maxMovesTotal : 80
property maxMovesPerAccount : 30
property logPath : "/tmp/move_useless_emails.log"

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

on listContainsMatch(theList, valueText)
	repeat with itemText in theList
		if valueText is (itemText as text) then return true
	end repeat
	return false
end listContainsMatch

on listContainsFragment(theList, valueText)
	repeat with itemText in theList
		set needle to itemText as text
		if needle is not "" and valueText contains needle then return true
	end repeat
	return false
end listContainsFragment

on accountSpecificList(accountName)
	set accountLower to my lowerText(accountName)
	repeat with pairItem in accountSpecificSenderExact
		set pairAccount to item 1 of pairItem
		if accountLower is my lowerText(pairAccount) then return item 2 of pairItem
	end repeat
	return {}
end accountSpecificList

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

on appendLog(lineText)
	do shell script "printf '%s %s\\n' " & quoted form of (do shell script "date '+%Y-%m-%d %H:%M:%S'") & quoted form of lineText & " >> " & quoted form of logPath
end appendLog

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

on run argv
	set movedCount to 0
	set reportLines to {}
	set cutoffDate to (current date) - (lookbackDays * days)
	set accountFilter to ""
	if (count of argv) ≥ 1 then set accountFilter to my lowerText(item 1 of argv)
	do shell script "rm -f " & quoted form of logPath
	my appendLog("start lookbackDays=" & lookbackDays & " maxMovesTotal=" & maxMovesTotal & " maxMovesPerAccount=" & maxMovesPerAccount & " accountFilter=" & accountFilter)
	tell application "Mail"
		set accountList to every account
	end tell
	repeat with acc in accountList
		if movedCount ≥ maxMovesTotal then exit repeat
		tell application "Mail"
			set accName to name of acc as text
			set inboxes to (every mailbox of acc whose name is "INBOX" or name is "Inbox")
		end tell
		if accountFilter is not "" and my lowerText(accName) is not accountFilter then
			my appendLog("skip_account " & accName)
		else
			my appendLog("begin_account " & accName & " inboxes=" & (count inboxes))
		if (count inboxes) is 0 then
			set end of reportLines to (accName & ": no inbox")
			my appendLog("no_inbox " & accName)
		else
			set targetMailbox to my ensureUselessMailbox(acc)
			set accountMoved to 0
			repeat with inboxMailbox in inboxes
				try
					tell application "Mail"
						set msgList to (messages of inboxMailbox whose date received >= cutoffDate)
					end tell
				on error
					set msgList to {}
				end try
				my appendLog("scan_mailbox " & accName & " messages=" & (count msgList))
				repeat with m in msgList
					if movedCount ≥ maxMovesTotal then exit repeat
					if accountMoved ≥ maxMovesPerAccount then exit repeat
					try
						tell application "Mail"
							set senderLine to sender of m as text
							set subjectLine to subject of m as text
						end tell
						if my shouldMoveMessage(accName, senderLine, subjectLine) then
							tell application "Mail"
								move m to targetMailbox
							end tell
							set movedCount to movedCount + 1
							set accountMoved to accountMoved + 1
						end if
					end try
				end repeat
			end repeat
			set end of reportLines to (accName & ": moved " & accountMoved)
			my appendLog("end_account " & accName & " moved=" & accountMoved)
		end if
		end if
	end repeat
	set AppleScript's text item delimiters to linefeed
	set reportText to reportLines as text
	set AppleScript's text item delimiters to ""
	my appendLog("done moved_total=" & movedCount)
	return "Moved total: " & movedCount & linefeed & reportText
end run
