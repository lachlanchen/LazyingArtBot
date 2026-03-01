#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: codex_refresh_ignore_list.sh [options]

Simplified daily loop:
- For each account
- For each day in lookback window
- Fetch that day's inbox messages with full content
- Ask Codex once per account/day to maintain a conservative ignore list

Options:
  --days <n>                 Number of days to scan backward (default: 7)
  --accounts <csv>           Restrict to account names (comma-separated)
  --ignore-file <path>       Ignore list JSON path
  --model <name>             Codex model override (default: gpt-5.3-codex)
  --confidence <float>       Min confidence to apply add/remove (default: 0.97)
  --dry-run                  Do not modify ignore file
  --skip-git-check           Pass --skip-git-repo-check to codex exec
  --no-known-useless         Do not pre-add known useless sender seeds
  -h, --help                 Show help
USAGE
}

ROOT="$HOME/.openclaw/workspace"
IGNORE_FILE="$ROOT/automation/mail_ignore_list.json"
LOG_DIR="$ROOT/logs"
DAYS=7
ACCOUNTS_CSV=""
MODEL="gpt-5.3-codex"
MIN_CONFIDENCE="0.97"
DRY_RUN=0
SKIP_GIT_CHECK=1
APPLY_KNOWN_USELESS=1

KNOWN_USELESS_SENDERS=(
  "notify@mox.com"
  "its_boc@bochk.com"
  "ealert@bochk.com"
  "no_reply@notification.futuhk.com"
)

while [ $# -gt 0 ]; do
  case "$1" in
    --days) DAYS="${2:-}"; shift ;;
    --accounts) ACCOUNTS_CSV="${2:-}"; shift ;;
    --ignore-file) IGNORE_FILE="${2:-}"; shift ;;
    --model) MODEL="${2:-}"; shift ;;
    --confidence) MIN_CONFIDENCE="${2:-}"; shift ;;
    --dry-run) DRY_RUN=1 ;;
    --skip-git-check) SKIP_GIT_CHECK=1 ;;
    --no-known-useless) APPLY_KNOWN_USELESS=0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

if ! command -v codex >/dev/null 2>&1; then
  echo "codex CLI not found in PATH." >&2
  exit 1
fi
if [ ! -f "$IGNORE_FILE" ]; then
  echo "Ignore file not found: $IGNORE_FILE" >&2
  exit 1
fi

mkdir -p "$LOG_DIR"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

RUN_ID="$(date +%Y%m%d-%H%M%S)"
RUN_LOG="$LOG_DIR/ignore-refresh-$RUN_ID.log"
RUN_ARTIFACT_DIR="$LOG_DIR/ignore-refresh-$RUN_ID"
mkdir -p "$RUN_ARTIFACT_DIR"

echo "run_id=$RUN_ID" | tee -a "$RUN_LOG"
echo "ignore_file=$IGNORE_FILE" | tee -a "$RUN_LOG"
echo "model=$MODEL reasoning=medium" | tee -a "$RUN_LOG"
echo "days=$DAYS min_confidence=$MIN_CONFIDENCE dry_run=$DRY_RUN" | tee -a "$RUN_LOG"
echo "artifact_dir=$RUN_ARTIFACT_DIR" | tee -a "$RUN_LOG"

slug() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9._-' '_'
}

if [ "$APPLY_KNOWN_USELESS" -eq 1 ]; then
  python3 - <<PY | tee -a "$RUN_LOG"
import json
path="$IGNORE_FILE"
dry=bool($DRY_RUN)
known=[s.strip().lower() for s in """$(printf "%s\n" "${KNOWN_USELESS_SENDERS[@]}")""".splitlines() if s.strip()]
data=json.load(open(path,encoding="utf-8"))
arr=data.setdefault("sender_exact",[])
existing={x.strip().lower() for x in arr if isinstance(x,str)}
added=[]
for sender in known:
    if sender not in existing:
        existing.add(sender)
        added.append(sender)
data["sender_exact"]=sorted(existing)
if not dry:
    with open(path,"w",encoding="utf-8") as f:
        json.dump(data,f,indent=2,ensure_ascii=False)
        f.write("\n")
print(f"known_useless_added={len(added)}")
for x in added:
    print(f"  + {x}")
PY
fi

