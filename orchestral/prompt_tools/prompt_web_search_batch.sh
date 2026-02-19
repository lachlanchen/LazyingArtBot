#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: prompt_web_search_batch.sh [options]

Run Selenium batch web search and summarize top results in one pass.

Options:
  --query <text>              Required query text
  --kind auto|general|scholar|news   Search kind (default: auto)
  --engine <google|google-scholar|google-news|duckduckgo|bing>  Override for general/auto
  --top-results <n>           Number of top links to open per query
  --scroll-steps <n>          Scroll steps for opened pages
  --scroll-pause <seconds>    Pause between scroll steps
  --summary-max-chars <n>     Max chars in source summary text
  --output-dir <path>         Run output root
  --run-id <id>               Optional run id
  --env <conda-env>           Conda env used by run_search.sh
  --headless                  Run browser headless
  --no-codex                  Skip post-search Codex summarization
  --keep-open                 Keep browser open after run
  --hold-seconds <seconds>    Keep-open duration (default 0.0)
  --conda-run <path>          run_search wrapper path
  --codex-model <model>       Codex model for summaries (default: gpt-5.3-codex-spark)
  --codex-reasoning <level>   Codex reasoning level
  --codex-safety <mode>       Codex safety mode
  --codex-approval <policy>   Codex approval policy
  --help

Output:
  - search_batch_result.json
  - search_batch_summary.md
  - items/result-XX.md
  - screenshots/*.png
USAGE
  exit 1
}

REPO_DIR="/Users/lachlan/Local/Clawbot"
RUN_TOOL="${REPO_DIR}/scripts/web_search_selenium_cli/batch_search_pipeline.py"
QUERY=""
KIND="auto"
ENGINE="google"
TOP_RESULTS="3"
SCROLL_STEPS="2"
SCROLL_PAUSE="0.8"
SUMMARY_MAX_CHARS="2200"
OUTPUT_DIR="${HOME}/.openclaw/workspace/AutoLife/MetaNotes/web_search_runs"
RUN_ID=""
ENV_NAME="${WEB_SEARCH_ENV:-clawbot}"
CONDA_RUN="${REPO_DIR}/scripts/web_search_selenium_cli/run_search.sh"
HEADLESS=0
NO_CODEX=0
KEEP_OPEN=0
HOLD_SECONDS="0.0"
CODEX_MODEL="${CODEX_MODEL:-gpt-5.3-codex-spark}"
CODEX_REASONING="${CODEX_REASONING:-high}"
CODEX_SAFETY="${CODEX_SAFETY:-danger-full-access}"
CODEX_APPROVAL="${CODEX_APPROVAL:-never}"

while [[ "${#@}" -gt 0 ]]; do
  case "$1" in
    --query)
      shift
      [[ "$#" -gt 0 ]] || { echo "--query requires a value" >&2; exit 1; }
      QUERY="$1"
      ;;
    --kind)
      shift
      [[ "$#" -gt 0 ]] || { echo "--kind requires a value" >&2; exit 1; }
      KIND="$1"
      ;;
    --engine)
      shift
      [[ "$#" -gt 0 ]] || { echo "--engine requires a value" >&2; exit 1; }
      ENGINE="$1"
      ;;
    --top-results)
      shift
      [[ "$#" -gt 0 ]] || { echo "--top-results requires a value" >&2; exit 1; }
      TOP_RESULTS="$1"
      ;;
    --scroll-steps)
      shift
      [[ "$#" -gt 0 ]] || { echo "--scroll-steps requires a value" >&2; exit 1; }
      SCROLL_STEPS="$1"
      ;;
    --scroll-pause)
      shift
      [[ "$#" -gt 0 ]] || { echo "--scroll-pause requires a value" >&2; exit 1; }
      SCROLL_PAUSE="$1"
      ;;
    --summary-max-chars)
      shift
      [[ "$#" -gt 0 ]] || { echo "--summary-max-chars requires a value" >&2; exit 1; }
      SUMMARY_MAX_CHARS="$1"
      ;;
    --output-dir)
      shift
      [[ "$#" -gt 0 ]] || { echo "--output-dir requires a value" >&2; exit 1; }
      OUTPUT_DIR="$1"
      ;;
    --run-id)
      shift
      [[ "$#" -gt 0 ]] || { echo "--run-id requires a value" >&2; exit 1; }
      RUN_ID="$1"
      ;;
    --env)
      shift
      [[ "$#" -gt 0 ]] || { echo "--env requires a value" >&2; exit 1; }
      ENV_NAME="$1"
      ;;
    --headless)
      HEADLESS=1
      ;;
    --no-codex)
      NO_CODEX=1
      ;;
    --keep-open)
      KEEP_OPEN=1
      ;;
    --hold-seconds)
      shift
      [[ "$#" -gt 0 ]] || { echo "--hold-seconds requires a value" >&2; exit 1; }
      HOLD_SECONDS="$1"
      ;;
    --conda-run)
      shift
      [[ "$#" -gt 0 ]] || { echo "--conda-run requires a value" >&2; exit 1; }
      CONDA_RUN="$1"
      ;;
    --codex-model)
      shift
      [[ "$#" -gt 0 ]] || { echo "--codex-model requires a value" >&2; exit 1; }
      CODEX_MODEL="$1"
      ;;
    --codex-reasoning)
      shift
      [[ "$#" -gt 0 ]] || { echo "--codex-reasoning requires a value" >&2; exit 1; }
      CODEX_REASONING="$1"
      ;;
    --codex-safety)
      shift
      [[ "$#" -gt 0 ]] || { echo "--codex-safety requires a value" >&2; exit 1; }
      CODEX_SAFETY="$1"
      ;;
    --codex-approval)
      shift
      [[ "$#" -gt 0 ]] || { echo "--codex-approval requires a value" >&2; exit 1; }
      CODEX_APPROVAL="$1"
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      ;;
  esac
  shift
done

if [[ -z "$QUERY" ]]; then
  echo "Missing required --query" >&2
  usage
fi

if [[ ! -x "$RUN_TOOL" ]]; then
  echo "Missing batch search tool: $RUN_TOOL" >&2
  exit 1
fi

args=(
  --query "$QUERY"
  --kind "$KIND"
  --engine "$ENGINE"
  --top-results "$TOP_RESULTS"
  --scroll-steps "$SCROLL_STEPS"
  --scroll-pause "$SCROLL_PAUSE"
  --summary-max-chars "$SUMMARY_MAX_CHARS"
  --output-dir "$OUTPUT_DIR"
  --env "$ENV_NAME"
  --conda-run "$CONDA_RUN"
  --codex-model "$CODEX_MODEL"
  --codex-reasoning "$CODEX_REASONING"
  --codex-safety "$CODEX_SAFETY"
  --codex-approval "$CODEX_APPROVAL"
)

if [[ -n "$RUN_ID" ]]; then
  args+=(--run-id "$RUN_ID")
fi

if [[ "$HEADLESS" -eq 1 ]]; then
  args+=(--headless)
fi
if [[ "$NO_CODEX" -eq 1 ]]; then
  args+=(--no-codex)
fi
if [[ "$KEEP_OPEN" -eq 1 ]]; then
  args+=(--keep-open --hold-seconds "$HOLD_SECONDS")
fi

python3 "$RUN_TOOL" "${args[@]}"
