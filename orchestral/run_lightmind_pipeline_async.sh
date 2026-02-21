#!/bin/zsh
exec "$(dirname "$0")/pipelines/run_lightmind_pipeline_async.sh" "$@"
