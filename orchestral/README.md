# Orchestral

This directory contains the project orchestration stack for LAB automations.

## Structure

- `orchestral/pipelines/` – executable pipeline entrypoints (sync/async + cron setup)
  - `run_lazyingart_pipeline.sh`
  - `run_lazyingart_pipeline_async.sh`
  - `run_lightmind_pipeline.sh`
  - `run_lightmind_pipeline_async.sh`
  - `setup_lazyingart_pipeline_cron.sh`
  - `setup_lightmind_pipeline_cron.sh`
- `orchestral/prompt_tools/` – LAB prompt tools and codex runners
- `orchestral/actors/` – side-effect/automation actors and legacy shell helpers
  - `orchestral/actors/automail2note/` – email automation source package
  - `orchestral/scripts/` – calendar/event helper scripts
- `orchestral/config/` – centralized defaults/paths references
- `orchestral/references/` – pipeline/playbook references
- `orchestral/pipelines.yml` – manifest for available orchestrations

Pipeline entrypoints are maintained in `orchestral/pipelines/`.
