#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

COMPANY_FOCUS="Lightmind"
CONTEXT_FILE=""
MARKET_SUMMARY_FILE=""
RESOURCE_SUMMARY_FILE=""
WEB_SUMMARY_FILE=""
MODEL="gpt-5.3-codex-spark"
REASONING="high"
SAFETY="${CODEX_SAFETY:-danger-full-access}"
APPROVAL="${CODEX_APPROVAL:-never}"
OUTPUT_DIR="/tmp/codex-legal-review"
LABEL="legal-dept"
PROMPT_FILE="orchestral/prompt_tools/company/legal_dept_prompt.md"
SCHEMA_FILE="orchestral/prompt_tools/company/la_ops_schema.json"
REFERENCE_SOURCES=(
  "https://www.gov.hk/"
  "https://www.gov.cn/"
  "https://www.beijing.gov.cn/"
)
CUSTOM_REFERENCE_SOURCES=0
DEFAULT_LEGAL_ROOT="/Users/lachlan/Documents/LazyingArtBotIO/LightMind/Input/Legal"
LEGAL_ROOTS=()
RUN_LEGAL_WEB_SEARCH=1
LEGAL_WEB_QUERY_BUDGET=5
LEGAL_WEB_TOP_RESULTS=3
LEGAL_WEB_SCROLL_STEPS=2
LEGAL_WEB_SCROLL_PAUSE=0.8
LEGAL_WEB_HOLD_SECONDS=8
LEGAL_WEB_QUERIES=()
LEGAL_WEB_QUERY_PLANNER_PROMPT="orchestral/prompt_tools/company/legal_web_search_query_planner_prompt.md"
LEGAL_WEB_QUERY_SCHEMA="orchestral/prompt_tools/websearch/web_search_query_planner_schema.json"

parse_web_query() {
  local raw="$1"
  local parsed_kind="auto"
  local parsed_query="$raw"
  local kind_normalized=""

  if [[ "$raw" == *:* ]]; then
    local kind_candidate="${raw%%:*}"
    local rest="${raw#*:}"
    kind_normalized="${kind_candidate:l}"
    case "$kind_normalized" in
      auto|general|news)
        parsed_kind="$kind_normalized"
        parsed_query="$rest"
        ;;
      google)
        parsed_kind="auto"
        parsed_query="$rest"
        ;;
      google-news)
        parsed_kind="news"
        parsed_query="$rest"
        ;;
      *)
        parsed_kind="auto"
        parsed_query="$raw"
        ;;
    esac
  fi

  parsed_query="$(printf '%s' "$parsed_query" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
  if [[ -z "$parsed_query" ]]; then
    parsed_query="$raw"
  fi
  printf '%s|%s\n' "$parsed_kind" "$parsed_query"
}

web_search_engine_from_kind() {
  local kind="$1"
  case "$kind" in
    news)
      echo "google-news"
      ;;
    auto|general)
      echo "google"
      ;;
    *)
      echo "google"
      ;;
  esac
}

slugify_query() {
  local raw="$1"
  local value
  value="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' | cut -c1-24)"
  if [[ -z "$value" ]]; then
    echo "query"
  else
    echo "$value"
  fi
}

