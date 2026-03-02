# Prompt Tools

This directory is the dedicated home for LAB Codex prompt-driven tooling.

## Runtime runners

Runtime entrypoints now live under `runtime/`:

- `runtime/codex-noninteractive.sh`
- `runtime/codex-email-cli.py`
- `runtime/codex-json-runner.py`
- `runtime/run_auto_ops.sh`

Compatibility wrappers are kept at top-level (`orchestral/prompt_tools/*.sh|*.py`) so existing callers continue to work.

## Prompt tool groups

- `company/` company pipeline stage tools (`prompt_la_market.sh`, `prompt_legal_dept.sh`, `prompt_funding_vc.sh`, etc.)
- `websearch/` web/news/search and playlist tools
- `email/` incremental email composition tools
- `notes/` notes read/write/log tools
- `calendar/` calendar planning + account-calendar migration helpers
- `reminders/` quick reminder, daily ritual, groceries helpers
- `migration/` LazyingArt migration planners
- `git/` commit helper wrappers

## Legacy top-level compatibility

Top-level script names remain available as wrappers so cronjobs, automations, and older scripts do not break immediately. New callers should prefer grouped paths.

## Core runners

- `runtime/codex-noninteractive.sh` – Minimal non-interactive Codex wrapper with explicit model/reasoning.
- `runtime/codex-email-cli.py` – Codex-assisted email draft/send flow (Apple Mail).
- `runtime/codex-json-runner.py` – Standard JSON-in / JSON-out Codex runner for reusable automation pipelines.
- `runtime/run_auto_ops.sh` – Helper wrapper that feeds payloads + prompt templates into `codex-json-runner.py` with the AutoLife operations schema.

## AutoLife prompt suite (delegation-first)

| Script                                          | Prompt template                                            | Purpose                                                                                                                   |
| ----------------------------------------------- | ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `websearch/prompt_web_search.sh`                | `websearch/prompt_web_search_prompt.md`                    | Search fallback wrapper that writes query JSON/TXT evidence + screenshots.                                                |
| `websearch/prompt_web_search_immersive.sh`      | `websearch/prompt_web_search_immersive_prompt.md`          | Immersive (UI) Google flow with screenshot capture and optional coordinate click.                                         |
| `websearch/prompt_web_search_batch.sh`          | `websearch/prompt_web_search_batch_prompt.md`              | Batch search + top-N result opening, screenshots, and per-item Codex summaries.                                           |
| `websearch/prompt_web_search_click.sh`          | `websearch/prompt_web_search_click_prompt.md`              | Search, click selected result in same window, and summarize opened page content.                                          |
| `websearch/prompt_youtube_playlist_reorder.sh`  | `websearch/prompt_youtube_playlist_reorder_prompt.md`      | Browser-driven YouTube playlist reorder flow using Selenium-style interactions with screenshots and per-item action logs. |
| `websearch/prompt_web_search_google.sh`         | (wrapper)                                                  | Google search + click-mode helper (default engine google).                                                                |
| `websearch/prompt_web_search_google_scholar.sh` | (wrapper)                                                  | Google Scholar search + click-mode helper.                                                                                |
| `websearch/prompt_web_search_google_news.sh`    | (wrapper)                                                  | Google News search + click-mode helper.                                                                                   |
| `notes/prompt_notes.sh`                         | `notes/notes_prompt.md`                                    | Turn raw context into HTML-ready AutoLife note updates.                                                                   |
| `notes/prompt_quick_notes.sh`                   | `notes/prompt_quick_notes_prompt.md`                       | Fast context-to-note JSON draft without app-side execution.                                                               |
| `calendar/prompt_calendar_and_reminder.sh`      | `calendar/calendar_prompt.md`                              | Decide whether tasks become calendar blocks or reminders.                                                                 |
| `calendar/prompt_quick_calendar.sh`             | `calendar/prompt_quick_calendar_prompt.md`                 | Fast context-to-calendar/reminder planning JSON output.                                                                   |
| `company/prompt_market_research.sh`             | `company/market_research_prompt.md`                        | Generate market intel summaries + suggested actions.                                                                      |
| `company/prompt_company_management.sh`          | `company/company_management_prompt.md`                     | Refine Lazying.art / Lightmind.art operating plans.                                                                       |
| `company/prompt_passive_income.sh`              | `company/passive_income_prompt.md`                         | Produce concrete passive-income opportunity stacks.                                                                       |
| `company/prompt_making_plan.sh`                 | `company/making_plan_prompt.md`                            | Build daily/weekly plans with sequenced steps.                                                                            |
| `notes/prompt_log.sh`                           | `notes/log_prompt.md` (with `notes/log_entry_schema.json`) | Format and append HTML entries to AutoLife › Log (Apple Notes + markdown mirror).                                         |
| `git/prompt_commit_push.sh`                     | `git/commit_summary_prompt.md`                             | Ask Codex to summarize repo changes, then commit & push automatically.                                                    |

