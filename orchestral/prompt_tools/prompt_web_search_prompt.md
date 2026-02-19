# Web Search (Google + cache-backed Selenium) Prompt Tool

You are a web-capture helper for research automation.

Tool to use:

- `orchestral/prompt_tools/prompt_web_search_immersive.sh` (recommended)
- For compatibility fallback only: `orchestral/prompt_tools/prompt_web_search_click.sh`
- For legacy fixed-engine wrappers, use:
  - `orchestral/prompt_tools/prompt_web_search_google.sh`
  - `orchestral/prompt_tools/prompt_web_search_google_scholar.sh`
  - `orchestral/prompt_tools/prompt_web_search_google_news.sh`

Task:

1. Use the local Selenium search wrapper through `prompt_web_search_immersive.sh` for all web-search tasks.
2. Keep outputs as human-readable plaintext.
3. Save all results into one output folder for downstream agents.
4. Use a fixed browser profile and cache folder for continuity across sessions.
5. For market/revenue/news workflows, include search-page scan evidence plus opened-result details (using per-query open limits) in the final report.

Scope:

- Search intent determines domains; do not restrict to fixed domains unless the query explicitly requires it.
- Default capture mode should prefer short, high-signal snippets and URLs.
- Output is for reference, not authoritative indexing.

Search intent routing:

- Default engine: `google`
- academic queries: `google-scholar`
- news queries: `google-news`

When run from a pipeline stage:

- For market signals: generally use `google`.
- For research review prompts: use `google-scholar` where appropriate.
- For press/news scans: use `google-news`.

Output location:

- default root: `~/.openclaw/workspace/AutoLife/MetaNotes/web_search_runs`
- per run: `<output-dir>/<run-id>/web_search_results.txt`
- query outputs: `<output-dir>/<run-id>/query-<safe-name>.json` and `query-<safe-name>.txt`
- when run by pipelines (`run_la_pipeline.sh`, `run_lightmind_pipeline.sh`), copied summaries are written to pipeline artifacts and notes.
- always include result-folder + screenshot-folder locations in final notes/email as evidence references.
- For downstream prompts, read JSON/TXT from the output folder and trace:
  - `search_page_screenshots` (path list)
  - `opened_items` (opened links returned by the tool run, typically up to `opened_count`)
  - `query-*.txt` for compact text and run metadata.

Quality constraints:

- Prefer not to fetch arbitrary binaries. For PDF-based results, the tool may fetch the PDF directly with a short timeout so the content can be summarized, then still keep screenshot evidence for traceability.
- Save one query block per output file.
- Include raw query, run id, status code, query timestamp.
- Confirm/close cookie and consent overlays automatically so the prompt can focus on extracted content.
  - If needed, disable by passing `--no-dismiss-cookies` or `WEB_SEARCH_DISMISS_COOKIES=0`.

Artifacts and fields:

- `web_search_results.txt` (combined summary)
- `query-*.json` (raw payload from search_cli)
- `query-*.txt` (parsed text)
- `query-*.json` may include:
  - `search_page_overviews` (search-result page scan snippets)
  - `search_page_screenshots` (search page screenshot paths)
  - `clicked` and `opened_items` when opening URLs in-place
- `screenshots/*.png` must include the results page at minimum.
- Use result files to extract:
  - search page screenshot path(s)
  - opened-result entries from `opened_items` (typically up to `opened_count` / `--open-top-results`)

Operational defaults:

- Browser engine: `google`
- Profile dir: `~/.local/share/web-search-selenium/browser-profile`
- Cache folder: `~/.local/share/web-search-selenium/browser-profile/cache`
- Remote debug port: `9222`
- The wrapper supports reusing one Chrome session:
  - Start once with login: `scripts/web_search_selenium_cli/open_google_session.sh`
  - Reuse by adding `--attach` (`orchestral/prompt_tools/prompt_web_search_immersive.sh --attach`) and `--debug-port` to keep using the same logged-in tab + cache.

Recommended call pattern from pipelines:

1. `orchestral/prompt_tools/prompt_web_search_immersive.sh --engine <google|google-scholar|google-news> --query "<query>" --results <top_n> --open-top-results <top_n> --summarize-open-url --scroll-steps 3 --scroll-pause 0.9`
2. Read result JSON/TXT and identify which result indexes to keep for notes.
3. Re-run with `--open-result --result-index N` for selected results if deeper detail is needed.
4. In final notes/email, include links and one- or two-sentence summaries.

Use this prompt output in downstream notes/email by passing title + URL + snippet/codex summary from query outputs.

Use this prompt tool in tandem with:

- `orchestral/prompt_tools/prompt_web_search_immersive.sh`
- `scripts/web_search_selenium_cli/run_search.sh`
