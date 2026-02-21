#!/bin/zsh
exec "$(dirname "$0")/pipelines/setup_la_pipeline_cron.sh" "$@"
