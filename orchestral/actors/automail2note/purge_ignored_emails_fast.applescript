use framework "Foundation"
use scripting additions

property ignoreConfig : missing value
property ignorePath : missing value
property verboseMode : true
property preferMoveToUseless : false
property opTimeoutSeconds : 60
property progressEvery : 200
property delayEvery : 50
property delaySeconds : 0.1
property stopAfterOlderStreak : 200

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

on ensureIgnoreLoaded()
  if ignoreConfig is not missing value then return
  if ignorePath is missing value then
    set ignorePath to (POSIX path of ((path to home folder) as text)) & ".openclaw/workspace/automation/data/automail2note/ignore_lists/mail_ignore_list.json"
  end if
  set txt to my readFileUTF8(ignorePath)
  set ignoreConfig to my parseJSON(txt)
end ensureIgnoreLoaded

on listKey(obj, k)
  set v to obj's objectForKey_(k)
  if v is missing value then return {}
  try
    return v as list
  on error
    return {}
  end try
end listKey

on dictKey(obj, k)
  set v to obj's objectForKey_(k)
  if v is missing value then return missing value
  return v
end dictKey

on findMailboxByName(acc, boxName)
  tell application "Mail"
    try
      set matches to (every mailbox of acc whose name is boxName)
      if (count matches) > 0 then return item 1 of matches
    end try
  end tell
  return missing value
end findMailboxByName

on extractSenderEmail(senderLine)
  set s to my lowerText(senderLine as text)
  try
    set openPos to (offset of "<" in s)
    set closePos to (offset of ">" in s)
    if openPos > 0 and closePos > openPos then
      return text (openPos + 1) thru (closePos - 1) of s
    end if
  end try
  return s
end extractSenderEmail

on containsFragment(fragList, hayLower)
  repeat with sub in fragList
    set needle to my lowerText(sub as text)
    if needle is not "" and hayLower contains needle then return true
  end repeat
  return false
end containsFragment

