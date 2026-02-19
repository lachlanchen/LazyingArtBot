#!/bin/zsh
set -euo pipefail

ACCOUNT="iCloud"
ROOT_FOLDER="AutoLife"
FOLDER_PATH="🏢 Companies/🐼 Lazying.art"
NOTE_NAME="🎨 Lazying.art · Milestones / 里程碑 / マイルストーン"
MODE="replace"
HTML_FILE=""
HTML_TEXT=""

usage() {
  cat <<'USAGE'
Usage: prompt_la_note_save.sh [options]

Options:
  --account <name>       Notes account (default: iCloud)
  --root-folder <name>   Root folder (default: AutoLife)
  --folder-path <path>   Nested folder path under root
  --note <name>          Note name
  --mode <append|replace> Write mode (default: replace)
  --html-file <path>     Input HTML file
  --html-text <text>     Inline HTML text
  -h, --help             Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --account)
      shift
      ACCOUNT="${1:-}"
      ;;
    --root-folder)
      shift
      ROOT_FOLDER="${1:-}"
      ;;
    --folder-path)
      shift
      FOLDER_PATH="${1:-}"
      ;;
    --note)
      shift
      NOTE_NAME="${1:-}"
      ;;
    --mode)
      shift
      MODE="${1:-}"
      ;;
    --html-file)
      shift
      HTML_FILE="${1:-}"
      ;;
    --html-text)
      shift
      HTML_TEXT="${1:-}"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if [[ "$MODE" != "append" && "$MODE" != "replace" ]]; then
  echo "Invalid --mode: $MODE" >&2
  exit 1
fi

if [[ -z "$HTML_FILE" && -z "$HTML_TEXT" ]]; then
  echo "Provide --html-file or --html-text" >&2
  exit 1
fi

if [[ -n "$HTML_FILE" && ! -f "$HTML_FILE" ]]; then
  echo "Missing html file: $HTML_FILE" >&2
  exit 1
fi

TMP_HTML=""
if [[ -n "$HTML_FILE" ]]; then
  TMP_HTML="$HTML_FILE"
else
  TMP_HTML="$(mktemp)"
  printf '%s' "$HTML_TEXT" > "$TMP_HTML"
fi

APPLESCRIPT="$(cat <<'APPLESCRIPT'
on splitPath(pathText)
  if pathText is "" then return {}
  set AppleScript's text item delimiters to "/"
  set itemsList to text items of pathText
  set AppleScript's text item delimiters to ""
  return itemsList
end splitPath

on ensureFolder(parentContainer, folderName)
  tell application "Notes"
    if exists folder folderName of parentContainer then
      return folder folderName of parentContainer
    end if
    return (make new folder at parentContainer with properties {name:folderName})
  end tell
end ensureFolder

on resolveFolder(accountName, rootFolderName, subPath)
  tell application "Notes"
    if not (exists account accountName) then error "Missing Notes account: " & accountName
    set currentContainer to account accountName
    if rootFolderName is not "" then
      set currentContainer to my ensureFolder(currentContainer, rootFolderName)
    end if
    repeat with seg in my splitPath(subPath)
      set segText to seg as text
      if segText is not "" then
        set currentContainer to my ensureFolder(currentContainer, segText)
      end if
    end repeat
    return currentContainer
  end tell
end resolveFolder

on run argv
  set accountName to item 1 of argv
  set rootFolderName to item 2 of argv
  set subPath to item 3 of argv
  set noteName to item 4 of argv
  set modeText to item 5 of argv
  set htmlPath to item 6 of argv

  set htmlBody to read (POSIX file htmlPath) as «class utf8»
  set targetFolder to my resolveFolder(accountName, rootFolderName, subPath)

  tell application "Notes"
    set targetNote to missing value
    if exists note noteName of targetFolder then
      set targetNote to note noteName of targetFolder
    else
      set targetNote to (make new note at targetFolder with properties {name:noteName, body:""})
    end if

    if modeText is "append" then
      set body of targetNote to ((body of targetNote as text) & htmlBody)
    else
      set body of targetNote to htmlBody
    end if
  end tell
end run
APPLESCRIPT
)"

export APPLESCRIPT
SCRIPT_RC=0
python3 - "$ACCOUNT" "$ROOT_FOLDER" "$FOLDER_PATH" "$NOTE_NAME" "$MODE" "$TMP_HTML" <<'PY' || SCRIPT_RC=$?
import os
import subprocess
import sys

account = sys.argv[1]
root_folder = sys.argv[2]
folder_path = sys.argv[3]
note_name = sys.argv[4]
mode_text = sys.argv[5]
html_path = sys.argv[6]

script = os.environ.get("APPLESCRIPT", "")

try:
    proc = subprocess.run(
        ["osascript", "-", account, root_folder, folder_path, note_name, mode_text, html_path],
        input=script,
        text=True,
        capture_output=True,
        timeout=30,
        check=False,
    )
except Exception as exc:  # noqa: BLE001
    print(f"ERROR: {exc}", file=sys.stderr)
    sys.exit(0)

if proc.returncode != 0:
    stderr = (proc.stderr or "").strip()
    if stderr:
        print(stderr, file=sys.stderr)
    sys.exit(0)

print("")
PY

if [[ "$SCRIPT_RC" -ne 0 ]]; then
  echo "Failed to write note '$NOTE_NAME' in folder '$FOLDER_PATH'; continuing." >&2
fi

if [[ -z "$HTML_FILE" ]]; then
  rm -f "$TMP_HTML"
fi
