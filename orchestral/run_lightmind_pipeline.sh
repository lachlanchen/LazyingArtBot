#!/bin/zsh
exec "$(dirname "$0")/pipelines/run_lightmind_pipeline.sh" "$@"
