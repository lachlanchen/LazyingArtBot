#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
WORKSPACE="/Users/lachlan/.openclaw/workspace"
PROMPT_DIR="$REPO_DIR/orchestral/prompt_tools"
NOTES_ROOT="$WORKSPACE/AutoLife/MetaNotes/Companies/Lightmind"
ARTIFACT_BASE="$WORKSPACE/AutoLife/MetaNotes/Companies/Lightmind/pipeline_runs"
PIPELINE_LOCK_FILE="$ARTIFACT_BASE/.lightmind_pipeline.lock"
CONFIDENTIAL_ROOT="/Users/lachlan/Library/Containers/com.tencent.WeWorkMac/Data/WeDrive/LightMind Tech Ltd./LightMind Tech Ltd./LightMind_Confidential"
LIGHTMIND_INPUT_ROOT="/Users/lachlan/Documents/LazyingArtBotIO/LightMind/Input"
LIGHTMIND_OUTPUT_ROOT="/Users/lachlan/Documents/LazyingArtBotIO/LightMind/Output"

DEFAULT_FROM="lachlan.miao.chen@gmail.com"
MODEL="gpt-5.1-codex-mini"
REASONING="medium"
SAFETY="${CODEX_SAFETY:-danger-full-access}"
APPROVAL="${CODEX_APPROVAL:-never}"
SEND_EMAIL=1
FROM_ADDR="$DEFAULT_FROM"
TO_ADDRS=("lachchen@qq.com" "ethan@lightmind.art" "robbie@lightmind.art" "lachlan@lightmind.art")
CUSTOM_TO=0
MARKET_CONTEXT_FILE=""
RUN_RESOURCE_ANALYSIS=1
RESOURCE_OUTPUT_DIR="$LIGHTMIND_OUTPUT_ROOT/ResourceAnalysis"
RESOURCE_LABEL="lightmind-resource-analysis"
RESOURCE_ROOTS=(
  "$CONFIDENTIAL_ROOT"
  "$LIGHTMIND_INPUT_ROOT"
  "$LIGHTMIND_OUTPUT_ROOT"
)
ACADEMIC_RESEARCH=1
ACADEMIC_MAX_RESULTS=5
ACADEMIC_QUERIES=(
  "AI system design for enterprise"
  "AI product management tooling"
  "AI for scientific discovery"
  "agentic workflow and coordination"
  "AI + CVPR"
  "AI + ICML"
  "AI + SIGGRAPH"
  "AI + Nature"
  "AI + Science"
)
FUNDING_LANGUAGE_POLICY="Chinese-first with concise bilingual EN/JP support where useful."
ACADEMIC_RSS_SOURCES=(
  "Nature:https://www.nature.com/nature.rss"
  "Cell:https://www.cell.com/cell/rss"
  "Science:https://www.science.org/action/showFeed?type=site&jc=science"
  "Nature news feed:https://www.nature.com/nature/articles?type=news"
)

usage() {
  cat <<'USAGE'
Usage: run_lightmind_pipeline.sh [options]

Runs the Lightmind chain:
  confidential+web context -> market research -> optional high-impact academic research ->
  milestone plan draft -> entrepreneurship mentor -> save notes under AutoLife ->
  compose/send HTML email

Options:
  --to <email>              Email recipient (repeatable; default has 3 recipients)
  --from <email>            Sender hint for Apple Mail (default: lachlan.miao.chen@gmail.com)
  --no-send-email           Build email draft only, do not send
  --send-email              Send email (default)
  --model <name>            Codex model (default: gpt-5.1-codex-mini)
  --reasoning <level>       Reasoning level (default: medium)
  --market-context <path>   Optional extra context file for market step
  --confidential-root <p>   Lightmind confidential root path override
  --resource-root <path>    Add resource root (repeatable; default: Lightmind resources)
  --resource-output-dir <p> Resource analysis markdown output directory
  --resource-label <name>   Resource analysis marker/label
  --skip-resource-analysis   Skip upfront resource analysis stage
  --academic-research        Enable high-impact academic research stage (default: on)
  --no-academic-research     Disable high-impact academic research stage
  --academic-max-results <n> Max results per arXiv query (default: 5)
  --academic-query <text>    Add/override an academic query (repeatable)
  -h, --help                Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --to)
      shift
      if [[ "$CUSTOM_TO" == "0" ]]; then
        TO_ADDRS=()
        CUSTOM_TO=1
      fi
      TO_ADDRS+=("${1:-}")
      ;;
    --from)
      shift
      FROM_ADDR="${1:-}"
      ;;
    --no-send-email)
      SEND_EMAIL=0
      ;;
    --send-email)
      SEND_EMAIL=1
      ;;
    --model)
      shift
      MODEL="${1:-}"
      ;;
    --reasoning)
      shift
      REASONING="${1:-}"
      ;;
    --market-context)
      shift
      MARKET_CONTEXT_FILE="${1:-}"
      ;;
    --confidential-root)
      shift
      CONFIDENTIAL_ROOT="${1:-}"
      if [[ "${#RESOURCE_ROOTS[@]}" -gt 0 ]]; then
        RESOURCE_ROOTS[0]="$CONFIDENTIAL_ROOT"
      else
        RESOURCE_ROOTS+=("$CONFIDENTIAL_ROOT")
      fi
      ;;
    --resource-root)
      shift
      RESOURCE_ROOTS+=("${1:-}")
      ;;
    --resource-output-dir)
      shift
      RESOURCE_OUTPUT_DIR="${1:-}"
      ;;
    --resource-label)
      shift
      RESOURCE_LABEL="${1:-}"
      ;;
    --skip-resource-analysis)
      RUN_RESOURCE_ANALYSIS=0
      ;;
    --academic-research)
      ACADEMIC_RESEARCH=1
      ;;
    --no-academic-research)
      ACADEMIC_RESEARCH=0
      ;;
    --academic-max-results)
      shift
      ACADEMIC_MAX_RESULTS="${1:-5}"
      ;;
    --academic-query)
      shift
      ACADEMIC_QUERIES+=("${1:-}")
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if [[ "${#TO_ADDRS[@]}" -eq 0 ]]; then
  echo "At least one recipient is required." >&2
  exit 1
