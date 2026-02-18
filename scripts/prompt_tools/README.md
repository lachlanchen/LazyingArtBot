# Prompt Tools

This directory is the dedicated home for LAB Codex prompt-driven tooling.

## Core runners

- `codex-noninteractive.sh` – Minimal non-interactive Codex wrapper with explicit model/reasoning.
- `codex-email-cli.py` – Codex-assisted email draft/send flow (Apple Mail).
- `codex-json-runner.py` – Standard JSON-in / JSON-out Codex runner for reusable automation pipelines.
- `run_auto_ops.sh` – Helper wrapper that feeds payloads + prompt templates into `codex-json-runner.py` with the AutoLife operations schema.

## AutoLife prompt suite (delegation-first)

| Script                            | Prompt template                                | Purpose                                                                           |
| --------------------------------- | ---------------------------------------------- | --------------------------------------------------------------------------------- |
| `prompt_notes.sh`                 | `notes_prompt.md`                              | Turn raw context into HTML-ready AutoLife note updates.                           |
| `prompt_calendar_and_reminder.sh` | `calendar_prompt.md`                           | Decide whether tasks become calendar blocks or reminders.                         |
| `prompt_market_research.sh`       | `market_research_prompt.md`                    | Generate market intel summaries + suggested actions.                              |
| `prompt_company_management.sh`    | `company_management_prompt.md`                 | Refine Lazying.art / Lightmind.art operating plans.                               |
| `prompt_passive_income.sh`        | `passive_income_prompt.md`                     | Produce concrete passive-income opportunity stacks.                               |
| `prompt_making_plan.sh`           | `making_plan_prompt.md`                        | Build daily/weekly plans with sequenced steps.                                    |
| `prompt_log.sh`                   | `log_prompt.md` (with `log_entry_schema.json`) | Format and append HTML entries to AutoLife › Log (Apple Notes + markdown mirror). |
| `prompt_commit_push.sh`           | `commit_summary_prompt.md`                     | Ask Codex to summarize repo changes, then commit & push automatically.            |

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
  --model gpt-5.1-codex-mini \
  --reasoning medium
```