on shouldDelete(exactSet, senderContains, subjectContains, senderLine, subjectLine)
  set senderEmail to my extractSenderEmail(senderLine)
  set senderLower to my lowerText(senderEmail)
  set subjectLower to my lowerText(subjectLine as text)

  if (exactSet's containsObject_(senderLower)) as boolean then return true
  if my containsFragment(senderContains, senderLower) then return true
  if my containsFragment(subjectContains, subjectLower) then return true
  return false
end shouldDelete

on run argv
  my ensureIgnoreLoaded()

  if (count of argv) ≥ 1 then
    set ignorePath to item 1 of argv
    set ignoreConfig to missing value
    my ensureIgnoreLoaded()
  end if

  my logLine("ignore_path=" & ignorePath)

  set senderExactGlobal to my listKey(ignoreConfig, "sender_exact")
  set senderContains to my listKey(ignoreConfig, "sender_contains")
  set subjectContains to my listKey(ignoreConfig, "subject_contains")
  set acctExactMap to my dictKey(ignoreConfig, "account_sender_exact")

  set accountFilter to ""
  if (count of argv) ≥ 2 then
    set accountFilter to my lowerText(item 2 of argv)
  end if

  set lookbackDays to 30
  if (count of argv) ≥ 3 then
    try
      set lookbackDays to (item 3 of argv) as integer
    end try
  end if
  set cutoffDate to (current date) - (lookbackDays * days)

  my logLine("mode=linear account_filter=" & accountFilter & " lookbackDays=" & lookbackDays)

  set totalScanned to 0
  set totalMatched to 0
  set totalDeleted to 0
  set totalErrors to 0

  set accountList to {}
  try
    with timeout of opTimeoutSeconds seconds
      tell application "Mail" to set accountList to every account
    end timeout
  on error errMsg number errNum
    my logLine("mail_error stage=list_accounts code=" & errNum & " msg=" & errMsg)
    return
  end try

  repeat with acc in accountList
    set accName to ""
    try
      with timeout of opTimeoutSeconds seconds
        tell application "Mail" to set accName to name of acc as text
      end timeout
    on error
      set accName to ""
    end try

    set accKey to my lowerText(accName)
    if accountFilter is not "" and accKey is not accountFilter then
      my logLine("skip_account " & accName)
    else
      my logLine("account=" & accName)

      set acctExactList to {}
      if acctExactMap is not missing value then
        set v to acctExactMap's objectForKey_(accKey)
        if v is not missing value then
          try
            set acctExactList to v as list
          end try
        end if
      end if

      -- Build per-account exact set: global + account-specific
      set exactSet to current application's NSMutableSet's alloc()'s init()
      repeat with e in senderExactGlobal
        exactSet's addObject_(my lowerText(e as text))
      end repeat
      repeat with e in acctExactList
        exactSet's addObject_(my lowerText(e as text))
      end repeat
      set inboxes to {}
      try
        with timeout of opTimeoutSeconds seconds
          tell application "Mail" to set inboxes to (every mailbox of acc whose name is "INBOX" or name is "Inbox")
        end timeout
      on error errMsg number errNum
        my logLine("mail_error stage=list_inboxes account=" & accName & " code=" & errNum & " msg=" & errMsg)
        set inboxes to {}
      end try

      repeat with mb in inboxes
        set mbName to ""
        try
          with timeout of opTimeoutSeconds seconds
            tell application "Mail" to set mbName to name of mb as text
          end timeout
        on error
          set mbName to ""
        end try
        my logLine("mailbox=" & mbName)

        set msgCount to 0
        try
          with timeout of opTimeoutSeconds seconds
            tell application "Mail" to set msgCount to (count of messages of mb)
          end timeout
        on error errMsg number errNum
          my logLine("mail_error stage=count_messages account=" & accName & " mailbox=" & mbName & " code=" & errNum & " msg=" & errMsg)
          set msgCount to 0
        end try

        my logLine("scan messages=" & msgCount)
        set olderStreak to 0

        repeat with i from msgCount to 1 by -1
          set m to missing value
          try
            with timeout of opTimeoutSeconds seconds
              tell application "Mail" to set m to (message i of mb)
            end timeout
          on error errMsg number errNum
            set totalErrors to totalErrors + 1
            my logLine("mail_error stage=get_message account=" & accName & " mailbox=" & mbName & " idx=" & i & " code=" & errNum & " msg=" & errMsg)
            if errNum is -1712 then exit repeat
          end try
          if m is missing value then
            if (totalScanned mod delayEvery is 0) then delay delaySeconds
          else
            set totalScanned to totalScanned + 1

            set senderLine to ""
            set subjectLine to ""
            set receivedDate to missing value
            try
              with timeout of opTimeoutSeconds seconds
                tell application "Mail"
                  set senderLine to sender of m as text
                  set subjectLine to subject of m as text
                  set receivedDate to date received of m
                end tell
              end timeout
            on error errMsg number errNum
              set totalErrors to totalErrors + 1
              my logLine("mail_error stage=read_message account=" & accName & " mailbox=" & mbName & " idx=" & i & " code=" & errNum & " msg=" & errMsg)
              set senderLine to ""
              set subjectLine to ""
              set receivedDate to missing value
            end try

            if receivedDate is not missing value then
              try
                if receivedDate < cutoffDate then
                  set olderStreak to olderStreak + 1
                else
                  set olderStreak to 0
                end if
              on error
                set olderStreak to 0
              end try
            end if

            if olderStreak ≥ stopAfterOlderStreak then
              my logLine("stop_old_streak account=" & accName & " mailbox=" & mbName & " streak=" & olderStreak & " cutoffDays=" & lookbackDays)
              exit repeat
            end if

            if my shouldDelete(exactSet, senderContains, subjectContains, senderLine, subjectLine) then
              set totalMatched to totalMatched + 1
              try
                with timeout of opTimeoutSeconds seconds
                  tell application "Mail" to delete m
                end timeout
                set totalDeleted to totalDeleted + 1
                if verboseMode and (totalDeleted mod 25 is 0) then my logLine("deleted deleted=" & totalDeleted & " scanned=" & totalScanned & " last_sender=" & senderLine)
              on error errMsg number errNum
                set totalErrors to totalErrors + 1
                my logLine("delete_error code=" & errNum & " msg=" & errMsg & " sender=" & senderLine)
                -- If Mail scripting connection is invalid, bail quickly to avoid crashing Mail.
                if errNum is -609 then
                  my logLine("abort reason=connection_invalid")
                  exit repeat
                end if
              end try
            end if

            if (totalScanned mod progressEvery is 0) then
              my logLine("progress scanned=" & totalScanned & " matched=" & totalMatched & " deleted=" & totalDeleted & " errors=" & totalErrors)
            end if
            if (totalScanned mod delayEvery is 0) then
              delay delaySeconds
            end if
          end if
        end repeat

      end repeat
    end if
  end repeat

  my logLine("done scanned=" & totalScanned & " matched=" & totalMatched & " deleted=" & totalDeleted & " errors=" & totalErrors)
end run
