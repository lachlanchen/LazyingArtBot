# Lightmind AutoLife Pipeline (OpenClaw Scheduler)

This pipeline runs at 08:00 and 20:00 (Asia/Hong_Kong) for Lightmind only.

## Scope separation

- Company scope is strictly `Lightmind`.
- Notes, milestones, and mentor outputs write under:
  - iCloud Notes
  - `AutoLife/🏢 Companies/👓 Lightmind.art`
- No reminder-planning step is included in this pipeline.
- Language policy: Chinese-first output with mixed EN/JP labels.
- Academic add-on stage is enabled by default and uses a high-impact paper set (Nature / Cell / Science / CVPR / SIGGRAPH / ICML + arXiv fallback).

## Inputs

- Website: `https://lightmind.art`
- Confidential context root:
  - `/Users/lachlan/Library/Containers/com.tencent.WeWorkMac/Data/WeDrive/LightMind Tech Ltd./LightMind Tech Ltd./LightMind_Confidential`

The pipeline creates a multi-source resource analysis stage per run, then feeds its summary into the market context.

Resource analysis inputs:

- Confidential materials:
  - `/Users/lachlan/Library/Containers/com.tencent.WeWorkMac/Data/WeDrive/LightMind Tech Ltd./LightMind Tech Ltd./LightMind_Confidential`
- Operations inputs:
  - `/Users/lachlan/Documents/LazyingArtBotIO/LightMind/Input`
- Output context:
  - `/Users/lachlan/Documents/LazyingArtBotIO/LightMind/Output`

Results are exported as markdown under:

- `/Users/lachlan/Documents/LazyingArtBotIO/LightMind/Output/ResourceAnalysis/<RUN_ID>`

These markdowns are generated from:

- `prompt_resource_analysis.sh`
- `resource_analysis_prompt.md`
- `resource_analysis_schema.json`

## Chain of tools

1. `prompt_resource_analysis.sh` (confidential + input + output resource profiling)
2. `prompt_la_note_reader.sh` (read current Lightmind milestone note)
3. `prompt_la_market.sh` + `lm_market_research_prompt.md`
4. `prompt_la_market.sh` + `lm_academic_research_prompt.md` (high-impact academic context)
5. `prompt_la_plan.sh` + `lm_plan_draft_prompt.md`
6. `prompt_entrepreneurship_mentor.sh` + `lm_entrepreneurship_mentor_prompt.md`
7. `prompt_la_note_save.sh` (write notes)
8. `codex-email-cli.py` (send rendered HTML digest)

Locking and scheduler behavior:

- `orchestral/run_lightmind_pipeline.sh` uses a run lock file:
  - `$WORKSPACE/AutoLife/MetaNotes/Companies/Lightmind/pipeline_runs/.lightmind_pipeline.lock`
- `orchestral/setup_lightmind_pipeline_cron.sh` runs the async wrapper:
  - `orchestral/run_lightmind_pipeline_async.sh`
- The wrapper launches the full pipeline in background and returns immediately for cron safety.

Coordinator:

- `orchestral/run_lightmind_pipeline.sh`
- Async launcher:
- `orchestral/run_lightmind_pipeline_async.sh`

Scheduler setup:

- `orchestral/setup_lightmind_pipeline_cron.sh`

## Email targets

Default recipients:

- `lachchen@qq.com`
- `ethan@lightmind.art`
- `robbie@lightmind.art`
- `lachlan@lightmind.art`

## Commands

```bash
cd /Users/lachlan/Local/Clawbot
orchestral/run_lightmind_pipeline.sh
```

Run asynchronously:

```bash
cd /Users/lachlan/Local/Clawbot
orchestral/run_lightmind_pipeline_async.sh
```

Dry run (no send):

```bash
orchestral/run_lightmind_pipeline.sh --no-send-email
```

Cron setup:

```bash
orchestral/setup_lightmind_pipeline_cron.sh
```