fi

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/Library/pnpm:$PATH"
cd "$REPO_DIR"

RUN_ID="$(TZ=Asia/Hong_Kong date '+%Y%m%d-%H%M%S')"
ARTIFACT_DIR="$ARTIFACT_BASE/$RUN_ID"
mkdir -p "$ARTIFACT_DIR" "$NOTES_ROOT"
LOG_FILE="$ARTIFACT_DIR/pipeline.log"

log() {
  printf '[%s] %s\n' "$(TZ=Asia/Hong_Kong date '+%Y-%m-%d %H:%M:%S %Z')" "$1" | tee -a "$LOG_FILE"
}

acquire_pipeline_lock() {
  mkdir -p "$ARTIFACT_BASE"
  if [[ -f "$PIPELINE_LOCK_FILE" ]]; then
    local lock_content
    local lock_pid
    local lock_ts
    lock_content="$(cat "$PIPELINE_LOCK_FILE")"
    lock_pid="${lock_content%%|*}"
    lock_ts="${lock_content##*|}"
    if [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" >/dev/null 2>&1; then
      log "Another Lightmind pipeline run is active (pid=$lock_pid, started=$lock_ts). Exiting."
      exit 0
    fi
    rm -f "$PIPELINE_LOCK_FILE"
  fi

  local lock_epoch
  lock_epoch="$(TZ=Asia/Hong_Kong date '+%Y%m%d-%H%M%S')"
  printf '%s|%s' "$$" "$lock_epoch" > "$PIPELINE_LOCK_FILE"
  chmod 600 "$PIPELINE_LOCK_FILE"
}

release_pipeline_lock() {
  if [[ ! -f "$PIPELINE_LOCK_FILE" ]]; then
    return 0
  fi
  local lock_content
  local lock_pid
  lock_content="$(cat "$PIPELINE_LOCK_FILE")"
  lock_pid="${lock_content%%|*}"
  if [[ "$lock_pid" == "$$" ]]; then
    rm -f "$PIPELINE_LOCK_FILE"
  fi
}

trap release_pipeline_lock EXIT INT TERM

extract_note_html() {
  local result_json="$1"
  local output_html="$2"
  python3 - "$result_json" "$output_html" <<'PY'
import json
import sys
from pathlib import Path

result_path = Path(sys.argv[1])
out_path = Path(sys.argv[2])
result = json.loads(result_path.read_text(encoding="utf-8"))
notes = result.get("notes") or []
html = ""
if notes and isinstance(notes, list):
    first = notes[0]
    if isinstance(first, dict):
        html = first.get("html_body", "") or ""
out_path.write_text(html, encoding="utf-8")
PY
}

extract_summary() {
  local result_json="$1"
  local output_txt="$2"
  python3 - "$result_json" "$output_txt" <<'PY'
import json
import sys
from pathlib import Path

result = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
summary = result.get("summary", "")
Path(sys.argv[2]).write_text(summary.strip() + "\n", encoding="utf-8")
PY
}

find_latest_resource_markdown_dir() {
  local base_dir="$1"
  python3 - "$base_dir" <<'PY'
import sys
from pathlib import Path

base = Path(sys.argv[1]).expanduser()
if not base.is_dir():
  raise SystemExit(0)

dirs = [p for p in base.iterdir() if p.is_dir()]
if not dirs:
  raise SystemExit(0)

dirs.sort(key=lambda p: p.stat().st_mtime, reverse=True)
print(dirs[0].as_posix())
PY
}

append_resource_summary() {
  local result_json="$1"
  local output_file="$2"
  if [[ -z "${result_json}" || ! -e "$result_json" ]]; then
    echo "Resource analysis result unavailable." > "$output_file"
    return 0
  fi

  if [[ -f "$result_json" ]]; then
    python3 - "$result_json" "$output_file" <<'PY'
import json
import sys
from pathlib import Path

result_path = Path(sys.argv[1])
out = Path(sys.argv[2])
try:
    data = json.loads(result_path.read_text(encoding="utf-8"))
except Exception:
    out.write_text("Resource analysis result unavailable.\n", encoding="utf-8")
    raise SystemExit(0)

summary = (data.get("summary") or "").strip()
if not summary:
    summary = "Resource analysis completed without a summary."
lines = [
    "Resource analysis summary:",
    summary,
    "",
]
for rec in data.get("resource_recommendations", [])[:12]:
    lines.append(f"- {rec}")
out.write_text("\n".join(lines), encoding="utf-8")
PY
    return 0
  fi

  if [[ -d "$result_json" ]]; then
    python3 - "$result_json" "$output_file" <<'PY'
from pathlib import Path
import sys

md_root = Path(sys.argv[1])
out = Path(sys.argv[2])

md_files = sorted(md_root.glob("*.md"))
if not md_files:
  out.write_text("Resource analysis result unavailable.\n", encoding="utf-8")
  raise SystemExit(0)

def _pick(patterns):
  for pattern in patterns:
    matches = sorted(md_root.glob(pattern))
    if matches:
      return matches[0]
  return None

summary_file = _pick(["*summary*.md", "*Summary*.md"])
if summary_file is None:
  summary_file = md_files[0]

lines = [
  "Resource analysis summary:",
  f"Loaded from markdown folder: {md_root}",
]
try:
  summary_text = summary_file.read_text(encoding="utf-8").strip()
except Exception:
  summary_text = ""
if summary_text:
  lines.append(summary_text)

recommendation_file = _pick(["*recommendations*.md", "*Recommendation*.md"])
if recommendation_file is not None:
  lines.append("")
  lines.append("Resource recommendations:")
  try:
    for row in recommendation_file.read_text(encoding="utf-8").splitlines():
      if row.strip():
        lines.append(f"- {row.strip()}")
  except Exception:
    pass

out.write_text("\\n".join(lines).strip() + "\\n", encoding="utf-8")
PY
    return 0
  fi

  echo "Resource analysis result unavailable." > "$output_file"
}

build_confidential_summary() {
  local root_path="$1"
  local out_path="$2"
  python3 - "$root_path" "$out_path" <<'PY'
import os
import sys
from datetime import datetime
from pathlib import Path

root = Path(sys.argv[1]).expanduser()
out = Path(sys.argv[2]).expanduser()
out.parent.mkdir(parents=True, exist_ok=True)

if not root.exists():
    out.write_text(f"[confidential] missing path: {root}\n", encoding="utf-8")
    raise SystemExit(0)

text_ext = {".md", ".txt", ".csv", ".json", ".html", ".htm", ".yaml", ".yml"}
files = []
for base, _, names in os.walk(root):
    for name in names:
        p = Path(base) / name
        try:
            st = p.stat()
        except OSError:
            continue
        files.append((p, st.st_size, st.st_mtime))

files.sort(key=lambda x: x[2], reverse=True)
total_size = sum(x[1] for x in files)

lines = []
lines.append(f"[confidential] root={root}")
lines.append(f"[confidential] file_count={len(files)} total_bytes={total_size}")
lines.append("")
lines.append("[confidential] most recent files:")
for p, size, mtime in files[:40]:
    ts = datetime.fromtimestamp(mtime).isoformat(timespec="seconds")
    rel = p.relative_to(root)
    lines.append(f"- {rel} | {size} bytes | {ts}")

lines.append("")
lines.append("[confidential] text excerpts:")
excerpt_chars = 0
excerpt_budget = 30000
for p, _, _ in files:
    if p.suffix.lower() not in text_ext:
        continue
    if excerpt_chars >= excerpt_budget:
        break
    try:
        text = p.read_text(encoding="utf-8", errors="ignore").strip()
    except OSError:
        continue
    if not text:
        continue
    snippet = text[:1500]
    excerpt_chars += len(snippet)
    rel = p.relative_to(root)
    lines.append(f"## {rel}")
    lines.append(snippet)
    lines.append("")

out.write_text("\n".join(lines).strip() + "\n", encoding="utf-8")
PY
}

build_website_snapshot() {
  local site_url="$1"
  local out_path="$2"
  python3 - "$site_url" "$out_path" <<'PY'
import re
import sys
import urllib.request
from html import unescape
from pathlib import Path

url = sys.argv[1]
out = Path(sys.argv[2])
out.parent.mkdir(parents=True, exist_ok=True)

try:
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=20) as resp:
        raw = resp.read()
    html_text = raw.decode("utf-8", errors="ignore")
except Exception as exc:  # noqa: BLE001
    out.write_text(f"[website] fetch_failed url={url} err={exc}\n", encoding="utf-8")
    raise SystemExit(0)

title_match = re.search(r"<title[^>]*>(.*?)</title>", html_text, flags=re.IGNORECASE | re.DOTALL)
title = unescape(title_match.group(1).strip()) if title_match else ""
text = re.sub(r"(?is)<script.*?>.*?</script>", " ", html_text)
text = re.sub(r"(?is)<style.*?>.*?</style>", " ", text)
text = re.sub(r"(?is)<[^>]+>", " ", text)
text = unescape(text)
text = re.sub(r"\s+", " ", text).strip()
snapshot = text[:12000]

lines = [f"[website] url={url}"]
if title:
    lines.append(f"[website] title={title}")
lines.append("[website] text_snapshot:")
lines.append(snapshot)
out.write_text("\n".join(lines).strip() + "\n", encoding="utf-8")
PY
}

