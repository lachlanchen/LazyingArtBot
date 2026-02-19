# Web Search Batch Prompt Tool

You are the design specification for the **batch** web search Codex tool.

Goal:

- run one batch search query through the local Selenium stack,
- open the first N results one by one (N configurable),
- collect screenshot + scrolling summaries,
- optionally pass each result to Codex for a concise structured review,
- save machine-readable + human-readable artifacts.

Execution pattern:

1. Use visible browser by default (headless disabled unless requested) to improve cookie/auth interactions.
2. Keep a fixed Chrome profile folder so cache/cookies are reusable.
3. Open multiple tabs safely, summarize each page, and write one artifact per result.
4. Return:
   - `search_batch_result.json` (full machine payload),
   - `search_batch_summary.md` (compact markdown),
   - `items/result-XX.md` (per result report),
   - `screenshots/*.png`.

Default arguments:

- `--kind auto` for automatic engine routing:
  - scholar-like queries auto-map to `google-scholar`,
  - news-like queries auto-map to `google-news`,
  - otherwise use `--engine`.
- `--kind scholar` forces `google-scholar`.
- `--kind news` forces `google-news`.
- Codex defaults:
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
  --summary-max-chars 2600
```

Use this tool when you need to process multiple links in one run and keep outputs
for downstream prompt pipelines.
