#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DEFAULT="$SCRIPT_DIR/../orchestral/actors/automail2note/install_automail2note_workspace.sh"

"$TARGET_DEFAULT" "$@"