build_academic_context() {
  local out_path="$1"
  local queries_json="$2"
  local max_results="$3"
  shift 3

  python3 - "$out_path" "$max_results" "$queries_json" "$@" <<'PY'
import json
import re
import sys
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime
from html import unescape
from pathlib import Path

out = Path(sys.argv[1])
max_results = int(sys.argv[2]) if sys.argv[2].strip() else 5
queries = json.loads(sys.argv[3]) if len(sys.argv) > 3 else []
high_impact_sources = [s for s in sys.argv[4:] if s.strip()]

def fetch_arxiv(query):
    encoded = urllib.parse.quote_plus(query)
    url = f"https://export.arxiv.org/api/query?search_query=all:{encoded}&start=0&max_results={max_results}&sortBy=submittedDate&sortOrder=descending"
    req = urllib.request.Request(url, headers={"User-Agent": "OpenClawLightmindPipeline/1.0"})
    with urllib.request.urlopen(req, timeout=20) as resp:
        raw = resp.read()
    root = ET.fromstring(raw)
    ns = "{http://www.w3.org/2005/Atom}"
    entries = []
    for entry in root.findall(f"{ns}entry"):
        title = (entry.findtext(f"{ns}title") or "").replace("\n", " ").strip()
        summary = (entry.findtext(f"{ns}summary") or "").replace("\n", " ").strip()
        summary = unescape(summary)
        updated = (entry.findtext(f"{ns}updated") or "").strip()
        link = (entry.findtext(f"{ns}id") or "").strip()
        authors = []
        for author in entry.findall(f"{ns}author"):
            name = (author.findtext(f"{ns}name") or "").strip()
            if name:
                authors.append(name)
        entries.append({
            "query": query,
            "title": title,
            "summary": summary,
            "updated": updated,
            "link": link,
            "authors": authors[:4],
            "raw_published": updated,
            "published": _normalize_iso(updated),
        })
    return entries


def _normalize_atom_url(text):
    if not text:
        return ""
    return text.strip()


def _load_rss_entries(source_name, source_url):
    try:
        req = urllib.request.Request(source_url, headers={"User-Agent": "OpenClawLightmindPipeline/1.0"})
        with urllib.request.urlopen(req, timeout=20) as resp:
            raw = resp.read()
        root = ET.fromstring(raw)
    except Exception as exc:  # noqa: BLE001
        lines.append("")
        lines.append(f"[academic] rss_fetch_failed source={source_name} error={exc}")
        return []

    items = root.findall(".//item")
    if not items:
        items = root.findall(".//entry")

    out = []
    for item in items[:max_results]:
        title = (item.findtext("title") or "").replace("\n", " ").strip()
        summary = (item.findtext("description") or item.findtext("summary") or "").replace("\n", " ").strip()
        link = ""
        link_node = item.find("link")
        if link_node is not None and (link_node.text or "").strip():
            link = (link_node.text or "").strip()
        if not link:
            link = _normalize_atom_url(item.findtext("{http://www.w3.org/2005/Atom}link") or "")
        if not link:
            alt = item.find("{http://www.w3.org/2005/Atom}id")
            if alt is not None:
                link = (alt.text or "").strip()
        published = (item.findtext("pubDate") or item.findtext("published") or item.findtext("updated") or "").strip()
        if not published:
            published = datetime.now().astimezone().isoformat(timespec="seconds")

        authors = []
        for author in item.findall("author"):
            name = (author.text or "").strip()
            if name:
                authors.append(name)
        out.append({
            "query": source_name,
            "title": unescape(title),
            "summary": unescape(summary),
            "updated": published,
            "link": link,
            "authors": authors[:4],
            "raw_published": published,
            "published": _normalize_iso(published),
        })

    return out


def _normalize_iso(value: str) -> str:
    value = value.strip()
    if not value:
        return ""
    match = re.match(r"^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})", value)
    return match.group(1) if match else value


parsed_sources = []
for item in high_impact_sources:
    source_name, sep, source_url = item.partition(":")
    if sep:
        parsed_sources.append((source_name.strip(), source_url.strip()))
    elif item.strip():
        parsed_sources.append((item.strip(), item.strip()))

lines = [f"[academic] mode=high_impact_research"]
lines.append(f"[academic] sources={', '.join(name for name, _ in parsed_sources)}")
lines.append(f"[academic] max_results_per_query={max_results}")
lines.append(f"[academic] run_time={datetime.now().astimezone().strftime('%Y-%m-%d %H:%M:%S %Z')}")

if not queries:
    queries = ["AI productivity systems", "AI enterprise operations"]

seen = set()
all_entries = []
for query in queries:
    query = query.strip()
    if not query:
        continue
    try:
        entries = fetch_arxiv(query)
    except Exception as exc:  # noqa: BLE001
        lines.append("")
        lines.append(f"[academic] query_failed={query}")
        lines.append(f"[academic] error={exc}")
        continue
    for item in entries:
        if not item["title"]:
            continue
        key = item["link"] or item["title"].lower()
        if key in seen:
            continue
        seen.add(key)
        all_entries.append(item)

for source_name, source_url in parsed_sources:
    entries = _load_rss_entries(source_name, source_url)
    for item in entries:
        if not item["title"]:
            continue
        key = item["link"] or item["title"].lower()
        if key in seen:
            continue
        seen.add(key)
        all_entries.append(item)

if not all_entries:
    lines.append("")
    lines.append("[academic] no entries found")
else:
    lines.append("")
    for item in all_entries:
        head = f"{item['published']} | {item['query']} | {item['title']}"
        lines.append(f"- {head}")
        if item["authors"]:
            lines.append(f"  authors: {', '.join(item['authors'])}")
        if item["summary"]:
            lines.append(f"  summary: {item['summary'][:360]}")
        if item["link"]:
            lines.append(f"  link: {item['link']}")
        lines.append("")

out.write_text("\n".join(lines).strip() + "\n", encoding="utf-8")
PY
}

