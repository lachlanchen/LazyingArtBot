#!/bin/zsh
set -euo pipefail

REPO_DIR="/Users/lachlan/Local/Clawbot"
cd "$REPO_DIR"

INPUT_MD="$HOME/Documents/LazyingArtBotIO/LazyingArt/Input/LazyingArtCompanyInput.md"
MARKET_SUMMARY_FILE=""
PLAN_SUMMARY_FILE=""
MENTOR_SUMMARY_FILE=""
MODEL="gpt-5.3-codex-spark"
REASONING="high"
OUTPUT_DIR="/tmp/codex-la-pipeline"
LABEL="la-life-reverse"
REMINDER_LIST="LazyingArt"
STATE_JSON="$HOME/.openclaw/workspace/AutoLife/MetaNotes/Companies/LazyingArt/life_reminder_state.json"
STATE_MD="$HOME/Documents/LazyingArtBotIO/LazyingArt/Output/LazyingArtLifeReminderState.md"
REPORT_JSON=""
REPORT_MD=""
REPORT_HTML=""
RUN_ID="$(TZ=Asia/Hong_Kong date '+%Y%m%d-%H%M%S')"

usage() {
  cat <<'USAGE'
Usage: prompt_life_reverse_engineering_tool.sh [options]

Options:
  --input-md <path>            Company input markdown (default: ~/Documents/LazyingArtBotIO/LazyingArt/Input/LazyingArtCompanyInput.md)
  --market-summary-file <p>    Optional market summary text file
  --plan-summary-file <p>      Optional plan summary text file
  --mentor-summary-file <p>    Optional mentor summary text file
  --state-json <path>          Reminder state JSON (default: workspace AutoLife state)
  --state-md <path>            Reminder state markdown mirror (default: ~/Documents/LazyingArtBotIO/LazyingArt/Output/LazyingArtLifeReminderState.md)
  --report-json <path>         Output report json path (default: <output-dir>/life-reminder-report.json)
  --report-md <path>           Output report markdown path (default: <output-dir>/life-reminder-report.md)
  --report-html <path>         Output report html path (default: <output-dir>/life-reminder-report.html)
  --list-name <name>           Reminders list name (default: LazyingArt)
  --model <name>               Codex model (default: gpt-5.3-codex-spark)
  --reasoning <level>          Reasoning level (default: high)
  --safety <mode>              Safety mode (currently ignored; for compatibility only)
  --approval <policy>          Approval policy (currently ignored; for compatibility only)
  --output-dir <path>          Codex artifact directory (default: /tmp/codex-la-pipeline)
  --label <name>               Codex run label (default: la-life-reverse)
  --run-id <id>                External run id for state tracking
  -h, --help                   Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --input-md)
      shift
      INPUT_MD="${1:-}"
      ;;
    --market-summary-file)
      shift
      MARKET_SUMMARY_FILE="${1:-}"
      ;;
    --plan-summary-file)
      shift
      PLAN_SUMMARY_FILE="${1:-}"
      ;;
    --mentor-summary-file)
      shift
      MENTOR_SUMMARY_FILE="${1:-}"
      ;;
    --state-json)
      shift
      STATE_JSON="${1:-}"
      ;;
    --state-md)
      shift
      STATE_MD="${1:-}"
      ;;
    --report-json)
      shift
      REPORT_JSON="${1:-}"
      ;;
    --report-md)
      shift
      REPORT_MD="${1:-}"
      ;;
    --report-html)
      shift
      REPORT_HTML="${1:-}"
      ;;
    --list-name)
      shift
      REMINDER_LIST="${1:-}"
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
      ;;
    --approval)
      shift
      ;;
    --output-dir)
      shift
      OUTPUT_DIR="${1:-}"
      ;;
    --label)
      shift
      LABEL="${1:-}"
      ;;
    --run-id)
      shift
      RUN_ID="${1:-}"
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

mkdir -p "$(dirname "$INPUT_MD")" "$(dirname "$STATE_JSON")" "$(dirname "$STATE_MD")" "$OUTPUT_DIR"

if [[ ! -f "$INPUT_MD" ]]; then
  cat > "$INPUT_MD" <<'MD'
# LazyingArt Company Input

## Founder Context
- Name: Lachlan
- Company: Lazying.art
- Working timezone: Asia/Hong_Kong
- Primary execution stack: OpenClaw orchestral pipeline + Apple Notes/Calendar/Reminders

## Strategic Background
- Lazying.art is building practical AI workflows combining:
  - EchoMind (voice-first assistant / multilingual interaction)
  - Automation products and toolchain integration
  - Notes, reminders, and milestone-oriented personal/company execution
- Priority is long-term compounding execution, not short-term noisy activity.

## Reminder Philosophy (Must Keep)
- Keep a fixed reminder backbone across 8 horizons:
  - day plan (08:00)
  - tomorrow plan (20:00)
  - week plan
  - tonight milestone
  - month milestone
  - season milestone
  - half-year milestone
  - one-year milestone
