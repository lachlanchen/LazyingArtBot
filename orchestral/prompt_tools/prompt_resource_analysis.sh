#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

COMPANY="Company"
OUTPUT_DIR="/tmp/codex-resource-analysis"
MARKDOWN_OUTPUT_DIR=""
PROMPT_FILE="orchestral/prompt_tools/resource_analysis_prompt.md"
SCHEMA_FILE="orchestral/prompt_tools/resource_analysis_schema.json"
MODEL="gpt-5.3-codex-spark"
REASONING="high"
LABEL="resource-analysis"
MAX_MANIFEST_FILES=500
MAX_TEXT_SNIPPETS=40000

usage() {
  cat <<'USAGE'
Usage: prompt_resource_analysis.sh [options]

Options:
  --company <name>               Company scope label (default: Company)
  --resource-root <path>         Add resource root (repeatable)
  --prompt-file <path>           Prompt template (default: orchestral/prompt_tools/resource_analysis_prompt.md)
  --schema-file <path>           Output schema file (default: orchestral/prompt_tools/resource_analysis_schema.json)
  --output-dir <path>            Codex artifact dir (default: /tmp/codex-resource-analysis)
  --markdown-output <path>       Directory for generated markdown reference docs (required)
  --model <name>                 Codex model (default: gpt-5.3-codex-spark)
  --reasoning <level>            Reasoning level (default: high)
  --max-manifest-files <n>       Cap manifest/sample files per root (default: 500)
  --max-text-snippets <n>        Cap snippet total chars (default: 40000)
  -h, --help                    Show help
USAGE
}

RESOURCE_ROOTS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --company)
      shift
      COMPANY="${1:-}"
      ;;
    --resource-root)
      shift
      RESOURCE_ROOTS+=("${1:-}")
      ;;
    --prompt-file)
      shift
      PROMPT_FILE="${1:-}"
      ;;
    --schema-file)
      shift
      SCHEMA_FILE="${1:-}"
      ;;
    --output-dir)
      shift
      OUTPUT_DIR="${1:-}"
      ;;
    --markdown-output)
      shift
      MARKDOWN_OUTPUT_DIR="${1:-}"
      ;;
    --model)
      shift
      MODEL="${1:-}"
      ;;
    --reasoning)
      shift
      REASONING="${1:-}"
      ;;
    --label)
      shift
      LABEL="${1:-}"
      ;;
    --max-manifest-files)
      shift
      MAX_MANIFEST_FILES="${1:-500}"
      ;;
    --max-text-snippets)
      shift
      MAX_TEXT_SNIPPETS="${1:-40000}"
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

if [[ "${#RESOURCE_ROOTS[@]}" -eq 0 ]]; then
  echo "At least one --resource-root is required." >&2
  exit 1
fi

if [[ -z "$MARKDOWN_OUTPUT_DIR" ]]; then
  echo "--markdown-output is required." >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR" "$MARKDOWN_OUTPUT_DIR"

PAYLOAD_PATH="$(mktemp)"
RUN_ID="$(TZ=Asia/Hong_Kong date '+%Y%m%d-%H%M%S')"

python3 - "$PAYLOAD_PATH" "$COMPANY" "$MAX_MANIFEST_FILES" "$MAX_TEXT_SNIPPETS" "${RESOURCE_ROOTS[@]}" <<'PY'
import hashlib
import json
import mimetypes
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

payload_path = Path(sys.argv[1])
company = sys.argv[2]
max_manifest = max(10, int(sys.argv[3] or 500))
max_snippet_chars = max(1000, int(sys.argv[4] or 40000))
roots = [x for x in sys.argv[5:] if x.strip()]


def safe_snippet(path: Path, limit: int = 5000) -> str:
  try:
    data = path.read_bytes()
  except OSError:
    return ""
  try:
    text = data.decode("utf-8")
  except UnicodeDecodeError:
    try:
      text = data.decode("latin1", errors="ignore")
    except Exception:
      return ""
  text = text.replace("\r\n", "\n").strip()
  if not text:
    return ""
  text = re.sub(r"\n{3,}", "\n\n", text)
  return text[:limit]


def is_likely_text(path: Path) -> bool:
  mime, _ = mimetypes.guess_type(str(path))
  if mime and mime.startswith("text/"):
    return True
  ext = path.suffix.lower().lstrip(".")
  return ext in {
    "txt", "md", "markdown", "json", "yaml", "yml", "csv", "tsv", "html", "htm",
    "xml", "log", "ini", "cfg", "conf", "rmd", "rst", "tex", "js", "ts", "py",
    "sh", "zsh", "swift", "java", "kt", "kts", "rs", "go", "cpp", "c", "h", "m",
    "mm", "pyi", "sql", "dockerfile", "properties", "plist", "rb", "php", "cs", "scala",
  }


manifest = []
total_seen = 0

