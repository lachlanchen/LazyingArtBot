#!/usr/bin/env zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
PROMPT_TOOL="$REPO_DIR/orchestral/prompt_tools/prompt_resource_analysis.sh"

RUN_ID="$(TZ=Asia/Hong_Kong date '+%Y%m%d-%H%M%S')"
COMPANY="Company"
MARKDOWN_OUTPUT=""
OUTPUT_DIR=""
MODEL="gpt-5.1-codex-mini"
REASONING="medium"
MAX_MANIFEST_FILES=500
MAX_TEXT_SNIPPETS=40000
RESOURCE_ROOTS=()

usage() {
  cat <<'USAGE'
Usage: run_resource_analysis.sh [options]

Run resource analysis for a company and generate reference markdowns.

Options:
  --company <name>               Company label (required)
  --resource-root <path>         Add resource root (repeatable)
  --markdown-output <path>       Output markdown folder (if omitted, generated automatically)
  --output-dir <path>            Codex artifact base directory (if omitted: /tmp/<company>-resource-analysis)
  --model <name>                 Codex model (default: gpt-5.1-codex-mini)
  --reasoning <level>            Reasoning level (default: medium)
  --max-manifest-files <n>       Manifest files per root (default: 500)
  --max-text-snippets <n>        Snippet text cap (default: 40000)
  -h, --help                    Show help
USAGE
}

sanitize_label() {
  local label="$1"
  label="${label// /-}"
  label="${label//[^A-Za-z0-9._-]/-}"
  while [[ "$label" == -* ]]; do
    label="${label#-}"
  done
  while [[ "$label" == *- ]]; do
    label="${label%-}"
  done
  if [[ -z "$label" ]]; then
    label="company"
  fi
  print -r -- "$label"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --company)
      shift
      COMPANY="${1:-}"
      ;;
    --resource-root)
      shift
      RESOURCE_ROOTS+=("${1:-}")
      ;;
    --markdown-output)
      shift
      MARKDOWN_OUTPUT="${1:-}"
      ;;
    --output-dir)
      shift
      OUTPUT_DIR="${1:-}"
      ;;
    --model)
      shift
      MODEL="${1:-}"
      ;;
    --reasoning)
      shift
      REASONING="${1:-}"
      ;;
    --max-manifest-files)
      shift
      MAX_MANIFEST_FILES="${1:-500}"
      ;;
    --max-text-snippets)
      shift
      MAX_TEXT_SNIPPETS="${1:-40000}"
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

if [[ -z "$COMPANY" || "$COMPANY" == "Company" ]]; then
  echo "--company is required." >&2
  usage >&2
  exit 1
fi

if [[ "${#RESOURCE_ROOTS[@]}" -eq 0 ]]; then
  echo "At least one --resource-root is required." >&2
  usage >&2
  exit 1
fi

safe_slug=$(sanitize_label "$COMPANY")
if [[ -z "$OUTPUT_DIR" ]]; then
  OUTPUT_DIR="/tmp/${safe_slug}-resource-analysis"
fi

if [[ -z "$MARKDOWN_OUTPUT" ]]; then
  MARKDOWN_OUTPUT="$HOME/Documents/LazyingArtBotIO/${safe_slug}/Output/ResourceAnalysis/$RUN_ID"
fi

mkdir -p "$OUTPUT_DIR" "$MARKDOWN_OUTPUT"

echo "[resource-profile] company=$COMPANY run_id=$RUN_ID"

aargs=(--company "$COMPANY" --output-dir "$OUTPUT_DIR" --markdown-output "$MARKDOWN_OUTPUT" --label "$safe_slug-resource-analysis" --model "$MODEL" --reasoning "$REASONING" --max-manifest-files "$MAX_MANIFEST_FILES" --max-text-snippets "$MAX_TEXT_SNIPPETS")
for root in "${RESOURCE_ROOTS[@]}"; do
  aargs+=(--resource-root "$root")
done

"$PROMPT_TOOL" "${aargs[@]}"

  echo "resource_analysis_markdown_dir=$MARKDOWN_OUTPUT"
echo "codex_output_dir=$OUTPUT_DIR"