- Avoid spam and avoid duplicate reminders.
- If an old reminder is already complete, next cycle should be updated naturally.
- Every reminder should tie to concrete milestone outcomes and measurable completion criteria.

## Operating Constraints
- Reminders must stay human-readable and operationally useful.
- Avoid abstract motivational text.
- Each reminder should include small checklist actions and one clear success condition.

## Current Focus (Editable)
- Keep this section updated manually as priorities shift.
- Example:
  - Improve daily execution rhythm (08:00 + 20:00 loops)
  - Keep weekly planning quality high
  - Maintain monthly/quarterly trajectory without drift
  - Align company milestones with personal cadence

## Additional Inputs
- Add any temporary priorities, deadlines, or risks here.
MD
fi

if [[ -z "$REPORT_JSON" ]]; then
  REPORT_JSON="$OUTPUT_DIR/life-reminder-report.json"
fi
if [[ -z "$REPORT_MD" ]]; then
  REPORT_MD="$OUTPUT_DIR/life-reminder-report.md"
fi
if [[ -z "$REPORT_HTML" ]]; then
  REPORT_HTML="$OUTPUT_DIR/life-reminder-report.html"
fi

TMP_PAYLOAD="$(mktemp)"
python3 - "$TMP_PAYLOAD" "$INPUT_MD" "$MARKET_SUMMARY_FILE" "$PLAN_SUMMARY_FILE" "$MENTOR_SUMMARY_FILE" "$STATE_JSON" "$STATE_MD" "$REMINDER_LIST" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

payload_path = Path(sys.argv[1])
input_md = Path(sys.argv[2]).expanduser()
market_path = sys.argv[3]
plan_path = sys.argv[4]
mentor_path = sys.argv[5]
state_json_path = Path(sys.argv[6]).expanduser()
state_md_path = Path(sys.argv[7]).expanduser()
list_name = sys.argv[8]


def read_optional(path_text: str) -> str:
    if not path_text:
        return ""
    p = Path(path_text).expanduser()
    if p.exists() and p.is_file():
        return p.read_text(encoding="utf-8")
    return ""

company_input = input_md.read_text(encoding="utf-8") if input_md.exists() else ""
state_json_text = state_json_path.read_text(encoding="utf-8") if state_json_path.exists() else ""
state_md_text = state_md_path.read_text(encoding="utf-8") if state_md_path.exists() else ""

payload = {
    "run_local_iso": datetime.now().astimezone().isoformat(timespec="seconds"),
    "run_utc_iso": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    "company_focus": "Lazying.art",
    "timezone": "Asia/Hong_Kong",
    "reminder_list": list_name,
    "required_slots": [
        "day_plan_8am",
        "tomorrow_plan_8pm",
        "week_plan",
        "tonight_milestone",
        "month_milestone",
        "season_milestone",
        "half_year_milestone",
        "one_year_milestone",
    ],
    "slot_time_intent": {
        "day_plan_8am": "08:00 local",
        "tomorrow_plan_8pm": "20:00 local",
        "week_plan": "weekly checkpoint",
        "tonight_milestone": "evening milestone checkpoint",
        "month_milestone": "monthly horizon",
        "season_milestone": "quarterly horizon",
        "half_year_milestone": "half-year horizon",
        "one_year_milestone": "annual horizon",
    },
    "company_input_markdown": company_input,
    "market_summary": read_optional(market_path),
    "plan_summary": read_optional(plan_path),
    "mentor_summary": read_optional(mentor_path),
    "previous_state_json": state_json_text,
    "previous_state_markdown": state_md_text,
}

payload_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY

python3 "$REPO_DIR/orchestral/prompt_tools/codex-json-runner.py" \
  --input-json "$TMP_PAYLOAD" \
  --output-dir "$OUTPUT_DIR" \
  --prompt-file "$REPO_DIR/orchestral/prompt_tools/life_reverse_engineering_prompt.md" \
  --schema "$REPO_DIR/orchestral/prompt_tools/life_reverse_engineering_schema.json" \
  --model "$MODEL" \
  --reasoning "$REASONING" \
  --label "$LABEL" \
  --skip-git-check \
  >/dev/null

PLAN_JSON="$OUTPUT_DIR/latest-result.json"
python3 "$REPO_DIR/orchestral/prompt_tools/life_reverse_reminder_apply.py" \
  --plan-json "$PLAN_JSON" \
  --state-json "$STATE_JSON" \
  --state-md "$STATE_MD" \
  --report-json "$REPORT_JSON" \
  --report-md "$REPORT_MD" \
  --report-html "$REPORT_HTML" \
  --run-id "$RUN_ID" \
  --list-name "$REMINDER_LIST" \
  >/dev/null

cat "$REPORT_JSON"
rm -f "$TMP_PAYLOAD"