build_default_legal_web_queries() {
  local planner_input="$OUTPUT_DIR/legal-web-planner-input.json"
  local planner_output_dir="$OUTPUT_DIR/legal_web_query_planner"
  local planner_result="$planner_output_dir/latest-result.json"
  mkdir -p "$planner_output_dir"

  python3 - "$planner_input" "$COMPANY_FOCUS" "$LEGAL_WEB_QUERY_BUDGET" "$CONTEXT_FILE" "$MARKET_SUMMARY_FILE" "$RESOURCE_SUMMARY_FILE" "$WEB_SUMMARY_FILE" "${REFERENCE_SOURCES[@]}" <<'PY'
import json
import sys
from pathlib import Path

out = Path(sys.argv[1]).expanduser()
company_focus = (sys.argv[2] or "").strip()
try:
    budget = int(sys.argv[3]) if str(sys.argv[3]).strip() else 5
except Exception:
    budget = 5
context_file = sys.argv[4]
market_file = sys.argv[5]
resource_file = sys.argv[6]
web_file = sys.argv[7]
references = [x for x in sys.argv[8:] if x.strip()]

def read_text(path: str, limit: int = 6000) -> str:
    p = Path(path).expanduser()
    if not path or not p.exists() or not p.is_file():
        return ""
    try:
        return p.read_text(encoding="utf-8", errors="ignore")[:limit]
    except Exception:
        return ""

source_text = "\n\n".join([
    read_text(context_file, 7000),
    read_text(market_file, 5000),
    read_text(resource_file, 5000),
    read_text(web_file, 5000),
]).strip()

if budget < 3:
    budget = 3
if budget > 8:
    budget = 8

payload = {
    "company_focus": company_focus or "target company",
    "search_kind": "web",
    "query_budget": budget,
    "reference_sources": references,
    "source_text": source_text,
    "context_file": context_file,
    "resource_context_hint": "Generate legal/compliance web+news discovery queries with funding/competition/entrepreneur context support.",
}
out.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY

  if [[ -f "$LEGAL_WEB_QUERY_PLANNER_PROMPT" && -f "$LEGAL_WEB_QUERY_SCHEMA" ]]; then
    if ! python3 orchestral/prompt_tools/runtime/codex-json-runner.py \
      --input-json "$planner_input" \
      --output-dir "$planner_output_dir" \
      --prompt-file "$LEGAL_WEB_QUERY_PLANNER_PROMPT" \
      --schema "$LEGAL_WEB_QUERY_SCHEMA" \
      --model "$MODEL" \
      --reasoning "$REASONING" \
      --safety "$SAFETY" \
      --approval "$APPROVAL" \
      --label "legal-web-query-planner" \
      --skip-git-check >/dev/null 2>&1; then
      true
    fi
  fi

  if [[ -f "$planner_result" ]]; then
    python3 - "$planner_result" "$LEGAL_WEB_QUERY_BUDGET" <<'PY'
import json
import re
import sys
from pathlib import Path

def simplify_query(text: str) -> str:
    text = re.sub(r"\s+", " ", text).strip().replace(":", " -")
    if not text:
        return ""
    out = []
    seen = set()
    for token in text.split():
        t = token.strip(" ,;|")
        if not t:
            continue
        key = t.lower()
        if key in seen:
            continue
        seen.add(key)
        out.append(t)
        if len(out) >= 9:
            break
    return " ".join(out).strip()

def parse_queries(payload_path: str, budget: int):
    try:
        payload = json.loads(Path(payload_path).read_text(encoding="utf-8"))
    except Exception:
        return []
    out = []
    seen = set()
    for row in payload.get("queries", []) if isinstance(payload, dict) else []:
        if isinstance(row, str):
            kind = "auto"
            query = row.strip()
        elif isinstance(row, dict):
            kind = str(row.get("kind", "auto")).strip().lower()
            query = str(row.get("query", "")).strip()
        else:
            continue
        if kind not in {"auto", "general", "news"}:
            kind = "auto"
        query = simplify_query(query)
        if not query:
            continue
        key = (kind, query.lower())
        if key in seen:
            continue
        seen.add(key)
        out.append((kind, query))
        if len(out) >= budget:
            break
    return out

queries = parse_queries(sys.argv[1], int(sys.argv[2]))
if not queries:
    queries = [
        ("news", "Hong Kong AI startup compliance and policy updates"),
        ("news", "China cross-border data compliance AI product"),
        ("general", "AI wearable privacy compliance checklist enterprise deployment"),
    ]

for kind, query in queries:
    if kind in {"auto", "general"}:
        print(query)
    else:
        print(f"{kind}:{query}")
PY
    rm -f "$planner_input"
    return 0
  fi

  rm -f "$planner_input"
  printf '%s\n' \
    "news:Hong Kong AI startup compliance and policy updates" \
    "news:China cross-border data compliance AI product" \
    "general:AI wearable privacy compliance checklist enterprise deployment"
}

