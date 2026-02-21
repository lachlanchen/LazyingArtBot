#!/bin/zsh
exec "$(dirname "$0")/pipelines/run_la_pipeline.sh" "$@"
