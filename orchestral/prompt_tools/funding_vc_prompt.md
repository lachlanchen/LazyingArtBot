# Prompt: Funding & VC Opportunity Research Tool

Find funding, VC, and grant signals that are directly supported by provided context.

Inputs:

- `company_focus`: run scope label.
- `market_summary`: latest market + competitor signals.
- `resource_summary`: resource-analysis summary.
- `web_search_summary`: web search summary artifacts and traces.
- `legal_summary`: legal/compliance summary from prior stage (if available).
- `run_context`: merged run context.
- `reference_sources`: source hints passed from the pipeline.
- `language_policy`: output style policy.

How to decide:

- Use `reference_sources` and local summaries first.
- Only use web-search links that exist in provided artifacts (opened items, result summaries, and screenshots when present).
- Treat upstream web evidence as traceable signals, not a full crawl.
- For funding conclusions, prioritize web/news and investment-program signals over scholarly links.
- Cover regional signals explicitly: Hong Kong, Mainland China, and US.
- Remove duplicates by URL.
- If evidence is weak, mark confidence and report gaps explicitly.
- Prefer practical opportunities with a clear next action in 7d/30d/quarter.

Output (`la_ops_schema.json`):

1. `summary`: short run summary.
2. `notes`: exactly one note entry:
   - `folder`: caller-specific company folder
   - For Lazying.art: `🏢 Companies/🐼 Lazying.art`
   - For Lightmind: `🏢 Companies/👓 Lightmind.art`
   - `target_note`
     - Lazying.art: `🏦 Funding & VC Opportunities / 融资与VC机会 / 融資與VC機會`
     - Lightmind: `🏦 Funding & VC Opportunities / 融资与投资机会 / 融資與投資機會`
   - `html_body`: append-ready light HTML with sections:
     - timestamp header
     - high-confidence opportunities
     - urgency block (7 days / 30 days / next quarter)
     - next 3 actions
     - risk / false-positive guard
     - compact table `Top opportunities` with columns:
       - `query`
       - `title`
       - `source`
       - `url`
       - `confidence`
       - `deadline_or_open_window`
       - `proof`
     - `proof` should be a short, human-readable evidence note (source context or risk signal), not a file path.
     - Include only links present in attached web-search artifacts or run summaries.
     - Add a short `Regional funding signal board` subsection (HK / CN / US) with `signal`, `confidence`, `next check`.
     - If any region lacks direct evidence, add one concrete follow-up query for that region in `next check`.
   - `tags`: include `funding`, `vc`, `grants`, `pipeline`.

Tone:

- Evidence-first and concise.
- Avoid speculation when evidence is weak.
- Keep headings in light `EN / 中文 / 日本語` style.

Return JSON only, no markdown fences.
