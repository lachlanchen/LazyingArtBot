#!/usr/bin/env bash
set -euo pipefail

SRC_AUTOMATION="${SRC_AUTOMATION:-$HOME/.openclaw/workspace/automation}"
SRC_MAIL_APP="${SRC_MAIL_APP:-$HOME/Library/Application Scripts/com.apple.mail}"
DEST_DIR="${1:-$PWD/automail2note}"

SCRIPT_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/$(basename -- "${BASH_SOURCE[0]}")"

FILES=(
  "lazyingart_simple.py"
  "lazyingart_simple_rule.applescript"
  "lazyingart_apply_action.py"
  "lazyingart_rule_write_json.py"
  "create_calendar_event.applescript"
  "create_reminder.applescript"
  "create_note.applescript"
)

mkdir -p "$DEST_DIR"

copied=()
missing=()

copy_if_exists() {
  local src="$1"
  local dst="$2"
  if [[ -f "$src" ]]; then
    cp -p "$src" "$dst"
    copied+=("$(basename "$dst")")
  else
    missing+=("$src")
  fi
}

for name in "${FILES[@]}"; do
  copy_if_exists "$SRC_AUTOMATION/$name" "$DEST_DIR/$name"
done

copy_if_exists "$SRC_MAIL_APP/Lazyingart Simple Rule.scpt" "$DEST_DIR/Lazyingart Simple Rule.scpt"
copy_if_exists "$SCRIPT_PATH" "$DEST_DIR/install_automail2note.sh"

{
  echo "automail2note bundle"
  echo "generated_at=$(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo "source_automation=$SRC_AUTOMATION"
  echo "source_mail_app=$SRC_MAIL_APP"
  echo
  echo "[copied]"
  for item in "${copied[@]}"; do
    echo "$item"
  done
  echo
  echo "[missing]"
  if [[ "${#missing[@]}" -eq 0 ]]; then
    echo "(none)"
  else
    for item in "${missing[@]}"; do
      echo "$item"
    done
  fi
} > "$DEST_DIR/README.txt"

echo "Destination: $DEST_DIR"
echo "Copied: ${#copied[@]}"
if [[ "${#missing[@]}" -gt 0 ]]; then
  echo "Missing: ${#missing[@]}"
  for item in "${missing[@]}"; do
    echo "  - $item"
  done
fi

