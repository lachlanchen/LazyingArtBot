# Prompt Tools

This directory is the dedicated home for LAB Codex prompt-driven tooling.

## Core runners

- `codex-noninteractive.sh` – Minimal non-interactive Codex wrapper with explicit model/reasoning.
- `codex-email-cli.py` – Codex-assisted email draft/send flow (Apple Mail).
- `codex-json-runner.py` – Standard JSON-in / JSON-out Codex runner for reusable automation pipelines.
- `run_auto_ops.sh` – Helper wrapper that feeds payloads + prompt templates into `codex-json-runner.py` with the AutoLife operations schema.

## AutoLife prompt suite (delegation-first)

| Script                                | Prompt template                                | Purpose                                                                           |
| ------------------------------------- | ---------------------------------------------- | --------------------------------------------------------------------------------- |
| `prompt_web_search.sh`                | `prompt_web_search_prompt.md`                  | Search fallback wrapper that writes query JSON/TXT evidence + screenshots.        |
| `prompt_web_search_immersive.sh`      | `prompt_web_search_immersive_prompt.md`        | Immersive (UI) Google flow with screenshot capture and optional coordinate click. |
| `prompt_web_search_batch.sh`          | `prompt_web_search_batch_prompt.md`            | Batch search + top-N result opening, screenshots, and per-item Codex summaries.   |
| `prompt_web_search_click.sh`          | `prompt_web_search_click_prompt.md`            | Search, click selected result in same window, and summarize opened page content.  |
| `prompt_web_search_google.sh`         | (wrapper)                                      | Google search + click-mode helper (default engine google).                        |
| `prompt_web_search_google_scholar.sh` | (wrapper)                                      | Google Scholar search + click-mode helper.                                        |
| `prompt_web_search_google_news.sh`    | (wrapper)                                      | Google News search + click-mode helper.                                           |
| `prompt_notes.sh`                     | `notes_prompt.md`                              | Turn raw context into HTML-ready AutoLife note updates.                           |
| `prompt_calendar_and_reminder.sh`     | `calendar_prompt.md`                           | Decide whether tasks become calendar blocks or reminders.                         |
| `prompt_market_research.sh`           | `market_research_prompt.md`                    | Generate market intel summaries + suggested actions.                              |
| `prompt_company_management.sh`        | `company_management_prompt.md`                 | Refine Lazying.art / Lightmind.art operating plans.                               |
| `prompt_passive_income.sh`            | `passive_income_prompt.md`                     | Produce concrete passive-income opportunity stacks.                               |
| `prompt_making_plan.sh`               | `making_plan_prompt.md`                        | Build daily/weekly plans with sequenced steps.                                    |
| `prompt_log.sh`                       | `log_prompt.md` (with `log_entry_schema.json`) | Format and append HTML entries to AutoLife › Log (Apple Notes + markdown mirror). |
| `prompt_commit_push.sh`               | `commit_summary_prompt.md`                     | Ask Codex to summarize repo changes, then commit & push automatically.            |

All AutoLife-oriented prompts share `auto_ops_schema.json`, which encodes `summary`, `notes`, optional `calendar_events`, `reminders`, `actions`, and `log_entries`. This keeps outputs composable across tools.

Supporting prompt assets:

- `common_tools.md`
- `email_send_prompt.md`
- `email_send_schema.json`
- `json_task_prompt.md`
- `auto_ops_schema.json`
- `log_prompt.md`
- `log_entry_schema.json`
- `commit_summary_prompt.md`
- `commit_summary_schema.json`
- `account_calendar_search_prompt.md`
- `account_calendar_search_schema.json`
- `account_calendar_move_prompt.md`
- `account_calendar_move_schema.json`
- `la_market_research_prompt.md`
- `la_plan_draft_prompt.md`
- `entrepreneurship_mentor_prompt.md`
- `la_ops_schema.json`
- `life_reverse_engineering_prompt.md`
- `life_reverse_engineering_schema.json`
- `life_reverse_reminder_apply.py`
- `lm_market_research_prompt.md`
- `lm_plan_draft_prompt.md`
- `lm_entrepreneurship_mentor_prompt.md`
- `resource_analysis_prompt.md`
- `resource_analysis_schema.json`
- `prompt_web_search_prompt.md`
- `web_search_selenium_cli` scripts reference (via `scripts/web_search_selenium_cli/run_search.sh`)

