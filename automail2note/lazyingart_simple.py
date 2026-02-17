#!/usr/bin/env python3
"""Lazyingart Simple email-to-action pipeline using Codex CLI.

Flow:
1) Read one email JSON payload written by Mail rule.
2) Ask `codex exec` to produce a strict JSON action at a fixed state path.
3) Pass the action JSON path to the action runner that creates calendar/reminder/note.
"""

from __future__ import annotations

import argparse
import json
import logging
import os
import re
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Dict, Optional, Tuple
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

WORKDIR = Path(__file__).resolve().parent.parent
AUTOMATION_DIR = WORKDIR / "automation"
STATE_DIR = WORKDIR / "state" / "lazyingart_simple"
INBOUND_DIR = STATE_DIR / "inbound"
CODEX_DIR = STATE_DIR / "codex"
RESULT_DIR = STATE_DIR / "results"
PROMPT_DIR = STATE_DIR / "prompts"
PROCESSED_IDS_PATH = STATE_DIR / "processed_message_ids.json"
LOG_DIR = WORKDIR / "logs"
LOG_FILE = LOG_DIR / "lazyingart_simple.log"

APPLY_SCRIPT = AUTOMATION_DIR / "lazyingart_apply_action.py"

MODEL = "gpt-5.1-codex-mini"
REASONING = "medium"

SCHEMA: Dict[str, Any] = {
    "type": "object",
    "additionalProperties": False,
    "required": [
        "decision",
        "importance",
        "title",
        "start",
        "end",
        "due",
        "notes",
        "reminderMinutes",
        "calendar",
        "list",
        "folder",
        "reason",
    ],
    "properties": {
        "decision": {"type": "string", "enum": ["calendar", "reminder", "note", "skip"]},
        "importance": {"type": "string", "enum": ["high", "medium", "low"]},
        "title": {"type": "string"},
        "start": {"type": "string"},
        "end": {"type": "string"},
        "due": {"type": "string"},
        "notes": {"type": "string"},
        "reminderMinutes": {"type": "integer", "minimum": 0, "maximum": 240},
        "calendar": {"type": "string"},
        "list": {"type": "string"},
        "folder": {
            "type": "string",
            "pattern": r"^$|^Lazyingart/.+",
            "description": (
                "For decision=note, use a nested path that starts with Lazyingart/, "
                "for example Lazyingart/Work/Meetings. "
                "For non-note decisions this may be an empty string."
            ),
        },
        "reason": {"type": "string"},
    },
}

REQUIRED_KEYS = set(SCHEMA["required"])


def ensure_dirs() -> None:
    for path in (LOG_DIR, INBOUND_DIR, CODEX_DIR, RESULT_DIR, PROMPT_DIR):
        path.mkdir(parents=True, exist_ok=True)


def setup_logging(level: str = "INFO") -> None:
    ensure_dirs()
    logging.basicConfig(
        level=getattr(logging, level.upper(), logging.INFO),
        format="%(asctime)s [%(levelname)s] %(message)s",
        handlers=[logging.FileHandler(LOG_FILE, encoding="utf-8"), logging.StreamHandler(sys.stderr)],
    )


def read_json(path: Path) -> Dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(payload, list):
        if not payload:
            raise ValueError(f"Empty JSON array in {path}")
        first = payload[0]
        if not isinstance(first, dict):
            raise ValueError(f"Expected object items in {path}")
        return first
    if not isinstance(payload, dict):
        raise ValueError(f"Expected JSON object in {path}")
    return payload


def write_json(path: Path, payload: Dict[str, Any]) -> None:
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def load_processed_ids() -> Dict[str, Dict[str, str]]:
    if not PROCESSED_IDS_PATH.exists():
        return {}
    try:
        payload = json.loads(PROCESSED_IDS_PATH.read_text(encoding="utf-8"))
    except Exception:
        logging.warning("processed_ids_read_failed path=%s", PROCESSED_IDS_PATH)
        return {}
    if not isinstance(payload, dict):
        return {}
    result: Dict[str, Dict[str, str]] = {}
    for key, value in payload.items():
        if not isinstance(key, str):
            continue
        if isinstance(value, dict):
            result[key] = {
                "timestamp": str(value.get("timestamp", "")),
                "run_id": str(value.get("run_id", "")),
                "decision": str(value.get("decision", "")),
            }
    return result


