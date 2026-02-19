#!/bin/zsh
set -euo pipefail

ACCOUNT="iCloud"
ROOT_FOLDER="AutoLife"
FOLDER_PATH="🏢 Companies/🐼 Lazying.art"
NOTE_NAME="🎨 Lazying.art · Milestones / 里程碑 / マイルストーン"
OUT_FILE=""

usage() {
  cat <<'USAGE'
Usage: prompt_la_note_reader.sh [options]

Options:
  --account <name>       Notes account (default: iCloud)
  --root-folder <name>   Root folder (default: AutoLife)
  --folder-path <path>   Nested folder path under root (default: 🏢 Companies/🐼 Lazying.art)
  --note <name>          Note name
  --out <path>           Write HTML body to file instead of stdout
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
    --out)
      shift
      OUT_FILE="${1:-}"
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

APPLESCRIPT="$(cat <<'APPLESCRIPT'
on splitPath(pathText)
  if pathText is "" then return {}
  set AppleScript's text item delimiters to "/"
  set itemsList to text items of pathText
  set AppleScript's text item delimiters to ""
  return itemsList
end splitPath

on resolveFolder(accountName, rootFolderName, subPath)
  tell application "Notes"
    if not (exists account accountName) then return missing value
    set currentContainer to account accountName
    if rootFolderName is not "" then
      if not (exists folder rootFolderName of currentContainer) then return missing value
      set currentContainer to folder rootFolderName of currentContainer
    end if
    repeat with seg in my splitPath(subPath)
      set segText to seg as text
      if segText is not "" then
        if not (exists folder segText of currentContainer) then return missing value
        set currentContainer to folder segText of currentContainer
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

  set targetFolder to my resolveFolder(accountName, rootFolderName, subPath)
  if targetFolder is missing value then return ""

  tell application "Notes"
    if not (exists note noteName of targetFolder) then return ""
    return (body of note noteName of targetFolder) as text
  end tell
end run
APPLESCRIPT
)"

export APPLESCRIPT
SCRIPT_OUTPUT="$(python3 - "$ACCOUNT" "$ROOT_FOLDER" "$FOLDER_PATH" "$NOTE_NAME" <<'PY'
import subprocess
import os
import sys

account = sys.argv[1]
root_folder = sys.argv[2]
folder_path = sys.argv[3]
note_name = sys.argv[4]

script = os.environ.get("APPLESCRIPT", "")
try:
    proc = subprocess.run(
        ["osascript", "-", account, root_folder, folder_path, note_name],
        input=script,
        text=True,
        capture_output=True,
        timeout=20,
        check=False,
    )
except Exception as exc:  # noqa: BLE001
    print(f"ERROR: {exc}", file=sys.stderr)
    print("")
    sys.exit(0)

if proc.returncode != 0:
    stderr = (proc.stderr or "").strip()
    if stderr:
        print(stderr, file=sys.stderr)
    print("")
    sys.exit(0)

print(proc.stdout.rstrip("\n"), end="")
PY
)"

if [[ -n "$OUT_FILE" ]]; then
  printf '%s' "$SCRIPT_OUTPUT" > "$OUT_FILE"
else
  printf '%s' "$SCRIPT_OUTPUT"
fi