run_legal_web_search_queries() {
  local output_dir="$1"
  local top_n="$2"
  local run_id="$3"
  shift 3
  local queries=("$@")
  local run_output_dir="$output_dir/legal_web_search"
  local summary_file="$output_dir/legal_web_search.summary.txt"
  mkdir -p "$run_output_dir"
  : > "$summary_file"

  local idx=1
  for raw_query in "${queries[@]}"; do
    local parse kind query query_slug query_run_id query_result_dir query_result_file query_log_file
    parse="$(parse_web_query "$raw_query")"
    kind="${parse%%|*}"
    query="${parse#*|}"
    query_slug="$(slugify_query "$query")"
    query_run_id="${run_id}-legal-web-${idx}-${query_slug}"
    query_result_dir="$run_output_dir/$query_run_id"
    query_log_file="$query_result_dir/search.log"
    mkdir -p "$query_result_dir"

    if ! "$REPO_DIR/orchestral/prompt_tools/websearch/prompt_web_search_immersive.sh" \
      --query "$query" \
      --engine "$(web_search_engine_from_kind "$kind")" \
      --results "$top_n" \
      --open-top-results "$top_n" \
      --summarize-open-url \
      --scroll-steps "$LEGAL_WEB_SCROLL_STEPS" \
      --scroll-pause "$LEGAL_WEB_SCROLL_PAUSE" \
      --keep-open \
      --hold-seconds "$LEGAL_WEB_HOLD_SECONDS" \
      --output-dir "$run_output_dir" \
      --run-id "$query_run_id" \
      > "$query_log_file" 2>&1; then
      printf '%s\n' "- [legal-web] ❌ $query ($kind): search failed" >> "$summary_file"
      idx=$((idx + 1))
      continue
    fi

    query_result_file=""
    for candidate in \
      "$query_result_dir"/query-*.json \
      "$query_result_dir"/search_batch_result.json; do
      if [[ -f "$candidate" ]]; then
        query_result_file="$candidate"
        break
      fi
    done

    if [[ -z "$query_result_file" ]]; then
      printf '%s\n' "- [legal-web] ⚠️ $query ($kind): result missing" >> "$summary_file"
      idx=$((idx + 1))
      continue
    fi

    python3 - "$summary_file" "$query" "$kind" "$query_result_file" <<'PY'
import json
import sys
from pathlib import Path

summary_path = Path(sys.argv[1]).expanduser()
query = sys.argv[2]
kind = sys.argv[3]
result_file = Path(sys.argv[4]).expanduser()

try:
    payload = json.loads(result_file.read_text(encoding="utf-8"))
except Exception as exc:
    with summary_path.open("a", encoding="utf-8") as w:
        w.write(f"- [legal-web] ⚠️ {query} ({kind}): parse failed ({exc})\n")
    raise SystemExit(0)

items = payload.get("items") if isinstance(payload, dict) else []
opened = payload.get("opened_items") if isinstance(payload, dict) else []
if not isinstance(items, list):
    items = []
if not isinstance(opened, list):
    opened = []

with summary_path.open("a", encoding="utf-8") as w:
    w.write(f"- [legal-web] ✅ {query} ({kind}): {len(items)} result(s)\n")
    for row in items[:3]:
        title = str(row.get("title", "")).strip()
        url = str(row.get("url", "")).strip()
        if title or url:
            w.write(f"  - {title} | {url}\n")
    for row in opened[:2]:
        title = str(row.get("title", "")).strip()
        url = str(row.get("url", "")).strip()
        summary = str(row.get("summary", "")).strip().replace("\n", " ")
        w.write(f"  - opened: {title} | {url}\n")
        if summary:
            w.write(f"    - summary: {summary[:320]}\n")
PY
    idx=$((idx + 1))
  done

  echo "$summary_file"
}

