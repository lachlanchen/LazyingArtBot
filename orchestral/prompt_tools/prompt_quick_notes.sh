#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

usage() {
  cat <<'USAGE'
Usage: prompt_quick_notes.sh --context <text> [options]

Options:
  --context <text>        Note context text to process
  --note <name>           Target note title (default: Quick Notes)
  --folder <name>         Notes folder (default: 🌱 Life)
  --output-dir <path>     Codex artifact directory (default: /tmp/codex-quick-notes)
  --model <name>          Codex model (default: gpt-5.3-codex-spark)
  --reasoning <level>     Reasoning level (default: high)
USAGE
}

CONTEXT=""
TARGET_NOTE="Quick Notes"
FOLDER="🌱 Life"
OUTPUT_DIR="/tmp/codex-quick-notes"
MODEL="gpt-5.3-codex-spark"
REASONING="high"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --context)
      shift
      CONTEXT="$1"
      ;;
    --note)
      shift
      TARGET_NOTE="$1"
      ;;
    --folder)
      shift
      FOLDER="$1"
      ;;
    --output-dir)
      shift
      OUTPUT_DIR="$1"
      ;;
    --model)
      shift
      MODEL="$1"
      ;;
    --reasoning)
      shift
      REASONING="$1"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
  shift
done

if [[ -z "$CONTEXT" ]]; then
  if [[ -t 0 ]]; then
    usage
    exit 1
  fi
  CONTEXT="$(cat)"
fi

TMP=$(mktemp)
export CONTEXT TARGET_NOTE FOLDER
python3 - "$TMP" <<'PY'
import json
import os
import sys

payload = {
    "context": os.environ["CONTEXT"],
    "target_note": os.environ["TARGET_NOTE"],
    "folder": os.environ["FOLDER"],
}

with open(sys.argv[1], "w", encoding="utf-8") as fh:
    json.dump(payload, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY

python3 scripts/prompt_tools/codex-json-runner.py \
  --input-json "$TMP" \
  --output-dir "$OUTPUT_DIR" \
  --prompt-file orchestral/prompt_tools/prompt_quick_notes_prompt.md \
  --schema orchestral/prompt_tools/quick_reminder_schema.json \
  --model "$MODEL" \
  --reasoning "$REASONING" \
  --label quick-notes \
  --skip-git-check

RESULT_JSON="$OUTPUT_DIR/latest-result.json"
CREATE_NOTE_SCRIPT="$HOME/.openclaw/workspace/automation/create_note.applescript"

if [[ ! -f "$RESULT_JSON" ]]; then
  echo "No result file from Codex prompt" >&2
  exit 1
fi

python3 "$RESULT_JSON" "$CREATE_NOTE_SCRIPT" "$TARGET_NOTE" "$FOLDER" <<'PY'
import json
import os
import subprocess
import sys
from pathlib import Path

PLAN_JSON = Path(sys.argv[1]).expanduser()
CREATE_NOTE_SCRIPT = Path(sys.argv[2]).expanduser()
DEFAULT_NOTE = os.fspath(sys.argv[3])
DEFAULT_FOLDER = os.fspath(sys.argv[4])


def run_osascript(script_path: str, *args: str) -> str:
    proc = subprocess.run(
        ["osascript", str(script_path), *args],
        text=True,
        capture_output=True,
        timeout=60,
    )
    if proc.returncode != 0:
        raise RuntimeError((proc.stderr or proc.stdout or "osascript failed").strip())
    return proc.stdout.strip()


def to_str(value: object, default: str = "") -> str:
    return str(value).strip() if isinstance(value, str) else default


plan = json.loads(PLAN_JSON.read_text(encoding="utf-8"))
summary = to_str(plan.get("summary"), "Quick note capture")
notes = plan.get("notes", [])
if not isinstance(notes, list):
    notes = []

results = []
created = 0
failed = 0

for item in notes:
    if not isinstance(item, dict):
        continue

    target_note = to_str(item.get("target_note"), DEFAULT_NOTE)
    if not target_note:
        target_note = DEFAULT_NOTE

    folder = to_str(item.get("folder"), DEFAULT_FOLDER)
    if not folder:
        folder = DEFAULT_FOLDER

    html_body = item.get("html_body") if isinstance(item.get("html_body"), str) else ""

    try:
        note_id = run_osascript(
            str(CREATE_NOTE_SCRIPT),
            target_note,
            html_body,
            folder,
            "replace",
        )
        created += 1
        results.append({
            "status": "created",
            "action": "note",
            "note": target_note,
            "folder": folder,
            "note_id": note_id,
        })
    except Exception as exc:  # noqa: BLE001
        failed += 1
        results.append({
            "status": "failed",
            "action": "note",
            "note": target_note,
            "folder": folder,
            "error": str(exc),
        })

report = {
    "summary": summary,
    "created": created,
    "failed": failed,
    "results": results,
}

print(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
PY

rm -f "$TMP"
