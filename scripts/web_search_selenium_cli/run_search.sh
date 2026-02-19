#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_NAME="${WEB_SEARCH_ENV:-clawbot}"
ARGS=("$@")

if ! command -v conda >/dev/null 2>&1; then
  echo "conda not found in PATH" >&2
  exit 1
fi

# Parse optional env selector
while ((${#ARGS[@]} > 0)); do
  case "${ARGS[0]}" in
    --env)
      if ((${#ARGS[@]} < 2)); then
        echo "--env requires an environment name" >&2
        exit 1
      fi
      ENV_NAME="${ARGS[1]}"
      ARGS=("${ARGS[@]:2}")
      ;;
    --help|-h)
      echo "Usage: $0 [--env clawbot] [search-cli args]"
      echo "Default env: ${ENV_NAME}"
      exit 0
      ;;
    *)
      break
      ;;
  esac
done

conda run -n "${ENV_NAME}" python "${SCRIPT_DIR}/search_cli.py" "${ARGS[@]}"
