#!/usr/bin/env python3
"""Run one search, open top N results one-by-one, then summarize each result.

Workflow:
1) Run local Selenium search tool.
2) Open top results in separate tabs and capture summary + screenshots from CLI.
3) For each opened result, optionally call Codex (non-interactive) to rewrite a compact markdown summary.
4) Save one aggregate JSON + per-item markdown for downstream automation.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional


REPO_DIR = Path(__file__).resolve().parents[2]
RUN_SEARCH_TOOL = REPO_DIR / "scripts" / "web_search_selenium_cli" / "run_search.sh"
CODEX_TOOL = REPO_DIR / "orchestral" / "prompt_tools" / "codex-noninteractive.sh"


AUTO_SCHOLAR_MARKERS = [
    "paper",
    "publication",
    "arxiv",
    "nature",
    "science",
    "ieee",
    "cvpr",
    "icml",
    "neurips",
    "neural",
    "scholar",
    "pubmed",
]

AUTO_NEWS_MARKERS = [
    "news",
    "press",
    "announcement",
    "update",
    "release",
    "journal",
    "breaking",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Batch web search + per-result summarization.")
    parser.add_argument("--query", required=True, help="Search query text")
    parser.add_argument(
        "--kind",
        choices=["auto", "general", "scholar", "news"],
        default="auto",
        help="Search kind to use (default: auto)",
    )
    parser.add_argument(
        "--engine",
        choices=["google", "google-scholar", "google-news", "duckduckgo", "bing"],
        default="google",
        help="Engine override for auto/general style",
    )
    parser.add_argument("--top-results", type=int, default=3, help="Open top N results")
    parser.add_argument("--scroll-steps", type=int, default=2, help="Scroll steps while summarizing pages")
    parser.add_argument("--scroll-pause", type=float, default=0.8, help="Pause between scroll steps")
    parser.add_argument("--summary-max-chars", type=int, default=2200, help="Max chars in page summary")
    parser.add_argument("--output-dir", default=str(Path.home() / ".openclaw" / "workspace" / "AutoLife" / "MetaNotes" / "web_search_runs"))
    parser.add_argument("--run-id", default=None, help="Optional run id")
    parser.add_argument("--env", default=os.environ.get("WEB_SEARCH_ENV", "clawbot"), help="Conda env for Selenium wrapper")
    parser.add_argument("--conda-run", default=str(REPO_DIR / "scripts" / "web_search_selenium_cli" / "run_search.sh"), help="search runner binary path")
    parser.add_argument("--headless", action="store_true", help="Run browser headless")
    parser.add_argument("--codex-model", default=os.environ.get("CODEX_MODEL", "gpt-5.3-codex-spark"), help="Codex model")
    parser.add_argument("--codex-reasoning", default=os.environ.get("CODEX_REASONING", "high"), help="Codex reasoning level")
    parser.add_argument("--codex-safety", default=os.environ.get("CODEX_SAFETY", "danger-full-access"), help="Codex safety mode")
    parser.add_argument("--codex-approval", default=os.environ.get("CODEX_APPROVAL", "never"), help="Codex approval mode")
    parser.add_argument("--no-codex", action="store_true", help="Skip Codex post-summary")
    parser.add_argument("--keep-open", action="store_true", help="Keep browser open after run")
    parser.add_argument(
        "--hold-seconds",
        type=float,
        default=0.0,
        help="Keep-open seconds (only when --keep-open)",
    )
    return parser.parse_args()


def resolve_tool_path(raw: str) -> str:
    path = Path(raw).expanduser()
    if not path.is_absolute():
        path = (REPO_DIR / path).resolve()
    return str(path)


def run_cmd(cmd: list[str], *, env: Optional[Dict[str, str]] = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        check=False,
        text=True,
        capture_output=True,
        env=env or None,
    )


def sanitize_query(q: str) -> str:
    q = q.strip().lower()
    q = re.sub(r"\s+", "-", q)
    return re.sub(r"[^a-z0-9-]", "", q)[:80] or "query"


def decide_engine(kind: str, engine_override: str, query: str) -> str:
    if kind in {"general", "scholar", "news"}:
        return "google-scholar" if kind == "scholar" else "google-news" if kind == "news" else engine_override
    q = query.lower()
    if any(token in q for token in AUTO_SCHOLAR_MARKERS):
        return "google-scholar"
    if any(token in q for token in AUTO_NEWS_MARKERS):
        return "google-news"
    return engine_override


def summarize_with_codex(query: str, title: str, url: str, source_summary: str, screenshot: Optional[str], args: argparse.Namespace, run_dir: Path) -> str:
    if args.no_codex:
        return source_summary

    screenshot_hint = screenshot or "not generated"
    prompt = (
        "You are a senior research analyst.\n"
        f"Query: {query}\n"
        f"Title: {title}\n"
        f"URL: {url}\n"
        f"Screenshot path: {screenshot_hint}\n"
        "\n"
        "Task: Produce a concise markdown summary for this search result for strategy research.\n"
        "Return only markdown.\n"
        "1) Key takeaways (3–8 bullet points)\n"
        "2) Why it is relevant to the query\n"
        "3) One-line follow-up action\n"
        "\n"
        f"Existing extracted text: {source_summary}\n"
        "\n"
        "If you think the screenshot content disagrees with text, prioritize screenshot cues. "
        "If the screenshot is missing, base your answer on extracted text only."
    )

    cmd = [
        str(CODEX_TOOL),
        "--model",
        args.codex_model,
        "--reasoning",
        args.codex_reasoning,
        "--safety",
        args.codex_safety,
        "--approval",
        args.codex_approval,
        "--skip-git-check",
        "--prompt",
        prompt,
    ]
    proc = run_cmd(cmd)
    if proc.returncode != 0:
        return source_summary
    result = (proc.stdout or "").strip()
    return result if result else source_summary


def search_once(args: argparse.Namespace, engine: str, run_dir: Path, search_tool: str, run_id: str) -> Dict[str, Any]:
    screenshot_dir = run_dir / "screenshots"
    screenshot_dir.mkdir(parents=True, exist_ok=True)
    if not os.path.exists(search_tool):
        raise RuntimeError(f"search tool not found: {search_tool}")

    search_cmd = [
        search_tool,
        "--env",
        args.env,
        "--engine",
        engine,
        "--results",
        str(args.top_results),
        "--open-top-results",
        str(args.top_results),
        "--query",
        args.query,
        "--output",
        "json",
        "--summarize-open-url",
        "--summary-max-chars",
        str(args.summary_max_chars),
        "--scroll-steps",
        str(args.scroll_steps),
        "--scroll-pause",
        str(args.scroll_pause),
        "--capture-screenshots",
        "--screenshot-dir",
        str(screenshot_dir),
        "--screenshot-prefix",
        run_id,
    ]

    if args.headless:
        search_cmd.append("--headless")
    if args.keep_open:
        search_cmd.extend(["--keep-open", "--hold-seconds", str(args.hold_seconds)])
    # Keep cache/cookies reusable but keep behavior deterministic for a single run.
    search_cmd.extend(["--profile-dir", str(Path.home() / ".local" / "share" / "web-search-selenium" / "browser-profile")])
    search_cmd.extend(["--remote-debugging-port", "9222"])

    payload: Dict[str, Any]
    proc = run_cmd(search_cmd)
    if proc.returncode != 0:
        raise RuntimeError(f"search tool failed rc={proc.returncode}\n{proc.stderr}")
    try:
        payload = json.loads((proc.stdout or "").strip())
    except json.JSONDecodeError as exc:
        err = proc.stderr.strip() if proc.stderr else ""
        raise RuntimeError(f"search tool did not output JSON: {err}") from exc

    return payload


def item_markdown(item: Dict[str, Any], idx: int, codex_summary: str) -> str:
    title = item.get("title", "(untitled)")
    url = item.get("url", "")
    snippet = item.get("snippet", "")
    raw_summary = item.get("summary", "")
    opened = item.get("opened_screenshots", [])
    screenshot = ""
    if isinstance(opened, list) and opened:
        screenshot = str(opened[0])
    lines = [
        f"# Result {idx}: {title}",
        "",
        f"- **URL:** {url}",
        f"- **Screenshot:** {screenshot or '(none)'}",
        f"- **Snippet:** {snippet}",
        "",
        "## Source summary",
        raw_summary or "(no source summary)",
        "",
        "## Codex summarized",
        codex_summary or "(no codex summary)",
        "",
    ]
    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    run_id = args.run_id or datetime.now().strftime("%Y%m%d-%H%M%S")
    engine = decide_engine(args.kind, args.engine, args.query)

    out_root = Path(args.output_dir).expanduser()
    run_dir = out_root / run_id
    run_dir.mkdir(parents=True, exist_ok=True)

    search_tool = resolve_tool_path(args.conda_run)

    payload = search_once(args, engine, run_dir, search_tool, run_id)
    opened_items = payload.get("opened_items", []) if isinstance(payload, dict) else []
    search_page_overviews = payload.get("search_page_overviews", [])
    search_page_screenshots = payload.get("search_page_screenshots", [])
    if not isinstance(opened_items, list):
        opened_items = []
    if not isinstance(search_page_overviews, list):
        search_page_overviews = []
    if not isinstance(search_page_screenshots, list):
        search_page_screenshots = []
    if not opened_items:
        print(json.dumps({"status": "no_results", "run_id": run_id, "query": args.query, "engine": engine}, ensure_ascii=False, indent=2))
        return 0

    item_dir = run_dir / "items"
    item_dir.mkdir(parents=True, exist_ok=True)

    processed: List[Dict[str, Any]] = []
    item_files: List[str] = []
    for idx, item in enumerate(opened_items[: args.top_results], 1):
        if not isinstance(item, dict):
            continue
        screenshot = None
        opened_screenshots = item.get("opened_screenshots")
        if isinstance(opened_screenshots, list) and opened_screenshots:
            first = opened_screenshots[0]
            screenshot = str(first) if isinstance(first, str) else None
        source_summary = str(item.get("summary", "") or "")
        codex_summary = summarize_with_codex(
            query=args.query,
            title=str(item.get("title", "")),
            url=str(item.get("url", "")),
            source_summary=source_summary,
            screenshot=screenshot,
            args=args,
            run_dir=run_dir,
        )
        safe_idx = f"{idx:02d}"
        item_file = item_dir / f"result-{safe_idx}.md"
        item_file.write_text(item_markdown(item, idx, codex_summary), encoding="utf-8")
        item_files.append(str(item_file))
        record: Dict[str, Any] = {
            "index": idx,
            "title": str(item.get("title", "")),
            "url": str(item.get("url", "")),
            "snippet": str(item.get("snippet", "")),
            "screenshot": screenshot,
            "raw_summary": source_summary,
            "codex_summary": codex_summary,
            "result_index": str(item.get("result_index", safe_idx)),
            "opened_screenshots": opened_screenshots if isinstance(opened_screenshots, list) else [],
        }
        processed.append(record)

    summary_payload = {
        "run_id": run_id,
        "query": args.query,
        "kind": args.kind,
        "engine": engine,
        "top_results": args.top_results,
        "count": len(processed),
        "search_page_overviews": search_page_overviews,
        "search_page_screenshots": search_page_screenshots,
        "items": processed,
        "item_markdown": item_files,
    }

    (run_dir / "search_batch_result.json").write_text(
        json.dumps(summary_payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    overall = ["# Search Batch Summary", "", f"- run_id: `{run_id}`", f"- query: `{args.query}`", f"- kind: `{args.kind}`", f"- engine: `{engine}`", f"- items: `{len(processed)}`", ""]
    if search_page_overviews:
        overall.append("## Search results page scan")
        for row in search_page_overviews:
            if not isinstance(row, dict):
                continue
            page = str(row.get("page", ""))
            row_summary = str(row.get("summary", "")).strip()
            if row_summary:
                overall.append(f"- page {page}: {row_summary[:320]}")
        overall.append("")
    if search_page_screenshots:
        overall.append("## Search result page screenshots")
        for path in search_page_screenshots:
            overall.append(f"- {path}")
        overall.append("")
    for item in processed:
        overall.append(f"## {item['index']}. {item['title'] or '(untitled)'}")
        overall.append(f"- URL: {item['url']}")
        if item["screenshot"]:
            overall.append(f"- Screenshot: `{item['screenshot']}`")
        overall.append("")
    summary_file = run_dir / "search_batch_summary.md"
    summary_file.write_text("\n".join(overall), encoding="utf-8")

    print(json.dumps(summary_payload, ensure_ascii=False, indent=2))
    print(f"run_dir={run_dir}")
    print(f"summary_file={summary_file}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
