#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

usage() {
  echo "Usage: $0 [--context <text>]" >&2
  echo "       Provide --context or pipe text via stdin." >&2
  exit 1
}

CONTEXT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --context)
      shift
      CONTEXT="$1"
      ;;
    *)
      usage
      ;;
  esac
  shift
done

if [[ -z "$CONTEXT" ]]; then
  if [[ -t 0 ]]; then
    usage
  else
    CONTEXT=$(cat)
  fi
fi

export CONTEXT
TMP=$(mktemp)
python3 - "$TMP" <<'PY'
import json, os, sys
payload = {"context": os.environ.get("CONTEXT")}
with open(sys.argv[1], "w", encoding="utf-8") as fh:
    json.dump(payload, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY

OUTPUT_DIR="/tmp/codex-log"
mkdir -p "$OUTPUT_DIR"

python3 scripts/prompt_tools/codex-json-runner.py \
  --input-json "$TMP" \
  --output-dir "$OUTPUT_DIR" \
  --prompt-file scripts/prompt_tools/log_prompt.md \
  --schema scripts/prompt_tools/log_entry_schema.json \
  --model gpt-5.3-codex-spark \
  --reasoning low \
  --label log-entry \
  --skip-git-check

rm -f "$TMP"

RESULT_PATH="$OUTPUT_DIR/latest-result.json"
if [[ ! -f "$RESULT_PATH" ]]; then
  echo "Log generation failed" >&2
  exit 1
fi

SUMMARY=$(python3 -c 'import json,sys; data=json.load(sys.stdin); print(data.get("summary",""))' < "$RESULT_PATH")
LOG_HTML=$(python3 -c 'import json,sys; data=json.load(sys.stdin); print(data.get("log_html",""))' < "$RESULT_PATH")

if [[ -z "$LOG_HTML" ]]; then
  echo "Log entry missing HTML" >&2
  exit 1
fi

HTML_FILE=$(mktemp)
printf "%s" "$LOG_HTML" > "$HTML_FILE"

DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)

APPLESCRIPT_FILE=$(mktemp)
cat <<'AS' > "$APPLESCRIPT_FILE"
on ensureLogFolder()
	tell application "Notes"
		set icloudAccount to account "iCloud"
		set autoFolder to folder "AutoLife" of icloudAccount
		if not (exists folder "🪵 Log" of autoFolder) then
			make new folder at autoFolder with properties {name:"Log"}
		end if
		return folder "🪵 Log" of autoFolder
	end tell
end ensureLogFolder

on appendLog(dateName, htmlPath)
	tell application "Notes"
		set logFolder to my ensureLogFolder()
		if not (exists note dateName of logFolder) then
			make new note at logFolder with properties {name:dateName, body:"<h1>" & dateName & " Log</h1>"}
		end if
		set targetNote to note dateName of logFolder
		set logHTML to read (POSIX file htmlPath) as «class utf8»
		set body of targetNote to (body of targetNote & logHTML)
	end tell
end appendLog

on run argv
	set theDate to item 1 of argv
	set htmlFile to item 2 of argv
	my appendLog(theDate, htmlFile)
end run
AS

osascript "$APPLESCRIPT_FILE" "$DATE" "$HTML_FILE"
rm -f "$APPLESCRIPT_FILE" "$HTML_FILE"

LOG_DIR="/Users/lachlan/.openclaw/workspace/AutoLife/Log"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$DATE.md"
cat <<EOF >> "$LOG_FILE"
## $TIME $SUMMARY

$LOG_HTML

EOF

echo "Logged entry: $SUMMARY"
