#!/usr/bin/env python3
"""Small Selenium search helper used for experiments.

The tool supports:

- search engines (google, google-scholar, google-news, duckduckgo, bing)
- reuse an existing Chrome session/profile cache
- parsing search results
- optional click on a selected result and keep that page in the same browser window
- optional page summary extraction
"""

from __future__ import annotations

import argparse
import json
import re
import socket
import sys
import time
import urllib.parse
import urllib.request
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Union

from selenium import webdriver
from selenium.common.exceptions import (
    ElementClickInterceptedException,
    ElementNotInteractableException,
    TimeoutException,
)
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait


DEFAULT_DRIVER_ZIP = (
    "https://storage.googleapis.com/chrome-for-testing-public/"
    "145.0.7632.77/mac-x64/chromedriver-mac-x64.zip"
)
DEFAULT_DRIVER_PATH = Path.home() / ".local" / "share" / "web-search-selenium" / "chromedriver"


SearchResult = Dict[str, Union[str, object]]


@dataclass
class SearchEngine:
    name: str
    search_url: str
    result_selectors: List[str]
    title_selectors: List[str]
    snippet_selectors: List[str]
    summary_selectors: Optional[List[str]] = None
    page_param: Optional[str] = None
    page_step: int = 0
    allow_google_host: bool = False


