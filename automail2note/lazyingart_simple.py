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
NOTE_SCRIPT = AUTOMATION_DIR / "create_note.applescript"

MODEL = "gpt-5.1-codex-mini"
REASONING = "medium"
LOG_NOTE_ROOT = "Lazyingart/Log"
DEFAULT_CALENDAR = "LazyingArt"
DEFAULT_REMINDER_LIST = "LazyingArt"
LEGACY_CALENDAR_PLACEHOLDERS = {"lachlan", "calendar"}
HARD_BLOCKED_ACCOUNTS = {"qq"}
HARD_BLOCKED_SENDER_EMAILS = {"lachchen@qq.com"}

ACTION_SCHEMA: Dict[str, Any] = {
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

SCHEMA: Dict[str, Any] = {
    "type": "object",
    "additionalProperties": False,
    "required": ["actions"],
    "properties": {
        "actions": {
            "type": "array",
            "minItems": 1,
            "maxItems": 10,
            "items": ACTION_SCHEMA,
        }
    },
}

LATEST_EMAIL_FETCH_SCHEMA: Dict[str, Any] = {
    "type": "object",
    "additionalProperties": False,
    "required": [
        "status",
        "reason",
        "attempts",
        "messageID",
        "subject",
        "sender",
        "receivedAt",
        "mailbox",
        "account",
        "body",
    ],
    "properties": {
        "status": {"type": "string", "enum": ["ok", "not_found", "error"]},
        "reason": {"type": "string"},
        "attempts": {"type": "integer", "minimum": 0},
        "messageID": {"type": "string"},
        "subject": {"type": "string"},
        "sender": {"type": "string"},
        "receivedAt": {"type": "string"},
        "mailbox": {"type": "string"},
        "account": {"type": "string"},
        "body": {"type": "string"},
    },
}

STRONG_SAVE_SCHEMA: Dict[str, Any] = {
    "type": "object",
    "additionalProperties": False,
    "required": ["status", "mode", "actions_count", "created", "skipped", "failed", "item_results", "log_note_result", "summary"],
    "properties": {
        "status": {"type": "string", "enum": ["ok", "partial", "failed"]},
        "mode": {"type": "string", "enum": ["strong_smart_save"]},
        "actions_count": {"type": "integer", "minimum": 0},
        "created": {"type": "integer", "minimum": 0},
        "skipped": {"type": "integer", "minimum": 0},
        "failed": {"type": "integer", "minimum": 0},
        "summary": {"type": "string"},
        "item_results": {
            "type": "array",
            "items": {
                "type": "object",
                "additionalProperties": False,
                "required": ["index", "decision", "title", "status", "target", "id", "fingerprint", "reason", "error"],
                "properties": {
                    "index": {"type": "integer", "minimum": 1},
                    "decision": {"type": "string", "enum": ["calendar", "reminder", "note", "skip"]},
                    "title": {"type": "string"},
                    "status": {"type": "string", "enum": ["created", "skipped", "failed"]},
                    "target": {"type": "string"},
                    "id": {"type": "string"},
                    "fingerprint": {"type": "string"},
                    "reason": {"type": "string"},
                    "error": {"type": "string"},
                },
            },
        },
        "log_note_result": {
            "type": "object",
            "additionalProperties": False,
            "required": ["status", "folder", "title", "id", "error"],
            "properties": {
                "status": {"type": "string", "enum": ["created", "failed", "skipped"]},
                "folder": {"type": "string"},
                "title": {"type": "string"},
                "id": {"type": "string"},
                "error": {"type": "string"},
            },
        },
    },
}

REQUIRED_ACTION_KEYS = set(ACTION_SCHEMA["required"])
DEFAULT_FLAG_INDEX_BY_DECISION = {
    "note": 2,  # Yellow
    "calendar": 4,  # Blue
    "reminder": 4,  # Blue
    "skip": 6,  # Gray
}
ACTION_FINGERPRINTS_PATH = STATE_DIR / "action_fingerprints.json"


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


def load_action_fingerprints() -> Dict[str, Dict[str, str]]:
    if not ACTION_FINGERPRINTS_PATH.exists():
        return {}
    try:
        payload = json.loads(ACTION_FINGERPRINTS_PATH.read_text(encoding="utf-8"))
    except Exception:
        logging.warning("action_fingerprints_read_failed path=%s", ACTION_FINGERPRINTS_PATH)
        return {}
    if not isinstance(payload, dict):
        return {}
    result: Dict[str, Dict[str, str]] = {}
    for key, value in payload.items():
        if not isinstance(key, str) or not isinstance(value, dict):
            continue
        result[key] = {str(k): str(v) for k, v in value.items() if isinstance(k, str)}
    return result


def save_action_fingerprints(fingerprints: Dict[str, Dict[str, str]]) -> None:
    ACTION_FINGERPRINTS_PATH.parent.mkdir(parents=True, exist_ok=True)
    ACTION_FINGERPRINTS_PATH.write_text(json.dumps(fingerprints, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


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
    missing = REQUIRED_ACTION_KEYS - keys
    extra = keys - REQUIRED_ACTION_KEYS
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


def normalize_codex_actions(payload: Dict[str, Any]) -> list[Dict[str, Any]]:
    # Backward compatibility: accept either {"actions":[...]} or one action object.
    if "actions" in payload:
        raw_actions = payload.get("actions")
        if not isinstance(raw_actions, list) or not raw_actions:
            raise ValueError("Codex output actions must be a non-empty array")
        actions: list[Dict[str, Any]] = []
        for idx, item in enumerate(raw_actions, start=1):
            if not isinstance(item, dict):
                raise ValueError(f"Action #{idx} is not an object")
            actions.append(normalize_action(item))
        return actions
    return [normalize_action(payload)]


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


def parse_sender_email(sender_text: str) -> str:
    raw = (sender_text or "").strip().lower()
    if not raw:
        return ""
    angle = re.search(r"<\s*([^>\s]+@[^>\s]+)\s*>", raw)
    if angle:
        return angle.group(1).strip().lower()
    direct = re.search(r"([a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,})", raw)
    if direct:
        return direct.group(1).strip().lower()
    return ""


def should_skip_message_early(message: Dict[str, str], skip_accounts: set[str]) -> tuple[bool, str]:
    account_name = str(message.get("account", "")).strip().lower()
    effective_skip_accounts = {item.strip().lower() for item in skip_accounts if item.strip()} | HARD_BLOCKED_ACCOUNTS
    if account_name and account_name in effective_skip_accounts:
        return True, f"blocked_account:{account_name}"
    sender_email = parse_sender_email(str(message.get("sender", "")))
    if sender_email and sender_email in HARD_BLOCKED_SENDER_EMAILS:
        return True, f"blocked_sender:{sender_email}"
    return False, ""


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


def fetch_recent_email_candidates(skip_accounts: set[str], per_inbox_limit: int = 12) -> list[Dict[str, str]]:
    effective_skip_accounts = set(skip_accounts) | HARD_BLOCKED_ACCOUNTS
    skip_literal = build_skip_accounts_literal(effective_skip_accounts)
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
\treturn do shell script "printf '%s' " & quoted form of safeText & " | tr '\\r\\n' '  '"
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

set skipAccounts to {skip_literal}
set perInboxLimit to {max(1, int(per_inbox_limit))}
set recSep to character id 30
set fieldSep to character id 31
set outText to ""

tell application "Mail"
\tset accountList to accounts
end tell

repeat with acc in accountList
\ttell application "Mail" to set accName to name of acc as text
\tif my inList(my lowerText(accName), skipAccounts) then
\t\t-- skip
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
\t\t\t\ttell application "Mail" to set msgCount to count of messages of mb
\t\t\t\tif msgCount > 0 then
\t\t\t\t\tset scanCount to perInboxLimit
\t\t\t\t\tif scanCount > msgCount then set scanCount to msgCount
\t\t\t\t\trepeat with idx from 1 to scanCount
\t\t\t\t\t\ttry
\t\t\t\t\t\t\ttell application "Mail"
\t\t\t\t\t\t\t\tset m to message idx of mb
\t\t\t\t\t\t\t\tset messageIDText to id of m as text
\t\t\t\t\t\t\t\tset subjectText to ""
\t\t\t\t\t\t\t\tset senderText to ""
\t\t\t\t\t\t\t\ttry
\t\t\t\t\t\t\t\t\tset subjectText to my oneLine(subject of m as text)
\t\t\t\t\t\t\t\tend try
\t\t\t\t\t\t\t\ttry
\t\t\t\t\t\t\t\t\tset senderText to my oneLine(sender of m as text)
\t\t\t\t\t\t\t\tend try
\t\t\t\t\t\t\t\tset recvDate to date received of m
\t\t\t\t\t\t\t\tset recvText to my isoStringFromDate(recvDate)
\t\t\t\t\t\t\tend tell
\t\t\t\t\t\t\tset outText to outText & messageIDText & fieldSep & subjectText & fieldSep & senderText & fieldSep & recvText & fieldSep & (my oneLine(mbName)) & fieldSep & (my oneLine(accName)) & recSep
\t\t\t\t\t\ton error
\t\t\t\t\t\t\t-- skip invalid reference
\t\t\t\t\t\tend try
\t\t\t\t\tend repeat
\t\t\t\tend if
\t\t\tend if
\t\tend repeat
\tend if
end repeat

return outText
""".strip()

    proc = subprocess.run(
        ["osascript", "-"],
        input=script,
        text=True,
        capture_output=True,
        check=True,
    )
    rec_sep = chr(30)
    field_sep = chr(31)
    candidates: list[Dict[str, str]] = []
    for rec in proc.stdout.split(rec_sep):
        if not rec.strip():
            continue
        parts = rec.split(field_sep)
        if len(parts) < 6:
            continue
        candidates.append(
            normalize_message(
                {
                    "messageID": parts[0],
                    "subject": parts[1],
                    "sender": parts[2],
                    "receivedAt": parts[3],
                    "mailbox": parts[4],
                    "account": parts[5],
                    "body": "",
                }
            )
        )
    return candidates


def fetch_message_payload_by_locator(message_id: str, account_name: str, mailbox_name: str) -> Dict[str, str]:
    script = r"""
use framework "Foundation"
use scripting additions

property isoFormatter : missing value

on ensureISOFormatter()
	if isoFormatter is missing value then
		set isoFormatter to current application's NSISO8601DateFormatter's alloc()'s init()
		isoFormatter's setFormatOptions_(current application's NSISO8601DateFormatWithInternetDateTime)
	end if
end ensureISOFormatter

on isoStringFromDate(theDate)
	my ensureISOFormatter()
	return (isoFormatter's stringFromDate_(theDate)) as text
end isoStringFromDate

on oneLine(rawText)
	if rawText is missing value then return ""
	set safeText to rawText as text
	return do shell script "printf '%s' " & quoted form of safeText & " | tr '\r\n' '  '"
end oneLine

on writeUTF8(pathText, contentsText)
	set fileRef to POSIX file pathText
	set fileHandle to open for access fileRef with write permission
	try
		set eof of fileHandle to 0
		write contentsText to fileHandle as «class utf8»
	on error errMsg number errNum
		try
			close access fileHandle
		end try
		error errMsg number errNum
	end try
	close access fileHandle
end writeUTF8

on run argv
	set messageIDRaw to item 1 of argv
	set accountName to item 2 of argv
	set mailboxName to item 3 of argv

	tell application "Mail"
		set targetAccount to missing value
		repeat with a in accounts
			if (name of a as text) is accountName then
				set targetAccount to a
				exit repeat
			end if
		end repeat
		if targetAccount is missing value then return "status=account_not_found"

		set mailboxCandidates to {}
		if mailboxName is not "" then
			repeat with mb in every mailbox of targetAccount
				if (name of mb as text) is mailboxName then
					set end of mailboxCandidates to mb
				end if
			end repeat
		end if
		if (count of mailboxCandidates) is 0 then set mailboxCandidates to every mailbox of targetAccount

		set targetMsg to missing value
		set idNum to missing value
		try
			set idNum to messageIDRaw as integer
		end try

		if idNum is not missing value then
			repeat with mb in mailboxCandidates
				try
					set targetMsg to first message of mb whose id is idNum
				end try
				if targetMsg is not missing value then exit repeat
			end repeat
		end if

		if targetMsg is missing value then
			repeat with mb in mailboxCandidates
				try
					set targetMsg to first message of mb whose message id is messageIDRaw
				end try
				if targetMsg is not missing value then exit repeat
			end repeat
		end if

		if targetMsg is missing value then
			repeat with mb in every mailbox of targetAccount
				try
					if idNum is not missing value then
						set targetMsg to first message of mb whose id is idNum
					else
						set targetMsg to first message of mb whose message id is messageIDRaw
					end if
				end try
				if targetMsg is not missing value then exit repeat
			end repeat
		end if

		if targetMsg is missing value then return "status=message_not_found"

		set actualMessageID to id of targetMsg as text
		set subjectText to ""
		set senderText to ""
		try
			set subjectText to my oneLine(subject of targetMsg as text)
		end try
		try
			set senderText to my oneLine(sender of targetMsg as text)
		end try
		set recvText to my isoStringFromDate(date received of targetMsg)
		set mailboxText to my oneLine(name of mailbox of targetMsg)
		set accountText to my oneLine(name of account of mailbox of targetMsg)
		set bodyText to content of targetMsg as text
	end tell

	set tmpBodyPath to do shell script "mktemp /tmp/lazyingart_latest_body.XXXXXX.txt"
	my writeUTF8(tmpBodyPath, bodyText)
	set outLines to {"status=ok", "messageID=" & actualMessageID, "subject=" & subjectText, "sender=" & senderText, "receivedAt=" & recvText, "mailbox=" & mailboxText, "account=" & accountText, "bodyPath=" & tmpBodyPath}
	set AppleScript's text item delimiters to linefeed
	return outLines as text
end run
""".strip()

    proc = subprocess.run(
        ["osascript", "-", message_id, account_name, mailbox_name],
        input=script,
        text=True,
        capture_output=True,
        check=True,
    )
    payload = parse_osascript_kv(proc.stdout)
    if payload.get("status") != "ok":
        raise RuntimeError(payload.get("status", "message_not_found"))
    body_path = Path(payload.get("bodyPath", "")).expanduser()
    body_text = body_path.read_text(encoding="utf-8") if body_path.exists() else ""
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


def norm_token(value: str) -> str:
    return re.sub(r"\s+", " ", str(value or "").strip().lower())


def resolve_effective_calendar(action: Dict[str, Any], default_calendar: str) -> str:
    requested = str(action.get("calendar", "") or "").strip()
    configured = (default_calendar or "").strip()
    if configured:
        if not requested or requested.lower() in LEGACY_CALENDAR_PLACEHOLDERS:
            return configured
    if requested:
        return requested
    if configured:
        return configured
    return DEFAULT_CALENDAR


def action_fingerprint(action: Dict[str, Any], default_calendar: str) -> str:
    decision = str(action.get("decision", "")).strip().lower()
    title = norm_token(str(action.get("title", "")))
    if decision == "calendar":
        start = norm_token(str(action.get("start", "")))
        end = norm_token(str(action.get("end", "")))
        cal = norm_token(resolve_effective_calendar(action, default_calendar))
        return f"calendar|{title}|{start}|{end}|{cal}"
    if decision == "reminder":
        due = norm_token(str(action.get("due", "")))
        lst = norm_token(str(action.get("list", "")))
        return f"reminder|{title}|{due}|{lst}"
    if decision == "note":
        folder = norm_token(str(action.get("folder", "")))
        note_preview = norm_token(str(action.get("notes", "")))[:120]
        return f"note|{title}|{folder}|{note_preview}"
    if decision == "skip":
        reason = norm_token(str(action.get("reason", "")))[:120]
        return f"skip|{title}|{reason}"
    return f"other|{decision}|{title}"


def summarize_recent_items_for_prompt(fingerprints: Dict[str, Dict[str, str]], limit: int = 80) -> str:
    rows = sorted(
        fingerprints.values(),
        key=lambda item: item.get("timestamp", ""),
        reverse=True,
    )
    lines: list[str] = []
    for item in rows[:limit]:
        lines.append(
            "- decision={decision}; title={title}; start={start}; end={end}; due={due}; calendar={calendar}; list={list}; folder={folder}".format(
                decision=item.get("decision", ""),
                title=item.get("title", ""),
                start=item.get("start", ""),
                end=item.get("end", ""),
                due=item.get("due", ""),
                calendar=item.get("calendar", ""),
                list=item.get("list", ""),
                folder=item.get("folder", ""),
            )
        )
    return "\n".join(lines) if lines else "- (none)"


def fetch_notes_index(account: str = "iCloud", limit: int = 200) -> list[Dict[str, str]]:
    script = r"""
on run argv
	set accountName to item 1 of argv
	set recSep to character id 30
	set fieldSep to character id 31
	set outText to ""
	tell application "Notes"
		set targetAccount to account accountName
		repeat with f in folders of targetAccount
			set folderName to name of f as text
			if folderName is not "Recently Deleted" then
				repeat with n in notes of f
					set noteID to id of n as text
					set noteTitle to name of n as text
					set noteText to ""
					try
						set noteText to plaintext of n as text
					end try
					set outText to outText & noteID & fieldSep & folderName & fieldSep & noteTitle & fieldSep & noteText & recSep
				end repeat
			end if
		end repeat
	end tell
	return outText
end run
""".strip()
    try:
        proc = subprocess.run(
            ["osascript", "-", account],
            input=script,
            text=True,
            capture_output=True,
            check=True,
        )
    except Exception as exc:
        logging.warning("notes_index_fetch_failed account=%s err=%s", account, exc)
        return []

    rec_sep = chr(30)
    field_sep = chr(31)
    rows: list[Dict[str, str]] = []
    for rec in proc.stdout.split(rec_sep):
        if not rec.strip():
            continue
        parts = rec.split(field_sep)
        if len(parts) < 4:
            continue
        note_text = re.sub(r"\s+", " ", parts[3]).strip()
        rows.append(
            {
                "id": parts[0],
                "folder": parts[1],
                "title": parts[2],
                "preview": note_text[:200],
            }
        )
        if len(rows) >= limit:
            break
    return rows


def summarize_notes_for_prompt(notes: list[Dict[str, str]], limit: int = 120) -> str:
    if not notes:
        return "- (none)"
    lines: list[str] = []
    for row in notes[:limit]:
        lines.append(
            "- folder={folder}; title={title}; preview={preview}".format(
                folder=row.get("folder", ""),
                title=row.get("title", ""),
                preview=row.get("preview", ""),
            )
        )
    return "\n".join(lines)


def summarize_item_counts(result_payload: Dict[str, Any]) -> tuple[int, int, int]:
    item_results = result_payload.get("item_results")
    if not isinstance(item_results, list):
        apply_result = result_payload.get("apply_result", {})
        if isinstance(apply_result, dict):
            status = str(apply_result.get("status", ""))
        else:
            status = str(apply_result)
        if status == "created":
            return (1, 0, 0)
        if status == "failed":
            return (0, 0, 1)
        return (0, 1, 0)

    created = sum(1 for item in item_results if str(item.get("status", "")).strip() == "created")
    failed = sum(1 for item in item_results if str(item.get("status", "")).strip() == "failed")
    skipped = len(item_results) - created - failed
    return (created, skipped, failed)


def build_processing_log_text(
    message: Dict[str, str],
    result_payload: Dict[str, Any],
    save_mode: str,
    now_local: datetime,
) -> str:
    created, skipped, failed = summarize_item_counts(result_payload)
    lines: list[str] = [
        f"Run: {result_payload.get('run_id', '')}",
        f"When: {now_local.isoformat(timespec='seconds')}",
        f"Mode: {save_mode}",
        f"MessageID: {message.get('messageID', '')}",
        f"From: {message.get('sender', '')}",
        f"Subject: {message.get('subject', '')}",
        f"ReceivedAt: {message.get('receivedAt', '')}",
        f"Decision: {result_payload.get('decision', '')}",
        f"Actions: {result_payload.get('actions_count', 0)}",
        f"Created: {created}  Skipped: {skipped}  Failed: {failed}",
        f"Flag: {json.dumps(result_payload.get('flag_result', {}), ensure_ascii=False)}",
    ]

    item_results = result_payload.get("item_results")
    if isinstance(item_results, list) and item_results:
        lines.append("")
        lines.append("Item results:")
        for item in item_results:
            lines.append(
                "- #{idx} {decision} | {status} | {title}".format(
                    idx=item.get("index", ""),
                    decision=item.get("decision", ""),
                    status=item.get("status", ""),
                    title=item.get("title", ""),
                )
            )

    return "\n".join(lines).strip()


def write_processing_log_note(
    message: Dict[str, str],
    result_payload: Dict[str, Any],
    save_mode: str,
    local_tz: ZoneInfo,
) -> Dict[str, Any]:
    if not NOTE_SCRIPT.exists():
        return {"status": "skipped", "reason": f"missing_note_script:{NOTE_SCRIPT}"}

    now_local = datetime.now(local_tz)
    day_key = now_local.date().isoformat()
    folder = f"{LOG_NOTE_ROOT}/{day_key}"
    title = f"Mail Log {day_key}"
    body = build_processing_log_text(message, result_payload, save_mode, now_local)

    try:
        proc = subprocess.run(
            ["osascript", str(NOTE_SCRIPT), title, body, folder, "prepend"],
            text=True,
            capture_output=True,
            check=True,
        )
        result: Dict[str, Any] = {
            "status": "created",
            "folder": folder,
            "title": title,
            "id": proc.stdout.strip(),
        }
        if proc.stderr.strip():
            result["stderr"] = proc.stderr.strip()
        return result
    except subprocess.CalledProcessError as exc:
        return {
            "status": "failed",
            "folder": folder,
            "title": title,
            "error": (exc.stderr or exc.stdout or str(exc)).strip(),
        }


def choose_flag_decision(actions: list[Dict[str, Any]]) -> str:
    decisions = {str(item.get("decision", "")).strip().lower() for item in actions}
    if "calendar" in decisions or "reminder" in decisions:
        return "calendar"
    if "note" in decisions:
        return "note"
    return "skip"


def bootstrap_action_fingerprints_from_results(
    fingerprints: Dict[str, Dict[str, str]],
    default_calendar: str,
    limit: int = 200,
) -> int:
    result_files = sorted(RESULT_DIR.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True)
    added = 0
    for result_path in result_files[:limit]:
        try:
            payload = json.loads(result_path.read_text(encoding="utf-8"))
        except Exception:
            continue
        if not isinstance(payload, dict):
            continue
        action_path_raw = str(payload.get("action_json_path", "")).strip()
        if not action_path_raw:
            continue
        action_path = Path(action_path_raw)
        if not action_path.exists():
            continue
        try:
            action_payload = json.loads(action_path.read_text(encoding="utf-8"))
        except Exception:
            continue
        if not isinstance(action_payload, dict):
            continue
        try:
            actions = normalize_codex_actions(action_payload)
        except Exception:
            continue
        for action in actions:
            if action.get("decision") == "skip":
                continue
            fp = action_fingerprint(action, default_calendar)
            if fp in fingerprints:
                continue
            fingerprints[fp] = {
                "timestamp": str(payload.get("timestamp", "")),
                "run_id": str(payload.get("run_id", "")),
                "message_id": str(payload.get("message_id", "")),
                "decision": str(action.get("decision", "")),
                "title": str(action.get("title", "")),
                "start": str(action.get("start", "")),
                "end": str(action.get("end", "")),
                "due": str(action.get("due", "")),
                "calendar": resolve_effective_calendar(action, default_calendar),
                "list": str(action.get("list", "")),
                "folder": str(action.get("folder", "")),
            }
            added += 1
    return added


def resolve_flag_index(decision: str) -> Optional[int]:
    normalized = str(decision or "").strip().lower()
    fallback = DEFAULT_FLAG_INDEX_BY_DECISION.get(normalized)
    if fallback is None:
        return None

    env_key_by_decision = {
        "note": "LAZYINGART_FLAG_NOTE_INDEX",
        "calendar": "LAZYINGART_FLAG_CALENDAR_INDEX",
        "reminder": "LAZYINGART_FLAG_REMINDER_INDEX",
        "skip": "LAZYINGART_FLAG_SKIP_INDEX",
    }
    raw = os.environ.get(env_key_by_decision[normalized], "").strip()
    if not raw:
        return fallback
    try:
        val = int(raw)
    except ValueError:
        logging.warning("flag_index_env_invalid decision=%s value=%s using_default=%s", normalized, raw, fallback)
        return fallback
    if not (0 <= val <= 6):
        logging.warning("flag_index_out_of_range decision=%s value=%s using_default=%s", normalized, val, fallback)
        return fallback
    return val


def apply_decision_flag(message: Dict[str, str], decision: str) -> Dict[str, Any]:
    flag_index = resolve_flag_index(decision)
    if flag_index is None:
        return {"status": "skipped", "reason": "unsupported_decision"}

    message_id = str(message.get("messageID", "")).strip()
    account_name = str(message.get("account", "")).strip()
    mailbox_name = str(message.get("mailbox", "")).strip()
    if not message_id or not account_name:
        return {"status": "skipped", "reason": "missing_message_locator"}

    script = r"""
on run argv
	if (count of argv) < 4 then return "status=invalid_args"
	set messageIDRaw to (item 1 of argv) as text
	set accountName to (item 2 of argv) as text
	set mailboxName to (item 3 of argv) as text
	set flagIndexText to (item 4 of argv) as text
	try
		set targetFlagIndex to flagIndexText as integer
	on error
		return "status=invalid_flag_index"
	end try

	tell application "Mail"
		set targetAccount to missing value
		repeat with a in accounts
			if (name of a as text) is accountName then
				set targetAccount to a
				exit repeat
			end if
		end repeat
		if targetAccount is missing value then return "status=account_not_found"

		set mailboxCandidates to {}
		if mailboxName is not "" then
			repeat with mb in every mailbox of targetAccount
				if (name of mb as text) is mailboxName then
					set end of mailboxCandidates to mb
				end if
			end repeat
		end if
		if (count of mailboxCandidates) is 0 then
			set mailboxCandidates to every mailbox of targetAccount
		end if

		set targetMsg to missing value
		set idNum to missing value
		try
			set idNum to messageIDRaw as integer
		end try

		if idNum is not missing value then
			repeat with mb in mailboxCandidates
				try
					set targetMsg to first message of mb whose id is idNum
				end try
				if targetMsg is not missing value then exit repeat
			end repeat
		end if

		if targetMsg is missing value then
			repeat with mb in mailboxCandidates
				try
					set targetMsg to first message of mb whose message id is messageIDRaw
				end try
				if targetMsg is not missing value then exit repeat
			end repeat
		end if

		if targetMsg is missing value then return "status=message_not_found"

		try
			set flagged status of targetMsg to true
			set flag index of targetMsg to targetFlagIndex
		on error errMsg number errNum
			return "status=flag_set_error" & linefeed & "error=" & errNum & ":" & errMsg
		end try
	end tell

	set outLines to {"status=ok", "messageID=" & messageIDRaw, "flagIndex=" & (targetFlagIndex as text), "account=" & accountName, "mailbox=" & mailboxName}
	set AppleScript's text item delimiters to linefeed
	return outLines as text
end run
""".strip()

    try:
        proc = subprocess.run(
            ["osascript", "-", message_id, account_name, mailbox_name, str(flag_index)],
            input=script,
            text=True,
            capture_output=True,
            check=True,
        )
    except subprocess.CalledProcessError as exc:
        err_text = (exc.stderr or exc.stdout or str(exc)).strip()
        return {"status": "failed", "error": err_text}

    payload = parse_osascript_kv(proc.stdout)
    status = payload.get("status", "").strip() or "unknown"
    result: Dict[str, Any] = {
        "status": status,
        "decision": decision,
        "flagIndex": flag_index,
        "messageID": message_id,
        "account": account_name,
        "mailbox": mailbox_name,
    }
    if proc.stderr.strip():
        result["stderr"] = proc.stderr.strip()
    if "error" in payload:
        result["error"] = payload.get("error", "")
    return result


def fetch_latest_email_payload(skip_accounts: set[str]) -> Dict[str, str]:
    effective_skip_accounts = set(skip_accounts) | HARD_BLOCKED_ACCOUNTS
    skip_literal = build_skip_accounts_literal(effective_skip_accounts)
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


def build_latest_email_fetch_prompt(
    *,
    skip_accounts: set[str],
    trigger_epoch: int,
    trigger_wait_seconds: int,
    trigger_poll_seconds: int,
    trigger_grace_seconds: int,
    candidate_depth: int,
) -> str:
    module_dir = str(Path(__file__).resolve().parent)
    script_lines = [
        "import json",
        "import sys",
        "import time",
        f"sys.path.insert(0, {module_dir!r})",
        "import lazyingart_simple as s",
        f"skip_accounts = set({json.dumps(sorted(skip_accounts), ensure_ascii=False)})",
        f"trigger_epoch = {int(trigger_epoch)}",
        f"trigger_wait_seconds = {int(trigger_wait_seconds)}",
        f"trigger_poll_seconds = {max(1, int(trigger_poll_seconds))}",
        f"trigger_grace_seconds = {max(0, int(trigger_grace_seconds))}",
        f"candidate_depth = {max(1, int(candidate_depth))}",
        "trigger_min_epoch = (trigger_epoch - trigger_grace_seconds) if trigger_epoch else 0",
        "processed_ids = set(s.load_processed_ids().keys())",
        "local_tz = s.get_local_tz()",
        "deadline = time.time() + max(0, trigger_wait_seconds)",
        "attempt = 0",
        "wait_reason = 'no_candidates'",
        "",
        "def emit(payload):",
        "    print(json.dumps(payload, ensure_ascii=False))",
        "    raise SystemExit(0)",
        "",
        "while True:",
        "    attempt += 1",
        "    try:",
        "        candidates = s.fetch_recent_email_candidates(skip_accounts, per_inbox_limit=candidate_depth)",
        "    except Exception as exc:",
        "        emit({",
        "            'status': 'error',",
        "            'reason': f'candidate_fetch_failed: {exc}',",
        "            'attempts': attempt,",
        "            'messageID': '',",
        "            'subject': '',",
        "            'sender': '',",
        "            'receivedAt': '',",
        "            'mailbox': '',",
        "            'account': '',",
        "            'body': '',",
        "        })",
        "",
        "    def candidate_epoch(item):",
        "        dt = s.parse_iso_datetime(item.get('receivedAt', ''), local_tz)",
        "        return int(dt.timestamp()) if dt else 0",
        "    candidates_sorted = sorted(candidates, key=candidate_epoch, reverse=True)",
        "    selected = None",
        "    wait_reason = 'no_candidates'",
        "    for item in candidates_sorted:",
        "        message_id = str(item.get('messageID', '')).strip()",
        "        received_dt = s.parse_iso_datetime(item.get('receivedAt', ''), local_tz)",
        "        received_epoch = int(received_dt.timestamp()) if received_dt else 0",
        "        if trigger_epoch and received_epoch < trigger_min_epoch:",
        "            wait_reason = f'before_trigger message_id={message_id} received_epoch={received_epoch} min_epoch={trigger_min_epoch}'",
        "            continue",
        "        if message_id and message_id in processed_ids:",
        "            wait_reason = f'already_processed message_id={message_id}'",
        "            continue",
        "        selected = item",
        "        break",
        "",
        "    if selected is not None:",
        "        try:",
        "            msg = s.fetch_message_payload_by_locator(",
        "                str(selected.get('messageID', '')),",
        "                str(selected.get('account', '')),",
        "                str(selected.get('mailbox', '')),",
        "            )",
        "        except Exception as exc:",
        "            if time.time() < deadline:",
        "                wait_reason = f'locator_fetch_failed: {exc}'",
        "                time.sleep(trigger_poll_seconds)",
        "                continue",
        "            emit({",
        "                'status': 'error',",
        "                'reason': f'locator_fetch_failed: {exc}',",
        "                'attempts': attempt,",
        "                'messageID': '',",
        "                'subject': '',",
        "                'sender': '',",
        "                'receivedAt': '',",
        "                'mailbox': '',",
        "                'account': '',",
        "                'body': '',",
        "            })",
        "",
        "        emit({",
        "            'status': 'ok',",
        "            'reason': 'matched_trigger_window' if trigger_epoch else 'latest_email',",
        "            'attempts': attempt,",
        "            'messageID': str(msg.get('messageID', '')),",
        "            'subject': str(msg.get('subject', '')),",
        "            'sender': str(msg.get('sender', '')),",
        "            'receivedAt': str(msg.get('receivedAt', '')),",
        "            'mailbox': str(msg.get('mailbox', '')),",
        "            'account': str(msg.get('account', '')),",
        "            'body': str(msg.get('body', '')),",
        "        })",
        "",
        "    if time.time() >= deadline:",
        "        emit({",
        "            'status': 'not_found',",
        "            'reason': wait_reason,",
        "            'attempts': attempt,",
        "            'messageID': '',",
        "            'subject': '',",
        "            'sender': '',",
        "            'receivedAt': '',",
        "            'mailbox': '',",
        "            'account': '',",
        "            'body': '',",
        "        })",
        "",
        "    time.sleep(trigger_poll_seconds)",
    ]
    worker_script = "\n".join(script_lines)
    return f"""
You are a fetch worker for Lazyingart mail automation.

Task:
- Find the email for this trigger window by polling latest inbox candidates.
- You MUST run shell commands to do the polling; do not guess.
- Use the provided Python worker script exactly and wait for it to finish.
- Then return the parsed JSON result in the required schema.
- Return `status="ok"` ONLY if `messageID`, `receivedAt`, `account`, and `mailbox` are non-empty.
- If those required fields are empty, return `status="not_found"` with a non-empty `reason`.

Trigger context:
- trigger_epoch={int(trigger_epoch)}
- trigger_wait_seconds={int(trigger_wait_seconds)}
- trigger_poll_seconds={max(1, int(trigger_poll_seconds))}
- trigger_grace_seconds={max(0, int(trigger_grace_seconds))}
- candidate_depth={max(1, int(candidate_depth))}
- skip_accounts={",".join(sorted(skip_accounts)) or "(none)"}

Run this exact command:
```bash
python3 - <<'PY'
{worker_script}
PY
```
""".strip()


def fetch_latest_email_via_codex(
    *,
    run_id: str,
    skip_accounts: set[str],
    trigger_epoch: int,
    trigger_wait_seconds: int,
    trigger_poll_seconds: int,
    trigger_grace_seconds: int,
    model: str,
    reasoning: str,
    codex_bin_override: str,
) -> Dict[str, Any]:
    candidate_depth = 12
    prompt = build_latest_email_fetch_prompt(
        skip_accounts=skip_accounts,
        trigger_epoch=trigger_epoch,
        trigger_wait_seconds=trigger_wait_seconds,
        trigger_poll_seconds=trigger_poll_seconds,
        trigger_grace_seconds=trigger_grace_seconds,
        candidate_depth=candidate_depth,
    )
    fetch_output_path = CODEX_DIR / f"{run_id}-latest-fetch.json"
    payload = run_codex_json(
        prompt=prompt,
        output_path=fetch_output_path,
        schema=LATEST_EMAIL_FETCH_SCHEMA,
        model=model,
        reasoning=reasoning,
        codex_bin_override=codex_bin_override,
        sandbox="danger-full-access",
    )
    shutil.copyfile(fetch_output_path, CODEX_DIR / "latest-fetch.json")
    return payload


def build_prompt(
    message: Dict[str, str],
    now_local: datetime,
    received_local: datetime,
    default_calendar: str,
    recent_items_text: str,
    trigger_context: str = "",
) -> str:
    prompt_default_calendar = default_calendar.strip() or DEFAULT_CALENDAR
    return f"""
You are an email triage assistant for Lazyingart.

You must output EXACTLY one JSON object that matches this schema and contains no extra keys:
{json.dumps(SCHEMA, indent=2)}

Core requirement:
- Extract ALL actionable items from this email exhaustively.
- Return them in `actions` array (one item per action).
- Mix action types when needed (calendar + reminder + note in the same output is allowed/expected).
- If there is truly nothing useful, return one action with decision="skip".
- Avoid duplicates against existing saved items below.

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
  - calendar: {json.dumps(prompt_default_calendar)}
  - list: {json.dumps(DEFAULT_REMINDER_LIST)}
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

Duplicate control (important):
- Existing saved items are listed below.
- Do NOT output an action if it is effectively the same task/event already saved.
- For calendar duplication check: compare title + start + end + calendar.
- For reminder duplication check: compare title + due + list.
- For note duplication check: compare title + folder and same core content.
- If email is forwarded/repeated, keep NEW items but skip already-saved duplicates.

Current local datetime:
- {now_local.isoformat(timespec="seconds")}
Email received datetime in local timezone:
- {received_local.isoformat(timespec="seconds")}
Trigger context:
- {trigger_context or "n/a"}

Existing saved items (most recent first):
{recent_items_text}

Email metadata:
- sender: {message['sender']}
- subject: {message['subject']}
- receivedAt: {message['receivedAt']}
- mailbox: {message['mailbox']}
- account: {message['account']}

Email body (full text):
{message['body']}
""".strip()


def build_smart_save_prompt(
    message: Dict[str, str],
    now_local: datetime,
    received_local: datetime,
    default_calendar: str,
    candidate_actions: list[Dict[str, Any]],
    recent_items_text: str,
    notes_index_text: str,
    trigger_context: str = "",
) -> str:
    prompt_default_calendar = default_calendar.strip() or DEFAULT_CALENDAR
    candidate_json = json.dumps({"actions": candidate_actions}, ensure_ascii=False, indent=2)
    return f"""
You are the Smart Save planner for Lazyingart email automation.

You must output EXACTLY one JSON object matching this schema, with no extra keys:
{json.dumps(SCHEMA, indent=2)}

Your job:
1) Review candidate actions extracted from this email.
2) Re-plan final save actions so they are deduplicated and organized.
3) Use existing notes index to decide whether to append to an existing note (same title/folder) or create a new note.

