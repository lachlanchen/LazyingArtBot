# Prompt Tool: web_search_immersive

Purpose:

- Run Google search through UI interaction (not headless by default) for human-aided workflows.
- Capture screenshots of key UI states.
- Return click targets (coordinates) for each ranked result so a second pass can use `--click-at x,y`.
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

- `query-<slug>.json` (`mode`, `results`, `screenshots`, and optional `clicked` block)
- `query-<slug>.txt` text summary
- `screenshots/*.png` UI captures (search input, results, post-click, etc.)
- `viewport` metadata embedded in JSON (`width`, `height`, `dpr`, `scrollX/Y`, document size) for
  precise coordinate interpretation.

Recommended interaction pattern for Codex-assisted extraction:

1. Run first pass with a page window, e.g.
   `prompt_web_search_immersive.sh --engine google --query "wearable glass paper" --results 6 --start-page 1 --end-page 2 --summarize-open-url`
2. Review returned screenshot paths, pick the best result with `(x,y)` from the screenshot.
3. Re-run with `--click-at "x,y"` (or `--open-result --result-index N`) on the same query.
4. Optionally increase page-depth or scroll depth for a long page:
   `prompt_web_search_immersive.sh --query "..."`
   `--scroll-steps 6 --scroll-pause 1.0 --summarize-open-url`.

Default behavior notes:

- Browser is visible (`--headless` is off by default).
- Cookie-dismiss attempts are enabled by default.
- This wrapper is designed for Google UI mode with rich screenshot feedback.