usage() {
  cat <<'USAGE'
Usage: prompt_legal_dept.sh [options]

Options:
  --company-focus <text>         Company label (default: Lightmind)
  --legal-root <path>            Legal materials root folder (repeatable)
  --context-file <path>          Context text file path
  --market-summary-file <path>    Market summary text file
  --resource-summary-file <path>  Resource analysis summary file
  --web-summary-file <path>      Web-search context summary file
  --legal-web-search             Run legal-stage targeted web search (default: on)
  --no-legal-web-search          Disable legal-stage targeted web search
  --legal-web-query <text>       Legal web search query (repeatable; planner used if omitted)
  --legal-web-query-budget <n>   Planner query budget (default: 5)
  --legal-web-top-results <n>    Open top N results per legal query (default: 3)
  --model <name>                 Codex model (default: gpt-5.3-codex-spark)
  --reasoning <level>            Reasoning level (default: high)
  --safety <mode>                Safety mode (default: danger-full-access)
  --approval <policy>            Approval mode (default: never)
  --output-dir <path>            Output artifact directory (default: /tmp/codex-legal-review)
  --label <name>                 Run label (default: legal-dept)
  --prompt-file <path>           Prompt file (default: orchestral/prompt_tools/company/legal_dept_prompt.md)
  --schema-file <path>           JSON schema (default: orchestral/prompt_tools/company/la_ops_schema.json)
  --reference-source <u>         Reference source URL/text (repeatable)
  -h, --help                    Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --company-focus)
      shift
      COMPANY_FOCUS="${1:-}"
      ;;
    --legal-root)
      shift
      LEGAL_ROOTS+=("${1:-}")
      ;;
    --context-file)
      shift
      CONTEXT_FILE="${1:-}"
      ;;
    --market-summary-file)
      shift
      MARKET_SUMMARY_FILE="${1:-}"
      ;;
    --resource-summary-file)
      shift
      RESOURCE_SUMMARY_FILE="${1:-}"
      ;;
    --web-summary-file)
      shift
      WEB_SUMMARY_FILE="${1:-}"
      ;;
    --legal-web-search)
      RUN_LEGAL_WEB_SEARCH=1
      ;;
    --no-legal-web-search)
      RUN_LEGAL_WEB_SEARCH=0
      ;;
    --legal-web-query)
      shift
      LEGAL_WEB_QUERIES+=("${1:-}")
      ;;
    --legal-web-query-budget)
      shift
      LEGAL_WEB_QUERY_BUDGET="${1:-5}"
      ;;
    --legal-web-top-results)
      shift
      LEGAL_WEB_TOP_RESULTS="${1:-3}"
      ;;
    --model)
      shift
      MODEL="${1:-}"
      ;;
    --reasoning)
      shift
      REASONING="${1:-}"
      ;;
    --safety)
      shift
      SAFETY="${1:-}"
      ;;
    --approval)
      shift
      APPROVAL="${1:-}"
      ;;
    --output-dir)
      shift
      OUTPUT_DIR="${1:-}"
      ;;
    --label)
      shift
      LABEL="${1:-}"
      ;;
    --prompt-file)
      shift
      PROMPT_FILE="${1:-}"
      ;;
    --schema-file)
      shift
      SCHEMA_FILE="${1:-}"
      ;;
    --reference-source)
      shift
      if [[ "$CUSTOM_REFERENCE_SOURCES" == "0" ]]; then
        REFERENCE_SOURCES=()
        CUSTOM_REFERENCE_SOURCES=1
      fi
      REFERENCE_SOURCES+=("${1:-}")
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

