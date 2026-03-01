use framework "Foundation"
use scripting additions

property ignoreConfig : missing value
property ignorePath : missing value
property verboseMode : true
property doDelete : true
property preferMoveToUseless : false

on logLine(s)
  try
    set ts to do shell script "date '+%Y-%m-%d %H:%M:%S'"
  on error
    set ts to ""
  end try
  if ts is "" then
    log s
  else
    log (ts & " " & s)
  end if
end logLine

on readFileUTF8(posixPath)
  set nsStr to current application's NSString's stringWithContentsOfFile_encoding_error_(posixPath, current application's NSUTF8StringEncoding, missing value)
  if nsStr is missing value then error "Failed to read file: " & posixPath
  return nsStr as text
end readFileUTF8

on parseJSON(textJSON)
  set nsStr to current application's NSString's stringWithString_(textJSON)
  set jsonData to nsStr's dataUsingEncoding_(current application's NSUTF8StringEncoding)
  set jErr to missing value
  set obj to current application's NSJSONSerialization's JSONObjectWithData_options_error_(jsonData, 0, reference to jErr)
  if jErr is not missing value then error (jErr's localizedDescription() as text)
  return obj
end parseJSON

on lowerText(t)
  return (current application's NSString's stringWithString_(t))'s lowercaseString() as text
end lowerText

on extractFirstEmail(senderText)
  set s to senderText as text
  set nsS to current application's NSString's stringWithString_(s)
  set pattern to "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}"
  set re to current application's NSRegularExpression's regularExpressionWithPattern_options_error_(pattern, current application's NSRegularExpressionCaseInsensitive, missing value)
  set m to re's firstMatchInString_options_range_(nsS, 0, {location:0, |length|:nsS's |length|()})
  if m is missing value then return ""
  set r to m's rangeAtIndex_(0)
  return (nsS's substringWithRange_(r)) as text
end extractFirstEmail

on listFrom(obj, keyName)
  set v to obj's valueForKey_(keyName)
  if v is missing value then return {}
  return v as list
end listFrom

on dictFrom(obj, keyName)
  set v to obj's valueForKey_(keyName)
  if v is missing value then return missing value
  return v
end dictFrom

on anyContains(hay, needles)
  set lh to my lowerText(hay)
  repeat with n in needles
    set ln to my lowerText(n as text)
    if ln is not "" then
      if lh contains ln then return true
    end if
  end repeat
  return false
end anyContains

on matchesIgnore(accountName, senderEmail, subjectText)
  set acctLower to my lowerText(accountName)
  set senderLower to my lowerText(senderEmail)

  set senderExact to my listFrom(ignoreConfig, "sender_exact")
  set senderContains to my listFrom(ignoreConfig, "sender_contains")
  set subjectContains to my listFrom(ignoreConfig, "subject_contains")

  if senderLower is not "" then
    repeat with e in senderExact
      if senderLower is my lowerText(e as text) then return true
    end repeat
  end if

  if senderLower is not "" then
    if my anyContains(senderLower, senderContains) then return true
  end if

  if subjectText is not "" then
    if my anyContains(subjectText, subjectContains) then return true
  end if

  set acctExactMap to my dictFrom(ignoreConfig, "account_sender_exact")
  if acctExactMap is not missing value then
    set acctList to acctExactMap's valueForKey_(acctLower)
    if acctList is not missing value then
      repeat with e in acctList as list
        if senderLower is my lowerText(e as text) then return true
      end repeat
    end if
  end if

  return false
end matchesIgnore

on ensureIgnoreLoaded()
  if ignoreConfig is not missing value then return
  if ignorePath is missing value then
    set ignorePath to (POSIX path of ((path to home folder) as text)) & ".openclaw/workspace/automation/data/automail2note/ignore_lists/mail_ignore_list.json"
  end if
  set txt to my readFileUTF8(ignorePath)
  set ignoreConfig to my parseJSON(txt)
end ensureIgnoreLoaded

on findMailboxByName(acc, boxName)
  tell application "Mail"
    try
      set matches to (every mailbox of acc whose name is boxName)
      if (count matches) > 0 then return item 1 of matches
    end try
  end tell
  return missing value
end findMailboxByName

on run argv
  my ensureIgnoreLoaded()

  set totalMatched to 0
  set totalMoved to 0
  set totalDeleted to 0

  if (count of argv) ≥ 1 then
    set ignorePath to item 1 of argv
    set ignoreConfig to missing value
    my ensureIgnoreLoaded()
  end if

  my logLine("ignore_path=" & ignorePath)

  tell application "Mail"
    set accs to every account
    repeat with acc in accs
      set accName to name of acc as text
      my logLine("account=" & accName)

      set uselessBox to missing value
      if preferMoveToUseless then set uselessBox to my findMailboxByName(acc, "Useless")

      set inboxes to (every mailbox of acc whose name is "INBOX" or name is "Inbox")
      repeat with mb in inboxes
        set mbName to name of mb as text
        my logLine("mailbox=" & mbName)

        try
          set msgList to messages of mb
        on error
          set msgList to {}
        end try

        set matchedMsgs to {}
        repeat with m in msgList
          try
            set subj to subject of m as text
          on error
            set subj to ""
          end try

          try
            set sndTxt to sender of m as text
          on error
            set sndTxt to ""
          end try

          set senderEmail to my extractFirstEmail(sndTxt)
          if senderEmail is "" then
            set senderEmail to sndTxt
          end if

          if my matchesIgnore(accName, senderEmail, subj) then
            set end of matchedMsgs to m
          end if
        end repeat

        set matchedCount to count of matchedMsgs
        if matchedCount is 0 then
          if verboseMode then my logLine("matched=0")
	        else
	          my logLine("matched=" & matchedCount)
	          set totalMatched to totalMatched + matchedCount
	          -- Mail is brittle with list-based move/delete. Process in batches and per-message.
	          set batchSize to 200
	          set i to 1
	          repeat while i ≤ matchedCount
	            set j to i + batchSize - 1
	            if j > matchedCount then set j to matchedCount
	            set batchMsgs to items i thru j of matchedMsgs
	            my logLine("batch=" & i & "-" & j & "/" & matchedCount)

	            if preferMoveToUseless and uselessBox is not missing value then
	              set movedInBatch to 0
	              repeat with bm in batchMsgs
	                try
	                  move bm to uselessBox
	                  set movedInBatch to movedInBatch + 1
	                on error errMsg number errNum
	                  my logLine("move_failed errNum=" & errNum)
	                end try
	              end repeat
	              set totalMoved to totalMoved + movedInBatch
	              my logLine("action=moved_to_useless count=" & movedInBatch)
	            else
	              if doDelete then
	                set deletedInBatch to 0
	                repeat with bm in batchMsgs
	                  try
	                    delete bm
	                    set deletedInBatch to deletedInBatch + 1
	                  on error errMsg number errNum
	                    my logLine("delete_failed errNum=" & errNum)
	                  end try
	                end repeat
	                set totalDeleted to totalDeleted + deletedInBatch
	                my logLine("action=deleted_to_trash count=" & deletedInBatch)
	              else
	                my logLine("action=skipped_delete")
	              end if
	            end if

	            set i to j + 1
	          end repeat
	        end if
      end repeat
    end repeat
  end tell

  my logLine("done total_matched=" & totalMatched & " total_moved=" & totalMoved & " total_deleted=" & totalDeleted)
end run