Rules:
- Keep only actions that provide value.
- Remove duplicates against existing saved items and against repeated forwarded email content.
- Preserve all distinct actionable items.
- If nothing should be saved, return exactly one action with decision="skip".
- Prefer calendar for personal schedule/deadline/travel related to the user.
- Use reminder for mass/broadcast/general notices that still need a nudge.
- Use note for reference/bookkeeping.
- For note actions, always use folder path starting with "Lazyingart/".
- For finance/payment/bank emails:
  - prefer note unless urgent action needed;
  - group by day: folder "Lazyingart/Finance/YYYY-MM-DD", title "Finance Ledger YYYY-MM-DD";
  - if a same-day ledger note already exists, reuse its exact title/folder.
- For note content, produce structured text when useful:
  - Summary
  - Todo
  - Cost Memo
  - Key Dates
  Include only non-empty sections.
- Default calendar: {json.dumps(prompt_default_calendar)}
- Default reminder list: {json.dumps(DEFAULT_REMINDER_LIST)}

Duplicate checks:
- calendar duplicate key: title + start + end + calendar
- reminder duplicate key: title + due + list
- note duplicate key: title + folder + core content

Current local datetime:
- {now_local.isoformat(timespec="seconds")}
Email received local datetime:
- {received_local.isoformat(timespec="seconds")}
Trigger context:
- {trigger_context or "n/a"}