## LazyingArt migration prompt tools

| Script                                  | Prompt template                         | Purpose                                                                                   |
| --------------------------------------- | --------------------------------------- | ----------------------------------------------------------------------------------------- |
| `prompt_lazyingart_migration_search.sh` | `lazyingart_migration_search_prompt.md` | Codex audit of current source/target migration status using script-produced summary data. |
| `prompt_lazyingart_migration_move.sh`   | `lazyingart_migration_move_prompt.md`   | Codex dry-run review + apply/post-check command planning for LazyingArt migration.        |

## Account-calendar migration prompt tools

| Script                              | Prompt template                     | Purpose                                                                                      |
| ----------------------------------- | ----------------------------------- | -------------------------------------------------------------------------------------------- |
| `prompt_account_calendar_search.sh` | `account_calendar_search_prompt.md` | Codex audit for one source account/calendar vs LazyingArt target using resolved calendar id. |
| `prompt_account_calendar_move.sh`   | `account_calendar_move_prompt.md`   | Codex planning wrapper for account-calendar move dry-run/apply/post-check flow.              |

These tools explicitly reference the executable migration scripts so Codex reasons from actual automation behavior:

- `orchestral/scripts/search_account_calendar_reminder_summary.sh`
- `orchestral/scripts/move_account_calendar_reminders_to_lazyingart.sh`
- `orchestral/scripts/check_calendar_events.sh`
- `orchestral/scripts/search_account_calendar_events.sh`
- `orchestral/scripts/move_events_from_account_calendar_to_lazyingart.sh`

## Lazying.art daily chain tools (AutoLife output)

| Script                                    | Prompt template                      | Purpose                                                                      |
| ----------------------------------------- | ------------------------------------ | ---------------------------------------------------------------------------- |
| `prompt_la_market.sh`                     | `la_market_research_prompt.md`       | Market+repo analysis focused on `https://lazying.art` and GitHub repos       |
| `prompt_la_plan.sh`                       | `la_plan_draft_prompt.md`            | Milestone rewrite with mixed EN/中文/日本語 sections + tables                |
| `prompt_entrepreneurship_mentor.sh`       | `entrepreneurship_mentor_prompt.md`  | Founder guidance and risk/bet framework updates                              |
| `prompt_life_reverse_engineering_tool.sh` | `life_reverse_engineering_prompt.md` | Fixed-slot life reminder planning (8 horizons) with dedupe-aware apply       |
| `prompt_la_note_reader.sh`                | (utility)                            | Reads HTML body from AutoLife Notes                                          |
| `prompt_la_note_save.sh`                  | (utility)                            | Appends/replaces AutoLife Notes safely                                       |
| `prompt_money_revenue.sh`                 | `money_revenue_prompt.md`            | Generates monetization and revenue strategy from market/funding/context data |
| `prompt_funding_vc.sh`                    | `funding_vc_prompt.md`               | Finds funding, VC, grant, and partnership opportunities                      |

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

- `orchestral/run_la_pipeline.sh`
- `orchestral/setup_la_pipeline_cron.sh`
- `orchestral/prompt_tools/life_reverse_reminder_apply.py`
- `orchestral/run_lightmind_pipeline.sh`
- `orchestral/setup_lightmind_pipeline_cron.sh`

## Standard paradigm

Use `codex-json-runner.py` (directly or via `run_auto_ops.sh`) as common practice:

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
python3 scripts/prompt_tools/codex-json-runner.py \
  --input-json /tmp/task.json \
  --output-dir /tmp/codex-runs \
  --schema scripts/prompt_tools/email_send_schema.json \
  --model gpt-5.3-codex-spark \
  --reasoning high
```

- `AUTOLIFE_PHILOSOPHY.md` – AutoLife capture/automation philosophy and folder layout.