def save_processed_ids(processed_ids: Dict[str, Dict[str, str]]) -> None:
    PROCESSED_IDS_PATH.parent.mkdir(parents=True, exist_ok=True)
    PROCESSED_IDS_PATH.write_text(json.dumps(processed_ids, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def safe_token(raw: str) -> str:
    cleaned = re.sub(r"[^A-Za-z0-9._-]+", "_", raw).strip("._")
    if not cleaned:
        cleaned = "msg"
    return cleaned[:120]


def parse_codex_json_text(text: str) -> Dict[str, Any]:
    raw = text.strip()
    if not raw:
        raise ValueError("Codex output file is empty")
    try:
        data = json.loads(raw)
        if not isinstance(data, dict):
            raise ValueError("Codex output JSON is not an object")
        return data
    except json.JSONDecodeError:
        pass

    fence = re.search(r"```(?:json)?\s*(\{.*\})\s*```", raw, re.DOTALL)
    if fence:
        data = json.loads(fence.group(1))
        if not isinstance(data, dict):
            raise ValueError("Codex fenced JSON is not an object")
        return data

    obj_match = re.search(r"(\{.*\})", raw, re.DOTALL)
    if obj_match:
        data = json.loads(obj_match.group(1))
        if not isinstance(data, dict):
            raise ValueError("Codex extracted JSON is not an object")
        return data

    raise ValueError("Could not parse JSON from Codex output")


def normalize_action(action: Dict[str, Any]) -> Dict[str, Any]:
    keys = set(action.keys())
    missing = REQUIRED_KEYS - keys
    extra = keys - REQUIRED_KEYS
    if missing:
        raise ValueError(f"Action JSON missing keys: {sorted(missing)}")
    if extra:
        raise ValueError(f"Action JSON has extra keys: {sorted(extra)}")

    decision = str(action["decision"]).strip().lower()
    if decision not in {"calendar", "reminder", "note", "skip"}:
        raise ValueError(f"Invalid decision: {decision}")
    importance = str(action["importance"]).strip().lower()
    if importance not in {"high", "medium", "low"}:
        raise ValueError(f"Invalid importance: {importance}")

    normalized: Dict[str, Any] = {
        "decision": decision,
        "importance": importance,
        "title": str(action["title"]),
        "start": str(action["start"]),
        "end": str(action["end"]),
        "due": str(action["due"]),
        "notes": str(action["notes"]),
        "reminderMinutes": int(action["reminderMinutes"]),
        "calendar": str(action["calendar"]),
        "list": str(action["list"]),
        "folder": str(action["folder"]),
        "reason": str(action["reason"]),
    }
    if normalized["reminderMinutes"] < 0:
        raise ValueError("reminderMinutes cannot be negative")
    return normalized


def normalize_message(message: Dict[str, Any]) -> Dict[str, str]:
    return {
        "messageID": str(message.get("messageID", "")).strip(),
        "subject": str(message.get("subject", "")).strip(),
        "sender": str(message.get("sender", "")).strip(),
        "receivedAt": str(message.get("receivedAt", "")).strip(),
        "mailbox": str(message.get("mailbox", "")).strip(),
        "account": str(message.get("account", "")).strip(),
        "body": str(message.get("body", "")),
    }


def applescript_string_literal(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def build_skip_accounts_literal(skip_accounts: set[str]) -> str:
    items = sorted({item.strip().lower() for item in skip_accounts if item.strip()})
    if not items:
        return "{}"
    return "{" + ", ".join(applescript_string_literal(item) for item in items) + "}"


def parse_osascript_kv(text: str) -> Dict[str, str]:
    payload: Dict[str, str] = {}
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        payload[key.strip()] = value
    return payload


def fetch_latest_email_payload(skip_accounts: set[str]) -> Dict[str, str]:
    skip_literal = build_skip_accounts_literal(skip_accounts)
    script = f"""
use framework "Foundation"
use scripting additions

property isoFormatter : missing value

on ensureISOFormatter()
\tif isoFormatter is missing value then
\t\tset isoFormatter to current application's NSISO8601DateFormatter's alloc()'s init()
\t\tisoFormatter's setFormatOptions_(current application's NSISO8601DateFormatWithInternetDateTime)
\tend if
end ensureISOFormatter

on isoStringFromDate(theDate)
\tmy ensureISOFormatter()
\treturn (isoFormatter's stringFromDate_(theDate)) as text
end isoStringFromDate

on oneLine(rawText)
\tif rawText is missing value then return ""
\tset safeText to rawText as text
\tset noCR to do shell script "printf '%s' " & quoted form of safeText & " | tr '\\r\\n' '  '"
\treturn noCR
end oneLine

on lowerText(rawText)
\tset safeText to my oneLine(rawText)
\tif safeText is "" then return ""
\treturn do shell script "printf '%s' " & quoted form of safeText & " | tr '[:upper:]' '[:lower:]'"
end lowerText

on inList(needle, values)
\trepeat with v in values
\t\tif needle is (v as text) then return true
\tend repeat
\treturn false
end inList

on writeUTF8(pathText, contentsText)
\tset fileRef to POSIX file pathText
\tset fileHandle to open for access fileRef with write permission
\ttry
\t\tset eof of fileHandle to 0
\t\twrite contentsText to fileHandle as «class utf8»
\ton error errMsg number errNum
\t\ttry
\t\t\tclose access fileHandle
\t\tend try
\t\terror errMsg number errNum
\tend try
\tclose access fileHandle
end writeUTF8

set skipAccounts to {skip_literal}
set foundLatest to false
set latestDate to current date - (36500 * days)
set latestID to ""
set latestSubject to ""
set latestSender to ""
set latestBody to ""
set latestMailbox to ""
set latestAccount to ""
set latestReceived to ""

tell application "Mail"
\tset accountList to accounts
end tell

repeat with acc in accountList
\ttell application "Mail" to set accName to name of acc as text
\tif my inList(my lowerText(accName), skipAccounts) then
\t\t-- skip account
\telse
\t\ttell application "Mail"
\t\t\ttry
\t\t\t\tset mailboxList to every mailbox of acc
\t\t\ton error
\t\t\t\tset mailboxList to {{}}
\t\t\tend try
\t\tend tell

\t\trepeat with mb in mailboxList
\t\t\ttell application "Mail" to set mbName to name of mb as text
\t\t\tif (my lowerText(mbName)) is "inbox" then
\t\t\t\ttell application "Mail"
\t\t\t\t\tset msgCount to count of messages of mb
\t\t\t\tend tell
\t\t\t\tif msgCount > 0 then
\t\t\t\t\ttell application "Mail"
\t\t\t\t\t\tset m to message 1 of mb
\t\t\t\t\t\tset recvDate to date received of m
\t\t\t\t\tend tell
\t\t\t\t\tif (foundLatest is false) or (recvDate > latestDate) then
\t\t\t\t\t\ttell application "Mail"
\t\t\t\t\t\t\tset latestID to id of m as text
\t\t\t\t\t\t\tset latestSubject to my oneLine(subject of m)
\t\t\t\t\t\t\tset latestSender to my oneLine(sender of m)
\t\t\t\t\t\t\tset latestBody to content of m as text
\t\t\t\t\t\t\tset latestMailbox to my oneLine(name of mailbox of m)
\t\t\t\t\t\tend tell
\t\t\t\t\t\tset latestAccount to my oneLine(accName)
\t\t\t\t\t\tset latestDate to recvDate
\t\t\t\t\t\tset latestReceived to my isoStringFromDate(recvDate)
\t\t\t\t\t\tset foundLatest to true
\t\t\t\t\tend if
\t\t\t\tend if
\t\t\tend if
\t\tend repeat
\tend if
end repeat

if foundLatest is false then
\treturn "status=empty"
end if

set tmpBodyPath to do shell script "mktemp /tmp/lazyingart_latest_body.XXXXXX.txt"
my writeUTF8(tmpBodyPath, latestBody)
set outLines to {{"status=ok", "messageID=" & latestID, "subject=" & latestSubject, "sender=" & latestSender, "receivedAt=" & latestReceived, "mailbox=" & latestMailbox, "account=" & latestAccount, "bodyPath=" & tmpBodyPath}}
set AppleScript's text item delimiters to linefeed
return outLines as text
""".strip()

    proc = subprocess.run(
        ["osascript", "-"],
        input=script,
        text=True,
        capture_output=True,
        check=True,
    )
    payload = parse_osascript_kv(proc.stdout)
    if payload.get("status") != "ok":
        raise RuntimeError("latest_message_empty")

    body_path = Path(payload.get("bodyPath", "")).expanduser()
    body_text = ""
    if body_path.exists():
        body_text = body_path.read_text(encoding="utf-8")
        body_path.unlink(missing_ok=True)

    return normalize_message(
        {
            "messageID": payload.get("messageID", ""),
            "subject": payload.get("subject", ""),
            "sender": payload.get("sender", ""),
            "receivedAt": payload.get("receivedAt", ""),
            "mailbox": payload.get("mailbox", ""),
            "account": payload.get("account", ""),
            "body": body_text,
        }
    )


def get_local_tz() -> ZoneInfo:
    tz_name = os.environ.get("LAZYINGART_LOCAL_TZ", "Asia/Hong_Kong").strip() or "Asia/Hong_Kong"
    try:
        return ZoneInfo(tz_name)
    except ZoneInfoNotFoundError:
        return ZoneInfo("UTC")


def parse_iso_datetime(value: str, local_tz: ZoneInfo) -> Optional[datetime]:
    raw = (value or "").strip()
    if not raw:
        return None
    try:
        dt = datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except ValueError:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=local_tz)
    return dt.astimezone(local_tz)


def next_weekday_date(anchor_date: datetime, weekday_idx: int) -> datetime:
    current_week_start = anchor_date - timedelta(days=anchor_date.weekday())
    target = current_week_start + timedelta(days=7 + weekday_idx)
    return target


def upcoming_weekday_date(anchor_date: datetime, weekday_idx: int) -> datetime:
    delta = (weekday_idx - anchor_date.weekday()) % 7
    if delta == 0:
        delta = 7
    return anchor_date + timedelta(days=delta)


def detect_weekday_intent(text: str) -> Optional[Tuple[int, str, str]]:
    if not text:
        return None
    lowered = text.lower()
    cn_map = {
        "一": 0,
        "二": 1,
        "三": 2,
        "四": 3,
        "五": 4,
        "六": 5,
        "日": 6,
        "天": 6,
        "1": 0,
        "2": 1,
        "3": 2,
        "4": 3,
        "5": 4,
        "6": 5,
        "7": 6,
    }
    # Chinese "next week" patterns.
    m = re.search(r"(下周|下星期|下禮拜|下礼拜)\s*([一二三四五六日天1-7])", text)
    if m:
        token = m.group(2)
        return (cn_map[token], "next_week", m.group(0))
    m = re.search(r"(周|星期|禮拜|礼拜)\s*([一二三四五六日天1-7])", text)
    if m:
        token = m.group(2)
        return (cn_map[token], "upcoming", m.group(0))

    en_map = {
        "monday": 0,
        "tuesday": 1,
        "wednesday": 2,
        "thursday": 3,
        "friday": 4,
        "saturday": 5,
        "sunday": 6,
    }
    m = re.search(
        r"(next\s+week\s+|next\s+)?(monday|tuesday|wednesday|thursday|friday|saturday|sunday)",
        lowered,
    )
    if m:
        wd = en_map[m.group(2)]
        mode = "next_week" if (m.group(1) or "").strip() else "upcoming"
        return (wd, mode, m.group(0))
    return None


def apply_weekday_correction(action: Dict[str, Any], message: Dict[str, str], now_local: datetime, local_tz: ZoneInfo) -> Dict[str, Any]:
    intent = detect_weekday_intent(f"{message.get('subject', '')}\n{message.get('body', '')}")
    if not intent:
        return action
    weekday_idx, mode, token = intent
    received_local = parse_iso_datetime(message.get("receivedAt", ""), local_tz) or now_local
    anchor = received_local
    if mode == "next_week":
        target_date = next_weekday_date(anchor, weekday_idx).date()
    else:
        target_date = upcoming_weekday_date(anchor, weekday_idx).date()

    changed_fields: list[str] = []
    for field in ("start", "end", "due"):
        field_val = str(action.get(field, "")).strip()
        if not field_val:
            continue
        dt_local = parse_iso_datetime(field_val, local_tz)
        if not dt_local:
            continue
        if dt_local.date() == target_date:
            continue
        corrected = dt_local.replace(year=target_date.year, month=target_date.month, day=target_date.day)
        action[field] = corrected.isoformat(timespec="seconds")
        changed_fields.append(field)

    if changed_fields:
        old_reason = str(action.get("reason", ""))
        if old_reason:
            action["reason"] = old_reason + f"; weekday corrected by rule token={token}"
        else:
            action["reason"] = f"weekday corrected by rule token={token}"
        logging.info(
            "weekday_corrected token=%s mode=%s target_date=%s fields=%s",
            token,
            mode,
            target_date.isoformat(),
            ",".join(changed_fields),
        )
    return action


def resolve_codex_bin(override: str = "") -> str:
    candidates: list[str] = []
    if override.strip():
        candidates.append(override.strip())
    env_bin = os.environ.get("LAZYINGART_CODEX_BIN", "").strip()
    if env_bin:
        candidates.append(env_bin)
    which_bin = shutil.which("codex")
    if which_bin:
        candidates.append(which_bin)
    home = Path.home()
    for p in sorted(home.glob(".nvm/versions/node/*/bin/codex"), reverse=True):
        candidates.append(str(p))
    candidates.extend(
        [
            "/opt/homebrew/bin/codex",
            "/usr/local/bin/codex",
            "/usr/bin/codex",
            "/bin/codex",
        ]
    )
    for candidate in candidates:
        if candidate and Path(candidate).exists() and os.access(candidate, os.X_OK):
            return candidate
    raise FileNotFoundError("codex")


def resolve_node_bin(codex_bin: str) -> str:
    node_from_path = shutil.which("node")
    if node_from_path:
        return node_from_path
    codex_dir = str(Path(codex_bin).resolve().parent)
    node_near_codex = Path(codex_dir) / "node"
    if node_near_codex.exists() and os.access(node_near_codex, os.X_OK):
        return str(node_near_codex)
    home = Path.home()
    nvm_nodes = sorted(home.glob(".nvm/versions/node/*/bin/node"), reverse=True)
    candidates = [str(path) for path in nvm_nodes]
    candidates.extend(
        [
        "/opt/homebrew/bin/node",
        "/usr/local/bin/node",
        "/usr/bin/node",
        "/bin/node",
        ]
    )
    for candidate in candidates:
        p = Path(candidate)
        if p.exists() and os.access(p, os.X_OK):
            return str(p)
    raise FileNotFoundError("node")


def build_prompt(message: Dict[str, str], now_local: datetime, received_local: datetime) -> str:
    return f"""
You are an email triage assistant for Lazyingart.

You must output EXACTLY one JSON object that matches this schema and contains no extra keys:
{json.dumps(SCHEMA, indent=2)}

Decision policy (strict):
- decision=calendar: default for items related to the user's own plan/schedule, or important events that should appear on timeline view.
  This includes personal tasks, deadlines, meetings, travel, application milestones, and important commitments.
- decision=reminder: use for general/broadcast/group emails where the user may need a nudge, but it is not clearly a personal schedule item.
  Use reminder for operational mass emails (account/security/billing/statement/system alerts) and general announcements.
- decision=note: message has useful reference info to save, but no follow-up action is needed.
- decision=skip: spam/newsletter/marketing/noise with no useful personal value.

Importance policy:
- importance=high: clearly personal, urgent, direct request, deadline-critical, or financially/security actionable.
- importance=medium: relevant and actionable but lower urgency, including broad emails that still need attention.
- importance=low: broad broadcast/newsletter/promo/group blast with no meaningful action.

Field rules:
- Always set title as concise human-readable text.
- start/end/due must be ISO8601 datetime with timezone (e.g., 2026-02-17T15:00:00+08:00) when relevant.
- For irrelevant fields, set empty string "".
- reminderMinutes must be integer 0..240.
- Default destinations unless email explicitly implies otherwise:
  - calendar: "Lachlan"
  - list: "Reminders"
- For decision=note, folder must be a nested path under Lazyingart in this format:
  - "Lazyingart/<Flexible>/<Flexible...>"
  - examples:
    - "Lazyingart/Inbox"
    - "Lazyingart/Work/Meetings"
    - "Lazyingart/School/HKU"
  - Keep the part after "Lazyingart/" flexible based on email context.
  - if unclear, use "Lazyingart/Inbox".
- For decision=calendar/reminder/skip, set folder to empty string "".
- For bank/payment/financial transaction emails (bank alerts, card spend, receipts, statements):
  - prefer decision=note for bookkeeping, unless urgent action is required (then use reminder).
  - use folder format: "Lazyingart/Finance/YYYY-MM-DD" (transaction date if available; otherwise received date).
  - use title format: "Finance Ledger YYYY-MM-DD".
  - include structured spending details in notes (merchant, amount, currency, channel/card, reference).
  - if it is the same date as another finance record, keep the same folder and title so entries can be grouped in one daily ledger note if possible.
- notes should summarize key details from the email.
- reason should briefly justify decision.
- Prefer calendar when event is related to the user personally, even if exact time is unclear.
- For travel/flight/train/hotel itinerary emails:
  - if email includes outbound + return, set calendar `start` to outbound departure datetime and `end` to return arrival datetime (trip range).
  - if return arrival is missing, use return departure as `end`.
  - if one-way with multiple legs, set `start` to first leg departure and `end` to final leg arrival.
  - include both outbound and return segment details in `notes`.
- If time is unclear but date is known for a calendar-worthy personal event, create a reasonable placeholder local time block and mention that in notes.
- For mass/group/general events, prefer reminder; use note only when archival value exists and no reminder is needed.
- If importance is low, avoid calendar unless there is clear personal impact.
- Resolve relative dates against current local datetime.
- If the email mentions weekday terms (e.g., Wednesday / Friday / 周三 / 下周5), ensure the chosen date actually matches that weekday.
- For Chinese weekday phrases, treat "下周X" as weekday X in next calendar week.
- Prefer local timezone offset in start/end/due (avoid UTC unless email explicitly uses UTC).

Current local datetime:
- {now_local.isoformat(timespec="seconds")}
Email received datetime in local timezone:
- {received_local.isoformat(timespec="seconds")}

Email metadata:
- sender: {message['sender']}
- subject: {message['subject']}
- receivedAt: {message['receivedAt']}
- mailbox: {message['mailbox']}
- account: {message['account']}

Email body (full text):
{message['body']}
""".strip()


def run_codex(
    prompt: str,
    output_path: Path,
    model: str,
    reasoning: str,
    codex_bin_override: str = "",
) -> Dict[str, Any]:
    codex_bin = resolve_codex_bin(codex_bin_override)
    node_bin = resolve_node_bin(codex_bin)
    codex_dir = str(Path(codex_bin).resolve().parent)
    node_dir = str(Path(node_bin).resolve().parent)
    with tempfile.NamedTemporaryFile(mode="w", delete=False, encoding="utf-8") as schema_file:
        schema_file.write(json.dumps(SCHEMA, indent=2))
        schema_path = Path(schema_file.name)

    cmd = [
        node_bin,
        codex_bin,
        "exec",
        "--model",
        model,
        "-c",
        f'model_reasoning_effort="{reasoning}"',
        "--skip-git-repo-check",
        "--output-schema",
        str(schema_path),
        "--output-last-message",
        str(output_path),
        "-",
    ]
    env = os.environ.copy()
    base_paths = [node_dir, codex_dir, "/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin", "/usr/sbin", "/sbin"]
    merged_paths = []
    for path in base_paths:
        if path and path not in merged_paths:
            merged_paths.append(path)
    old_path = env.get("PATH", "")
    for piece in old_path.split(":"):
        if piece and piece not in merged_paths:
            merged_paths.append(piece)
    env["PATH"] = ":".join(merged_paths)

    try:
        proc = subprocess.run(cmd, input=prompt, text=True, capture_output=True, check=True, env=env)
    finally:
        schema_path.unlink(missing_ok=True)

    if proc.stdout.strip():
        logging.info("codex_stdout: %s", proc.stdout.strip()[:1000])
    if proc.stderr.strip():
        logging.info("codex_stderr: %s", proc.stderr.strip()[:1000])

    text = output_path.read_text(encoding="utf-8")
    parsed = parse_codex_json_text(text)
    normalized = normalize_action(parsed)
    write_json(output_path, normalized)
    return normalized


def enforce_low_importance_policy(action: Dict[str, Any], message: Dict[str, str]) -> Dict[str, Any]:
    if action["importance"] == "low" and action["decision"] in {"calendar", "reminder"}:
        old_decision = action["decision"]
        action["decision"] = "note"
        if not action.get("folder"):
            action["folder"] = "Lazyingart/Inbox/LowPriority"
        if not action.get("notes"):
            action["notes"] = (
                f"Low-importance email saved as note.\n"
                f"From: {message.get('sender', '')}\n"
                f"Subject: {message.get('subject', '')}"
            )
        if action.get("reason"):
            action["reason"] = action["reason"] + "; auto-downgraded to note because importance=low"
        else:
            action["reason"] = "auto-downgraded to note because importance=low"
        logging.info(
            "decision_downgraded importance=low old_decision=%s new_decision=%s",
            old_decision,
            action["decision"],
        )
    return action


def apply_action(action_json_path: Path, message_json_path: Path) -> Dict[str, Any]:
    if not APPLY_SCRIPT.exists():
        raise FileNotFoundError(f"Missing action script: {APPLY_SCRIPT}")
    cmd = [
        sys.executable,
        str(APPLY_SCRIPT),
        "--action-json",
        str(action_json_path),
        "--message-json",
        str(message_json_path),
    ]
    proc = subprocess.run(cmd, text=True, capture_output=True, check=True)
    if proc.stderr.strip():
        logging.info("apply_stderr: %s", proc.stderr.strip()[:1000])
    stdout = proc.stdout.strip()
    if not stdout:
        return {"status": "ok", "detail": "no output"}
    try:
        payload = json.loads(stdout)
        if isinstance(payload, dict):
            return payload
    except json.JSONDecodeError:
        pass
    return {"status": "ok", "detail": stdout}


def main() -> None:
    parser = argparse.ArgumentParser(description="Lazyingart Simple Codex pipeline.")
    input_group = parser.add_mutually_exclusive_group(required=True)
    input_group.add_argument("--message-json", help="Path to single email JSON payload")
    input_group.add_argument(
        "--latest-email",
        action="store_true",
        help="Fetch latest inbox email from Mail directly, then run pipeline",
    )
    parser.add_argument(
        "--skip-accounts",
        default="qq",
        help="Comma-separated account names to skip in --latest-email mode (default: qq)",
    )
    parser.add_argument("--log-level", default="INFO")
    parser.add_argument("--model", default=MODEL)
    parser.add_argument("--reasoning", default=REASONING)
    parser.add_argument("--codex-bin", default="")
    args = parser.parse_args()

    setup_logging(args.log_level)

    source_ref = ""
    if args.latest_email:
        skip_accounts = {item.strip().lower() for item in args.skip_accounts.split(",") if item.strip()}
        try:
            message = fetch_latest_email_payload(skip_accounts)
        except subprocess.CalledProcessError as exc:
            logging.error("latest_fetch_failed code=%s stderr=%s", exc.returncode, (exc.stderr or "").strip()[:2000])
            sys.exit(1)
        except Exception as exc:
            logging.error("latest_fetch_failed err=%s", exc)
            sys.exit(1)
        source_ref = f"mail_latest(skip_accounts={','.join(sorted(skip_accounts))})"
    else:
        source_path = Path(str(args.message_json)).expanduser()
        source_ref = str(source_path)
        if not source_path.exists():
            logging.error("message_json_missing path=%s", source_path)
            sys.exit(1)

        try:
            raw_message = read_json(source_path)
            message = normalize_message(raw_message)
        except Exception as exc:
            logging.error("message_parse_failed path=%s err=%s", source_path, exc)
            sys.exit(1)

    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    message_token = safe_token(message.get("messageID", ""))
    run_id = f"{timestamp}-{message_token}"
    message_id = message.get("messageID", "")
    processed_ids = load_processed_ids()

    inbound_path = INBOUND_DIR / f"{run_id}.json"
    prompt_path = PROMPT_DIR / f"{run_id}.txt"
    codex_output_path = CODEX_DIR / f"{run_id}.json"
    result_path = RESULT_DIR / f"{run_id}.json"

    write_json(inbound_path, message)
    shutil.copyfile(inbound_path, INBOUND_DIR / "latest.json")

    if message_id and message_id in processed_ids:
        duplicate_result = {
            "run_id": run_id,
            "message_id": message_id,
            "decision": "skip",
            "importance": "low",
            "action_json_path": "",
            "apply_result": {
                "status": "skipped_duplicate",
                "target": "none",
                "reason": "message_id already processed",
                "first_run_id": processed_ids[message_id].get("run_id", ""),
            },
            "timestamp": datetime.now().isoformat(),
        }
        write_json(result_path, duplicate_result)
        shutil.copyfile(result_path, RESULT_DIR / "latest.json")
        logging.info(
            "pipeline_skip_duplicate run_id=%s message_id=%s first_run_id=%s",
            run_id,
            message_id,
            processed_ids[message_id].get("run_id", ""),
        )
        print(json.dumps(duplicate_result, ensure_ascii=False))
        return

    local_tz = get_local_tz()
    now_local = datetime.now(local_tz)
    received_local = parse_iso_datetime(message.get("receivedAt", ""), local_tz) or now_local

    prompt = build_prompt(message, now_local, received_local)
    prompt_path.write_text(prompt + "\n", encoding="utf-8")
    shutil.copyfile(prompt_path, PROMPT_DIR / "latest.txt")

    logging.info(
        "pipeline_start run_id=%s message_id=%s source=%s inbound=%s codex_out=%s codex_bin=%s",
        run_id,
        message.get("messageID", ""),
        source_ref,
        inbound_path,
        codex_output_path,
        args.codex_bin or os.environ.get("LAZYINGART_CODEX_BIN", "") or "auto",
    )

    try:
        action = run_codex(prompt, codex_output_path, args.model, args.reasoning, args.codex_bin)
    except subprocess.CalledProcessError as exc:
        logging.error("codex_exec_failed run_id=%s code=%s", run_id, exc.returncode)
        if exc.stderr:
            logging.error("codex_exec_stderr=%s", exc.stderr.strip()[:2000])
        sys.exit(1)
    except Exception as exc:
        logging.error("codex_output_invalid run_id=%s err=%s", run_id, exc)
        sys.exit(1)

    action = enforce_low_importance_policy(action, message)
    action = apply_weekday_correction(action, message, now_local, local_tz)
    write_json(codex_output_path, action)

    shutil.copyfile(codex_output_path, CODEX_DIR / "latest.json")
    logging.info(
        "codex_action_ready run_id=%s decision=%s importance=%s action_path=%s",
        run_id,
        action["decision"],
        action["importance"],
        codex_output_path,
    )

    try:
        apply_result = apply_action(codex_output_path, inbound_path)
    except subprocess.CalledProcessError as exc:
        logging.error("apply_failed run_id=%s code=%s", run_id, exc.returncode)
        if exc.stderr:
            logging.error("apply_stderr=%s", exc.stderr.strip()[:2000])
        sys.exit(1)
    except Exception as exc:
        logging.error("apply_exception run_id=%s err=%s", run_id, exc)
        sys.exit(1)

    result_payload = {
        "run_id": run_id,
        "message_id": message_id,
        "decision": action["decision"],
        "importance": action["importance"],
        "action_json_path": str(codex_output_path),
        "apply_result": apply_result,
        "timestamp": datetime.now().isoformat(),
    }
    if message_id:
        processed_ids[message_id] = {
            "timestamp": result_payload["timestamp"],
            "run_id": run_id,
            "decision": action["decision"],
        }
        save_processed_ids(processed_ids)
    write_json(result_path, result_payload)
    shutil.copyfile(result_path, RESULT_DIR / "latest.json")

    logging.info(
        "pipeline_done run_id=%s decision=%s result=%s",
        run_id,
        action["decision"],
        apply_result,
    )
    print(json.dumps(result_payload, ensure_ascii=False))


if __name__ == "__main__":
    main()
