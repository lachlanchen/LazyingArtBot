use scripting additions

property senderExact : {"its_boc@bochk.com", "e-statement@bochk.com", "ealert@bochk.com", "no_reply@stmt.futuhk.com", "no_reply@notification.futuhk.com", "noreply@medium.com", "notifications-noreply@linkedin.com", "updates-noreply@linkedin.com", "noreply@news.paypal.com", "noreply@mail.justpark.com", "news_en-gb@avis-comms.international", "trip.com@newsletter.trip.com", "en_flight_noreply@trip.com", "no-reply@researchgatemail.net", "enotices.daily.digest@hku.hk", "notify@mox.com", "no-reply@mailer.mox.com", "st@newsletter.st.com", "recommends@ted.com", "notifications@stripe.com", "system-sg@notice.alibabacloud.com"}
property senderContains : {"googlealerts", "@newsletter.", "newsletter@", "digest@"}
property subjectContains : {"daily digest", "weekly digest", "e-statement", "google alert", "newsletter", "deals", "promotion", "cashback earned", "direct payment successful", "money transfer unsuccessful", "new account statement available", "pay in 4", "paypal credit", "new mox account statement available", "trip coins balance changed", "internet banking txn notification", "securities daily statement"}
property targetAccounts : {"lachen@connect.hku.hk", "lachlan.mia.chan", "lachlan.mia.chan@gmail.com", "lachlan.miao.chen@gmail.com"}
property accountSpecificSenderExact : {{"lachen@connect.hku.hk", {"enotices.daily.digest@hku.hk", "careers@cedars.hku.hk", "cedars-cybercampus@hku.hk", "hkuip@hku.hk", "ivanhwc@hku.hk", "psychiatry-events@hku.hk", "events@mail.opticacommunications.org", "events@eee.hku.hk", "enggfac@hku.hk", "cedarspe@hku.hk", "ip0122@hku.hk", "semin@hku.hk", "garyhkl@hku.hk", "hkutec@hku.hk", "libis@hku.hk", "pgsa@connect.hku.hk", "kyduen@hku.hk", "geogevnt@hku.hk", "eduert@hku.hk", "cultural@connect.hku.hk", "ylaa@connect.hku.hk", "enggrpg@hku.hk"}}}
property logPath : "/tmp/purge_useless_to_trash.log"
property progressEvery : 200

on normalizedText(rawText)
	if rawText is missing value then return ""
	try
		return rawText as text
	on error
		return ""
	end try
end normalizedText

on lowerText(rawText)
	return do shell script "printf %s " & quoted form of (my normalizedText(rawText)) & " | tr '[:upper:]' '[:lower:]'"
end lowerText

on appendLog(lineText)
	do shell script "printf '%s %s\\n' " & quoted form of (do shell script "date '+%Y-%m-%d %H:%M:%S'") & quoted form of lineText & " >> " & quoted form of logPath
end appendLog

on listContainsMatch(theList, valueText)
	repeat with itemText in theList
		if valueText is my lowerText(itemText as text) then return true
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
	set senderLower to my lowerText(senderLine)
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

on shouldDeleteMessage(accountName, senderLine, subjectLine)
	set senderEmail to my extractSenderEmail(senderLine)
	set subjectLower to my lowerText(subjectLine)
	if my listContainsMatch(senderExact, senderEmail) then return true
	if my listContainsFragment(senderContains, senderEmail) then return true
	if my listContainsFragment(subjectContains, subjectLower) then return true
	set accountList to my accountSpecificList(accountName)
	if my listContainsMatch(accountList, senderEmail) then return true
	return false
end shouldDeleteMessage

on run argv
	set runAccountFilter to ""
	set lookbackDays to 3650
	if (count of argv) ≥ 1 then set runAccountFilter to my lowerText(item 1 of argv)
	if (count of argv) ≥ 2 then
		try
			set lookbackDays to (item 2 of argv) as integer
		end try
	end if
	set cutoffDate to (current date) - (lookbackDays * days)
	set scannedTotal to 0
	set matchedTotal to 0
	set deletedTotal to 0
	set accountReports to {}
	do shell script "rm -f " & quoted form of logPath
	my appendLog("start mode=trash lookbackDays=" & lookbackDays & " accountFilter=" & runAccountFilter)
	tell application "Mail"
		set accountList to every account
	end tell
	repeat with acc in accountList
		tell application "Mail"
			set accName to name of acc as text
		end tell
		if runAccountFilter is not "" and my lowerText(accName) is not runAccountFilter then
			my appendLog("skip_account " & accName)
		else if my shouldProcessAccount(accName) is false then
			my appendLog("skip_account " & accName)
		else
			tell application "Mail"
				set inboxes to (every mailbox of acc whose name is "INBOX" or name is "Inbox")
			end tell
			my appendLog("begin_account " & accName & " inboxes=" & (count inboxes))
			set scannedAccount to 0
			set matchedAccount to 0
			set deletedAccount to 0
			repeat with inboxMailbox in inboxes
				try
					tell application "Mail"
						set msgList to (messages of inboxMailbox whose date received >= cutoffDate)
					end tell
				on error
					set msgList to {}
				end try
				set msgCount to count msgList
				my appendLog("scan_mailbox " & accName & " messages=" & msgCount)
				repeat with i from msgCount to 1 by -1
					set m to item i of msgList
					try
						tell application "Mail"
							set senderLine to sender of m as text
							set subjectLine to subject of m as text
							set receivedLine to date received of m as text
						end tell
					on error
						set senderLine to ""
						set subjectLine to ""
						set receivedLine to ""
					end try
					set scannedTotal to scannedTotal + 1
					set scannedAccount to scannedAccount + 1
					if my shouldDeleteMessage(accName, senderLine, subjectLine) then
						set matchedTotal to matchedTotal + 1
						set matchedAccount to matchedAccount + 1
						try
							tell application "Mail"
								delete m
							end tell
							set deletedTotal to deletedTotal + 1
							set deletedAccount to deletedAccount + 1
							if deletedAccount mod 25 is 0 then
								my appendLog("deleted account=" & accName & " deletedAccount=" & deletedAccount & " scannedAccount=" & scannedAccount & " | " & receivedLine & " | " & senderLine & " | " & subjectLine)
							end if
						on error errMsg number errNum
							my appendLog("delete_error account=" & accName & " code=" & errNum & " error=" & errMsg & " | " & senderLine & " | " & subjectLine)
						end try
					end if
					if scannedTotal mod progressEvery is 0 then
						my appendLog("progress scannedTotal=" & scannedTotal & " matchedTotal=" & matchedTotal & " deletedTotal=" & deletedTotal)
					end if
				end repeat
			end repeat
			my appendLog("end_account " & accName & " scanned=" & scannedAccount & " matched=" & matchedAccount & " deleted=" & deletedAccount)
			set end of accountReports to (accName & ": scanned " & scannedAccount & ", matched " & matchedAccount & ", deleted " & deletedAccount)
		end if
	end repeat
	my appendLog("done scannedTotal=" & scannedTotal & " matchedTotal=" & matchedTotal & " deletedTotal=" & deletedTotal)
	set AppleScript's text item delimiters to linefeed
	set reportText to accountReports as text
	set AppleScript's text item delimiters to ""
	return "Done. scanned=" & scannedTotal & " matched=" & matchedTotal & " deleted=" & deletedTotal & linefeed & reportText
end run
