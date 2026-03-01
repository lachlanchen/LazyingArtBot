#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: codex_refresh_ignore_list_repetitive.sh [options]

Goal:
- Build a *new* ignore list focused on senders that are repetitive over a week.
- Use Codex (non-interactive) to decide which repetitive senders are safe to ignore.
- Confidence threshold defaults to 0.90 (less strict than the conservative daily script).

This script:
1) Fetches last N days of INBOX messages (full content) for each Mail account.
2) Finds repetitive senders (appear on many distinct days / many total messages).
3) Asks Codex once per repetitive sender to decide ignore vs keep.
4) Updates a new ignore list file (by default: mail_ignore_list_repetitive.json).

Options:
  --days <n>                 Lookback days (default: 7)
  --confidence <float>       Min confidence to add/remove (default: 0.90)
  --min-distinct-days <n>    Repetitive threshold (default: 5)
  --min-total-count <n>      Repetitive threshold (default: 6)
  --max-messages <n>         Max messages to send to Codex per sender (default: 15)
  --accounts <csv>           Restrict to account names (comma-separated)
  --base-ignore-file <path>  Base ignore list to copy/merge from (default: mail_ignore_list.json)
  --out-ignore-file <path>   Output ignore list path (default: mail_ignore_list_repetitive.json)
  --model <name>             Codex model override (default: gpt-5.3-codex)
  --dry-run                  Do not modify output ignore file
  --skip-git-check           Pass --skip-git-repo-check to codex exec
  -h, --help                 Show help

Examples:
  codex_refresh_ignore_list_repetitive.sh --days 7 --confidence 0.9
  codex_refresh_ignore_list_repetitive.sh --accounts "QQ,lachen@connect.hku.hk"
USAGE
}

ROOT="$HOME/.openclaw/workspace"
LOG_DIR="$ROOT/logs"
DATA_ROOT="$ROOT/automation/data/automail2note"

DAYS=7
MIN_CONFIDENCE="0.90"
MIN_DISTINCT_DAYS=5
MIN_TOTAL_COUNT=6
MAX_MESSAGES=15
ACCOUNTS_CSV=""

BASE_IGNORE_FILE="$DATA_ROOT/ignore_lists/mail_ignore_list.json"
OUT_IGNORE_FILE="$DATA_ROOT/ignore_lists/mail_ignore_list_repetitive.json"

MODEL="gpt-5.3-codex"
DRY_RUN=0
SKIP_GIT_CHECK=1

while [ $# -gt 0 ]; do
  case "$1" in
    --days) DAYS="${2:-}"; shift ;;
    --confidence) MIN_CONFIDENCE="${2:-}"; shift ;;
    --min-distinct-days) MIN_DISTINCT_DAYS="${2:-}"; shift ;;
    --min-total-count) MIN_TOTAL_COUNT="${2:-}"; shift ;;
    --max-messages) MAX_MESSAGES="${2:-}"; shift ;;
    --accounts) ACCOUNTS_CSV="${2:-}"; shift ;;
    --base-ignore-file) BASE_IGNORE_FILE="${2:-}"; shift ;;
    --out-ignore-file) OUT_IGNORE_FILE="${2:-}"; shift ;;
    --model) MODEL="${2:-}"; shift ;;
    --dry-run) DRY_RUN=1 ;;
    --skip-git-check) SKIP_GIT_CHECK=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

if ! command -v codex >/dev/null 2>&1; then
  echo "codex CLI not found in PATH." >&2
  exit 1
fi
if [ ! -f "$BASE_IGNORE_FILE" ]; then
  echo "Base ignore file not found: $BASE_IGNORE_FILE" >&2
  exit 1
fi

mkdir -p "$LOG_DIR"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

RUN_ID="$(date +%Y%m%d-%H%M%S)"
RUN_LOG="$LOG_DIR/ignore-refresh-repetitive-$RUN_ID.log"
RUN_ARTIFACT_DIR="$LOG_DIR/ignore-refresh-repetitive-$RUN_ID"
mkdir -p "$RUN_ARTIFACT_DIR"

