# Prompt Tool: web_search_click

Tool to use:

- `orchestral/prompt_tools/prompt_web_search_click.sh`
- Prefer `orchestral/prompt_tools/prompt_web_search_immersive.sh` when multi-result scraping and results-page screenshots are needed.
- Use `orchestral/prompt_tools/prompt_web_search_click.sh` when only one explicit click is required.

Output root:

- default: `~/.openclaw/workspace/AutoLife/MetaNotes/web_search_runs`
- run folder: `<output-dir>/<run-id>/`

Result files:

Purpose:

- Search web via local Selenium CLI
- Click a selected result in the same browser session
- Save a structured artifact for downstream analysis/summarization
- If available, prefer the immersive flow so result-page screenshots + top results detail are available for Codex extraction.

Inputs:

- Query text
- Engine: `google`, `google-scholar`, `google-news`, `duckduckgo`, `bing`
- Result index (default 1)
- Optional `--attach` to reuse an already-opened Chrome session

Artifacts and fields:

- `web_search_results.txt` (run summary)
- `query-<slug>-clicked.json` (raw JSON payload from `search_cli`)
- `query-<slug>-clicked.txt` (human-readable summary)
- `screenshots/*.png`
- `query-<slug>-clicked.json` includes:
  - `clicked` summary with `result_index`, `title`, `url`
  - `opened_items` if any results were opened
  - `search_page_overviews` scan summaries
  - `search_page_screenshots` for search page screenshots
  - `search_page_overviews` and `search_page_screenshots` for evidence when validating result links

Operational expectations:

- Keep a fixed Chrome profile/cache:
  - Profile: `~/.local/share/web-search-selenium/browser-profile`
  - Cache: `${profile}/cache`
- Prefer visible browser for cookie/consent interaction (not headless) when `--headless` is not set.
- Use one Chrome window per run session unless `--attach` reuses an existing session.
- Cookie/consent popups are auto-dismissed by default (set `--no-dismiss-cookies` / `WEB_SEARCH_DISMISS_COOKIES=0` if needed).
- Save outputs under:
  - `~/.openclaw/workspace/AutoLife/MetaNotes/web_search_runs/<run-id>/`

Artifacts:

- `query-<slug>-clicked.json` (full JSON payload from `search_cli`)
- `query-<slug>-clicked.txt` (human-readable summary)
- `web_search_results.txt` (run summary)

Use this flow when you need explicit result opening in one click:

1. Run `orchestral/prompt_tools/prompt_web_search_click.sh` with `--result-index` and `--open-result`.
2. If a click needs cookies/session reuse, use `--attach`.
3. Use outputs above in downstream notes/email context.
4. If this one-click flow misses multi-result evidence, switch to a richer run:
   `orchestral/prompt_tools/prompt_web_search_immersive.sh --open-top-results <top_n> --summarize-open-url --scroll-steps 3 --scroll-pause 1.0`

Notes:

- `google` / `google-scholar` / `google-news` support first-click open.
- Use `--dismiss-cookies` for automated cookie banner dismissal attempts on first navigation.
