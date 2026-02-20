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
PROMPT_FILE="orchestral/prompt_tools/legal_dept_prompt.md"
SCHEMA_FILE="orchestral/prompt_tools/la_ops_schema.json"
REFERENCE_SOURCES=(
  "https://www.gov.hk/"
  "https://www.gov.cn/"
  "https://www.beijing.gov.cn/"
)
CUSTOM_REFERENCE_SOURCES=0
DEFAULT_LEGAL_ROOT="/Users/lachlan/Documents/LazyingArtBotIO/LightMind/Input/Legal"
LEGAL_ROOTS=()

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
  --model <name>                 Codex model (default: gpt-5.3-codex-spark)
  --reasoning <level>            Reasoning level (default: high)
  --safety <mode>                Safety mode (default: danger-full-access)
  --approval <policy>            Approval mode (default: never)
  --output-dir <path>            Output artifact directory (default: /tmp/codex-legal-review)
  --label <name>                 Run label (default: legal-dept)
  --prompt-file <path>           Prompt file (default: orchestral/prompt_tools/legal_dept_prompt.md)
  --schema-file <path>           JSON schema (default: orchestral/prompt_tools/la_ops_schema.json)
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

PAYLOAD_PATH="$OUTPUT_DIR/latest-payload.json"
python3 - "$OUTPUT_DIR" "$CONTEXT_FILE" "$MARKET_SUMMARY_FILE" "$RESOURCE_SUMMARY_FILE" "$WEB_SUMMARY_FILE" "$COMPANY_FOCUS" \
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

python3 orchestral/prompt_tools/codex-json-runner.py \
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