ACCOUNTS_JSON="$TMP_DIR/accounts.json"
osascript <<'APPLESCRIPT' > "$ACCOUNTS_JSON"
use framework "Foundation"
set outList to {}
tell application "Mail"
  repeat with acc in every account
    set end of outList to (name of acc as text)
  end repeat
end tell
set jsonData to current application's NSJSONSerialization's dataWithJSONObject_options_error_(outList, 0, missing value)
set jsonString to current application's NSString's alloc()'s initWithData_encoding_(jsonData, current application's NSUTF8StringEncoding)
return jsonString as text
APPLESCRIPT

if [ -n "$ACCOUNTS_CSV" ]; then
  TARGET_ACCOUNTS_JSON="$(python3 - <<PY
import json
selected=[a.strip() for a in "$ACCOUNTS_CSV".split(",") if a.strip()]
print(json.dumps(selected))
PY
)"
else
  TARGET_ACCOUNTS_JSON="$(cat "$ACCOUNTS_JSON")"
fi

RESULT_SCHEMA="$TMP_DIR/result-schema.json"
cat > "$RESULT_SCHEMA" <<'JSON'
{
  "type": "object",
  "additionalProperties": false,
  "required": ["account", "day_offset", "add_account_sender_exact", "remove_account_sender_exact", "rationale"],
  "properties": {
    "account": { "type": "string" },
    "day_offset": { "type": "integer" },
    "add_account_sender_exact": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": ["email", "confidence", "reason"],
        "properties": {
          "email": { "type": "string" },
          "confidence": { "type": "number" },
          "reason": { "type": "string" }
        }
      }
    },
    "remove_account_sender_exact": {
      "type": "array",
      "items": { "type": "string" }
    },
    "rationale": { "type": "string" }
  }
}
JSON

fetch_account_day_messages() {
  local account_name="$1"
  local day_offset="$2"
  local out_file="$3"
  osascript - "$account_name" "$day_offset" <<'APPLESCRIPT' > "$out_file"
use framework "Foundation"
use scripting additions

on run argv
  set accountName to item 1 of argv
  set dayOffset to (item 2 of argv) as integer
  set dayStart to (current date)
  set time of dayStart to 0
  set dayStart to dayStart - (dayOffset * days)
  set dayEnd to dayStart + days

  set outList to {}
  tell application "Mail"
    set targetAccounts to (every account whose name is accountName)
    if (count targetAccounts) is 0 then
      set jsonData to current application's NSJSONSerialization's dataWithJSONObject_options_error_(outList, 0, missing value)
      set jsonString to current application's NSString's alloc()'s initWithData_encoding_(jsonData, current application's NSUTF8StringEncoding)
      return jsonString as text
    end if

    set acc to item 1 of targetAccounts
    set inboxes to (every mailbox of acc whose name is "INBOX" or name is "Inbox")
    repeat with mb in inboxes
      try
        set msgList to (messages of mb whose date received >= dayStart and date received < dayEnd)
      on error
        set msgList to {}
      end try
      repeat with m in msgList
        try
          set senderText to sender of m as text
          set subjectText to subject of m as text
          set dateText to date received of m as text
          set bodyText to content of m as text
          set msgidText to ""
          try
            set msgidText to message id of m as text
          end try
          set end of outList to {sender_text:senderText, subject_text:subjectText, received_text:dateText, body_text:bodyText, message_id_text:msgidText}
        end try
      end repeat
    end repeat
  end tell

  set jsonData to current application's NSJSONSerialization's dataWithJSONObject_options_error_(outList, 0, missing value)
  set jsonString to current application's NSString's alloc()'s initWithData_encoding_(jsonData, current application's NSUTF8StringEncoding)
  return jsonString as text
end run
APPLESCRIPT
}

python3 - <<PY > "$TMP_DIR/target_accounts.txt"
import json
for a in json.loads('''$TARGET_ACCOUNTS_JSON'''):
    if isinstance(a, str) and a.strip():
        print(a.strip())
PY

TOTAL_ACCOUNTS=0
PROCESSED_ACCOUNTS=0
SKIPPED_DAYS=0
FAILED_BATCHES=0
PROCESSED_BATCHES=0
TOTAL_MESSAGES=0

