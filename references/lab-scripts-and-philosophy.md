# LazyingArtBot Scripts and Philosophy

This reference documents the LAB-specific script layer added on top of OpenClaw.

## Philosophy

LAB automation follows these rules:

1. Local-first behavior

- Keep your own branding, workflow, and operating style as the source of truth.
- Pull upstream improvements selectively, not by overwriting local intent.

2. Structured over implicit

- Use schema-constrained outputs when Codex is in the loop.
- Prefer deterministic JSON handoff between steps.

3. Safe side effects

- Default to draft/dry-run where possible.
- Require explicit action flags for real side effects (send, delete, move, write).

4. Human override always

- You can override recipients/subject/model/reasoning/paths at runtime.
- Automation should assist, not lock decisions.

5. Observable pipeline

- Keep logs and intermediate artifacts for debugging and rollback.
- Make failures explicit and actionable.

## Script inventory (LAB custom)

All Codex prompt-driven scripts now live in:

- `scripts/prompt_tools/`

### 1) Codex non-interactive wrapper

- Path: `scripts/prompt_tools/codex-noninteractive.sh`
- Purpose: stable shell wrapper around `codex exec` with explicit model/reasoning.
- Key options:
  - `--model <name>`
  - `--reasoning <level>`
  - `--output-schema <path>`
  - `--output-last-message <path>`
  - `--json`
  - `--skip-git-check`

Example:

```bash
./scripts/prompt_tools/codex-noninteractive.sh \
  --model gpt-5.1-codex-mini \
  --reasoning medium \
  --prompt "Reply with exactly: OK"
```

### 2) Codex email CLI (Apple Mail sender)

- Path: `scripts/prompt_tools/codex-email-cli.py`
- Purpose: use Codex to draft structured email, then optionally send via macOS Mail.
- Behavior:
  - Uses strict JSON output schema.
  - Prints normalized draft action.
  - Sends only when `--send` is provided.

Key options:

- `--instruction <text>` (or stdin)
- `--to/--cc/--bcc`
- `--model`, `--reasoning`, `--codex-bin`
- `--output-json <path>`
- `--send` (actual Mail send)

Dry-run:

```bash
./scripts/prompt_tools/codex-email-cli.py \
  --to lachchen@qq.com \
  --instruction "Write a short friendly hello email." \
  --model gpt-5.1-codex-mini \
  --reasoning medium
```

Send now:

```bash
./scripts/prompt_tools/codex-email-cli.py \
  --to lachchen@qq.com \
  --instruction "Write a short friendly hello email." \
  --model gpt-5.1-codex-mini \
  --reasoning medium \
  --send
```

### 3) Standardized JSON runner (common Codex practice)

- Path: `scripts/prompt_tools/codex-json-runner.py`
- Purpose: run any JSON-in / JSON-out Codex task with standardized artifacts.
- Required input contract:
  - `--input-json <path>`
  - `--output-dir <path>`
- Optional enforcement:
  - `--schema <path>`

Example:

```bash
python3 scripts/prompt_tools/codex-json-runner.py \
  --input-json /tmp/task.json \
  --output-dir /tmp/codex-runs \
  --schema scripts/prompt_tools/email_send_schema.json \
  --model gpt-5.1-codex-mini \
  --reasoning medium
```

Standardized outputs per run:

- `request.json`
- `input.json`
- `prompt.txt`
- `result.raw.json`
- `result.json`
- `meta.json`
- `codex.stdout.log`
- `codex.stderr.log`

Shared latest pointers:

- `<output-dir>/latest-run.txt`
- `<output-dir>/latest-result.json`

### 4) Prompt tools (reusable prompt components)

- Directory: `scripts/prompt_tools/`
- Files:
  - `common_tools.md` - shared tool semantics and guardrails
  - `email_send_prompt.md` - system/task prompt for email drafting
  - `email_send_schema.json` - strict JSON schema contract

Design goal:

- Keep prompts modular and reusable.
- Make schema the contract between model output and execution code.

### 5) Upstream sync policy

- Path: `references/upstream-sync-local-first.md`
- Purpose: merge/fetch upstream without losing LAB customizations.
- AGENTS policy now requires reading this before upstream sync operations.

## Runtime prerequisites

- Codex CLI installed and authenticated.
- macOS Apple Mail available (for `--send` flows).
- AppleScript automation permissions granted for Mail sends.
- Network access for model calls.

## Recommended operating pattern

1. Draft with dry-run first.
2. Review output JSON/body.
3. Send with explicit `--send`.
4. Keep model + reasoning explicit in commands.
5. Keep prompt tools and schema versioned with code.

## Notes on scope

- This document covers LAB custom script layer in this repo.
- Broader mailbox automation under `~/.openclaw/workspace/automation/` is operational runtime state and can evolve separately.
