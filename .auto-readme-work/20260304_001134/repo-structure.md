## Project Summary

LAB (`LazyingArtBot`) is a TypeScript-first monorepo/fork built on OpenClaw, centered on a local AI gateway + multi-channel assistant runtime, with added personal orchestration under `orchestral/` and a large skills surface (`skills/`, `.agents/skills/`).

The repository blends:

- Core OpenClaw runtime (`src/`, `extensions/`, `ui/`, `apps/`, `docs/`)
- LAB-specific automation/orchestration (`orchestral/`, `references/`)
- Nested ecosystem repos via git submodules (`AgInTi`, `vendor/*`)

## Repository Map

```text
/Users/lachlan/Local/Clawbot
├─ README.md / README_OPENCLAW.md / AGENTS.md
├─ package.json / pnpm-workspace.yaml / pnpm-lock.yaml
├─ src/                    # core CLI, gateway, channels, routing, agents, skills runtime
├─ extensions/             # workspace plugin packages (channels/auth/providers/tools)
├─ skills/                 # local skill catalog (55 skill folders with SKILL.md)
├─ .agents/skills/         # maintainer workflow skills (review/prepare/merge + mintlify)
├─ orchestral/
│  ├─ pipelines/           # LazyingArt + Lightmind run/async/cron scripts
│  ├─ pipelines.yml        # pipeline manifest + prompt-tool wiring
│  ├─ prompt_tools/        # grouped Codex prompt tooling + runtime runners
│  ├─ actors/              # automail2note actor packages
│  ├─ scripts/             # calendar/reminder migration helpers
│  ├─ config/              # orchestration defaults/paths
│  └─ references/
├─ scripts/                # build/test/release/dev/docs helpers
├─ docs/                   # Mintlify docs (+ zh-CN generated tree)
├─ ui/                     # Vite/Lit control UI package
├─ apps/                   # macOS, iOS, Android, shared kits
├─ packages/               # compatibility CLIs (moltbot, clawdbot)
├─ vendor/
│  ├─ openai-cookbook/     # git submodule
│  ├─ SillyTavern-WebSearch-Selenium/  # git submodule
│  └─ a2ui/                # vendored directory (not a declared submodule)
├─ AgInTi/                 # git submodule (with nested submodules)
├─ Swabble/                # embedded Swift wake-word project
└─ website/                # static site deployed by .github/workflows/static.yml
```

### Git Submodules (Detected, with parent-child topology)

- Root repo (`.gitmodules`)
  - `AgInTi` -> `git@github.com:lachlanchen/AgInTi.git` (`git submodule status`: initialized, `heads/main`)
    - `AgInTi/AutoAppDev` -> `git@github.com:lachlanchen/AutoAppDev.git` (initialized)
    - `AgInTi/AutoNovelWriter` -> `git@github.com:lachlanchen/AutoNovelWriter.git` (status prefix `-`: not initialized)
    - `AgInTi/OrganoidAgent` -> `git@github.com:lachlanchen/OrganoidAgent.git` (status prefix `-`: not initialized)
    - `AgInTi/PaperAgent` -> `git@github.com:lachlanchen/PaperAgent.git` (status prefix `-`: not initialized)
    - `AgInTi/LifeReverseEngineering` -> `git@github.com:lachlanchen/LifeReverseEngineering.git` (status prefix `+`: checked out at a different commit than recorded in parent)
      - `AgInTi/LifeReverseEngineering/learn` -> `https://github.com/lachlanchen/LazyLearn.git` (initialized)
      - `AgInTi/LifeReverseEngineering/earn` -> `https://github.com/lachlanchen/LazyEarn.git` (initialized)
      - `AgInTi/LifeReverseEngineering/IDEAS` -> `git@github.com:lachlanchen/IDEAS.git` (initialized)
  - `vendor/openai-cookbook` -> `https://github.com/openai/openai-cookbook.git` (initialized)
  - `vendor/SillyTavern-WebSearch-Selenium` -> `https://github.com/SillyTavern/SillyTavern-WebSearch-Selenium.git` (initialized)

## Key Components

- `src/` (core runtime):
  - Entry flow is `openclaw.mjs` -> `dist/entry.js`/`dist/entry.mjs`.
  - Source entry (`src/entry.ts`, `src/cli/run-main.ts`) normalizes env/runtime, lazy-registers CLI subcommands, then dispatches to command modules.
  - Major domains include `src/gateway`, `src/cli`, `src/commands`, `src/channels`, `src/routing`, `src/agents`, and `src/agents/skills`.

- `.agents/skills/` (workflow-critical maintainer automation):
  - Contains `PR_WORKFLOW.md` and skill bundles for `review-pr`, `prepare-pr`, `merge-pr`, plus `mintlify`.
  - `PR_WORKFLOW.md` enforces script-first PR lifecycle (`review-pr` -> `prepare-pr` -> `merge-pr`) with wrapper scripts under `scripts/pr*`.

