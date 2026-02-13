#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This installer is for macOS (launchd) only."
  exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
START_SCRIPT="${REPO_DIR}/scripts/start-openclaw-tmux.sh"
STOP_SCRIPT="${REPO_DIR}/scripts/stop-openclaw-tmux.sh"

if [[ ! -x "${START_SCRIPT}" ]]; then
  echo "Start script missing or not executable: ${START_SCRIPT}"
  exit 1
fi

if [[ ! -x "${STOP_SCRIPT}" ]]; then
  echo "Stop script missing or not executable: ${STOP_SCRIPT}"
  exit 1
fi

LABEL="${OPENCLAW_LAUNCHD_LABEL:-ai.openclaw.tmux}"
SESSION_NAME="${OPENCLAW_TMUX_SESSION:-openclaw}"
PLIST_DIR="${HOME}/Library/LaunchAgents"
PLIST_PATH="${PLIST_DIR}/${LABEL}.plist"
LOG_DIR="${HOME}/Library/Logs"
STDOUT_LOG="${LOG_DIR}/${LABEL}.out.log"
STDERR_LOG="${LOG_DIR}/${LABEL}.err.log"
UID_NUM="$(id -u)"

mkdir -p "${PLIST_DIR}" "${LOG_DIR}"

cat > "${PLIST_PATH}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>

  <key>ProgramArguments</key>
  <array>
    <string>${START_SCRIPT}</string>
    <string>${SESSION_NAME}</string>
    <string>detach</string>
  </array>

  <key>WorkingDirectory</key>
  <string>${REPO_DIR}</string>

  <key>RunAtLoad</key>
  <true/>

  <key>KeepAlive</key>
  <false/>

  <key>EnvironmentVariables</key>
  <dict>
    <key>HOME</key>
    <string>${HOME}</string>
    <key>PATH</key>
    <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${HOME}/Library/pnpm:${HOME}/miniconda3/bin</string>
  </dict>

  <key>StandardOutPath</key>
  <string>${STDOUT_LOG}</string>
  <key>StandardErrorPath</key>
  <string>${STDERR_LOG}</string>
</dict>
</plist>
EOF

# Reload cleanly if it already exists.
launchctl bootout "gui/${UID_NUM}/${LABEL}" >/dev/null 2>&1 || true
launchctl bootstrap "gui/${UID_NUM}" "${PLIST_PATH}"
launchctl enable "gui/${UID_NUM}/${LABEL}"
launchctl kickstart -k "gui/${UID_NUM}/${LABEL}"

echo "Installed LaunchAgent: ${LABEL}"
echo "Plist: ${PLIST_PATH}"
echo "Start: launchctl kickstart -k gui/${UID_NUM}/${LABEL}"
echo "Stop:  launchctl bootout gui/${UID_NUM}/${LABEL} && ${STOP_SCRIPT} ${SESSION_NAME}"
echo "View:  launchctl print gui/${UID_NUM}/${LABEL}"