Candidate actions from parser:
{candidate_json}

Existing saved items (recent first):
{recent_items_text}

Existing notes index (recent sample):
{notes_index_text}

Email metadata:
- sender: {message['sender']}
- subject: {message['subject']}
- receivedAt: {message['receivedAt']}
- mailbox: {message['mailbox']}
- account: {message['account']}

Email body (full text):
{message['body']}
""".strip()


def build_strong_save_prompt(
    message: Dict[str, str],
    now_local: datetime,
    received_local: datetime,
    default_calendar: str,
    actions: list[Dict[str, Any]],
    recent_items_text: str,
    notes_index_text: str,
    run_id: str,
    trigger_context: str = "",
) -> str:
    prompt_default_calendar = default_calendar.strip() or DEFAULT_CALENDAR
    today = now_local.date().isoformat()
    actions_json = json.dumps({"actions": actions}, ensure_ascii=False, indent=2)
    return f"""
You are the strong_smart_save executor for Lazyingart mail automation.

You MUST execute saves yourself using shell commands (not just planning), then return one final JSON object matching this schema exactly:
{json.dumps(STRONG_SAVE_SCHEMA, indent=2)}

Execution requirements:
1) Input actions to execute:
{actions_json}
2) Deduplicate:
   - against existing saved items below
   - within this run
   - calendar duplicate key: title + start + end + calendar
   - reminder duplicate key: title + due + list
   - note duplicate key: title + folder + core content