while IFS= read -r ACCOUNT; do
  [ -z "$ACCOUNT" ] && continue
  TOTAL_ACCOUNTS=$((TOTAL_ACCOUNTS + 1))
  echo "=== account: $ACCOUNT ===" | tee -a "$RUN_LOG"
  ACCOUNT_SLUG="$(slug "$ACCOUNT")"

  day=0
  while [ "$day" -lt "$DAYS" ]; do
    MSG_FILE="$TMP_DIR/messages-$ACCOUNT_SLUG-day$day.json"
    MSG_ARTIFACT="$RUN_ARTIFACT_DIR/messages-$ACCOUNT_SLUG-day$day.json"
    fetch_account_day_messages "$ACCOUNT" "$day" "$MSG_FILE"
    cp "$MSG_FILE" "$MSG_ARTIFACT"

    MSG_COUNT="$(python3 - <<PY
import json
print(len(json.load(open("$MSG_FILE",encoding="utf-8"))))
PY
)"

    if [ "$MSG_COUNT" -eq 0 ]; then
      SKIPPED_DAYS=$((SKIPPED_DAYS + 1))
      echo "day=$day messages=0 skip" | tee -a "$RUN_LOG"
      day=$((day + 1))
      continue
    fi

    TOTAL_MESSAGES=$((TOTAL_MESSAGES + MSG_COUNT))
    echo "day=$day messages=$MSG_COUNT file=$MSG_ARTIFACT" | tee -a "$RUN_LOG"

    OUT_FILE="$TMP_DIR/codex-$ACCOUNT_SLUG-day$day.json"
    PROMPT_FILE="$TMP_DIR/prompt-$ACCOUNT_SLUG-day$day.txt"
    OUT_ARTIFACT="$RUN_ARTIFACT_DIR/codex-$ACCOUNT_SLUG-day$day.json"
    PROMPT_ARTIFACT="$RUN_ARTIFACT_DIR/prompt-$ACCOUNT_SLUG-day$day.txt"

    cat > "$PROMPT_FILE" <<EOF2
You are maintaining a conservative ignore list for email automation cost control.

Task:
- Review the provided ONE-DAY email dataset for ONE account.
- Add only sender emails that are VERY HIGH confidence useless/repetitive noise.
- Remove sender emails from account ignore if they appear useful/personal/sensitive.

Strict policy:
- Be conservative. Prefer false negative over false positive.
- Ignore only clear repetitive broadcast/marketing/statements/alerts that are safe to auto-delete with minimal risk.
- Keep anything security/login/payment/bank transaction/itinerary/flight/personal communication/school opportunity/research opportunity/account operation.
- If sender did not appear in this one-day dataset, do not add it.
- Output exact sender email addresses only.
- Only propose add/remove candidates if confidence >= $MIN_CONFIDENCE.
- If a sender is a clear marketing/newsletter broadcast with unsubscribe footer and no account/security value, it is OK to set confidence to 0.99.

Current ignore config:
$(cat "$IGNORE_FILE")

Account:
$ACCOUNT
Day offset:
$day

Emails JSON for this account/day (full content):
$(cat "$MSG_FILE")

Output requirements:
- Return JSON matching schema exactly.
- add_account_sender_exact should only include senders seen in this dataset.
- Use confidence to reflect certainty.
- rationale should be concise and concrete.
EOF2
    cp "$PROMPT_FILE" "$PROMPT_ARTIFACT"

    CMD=(codex exec --output-schema "$RESULT_SCHEMA" --output-last-message "$OUT_FILE" --model "$MODEL" -c model_reasoning_effort='"medium"')
    if [ "$SKIP_GIT_CHECK" -eq 1 ]; then
      CMD+=(--skip-git-repo-check)
    fi
    CMD+=(-)

    attempt=1
    max_attempts=3
    success=0
    while [ "$attempt" -le "$max_attempts" ]; do
      rm -f "$OUT_FILE"
      echo "classify account=$ACCOUNT day=$day attempt=$attempt" | tee -a "$RUN_LOG"
      if "${CMD[@]}" < "$PROMPT_FILE" >/dev/null 2>>"$RUN_LOG" && [ -s "$OUT_FILE" ]; then
        success=1
        break
      fi
      echo "codex_retry account=$ACCOUNT day=$day attempt=$attempt/$max_attempts" | tee -a "$RUN_LOG"
      sleep 2
      attempt=$((attempt + 1))
    done

    if [ "$success" -ne 1 ]; then
      FAILED_BATCHES=$((FAILED_BATCHES + 1))
      echo "codex_error account=$ACCOUNT day=$day reason=missing_or_invalid_output prompt=$PROMPT_ARTIFACT" | tee -a "$RUN_LOG"
      day=$((day + 1))
      continue
    fi
    cp "$OUT_FILE" "$OUT_ARTIFACT"

    if ! python3 - <<PY | tee -a "$RUN_LOG"
