#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
PIPELINE_SCRIPT="$REPO_DIR/orchestral/pipelines/run_lazyingart_pipeline.sh"
LOG_DIR="${TMPDIR:-/tmp}/lazyingart_pipeline_runs"
mkdir -p "$LOG_DIR"

RUN_ID="$(TZ=Asia/Hong_Kong date '+%Y%m%d-%H%M%S')"
STDOUT_LOG="$LOG_DIR/lazyingart_pipeline_${RUN_ID}.out.log"
STDERR_LOG="$LOG_DIR/lazyingart_pipeline_${RUN_ID}.err.log"
LAUNCH_LOG="$LOG_DIR/lazyingart_pipeline_${RUN_ID}.launch.log"

{
  echo "[lazyingart-async] run_id=$RUN_ID args=$*"
  echo "[lazyingart-async] command=$PIPELINE_SCRIPT"
} | tee -a "$LAUNCH_LOG"

nohup "$PIPELINE_SCRIPT" "$@" >"$STDOUT_LOG" 2>"$STDERR_LOG" &
PID=$!

echo "Launched Lazying.art pipeline pid=$PID run_id=$RUN_ID"
echo "stdout=$STDOUT_LOG"
echo "stderr=$STDERR_LOG"

echo "[lazyingart-async] launched pid=$PID" >> "$LAUNCH_LOG"