3) Save commands:
   - calendar:
     osascript {json.dumps(str(AUTOMATION_DIR / "create_calendar_event.applescript"))} "<title>" "<start>" "<end>" "<notes>" "<calendar>" "<reminderMinutes>"
   - reminder:
     osascript {json.dumps(str(AUTOMATION_DIR / "create_reminder.applescript"))} "<title>" "<due>" "<notes>" "<list>" "<reminderMinutes>"
   - note:
     osascript {json.dumps(str(AUTOMATION_DIR / "create_note.applescript"))} "<title>" "<notes>" "<folder>" "prepend"
4) For note actions, dynamically merge into existing knowledge:
   - folder must be meaningful and start with Lazyingart/
   - prefer this top-level taxonomy when possible:
     Work / Research / Travel / MEMO / To-Do-List / Finance / School / Personal / Inbox
   - use nested folders to keep context clear, examples:
     Lazyingart/Work/Meetings
     Lazyingart/Research/Papers
     Lazyingart/Travel/Japan
     Lazyingart/MEMO/Quick
     Lazyingart/To-Do-List/ThisWeek
   - avoid Lazyingart/Inbox when a better category is obvious
   - reuse same title/folder when semantically same topic
   - merge and rewrite consolidated note content when needed (not raw duplicate append), newest first
