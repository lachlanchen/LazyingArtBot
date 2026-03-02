# Prompt Tools Reorganization Plan (Analysis-Only, No Move)

This file explains:

1. What `orchestral/prompt_tools` contains.
2. Which systems depend on it (including LazyingArt and Lightmind pipelines).
3. How to reorganize safely without breaking automations.

This is a planning document only.  
No additional file moves are part of this document update.

## What these prompt tools are

`orchestral/prompt_tools` is the Codex automation layer for orchestral workflows.

It has four major kinds of files:

1. Runtime executors
   - `codex-json-runner.py`: JSON-in/JSON-out Codex runner.
   - `codex-email-cli.py`: structured email generation/sending via Apple Mail.
   - `codex-noninteractive.sh`: non-interactive Codex shell wrapper.
   - `run_auto_ops.sh`: helper wrapper for `auto_ops_schema.json`.
2. Prompt templates (`*.md`)
   - Define behavior for market/funding/legal/notes/web-search/etc.
3. Schemas (`*.json`)
   - Enforce output structure for each prompt flow.
4. Script entrypoints (`prompt_*.sh`)
   - Build payload/context, call runtime runners, and optionally apply results to Notes/Calendar/Reminders.

## Key dependency map

## Pipeline dependencies (high priority)

These are direct runtime dependencies and must stay valid:

1. `orchestral/pipelines/run_lazyingart_pipeline.sh`
2. `orchestral/pipelines/run_lightmind_pipeline.sh`

Both pipelines call multiple `prompt_*.sh` entrypoints and runtime tools.  
Any path change here can break morning cron output.

## Secondary orchestration dependencies

1. `orchestral/pipelines.yml`
2. `orchestral/scripts/run_resource_analysis.sh`
3. Playbooks/docs under:
   - `orchestral/references/*.md`
   - `references/*.md`
   - `scripts/web_search_selenium_cli/README.md`

These must be updated for consistency after reorg, even if wrappers keep runtime stable.

## Automail dependency status

Checked paths:

1. `orchestral/actors/automail2note`
2. `~/.openclaw/workspace/automation/automail2note`

Current status:

- No direct hard dependency on `orchestral/prompt_tools` runtime paths was found.
- Automail appears operationally separate from these prompt entrypoints.

Implication:

- Prompt-tools reorg risk to automail is low today.
- Still keep compatibility wrappers to avoid future accidental coupling breakage.

## Reorganization target structure (recommended)

Use domain folders under `orchestral/prompt_tools`:

1. `runtime/`
   - Core executors only (`codex-json-runner.py`, `codex-email-cli.py`, `codex-noninteractive.sh`, `run_auto_ops.sh`).
2. `company/`
   - Company pipeline stage entrypoints (market, legal, funding, money, plan, mentor, life, resource analysis).
3. `websearch/`
   - Web search and playlist prompt entrypoints.
4. `notes/`
   - Notes/log read-write entrypoints.
5. `calendar/`
   - Calendar/account-calendar prompt entrypoints.
6. `reminders/`
   - Quick reminder, daily ritual, groceries entrypoints.
7. `migration/`
   - LazyingArt migration prompt entrypoints.
8. `git/`
   - Commit/push helper entrypoints.

Templates/schemas can remain at top-level initially, then optionally split later.

## Safety constraints for future move

If/when moving files physically, enforce these constraints:

1. Keep old top-level names as wrappers for one migration cycle.
   - Example: `prompt_la_market.sh` remains as `exec` wrapper to new path.
2. Update both pipelines first.
   - `run_lazyingart_pipeline.sh`
   - `run_lightmind_pipeline.sh`
3. Keep runtime import assumptions valid.
   - `runtime/codex-json-runner.py` must still resolve shared prompt files/schemas.
4. Update non-runtime references.
   - `orchestral/pipelines.yml`
   - docs/playbooks
5. Do not remove wrappers until all callers are migrated.

## Concrete migration checklist (when executing reorg)

1. Prepare mapping table
   - old path -> new path for all `prompt_*.sh` + runtime files.
2. Move files
   - move entrypoints into grouped folders.
3. Add compatibility wrappers at old paths
   - shell wrappers for moved `.sh`
   - python shim wrappers for moved `.py`
4. Update hardcoded callers
   - both company pipelines
   - orchestration config/scripts
5. Update docs/references
   - path examples in playbooks and READMEs
6. Run one dry pass per pipeline
   - lazyingart
   - lightmind
7. After stable period, remove wrappers (optional)

## Risk assessment

1. Highest risk: pipeline path breakage causing missed 07:00/08:00 runs.
2. Medium risk: schema path mismatch causing Codex output parse failures.
3. Low current risk: automail direct breakage (no direct runtime link found).

## Rollback strategy

If anything fails after moving:

1. Re-enable old wrappers immediately.
2. Re-point pipeline scripts back to old top-level wrapper paths.
3. Keep grouped folders but defer hard cutover.

This rollback keeps cronjobs and daily email outputs stable.