ENGINES: Dict[str, SearchEngine] = {
    "google": SearchEngine(
        name="Google",
        search_url="https://www.google.com/search?q={query}",
        result_selectors=["div.g", "div[data-ved]", "div.MjjYud"],
        title_selectors=["h3", "a > h3", "span[role='text']"],
        snippet_selectors=["div.VwiC3b", "div.IsZvec", "span.aCOpRe", "div[data-sncf='1']"],
        page_param="start",
        page_step=10,
        allow_google_host=False,
    ),
    "google-scholar": SearchEngine(
        name="Google Scholar",
        search_url="https://scholar.google.com/scholar?q={query}",
        result_selectors=["div.gs_r", "div.gs_or", "div.gs_ri"],
        title_selectors=["h3 a", "a[href*='scholar.google.com']"],
        snippet_selectors=["div.gs_rs", "div.gs_a"],
        page_param="start",
        page_step=10,
        allow_google_host=True,
    ),
    "google-news": SearchEngine(
        name="Google News",
        search_url="https://news.google.com/search?q={query}",
        result_selectors=[
            "article",
            "div.VfPpkd-RLmnJb",
            "main article",
        ],
        title_selectors=["h4", "a", "h3", "a.DY5T1d", "a.wF2Wne"],
        snippet_selectors=["span", "p", "div", "time"],
        page_param="start",
        page_step=10,
        allow_google_host=True,
    ),
    "duckduckgo": SearchEngine(
        name="DuckDuckGo",
        search_url="https://duckduckgo.com/?q={query}",
        result_selectors=["article[data-testid='result']", "a.result__a", "div.results--main .result"],
        title_selectors=["a.result__a", "h2", "h3"],
        snippet_selectors=["a.result__snippet", "p", "div.result__snippet"],
        page_param="s",
        page_step=10,
        allow_google_host=False,
    ),
    "bing": SearchEngine(
        name="Bing",
        search_url="https://www.bing.com/search?q={query}",
        result_selectors=["li.b_algo", "li.b_ans"],
        title_selectors=["h2", "a"],
        snippet_selectors=["p", "div.b_caption p", "p.b_vPanel"],
        page_param="first",
        page_step=10,
        allow_google_host=False,
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
    parser.add_argument("--results", type=int, default=5, help="Maximum search results")
    parser.add_argument("--start-page", type=int, default=1, help="Search page start (default: 1)")
    parser.add_argument("--end-page", type=int, default=1, help="Search page end (default: 1)")
    parser.add_argument(
        "--headless", action="store_true", help="Run browser in headless mode"
    )
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
    parser.add_argument(
        "--profile-dir",
        default=str(
            Path.home() / ".local" / "share" / "web-search-selenium" / "browser-profile"
        ),
        help="Chrome user profile directory for session cache/cookies",
    )
    parser.add_argument(
        "--remote-debugging-port",
        type=int,
        default=0,
        help="Remote debugging port for Chrome DevTools (0 = random)",
    )
    parser.add_argument(
        "--attach",
        action="store_true",
        help="Attach to an existing Chrome session by debugger address",
    )
    parser.add_argument(
        "--debugger-address",
        default="",
        help="Debugger address for attach mode (default: 127.0.0.1:<remote-debugging-port>)",
    )
    parser.add_argument(
        "--keep-open",
        action="store_true",
        help="Keep browser open after results are collected",
    )
    parser.add_argument(
        "--hold-seconds",
        type=float,
        default=0.0,
        help="Seconds to wait before closing browser when --keep-open is set",
    )
    parser.add_argument(
        "--open-url",
        help="Open a fixed URL directly (for login/bootstrap), skipping search.",
    )
    parser.add_argument(
        "--open-result",
        action="store_true",
        help="After search, click/open the selected result (index via --result-index).",
    )
    parser.add_argument(
        "--open-top-results",
        type=int,
        default=0,
        help="Open and summarize the first N results (default: 0 = only --result-index).",
    )
    parser.add_argument(
        "--result-index",
        type=int,
        default=1,
        help="Which result to open when --open-result is set (default: 1)",
    )
    parser.add_argument(
        "--dismiss-cookies",
        action="store_true",
        help="Attempt to auto-dismiss common cookie overlays before searching/clicking.",
    )
    parser.add_argument(
        "--summarize-open-url",
        action="store_true",
        help="Extract and print a plain-text summary from opened URL/clicked page.",
    )
    parser.add_argument(
        "--keep-opened-tabs",
        action="store_true",
        help="Keep opened result tabs/windows instead of closing them after summarization.",
    )
    parser.add_argument(
        "--capture-screenshots",
        action="store_true",
        help="Save screenshots for major UI steps.",
    )
    parser.add_argument(
        "--screenshot-dir",
        default=str(
            Path.home() / ".local" / "share" / "web-search-selenium" / "screenshots"
        ),
        help="Directory to write screenshots.",
    )
    parser.add_argument(
        "--screenshot-prefix",
        default="websearch",
        help="Prefix for screenshot filenames.",
    )
    parser.add_argument(
        "--click-at",
        default="",
        help="Click at absolute browser coordinates (x,y) before summary.",
    )
    parser.add_argument(
        "--immersive",
        action="store_true",
        help="Drive Google search with UI flow (type query + Enter) and capture UI screenshots.",
    )
    parser.add_argument(
        "--scroll-steps",
        type=int,
        default=0,
        help="How many scroll steps to run when summarizing opened URL.",
    )
    parser.add_argument(
        "--scroll-pause",
        type=float,
        default=0.9,
        help="Seconds to wait between scroll steps (default: 0.9).",
    )
    parser.add_argument(
        "--summary-max-chars",
        type=int,
        default=2000,
        help="Maximum characters for --summarize-open-url output (default: 2000).",
    )
    return parser.parse_args()


def resolve_query(args: argparse.Namespace) -> str:
    if args.open_url:
        return ""

    query = " ".join(args.query).strip()
    if not query and args.query_opt:
        query = args.query_opt.strip()
    if not query:
        raise SystemExit("query is required (pass positional words or --query)")
    return query


def parse_click_coordinate(raw: str) -> Optional[tuple[int, int]]:
    if not raw:
        return None
    cleaned = raw.strip()
    if not cleaned:
        return None
    if "," in cleaned:
        x_text, y_text = cleaned.split(",", 1)
    elif "x" in cleaned.lower() and "," not in cleaned:
        x_text, y_text = cleaned.lower().replace("x", " ").split(None, 1)
    else:
        raise SystemExit(f"invalid --click-at format: {raw}. use x,y")

    try:
        return int(float(x_text.strip())), int(float(y_text.strip()))
    except ValueError as exc:
        raise SystemExit(f"invalid --click-at values: {raw}") from exc


def _coerce_engine_name(engine_key: str) -> str:
    return (engine_key or "").strip()


def build_search_url(
    engine: SearchEngine, engine_key: str, query: str, page: int
) -> str:
    base_url = engine.search_url.format(query=urllib.parse.quote_plus(query))
    if page <= 1 or not engine.page_param:
        return base_url

    try:
        parsed = urllib.parse.urlparse(base_url)
    except Exception:
        return base_url

    params = urllib.parse.parse_qs(parsed.query, keep_blank_values=True)
    if engine_key in {"google", "google-scholar", "google-news"}:
        page_index = max(0, page - 1)
        offset = page_index * max(1, engine.page_step or 10)
    elif engine_key == "bing":
        page_index = max(0, page - 1)
        offset = page_index * max(1, engine.page_step or 10) + 1
    else:
        page_index = max(0, page - 1)
        offset = page_index * max(1, engine.page_step or 10)

    params[engine.page_param] = [str(offset)]
    return urllib.parse.urlunparse(
        (
            parsed.scheme,
            parsed.netloc,
            parsed.path,
            parsed.params,
            urllib.parse.urlencode(params, doseq=True),
            parsed.fragment,
        )
    )


def take_screenshot(driver: webdriver.Chrome, output_dir: Path, label: str, prefix: str) -> str:
    output_dir.mkdir(parents=True, exist_ok=True)
    safe_label = re.sub(r"[^a-z0-9._-]+", "-", label.strip().lower())[:80] or "step"
    path = output_dir / f"{prefix}-{safe_label}.png"
    path.parent.mkdir(parents=True, exist_ok=True)
    driver.save_screenshot(str(path))
    return str(path)


def wait_for_new_window(
    driver: webdriver.Chrome, previous_handles: List[str], timeout: float = 2.5
) -> Optional[str]:
    deadline = time.time() + max(0.0, timeout)
    prev = set(previous_handles)
    while time.time() < deadline:
        try:
            current_handles = driver.window_handles
        except Exception:
            current_handles = previous_handles
        current_set = set(current_handles)
        new_handles = list(current_set - prev)
        if new_handles:
            return next((h for h in current_handles if h in new_handles), new_handles[0])
        time.sleep(0.1)
    return None


def switch_to_best_content_window(
    driver: webdriver.Chrome,
    previous_handles: Optional[List[str]] = None,
) -> None:
    previous = previous_handles or list(driver.window_handles)
    new_window = wait_for_new_window(driver, previous)
    if new_window:
        try:
            driver.switch_to.window(new_window)
        except Exception:
            pass
        return

    current = None
    try:
        current = driver.current_url
    except Exception:
        current = ""

    # Heuristic: if we are on a search page but there are extra tabs, use the newest one.
    try:
        handles = driver.window_handles
    except Exception:
        return
    if len(handles) > len(previous):
        for handle in reversed(handles):
            if handle not in previous:
                try:
                    driver.switch_to.window(handle)
                    return
                except Exception:
                    pass
        if handles:
            driver.switch_to.window(handles[-1])


def open_result_in_new_tab(
    driver: webdriver.Chrome,
    item: SearchResult,
    prior_handles: List[str],
) -> Optional[str]:
    url = str(item.get("url", ""))
    element = item.get("element")
    if not url:
        return None
    new_handle: Optional[str] = None
    # Open directly in a separate tab and use window handles as the source of truth.
    # This avoids mutating the search tab for each click.
    try:
        if hasattr(element, "get_attribute"):
            try:
                candidate_href = element.get_attribute("href")
            except Exception:
                candidate_href = ""
            if candidate_href:
                driver.execute_script("window.open(arguments[0], '_blank');", candidate_href)
            else:
                driver.execute_script("window.open(arguments[0], '_blank');", url)
        else:
            driver.execute_script("window.open(arguments[0], '_blank');", url)
    except Exception:
        pass

    new_handle = wait_for_new_window(driver, prior_handles, timeout=6.0)
    if new_handle:
        try:
            driver.switch_to.window(new_handle)
            return new_handle
        except Exception:
            pass

    # Selenium native fallback: force-open a new tab, then navigate there.
    # This keeps deterministic tab behavior where possible.
    try:
        opened_handle = driver.switch_to.new_window("tab")
        if opened_handle:
            driver.get(url)
            return str(opened_handle)
        new_handle = wait_for_new_window(driver, prior_handles, timeout=2.5)
        if new_handle:
            driver.switch_to.window(new_handle)
            return new_handle
    except Exception:
        pass

    # If all fallback methods fail, explicitly return None so caller can handle safely.
    # Do not navigate current tab here; that causes false positives in link-switching logic.
    return None



def click_by_coordinates(
    driver: webdriver.Chrome, x: int, y: int
) -> Dict[str, Union[str, bool]]:
    script = """
const x = Number(arguments[0]);
const y = Number(arguments[1]);
if (!Number.isFinite(x) || !Number.isFinite(y)) {
  return {ok: false, reason: "invalid-coordinate"};
}
const el = document.elementFromPoint(x, y);
if (!el) {
  return {ok: false, reason: "no-element"};
}
let target = el;
if (el.tagName.toLowerCase() !== "a" && el.closest) {
  const anchor = el.closest("a");
  if (anchor) {
    target = anchor;
  }
}
const rect = target.getBoundingClientRect();
if (!rect || !rect.width || !rect.height) {
  return {ok: false, reason: "empty-element"};
}
try {
  target.scrollIntoView({block: "center", inline: "center"});
  const eventInit = {bubbles: true, cancelable: true, view: window, clientX: x, clientY: y};
  const down = new MouseEvent("mousedown", eventInit);
  const up = new MouseEvent("mouseup", eventInit);
  const click = new MouseEvent("click", eventInit);
  target.dispatchEvent(down);
  target.dispatchEvent(up);
  target.dispatchEvent(click);
  target.click();
  return {
    ok: true,
    tag: target.tagName,
    text: (target.innerText || "").trim().slice(0, 400),
    href: target.href || target.getAttribute("href") || "",
    x,
    y,
  };
} catch (e) {
  return {
    ok: false,
    reason: String(e && e.message ? e.message : e),
  };
}
"""
    return driver.execute_script(script, x, y)


def collect_visible_elements(
    driver: webdriver.Chrome, selectors: List[str], attempts: int = 3
) -> List:
    for _ in range(attempts):
        for selector in selectors:
            try:
                nodes = driver.find_elements(By.CSS_SELECTOR, selector)
            except Exception:
                nodes = []
            if nodes:
                visible_nodes = [node for node in nodes if _is_displayed(node)]
                if visible_nodes:
                    return visible_nodes
        time.sleep(0.4)
    return []


def _is_displayed(node: webdriver.remote.webelement.WebElement) -> bool:
    try:
        return bool(node.is_displayed())
    except Exception:
        return False


def download_and_extract_driver(download_url: str, driver_dir: Path) -> Path:
    driver_dir.mkdir(parents=True, exist_ok=True)
    zip_path = driver_dir / "chromedriver.zip"
    with urllib.request.urlopen(download_url, timeout=120) as response:
        zip_path.write_bytes(response.read())

    with zipfile.ZipFile(zip_path, "r") as zf:
        zf.extractall(driver_dir)

    candidate_paths = [
        p
        for p in driver_dir.rglob("chromedriver")
        if p.is_file() and p.as_posix().endswith("chromedriver")
    ]
    if not candidate_paths:
        raise RuntimeError("Could not locate extracted chromedriver binary")

    executable = candidate_paths[0]
    executable.chmod(0o755)
    return executable


def _normalize_debugger_address(port: int, explicit: str) -> str:
    if explicit:
        return explicit.strip()
    if port <= 0:
        raise SystemExit(
            "attach mode requires either --debugger-address or --remote-debugging-port"
        )
    return f"127.0.0.1:{port}"


def is_debugger_available(address: str) -> bool:
    host, _, port = address.partition(":")
    if not host or not port:
        return False
    try:
        port_num = int(port)
    except ValueError:
        return False

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        sock.settimeout(0.75)
        return sock.connect_ex((host, port_num)) == 0
    finally:
        sock.close()


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


def create_driver(
    driver_path: Path,
    headless: bool,
    profile_dir: Path,
    debug_port: int,
    attach: bool = False,
    debugger_address: str = "",
) -> webdriver.Chrome:
    options = Options()
    options.add_argument("--start-maximized")
    options.add_argument("--disable-blink-features=AutomationControlled")
    options.add_argument("--lang=en-US")
    options.add_argument("--no-first-run")
    options.add_argument("--no-default-browser-check")

    if attach:
        address = _normalize_debugger_address(debug_port, debugger_address)
        if not is_debugger_available(address):
            raise SystemExit(
                f"attach requested but no Chrome debugger found at {address}. "
                "Start the browser with --remote-debugging-port first."
            )
        options.add_experimental_option("debuggerAddress", address)
    else:
        options.add_argument(f"--user-data-dir={profile_dir}")
        options.add_argument(f"--disk-cache-dir={profile_dir / 'cache'}")

    if headless:
        options.add_argument("--headless=new")
        options.add_argument("--window-size=1920,1080")
    elif not attach and debug_port:
        options.add_argument(f"--remote-debugging-port={debug_port}")

    service = Service(executable_path=str(driver_path))
    return webdriver.Chrome(service=service, options=options)


def _extract_text(node, selectors: List[str]) -> str:
    for selector in selectors:
        try:
            if selector.startswith("xpath:"):
                found = node.find_elements(By.XPATH, selector.replace("xpath:", "", 1))
            else:
                found = node.find_elements(By.CSS_SELECTOR, selector)
        except Exception:
            continue
        for item in found:
            text = (item.text or "").strip()
            if text:
                return text
    return ""


def dismiss_cookie_overlays(driver: webdriver.Chrome) -> None:
    def _norm(text: str) -> str:
        return re.sub(r"\s+", " ", (text or "").strip().lower())

    common_selectors = [
        "#L2AGLb",
        "button#L2AGLb",
        "button[aria-label*='Accept']",
        "button[data-testid*='accept']",
        "button[id*='accept']",
        "button[id*='Accept']",
        "button[class*='accept']",
        "button[class*='Allow']",
        "button[id*='agree']",
        "button[class*='agree']",
        "button[id*='consent']",
        "button[class*='consent']",
        "button[title*='Accept']",
        "a[role='button'][data-cookie-banner='accept']",
        "button:has-text('accept')",
        "button:has-text('agree')",
        "a:has-text('accept')",
    ]
    phrases = [
        "accept all",
        "accept",
        "i agree",
        "agree",
        "got it",
        "allow all",
        "allow",
        "continue",
        "ok",
        "ok, i agree",
    ]

    def _click_if_possible(candidate: webdriver.remote.webelement.WebElement) -> bool:
        try:
            if candidate.is_displayed() and candidate.is_enabled():
                driver.execute_script("arguments[0].scrollIntoView({block: 'center'});", candidate)
                driver.execute_script("arguments[0].click();", candidate)
                return True
        except Exception:
            return False
        return False

    def _scan_candidates(nodes: List[webdriver.remote.webelement.WebElement]) -> bool:
        for node in nodes:
            try:
                text = _norm(node.text or "")
            except Exception:
                text = ""
            for phrase in phrases:
                if phrase and phrase in text:
                    if _click_if_possible(node):
                        return True
            try:
                aria = _norm(node.get_attribute("aria-label") or "")
                if any(phrase in aria for phrase in phrases):
                    if _click_if_possible(node):
                        return True
            except Exception:
                pass
            try:
                title = _norm(node.get_attribute("title") or "")
                if any(phrase in title for phrase in phrases):
                    if _click_if_possible(node):
                        return True
            except Exception:
                pass
        return False

    def _collect_and_click() -> bool:
        # 1) direct selectors
        for selector in common_selectors:
            try:
                nodes = driver.find_elements(By.CSS_SELECTOR, selector)
            except Exception:
                nodes = []
            for node in nodes:
                if _click_if_possible(node):
                    return True

        # 2) generic candidate buttons/links
        try:
            nodes = driver.find_elements(By.CSS_SELECTOR, "button, a[role='button'], input[type='button'], [role='button']")
        except Exception:
            nodes = []
        if _scan_candidates(nodes):
            return True

        return False

    for _ in range(3):
        try:
            if _collect_and_click():
                return
            # Cookie overlays can appear after scripts settle.
            time.sleep(0.6)
            try:
                driver.switch_to.default_content()
                frames = driver.find_elements(By.TAG_NAME, "iframe")
            except Exception:
                frames = []
            for frame in frames:
                try:
                    driver.switch_to.frame(frame)
                    if _collect_and_click():
                        return
                    driver.switch_to.default_content()
                except Exception:
                    try:
                        driver.switch_to.default_content()
                    except Exception:
                        pass
            # Last resort: escape dismisses modal-like overlays.
            try:
                driver.find_element(By.TAG_NAME, "body").send_keys(Keys.ESCAPE)
            except Exception:
                pass
        except Exception:
            continue


def wait_for_results(
    driver: webdriver.Chrome, engine: SearchEngine, wait_seconds: float
) -> List:
    if not engine.result_selectors:
        return []
    for selector in engine.result_selectors:
        try:
            WebDriverWait(driver, wait_seconds).until(
                EC.presence_of_all_elements_located((By.CSS_SELECTOR, selector))
            )
            nodes = driver.find_elements(By.CSS_SELECTOR, selector)
            if nodes:
                return nodes[:30]
        except TimeoutException:
            continue
    return []


def perform_google_ui_search(driver: webdriver.Chrome, query: str, screenshot_dir: Path, capture: bool) -> None:
    if capture:
        _ = take_screenshot(driver, screenshot_dir, "google-home", "websearch")

    candidates = collect_visible_elements(
        driver,
        [
            "textarea[name='q']",
            "input[name='q']",
            "textarea[title*='Search']",
            "input[title*='Search']",
            "input[type='search']",
        ],
    )
    for input_box in candidates:
        try:
            input_box.click()
            input_box.clear()
            input_box.send_keys(query)
            input_box.send_keys(Keys.RETURN)
            time.sleep(0.6)
            if capture:
                _ = take_screenshot(driver, screenshot_dir, "after-query", "websearch")
            return
        except Exception:
            continue

    raise SystemExit("Unable to find Google search input in immersive mode.")


def collect_links(
    driver: webdriver.Chrome,
    engine: SearchEngine,
    engine_key: str,
    seen_urls: Optional[set],
    max_results: int,
) -> List[SearchResult]:
    results: List[SearchResult] = []
    items = wait_for_results(driver, engine, 5.0)
    seen = set()

    def is_relevant_target(href: str) -> bool:
        try:
            parsed = urllib.parse.urlparse(href)
        except Exception:
            return False
        host = (parsed.netloc or "").lower()
        if not host or not parsed.scheme.startswith("http"):
            return False
        if "google" in host:
            if not engine.allow_google_host:
                if parsed.path in {"/", "/webhp", "/intl/en/about/products", ""}:
                    return False
                if "search" in parsed.path:
                    return False
                if "accounts.google" in host:
                    return False
                if host.endswith("googleusercontent.com"):
                    return False
                return False
            # For google-scholar / google-news we still remove obvious chrome control paths.
            if parsed.path in {"/", "/webhp", "/intl/en/about/products", ""}:
                return False
            if "search" in parsed.path:
                return False
            if host.endswith("google.com.hk"):
                return False
            if "accounts.google" in host:
                return False
            if host.endswith("googleusercontent.com"):
                return False
            # keep Google-branded non-result links out to reduce accidental nav clicks
            allowed_google_hosts = {"scholar.google.com", "news.google.com"}
            if host.endswith("google.com") or host.endswith("google.co.uk") or host.endswith("google.com.sg"):
                if host not in allowed_google_hosts:
                    return False
            if host.endswith("scholar.google.com") and engine.name != "Google Scholar":
                return False
        return True

    def add_result(item: SearchResult) -> None:
        link = item.get("url") or ""
        if not isinstance(link, str):
            return
        if not link.startswith("http"):
            return
        if link in seen or (seen_urls is not None and link in seen_urls):
            return
        seen.add(link)
        if seen_urls is not None:
            seen_urls.add(link)
        try:
            elem = item.get("element")
            if hasattr(elem, "rect"):
                rect = elem.rect
                item["element_x"] = int(rect.get("x", 0))
                item["element_y"] = int(rect.get("y", 0))
                item["element_width"] = int(rect.get("width", 0))
                item["element_height"] = int(rect.get("height", 0))
                item["center_x"] = int(rect.get("x", 0) + rect.get("width", 0) / 2)
                item["center_y"] = int(rect.get("y", 0) + rect.get("height", 0) / 2)
        except Exception:
            pass
        results.append(item)

    if not items:
        anchors = driver.find_elements(By.CSS_SELECTOR, "a[href]")[:150]
        for anchor in anchors:
            title = (anchor.text or "").strip()
            href = (anchor.get_attribute("href") or "").strip()
            if not title or not href.startswith("http"):
                continue
            if not is_relevant_target(href):
                continue
            snippet = ""
            add_result(
                {
                    "title": title,
                    "url": href,
                    "snippet": snippet,
                    "element": anchor,
                }
            )
            if len(results) >= max_results:
                break
        return results[:max_results]

    for node in items:
        title = _extract_text(node, engine.title_selectors)
        snippet = _extract_text(node, engine.snippet_selectors)
        anchor = None
        try:
            anchor = node.find_element(By.CSS_SELECTOR, "a[href]")
        except Exception:
            try:
                anchors = node.find_elements(By.CSS_SELECTOR, "a")
                anchor = anchors[0] if anchors else None
            except Exception:
                anchor = None

        url = ""
        if anchor is not None:
            try:
                url = (anchor.get_attribute("href") or "").strip()
            except Exception:
                url = ""

        if not title and not url:
            continue
        if url and not is_relevant_target(url):
            continue
        if not title and anchor is not None:
            try:
                title = (anchor.text or "").strip()
            except Exception:
                title = ""

        add_result(
            {
                "title": title,
                "url": url,
                "snippet": snippet,
                "element": anchor,
            }
        )
        if len(results) >= max_results:
            break

    if not results:
        anchors = driver.find_elements(By.CSS_SELECTOR, "a[href]")[:150]
        for anchor in anchors:
            title = (anchor.text or "").strip()
            href = (anchor.get_attribute("href") or "").strip()
            if not title or not href.startswith("http"):
                continue
            if not is_relevant_target(href):
                continue
            add_result({"title": title, "url": href, "snippet": "", "element": anchor})
            if len(results) >= max_results:
                break

    return results[:max_results]


def extract_page_summary(driver: webdriver.Chrome, max_chars: int) -> str:
    selectors = ["article", "main", "body"]
    for selector in selectors:
        try:
            nodes = driver.find_elements(By.CSS_SELECTOR, selector)
        except Exception:
            continue
        for node in nodes:
            text = (node.text or "").strip()
            if text:
                normalized = re.sub(r"\n{3,}", "\n\n", text)
                normalized = re.sub(r"[ \t]+", " ", normalized)
                return normalized[:max_chars].strip()
    return ""


def collect_scrolled_summary(
    driver: webdriver.Chrome,
    max_chars: int,
    scroll_steps: int,
    scroll_pause: float,
    screenshot_dir: Optional[Path],
    screenshot_prefix: str,
    capture: bool,
) -> Dict[str, Union[str, List[Dict[str, Union[str, float, int]]]]]:
    steps: List[Dict[str, Union[str, float, int]]] = []
    summaries: List[str] = []
    seen_fragments = set()
    total_chars = 0
    safe_prefix = re.sub(r"[^a-z0-9._-]+", "-", screenshot_prefix.lower())[:80] or "open"

    def _collect_once(step_id: int) -> str:
        nonlocal total_chars
        text = extract_page_summary(driver, max_chars)
        if not text:
            return ""
        if text in seen_fragments:
            return ""
        seen_fragments.add(text)
        snippets = []
        # Keep each step short to avoid duplicated large blocks.
        remaining = max(0, max_chars - total_chars)
        if remaining <= 0:
            return ""
        chunk = text[:remaining]
        total_chars += len(chunk)
        summaries.append(chunk)
        return chunk

    step_path: Optional[str]
    if capture and screenshot_dir:
        for step in range(max(0, scroll_steps) + 1):
            step_path = take_screenshot(
                driver,
                screenshot_dir,
                f"{safe_prefix}-scroll-{step:02d}",
                "websearch",
            )
            chunk = _collect_once(step)
            step_record: Dict[str, Union[str, float, int]] = {
                "scroll_step": step,
                "screenshot": step_path,
            }
            if chunk:
                step_record["summary"] = chunk
            try:
                viewport = capture_viewport_info(driver)
                step_record["scrollY"] = int(viewport.get("scrollY", 0))
                step_record["documentHeight"] = int(viewport.get("documentHeight", 0))
            except Exception:
                pass
            steps.append(step_record)

            if step < scroll_steps:
                try:
                    if step == 0 and step_path and not step_record.get("summary"):
                        pass
                    driver.execute_script(
                        "window.scrollBy({top: Math.max(window.innerHeight * 0.85, 200), behavior: 'smooth'});"
                    )
                except Exception:
                    try:
                        driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
                    except Exception:
                        pass
                time.sleep(max(0.1, scroll_pause))
            if total_chars >= max_chars:
                break
    else:
        for step in range(max(0, scroll_steps) + 1):
            chunk = _collect_once(step)
            step_record = {
                "scroll_step": step,
            }
            if chunk:
                step_record["summary"] = chunk
            try:
                viewport = capture_viewport_info(driver)
                step_record["scrollY"] = int(viewport.get("scrollY", 0))
            except Exception:
                pass
            steps.append(step_record)
            if step < scroll_steps and chunk is not None:
                try:
                    driver.execute_script(
                        "window.scrollBy({top: Math.max(window.innerHeight * 0.85, 200), behavior: 'smooth'});"
                    )
                except Exception:
                    try:
                        driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
                    except Exception:
                        pass
                time.sleep(max(0.1, scroll_pause))
            if total_chars >= max_chars:
                break

    if chunk := " ".join(summaries).strip():
        return {
            "summary": chunk,
            "screenshots": [str(step.get("screenshot")) for step in steps if step.get("screenshot")],
            "steps": steps,
        }
    return {"summary": "", "screenshots": [str(step.get("screenshot")) for step in steps if step.get("screenshot")], "steps": steps}


def capture_viewport_info(driver: webdriver.Chrome) -> Dict[str, Union[int, float, str]]:
    return driver.execute_script(
        """
        return {
            width: window.innerWidth,
            height: window.innerHeight,
            scrollX: window.scrollX,
            scrollY: window.scrollY,
            dpr: window.devicePixelRatio || 1,
            documentWidth: Math.max(
                document.documentElement && document.documentElement.scrollWidth ? document.documentElement.scrollWidth : 0,
                document.body && document.body.scrollWidth ? document.body.scrollWidth : 0
            ),
            documentHeight: Math.max(
                document.documentElement && document.documentElement.scrollHeight ? document.documentElement.scrollHeight : 0,
                document.body && document.body.scrollHeight ? document.body.scrollHeight : 0
            ),
            userAgent: navigator.userAgent || "",
        };
        """
    )


def click_result_and_summary(
    driver: webdriver.Chrome,
    results: List[SearchResult],
    index: int,
    summary_max_chars: int,
    open_in_new_tab: bool = False,
    base_window: Optional[str] = None,
    screenshot_dir: Optional[Path] = None,
    screenshot_prefix: str = "websearch",
    capture: bool = False,
    scroll_steps: int = 0,
    scroll_pause: float = 0.9,
    keep_opened_tabs: bool = False,
) -> SearchResult:
    selected_idx = max(1, index)
    if selected_idx > len(results):
        raise SystemExit(f"result index {selected_idx} out of range (got {len(results)})")

    item = results[selected_idx - 1]
    url = str(item.get("url", ""))
    element = item.get("element")

    prior_handles = list(driver.window_handles)
    opened_handle = None

    if open_in_new_tab:
        opened_handle = open_result_in_new_tab(driver=driver, item=item, prior_handles=prior_handles)
    else:
        # Some result anchors are not reliably clickable, so fallback to direct URL navigation.
        if hasattr(element, "click"):
            try:
                driver.execute_script("arguments[0].scrollIntoView({block: 'center'});", element)
                driver.execute_script("arguments[0].click();", element)
            except (ElementClickInterceptedException, ElementNotInteractableException):
                pass
            except Exception:
                pass
        if not driver.current_url or driver.current_url == "about:blank":
            try:
                driver.get(url)
            except Exception as exc:
                raise SystemExit(f"clicking result failed: {exc}") from exc
        opened_handle = driver.current_window_handle
        if opened_handle in prior_handles and url and not any(w in (driver.current_url or "") for w in ["google", "bing", "duckduckgo"]):
            # If click failed and navigation happened in search tab, keep deterministic by opening in-place.
            pass
        else:
            switch_to_best_content_window(driver, prior_handles)
            opened_handle = driver.current_window_handle

    # Give page time to render before summary/next actions.
    time.sleep(1.5)
    summary = ""
    opened_screenshots: List[str] = []
    open_steps: List[Dict[str, Union[str, float, int]]] = []
    if summary_max_chars > 0:
        summary_payload = collect_scrolled_summary(
            driver=driver,
            max_chars=summary_max_chars,
            scroll_steps=scroll_steps,
            scroll_pause=scroll_pause,
            screenshot_dir=screenshot_dir,
            screenshot_prefix=f"{screenshot_prefix}-open",
            capture=capture,
        )
        if isinstance(summary_payload, dict):
            summary = str(summary_payload.get("summary", ""))
            opened_screenshots = [
                str(path) for path in (summary_payload.get("screenshots") or [])
            ]
            open_steps = summary_payload.get("steps", []) if isinstance(summary_payload.get("steps"), list) else []
    summary_item = item.copy()
    summary_item["summary"] = summary
    summary_item["result_index"] = str(selected_idx)
    if opened_screenshots:
        summary_item["opened_screenshots"] = opened_screenshots
    if open_steps:
        summary_item["open_scroll_steps"] = open_steps

    if not keep_opened_tabs:
        if opened_handle is not None and base_window:
            try:
                if driver.current_window_handle != base_window:
                    try:
                        driver.close()
                    except Exception:
                        pass
                driver.switch_to.window(base_window)
            except Exception:
                pass
    return summary_item


def results_payload(results: List[SearchResult]) -> List[Dict[str, str]]:
    safe: List[Dict[str, str]] = []
    for item in results:
        url = item.get("url", "")
        title = item.get("title", "")
        snippet = item.get("snippet", "")
        safe_item: Dict[str, str] = {
            "title": str(title),
            "url": str(url),
            "snippet": str(snippet),
        }
        for key in [
            "page",
            "position",
            "center_x",
            "center_y",
            "element_x",
            "element_y",
            "element_width",
            "element_height",
        ]:
            value = item.get(key)
            if isinstance(value, int):
                safe_item[key] = str(value)
        safe.append(safe_item)
    return safe


def print_results(query: str, items: List[SearchResult], output: str) -> None:
    if output == "json":
        return

    if not items:
        print(f"No results for: {query}")
        return

    print(f"Results for: {query}")
    for idx, item in enumerate(items, 1):
        title = str(item.get("title") or "(untitled)")
        snippet = str(item.get("snippet") or "")
        print(f"[{idx}] {title}")
        print(f"    url: {item.get('url')}")
        if snippet:
            print(f"    snippet: {snippet}")


def sanitize_for_json(value: object) -> object:
    if value is None or isinstance(value, (str, int, float, bool)):
        return value
    if isinstance(value, list):
        return [sanitize_for_json(item) for item in value]
    if isinstance(value, dict):
        safe: Dict[str, object] = {}
        for key, item in value.items():
            if key == "element":
                continue
            safe[key] = sanitize_for_json(item)
        return safe
    return str(value)


def print_open_payload(
    payload: Dict[str, str],
    output_format: str,
    context: str,
) -> None:
    if output_format == "json":
        safe_payload = sanitize_for_json(payload)
        print(json.dumps(safe_payload, ensure_ascii=False, indent=2))
        return
    if context:
        print(context)
    print(f"Opened URL: {payload.get('url')}")
    if payload.get("summary"):
        print("--- Opened URL Summary ---")
        print(payload.get("summary", ""))


def main() -> None:
    args = parse_args()
    query = resolve_query(args).strip()
    screenshot_dir = Path(args.screenshot_dir).expanduser()
    screenshot_steps: List[str] = []
    start_page = max(1, int(args.start_page))
    end_page = max(start_page, int(args.end_page))

    if args.open_result and args.open_url:
        raise SystemExit("--open-result cannot be used with --open-url")
    if args.start_page < 1 or args.end_page < 1:
        raise SystemExit("--start-page/--end-page must be >= 1")
    if args.end_page < args.start_page:
        raise SystemExit("--end-page must be >= --start-page")
    if args.immersive and args.engine not in {"google", "google-scholar", "google-news"}:
        raise SystemExit("--immersive is supported for google, google-scholar and google-news")
    if args.immersive and not query:
        raise SystemExit("--immersive requires a query")
    click_point = parse_click_coordinate(args.click_at)

    driver_path = find_driver(args)
    profile_dir = Path(args.profile_dir).expanduser()
    profile_dir.mkdir(parents=True, exist_ok=True)
    driver = create_driver(
        driver_path=driver_path,
        headless=args.headless,
        profile_dir=profile_dir,
        debug_port=args.remote_debugging_port,
        attach=args.attach,
        debugger_address=args.debugger_address,
    )

    open_summary = ""
    viewport_info: Dict[str, Union[int, float, str]] = {}
    query_results: List[SearchResult] = []
    clicked_result: Optional[SearchResult] = None
    clicked_results: List[SearchResult] = []
    remaining_results = max(0, args.results)
    seen_urls: set[str] = set()
    engine_key = _coerce_engine_name(args.engine)
    engine = ENGINES[engine_key]

    try:
        if args.open_url:
            driver.get(args.open_url)
            viewport_info = capture_viewport_info(driver)
            if args.dismiss_cookies:
                dismiss_cookie_overlays(driver)
            if args.capture_screenshots:
                screenshot_steps.append(take_screenshot(driver, screenshot_dir, "open-url", args.screenshot_prefix))
            if args.summarize_open_url:
                open_summary_payload = collect_scrolled_summary(
                    driver=driver,
                    max_chars=args.summary_max_chars,
                    scroll_steps=args.scroll_steps,
                    scroll_pause=args.scroll_pause,
                    screenshot_dir=screenshot_dir,
                    screenshot_prefix=f"{args.screenshot_prefix}-open-url",
                    capture=args.capture_screenshots,
                )
                open_summary = str(open_summary_payload.get("summary", ""))
                clicked_result = {
                    "title": "",
                    "url": args.open_url,
                    "summary": open_summary,
                    "result_index": "open-url",
                }
                if open_summary_payload.get("screenshots"):
                    clicked_result["opened_screenshots"] = [str(path) for path in open_summary_payload.get("screenshots", [])]
                if open_summary_payload.get("steps"):
                    clicked_result["open_scroll_steps"] = open_summary_payload.get("steps")
        else:
            if args.immersive:
                base_query_url = build_search_url(engine, engine_key, query, start_page)
                driver.get(base_query_url)

                if args.dismiss_cookies:
                    dismiss_cookie_overlays(driver)
                    if args.capture_screenshots:
                        screenshot_steps.append(
                            take_screenshot(driver, screenshot_dir, "after-cookie-dismiss", args.screenshot_prefix)
                        )
                if args.capture_screenshots:
                    screenshot_steps.append(
                        take_screenshot(driver, screenshot_dir, "google-home-before-query", args.screenshot_prefix)
                    )

                perform_google_ui_search(driver, query, screenshot_dir, args.capture_screenshots)
                if args.capture_screenshots:
                    screenshot_steps.append(take_screenshot(driver, screenshot_dir, "google-results", args.screenshot_prefix))

                page_start = start_page
                query_results = []
                seen_urls = set()
                result_counter = 0
                # For immersive path, start with first page via UI typing; additional pages use direct URLs.
                for page in range(start_page, end_page + 1):
                    if remaining_results <= 0:
                        break
                    if page > start_page:
                        page_url = build_search_url(engine, engine_key, query, page)
                        driver.get(page_url)
                        if args.capture_screenshots:
                            screenshot_steps.append(
                                take_screenshot(driver, screenshot_dir, f"page-{page:02d}", args.screenshot_prefix)
                            )

                    time.sleep(0.5)
                    viewport_info = capture_viewport_info(driver)
                    page_results = collect_links(
                        driver=driver,
                        engine=engine,
                        engine_key=engine_key,
                        seen_urls=seen_urls,
                        max_results=remaining_results,
                    )
                    if args.capture_screenshots:
                        screenshot_steps.append(take_screenshot(driver, screenshot_dir, "results", args.screenshot_prefix))
                    for item in page_results:
                        result_counter += 1
                        if result_counter > args.results:
                            break
                        item = dict(item)
                        item["page"] = str(page)
                        item["position"] = str(result_counter)
                        query_results.append(item)
                        remaining_results -= 1
            else:
                result_counter = 0
                for page in range(start_page, end_page + 1):
                    if remaining_results <= 0:
                        break
                    page_url = build_search_url(engine, engine_key, query, page)
                    driver.get(page_url)
                    if args.dismiss_cookies and page == start_page:
                        dismiss_cookie_overlays(driver)
                        if args.capture_screenshots:
                            screenshot_steps.append(
                                take_screenshot(driver, screenshot_dir, "after-cookie-dismiss", args.screenshot_prefix)
                            )

                    time.sleep(0.5)
                    viewport_info = capture_viewport_info(driver)
                    if args.capture_screenshots:
                        screenshot_steps.append(
                            take_screenshot(driver, screenshot_dir, f"search-page-{page:02d}", args.screenshot_prefix)
                        )

                    page_results = collect_links(
                        driver=driver,
                        engine=engine,
                        engine_key=engine_key,
                        seen_urls=seen_urls,
                        max_results=remaining_results,
                    )
                    for item in page_results:
                        result_counter += 1
                        if result_counter > args.results:
                            break
                        item = dict(item)
                        item["page"] = str(page)
                        item["position"] = str(result_counter)
                        query_results.append(item)
                        remaining_results -= 1

            if args.open_result or click_point is not None or args.open_top_results > 0:
                base_window: Optional[str] = None
                try:
                    base_window = driver.current_window_handle
                except Exception:
                    base_window = None

                if click_point is not None:
                    prior_handles = list(driver.window_handles)
                    click_result = click_by_coordinates(driver, click_point[0], click_point[1])
                    if not click_result.get("ok"):
                        raise SystemExit(f"click-by-coordinate failed: {click_result.get('reason', 'unknown')}")
                    switch_to_best_content_window(driver, prior_handles)
                    time.sleep(1.2)
                    clicked_result = {
                        "title": click_result.get("text", ""),
                        "url": click_result.get("href", ""),
                        "summary": "",
                        "result_index": "manual",
                    }
                    if args.summarize_open_url:
                        summary_payload = collect_scrolled_summary(
                            driver=driver,
                            max_chars=args.summary_max_chars,
                            scroll_steps=args.scroll_steps,
                            scroll_pause=args.scroll_pause,
                            screenshot_dir=screenshot_dir,
                            screenshot_prefix=f"{args.screenshot_prefix}-coordinate-open",
                            capture=args.capture_screenshots,
                        )
                        open_summary = str(summary_payload.get("summary", ""))
                        if summary_payload.get("screenshots"):
                            clicked_result["opened_screenshots"] = [
                                str(path) for path in summary_payload.get("screenshots", [])
                            ]
                        if summary_payload.get("steps"):
                            clicked_result["open_scroll_steps"] = summary_payload.get("steps")
                        clicked_result["summary"] = open_summary
                    if args.capture_screenshots:
                        screenshot_steps.append(take_screenshot(driver, screenshot_dir, "after-coordinate-click", args.screenshot_prefix))
                    clicked_results = [clicked_result]
                else:
                    open_indices: List[int] = []
                    if args.open_top_results > 0:
                        open_indices = list(
                            range(1, min(len(query_results), max(1, args.open_top_results)) + 1)
                        )
                    else:
                        open_indices = [args.result_index]

                    for idx in open_indices:
                        clicked = click_result_and_summary(
                            driver=driver,
                            results=query_results,
                            index=idx,
                            summary_max_chars=args.summary_max_chars,
                            screenshot_dir=screenshot_dir if args.capture_screenshots else None,
                            screenshot_prefix=f"{args.screenshot_prefix}-idx{idx:02d}",
                            capture=args.capture_screenshots,
                            scroll_steps=args.scroll_steps,
                            scroll_pause=args.scroll_pause,
                            open_in_new_tab=True,
                            base_window=base_window,
                            keep_opened_tabs=args.keep_opened_tabs,
                        )
                        clicked_results.append(clicked)
                        if args.capture_screenshots:
                            screenshot_steps.append(take_screenshot(driver, screenshot_dir, f"after-result-click-{idx:02d}", args.screenshot_prefix))
                        if base_window:
                            try:
                                driver.switch_to.window(base_window)
                            except Exception:
                                pass
                        if base_window is None:
                            try:
                                clicked_results[-1]["search_backed"] = "unable"
                            except Exception:
                                pass
                    clicked_result = clicked_results[0] if clicked_results else None
                if args.summarize_open_url and clicked_result.get("summary"):
                    open_summary = str(clicked_result.get("summary", ""))
    except TimeoutException as err:
        raise SystemExit(f"search timeout: {err}")
    except Exception as err:
        raise SystemExit(f"web search failed: {err}")
    finally:
        should_quit = not args.attach
        if args.attach:
            should_quit = False
        elif args.keep_open:
            should_quit = False
            if args.hold_seconds > 0:
                time.sleep(args.hold_seconds)
            elif sys.stdin.isatty():
                input("Finished. Press Enter to close browser and finish.")
            else:
                time.sleep(1)

        if should_quit:
            driver.quit()

    if args.open_url:
        payload = {
            "mode": "open-url",
            "url": args.open_url,
            "summary": open_summary,
            "summary_max_chars": args.summary_max_chars,
            "screenshots": screenshot_steps,
            "viewport": viewport_info,
        }
        print_open_payload(payload, args.output, f"Original query: {query}" if query else "")
        return

    if args.open_result or click_point is not None or args.open_top_results > 0:
        safe_opened_items = [
            sanitize_for_json(item)
            for item in (clicked_results if isinstance(clicked_results, list) else [])
        ]
        safe_clicked = sanitize_for_json(clicked_result) if isinstance(clicked_result, dict) else {}
        if isinstance(safe_clicked, dict) and "element" in safe_clicked:
            del safe_clicked["element"]

        payload = {
            "mode": "search-and-open",
            "query": query,
            "engine": args.engine,
            "start_page": start_page,
            "end_page": end_page,
            "results_count": len(query_results),
            "results": results_payload(query_results),
            "screenshots": screenshot_steps,
            "viewport": viewport_info,
            "count": len(query_results),
            "clicked": {
                "result_index": safe_clicked.get("result_index", ""),
                "title": str(safe_clicked.get("title", "")),
                "url": str(safe_clicked.get("url", "")),
                "summary": str(safe_clicked.get("summary", "")),
                "coordinate_click": args.click_at or "",
                "open_top_results": args.open_top_results,
            },
            "opened_items": safe_opened_items,
        }
        if isinstance(clicked_result, dict):
            for extra_key in (
                "opened_screenshots",
                "open_scroll_steps",
                "click_point",
                "scroll_steps",
                "scroll_pause",
            ):
                if extra_key in clicked_result:
                    payload["clicked"][extra_key] = clicked_result[extra_key]
        if args.open_top_results > 0:
            payload["opened_count"] = len(clicked_results)

        if args.output == "json":
            print(json.dumps(sanitize_for_json(payload), ensure_ascii=False, indent=2))
        else:
            print_results(query, query_results, "text")
            if clicked_results:
                print("--- Opened Items ---")
                for item in clicked_results:
                    index = item.get("result_index", "")
                    title = item.get("title", "(untitled)")
                    url = item.get("url", "")
                    print(f"- [{index}] {title}")
                    if url:
                        print(f"  URL: {url}")
                    item_summary = str(item.get("summary", "") or "")
                    if item_summary:
                        print("  Summary:")
                        print(f"  {item_summary[:2800]}")
            elif clicked_result:
                print(f"Opened [{clicked_result.get('result_index', args.result_index)}] {clicked_result.get('title','(untitled)')}")
                print(f"Opened URL: {clicked_result.get('url')}")
                if open_summary:
                    print("--- Opened URL Summary ---")
                    print(open_summary)
        return

    payload = {
        "query": query,
        "engine": args.engine,
        "count": len(query_results),
        "items": results_payload(query_results),
        "start_page": start_page,
        "end_page": end_page,
        "results_count": len(query_results),
        "screenshots": screenshot_steps,
        "viewport": viewport_info,
    }
    if args.output == "json":
        print(json.dumps(sanitize_for_json(payload), ensure_ascii=False, indent=2))
    else:
        print_results(query, query_results, "text")


if __name__ == "__main__":
    main()