merge_market_and_academic_summaries() {
  local market_summary="$1"
  local academic_summary="$2"
  local out_file="$3"
  if [[ -n "$academic_summary" && -f "$academic_summary" ]]; then
    {
      echo "Market summary:"
      cat "$market_summary"
      echo
      echo "Academic research summary (high-impact):"
      cat "$academic_summary"
    } > "$out_file"
  else
    cat "$market_summary" > "$out_file"
  fi
}

log "Pipeline start run_id=$RUN_ID model=$MODEL reasoning=$REASONING"
log "Pipeline config: resource_analysis=$RUN_RESOURCE_ANALYSIS roots=${#RESOURCE_ROOTS[@]}"

acquire_pipeline_lock

CONFIDENTIAL_SUMMARY="$ARTIFACT_DIR/confidential_context_summary.txt"
build_confidential_summary "$CONFIDENTIAL_ROOT" "$CONFIDENTIAL_SUMMARY"
WEBSITE_SNAPSHOT="$ARTIFACT_DIR/lightmind_website_snapshot.txt"
build_website_snapshot "https://lightmind.art" "$WEBSITE_SNAPSHOT"
RESOURCE_ANALYSIS_RUN_DIR="$ARTIFACT_DIR/resource_analysis"
RESOURCE_ANALYSIS_RESULT=""
RESOURCE_ANALYSIS_MARKDOWN_DIR="$RESOURCE_OUTPUT_DIR/$RUN_ID"
HAS_RESOURCE_CACHE=0
if [[ "$RUN_RESOURCE_ANALYSIS" == "1" ]]; then
  mkdir -p "$RESOURCE_ANALYSIS_RUN_DIR" "$RESOURCE_OUTPUT_DIR" "$RESOURCE_ANALYSIS_MARKDOWN_DIR"
  RESOURCE_ANALYSIS_ARGS=()
  for root in "${RESOURCE_ROOTS[@]}"; do
    RESOURCE_ANALYSIS_ARGS+=(--resource-root "$root")
  done
  log "Resource analysis starting"
  set +e
  "$PROMPT_DIR/prompt_resource_analysis.sh" \
    --company "Lightmind" \
    --output-dir "$RESOURCE_ANALYSIS_RUN_DIR" \
    --markdown-output "$RESOURCE_ANALYSIS_MARKDOWN_DIR" \
    --label "$RESOURCE_LABEL" \
    --model "$MODEL" \
    --reasoning "$REASONING" \
    --max-manifest-files 500 \
    --max-text-snippets 40000 \
    --prompt-file "$PROMPT_DIR/resource_analysis_prompt.md" \
    --schema-file "$PROMPT_DIR/resource_analysis_schema.json" \
    "${RESOURCE_ANALYSIS_ARGS[@]}" \
    > "$ARTIFACT_DIR/resource_analysis.log" 2>&1
  RC=$?
  set -e
  if [[ "$RC" -ne 0 ]]; then
    log "Resource analysis codex command failed with rc=$RC; continuing with available artifacts."
  fi

  latest_ra="$(ls -1 "$RESOURCE_ANALYSIS_RUN_DIR/${RESOURCE_LABEL}"-* 2>/dev/null | head -n 1 || true)"
  if [[ -n "$latest_ra" ]]; then
    RESOURCE_ANALYSIS_RESULT="$latest_ra/latest-result.json"
  fi
  HAS_RESOURCE_CACHE=1