All AutoLife-oriented prompts share `auto_ops_schema.json`, which encodes `summary`, `notes`, optional `calendar_events`, `reminders`, `actions`, and `log_entries`. This keeps outputs composable across tools.

Supporting prompt assets:

- `runtime/common_tools.md`
- `runtime/email_send_prompt.md`
- `runtime/email_send_schema.json`
- `runtime/json_task_prompt.md`
- `runtime/auto_ops_schema.json`
- `notes/log_prompt.md`
- `notes/log_entry_schema.json`
- `git/commit_summary_prompt.md`
- `git/commit_summary_schema.json`
- `calendar/account_calendar_search_prompt.md`
- `calendar/account_calendar_search_schema.json`
- `calendar/account_calendar_move_prompt.md`
- `calendar/account_calendar_move_schema.json`
- `company/la_market_research_prompt.md`
- `company/la_plan_draft_prompt.md`
- `company/entrepreneurship_mentor_prompt.md`
- `company/la_ops_schema.json`
- `company/life_reverse_engineering_prompt.md`
- `company/life_reverse_engineering_schema.json`
- `company/life_reverse_reminder_apply.py`
- `company/lm_market_research_prompt.md`
- `company/lm_plan_draft_prompt.md`
- `company/lm_entrepreneurship_mentor_prompt.md`
- `company/resource_analysis_prompt.md`
- `company/resource_analysis_schema.json`
- `websearch/prompt_web_search_prompt.md`
- `web_search_selenium_cli` scripts reference (via `scripts/web_search_selenium_cli/run_search.sh`)

## LazyingArt migration prompt tools

| Script                                            | Prompt template                                   | Purpose                                                                                   |
| ------------------------------------------------- | ------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `migration/prompt_lazyingart_migration_search.sh` | `migration/lazyingart_migration_search_prompt.md` | Codex audit of current source/target migration status using script-produced summary data. |
| `migration/prompt_lazyingart_migration_move.sh`   | `migration/lazyingart_migration_move_prompt.md`   | Codex dry-run review + apply/post-check command planning for LazyingArt migration.        |

## Account-calendar migration prompt tools

| Script                                       | Prompt template                              | Purpose                                                                                      |
| -------------------------------------------- | -------------------------------------------- | -------------------------------------------------------------------------------------------- |
| `calendar/prompt_account_calendar_search.sh` | `calendar/account_calendar_search_prompt.md` | Codex audit for one source account/calendar vs LazyingArt target using resolved calendar id. |
| `calendar/prompt_account_calendar_move.sh`   | `calendar/account_calendar_move_prompt.md`   | Codex planning wrapper for account-calendar move dry-run/apply/post-check flow.              |

These tools explicitly reference the executable migration scripts so Codex reasons from actual automation behavior:

- `orchestral/scripts/search_account_calendar_reminder_summary.sh`
- `orchestral/scripts/move_account_calendar_reminders_to_lazyingart.sh`
- `orchestral/scripts/check_calendar_events.sh`
- `orchestral/scripts/search_account_calendar_events.sh`
- `orchestral/scripts/move_events_from_account_calendar_to_lazyingart.sh`

