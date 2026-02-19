# Web Search (Google + cache-backed Selenium) Prompt Tool

Use this as a general web-search fallback contract when one query needs a
non-immersive call path.

Use the local Selenium search wrapper through
`orchestral/prompt_tools/prompt_web_search_immersive.sh` for all web-search tasks
unless a fixed workflow requires another wrapper.

- For compatibility fallback only: `orchestral/prompt_tools/prompt_web_search_click.sh`
- Legacy fixed-engine wrappers:
  - `orchestral/prompt_tools/prompt_web_search_google.sh`
  - `orchestral/prompt_tools/prompt_web_search_google_scholar.sh`
  - `orchestral/prompt_tools/prompt_web_search_google_news.sh`

Task:

1. Use the local Selenium stack for the configured web engine.
2. Keep outputs as human-readable and machine-readable evidence.
3. Save all artifacts under one run folder.
4. Keep search-page scan evidence and opened-result details for downstream prompts.

Scope:

- Query intent decides engine:
  - default: `google`
  - academic: `google-scholar`
  - news: `google-news`
- Capture short snippets and URLs first, then open selected deep links.
- Output is evidence-driven, not authoritative indexing.

When run from a pipeline stage:

- For market signals: default `google`.
- For research review: prefer `google-scholar`.
- For press/news scans: prefer `google-news`.

Output location:

- default root: `~/.openclaw/workspace/AutoLife/MetaNotes/web_search_runs`
- per run: `<output-dir>/<run-id>/web_search_results.txt`
- per query:
  - `<output-dir>/<run-id>/query-<safe-name>.json`
  - `<output-dir>/<run-id>/query-<safe-name>.txt`
- screenshots are in `<output-dir>/<run-id>/screenshots/*.png`
- downstream prompts should read:
  - `search_page_screenshots` (result page captures)
  - `opened_items` (opened links returned by the tool run)
  - `query-*.txt` for compact text and run metadata.

Output contract expectations:

- `query-*.json` may include:
  - `search_page_overviews`
  - `search_page_screenshots`
  - `clicked`
  - `opened_items`
  - `opened_count`
  - optional `query_file_root`
  - optional `query_file_pattern`, `query_file_pattern_txt`, `query_file_pattern_screenshots`
- `query-*.txt` for compact snippets and timestamps.
- `web_search_results.txt` for the combined text summary.

Operational defaults:

- Browser engine: `google`
- Profile: `~/.local/share/web-search-selenium/browser-profile`
- Cache folder: `~/.local/share/web-search-selenium/browser-profile/cache`
- Remote debug port: `9222`
- Reuse session with `--attach` + `--debug-port` where appropriate.
- Keep browser visible by default.

Execution pattern from pipelines:

1. `orchestral/prompt_tools/prompt_web_search_immersive.sh --engine <google|google-scholar|google-news> --query "<query>" --results <n> --open-top-results <n> --summarize-open-url --scroll-steps 3 --scroll-pause 0.9`
2. Read `query-*.json`/`query-*.txt` and pick links.
3. Re-run via `--open-result --result-index N` only for priority links.
4. In final notes/email include links and short evidence-backed snippets.

Prompting guidance:

- Keep evidence metadata for downstream steps:
  - `query_file_root` when multiple folders are produced.
  - `query_file_pattern` / `query_file_pattern_txt` / `query_file_pattern_screenshots`.
  - `top_results_per_query` and `opened_count`.
- Do not hardcode fixed top-3 behavior in later stages.
- If a link is a PDF, prefer short local parse/summarization in the existing browser flow; keep screenshot evidence regardless.
