#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: codex-noninteractive.sh [options]

Run Codex in non-interactive mode with explicit model/reasoning settings.

Options:
  --prompt <text>                 Prompt text (or pipe prompt via stdin)
  --model <name>                  Model name (default: CODEX_MODEL or gpt-5.1-codex-mini)
  --reasoning <level>             Reasoning level (default: CODEX_REASONING or medium)
  --output-last-message <path>    Save final assistant message to path
  --output-schema <path>          JSON schema path for structured output
  --json                          Stream Codex JSONL events to stdout
  --skip-git-check                Pass --skip-git-repo-check to codex exec
  --codex-bin <path>              Codex binary (default: codex)
  -h, --help                      Show this help

Examples:
  codex-noninteractive.sh --model gpt-5.1-codex-mini --reasoning medium --prompt "Reply with exactly: OK"
  printf '%s' "Summarize this log" | codex-noninteractive.sh --model gpt-5.3-codex --reasoning low
USAGE
}

PROMPT=""
MODEL="${CODEX_MODEL:-gpt-5.1-codex-mini}"
REASONING="${CODEX_REASONING:-medium}"
OUTPUT_LAST=""
OUTPUT_SCHEMA=""
JSON_OUT=0
SKIP_GIT_CHECK=0
CODEX_BIN="${CODEX_BIN:-codex}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --prompt)
      PROMPT="${2:-}"
      shift
      ;;
    --model)
      MODEL="${2:-}"
      shift
      ;;
    --reasoning)
      REASONING="${2:-}"
      shift
      ;;
    --output-last-message)
      OUTPUT_LAST="${2:-}"
      shift
      ;;
    --output-schema)
      OUTPUT_SCHEMA="${2:-}"
      shift
      ;;
    --json)
      JSON_OUT=1
      ;;
    --skip-git-check)
      SKIP_GIT_CHECK=1
      ;;
    --codex-bin)
      CODEX_BIN="${2:-}"
      shift
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

if ! command -v "$CODEX_BIN" >/dev/null 2>&1; then
  echo "codex executable not found: $CODEX_BIN" >&2
  exit 1
fi

if [ -z "$PROMPT" ]; then
  if [ -t 0 ]; then
    echo "No prompt provided. Use --prompt or pipe input via stdin." >&2
    exit 1
  fi
  PROMPT="$(cat)"
fi

if [ -z "$PROMPT" ]; then
  echo "Prompt is empty." >&2
  exit 1
fi

cleanup_output_last=0
if [ -z "$OUTPUT_LAST" ]; then
  OUTPUT_LAST="$(mktemp)"
  cleanup_output_last=1
fi

CMD=(
  "$CODEX_BIN"
  exec
  --model "$MODEL"
  -c "model_reasoning_effort=\"$REASONING\""
  --output-last-message "$OUTPUT_LAST"
)

if [ "$SKIP_GIT_CHECK" -eq 1 ]; then
  CMD+=(--skip-git-repo-check)
fi

if [ -n "$OUTPUT_SCHEMA" ]; then
  CMD+=(--output-schema "$OUTPUT_SCHEMA")
fi

if [ "$JSON_OUT" -eq 1 ]; then
  CMD+=(--json)
fi

CMD+=(-)

if [ "$JSON_OUT" -eq 1 ]; then
  printf "%s" "$PROMPT" | "${CMD[@]}"
else
  # Keep output deterministic: print only the final assistant message.
  stderr_log="$(mktemp)"
  if ! printf "%s" "$PROMPT" | "${CMD[@]}" >/dev/null 2>"$stderr_log"; then
    cat "$stderr_log" >&2
    rm -f "$stderr_log"
    exit 1
  fi
  rm -f "$stderr_log"
  cat "$OUTPUT_LAST"
fi

if [ "$cleanup_output_last" -eq 1 ]; then
  rm -f "$OUTPUT_LAST"
fi