echo "run_id=$RUN_ID" | tee -a "$RUN_LOG"
echo "base_ignore_file=$BASE_IGNORE_FILE" | tee -a "$RUN_LOG"
echo "out_ignore_file=$OUT_IGNORE_FILE" | tee -a "$RUN_LOG"
echo "model=$MODEL reasoning=medium" | tee -a "$RUN_LOG"
echo "days=$DAYS min_confidence=$MIN_CONFIDENCE min_distinct_days=$MIN_DISTINCT_DAYS min_total_count=$MIN_TOTAL_COUNT max_messages=$MAX_MESSAGES dry_run=$DRY_RUN" | tee -a "$RUN_LOG"
echo "artifact_dir=$RUN_ARTIFACT_DIR" | tee -a "$RUN_LOG"

slug() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9._-' '_'
}

# Ensure OUT_IGNORE_FILE exists by copying BASE_IGNORE_FILE.
if [ ! -f "$OUT_IGNORE_FILE" ]; then
  if [ "$DRY_RUN" -eq 0 ]; then
    cp "$BASE_IGNORE_FILE" "$OUT_IGNORE_FILE"
  fi
  echo "initialized_out_ignore_file=1" | tee -a "$RUN_LOG"
else
  echo "initialized_out_ignore_file=0" | tee -a "$RUN_LOG"
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

python3 - <<PY > "$TMP_DIR/target_accounts.txt"
import json
for a in json.loads('''$TARGET_ACCOUNTS_JSON'''):
    if isinstance(a, str) and a.strip():
        print(a.strip())
PY

RESULT_SCHEMA="$TMP_DIR/result-schema.json"
cat > "$RESULT_SCHEMA" <<'JSON'
{
  "type": "object",
  "additionalProperties": false,
  "required": ["account", "sender", "decision", "confidence", "reason"],
  "properties": {
    "account": { "type": "string" },
    "sender": { "type": "string" },
    "decision": { "type": "string", "enum": ["ignore", "keep"] },
    "confidence": { "type": "number" },
    "reason": { "type": "string" }
  }
}
JSON

