#!/bin/zsh
exec "$(dirname "$0")/pipelines/run_la_pipeline_async.sh" "$@"
