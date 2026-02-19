# Prompt Tool: web_search

This document defines how to run the local Selenium-powered web search prompt tool and where artifacts are written.

## Files

- `orchestral/prompt_tools/prompt_web_search.sh`
- `orchestral/prompt_tools/prompt_web_search_click.sh`
- `orchestral/prompt_tools/prompt_web_search_immersive.sh`
- `orchestral/prompt_tools/prompt_web_search_google.sh`
- `orchestral/prompt_tools/prompt_web_search_google_scholar.sh`
- `orchestral/prompt_tools/prompt_web_search_google_news.sh`
- `orchestral/prompt_tools/prompt_web_search_click_prompt.md`
- `orchestral/prompt_tools/prompt_web_search_immersive_prompt.md`
- `orchestral/prompt_tools/prompt_web_search_prompt.md`
- `scripts/web_search_selenium_cli/run_search.sh`
- `scripts/web_search_selenium_cli/search_cli.py`

## Default behavior

- Engine: `google`
- Queries:
  - `site:nature.com research paper`
  - `site:science.org research paper`
- Conda env: `clawbot`
- Output folder: `~/.openclaw/workspace/AutoLife/MetaNotes/web_search_runs/<RUN_ID>/`
- Browser profile: `~/.local/share/web-search-selenium/browser-profile`
- Browser cache: `~/.local/share/web-search-selenium/browser-profile/cache`
- Remote debug port: `9222` (adjustable by `--debug-port`)
- Login mode: use `--open-url https://accounts.google.com/` to open Google login in a visible browser with persistent profile.
- Reuse an existing logged-in Chrome instance:
  - Start once with `--open-url https://accounts.google.com/ --keep-open`
  - Then run with `--attach` (same `--debug-port`) to reuse the same tab/session instead of opening a new browser.
- Cookie banners: cookie dismissal is enabled by default in click/search wrappers for both search and open-url bootstrap flows.
- Click mode: search + click selected result + summarize opened page in the **same window**:
  - `prompt_web_search_click.sh --query "your query" --engine google-scholar --result-index 1`
  - `prompt_web_search_google_scholar.sh --query "wearable glass paper"`
  - `prompt_web_search_google_news.sh --query "HK startup funding"`
  - `prompt_web_search_google.sh --query "latest multimodal paper"`
- Immersive mode: open Google search, capture screenshots, scroll each result page, and optionally click by index or coordinates:
  - `prompt_web_search_immersive.sh --query "site:nature.com robotics" --engine google --click-index 1`
  - `prompt_web_search_immersive.sh --query "site:science.org AI" --start-page 1 --end-page 4 --scroll-steps 5 --scroll-pause 0.8`

## Artifacts per run

Assume `RUN_ID=20260219-010101`.

- `web_search_results.txt`
- `query-site-nature-com-research-paper.json`
- `query-site-nature-com-research-paper.txt`
- `query-site-science-org-research-paper.json`
- `query-site-science-org-research-paper.txt`
- `query-<safe-query>-clicked.json` when using click-mode wrappers
- `query-<safe-query>-clicked.txt` when using click-mode wrappers
- `query-<safe-query>-immersion-summary.json` for immersive runs
- `query-<safe-query>-immersion-summary.txt`
- optional `screenshot-*.png` captures for each searched/clicked page
- Optional per-query `.err` files on failures.

## Quick commands

```bash
orchestral/prompt_tools/prompt_web_search.sh
orchestral/prompt_tools/prompt_web_search.sh --headless --results 8 --run-id test-1
orchestral/prompt_tools/prompt_web_search.sh --query "site:science.org CRISPR" --query "site:nature.com GPT-4" --output-dir /tmp/web-search
orchestral/prompt_tools/prompt_web_search.sh --open-url https://www.google.com --attach --debug-port 9222
orchestral/prompt_tools/prompt_web_search.sh --open-url https://accounts.google.com/ --keep-open --hold-seconds 30 --output-dir ~/.openclaw/workspace/AutoLife/MetaNotes/web_search_runs
orchestral/prompt_tools/prompt_web_search_google_scholar.sh --query "wearable glass" --results 5 --result-index 1 --keep-open --summary-max-chars 2500
orchestral/prompt_tools/prompt_web_search_immersive.sh --query "site:nature.com quantum sensing" --engine google --keep-open --scroll-steps 6 --scroll-pause 1 --output-dir ~/.openclaw/workspace/AutoLife/MetaNotes/web_search_runs
orchestral/prompt_tools/prompt_web_search_immersive.sh --query "site:arxiv.org multimodal" --open-url https://www.google.com --attach --debug-port 9222 --click-x 420 --click-y 560
```

## Notes

- Use `--run-id` if you want deterministic folder naming.
- Use `--headless` for CI-like unattended runs.
- For interactive bootstrap/login, use `--keep-open` (default closes fast) and optionally `--hold-seconds` to keep Chrome visible.
- `--start-page`/`--end-page` control how many search result pages are scanned before stopping.
- `--scroll-steps` + `--scroll-pause` tune multi-turn page reading in immersive mode before summarization.
- Outputs are plaintext by design to keep downstream parsers simple.
