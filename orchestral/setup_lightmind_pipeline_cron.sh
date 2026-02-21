#!/bin/zsh
exec "$(dirname "$0")/pipelines/setup_lightmind_pipeline_cron.sh" "$@"