fetch_account_week_headers() {
  local account_name="$1"
  local days="$2"
  local out_file="$3"
  osascript - "$account_name" "$days" <<'APPLESCRIPT' > "$out_file"
use framework "Foundation"
use scripting additions

on run argv
  set accountName to item 1 of argv
  set lookbackDays to (item 2 of argv) as integer

  set startDate to (current date) - (lookbackDays * days)
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
        set msgList to (messages of mb whose date received ≥ startDate)
      on error
        set msgList to {}
      end try
      repeat with m in msgList
        try
          set senderText to sender of m as text
          set subjectText to subject of m as text
          set dateText to date received of m as text
          set msgidText to ""
          try
            set msgidText to message id of m as text
          end try
          -- Important: do NOT fetch full content here (slow). We'll fetch content only for shortlisted senders.
          set end of outList to {sender_text:senderText, subject_text:subjectText, received_text:dateText, message_id_text:msgidText}
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

fetch_sender_full_messages() {
  local account_name="$1"
  local days="$2"
  local sender_email="$3"
  local max_messages="$4"
  local out_file="$5"
  osascript - "$account_name" "$days" "$sender_email" "$max_messages" <<'APPLESCRIPT' > "$out_file"
use framework "Foundation"
use scripting additions

on run argv
  set accountName to item 1 of argv
  set lookbackDays to (item 2 of argv) as integer
  set senderEmail to item 3 of argv
  set maxMessages to (item 4 of argv) as integer

  set startDate to (current date) - (lookbackDays * days)
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
        set msgList to (messages of mb whose date received ≥ startDate and sender contains senderEmail)
      on error
        set msgList to {}
      end try

      set added to 0
      repeat with m in msgList
        if added ≥ maxMessages then exit repeat
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
          set added to added + 1
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

TOTAL_SENDERS=0
IGNORED_ADDED=0
KEEPED=0

while IFS= read -r ACCOUNT; do
  [ -z "$ACCOUNT" ] && continue
  echo "=== account: $ACCOUNT ===" | tee -a "$RUN_LOG"
  ACCOUNT_SLUG="$(slug "$ACCOUNT")"

  MSG_FILE="$TMP_DIR/week-headers-$ACCOUNT_SLUG.json"
  MSG_ARTIFACT="$RUN_ARTIFACT_DIR/messages-$ACCOUNT_SLUG-week-headers.json"
  fetch_account_week_headers "$ACCOUNT" "$DAYS" "$MSG_FILE"
  cp "$MSG_FILE" "$MSG_ARTIFACT"

  MSG_COUNT="$(python3 - <<PY
import json
print(len(json.load(open("$MSG_FILE",encoding="utf-8"))))
PY
)"
  echo "week_headers=$MSG_COUNT file=$MSG_ARTIFACT" | tee -a "$RUN_LOG"
  if [ "$MSG_COUNT" -eq 0 ]; then
    continue
  fi

  CAND_FILE="$TMP_DIR/candidates-$ACCOUNT_SLUG.json"
  CAND_ARTIFACT="$RUN_ARTIFACT_DIR/candidates-$ACCOUNT_SLUG.json"
  MIN_DISTINCT_DAYS="$MIN_DISTINCT_DAYS" MIN_TOTAL_COUNT="$MIN_TOTAL_COUNT" MAX_MESSAGES="$MAX_MESSAGES" \
    python3 - "$ACCOUNT" "$MSG_FILE" "$CAND_FILE" >/dev/null <<'PY'
import json,sys,re
account=sys.argv[1]
msg_file=sys.argv[2]
out_file=sys.argv[3]

MIN_DISTINCT_DAYS=int(__import__("os").environ.get("MIN_DISTINCT_DAYS","5"))
MIN_TOTAL_COUNT=int(__import__("os").environ.get("MIN_TOTAL_COUNT","6"))
MAX_MESSAGES=int(__import__("os").environ.get("MAX_MESSAGES","15"))

msgs=json.load(open(msg_file,encoding="utf-8"))

def parse_email(sender_text: str) -> str:
    s=(sender_text or "").strip()
    m=re.search(r"<\s*([^<>\s]+@[^<>\s]+)\s*>", s)
    if m: return m.group(1).lower()
    if re.match(r"^[^@\s]+@[^@\s]+\.[^@\s]+$", s.lower()): return s.lower()
    return ""

def day_key(received_text: str) -> str:
    t=(received_text or "").strip()
    if len(t)>=10 and t[4:5]=='-' and t[7:8]=='-':
        return t[:10]
    try:
        from dateutil import parser
        dt=parser.parse(t)
        return dt.strftime("%Y-%m-%d")
    except Exception:
        return "unknown"

from collections import defaultdict
by_sender=defaultdict(list)
by_sender_days=defaultdict(set)

for m in msgs:
    email=parse_email(m.get("sender_text",""))
    if not email:
        continue
    by_sender[email].append(m)
    by_sender_days[email].add(day_key(m.get("received_text","")))

candidates=[]
for sender, arr in by_sender.items():
    total=len(arr)
    distinct=len(by_sender_days[sender])
    if distinct >= MIN_DISTINCT_DAYS or total >= MIN_TOTAL_COUNT:
        arr_sorted=sorted(arr, key=lambda x: (x.get("received_text","")), reverse=True)
        sample=arr_sorted[:MAX_MESSAGES]
        candidates.append({
            "sender": sender,
            "total_count": total,
            "distinct_days": distinct,
            "sample_messages": sample,
        })

candidates.sort(key=lambda x: (x["distinct_days"], x["total_count"]), reverse=True)
json.dump(candidates, open(out_file,"w",encoding="utf-8"), indent=2, ensure_ascii=False)
PY

  cp "$CAND_FILE" "$CAND_ARTIFACT"
  CAND_COUNT="$(python3 - <<PY
import json
print(len(json.load(open("$CAND_FILE",encoding="utf-8"))))
PY
)"
  echo "repetitive_senders=$CAND_COUNT file=$CAND_ARTIFACT" | tee -a "$RUN_LOG"

  if [ "$CAND_COUNT" -eq 0 ]; then
    continue
  fi

  # Iterate sender-by-sender so we can include full bodies without blowing context.
  python3 - <<PY > "$TMP_DIR/senders-$ACCOUNT_SLUG.txt"