import json,re
ignore_path="$IGNORE_FILE"
out_path="$OUT_FILE"
msg_path="$MSG_FILE"
account="$ACCOUNT".lower().strip()
min_conf=float("$MIN_CONFIDENCE")
dry_run=bool($DRY_RUN)

ignore=json.load(open(ignore_path,encoding="utf-8"))
res=json.load(open(out_path,encoding="utf-8"))
msgs=json.load(open(msg_path,encoding="utf-8"))

occurred=set()
for m in msgs:
    s=(m.get("sender_text") or "").strip().lower()
    mm=re.search(r"<\s*([^<>\s]+@[^<>\s]+)\s*>", s)
    if mm:
        occurred.add(mm.group(1).lower())
    elif re.match(r"^[^@\s]+@[^@\s]+\.[^@\s]+$", s):
        occurred.add(s)

acct_map=ignore.setdefault("account_sender_exact",{})
existing=set(s.lower() for s in acct_map.get(account,[]))

added=[]
rejected=[]
for item in res.get("add_account_sender_exact",[]):
    email=(item.get("email") or "").strip().lower()
    conf=float(item.get("confidence") or 0.0)
    reason=(item.get("reason") or "").strip()
    if conf < min_conf:
        if email:
            rejected.append((email, conf, "below_confidence"))
        continue
    if email not in occurred:
        if email:
            rejected.append((email, conf, "not_occurred"))
        continue
    if not re.match(r"^[^@\s]+@[^@\s]+\.[^@\s]+$", email):
        if email:
            rejected.append((email, conf, "invalid_email"))
        continue
    if email not in existing:
        existing.add(email)
        added.append((email, conf, reason))

removed=[]
removed_rejected=[]
for email in res.get("remove_account_sender_exact",[]):
    x=(email or "").strip().lower()
    if x and x not in occurred:
        removed_rejected.append(x)
        continue
    if x in existing:
        existing.remove(x)
        removed.append(x)

acct_map[account]=sorted(existing)

if not dry_run:
    with open(ignore_path,"w",encoding="utf-8") as f:
        json.dump(ignore,f,indent=2,ensure_ascii=False)
        f.write("\n")

print(f"account={account} day={res.get('day_offset')} add={len(added)} remove={len(removed)} keep={len(existing)}")
print(f"rationale={res.get('rationale','')}")
for email,conf,reason in added[:20]:
    print(f"  + {email} conf={conf:.2f} reason={reason}")
for email in removed[:20]:
    print(f"  - {email}")
for email,conf,why in rejected[:10]:
    print(f"  ! reject_add {email} conf={conf:.2f} why={why}")
for email in removed_rejected[:10]:
    print(f"  ! reject_remove {email} why=not_occurred")
PY
    then
      FAILED_BATCHES=$((FAILED_BATCHES + 1))
      echo "codex_parse_error account=$ACCOUNT day=$day out=$OUT_ARTIFACT prompt=$PROMPT_ARTIFACT" | tee -a "$RUN_LOG"
      day=$((day + 1))
      continue
    fi

    PROCESSED_BATCHES=$((PROCESSED_BATCHES + 1))
    day=$((day + 1))
  done

  PROCESSED_ACCOUNTS=$((PROCESSED_ACCOUNTS + 1))
done < "$TMP_DIR/target_accounts.txt"

if [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry run complete. ignore file unchanged." | tee -a "$RUN_LOG"
else
  echo "Updated ignore file: $IGNORE_FILE" | tee -a "$RUN_LOG"
fi

echo "summary total_accounts=$TOTAL_ACCOUNTS processed_accounts=$PROCESSED_ACCOUNTS processed_batches=$PROCESSED_BATCHES skipped_days=$SKIPPED_DAYS failed_batches=$FAILED_BATCHES total_messages=$TOTAL_MESSAGES" | tee -a "$RUN_LOG"
echo "Run log: $RUN_LOG"
echo "Artifacts: $RUN_ARTIFACT_DIR"