5) Note content formatting requirements:
   - output rich, readable Apple Notes content with clear structure
   - use section headers + blank lines
   - prefer HTML-friendly formatting for notes content:
     <h3>, <p>, <ul>/<ol>/<li>, <table>/<tr>/<th>/<td>, <br/>
   - for checklists, do NOT rely only on markdown "- [ ]":
     use visible checkbox glyphs ("☐ item", "☑ item")
   - for checklist lines specifically, avoid list bullets:
     use block lines like <div>☐ item</div> (not <ul>/<li> for checkbox items)
   - for tables, use real HTML table tags when data is tabular
   - use bullets for facts and indentation for subitems (2 spaces or nested lists)
   - preferred sections when relevant: Summary / To-Do / Checklist / Key Dates / Cost Memo
   - keep one item per line; avoid long unstructured paragraphs
   - when merging existing notes, dedupe repeated checklist lines and reorder by urgency/date
6) For finance/payment messages:
   - prefer daily ledger note
   - folder: Lazyingart/Finance/YYYY-MM-DD
   - title: Finance Ledger YYYY-MM-DD
7) After actions, create one processing log note:
   - folder: Lazyingart/Log/{today}
   - title: Mail Log {today}
   - include run_id, message_id, subject, created/skipped/failed, and per-item summary
   - command:
     osascript {json.dumps(str(AUTOMATION_DIR / "create_note.applescript"))} "Mail Log {today}" "<log_text>" "Lazyingart/Log/{today}" "prepend"
