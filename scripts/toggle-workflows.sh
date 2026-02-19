#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: ./scripts/toggle-workflows.sh <disable|enable> [--all]

disable
  Rename active GitHub workflow files (*.yml) to *.yml.disabled.

enable
  Rename disabled GitHub workflow files (*.yml.disabled) back to *.yml.

--all
  Include every workflow file currently in .github/workflows.
  Without --all, only active workflows are targeted for disable, or disabled
  workflows are targeted for enable.
USAGE
}

MODE="${1:-}"
ALL=0

if [ "$#" -eq 0 ]; then
  usage
  exit 1
fi

shift || true

while [ "$#" -gt 0 ]; do
  case "${1:-}" in
    --all)
      ALL=1
      ;;
    *)
      usage
      exit 1
      ;;
  esac
  shift
done

WORKFLOW_DIR="${WORKFLOW_DIR:-$(cd "$(dirname "$0")/.." && pwd)/.github/workflows}"

if [ ! -d "$WORKFLOW_DIR" ]; then
  echo "Missing workflow directory: $WORKFLOW_DIR" >&2
  exit 1
fi

to_disable() {
  local file="$1"
  local base
  base="$(basename "$file")"
  [ "$base" = "ci.yml.disabled" ] && return 0
  mv "$file" "$file.disabled"
}

to_enable() {
  local file="$1"
  local base
  base="$(basename "$file")"
  local enabled_file="${file%.disabled}"
  mv "$file" "$enabled_file"
}

case "$MODE" in
  disable)
    for workflow in "$WORKFLOW_DIR"/*.yml; do
      [ -f "$workflow" ] || continue
      if [ "$ALL" -eq 1 ] || [[ "$workflow" != *.yml.disabled ]]; then
        if [[ "$workflow" == *.yml ]]; then
          if [[ "$workflow" == "$WORKFLOW_DIR/ci.yml" ]]; then
            echo "skip: $workflow (kept manually disabled as .yml.disabled baseline)"
          else
            to_disable "$workflow"
            echo "disabled: $(basename "$workflow")"
          fi
        fi
      fi
    done
    ;;
  enable)
    for workflow in "$WORKFLOW_DIR"/*.yml.disabled; do
      [ -f "$workflow" ] || continue
      if [ "$ALL" -eq 1 ] || [ "$(basename "${workflow%.disabled}")" != "ci.yml" ]; then
        to_enable "$workflow"
        echo "enabled: $(basename "$workflow")"
      fi
    done
    ;;
  *)
    usage
    exit 1
    ;;
esac