mkdir -p "$OUTPUT_DIR"

if [[ ${#LEGAL_ROOTS[@]} -eq 0 ]]; then
  LEGAL_ROOTS=("$DEFAULT_LEGAL_ROOT")
fi

if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "Prompt file not found: $PROMPT_FILE" >&2
  exit 1
fi

if [[ ! -f "$SCHEMA_FILE" ]]; then
  echo "Schema file not found: $SCHEMA_FILE" >&2
  exit 1
fi

dedupe_legal_roots=()
for root_item in "${LEGAL_ROOTS[@]}"; do
  if [[ -z "${root_item// /}" ]]; then
    continue
  fi
  # shellcheck disable=SC2001
  trimmed="$(printf "%s" "$root_item" | sed 's/^ *//;s/ *$//')"
  already=0
  for seen in "${dedupe_legal_roots[@]}"; do
    if [[ "$seen" == "$trimmed" ]]; then
      already=1
      break
    fi
  done
  if [[ "$already" -eq 0 ]]; then
    dedupe_legal_roots+=("$trimmed")
  fi
done
LEGAL_ROOTS=("${dedupe_legal_roots[@]}")

if [[ ${#LEGAL_ROOTS[@]} -eq 0 ]]; then
  LEGAL_ROOTS=("$DEFAULT_LEGAL_ROOT")
fi

if [[ ${#REFERENCE_SOURCES[@]} -eq 0 ]]; then
  REFERENCE_SOURCES=(
    "https://www.gov.hk/"
    "https://www.gov.cn/"
    "https://www.beijing.gov.cn/"
    "https://lightmind.art"
  )
fi

dedupe_reference_sources=()
for ref_item in "${REFERENCE_SOURCES[@]}"; do
  if [[ -z "${ref_item// /}" ]]; then
    continue
  fi
  trimmed_ref="$(printf "%s" "$ref_item" | sed 's/^ *//;s/ *$//')"
  seen_ref=0
  for seen in "${dedupe_reference_sources[@]}"; do
    if [[ "$seen" == "$trimmed_ref" ]]; then
      seen_ref=1
      break
    fi
  done
  if [[ "$seen_ref" -eq 0 ]]; then
    dedupe_reference_sources+=("$trimmed_ref")
  fi
done
REFERENCE_SOURCES=("${dedupe_reference_sources[@]}")

MERGED_WEB_SUMMARY_FILE="$WEB_SUMMARY_FILE"
LEGAL_WEB_SUMMARY_FILE=""
if [[ "$RUN_LEGAL_WEB_SEARCH" == "1" ]]; then
  if [[ "${#LEGAL_WEB_QUERIES[@]}" -eq 0 ]]; then
    LEGAL_WEB_QUERIES=("${(@f)$(build_default_legal_web_queries)}")
  fi
  LEGAL_WEB_RUN_ID="$(date +%Y%m%d-%H%M%S)"
  LEGAL_WEB_SUMMARY_FILE="$(run_legal_web_search_queries "$OUTPUT_DIR" "$LEGAL_WEB_TOP_RESULTS" "$LEGAL_WEB_RUN_ID" "${LEGAL_WEB_QUERIES[@]}")"

  if [[ -n "$LEGAL_WEB_SUMMARY_FILE" && -f "$LEGAL_WEB_SUMMARY_FILE" ]]; then
    if [[ -n "$WEB_SUMMARY_FILE" && -f "$WEB_SUMMARY_FILE" ]]; then
      MERGED_WEB_SUMMARY_FILE="$OUTPUT_DIR/merged_web_summary.txt"
      {
        cat "$WEB_SUMMARY_FILE"
        printf '\n'
        echo "Legal stage targeted web search:"
        cat "$LEGAL_WEB_SUMMARY_FILE"
      } > "$MERGED_WEB_SUMMARY_FILE"
    else
      MERGED_WEB_SUMMARY_FILE="$LEGAL_WEB_SUMMARY_FILE"
    fi
  fi
fi

PAYLOAD_PATH="$OUTPUT_DIR/latest-payload.json"
python3 - "$OUTPUT_DIR" "$CONTEXT_FILE" "$MARKET_SUMMARY_FILE" "$RESOURCE_SUMMARY_FILE" "$MERGED_WEB_SUMMARY_FILE" "$COMPANY_FOCUS" \
  "__ROOTS__" "${LEGAL_ROOTS[@]}" "__REFS__" "${REFERENCE_SOURCES[@]}" <<'PY'
import json
import re
from datetime import datetime
from pathlib import Path
import sys

output_dir, context_path, market_path, resource_path, web_path, company_focus = sys.argv[1:7]

try:
    roots_idx = sys.argv.index("__ROOTS__", 4)
    refs_idx = sys.argv.index("__REFS__", roots_idx + 1)
except ValueError:
    raise SystemExit("Missing markers for payload builder")

legal_roots = [p for p in sys.argv[roots_idx + 1 : refs_idx] if p.strip()]
reference_sources = [s for s in sys.argv[refs_idx + 1 :] if s.strip()]


def _read_text(path):
    if not path:
        return ""
    p = Path(path).expanduser()
    if not p.exists():
        return ""
    try:
        return p.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return ""


context_text = _read_text(context_path)
market_summary = _read_text(market_path)
resource_summary = _read_text(resource_path)
web_search_summary = _read_text(web_path)

allowed_exts = {".md", ".txt", ".rst", ".yaml", ".yml", ".json", ".html", ".htm", ".pdf", ".doc", ".docx"}
max_chars = 60000
spent = 0
snippets = []

for root_str in legal_roots:
    root_path = Path(root_str).expanduser()
    if not root_path.exists():
        snippets.append(f"- [missing] {root_path}")
        continue
    snippets.append(f"- [root] {root_path}")
    for p in sorted(root_path.rglob("*")):
        if spent >= max_chars:
            break
        if not p.is_file():
            continue
        if p.suffix.lower() not in allowed_exts:
            continue
        if p.name.startswith("."):
            continue
        try:
            text = p.read_bytes().decode("utf-8", errors="ignore")
        except OSError:
            continue
        text = re.sub(r"\s+", " ", text).strip()
        if not text:
            continue
        snippet = text[:4000]
        try:
            relative = p.relative_to(root_path)
        except ValueError:
            relative = p.name
        snippets.append(f"- {relative} :: {snippet}")
        spent += len(snippet)

if not snippets:
    snippets = ["No legal source file content loaded."]

payload = {
    "run_local_iso": datetime.now().astimezone().isoformat(timespec="seconds"),
    "company_focus": company_focus,
    "run_context": context_text[:20000],
    "market_summary": market_summary[:8000],
    "resource_summary": resource_summary[:8000],
    "web_search_summary": web_search_summary[:8000],
    "legal_materials": "\\n".join(snippets),
    "legal_roots": legal_roots,
    "reference_sources": reference_sources,
}

payload_path = Path(output_dir).expanduser() / "latest-payload.json"
payload_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY

if [[ ! -f "$PAYLOAD_PATH" ]]; then
  echo "Failed to build legal payload." >&2
  exit 1
fi

python3 orchestral/prompt_tools/runtime/codex-json-runner.py \
  --input-json "$PAYLOAD_PATH" \
  --output-dir "$OUTPUT_DIR" \
  --prompt-file "$PROMPT_FILE" \
  --schema "$SCHEMA_FILE" \
  --model "$MODEL" \
  --reasoning "$REASONING" \
  --safety "$SAFETY" \
  --approval "$APPROVAL" \
  --label "$LABEL" \
  --skip-git-check \
  >/dev/null

cat "$OUTPUT_DIR/latest-result.json"