## Lazying.art daily chain tools (AutoLife output)

| Script                                            | Prompt template                              | Purpose                                                                      |
| ------------------------------------------------- | -------------------------------------------- | ---------------------------------------------------------------------------- |
| `company/prompt_la_market.sh`                     | `company/la_market_research_prompt.md`       | Market+repo analysis focused on `https://lazying.art` and GitHub repos       |
| `company/prompt_la_plan.sh`                       | `company/la_plan_draft_prompt.md`            | Milestone rewrite with mixed EN/中文/日本語 sections + tables                |
| `company/prompt_entrepreneurship_mentor.sh`       | `company/entrepreneurship_mentor_prompt.md`  | Founder guidance and risk/bet framework updates                              |
| `company/prompt_life_reverse_engineering_tool.sh` | `company/life_reverse_engineering_prompt.md` | Fixed-slot life reminder planning (8 horizons) with dedupe-aware apply       |
| `notes/prompt_la_note_reader.sh`                  | (utility)                                    | Reads HTML body from AutoLife Notes                                          |
| `notes/prompt_la_note_save.sh`                    | (utility)                                    | Appends/replaces AutoLife Notes safely                                       |
| `company/prompt_money_revenue.sh`                 | `company/money_revenue_prompt.md`            | Generates monetization and revenue strategy from market/funding/context data |
| `company/prompt_funding_vc.sh`                    | `company/funding_vc_prompt.md`               | Finds funding, VC, grant, and partnership opportunities                      |

## Resource analysis tool (company-wide)

| Script                          | Prompt template               | Purpose                                                                                     |
| ------------------------------- | ----------------------------- | ------------------------------------------------------------------------------------------- |
| `prompt_resource_analysis.sh`   | `resource_analysis_prompt.md` | Collects local resource manifests, extracts bounded snippets, and generates structured JSON |
| `resource_analysis_schema.json` | —                             | Contracts output with `summary`, `resource_overview`, and `markdown_documents`              |

Outputs are written both as:

- codex artifact JSON in `--output-dir`
- generated markdown notes in `--markdown-output` (one summary + recommendations + source-theme notes)

The tool is company-agnostic: pass any `--company` and `--resource-root` paths, then wire
the generated markdowns into any downstream prompt chain for richer context.

Coordinator scripts:

- `orchestral/pipelines/run_lazyingart_pipeline.sh`
- `orchestral/pipelines/setup_lazyingart_pipeline_cron.sh`
- `orchestral/prompt_tools/company/life_reverse_reminder_apply.py`
- `orchestral/pipelines/run_lightmind_pipeline.sh`
- `orchestral/pipelines/setup_lightmind_pipeline_cron.sh`

## Standard paradigm

Use `runtime/codex-json-runner.py` (directly or via `runtime/run_auto_ops.sh`) as common practice:

1. Provide `--input-json` (task payload).
2. Provide `--output-dir` (artifact/result folder).
3. Optionally provide `--schema` to enforce structured output.
4. Keep model/reasoning explicit.

Outputs are standardized per run:

- `request.json`
- `input.json`
- `prompt.txt`
- `result.raw.json`
- `result.json`
- `meta.json`
- `codex.stdout.log`
- `codex.stderr.log`

Plus shared latest pointers:

- `<output-dir>/latest-run.txt`
- `<output-dir>/latest-result.json`

## Example

```bash
python3 orchestral/prompt_tools/runtime/codex-json-runner.py \
  --input-json /tmp/task.json \
  --output-dir /tmp/codex-runs \
  --schema orchestral/prompt_tools/runtime/email_send_schema.json \
  --model gpt-5.3-codex-spark \
  --reasoning high
```

- `docs/AUTOLIFE_PHILOSOPHY.md` – AutoLife capture/automation philosophy and folder layout.