else
  RESOURCE_ANALYSIS_MARKDOWN_DIR="$(find_latest_resource_markdown_dir "$RESOURCE_OUTPUT_DIR" || true)"
  if [[ -n "$RESOURCE_ANALYSIS_MARKDOWN_DIR" ]]; then
    log "Resource analysis using latest cached markdown"
    HAS_RESOURCE_CACHE=1
  else
    log "Resource analysis skipped (no cache available)"
  fi
fi

CONTEXT_FILE="$ARTIFACT_DIR/market_context.txt"
RESOURCE_APPEND_PATH="$ARTIFACT_DIR/resource_analysis.txt"
: > "$RESOURCE_APPEND_PATH"
if [[ "$RUN_RESOURCE_ANALYSIS" == "1" ]]; then
  append_resource_summary "$RESOURCE_ANALYSIS_RESULT" "$RESOURCE_APPEND_PATH"
else
  append_resource_summary "$RESOURCE_ANALYSIS_MARKDOWN_DIR" "$RESOURCE_APPEND_PATH"
fi
{
  echo "Run time: $(TZ=Asia/Hong_Kong date '+%Y-%m-%d %H:%M:%S %Z')"
  echo "Primary brand: Lightmind"
  echo "Must inspect https://lightmind.art and confidential context below."
  echo "Reference input folder: $LIGHTMIND_INPUT_ROOT"
  echo "Reference output folder: $LIGHTMIND_OUTPUT_ROOT"
  echo "Pipeline uses both input and output references for long-term company context."
  echo "Reference input examples: $LIGHTMIND_INPUT_ROOT/PitchDemoTraning.md, etc."
  echo
  if [[ -n "$RESOURCE_ANALYSIS_RESULT" && -f "$RESOURCE_ANALYSIS_RESULT" ]]; then
    cat "$RESOURCE_APPEND_PATH"
    echo
    echo "Resource analysis markdown outputs:"
    find "$RESOURCE_ANALYSIS_MARKDOWN_DIR" -maxdepth 1 -type f -print
  elif [[ -n "$RESOURCE_ANALYSIS_MARKDOWN_DIR" && -d "$RESOURCE_ANALYSIS_MARKDOWN_DIR" ]]; then
    cat "$RESOURCE_APPEND_PATH"
    echo
    echo "Resource analysis markdown outputs:"
    find "$RESOURCE_ANALYSIS_MARKDOWN_DIR" -maxdepth 1 -type f -print
  fi
  echo "Output notes target: AutoLife / 🏢 Companies / 👓 Lightmind.art"
  echo "Output language preference: Chinese-first with mixed EN/日文 label support."
  echo
  echo "Website snapshot:"
  cat "$WEBSITE_SNAPSHOT"
  echo
  echo "Confidential context summary:"
  cat "$CONFIDENTIAL_SUMMARY"
  if [[ -n "$MARKET_CONTEXT_FILE" && -f "$MARKET_CONTEXT_FILE" ]]; then
    echo
    echo "User extra context:"
    cat "$MARKET_CONTEXT_FILE"
  fi
} > "$CONTEXT_FILE"

TOTAL_STEPS=7
if [[ "$HAS_RESOURCE_CACHE" == "1" ]]; then
  TOTAL_STEPS=$((TOTAL_STEPS + 1))
fi
if [[ "$ACADEMIC_RESEARCH" == "1" ]]; then
  TOTAL_STEPS=$((TOTAL_STEPS + 1))
fi

BASE_STEP=0
if [[ "$HAS_RESOURCE_CACHE" == "1" ]]; then
  BASE_STEP=1
  log "Step 0/$TOTAL_STEPS: analyze resources and create reference summary"
fi

