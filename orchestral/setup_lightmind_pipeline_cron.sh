#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

TZ_NAME="Asia/Hong_Kong"
JOB_NAME_AM="Lightmind Pipeline 07:00 HK"
JOB_NAME_PM="Lightmind Pipeline 19:00 HK"
MODEL="gpt-5.3-codex-spark"
REASONING="xhigh"
RUN_LIFE_REMINDER=1
RUN_LEGAL_DEPT=1
LIFE_INPUT_MD="/Users/lachlan/Documents/LazyingArtBotIO/LightMind/Input/PitchDemoTraning.md"
LIFE_STATE_JSON="/Users/lachlan/.openclaw/workspace/AutoLife/MetaNotes/Companies/Lightmind/lightmind_life_reminder_state.json"
LIFE_STATE_MD="/Users/lachlan/Documents/LazyingArtBotIO/LightMind/Output/LightMindLifeReminderState.md"

usage() {
  cat <<'USAGE'
Usage: setup_lightmind_pipeline_cron.sh [options]

Creates/refreshes OpenClaw cron jobs (07:00 + 19:00 Asia/Hong_Kong) that trigger
the Lightmind pipeline script through agent exec.

Options:
  --model <name>          Agent model for cron run (default: gpt-5.3-codex-spark)
  --reasoning <level>     Reasoning level (default: xhigh)
  --life-reminder         Enable life reverse planning (default: on)
  --no-life-reminder      Disable life reverse planning
  --legal-dept            Enable legal compliance review (default: on)
  --no-legal-dept         Disable legal compliance review
  --life-input-md <path>  Life reverse input markdown path
  --life-state-json <path> Life reverse state JSON path
  --life-state-md <path>  Life reverse state markdown path
  -h, --help              Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model)
      shift
      MODEL="${1:-}"
      ;;
    --reasoning)
      shift
      REASONING="${1:-}"
      ;;
    --life-reminder)
      RUN_LIFE_REMINDER=1
      ;;
    --no-life-reminder)
      RUN_LIFE_REMINDER=0
      ;;
    --legal-dept)
      RUN_LEGAL_DEPT=1
      ;;
    --no-legal-dept)
      RUN_LEGAL_DEPT=0
      ;;
    --life-input-md)
      shift
      LIFE_INPUT_MD="${1:-}"
      ;;
    --life-state-json)
      shift
      LIFE_STATE_JSON="${1:-}"
      ;;
    --life-state-md)
      shift
      LIFE_STATE_MD="${1:-}"
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

if ! command -v pnpm >/dev/null 2>&1; then
  echo "pnpm is required to manage OpenClaw cron." >&2
  exit 1
fi

list_json="$(pnpm openclaw cron list --json | sed -n '/^{/,$p')"
existing_ids="$(
  python3 - "$list_json" <<'PY'
import json
import sys

data = json.loads(sys.argv[1])
for job in data.get("jobs", []):
  name = job.get("name", "")
  if name.startswith("Lightmind Pipeline ") and job.get("id"):
    print(job["id"])
PY
)"

if [[ -n "$existing_ids" ]]; then
  while IFS= read -r jid; do
    [[ -z "$jid" ]] && continue
    pnpm openclaw cron rm "$jid" >/dev/null
  done <<< "$existing_ids"
fi

if [[ "$RUN_LIFE_REMINDER" == "1" ]]; then
  LIFE_ARGS=(
    --life-reminder
    --life-input-md "$LIFE_INPUT_MD"
    --life-state-json "$LIFE_STATE_JSON"
    --life-state-md "$LIFE_STATE_MD"
  )
else
  LIFE_ARGS=(--no-life-reminder)
fi

if [[ "$RUN_LEGAL_DEPT" == "1" ]]; then
  LEGAL_ARGS=(--legal-dept)
else
  LEGAL_ARGS=(--no-legal-dept)
fi

MESSAGE_TEMPLATE="$(cat <<EOF
Run the local Lightmind pipeline exactly once via async launcher.
1) Execute:
$REPO_DIR/orchestral/run_lightmind_pipeline_async.sh \
  --model \"$MODEL\" --reasoning \"$REASONING\" \\
$(printf '  %q ' "${LEGAL_ARGS[@]}")
$(printf '  %q ' "${LIFE_ARGS[@]}")
2) The launcher returns quickly; pipeline logs are written under /tmp/lightmind_pipeline_runs.
3) Run a full cycle (resource analysis + context refresh) by default.
4) Save and summarize outputs in the current Lightmind run directory.
   Focus on run-local summary files and web-search context:
   web_search.summary.txt, web_search_digest.html, and open-item evidence from the same run.
5) If execution fails, report stderr and stop.
6) Do not run other commands.
EOF
)"

pnpm openclaw cron add \
  --name "$JOB_NAME_AM" \
  --cron "0 7 * * *" \
  --tz "$TZ_NAME" \
  --session isolated \
  --message "$MESSAGE_TEMPLATE" \
  --no-deliver \
  >/dev/null

pnpm openclaw cron add \
  --name "$JOB_NAME_PM" \
  --cron "0 19 * * *" \
  --tz "$TZ_NAME" \
  --session isolated \
  --message "$MESSAGE_TEMPLATE" \
  --no-deliver \
  >/dev/null

echo "Configured OpenClaw cron jobs:"
pnpm openclaw cron list
