# Lazying.art AutoLife Pipeline (OpenClaw Scheduler)

This pipeline runs at 08:00 and 20:00 (Asia/Hong_Kong) and updates AutoLife notes, life reminders, and HTML email digest.

## Chain of tools

1. `prompt_la_market.sh`
   - Online research + GitHub scan context
   - Outputs note HTML for `🧠 Market Intel Digest / 市場情報ログ`
2. `prompt_la_note_reader.sh`
   - Reads current milestones note HTML from AutoLife
3. `prompt_la_plan.sh`
   - Rewrites milestones note with mixed EN/中文/日本語 tables/checklists
4. `prompt_entrepreneurship_mentor.sh`
   - Produces mentor guidance note block
5. `prompt_life_reverse_engineering_tool.sh`
   - Maintains a fixed 8-slot reminder backbone:
     - day_plan_8am
     - tomorrow_plan_8pm
     - week_plan
     - tonight_milestone
     - month_milestone
     - season_milestone
     - half_year_milestone
     - one_year_milestone
   - Dedupes by slot and rolls old open slot reminders forward safely
   - Writes markdown mirrors for audit in `~/Documents/LazyingArtBotIO/LazyingArt/Output/`
6. `prompt_resource_analysis.sh` (via `prompt_resource_analysis.sh` wrapper in pipeline startup)
   - Scans LazyingArt resources (Input/Output + ITIN+Company), writes JSON + markdown digest under `~/Documents/LazyingArtBotIO/LazyingArt/Output/ResourceAnalysis/<run_id>/`
7. `prompt_funding_vc.sh`
   - Builds funding, VC, grant, and partnership opportunities for each run.
8. `prompt_money_revenue.sh`
   - Builds monetization and revenue strategy block with:
     - How to make money
     - Think out of the box
     - 1000-billion reverse-engineering options
9. `prompt_la_note_save.sh`
   - Saves/append note bodies into iCloud Notes under AutoLife
10. `codex-email-cli.py`

- Composes + sends HTML digest email

Coordinator:

- `orchestral/run_la_pipeline.sh`

Scheduler setup:

- `orchestral/setup_la_pipeline_cron.sh`

## AutoLife output notes

All outputs stay under:

- iCloud Notes account
- `AutoLife/🏢 Companies/🐼 Lazying.art`

Primary notes:

- `🧠 Market Intel Digest / 市場情報ログ` (append)
- `🎨 Lazying.art · Milestones / 里程碑 / マイルストーン` (replace)
- `🧭 Entrepreneurship Mentor / 創業メンター / 創業導航` (append)
- `🏦 Funding & VC Opportunities / 融资与VC机会 / 融資與VC機會` (append)
- `💰 Monetization & Revenue Strategy / 變現與收益 / 収益化戦略` (append)
- `🗓️ Life Reverse Plan / 反向规划 / 逆算計画` (replace)
- `🪵 Lazying.art Pipeline Log / ログ / 日誌` (append)

Reminder planning input:

- `~/Documents/LazyingArtBotIO/LazyingArt/Input/LazyingArtCompanyInput.md`
  - Reminder state mirror: `~/Documents/LazyingArtBotIO/LazyingArt/Output/LazyingArtLifeReminderState.md`
  - Auto-created with detailed template if missing.

## One-time setup

```bash
cd /Users/lachlan/Local/Clawbot
chmod +x orchestral/run_la_pipeline.sh orchestral/setup_la_pipeline_cron.sh
chmod +x orchestral/prompt_tools/prompt_la_market.sh orchestral/prompt_tools/prompt_la_plan.sh
chmod +x orchestral/prompt_tools/prompt_entrepreneurship_mentor.sh
chmod +x orchestral/prompt_tools/prompt_life_reverse_engineering_tool.sh
chmod +x orchestral/prompt_tools/prompt_la_note_reader.sh orchestral/prompt_tools/prompt_la_note_save.sh
orchestral/setup_la_pipeline_cron.sh --to lachchen@qq.com --from lachlan.miao.chen@gmail.com
```

## Manual run (after setup)

```bash
orchestral/run_la_pipeline.sh --to lachchen@qq.com --from lachlan.miao.chen@gmail.com
```

Dry-run email only:

```bash
orchestral/run_la_pipeline.sh --to lachchen@qq.com --from lachlan.miao.chen@gmail.com --no-send-email
```

## Why it failed before

- Broken heredoc/script syntax in `run_la_pipeline.sh`.
- Missing env export in prompt wrappers.
- Wrong schema in mentor tool (`purchases_sort_schema.json`) causing invalid result shape.
- No cron jobs existed (`openclaw cron list` returned empty).
