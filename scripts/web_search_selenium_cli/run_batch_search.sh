#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIPELINE="${SCRIPT_DIR}/batch_search_pipeline.py"

if [[ ! -x "$PIPELINE" ]]; then
  if [[ ! -f "$PIPELINE" ]]; then
    echo "batch pipeline not found: $PIPELINE" >&2
    exit 1
  fi
fi

if [[ "$#" -lt 1 ]]; then
  echo "Usage: run_batch_search.sh --query \"...\" [options]" >&2
  exit 1
fi

python3 "$PIPELINE" "$@"
