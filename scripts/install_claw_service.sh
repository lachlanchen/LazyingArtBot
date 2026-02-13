#!/usr/bin/env bash
set -euo pipefail

if ! command -v systemctl >/dev/null 2>&1; then
  echo "systemctl is not available on this machine."
  echo "On macOS, use: scripts/install_claw_service_mac.sh"
  exit 1
fi

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo $0"
  exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
START_SCRIPT="${REPO_DIR}/scripts/start-openclaw-tmux.sh"
STOP_SCRIPT="${REPO_DIR}/scripts/stop-openclaw-tmux.sh"

SERVICE_NAME="${OPENCLAW_SERVICE_NAME:-openclaw-tmux.service}"
SESSION_NAME="${OPENCLAW_TMUX_SESSION:-openclaw}"
RUN_USER="${OPENCLAW_SERVICE_USER:-${SUDO_USER:-$(id -un)}}"
RUN_HOME="$(eval echo "~${RUN_USER}")"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"

if [[ ! -x "${START_SCRIPT}" ]]; then
  echo "Start script missing or not executable: ${START_SCRIPT}"
  exit 1
fi

if [[ ! -x "${STOP_SCRIPT}" ]]; then
  echo "Stop script missing or not executable: ${STOP_SCRIPT}"
  exit 1
fi

if ! id "${RUN_USER}" >/dev/null 2>&1; then
  echo "Service user does not exist: ${RUN_USER}"
  exit 1
fi

cat > "${SERVICE_PATH}" <<EOF
[Unit]
Description=OpenClaw tmux gateway session
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
User=${RUN_USER}
WorkingDirectory=${REPO_DIR}
Environment=HOME=${RUN_HOME}
Environment=SHELL=/bin/bash
ExecStart=${START_SCRIPT} ${SESSION_NAME} detach
ExecStop=${STOP_SCRIPT} ${SESSION_NAME}
TimeoutStartSec=120
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable "${SERVICE_NAME}"

echo "Installed and enabled ${SERVICE_NAME}"
echo "Start:  sudo systemctl start ${SERVICE_NAME}"
echo "Stop:   sudo systemctl stop ${SERVICE_NAME}"
echo "Status: sudo systemctl status ${SERVICE_NAME}"