- `skills/` (workflow-critical local skill catalog):
  - 55 skill directories, each with `SKILL.md` (plus optional `scripts/` and `references/`).
  - Operates as the local skill content base consumed by the agent/CLI skill systems.

- `orchestral/` (workflow-critical LAB orchestration layer):
  - `pipelines.yml` declares at least two named pipelines (`la-daily`, `lightmind-daily`) with sync/async launch scripts and cron setup scripts.
  - `pipelines/` contains large shell entrypoints for daily automation.
  - `scripts/` includes migration/search/move helpers for reminders/calendars and resource analysis.

- `orchestral/prompt_tools/` (workflow-critical prompt-tool topology):
  - Grouped domains: `runtime`, `company`, `websearch`, `email`, `notes`, `calendar`, `reminders`, `migration`, `git`, `docs`.
  - Runtime center is `runtime/codex-json-runner.py`, with `run_auto_ops.sh` and schema contracts (`auto_ops_schema.json`, etc.).
  - `README.md` explicitly states top-level compatibility wrappers were removed; grouped canonical paths are required.

- `extensions/`:
  - Channel/auth/provider plugin workspace packages (Discord/Telegram/Slack/Matrix/Zalo/etc. and auth helpers).

- `docs/`:
  - Mintlify site configured by `docs/docs.json`.
  - Includes channel/gateway/install/reference surfaces and generated `docs/zh-CN/**` docs.

## Setup Signals

- Runtime/tooling baselines:
  - `package.json` -> Node `>=22.12.0`, `packageManager: pnpm@10.23.0`.
  - Workspace packages from `pnpm-workspace.yaml`: root, `ui`, `packages/*`, `extensions/*`.

- Build/test/dev signals (`package.json` + docs):
  - Install: `pnpm install`
  - Build: `pnpm build` (includes `canvas:a2ui:bundle`, `tsdown`, metadata writers)
  - UI build/dev: `pnpm ui:build`, `pnpm ui:dev`
  - Quality gates: `pnpm check`, `pnpm test`, `pnpm test:e2e`, `pnpm test:live`, Docker test scripts

- Environment/deployment signals:
  - `.env.example` documents gateway auth token, provider keys, channel credentials, and env precedence.
  - `docker-compose.yml` defines `openclaw-gateway` + `openclaw-cli` with default ports `18789`/`18790`.

- Docs/dev infra signals:
  - Mintlify docs config exists (`docs/docs.json`), with `pnpm docs:dev` script.
  - `docs/testing.md` provides suite boundaries and live-test environment conventions.

## Usage Signals

- Primary CLI flow (README + command registration):
  - Onboarding: `openclaw onboard --install-daemon`
  - Gateway run: `openclaw gateway run --bind loopback --port 18789 --verbose`
  - Messaging/agent actions: `openclaw message send ...`, `openclaw agent --message ...`
  - Diagnostics: `openclaw channels status --probe`, `openclaw status --all|--deep`, `openclaw doctor`

- LAB orchestration flow:
  - Daily pipelines via `orchestral/pipelines/run_lazyingart_pipeline.sh` and `run_lightmind_pipeline.sh` (+ async + cron setup scripts).
  - Prompt-tool execution standardized around `orchestral/prompt_tools/runtime/codex-json-runner.py` and schema-validated JSON artifacts.
  - Web-search automation integrates `scripts/web_search_selenium_cli/*` and prompt wrappers in `orchestral/prompt_tools/websearch/`.

- Compatibility/binary flow:
  - `packages/clawdbot` and `packages/moltbot` are compatibility shims forwarding to `openclaw`.

## Gaps/Unknowns

- CI/CD state is non-standard in this snapshot:
  - Most workflows are under `.github/workflows.disabled/`; active workflow observed is `static.yml` for `website/` GitHub Pages deploy.

- Submodule completeness is mixed:
  - Some nested `AgInTi` submodules are uninitialized (`AutoNovelWriter`, `OrganoidAgent`, `PaperAgent`), so full nested topology/content cannot be confirmed from this checkout.
  - `AgInTi/LifeReverseEngineering` is checked out at a non-recorded commit relative to its parent (`+` status), indicating local divergence.

- Repository scope is broad/multi-product:
  - Root includes OpenClaw core plus LAB-specific orchestration, plus extra project trees (`Swabble`, `AgInTi`); README generation should decide clearly what is “core LAB” vs “embedded ecosystem”.

- Prompt-tool duplication risk across trees:
  - Root `orchestral/prompt_tools/` is canonical per AGENTS guidance, while `AgInTi/lab_prompt_tools/` also exists in submodule space; ownership boundaries should be clarified in the README.