MARKET_RESULT="$ARTIFACT_DIR/market.result.json"
ACADEMIC_RESULT="$ARTIFACT_DIR/academic.result.json"
FUNDING_RESULT="$ARTIFACT_DIR/funding.result.json"
PLAN_RESULT="$ARTIFACT_DIR/plan.result.json"
MENTOR_RESULT="$ARTIFACT_DIR/mentor.result.json"

MARKET_HTML="$ARTIFACT_DIR/market.html"
ACADEMIC_CONTEXT="$ARTIFACT_DIR/academic_context.txt"
ACADEMIC_HTML="$ARTIFACT_DIR/academic.html"
FUNDING_HTML="$ARTIFACT_DIR/funding.html"
PLAN_HTML="$ARTIFACT_DIR/milestones.html"
MENTOR_HTML="$ARTIFACT_DIR/mentor.html"

MARKET_SUMMARY="$ARTIFACT_DIR/market.summary.txt"
ACADEMIC_SUMMARY="$ARTIFACT_DIR/academic.summary.txt"
FUNDING_SUMMARY="$ARTIFACT_DIR/funding.summary.txt"
PLAN_INPUT_SUMMARY="$ARTIFACT_DIR/plan_input_summary.txt"
PLAN_SUMMARY="$ARTIFACT_DIR/plan.summary.txt"
MENTOR_SUMMARY="$ARTIFACT_DIR/mentor.summary.txt"

CURRENT_MILESTONE_HTML="$ARTIFACT_DIR/current_milestones.html"
: > "$CURRENT_MILESTONE_HTML"

if [[ "$ACADEMIC_RESEARCH" == "1" ]]; then
  ACADEMIC_STEP=$((BASE_STEP + 3))
  FUNDING_STEP=$((BASE_STEP + 4))
  PLAN_STEP=$((BASE_STEP + 5))
  MENTOR_STEP=$((BASE_STEP + 6))
  LOG_STEP=$((BASE_STEP + 7))
  EMAIL_STEP=$((BASE_STEP + 8))
else
  FUNDING_STEP=$((BASE_STEP + 3))
  PLAN_STEP=$((BASE_STEP + 4))
  MENTOR_STEP=$((BASE_STEP + 5))
  LOG_STEP=$((BASE_STEP + 6))
  EMAIL_STEP=$((BASE_STEP + 7))
fi

log "Step $((BASE_STEP))/$TOTAL_STEPS: read current milestone note from AutoLife"
"$PROMPT_DIR/prompt_la_note_reader.sh" \
  --account "iCloud" \
  --root-folder "AutoLife" \
  --folder-path "🏢 Companies/👓 Lightmind.art" \
  --note "💡 Lightmind Milestones / 里程碑 / マイルストーン" \
  --out "$CURRENT_MILESTONE_HTML" || true

log "Step $((BASE_STEP + 2))/$TOTAL_STEPS: market research"
"$PROMPT_DIR/prompt_la_market.sh" \
  --context-file "$CONTEXT_FILE" \
  --company-focus "Lightmind" \
  --reference-source "https://lightmind.art" \
  --reference-source "LightMind_Confidential internal context" \
  --prompt-file "$PROMPT_DIR/lm_market_research_prompt.md" \
  --model "$MODEL" \
  --reasoning "$REASONING" \
  --safety "$SAFETY" \
  --approval "$APPROVAL" \
  --label "lm-market" \
  > "$MARKET_RESULT"

extract_note_html "$MARKET_RESULT" "$MARKET_HTML"
extract_summary "$MARKET_RESULT" "$MARKET_SUMMARY"
cp "$MARKET_RESULT" "$NOTES_ROOT/last_market_result.json"
cp "$MARKET_HTML" "$NOTES_ROOT/last_market.html"

"$PROMPT_DIR/prompt_la_note_save.sh" \
  --account "iCloud" \
  --root-folder "AutoLife" \
  --folder-path "🏢 Companies/👓 Lightmind.art" \
  --note "🧠 Lightmind Market Intel / 市場情報ログ" \
  --mode append \
  --html-file "$MARKET_HTML"

if [[ "$ACADEMIC_RESEARCH" == "1" ]]; then
  log "Step $ACADEMIC_STEP/$TOTAL_STEPS: academic research (high-impact)"
fi
if [[ "$ACADEMIC_RESEARCH" == "1" ]]; then
  ACADEMIC_QUERIES_JSON="$(python3 - <<'PY' "${ACADEMIC_QUERIES[@]}"
import json
import sys
print(json.dumps([q for q in sys.argv[1:] if q.strip()], ensure_ascii=False))
PY
)"
  build_academic_context "$ACADEMIC_CONTEXT" "$ACADEMIC_QUERIES_JSON" "$ACADEMIC_MAX_RESULTS" "${ACADEMIC_RSS_SOURCES[@]}"

  "$PROMPT_DIR/prompt_la_market.sh" \
    --context-file "$ACADEMIC_CONTEXT" \
    --company-focus "Lightmind" \
    --reference-source "https://arxiv.org" \
    --reference-source "Nature" \
    --reference-source "Science" \
    --reference-source "Cell" \
    --reference-source "ICML, ICLR, NeurIPS, CVPR, SIGGRAPH" \
    --prompt-file "$PROMPT_DIR/lm_academic_research_prompt.md" \
    --model "$MODEL" \
    --reasoning "$REASONING" \
    --safety "$SAFETY" \
    --approval "$APPROVAL" \
    --label "lm-academic" \
    > "$ACADEMIC_RESULT"

  extract_note_html "$ACADEMIC_RESULT" "$ACADEMIC_HTML"
  extract_summary "$ACADEMIC_RESULT" "$ACADEMIC_SUMMARY"
  cp "$ACADEMIC_RESULT" "$NOTES_ROOT/last_academic_result.json"
  cp "$ACADEMIC_HTML" "$NOTES_ROOT/last_academic.html"

  "$PROMPT_DIR/prompt_la_note_save.sh" \
    --account "iCloud" \
    --root-folder "AutoLife" \
    --folder-path "🏢 Companies/👓 Lightmind.art" \
    --note "📚 Lightmind Academic Research / 论文追踪 / 論文追蹤" \
    --mode append \
    --html-file "$ACADEMIC_HTML"
