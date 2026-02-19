# Web Search Batch Prompt Tool

You are the design specification for the **batch** web search Codex tool.

Tool to use:

- `orchestral/prompt_tools/prompt_web_search_batch.sh`

Goal:

- run one batch search query through the local Selenium stack
- open the first N results one by one (N configurable)
- collect screenshot + scrolling summaries
- optionally pass each opened result to Codex for concise structured review
- save machine-readable + human-readable artifacts for downstream prompts

Output root:

- default: `~/.openclaw/workspace/AutoLife/MetaNotes/web_search_runs`
- per run: `<output-dir>/<run-id>/`
- per pipeline query: `<output-dir>/<context>/<run-id>-<context>-<idx>-<slug>/`
- Lightmind pipeline writes:<br/>`~/.openclaw/workspace/AutoLife/MetaNotes/web_search_runs/lightmind/<run-id>-lightmind-.../`<br/>then saves rollup files to `.../pipeline_runs/<run_id>/web_search.summary.txt` and `.../web_search_digest.html`
- LA pipeline writes similarly under `/.../web_search/lazyingart/`

Artifacts:

- `search_batch_result.json` (full machine payload):
  - `items` list
  - `search_page_overviews` (page scan summary entries)
  - `search_page_screenshots` (search results page screenshot files)
  - `opened_items` (top opened result details)
- `search_batch_summary.md` (compact markdown)
- `items/result-XX.md` (per result report)
- `screenshots/*.png` (result + page screenshots)

Default arguments:

- `--kind auto` for automatic engine routing
  - scholar-like queries auto-map to `google-scholar`
  - news-like queries auto-map to `google-news`
- `--kind scholar` forces `google-scholar`
- `--kind news` forces `google-news`
- Codex defaults
  - model `gpt-5.3-codex-spark`
  - reasoning `high`
  - safety `danger-full-access`
  - approval `never`

Use command:

```
orchestral/prompt_tools/prompt_web_search_batch.sh \
  --query "wearable glass paper" \
  --kind scholar \
  --top-results 4 \
  --scroll-steps 3 \
  --summary-max-chars 2600 \
  --output-dir ~/.openclaw/workspace/AutoLife/MetaNotes/web_search_runs
```

Use this tool when you need to process multiple links in one run and keep outputs
for downstream prompt pipelines (notes and email digests).
