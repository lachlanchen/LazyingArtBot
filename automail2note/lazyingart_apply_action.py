#!/usr/bin/env python3
"""Apply Codex action JSON by creating calendar events, reminders, or notes."""

from __future__ import annotations

import argparse
import json
import logging
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict

WORKDIR = Path(__file__).resolve().parent.parent
AUTOMATION_DIR = WORKDIR / "automation"
LOG_DIR = WORKDIR / "logs"
LOG_FILE = LOG_DIR / "lazyingart_simple.log"

CALENDAR_SCRIPT = AUTOMATION_DIR / "create_calendar_event.applescript"
REMINDER_SCRIPT = AUTOMATION_DIR / "create_reminder.applescript"
NOTE_SCRIPT = AUTOMATION_DIR / "create_note.applescript"


def setup_logging(level: str = "INFO") -> None:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    logging.basicConfig(
        level=getattr(logging, level.upper(), logging.INFO),
        format="%(asctime)s [%(levelname)s] %(message)s",
        handlers=[logging.FileHandler(LOG_FILE, encoding="utf-8"), logging.StreamHandler(sys.stderr)],
    )


def load_json(path: Path) -> Dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"Expected object in {path}")
    return payload


def run_osascript(script_path: Path, args: list[str]) -> Dict[str, str]:
    cmd = ["osascript", str(script_path), *args]
    proc = subprocess.run(cmd, capture_output=True, text=True, check=True)
    return {"stdout": proc.stdout.strip(), "stderr": proc.stderr.strip()}


def apply_calendar(action: Dict[str, Any]) -> Dict[str, Any]:
    out = run_osascript(
        CALENDAR_SCRIPT,
        [
            str(action.get("title", "")),
            str(action.get("start", "")),
            str(action.get("end", "")),
            str(action.get("notes", "")),
            str(action.get("calendar", "Lachlan") or "Lachlan"),
            str(int(action.get("reminderMinutes", 0))),
        ],
    )
    return {"status": "created", "target": "calendar", "id": out["stdout"], "stderr": out["stderr"]}


def apply_reminder(action: Dict[str, Any]) -> Dict[str, Any]:
    out = run_osascript(
        REMINDER_SCRIPT,
        [
            str(action.get("title", "")),
            str(action.get("due", "")),
            str(action.get("notes", "")),
            str(action.get("list", "Reminders") or "Reminders"),
            str(int(action.get("reminderMinutes", 0))),
        ],
    )
    return {"status": "created", "target": "reminder", "id": out["stdout"], "stderr": out["stderr"]}


def apply_note(action: Dict[str, Any]) -> Dict[str, Any]:
    out = run_osascript(
        NOTE_SCRIPT,
        [
            str(action.get("title", "")),
            str(action.get("notes", "")),
            str(action.get("folder", "Lazyingart/Inbox") or "Lazyingart/Inbox"),
        ],
    )
    return {"status": "created", "target": "note", "id": out["stdout"], "stderr": out["stderr"]}


def main() -> None:
    parser = argparse.ArgumentParser(description="Apply Lazyingart action JSON")
    parser.add_argument("--action-json", required=True)
    parser.add_argument("--message-json", default="")
    parser.add_argument("--log-level", default="INFO")
    args = parser.parse_args()

    setup_logging(args.log_level)

    action_path = Path(args.action_json).expanduser()
    if not action_path.exists():
        logging.error("action_json_missing path=%s", action_path)
        sys.exit(1)

    action = load_json(action_path)
    decision = str(action.get("decision", "skip")).strip().lower()
    message_path = str(Path(args.message_json).expanduser()) if args.message_json else ""

    logging.info(
        "apply_start decision=%s action_path=%s message_path=%s",
        decision,
        action_path,
        message_path,
    )

    if decision == "skip":
        result: Dict[str, Any] = {
            "status": "skipped",
            "target": "none",
            "reason": str(action.get("reason", "")),
        }
    else:
        try:
            if decision == "calendar":
                result = apply_calendar(action)
            elif decision == "reminder":
                result = apply_reminder(action)
            elif decision == "note":
                result = apply_note(action)
            else:
                raise ValueError(f"Unsupported decision: {decision}")
        except subprocess.CalledProcessError as exc:
            result = {
                "status": "failed",
                "target": decision,
                "error": exc.stderr.strip() or str(exc),
            }
            logging.error("apply_script_failed decision=%s err=%s", decision, result["error"])
            print(json.dumps(result, ensure_ascii=False))
            sys.exit(1)

    logging.info("apply_done decision=%s result=%s", decision, result)
    print(json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    main()
