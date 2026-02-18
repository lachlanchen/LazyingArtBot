# Prompt Tools

This directory is the dedicated home for LAB Codex prompt-driven tooling.

## Included tools

- `codex-noninteractive.sh`
  - Minimal non-interactive Codex wrapper with explicit model/reasoning.
- `codex-email-cli.py`
  - Codex-assisted email draft/send flow (Apple Mail).
- `codex-json-runner.py`
  - Standard JSON-in / JSON-out Codex runner for reusable automation pipelines.

Supporting prompt assets:

- `common_tools.md`
- `email_send_prompt.md`
- `email_send_schema.json`
- `json_task_prompt.md`

## Standard paradigm

Use `codex-json-runner.py` as common practice:

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
