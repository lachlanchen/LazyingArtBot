#!/usr/bin/env python3
"""Small Selenium search helper used for experiments.

The script can query search engines in a visible browser (default) and prints
parsed results. It supports a fallback path for blocked/empty pages by collecting
candidate links from result pages.
"""

from __future__ import annotations

import argparse
import json
import time
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List

import urllib.request
import urllib.parse

from selenium import webdriver
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait


DEFAULT_DRIVER_ZIP = (
    "https://storage.googleapis.com/chrome-for-testing-public/"
    "145.0.7632.77/mac-x64/chromedriver-mac-x64.zip"
)
DEFAULT_DRIVER_PATH = Path.home() / ".local" / "share" / "web-search-selenium" / "chromedriver"


@dataclass
class SearchEngine:
    name: str
    search_url: str
    result_selectors: List[str]
    title_selectors: List[str]
    snippet_selectors: List[str]


ENGINES: Dict[str, SearchEngine] = {
    "google": SearchEngine(
        name="Google",
        search_url="https://www.google.com/search?q={query}",
        result_selectors=["div.g", "div[data-ved]"],
        title_selectors=["h3", "a > h3", "span[role='text']"],
        snippet_selectors=["div.VwiC3b", "div.IsZvec", "span.aCOpRe"],
    ),
    "duckduckgo": SearchEngine(
        name="DuckDuckGo",
        search_url="https://duckduckgo.com/?q={query}",
        result_selectors=["article[data-testid='result']", "a.result__a"],
        title_selectors=["a.result__a", "h2", "h3"],
        snippet_selectors=["a.result__snippet", "p", "div.result__snippet"],
    ),
    "bing": SearchEngine(
        name="Bing",
        search_url="https://www.bing.com/search?q={query}",
        result_selectors=["li.b_algo", "li.b_ans"],
        title_selectors=["h2", "a"],
        snippet_selectors=["p", "div.b_caption p", "p.b_vPanel"],
    ),
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Search the web using Selenium.")
    parser.add_argument("query", nargs="*", help="Search query")
    parser.add_argument("--query", dest="query_opt", help="Search query")
    parser.add_argument(
        "--engine",
        choices=sorted(ENGINES),
        default="google",
        help="Search engine to use (default: google)",
    )
    parser.add_argument("--results", type=int, default=5, help="Maximum results")
    parser.add_argument("--headless", action="store_true", help="Run browser in headless mode")
    parser.add_argument("--driver", help="Path to chromedriver executable")
    parser.add_argument(
        "--driver-zip",
        default=DEFAULT_DRIVER_ZIP,
        help="Chromedriver zip URL for installation fallback",
    )
    parser.add_argument(
        "--driver-dir",
        default=str(DEFAULT_DRIVER_PATH.parent),
        help="Directory to cache driver (default: ~/.local/share/web-search-selenium)",
    )
    parser.add_argument(
        "--install-driver",
        action="store_true",
        help="Download/extract default driver if missing",
    )
    parser.add_argument(
        "--output",
        choices=["text", "json"],
        default="text",
        help="Output format",
    )
    parser.add_argument(
        "--wait",
        type=float,
        default=20.0,
        help="Seconds to wait for result load",
    )
    return parser.parse_args()


def resolve_query(args: argparse.Namespace) -> str:
    query = " ".join(args.query).strip()
    if not query and args.query_opt:
        query = args.query_opt.strip()
    if not query:
        raise SystemExit("query is required (pass positional words or --query)")
    return query


def download_and_extract_driver(download_url: str, driver_dir: Path) -> Path:
    driver_dir.mkdir(parents=True, exist_ok=True)
    zip_path = driver_dir / "chromedriver.zip"
    with urllib.request.urlopen(download_url, timeout=120) as response:
        data = response.read()
    zip_path.write_bytes(data)

    with zipfile.ZipFile(zip_path, "r") as zf:
        members = [m for m in zf.namelist() if m.endswith("chromedriver") and "chromedriver" in Path(m).name]
        if not members:
            raise RuntimeError("Downloaded archive does not contain chromedriver")
        extracted = zf.extractall(driver_dir)
    candidate_paths = [
        p for p in driver_dir.rglob("chromedriver") if p.is_file() and p.as_posix().endswith("chromedriver")
    ]
    if not candidate_paths:
        raise RuntimeError("Could not locate extracted chromedriver binary")
    executable = candidate_paths[0]
    executable.chmod(0o755)
    return executable


def find_driver(args: argparse.Namespace) -> Path:
    if args.driver:
        driver_path = Path(args.driver).expanduser()
        if not driver_path.exists():
            raise SystemExit(f"driver path does not exist: {driver_path}")
        return driver_path

    driver_dir = Path(args.driver_dir).expanduser()
    cached = sorted(driver_dir.glob("**/chromedriver"))
    if cached:
        return cached[0]

    if args.install_driver:
        return download_and_extract_driver(args.driver_zip, driver_dir)

    raise SystemExit(
        "Chromedriver not found. Pass --driver <path> or --install-driver to fetch one."
    )


def create_driver(driver_path: Path, headless: bool) -> webdriver.Chrome:
    options = Options()
    options.add_argument("--start-maximized")
    options.add_argument("--disable-blink-features=AutomationControlled")
    options.add_argument("--lang=en-US")
    if headless:
        options.add_argument("--headless=new")
        options.add_argument("--window-size=1920,1080")
    service = Service(executable_path=str(driver_path))
    return webdriver.Chrome(service=service, options=options)


def wait_for_results(driver: webdriver.Chrome, engine: SearchEngine, wait_seconds: float) -> List:
    if not engine.result_selectors:
        return []
    for selector in engine.result_selectors:
        try:
            WebDriverWait(driver, wait_seconds).until(
                EC.presence_of_all_elements_located((By.CSS_SELECTOR, selector))
            )
            nodes = driver.find_elements(By.CSS_SELECTOR, selector)
            if nodes:
                return nodes[:25]
        except TimeoutException:
            continue
    return []


def extract_text(el, selectors: Iterable[str]) -> str:
    for selector in selectors:
        try:
            text_nodes = el.find_elements(By.CSS_SELECTOR, selector)
            for node in text_nodes:
                text = (node.text or "").strip()
                if text:
                    return text
        except Exception:
            continue
    return ""


def collect_links_fallback(driver: webdriver.Chrome, engine: SearchEngine, max_results: int) -> List[Dict[str, str]]:
    links: List[Dict[str, str]] = []
    items = wait_for_results(driver, engine, 2.0)
    if not items:
        anchors = driver.find_elements(By.CSS_SELECTOR, "a[href]")[:120]
        seen = set()
        for a in anchors:
            title = (a.text or "").strip()
            href = a.get_attribute("href") or ""
            if not title or not href or href in seen:
                continue
            if not href.startswith("http"):
                continue
            links.append({"title": title, "url": href, "snippet": ""})
            seen.add(href)
            if len(links) >= max_results:
                break
        return links

    links = []
    seen = set()
    for node in items:
        title = extract_text(node, engine.title_selectors)
        if not title:
            continue
        snippet = extract_text(node, engine.snippet_selectors)
        link = ""
        try:
            anchor = node.find_element(By.CSS_SELECTOR, "a[href]")
            link = anchor.get_attribute("href") or ""
        except Exception:
            pass
        if not link or link in seen or not link.startswith("http"):
            continue
        seen.add(link)
        links.append({"title": title, "url": link, "snippet": snippet})
        if len(links) >= max_results:
            break
    return links


def search(query: str, engine_name: str, driver: webdriver.Chrome, limit: int, wait_seconds: float) -> List[Dict[str, str]]:
    engine = ENGINES[engine_name]
    url = engine.search_url.format(query=urllib.parse.quote_plus(query))
    driver.get(url)
    time.sleep(0.5)

    items = collect_links_fallback(driver, engine, max_results=limit)
    if not items:
        # final fallback to links in body
        items = collect_links_fallback(driver, SearchEngine("Fallback", url, [], [""], [""]), limit)
    return items[:limit]


def print_results(query: str, items: List[Dict[str, str]], output: str) -> None:
    if output == "json":
        payload = {
            "query": query,
            "count": len(items),
            "items": items,
        }
        print(json.dumps(payload, ensure_ascii=False, indent=2))
        return

    if not items:
        print(f"No results for: {query}")
        return

    print(f"Results for: {query}")
    for idx, item in enumerate(items, 1):
        title = item.get("title") or "(untitled)"
        snippet = item.get("snippet") or ""
        print(f"[{idx}] {title}")
        print(f"    url: {item.get('url')}")
        if snippet:
            print(f"    snippet: {snippet}")



def main() -> None:
    args = parse_args()
    query = resolve_query(args)
    query = query.strip()

    driver_path = find_driver(args)
    driver = create_driver(driver_path, headless=args.headless)

    try:
        results = search(
            query=query,
            engine_name=args.engine,
            driver=driver,
            limit=args.results,
            wait_seconds=args.wait,
        )
    except TimeoutException as err:
        raise SystemExit(f"search timeout: {err}")
    finally:
        driver.quit()

    print_results(query, results, args.output)


if __name__ == "__main__":
    main()
