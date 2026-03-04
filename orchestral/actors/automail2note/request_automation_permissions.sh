#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: request_automation_permissions.sh [--open-settings]

Purpose:
- Trigger macOS Automation permission prompts for AppleScript access to:
  Reminders, Notes, Calendar, Mail
- This is used to pre-authorize automail2note actions so background runs do not hang.

Options:
  --open-settings   Open Privacy & Security > Automation after probing
EOF
}

OPEN_SETTINGS=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --open-settings)
      OPEN_SETTINGS=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

probe() {
  local app_name="$1"
  local script="$2"
  echo "[probe] osascript -> ${app_name}"
  if osascript -e "$script" >/tmp/automail2note-permission-"${app_name}".out 2>/tmp/automail2note-permission-"${app_name}".err; then
    echo "[ok] ${app_name}"
  else
    local code="$?"
    echo "[warn] ${app_name} probe failed (exit=${code})"
    if [[ -s /tmp/automail2note-permission-"${app_name}".err ]]; then
      sed -n '1,3p' /tmp/automail2note-permission-"${app_name}".err
    fi
  fi
}

echo "Triggering macOS Automation prompts. Click 'Allow' for each app."
probe "Reminders" 'tell application "Reminders" to count of lists'
probe "Notes" 'tell application "Notes" to count of notes'
probe "Calendar" 'tell application "Calendar" to count of calendars'
probe "Mail" 'tell application "Mail" to count of accounts'

if [[ "$OPEN_SETTINGS" == "1" ]]; then
  open "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation" || true
fi

cat <<'EOF'

Done.
Persistent control location:
System Settings > Privacy & Security > Automation

Grant/verify:
- osascript -> Reminders
- osascript -> Notes
- osascript -> Calendar
- osascript -> Mail

If previously denied, toggle back to Allow in Automation settings, then rerun this script once.
EOF
