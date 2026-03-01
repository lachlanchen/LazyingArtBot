#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="${AUTOMAIL_DATA_DIR:-$HOME/.openclaw/workspace/automation/data/automail2note}"
SENDER_LIST_DIR="${DATA_DIR}/non_important_senders"
SENDER_LIST_PATH="${1:-$SENDER_LIST_DIR/hku_non_important_senders_2026-02-17.txt}"
ACCOUNT_NAME="${HKU_CLEANUP_ACCOUNT:-lachen@connect.hku.hk}"
MAILBOX_NAME="${HKU_CLEANUP_MAILBOX:-Inbox}"
DRY_RUN="${HKU_CLEANUP_DRY_RUN:-0}"
PROGRESS_EVERY="${HKU_CLEANUP_PROGRESS_EVERY:-100}"
LOG_FILE="${HKU_CLEANUP_LOG:-$HOME/.openclaw/workspace/logs/hku_sender_cleanup.log}"

mkdir -p "$(dirname "$LOG_FILE")"

if [[ ! -f "$SENDER_LIST_PATH" ]]; then
  echo "sender list file not found: $SENDER_LIST_PATH" | tee -a "$LOG_FILE"
  exit 1
fi

{
  echo "$(date '+%Y-%m-%d %H:%M:%S') start account=$ACCOUNT_NAME mailbox=$MAILBOX_NAME dry_run=$DRY_RUN sender_list=$SENDER_LIST_PATH"

  osascript - "$SENDER_LIST_PATH" "$ACCOUNT_NAME" "$MAILBOX_NAME" "$DRY_RUN" "$PROGRESS_EVERY" <<'APPLESCRIPT'
use framework "Foundation"
use scripting additions

on lowerText(t)
  return ((current application's NSString's stringWithString_(t))'s lowercaseString()) as text
end lowerText

on trimText(t)
  set ns to current application's NSString's stringWithString_(t)
  set ws to current application's NSCharacterSet's whitespaceAndNewlineCharacterSet()
  return (ns's stringByTrimmingCharactersInSet_(ws)) as text
end trimText

on stripEdgePunctuation(t)
  set s to t as text
  set punct to "<>[](){}\"',;:"
  repeat while s is not ""
    set c to character 1 of s
    if punct contains c then
      if (length of s) = 1 then
        set s to ""
      else
        set s to text 2 thru -1 of s
      end if
    else
      exit repeat
    end if
  end repeat
  repeat while s is not ""
    set c to character -1 of s
    if punct contains c then
      if (length of s) = 1 then
        set s to ""
      else
        set s to text 1 thru -2 of s
      end if
    else
      exit repeat
    end if
  end repeat
  return s
end stripEdgePunctuation

on extractSenderEmail(senderLine)
  set s to my lowerText(senderLine as text)
  set openPos to offset of "<" in s
  set closePos to offset of ">" in s
  if openPos > 0 and closePos > openPos then
    return my trimText(text (openPos + 1) thru (closePos - 1) of s)
  end if
  set tokenList to words of s
  repeat with tok in tokenList
    set t to my stripEdgePunctuation(tok as text)
    if t contains "@" then return t
  end repeat
  return my trimText(s)
end extractSenderEmail

on loadSenderSet(senderListPath)
  set nsStr to current application's NSString's stringWithContentsOfFile_encoding_error_(senderListPath, current application's NSUTF8StringEncoding, missing value)
  if nsStr is missing value then error "failed_read_sender_list=" & senderListPath

  set lineArray to nsStr's componentsSeparatedByCharactersInSet_(current application's NSCharacterSet's newlineCharacterSet())
  set senderSet to current application's NSMutableSet's alloc()'s init()

  repeat with lineObj in lineArray
    set lineText to my trimText(lineObj as text)
    if lineText is not "" then
      if lineText does not start with "#" then
        set emailText to my lowerText(lineText)
        if emailText contains "@" then senderSet's addObject_(emailText)
      end if
    end if
  end repeat
  return senderSet
end loadSenderSet

on run argv
  if (count of argv) < 5 then error "expected args: sender_list account mailbox dry_run progress_every"

  set senderListPath to item 1 of argv
  set accountName to item 2 of argv
  set mailboxName to item 3 of argv
  set dryRunFlag to item 4 of argv
  set progressEvery to 100
  try
    set progressEvery to (item 5 of argv) as integer
  end try
  if progressEvery < 1 then set progressEvery to 100

  set dryRun to false
  if dryRunFlag is "1" then set dryRun to true

  set senderSet to my loadSenderSet(senderListPath)
  set senderCount to (senderSet's |count|()) as integer
  log "sender_list_loaded count=" & senderCount

  set scanned to 0
  set matched to 0
  set deleted to 0
  set errorsCount to 0

  tell application "Mail"
    set targetAccount to missing value
    repeat with a in accounts
      if (name of a as text) is accountName then
        set targetAccount to a
        exit repeat
      end if
    end repeat
    if targetAccount is missing value then error "account_not_found=" & accountName

    set targetMailbox to missing value
    try
      set targetMailbox to mailbox mailboxName of targetAccount
    on error
      repeat with mb in mailboxes of targetAccount
        if my lowerText(name of mb as text) is my lowerText(mailboxName) then
          set targetMailbox to mb
          exit repeat
        end if
      end repeat
    end try
    if targetMailbox is missing value then error "mailbox_not_found=" & mailboxName

    set msgCount to count of messages of targetMailbox
    log "scan_begin account=" & accountName & " mailbox=" & mailboxName & " messages=" & msgCount

    repeat with i from msgCount to 1 by -1
      set m to missing value
      try
        set m to message i of targetMailbox
      on error errMsg number errNum
        set errorsCount to errorsCount + 1
        log "read_error idx=" & i & " code=" & errNum & " msg=" & errMsg
      end try

      if m is not missing value then
        set scanned to scanned + 1
        set senderLine to ""
        set subjectLine to ""
        try
          set senderLine to sender of m as text
          set subjectLine to subject of m as text
        on error errMsg number errNum
          set errorsCount to errorsCount + 1
          log "field_error idx=" & i & " code=" & errNum & " msg=" & errMsg
        end try

        set senderEmail to my extractSenderEmail(senderLine)
        if (senderSet's containsObject_(senderEmail)) as boolean then
          set matched to matched + 1
          if dryRun then
            if matched ≤ 30 then log "dry_match sender=" & senderEmail & " subject=" & subjectLine
          else
            try
              delete m
              set deleted to deleted + 1
              if (deleted mod 25) is 0 then log "deleted_count=" & deleted
            on error errMsg number errNum
              set errorsCount to errorsCount + 1
              log "delete_error idx=" & i & " sender=" & senderEmail & " code=" & errNum & " msg=" & errMsg
            end try
          end if
        end if

        if (scanned mod progressEvery) is 0 then
          log "progress scanned=" & scanned & " matched=" & matched & " deleted=" & deleted & " errors=" & errorsCount
        end if
      end if
    end repeat
  end tell

  log "done scanned=" & scanned & " matched=" & matched & " deleted=" & deleted & " errors=" & errorsCount & " dry_run=" & dryRunFlag
  return "scanned=" & scanned & " matched=" & matched & " deleted=" & deleted & " errors=" & errorsCount & " dry_run=" & dryRunFlag
end run
APPLESCRIPT

  rc=$?
  echo "$(date '+%Y-%m-%d %H:%M:%S') done rc=$rc"
  exit $rc
} 2>&1 | tee -a "$LOG_FILE"