for root_str in roots:
  root = Path(root_str).expanduser().resolve()
  entry = {
      "label": root.name or root_str,
      "path": str(root),
      "status": "missing",
      "file_count": 0,
      "total_bytes": 0,
      "sample_files": [],
  }
  if root.exists() and root.is_dir():
    files = []
    for p in root.rglob("*"):
      if p.is_file():
        try:
          st = p.stat()
        except OSError:
          continue
        if p.name.startswith("."):
          continue
        files.append((p, st.st_size, st.st_mtime))
    files.sort(key=lambda item: item[2], reverse=True)
    entry["status"] = "ok"
    entry["file_count"] = len(files)
    entry["total_bytes"] = int(sum(size for _, size, _ in files))
    for p, size, mtime in files[:max_manifest]:
      rel = p.relative_to(root)
      mime, _ = mimetypes.guess_type(str(p))
      sample_payload = {
        "path": str(rel),
        "size": int(size),
        "mtime": datetime.fromtimestamp(mtime, tz=timezone.utc).isoformat(timespec="seconds"),
        "mime_type": mime or "",
      }
      if is_likely_text(p) and total_seen < max_snippet_chars:
        snippet = safe_snippet(p, limit=min(3500, max_snippet_chars - total_seen))
        if snippet:
          sample_payload["snippet"] = snippet
          total_seen += len(snippet)
      entry["sample_files"].append(sample_payload)
  manifest.append(entry)

payload = {
  "run_local_iso": datetime.now().astimezone().isoformat(timespec="seconds"),
  "run_utc_iso": datetime.now(timezone.utc).isoformat(timespec="seconds"),
  "company_focus": company,
  "resource_roots": manifest,
}

payload_text = json.dumps(payload, ensure_ascii=False, indent=2)
signature = hashlib.sha256(payload_text.encode("utf-8")).hexdigest()[:16]
payload["resource_signature"] = signature
payload["snippet_chars_budget_used"] = total_seen
payload["prompt_style"] = "strict_output_json"

payload_path.write_text(payload_text, encoding="utf-8")
PY

CODex_RC=0
RUN_OUTPUT_DIR="$OUTPUT_DIR/$LABEL-$RUN_ID"
mkdir -p "$RUN_OUTPUT_DIR"

python3 scripts/prompt_tools/codex-json-runner.py \
  --input-json "$PAYLOAD_PATH" \
  --output-dir "$RUN_OUTPUT_DIR" \
  --prompt-file "$PROMPT_FILE" \
  --schema "$SCHEMA_FILE" \
  --model "$MODEL" \
  --reasoning "$REASONING" \
  --label "$LABEL" \
  --skip-git-check || CODex_RC=$?

LATEST_RESULT="$RUN_OUTPUT_DIR/latest-result.json"
if [[ ! -s "$LATEST_RESULT" || "$CODex_RC" -ne 0 ]]; then
  NOW_PATH="$(TZ=Asia/Hong_Kong date '+%Y-%m-%d %H:%M:%S %Z')"
  python3 - "$PAYLOAD_PATH" "$COMPANY" "$NOW_PATH" "$CODex_RC" > "$LATEST_RESULT" <<'PY'
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
company = sys.argv[2]
now = sys.argv[3]
rc = sys.argv[4]

resource_overview = []
for item in payload.get("resource_roots", []):
  resource_overview.append(
    {
      "path": item.get("path", ""),
      "status": item.get("status", "missing"),
      "file_count": int(item.get("file_count", 0)),
      "total_bytes": int(item.get("total_bytes", 0)),
    }
  )

result = {
  "summary": (
    f"Resource analysis executed for {company} with manual fallback "
    f"(codex_rc={rc}) at {now}."
  ),
  "resource_signature": f"fallback-{now}",
  "resource_recommendations": [
    "Retry Codex when permissions/network are stable.",
    "Review manifest files and rerun in a short interval.",
  ],
  "resource_overview": resource_overview,
  "markdown_documents": [
    {
      "file_name": "resource-analysis-fallback.md",
      "title": "Resource Analysis Fallback",
      "section_scope": "resource",
      "scope_hint": "resource_roots payload",
      "importance": "medium",
      "markdown": (
        "Resource analysis model step fell back to a deterministic manifest. "
        "Please review source files and rerun when Codex is available."
      ),
    }
  ],
}

print(json.dumps(result, ensure_ascii=False, indent=2))
PY
fi

python3 - "$LATEST_RESULT" "$MARKDOWN_OUTPUT_DIR" "$RUN_ID" "$PAYLOAD_PATH" <<'PY'
import json
import re
import sys
from datetime import datetime
from pathlib import Path

result_path = Path(sys.argv[1])
md_dir = Path(sys.argv[2]).expanduser()
run_id = sys.argv[3]
payload_path = Path(sys.argv[4]).expanduser()