import json
for item in json.load(open("$CAND_FILE",encoding="utf-8")):
    print(item["sender"])
PY

  while IFS= read -r SENDER; do
    [ -z "$SENDER" ] && continue
    TOTAL_SENDERS=$((TOTAL_SENDERS + 1))
    echo "sender=$SENDER" | tee -a "$RUN_LOG"

    SENDER_SLUG="$(slug "$SENDER")"
    SENDER_HEADERS_BUNDLE="$TMP_DIR/bundle-headers-$ACCOUNT_SLUG-$SENDER_SLUG.json"
    SENDER_HEADERS_BUNDLE_ARTIFACT="$RUN_ARTIFACT_DIR/bundle-headers-$ACCOUNT_SLUG-$SENDER_SLUG.json"
    python3 - <<PY
import json
cands=json.load(open("$CAND_FILE",encoding="utf-8"))
sender="$SENDER"
bundle=next((x for x in cands if x.get("sender")==sender), None)
json.dump(bundle or {}, open("$SENDER_HEADERS_BUNDLE","w",encoding="utf-8"), indent=2, ensure_ascii=False)
PY
    cp "$SENDER_HEADERS_BUNDLE" "$SENDER_HEADERS_BUNDLE_ARTIFACT"

    SENDER_FULL="$TMP_DIR/bundle-full-$ACCOUNT_SLUG-$SENDER_SLUG.json"
    SENDER_FULL_ARTIFACT="$RUN_ARTIFACT_DIR/bundle-full-$ACCOUNT_SLUG-$SENDER_SLUG.json"
    fetch_sender_full_messages "$ACCOUNT" "$DAYS" "$SENDER" "$MAX_MESSAGES" "$SENDER_FULL"
    cp "$SENDER_FULL" "$SENDER_FULL_ARTIFACT"

    PROMPT_FILE="$TMP_DIR/prompt-$ACCOUNT_SLUG-$SENDER_SLUG.txt"
    PROMPT_ARTIFACT="$RUN_ARTIFACT_DIR/prompt-$ACCOUNT_SLUG-$SENDER_SLUG.txt"
    OUT_FILE="$TMP_DIR/codex-$ACCOUNT_SLUG-$SENDER_SLUG.json"
    OUT_ARTIFACT="$RUN_ARTIFACT_DIR/codex-$ACCOUNT_SLUG-$SENDER_SLUG.json"

    cat > "$PROMPT_FILE" <<EOF
You are maintaining an email ignore list focused on *repetitive* senders for cost control.

Task:
- Decide whether the sender below is safe to ignore (auto-delete / auto-move) based on the last week.
- Use the provided sample messages (full content). If any sample indicates security/account/payment/itinerary or human-to-human value, choose KEEP.

Policy:
- Only choose decision="ignore" when confidence >= $MIN_CONFIDENCE.
- Prefer KEEP when uncertain.
- Repetitive alone is not enough: the content must clearly be low-value broadcast (daily digest/newsletter/marketing/automated statement).
- Treat "bulk notice / bulletin / digest / announcement" emails as IGNORE candidates even if they mention seminars/careers/research recruitment, as long as they are not transactional/security and not human-to-human.
- ALWAYS KEEP:
  - security alerts, login attempts, verification codes, 2FA codes
  - receipts, invoices, charge/transfer confirmations, bank transaction notices, statements with money movement
  - flight/hotel itineraries and bookings
  - human-to-human email (a real person writing to you, replies, coordination, feedback)

