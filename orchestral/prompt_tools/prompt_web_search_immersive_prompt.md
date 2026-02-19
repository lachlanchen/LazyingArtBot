# Prompt Tool: web_search_immersive

Purpose:

- Run Google search through UI interaction (not headless by default) for human-aided workflows.
- Capture screenshots of key UI states.
- Return click targets (coordinates) for each ranked result so a second pass can use `--click-at x,y`.
- Save and return both result-page and opened-page screenshots.
- Optionally click a coordinate and summarize the opened page in the same browser session.
- Support multi-page crawling by setting `--start-page` and `--end-page`.
- Optional `--scroll-steps` + `--scroll-pause` is used when summarizing opened pages so long pages can be scanned in segments.

Inputs:

- `--query` required
- `--output-dir` optional (default `~/.openclaw/workspace/AutoLife/MetaNotes/web_search_runs`)
- `--run-id` optional for deterministic artifact folders
- optional `--click-at "<x,y>"` for coordinate clicks from screenshot inspection
- optional `--open-result` + `--result-index` to click the N-th search result programmatically
- optional `--start-page <n> --end-page <n>` for repeated search pages
- optional `--scroll-steps <n>` and `--scroll-pause <sec>` for opened-page extraction
- optional `--summarize-open-url`
- optional `--keep-open` / `--attach` for session reuse

Output folder (run-id scoped):

- `query-<slug>.json` (`mode`, `results`, `screenshots`, `search_page_overviews`, `search_page_screenshots`, `opened_items`, `opened_count`, and optional `clicked` block)
- `query-<slug>.txt` text summary
- `screenshots/*.png` UI captures (search input, results, post-click, etc.)
- `viewport` metadata embedded in JSON (`width`, `height`, `dpr`, `scrollX/Y`, document size) for
  precise coordinate interpretation.

Recommended interaction pattern for Codex-assisted extraction:

1. Run first pass with a results-page capture, e.g.
   - `prompt_web_search_immersive.sh --engine google --query "wearable AI news" --results <top_n> --open-top-results <top_n> --summarize-open-url --scroll-steps 3 --scroll-pause 0.9`
2. Read returned JSON/TXT and pick top results from the search-result page and opened details.
3. Re-run only if needed with:
   - `--open-result --result-index N` for deep capture, where N follows the opened result set from `opened_items`, and
   - `--click-at "x,y"` using screenshot coordinates in the same run.
4. For any rerun, keep:
   - `--scroll-steps` (typically 3-6) and `--scroll-pause` (~0.8-1.2) for long pages.
5. Final output should always include:
   - result folder path
   - results-page screenshot path(s) (`search_page_screenshots`)
   - `opened_items` (opened links from the current query window)
   - for each opened item: title, url, summary, optional `opened_screenshots`, and click location if available
   - `--summarize-open-url` snippets for each opened result

Default behavior notes:

- Browser is visible (`--headless` is off by default).
- Cookie-dismiss attempts are enabled by default.
- This wrapper is designed for Google UI mode with rich screenshot feedback.

Where to write outputs:

- default root: `~/.openclaw/workspace/AutoLife/MetaNotes/web_search_runs`
- outputs are under `<output-dir>/<run-id>/`
- expected final artifacts:
  - `query-<slug>.json`
  - `query-<slug>.txt`
  - `screenshots/*.png`

Downstream note/email rule:

- Include opened result titles + URLs + summaries for the query-configured result depth, and provide screenshot references for evidence.
