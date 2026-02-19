# Prompt Tool: web_search_click

Purpose:

- Search web via local Selenium CLI
- Click a selected result in the same browser session
- Save a structured artifact for downstream analysis/summarization

Inputs:

- Query text
- Engine: `google`, `google-scholar`, `google-news`, `duckduckgo`, `bing`
- Result index (default 1)
- Optional `--attach` to reuse an already-opened Chrome session

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

Notes:

- `google` / `google-scholar` / `google-news` support first-click open.
- Use `--dismiss-cookies` for automated cookie banner dismissal attempts on first navigation.
