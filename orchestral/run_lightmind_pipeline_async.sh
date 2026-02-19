#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
PIPELINE_SCRIPT="$REPO_DIR/orchestral/run_lightmind_pipeline.sh"
LOG_DIR="${TMPDIR:-/tmp}/lightmind_pipeline_runs"
mkdir -p "$LOG_DIR"

RUN_ID="$(TZ=Asia/Hong_Kong date '+%Y%m%d-%H%M%S')"
STDOUT_LOG="$LOG_DIR/lightmind_pipeline_${RUN_ID}.out.log"
STDERR_LOG="$LOG_DIR/lightmind_pipeline_${RUN_ID}.err.log"
LAUNCH_LOG="$LOG_DIR/lightmind_pipeline_${RUN_ID}.launch.log"

{
  echo "[lightmind-async] run_id=$RUN_ID args=$*"
  echo "[lightmind-async] command=$PIPELINE_SCRIPT"
} | tee -a "$LAUNCH_LOG"

nohup "$PIPELINE_SCRIPT" "$@" >"$STDOUT_LOG" 2>"$STDERR_LOG" &
PID=$!

echo "Launched Lightmind pipeline pid=$PID run_id=$RUN_ID"
echo "stdout=$STDOUT_LOG"
echo "stderr=$STDERR_LOG"

echo "[lightmind-async] launched pid=$PID" >> "$LAUNCH_LOG"