Current output ignore config (this script writes to it):
$(cat "$OUT_IGNORE_FILE" 2>/dev/null || cat "$BASE_IGNORE_FILE")

Account: $ACCOUNT
Sender under review: $SENDER

Week repetition stats (from headers) + sample messages (FULL bodies for this sender, limited):
headers_stats:
$(cat "$SENDER_HEADERS_BUNDLE")

full_messages:
$(cat "$SENDER_FULL")

Return JSON matching schema exactly.
EOF
    cp "$PROMPT_FILE" "$PROMPT_ARTIFACT"

    CMD=(codex exec --output-schema "$RESULT_SCHEMA" --output-last-message "$OUT_FILE" --model "$MODEL" -c model_reasoning_effort='"medium"')
    if [ "$SKIP_GIT_CHECK" -eq 1 ]; then
      CMD+=(--skip-git-repo-check)
    fi
    CMD+=(-)

    rm -f "$OUT_FILE"
    if ! "${CMD[@]}" < "$PROMPT_FILE" >/dev/null 2>>"$RUN_LOG"; then
      echo "codex_error sender=$SENDER prompt=$PROMPT_ARTIFACT" | tee -a "$RUN_LOG"
      continue
    fi
    if [ ! -s "$OUT_FILE" ]; then
      echo "codex_error sender=$SENDER reason=empty_output prompt=$PROMPT_ARTIFACT" | tee -a "$RUN_LOG"
      continue
    fi
    cp "$OUT_FILE" "$OUT_ARTIFACT"

    # Apply result to OUT_IGNORE_FILE (account_sender_exact only).
    python3 - <<PY | tee -a "$RUN_LOG"
import json,re
out_ignore_path="$OUT_IGNORE_FILE"
base_ignore_path="$BASE_IGNORE_FILE"
res_path="$OUT_FILE"
account="$ACCOUNT".lower().strip()
min_conf=float("$MIN_CONFIDENCE")
dry=bool($DRY_RUN)

if not __import__("os").path.exists(out_ignore_path):
    data=json.load(open(base_ignore_path,encoding="utf-8"))
else:
    data=json.load(open(out_ignore_path,encoding="utf-8"))

res=json.load(open(res_path,encoding="utf-8"))
sender=(res.get("sender") or "").strip().lower()
decision=res.get("decision")
conf=float(res.get("confidence") or 0.0)
reason=(res.get("reason") or "").strip()

if not sender or not re.match(r"^[^@\s]+@[^@\s]+\.[^@\s]+$", sender):
    print(f"apply_skip invalid_sender={sender!r}")
    raise SystemExit(0)

acct_map=data.setdefault("account_sender_exact",{})
existing=set(s.lower() for s in acct_map.get(account,[]))

changed=False
action="noop"

if decision == "ignore" and conf >= min_conf:
    if sender not in existing:
        existing.add(sender)
        action="added"
        changed=True
elif decision == "keep":
    if sender in existing:
        existing.remove(sender)
        action="removed"
        changed=True
else:
    action="noop"

acct_map[account]=sorted(existing)

if changed and not dry:
    with open(out_ignore_path,"w",encoding="utf-8") as f:
        json.dump(data,f,indent=2,ensure_ascii=False)
        f.write("\\n")

print(f"apply account={account} sender={sender} decision={decision} conf={conf:.2f} action={action} reason={reason}")
PY

  done < "$TMP_DIR/senders-$ACCOUNT_SLUG.txt"

done < "$TMP_DIR/target_accounts.txt"

echo "Updated output ignore file: $OUT_IGNORE_FILE" | tee -a "$RUN_LOG"
echo "Run log: $RUN_LOG"
echo "Artifacts: $RUN_ARTIFACT_DIR"