result = json.loads(result_path.read_text(encoding="utf-8"))
md_dir.mkdir(parents=True, exist_ok=True)
payload = {}
if payload_path.is_file():
    try:
        payload = json.loads(payload_path.read_text(encoding="utf-8"))
    except Exception:
        payload = {}


def safe_name(name: str, fallback: str = "note") -> str:
  out = re.sub(r"[^a-zA-Z0-9_.-]+", "-", name.strip().lower())
  out = out.strip("-") or fallback
  if not out.endswith(".md"):
    out = f"{out}.md"
  return out[:140]


summary_path = md_dir / f"{run_id}-summary.md"
summary_path.write_text(
  "# Resource Analysis Summary\n\n"
  f"Generated: {datetime.now().astimezone().isoformat(timespec='seconds')}\n\n"
  f"{result.get('summary','')}\n",
  encoding="utf-8",
)

manifest = result.get("resource_overview", [])
manifest_lines = [
  "# Resource Overview",
  "| Path | Status | Files | Size (bytes) |",
  "| --- | --- | ---: | ---: |",
]
for item in manifest:
  manifest_lines.append(
    f"| `{item.get('path','')}` | {item.get('status','')} | "
    f"{int(item.get('file_count',0))} | {int(item.get('total_bytes',0))} |"
  )
if len(manifest_lines) == 3:
  manifest_lines.append("| - | - | - | - |")

(md_dir / f"{run_id}-manifest.md").write_text("\n".join(manifest_lines) + "\n", encoding="utf-8")

for idx, doc in enumerate(result.get("markdown_documents", []), 1):
  file_name = safe_name(doc.get("file_name", "resource-analysis-note.md"), f"resource-note-{idx}")
  title = doc.get("title", "Resource Note")
  section = doc.get("section_scope", "")
  scope = doc.get("scope_hint", "")
  importance = doc.get("importance", "medium")
  body = doc.get("markdown", "")
  out = md_dir / file_name
  out.write_text(
    f"# {title}\n\n"
    f"- scope: {section}\n"
    f"- source hint: `{scope}`\n"
    f"- importance: {importance}\n\n"
    f"{body}\n",
    encoding="utf-8",
  )

recommendations = result.get("resource_recommendations", [])
if recommendations:
  (md_dir / f"{run_id}-recommendations.md").write_text(
    "# Recommendations\n\n" + "\n".join(f"- {r}" for r in recommendations) + "\n",
    encoding="utf-8",
  )

resource_roots = payload.get("resource_roots", [])
if isinstance(resource_roots, list) and resource_roots:
  for root in resource_roots:
    label = root.get("label", "resource-root")
    path = root.get("path", "")
    status = root.get("status", "")
    file_count = int(root.get("file_count", 0))
    total_bytes = int(root.get("total_bytes", 0))
    samples = root.get("sample_files", [])

    files_lines = ["# Resource Root Inventory\n", f"- label: {label}\n", f"- path: `{path}`\n"]
    files_lines.append(f"- status: {status}\n")
    files_lines.append(f"- files: {file_count}\n")
    files_lines.append(f"- total_bytes: {total_bytes}\n")
    files_lines.append("")

    if isinstance(samples, list) and samples:
      files_lines.append("## Sample files\n")
      files_lines.append("| Relative path | Size | Modified UTC | Type | Has snippet |")
      files_lines.append("| --- | ---: | --- | --- | --- |")
      for item in samples[:80]:
        if not isinstance(item, dict):
          continue
        rel = item.get("path", "")
        size = item.get("size", 0)
        mtime = item.get("mtime", "")
        mime = item.get("mime_type", "")
        has_snippet = "yes" if item.get("snippet") else "no"
        files_lines.append(f"| `{rel}` | {int(size)} | {mtime} | `{mime}` | {has_snippet} |")
      files_lines.append("")

      for item in samples:
        snippet = item.get("snippet", "")
        if snippet:
          files_lines.append(f"### {item.get('path', 'file')}\n")
          files_lines.append("```text")
          files_lines.append(str(snippet).strip())
          files_lines.append("```")

    inventory_file = md_dir / f"{run_id}-{safe_name(label, 'resource-root')}"
    if inventory_file.suffix.lower() != ".md":
      inventory_file = Path(f"{inventory_file}.md")
    inventory_file.write_text("\n".join(files_lines).strip() + "\n", encoding="utf-8")
PY

echo "[resource-analysis] company=$COMPANY run_id=$RUN_ID artifacts=$RUN_OUTPUT_DIR latest_result=$LATEST_RESULT"
echo "[$(TZ=Asia/Hong_Kong date '+%Y%m%d-%H%M%S')] output_markdowns_dir=$MARKDOWN_OUTPUT_DIR"

rm -f "$PAYLOAD_PATH"
exit 0