8) Always return all items in item_results with status created/skipped/failed and concise reason.

Defaults:
- calendar default: {json.dumps(prompt_default_calendar)}
- reminder list default: {json.dumps(DEFAULT_REMINDER_LIST)}

Run context:
- run_id: {run_id}
- now_local: {now_local.isoformat(timespec="seconds")}
- received_local: {received_local.isoformat(timespec="seconds")}
- message_id: {message.get('messageID', '')}
- sender: {message.get('sender', '')}
- subject: {message.get('subject', '')}
- trigger_context: {trigger_context or "n/a"}

Existing saved items:
{recent_items_text}

Existing notes index:
{notes_index_text}

Email body:
{message.get('body', '')}
""".strip()


def run_codex_json(
    prompt: str,
    output_path: Path,
    schema: Dict[str, Any],
    model: str,
    reasoning: str,
    codex_bin_override: str = "",
    sandbox: str = "read-only",
) -> Dict[str, Any]:
    codex_bin = resolve_codex_bin(codex_bin_override)
    node_bin = resolve_node_bin(codex_bin)
    codex_dir = str(Path(codex_bin).resolve().parent)
    node_dir = str(Path(node_bin).resolve().parent)
    with tempfile.NamedTemporaryFile(mode="w", delete=False, encoding="utf-8") as schema_file:
        schema_file.write(json.dumps(schema, indent=2))
        schema_path = Path(schema_file.name)

    cmd = [
        node_bin,
        codex_bin,
        "exec",
        "--model",
        model,
        "--sandbox",
        sandbox,
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
    write_json(output_path, parsed)
    return parsed


def run_codex(
    prompt: str,
    output_path: Path,
    model: str,
    reasoning: str,
    codex_bin_override: str = "",
) -> list[Dict[str, Any]]:
    parsed = run_codex_json(
        prompt=prompt,
        output_path=output_path,
        schema=SCHEMA,
        model=model,
        reasoning=reasoning,
        codex_bin_override=codex_bin_override,
        sandbox="read-only",
    )
    actions = normalize_codex_actions(parsed)
    write_json(output_path, {"actions": actions})
    return actions


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


def apply_action(action_json_path: Path, message_json_path: Path, default_calendar: str) -> Dict[str, Any]:
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
    if default_calendar.strip():
        cmd.extend(["--default-calendar", default_calendar.strip()])
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
    parser.add_argument("--default-calendar", default=os.environ.get("LAZYINGART_DEFAULT_CALENDAR", DEFAULT_CALENDAR))
    parser.add_argument(
        "--trigger-epoch",
        type=int,
        default=0,
        help="Rule trigger Unix epoch seconds. In --latest-email mode, ignore stale mails before this trigger window.",
    )
    parser.add_argument(
        "--trigger-wait-seconds",
        type=int,
        default=0,
        help="In --latest-email mode, max seconds to keep polling for a post-trigger mail.",
    )
    parser.add_argument(
        "--trigger-poll-seconds",
        type=int,
        default=5,
        help="In --latest-email mode, poll interval while waiting for a post-trigger mail.",
    )
    parser.add_argument(
        "--trigger-grace-seconds",
        type=int,
        default=45,
        help="Allow a message slightly earlier than trigger (seconds).",
    )
    mode_group = parser.add_mutually_exclusive_group()
    mode_group.add_argument(
        "--smart_save",
        "--smart-save",
        dest="smart_save",
        action="store_true",
        help="Use Codex smart-save planning before applying actions.",
    )
    mode_group.add_argument(
        "--code_save",
        "--code-save",
        dest="code_save",
        action="store_true",
        help="Use code-only save flow after initial Codex extraction.",
    )
    mode_group.add_argument(
        "--strong_smart_save",
        "--strong-smart-save",
        dest="strong_smart_save",
        action="store_true",
        help="Use Codex to execute save actions directly (calendar/reminder/note + dynamic merge) (default).",
    )
    args = parser.parse_args()

    setup_logging(args.log_level)
    if args.code_save:
        save_mode = "code_save"
    elif args.smart_save:
        save_mode = "smart_save"
    else:
        save_mode = "strong_smart_save"

    local_tz = get_local_tz()
    default_calendar = str(args.default_calendar or "").strip() or DEFAULT_CALENDAR
    processed_ids = load_processed_ids()

    source_ref = ""
    skip_accounts: set[str] = set()
    if args.latest_email:
        skip_accounts = {item.strip().lower() for item in args.skip_accounts.split(",") if item.strip()}
        skip_accounts |= HARD_BLOCKED_ACCOUNTS
        trigger_epoch = max(0, int(args.trigger_epoch or 0))
        trigger_wait_seconds = max(0, int(args.trigger_wait_seconds or 0))
        trigger_poll_seconds = max(1, int(args.trigger_poll_seconds or 1))
        trigger_grace_seconds = max(0, int(args.trigger_grace_seconds or 0))
        fetch_run_id = f"{datetime.now().strftime('%Y%m%d-%H%M%S')}-trigger-fetch"
        try:
            fetch_payload = fetch_latest_email_via_codex(
                run_id=fetch_run_id,
                skip_accounts=skip_accounts,
                trigger_epoch=trigger_epoch,
                trigger_wait_seconds=trigger_wait_seconds,
                trigger_poll_seconds=trigger_poll_seconds,
                trigger_grace_seconds=trigger_grace_seconds,
                model=args.model,
                reasoning=args.reasoning,
                codex_bin_override=args.codex_bin,
            )
        except subprocess.CalledProcessError as exc:
            logging.error("latest_fetch_codex_failed code=%s stderr=%s", exc.returncode, (exc.stderr or "").strip()[:2000])
            sys.exit(1)
        except Exception as exc:
            logging.error("latest_fetch_codex_failed err=%s", exc)
            sys.exit(1)

        fetch_status = str(fetch_payload.get("status", "")).strip()
        fetch_reason = str(fetch_payload.get("reason", "")).strip()
        fetch_attempts = int(fetch_payload.get("attempts", 0) or 0)
        fetch_message_id = str(fetch_payload.get("messageID", "")).strip()
        fetch_received_at = str(fetch_payload.get("receivedAt", "")).strip()
        fetch_account = str(fetch_payload.get("account", "")).strip()
        fetch_mailbox = str(fetch_payload.get("mailbox", "")).strip()
        if fetch_status == "ok" and (not fetch_message_id or not fetch_received_at or not fetch_account or not fetch_mailbox):
            fetch_status = "not_found"
            if not fetch_reason:
                fetch_reason = "codex_fetch_returned_empty_fields"
        if fetch_status != "ok":
            logging.error(
                "latest_fetch_no_match status=%s reason=%s attempts=%s trigger_epoch=%s",
                fetch_status or "(none)",
                fetch_reason or "(none)",
                fetch_attempts,
                trigger_epoch,
            )
            sys.exit(2 if fetch_status == "not_found" else 1)

        message = normalize_message(fetch_payload)
        source_ref = (
            f"mail_latest_codex(skip_accounts={','.join(sorted(skip_accounts))},trigger_epoch={trigger_epoch},"
            f"trigger_wait_seconds={trigger_wait_seconds},trigger_poll_seconds={trigger_poll_seconds},"
            f"trigger_grace_seconds={trigger_grace_seconds},attempts={fetch_attempts},reason={fetch_reason})"
        )
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

    skip_now, skip_reason = should_skip_message_early(message, skip_accounts)
    if skip_now:
        skip_payload = {
            "status": "skipped_early",
            "reason": skip_reason,
            "message_id": message.get("messageID", ""),
            "account": message.get("account", ""),
            "sender": message.get("sender", ""),
        }
        logging.info(
            "early_skip reason=%s message_id=%s account=%s sender=%s",
            skip_reason,
            message.get("messageID", ""),
            message.get("account", ""),
            message.get("sender", ""),
        )
        print(json.dumps(skip_payload, ensure_ascii=False))
        return

    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    message_token = safe_token(message.get("messageID", ""))
    run_id = f"{timestamp}-{message_token}"
    message_id = message.get("messageID", "")
    now_local = datetime.now(local_tz)
    received_local = parse_iso_datetime(message.get("receivedAt", ""), local_tz) or now_local

    inbound_path = INBOUND_DIR / f"{run_id}.json"
    prompt_path = PROMPT_DIR / f"{run_id}.txt"
    parser_output_path = CODEX_DIR / f"{run_id}.json"
    smart_prompt_path = PROMPT_DIR / f"{run_id}-smart.txt"
    smart_output_path = CODEX_DIR / f"{run_id}-smart.json"
    final_output_path = parser_output_path
    result_path = RESULT_DIR / f"{run_id}.json"

    write_json(inbound_path, message)
    shutil.copyfile(inbound_path, INBOUND_DIR / "latest.json")

    if message_id and message_id in processed_ids:
        duplicate_result = {
            "run_id": run_id,
            "message_id": message_id,
            "decision": "skip",
            "importance": "low",
            "decisions": ["skip"],
            "actions_count": 0,
            "save_mode": save_mode,
            "action_json_path": "",
            "apply_result": {
                "status": "skipped_duplicate",
                "target": "none",
                "reason": "message_id already processed",
                "first_run_id": processed_ids[message_id].get("run_id", ""),
            },
            "flag_result": {"status": "skipped", "reason": "duplicate_message"},
            "timestamp": datetime.now().isoformat(),
        }
        duplicate_result["log_note_result"] = write_processing_log_note(message, duplicate_result, save_mode, local_tz)
        write_json(result_path, duplicate_result)
        shutil.copyfile(result_path, RESULT_DIR / "latest.json")
        logging.info(
            "pipeline_skip_duplicate run_id=%s message_id=%s first_run_id=%s mode=%s",
            run_id,
            message_id,
            processed_ids[message_id].get("run_id", ""),
            save_mode,
        )
        print(json.dumps(duplicate_result, ensure_ascii=False))
        return

    action_fingerprints = load_action_fingerprints()
    boot_added = bootstrap_action_fingerprints_from_results(action_fingerprints, default_calendar)
    if boot_added:
        save_action_fingerprints(action_fingerprints)
        logging.info("action_fingerprint_bootstrap_added=%s", boot_added)
    recent_items_text = summarize_recent_items_for_prompt(action_fingerprints)

    trigger_context = (
        f"trigger_epoch={int(args.trigger_epoch or 0)},"
        f"trigger_wait_seconds={int(args.trigger_wait_seconds or 0)},"
        f"trigger_poll_seconds={int(args.trigger_poll_seconds or 0)},"
        f"trigger_grace_seconds={int(args.trigger_grace_seconds or 0)}"
    )
    prompt = build_prompt(message, now_local, received_local, default_calendar, recent_items_text, trigger_context)
    prompt_path.write_text(prompt + "\n", encoding="utf-8")
    shutil.copyfile(prompt_path, PROMPT_DIR / "latest.txt")

    logging.info(
        "pipeline_start run_id=%s mode=%s message_id=%s source=%s inbound=%s codex_out=%s codex_bin=%s default_calendar=%s",
        run_id,
        save_mode,
        message.get("messageID", ""),
        source_ref,
        inbound_path,
        parser_output_path,
        args.codex_bin or os.environ.get("LAZYINGART_CODEX_BIN", "") or "auto",
        default_calendar or "(none)",
    )

    try:
        parser_actions = run_codex(prompt, parser_output_path, args.model, args.reasoning, args.codex_bin)
    except subprocess.CalledProcessError as exc:
        logging.error("codex_exec_failed run_id=%s code=%s", run_id, exc.returncode)
        if exc.stderr:
            logging.error("codex_exec_stderr=%s", exc.stderr.strip()[:2000])
        sys.exit(1)
    except Exception as exc:
        logging.error("codex_output_invalid run_id=%s err=%s", run_id, exc)
        sys.exit(1)

    normalized_actions: list[Dict[str, Any]] = []
    for action in parser_actions:
        patched = enforce_low_importance_policy(action, message)
        patched = apply_weekday_correction(patched, message, now_local, local_tz)
        normalized_actions.append(patched)
    write_json(parser_output_path, {"actions": normalized_actions})

    if save_mode in {"smart_save", "strong_smart_save"}:
        notes_index = fetch_notes_index(account="iCloud", limit=300)
        notes_index_text = summarize_notes_for_prompt(notes_index, limit=160)
        smart_prompt = build_smart_save_prompt(
            message,
            now_local,
            received_local,
            default_calendar,
            normalized_actions,
            recent_items_text,
            notes_index_text,
            trigger_context,
        )
        smart_prompt_path.write_text(smart_prompt + "\n", encoding="utf-8")
        shutil.copyfile(smart_prompt_path, PROMPT_DIR / "latest-smart.txt")
        try:
            smart_actions = run_codex(smart_prompt, smart_output_path, args.model, args.reasoning, args.codex_bin)
        except subprocess.CalledProcessError as exc:
            logging.error("smart_save_codex_exec_failed run_id=%s code=%s", run_id, exc.returncode)
            if exc.stderr:
                logging.error("smart_save_codex_stderr=%s", exc.stderr.strip()[:2000])
            sys.exit(1)
        except Exception as exc:
            logging.error("smart_save_output_invalid run_id=%s err=%s", run_id, exc)
            sys.exit(1)

        smart_normalized: list[Dict[str, Any]] = []
        for action in smart_actions:
            patched = enforce_low_importance_policy(action, message)
            patched = apply_weekday_correction(patched, message, now_local, local_tz)
            smart_normalized.append(patched)
        normalized_actions = smart_normalized
        write_json(smart_output_path, {"actions": normalized_actions})
        final_output_path = smart_output_path

    shutil.copyfile(final_output_path, CODEX_DIR / "latest.json")
    logging.info(
        "codex_action_ready run_id=%s mode=%s actions=%s action_path=%s",
        run_id,
        save_mode,
        len(normalized_actions),
        final_output_path,
    )

    item_results: list[Dict[str, Any]] = []
    strong_log_note_result: Optional[Dict[str, Any]] = None
    if save_mode == "strong_smart_save":
        strong_prompt_path = PROMPT_DIR / f"{run_id}-strong.txt"
        strong_output_path = CODEX_DIR / f"{run_id}-strong.json"
        notes_index = fetch_notes_index(account="iCloud", limit=300)
        notes_index_text = summarize_notes_for_prompt(notes_index, limit=200)
        strong_prompt = build_strong_save_prompt(
            message=message,
            now_local=now_local,
            received_local=received_local,
            default_calendar=default_calendar,
            actions=normalized_actions,
            recent_items_text=recent_items_text,
            notes_index_text=notes_index_text,
            run_id=run_id,
            trigger_context=trigger_context,
        )
        strong_prompt_path.write_text(strong_prompt + "\n", encoding="utf-8")
        shutil.copyfile(strong_prompt_path, PROMPT_DIR / "latest-strong.txt")
        try:
            strong_payload = run_codex_json(
                prompt=strong_prompt,
                output_path=strong_output_path,
                schema=STRONG_SAVE_SCHEMA,
                model=args.model,
                reasoning=args.reasoning,
                codex_bin_override=args.codex_bin,
                sandbox="danger-full-access",
            )
        except subprocess.CalledProcessError as exc:
            logging.error("strong_save_codex_exec_failed run_id=%s code=%s", run_id, exc.returncode)
            if exc.stderr:
                logging.error("strong_save_codex_stderr=%s", exc.stderr.strip()[:2000])
            sys.exit(1)
        except Exception as exc:
            logging.error("strong_save_output_invalid run_id=%s err=%s", run_id, exc)
            sys.exit(1)

        final_output_path = strong_output_path
        shutil.copyfile(final_output_path, CODEX_DIR / "latest.json")
        logging.info("strong_save_done run_id=%s action_path=%s", run_id, final_output_path)

        raw_results = strong_payload.get("item_results")
        if not isinstance(raw_results, list):
            raw_results = []

        for raw in raw_results:
            if not isinstance(raw, dict):
                continue
            idx = int(raw.get("index", 0) or 0)
            action_ref: Dict[str, Any] = {}
            if 1 <= idx <= len(normalized_actions):
                action_ref = normalized_actions[idx - 1]
            decision = str(raw.get("decision", action_ref.get("decision", "skip"))).strip().lower() or "skip"
            title = str(raw.get("title", action_ref.get("title", "")))
            status = str(raw.get("status", "failed")).strip() or "failed"
            fingerprint = str(raw.get("fingerprint", "")).strip()
            if not fingerprint and action_ref:
                fingerprint = action_fingerprint(action_ref, default_calendar)
            apply_result: Dict[str, Any] = {
                "status": status,
                "target": str(raw.get("target", decision)),
                "id": str(raw.get("id", "")),
                "reason": str(raw.get("reason", "")),
            }
            error_text = str(raw.get("error", "")).strip()
            if error_text:
                apply_result["error"] = error_text
            item_result: Dict[str, Any] = {
                "index": idx,
                "decision": decision,
                "importance": str(action_ref.get("importance", "medium")),
                "title": title,
                "fingerprint": fingerprint,
                "status": status,
                "apply_result": apply_result,
            }
            item_results.append(item_result)

            if status == "created" and action_ref:
                action_fingerprints[fingerprint] = {
                    "timestamp": datetime.now().isoformat(),
                    "run_id": run_id,
                    "message_id": message_id,
                    "decision": decision,
                    "title": action_ref.get("title", ""),
                    "start": action_ref.get("start", ""),
                    "end": action_ref.get("end", ""),
                    "due": action_ref.get("due", ""),
                    "calendar": resolve_effective_calendar(action_ref, default_calendar),
                    "list": action_ref.get("list", ""),
                    "folder": action_ref.get("folder", ""),
                }

        if not item_results:
            for idx, action in enumerate(normalized_actions, start=1):
                fp = action_fingerprint(action, default_calendar)
                item_results.append(
                    {
                        "index": idx,
                        "decision": action["decision"],
                        "importance": action["importance"],
                        "title": action["title"],
                        "fingerprint": fp,
                        "status": "failed",
                        "apply_result": {"status": "failed", "error": "strong_smart_save returned no item_results"},
                    }
                )

        log_note_obj = strong_payload.get("log_note_result")
        if isinstance(log_note_obj, dict):
            strong_log_note_result = {str(k): v for k, v in log_note_obj.items()}
    else:
        seen_fingerprints_in_run: set[str] = set()
        for idx, action in enumerate(normalized_actions, start=1):
            decision = action["decision"]
            fingerprint = action_fingerprint(action, default_calendar)
            item_result: Dict[str, Any] = {
                "index": idx,
                "decision": decision,
                "importance": action["importance"],
                "title": action["title"],
                "fingerprint": fingerprint,
                "status": "",
                "apply_result": {},
            }

            if fingerprint in seen_fingerprints_in_run:
                item_result["status"] = "skipped_duplicate_in_output"
                item_result["apply_result"] = {"status": "skipped_duplicate_in_output"}
                item_results.append(item_result)
                continue
            seen_fingerprints_in_run.add(fingerprint)

            if decision != "skip" and fingerprint in action_fingerprints:
                item_result["status"] = "skipped_duplicate_saved"
                item_result["apply_result"] = {
                    "status": "skipped_duplicate_saved",
                    "first_saved_at": action_fingerprints[fingerprint].get("timestamp", ""),
                    "first_run_id": action_fingerprints[fingerprint].get("run_id", ""),
                }
                item_results.append(item_result)
                continue

            if decision == "skip":
                item_result["status"] = "skipped"
                item_result["apply_result"] = {"status": "skipped", "target": "none", "reason": action.get("reason", "")}
                item_results.append(item_result)
                continue

            item_action_path = CODEX_DIR / f"{run_id}-item{idx}.json"
            write_json(item_action_path, action)
            try:
                apply_result = apply_action(item_action_path, inbound_path, default_calendar)
                item_result["status"] = str(apply_result.get("status", "unknown"))
                item_result["apply_result"] = apply_result
                if item_result["status"] == "created":
                    action_fingerprints[fingerprint] = {
                        "timestamp": datetime.now().isoformat(),
                        "run_id": run_id,
                        "message_id": message_id,
                        "decision": decision,
                        "title": action.get("title", ""),
                        "start": action.get("start", ""),
                        "end": action.get("end", ""),
                        "due": action.get("due", ""),
                        "calendar": resolve_effective_calendar(action, default_calendar),
                        "list": action.get("list", ""),
                        "folder": action.get("folder", ""),
                    }
            except subprocess.CalledProcessError as exc:
                err_text = (exc.stderr or str(exc)).strip()
                item_result["status"] = "failed"
                item_result["apply_result"] = {"status": "failed", "error": err_text}
                logging.error("apply_failed run_id=%s item=%s err=%s", run_id, idx, err_text[:1000])
            except Exception as exc:
                item_result["status"] = "failed"
                item_result["apply_result"] = {"status": "failed", "error": str(exc)}
                logging.error("apply_exception run_id=%s item=%s err=%s", run_id, idx, exc)
            item_results.append(item_result)

    save_action_fingerprints(action_fingerprints)

    created_decisions = [item["decision"] for item in item_results if item["status"] == "created"]
    flag_basis = [{"decision": d} for d in created_decisions] or [{"decision": "skip"}]
    flag_decision = choose_flag_decision(flag_basis)
    flag_result = apply_decision_flag(message, flag_decision)
    flag_status = str(flag_result.get("status", "unknown"))
    if flag_status == "ok":
        logging.info(
            "flag_applied run_id=%s decision=%s flag_index=%s message_id=%s",
            run_id,
            flag_decision,
            flag_result.get("flagIndex", ""),
            message_id,
        )
    else:
        logging.warning(
            "flag_apply_issue run_id=%s decision=%s status=%s detail=%s",
            run_id,
            flag_decision,
            flag_status,
            flag_result,
        )

    decision_values = [item["decision"] for item in normalized_actions]
    importance_rank = {"low": 1, "medium": 2, "high": 3}
    top_importance = "low"
    for item in normalized_actions:
        imp = str(item.get("importance", "low"))
        if importance_rank.get(imp, 0) > importance_rank.get(top_importance, 0):
            top_importance = imp
    created_count = sum(1 for item in item_results if item["status"] == "created")
    failed_count = sum(1 for item in item_results if item["status"] == "failed")
    skipped_count = len(item_results) - created_count - failed_count
    if len(decision_values) == 1:
        decision_summary = decision_values[0]
    elif decision_values:
        decision_summary = "multi"
    else:
        decision_summary = "skip"
    if len(item_results) == 1:
        apply_result_summary: Dict[str, Any] = item_results[0]["apply_result"]
    else:
        apply_result_summary = {
            "status": "multi",
            "created": created_count,
            "skipped": skipped_count,
            "failed": failed_count,
        }

    result_payload = {
        "run_id": run_id,
        "message_id": message_id,
        "decision": decision_summary,
        "importance": top_importance,
        "decisions": decision_values,
        "actions_count": len(normalized_actions),
        "save_mode": save_mode,
        "action_json_path": str(final_output_path),
        "item_results": item_results,
        "apply_result": apply_result_summary,
        "flag_result": flag_result,
        "timestamp": datetime.now().isoformat(),
    }
    if strong_log_note_result:
        result_payload["log_note_result"] = strong_log_note_result
    else:
        result_payload["log_note_result"] = write_processing_log_note(message, result_payload, save_mode, local_tz)
    if message_id:
        processed_ids[message_id] = {
            "timestamp": result_payload["timestamp"],
            "run_id": run_id,
            "decision": decision_summary,
        }
        save_processed_ids(processed_ids)
    write_json(result_path, result_payload)
    shutil.copyfile(result_path, RESULT_DIR / "latest.json")

    logging.info(
        "pipeline_done run_id=%s mode=%s decision=%s actions=%s created=%s skipped=%s failed=%s",
        run_id,
        save_mode,
        decision_summary,
        len(normalized_actions),
        created_count,
        skipped_count,
        failed_count,
    )
    print(json.dumps(result_payload, ensure_ascii=False))


if __name__ == "__main__":
    main()
