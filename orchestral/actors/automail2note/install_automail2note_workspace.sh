#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-$HOME/.openclaw/workspace/automation}"
SRC_MAIL_APP="${SRC_MAIL_APP:-$HOME/Library/Application Scripts/com.apple.mail}"
RULE_SRC="${RULE_SRC:-$SCRIPT_DIR/lazyingart_simple_rule.applescript}"
RULE_SCPT="${RULE_SCPT:-$SRC_MAIL_APP/Lazyingart Simple Rule.scpt}"

mkdir -p "$TARGET_DIR"

"$SCRIPT_DIR/install_automail2note.sh" "$TARGET_DIR"

if [[ -f "$RULE_SRC" ]] && command -v osacompile >/dev/null 2>&1; then
  if osacompile -o "$RULE_SCPT" "$RULE_SRC" 2>/dev/null; then
    echo "Installed rule script: $RULE_SCPT"
  else
    echo "Warning: osacompile failed; keeping existing $RULE_SCPT if present." >&2
    if [[ ! -f "$RULE_SCPT" ]]; then
      copy_src=""
      if [[ -f "$SCRIPT_DIR/Lazyingart Simple Rule.scpt" ]]; then
        copy_src="$SCRIPT_DIR/Lazyingart Simple Rule.scpt"
      elif [[ -f "$SRC_MAIL_APP/Lazyingart Simple Rule.scpt" ]]; then
        copy_src="$SRC_MAIL_APP/Lazyingart Simple Rule.scpt"
      fi
      if [[ -n "$copy_src" ]]; then
        cp -p "$copy_src" "$RULE_SCPT"
        echo "Fallback copied rule script from local source: $copy_src"
      fi
    fi
  fi
else
  echo "Warning: osacompile not available; skipping rule compilation." >&2
fi

echo "Automail2note workspace sync finished: $TARGET_DIR"