else
  printf '%s\n' "Academic research disabled for this run." > "$ACADEMIC_SUMMARY"
  printf '%s\n' "<p>Academic research stage skipped for this run.</p>" > "$ACADEMIC_HTML"
fi

merge_market_and_academic_summaries "$MARKET_SUMMARY" "$ACADEMIC_SUMMARY" "$PLAN_INPUT_SUMMARY"

log "Step $FUNDING_STEP/$TOTAL_STEPS: funding and VC opportunities"
"$PROMPT_DIR/prompt_funding_vc.sh" \
  --context-file "$CONTEXT_FILE" \
  --market-summary-file "$PLAN_INPUT_SUMMARY" \
  --resource-summary-file "$RESOURCE_APPEND_PATH" \
  --company-focus "Lightmind" \
  --language-policy "$FUNDING_LANGUAGE_POLICY" \
  --reference-source "https://lightmind.art" \
  --reference-source "https://github.com/lachlanchen?tab=repositories" \
  --reference-source "Hong Kong startup competitions, VC and grant opportunities" \
  --reference-source "High impact research and commercialization signals" \
  --model "$MODEL" \
  --reasoning "$REASONING" \
  --safety "$SAFETY" \
  --approval "$APPROVAL" \
  --label "lm-funding" \
  > "$FUNDING_RESULT"

extract_note_html "$FUNDING_RESULT" "$FUNDING_HTML"
extract_summary "$FUNDING_RESULT" "$FUNDING_SUMMARY"
cp "$FUNDING_RESULT" "$NOTES_ROOT/last_funding_result.json"
cp "$FUNDING_HTML" "$NOTES_ROOT/last_funding.html"

"$PROMPT_DIR/prompt_la_note_save.sh" \
  --account "iCloud" \
  --root-folder "AutoLife" \
  --folder-path "🏢 Companies/👓 Lightmind.art" \
  --note "🏦 Lightmind Funding & VC Opportunities / 融资与VC机会 / 融資與VC機會" \
  --mode append \
  --html-file "$FUNDING_HTML"

log "Step $PLAN_STEP/$TOTAL_STEPS: milestone plan draft"
"$PROMPT_DIR/prompt_la_plan.sh" \
  --note-html "$CURRENT_MILESTONE_HTML" \
  --market-summary-file "$MARKET_SUMMARY" \
  --academic-summary-file "$PLAN_INPUT_SUMMARY" \
  --funding-summary-file "$FUNDING_SUMMARY" \
  --company-focus "Lightmind" \
  --reference-source "https://lightmind.art" \
  --prompt-file "$PROMPT_DIR/lm_plan_draft_prompt.md" \
  --model "$MODEL" \
  --reasoning "$REASONING" \
  --safety "$SAFETY" \
  --approval "$APPROVAL" \
  --label "lm-plan" \
  > "$PLAN_RESULT"

extract_note_html "$PLAN_RESULT" "$PLAN_HTML"
extract_summary "$PLAN_RESULT" "$PLAN_SUMMARY"
cp "$PLAN_RESULT" "$NOTES_ROOT/last_plan_result.json"
cp "$PLAN_HTML" "$NOTES_ROOT/last_plan.html"

"$PROMPT_DIR/prompt_la_note_save.sh" \
  --account "iCloud" \
  --root-folder "AutoLife" \
  --folder-path "🏢 Companies/👓 Lightmind.art" \
  --note "💡 Lightmind Milestones / 里程碑 / マイルストーン" \
  --mode replace \
  --html-file "$PLAN_HTML"

log "Step $MENTOR_STEP/$TOTAL_STEPS: entrepreneurship mentor"
"$PROMPT_DIR/prompt_entrepreneurship_mentor.sh" \
  --market-summary-file "$PLAN_INPUT_SUMMARY" \
  --plan-summary-file "$PLAN_SUMMARY" \
  --academic-summary-file "$PLAN_INPUT_SUMMARY" \
  --funding-summary-file "$FUNDING_SUMMARY" \
  --milestone-html-file "$PLAN_HTML" \
  --company-focus "Lightmind" \
  --reference-source "https://lightmind.art" \
  --prompt-file "$PROMPT_DIR/lm_entrepreneurship_mentor_prompt.md" \
  --model "$MODEL" \
  --reasoning "$REASONING" \
  --safety "$SAFETY" \
  --approval "$APPROVAL" \
  --label "lm-mentor" \
  > "$MENTOR_RESULT"

extract_note_html "$MENTOR_RESULT" "$MENTOR_HTML"
extract_summary "$MENTOR_RESULT" "$MENTOR_SUMMARY"
cp "$MENTOR_RESULT" "$NOTES_ROOT/last_mentor_result.json"
cp "$MENTOR_HTML" "$NOTES_ROOT/last_mentor.html"

"$PROMPT_DIR/prompt_la_note_save.sh" \
  --account "iCloud" \
  --root-folder "AutoLife" \
  --folder-path "🏢 Companies/👓 Lightmind.art" \
  --note "🧭 Lightmind Entrepreneurship Mentor / 創業メンター / 創業導航" \
  --mode append \
  --html-file "$MENTOR_HTML"

EMAIL_HTML="$ARTIFACT_DIR/email_digest.html"
python3 - "$MARKET_HTML" "$FUNDING_HTML" "$PLAN_HTML" "$MENTOR_HTML" "$ACADEMIC_HTML" "$PLAN_INPUT_SUMMARY" "$EMAIL_HTML" <<'PY'
import html
import sys
from datetime import datetime
from pathlib import Path

