#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

TZ_NAME="Asia/Hong_Kong"
JOB_NAME_AM="LazyingArt Pipeline 08:00 HK"
JOB_NAME_PM="LazyingArt Pipeline 20:00 HK"
TO_ADDR="lachchen@qq.com"
FROM_ADDR="lachlan.miao.chen@gmail.com"
MODEL="gpt-5.1-codex-mini"
REASONING="medium"

usage() {
  cat <<'USAGE'
Usage: setup_la_pipeline_cron.sh [options]

Creates/refreshes OpenClaw cron jobs (08:00 + 20:00 Asia/Hong_Kong) that trigger
the Lazying.art pipeline script through agent exec.

Options:
  --to <email>            Digest recipient (default: lachchen@qq.com)
  --from <email>          Sender hint (default: lachlan.miao.chen@gmail.com)
  --model <name>          Agent model for cron run (default: gpt-5.1-codex-mini)
  --reasoning <level>     Agent reasoning level (default: medium)
  -h, --help              Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --to)
      shift
      TO_ADDR="${1:-}"
      ;;
    --from)
      shift
      FROM_ADDR="${1:-}"
      ;;
    --model)
      shift
      MODEL="${1:-}"
      ;;
    --reasoning)
      shift
      REASONING="${1:-}"
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

list_json="$(pnpm openclaw cron list --json | sed -n '/^{/,$p')"
existing_ids="$(
  python3 - "$list_json" "$JOB_NAME_AM" "$JOB_NAME_PM" <<'PY'
import json
import sys

data = json.loads(sys.argv[1])
names = {sys.argv[2], sys.argv[3]}
for job in data.get("jobs", []):
    if job.get("name") in names and job.get("id"):
        print(job["id"])
PY
)"

if [[ -n "$existing_ids" ]]; then
  while IFS= read -r jid; do
    [[ -z "$jid" ]] && continue
    pnpm openclaw cron rm "$jid" >/dev/null
  done <<< "$existing_ids"
fi

MESSAGE_TEMPLATE="$(cat <<EOF
Run the local Lazying.art pipeline exactly once.
1) Execute:
\`/Users/lachlan/Local/Clawbot/orchestral/run_la_pipeline.sh --to "$TO_ADDR" --from "$FROM_ADDR" --model "$MODEL" --reasoning "$REASONING"\`
2) If execution fails, report stderr and stop.
3) Do not run other commands.
EOF
)"

pnpm openclaw cron add \
  --name "$JOB_NAME_AM" \
  --cron "0 8 * * *" \
  --tz "$TZ_NAME" \
  --session isolated \
  --message "$MESSAGE_TEMPLATE" \
  --no-deliver \
  >/dev/null

pnpm openclaw cron add \
  --name "$JOB_NAME_PM" \
  --cron "0 20 * * *" \
  --tz "$TZ_NAME" \
  --session isolated \
  --message "$MESSAGE_TEMPLATE" \
  --no-deliver \
  >/dev/null

echo "Configured OpenClaw cron jobs:"
pnpm openclaw cron list
