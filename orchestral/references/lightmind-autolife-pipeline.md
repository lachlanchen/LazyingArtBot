# Lightmind AutoLife Pipeline (OpenClaw Scheduler)

This pipeline runs at 08:00 and 20:00 (Asia/Hong_Kong) for Lightmind only.

## Scope separation

- Company scope is strictly `Lightmind`.
- Notes, milestones, and mentor outputs write under:
  - iCloud Notes
  - `AutoLife/🏢 Companies/👓 Lightmind.art`
- Lightmind now includes a life reverse planning stage by default (driven by
  `prompt_life_reverse_engineering_tool.sh`) and writes stateful reminders under the
  Lightmind Life Reverse notes.
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
5. `prompt_funding_vc.sh` (funding, VC, grant and partnership opportunities)
6. `prompt_money_revenue.sh` (monetization and revenue strategy)
7. `prompt_la_plan.sh` + `lm_plan_draft_prompt.md`
8. `prompt_entrepreneurship_mentor.sh` + `lm_entrepreneurship_mentor_prompt.md`
9. `prompt_la_note_save.sh` (write notes)
10. `prompt_life_reverse_engineering_tool.sh` + `life state` files
11. `prompt_la_note_save.sh` (append `🗓️ Lightmind Life Reverse Plan / 反向規劃`)
12. `codex-email-cli.py` (send rendered HTML digest)

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

## Primary notes

- `🧠 Lightmind Market Intel / 市場情報ログ` (append)
- `🏦 Lightmind Funding & VC Opportunities / 融资与VC机会 / 融資與VC機會` (append)
- `💰 盈利模式與增長策略 / 収益化戦略 / 收益战略` (append)
- `💡 Lightmind Milestones / 里程碑 / マイルストーン` (replace)
- `🧭 Lightmind Entrepreneurship Mentor / 創業メンター / 創業導航` (append)
- `🗓️ Lightmind Life Reverse Plan / 反向規劃` (append)
- `🪵 Lightmind Pipeline Log / ログ / 日誌` (append)

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