market = Path(sys.argv[1]).read_text(encoding="utf-8")
funding = Path(sys.argv[2]).read_text(encoding="utf-8")
plan = Path(sys.argv[3]).read_text(encoding="utf-8")
mentor = Path(sys.argv[4]).read_text(encoding="utf-8")
academic = Path(sys.argv[5]).read_text(encoding="utf-8")
plan_input = Path(sys.argv[6]).read_text(encoding="utf-8").strip()
out = Path(sys.argv[7])

run_ts = datetime.now().astimezone().strftime("%Y-%m-%d %H:%M %Z")
digest = (
    f"<h1>👓 Lightmind Daily Intelligence Digest</h1>"
    f"<p><strong>Generated:</strong> {html.escape(run_ts)}</p>"
    "<hr/>"
    f"<h2>🧠 Market Research / 市场 / 市場</h2>{market}"
    "<hr/>"
    f"<h2>🏦 Funding & VC Opportunities / 融资与VC机会 / 融資與VC機會</h2>{funding}"
    "<hr/>"
    f"<h2>📚 High-Impact Academic Research / 高质量论文追踪 / 高影響論文追跡</h2>{academic}"
    "<hr/>"
    f"<h2>🧭 Executive Note / 运营要点 / 運營要點</h2><p>{html.escape(plan_input)}</p>"
    "<hr/>"
    f"<h2>💡 Milestones / 里程碑 / マイルストーン</h2>{plan}"
    "<hr/>"
    f"<h2>🧭 Entrepreneurship Mentor / 创业导师 / 創業メンター</h2>{mentor}"
)
out.write_text(digest, encoding="utf-8")
PY

log "Step $LOG_STEP/$TOTAL_STEPS: save daily pipeline log note"
LOG_HTML="$ARTIFACT_DIR/pipeline_log_note.html"
python3 - "$RUN_ID" "$MARKET_SUMMARY" "$PLAN_SUMMARY" "$MENTOR_SUMMARY" "$ACADEMIC_SUMMARY" "$LOG_HTML" <<'PY'
import html
import sys
from pathlib import Path

run_id = sys.argv[1]
market = Path(sys.argv[2]).read_text(encoding="utf-8").strip()
plan = Path(sys.argv[3]).read_text(encoding="utf-8").strip()
mentor = Path(sys.argv[4]).read_text(encoding="utf-8").strip()
academic = Path(sys.argv[5]).read_text(encoding="utf-8").strip()
out = Path(sys.argv[6])

content = (
    f"<h3>📌 Lightmind Pipeline Run / 运行 / 実行: {html.escape(run_id)}</h3>"
    "<ul>"
    f"<li><strong>🧠 Market</strong>: {html.escape(market)}</li>"
    f"<li><strong>💡 Plan</strong>: {html.escape(plan)}</li>"
    f"<li><strong>🧭 Mentor</strong>: {html.escape(mentor)}</li>"
    f"<li><strong>📚 Academic</strong>: {html.escape(academic)}</li>"
    "</ul>"
)
out.write_text(content, encoding="utf-8")
PY

"$PROMPT_DIR/prompt_la_note_save.sh" \
  --account "iCloud" \
  --root-folder "AutoLife" \
  --folder-path "🏢 Companies/👓 Lightmind.art" \
  --note "🪵 Lightmind Pipeline Log / ログ / 日誌" \
  --mode append \
  --html-file "$LOG_HTML"

log "Step $EMAIL_STEP/$TOTAL_STEPS: compose/send email digest"
EMAIL_INSTRUCTION="$ARTIFACT_DIR/email_instruction.txt"
cat > "$EMAIL_INSTRUCTION" <<EOF
Create a beautiful HTML email update for Lightmind.

Requirements:
- Use the provided digest HTML as the core content.
- Keep sections structured and readable in Apple Mail.
- Use Chinese-first copy with concise English/Japanese labels where useful.
- Subject must include: [AutoLife] Lightmind 08:00/20:00 Update
- Do not invent facts outside the provided digest.
- Keep company scope strict to Lightmind only.

Digest HTML:
$(cat "$EMAIL_HTML")
EOF

EMAIL_TO_ARGS=()
for addr in "${TO_ADDRS[@]}"; do
  EMAIL_TO_ARGS+=(--to "$addr")
done

EMAIL_LOG="$ARTIFACT_DIR/email.log"
if [[ "$SEND_EMAIL" == "1" ]]; then
  cat "$EMAIL_INSTRUCTION" | python3 "$PROMPT_DIR/codex-email-cli.py" \
    "${EMAIL_TO_ARGS[@]}" \
    --from "$FROM_ADDR" \
    --model "$MODEL" \
    --reasoning "$REASONING" \
    --safety "$SAFETY" \
    --approval "$APPROVAL" \
    --prompt-tools-dir "$PROMPT_DIR" \
    --skip-git-check \
    --send \
    >"$EMAIL_LOG" 2>&1
  log "Email sent to ${TO_ADDRS[*]}"
else
  cat "$EMAIL_INSTRUCTION" | python3 "$PROMPT_DIR/codex-email-cli.py" \
    "${EMAIL_TO_ARGS[@]}" \
    --from "$FROM_ADDR" \
    --model "$MODEL" \
    --reasoning "$REASONING" \
    --safety "$SAFETY" \
    --approval "$APPROVAL" \
    --prompt-tools-dir "$PROMPT_DIR" \
    --skip-git-check \
    >"$EMAIL_LOG" 2>&1
  log "Email draft generated (send disabled)"
fi

log "Pipeline completed. artifacts=$ARTIFACT_DIR"
echo "$ARTIFACT_DIR"
