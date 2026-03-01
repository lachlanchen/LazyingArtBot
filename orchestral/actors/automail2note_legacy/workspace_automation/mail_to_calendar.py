#!/usr/bin/env python3
"""Scan macOS Mail for actionable messages and create Calendar follow-up holds."""
from __future__ import annotations

import argparse
import json
import logging
import re
import subprocess
import sys
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional

from dateparser.search import search_dates
from dateutil import tz

WORKDIR = Path(__file__).resolve().parent.parent
FETCH_SCRIPT = WORKDIR / "automation" / "fetch_mail_candidates.applescript"
CREATE_SCRIPT = WORKDIR / "automation" / "create_calendar_event.applescript"
STATE_FILE = WORKDIR / "state" / "mail_actions.json"
LOG_FILE = WORKDIR / "logs" / "mail_actions.log"
AUDIT_LOG_FILE = WORKDIR / "logs" / "mail_monitoring.jsonl"
IGNORE_RULES_FILE = WORKDIR / "automation" / "mail_ignore_list.json"
CALENDAR_NAME = "Lachlan"
FOLLOW_UP_DURATION_MINUTES = 30
EXPLICIT_DURATION_MINUTES = 60
ALERT_MINUTES = 15
KEYWORDS = [
    "meeting",
    "meet",
    "call",
    "deadline",
    "due",
    "follow up",
    "follow-up",
    "action required",
    "schedule",
    "appointment",
    "interview",
    "confirm",
    "reminder",
    "deliverable",
    "submission",
    "invoice",
    "payment",
]
MAX_BODY_FOR_PARSING = 800
LOCAL_TZ = datetime.now().astimezone().tzinfo or tz.gettz("Asia/Shanghai")


DEFAULT_IGNORE_RULES = {
    "sender_exact": [
        "its_boc@bochk.com",
        "e-statement@bochk.com",
        "ealert@bochk.com",
        "no_reply@stmt.futuhk.com",
        "no_reply@notification.futuhk.com",
        "noreply@medium.com",
        "notifications-noreply@linkedin.com",
        "noreply@mail.justpark.com",
        "news_en-gb@avis-comms.international",
        "trip.com@newsletter.trip.com",
        "en_flight_noreply@trip.com",
        "enotices.daily.digest@hku.hk",
    ],
    "sender_contains": [
        "googlealerts",
        "@newsletter.",
    ],
    "subject_contains": [
        "daily digest",
        "e-statement",
        "google alert",
    ],
    "account_sender_exact": {},
    "account_sender_contains": {},
}


def setup_logging() -> None:
    LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        handlers=[
            logging.FileHandler(LOG_FILE, encoding="utf-8"),
            logging.StreamHandler(sys.stdout),
        ],
    )


def append_audit(event: str, **fields: object) -> None:
    AUDIT_LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
    record = {
        "ts": datetime.now().astimezone().isoformat(),
        "event": event,
        **fields,
    }
    with AUDIT_LOG_FILE.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(record, ensure_ascii=False) + "\n")


def load_ignore_rules() -> Dict[str, object]:
    rules = {
        "sender_exact": [s.lower() for s in DEFAULT_IGNORE_RULES["sender_exact"]],
        "sender_contains": [s.lower() for s in DEFAULT_IGNORE_RULES["sender_contains"]],
        "subject_contains": [s.lower() for s in DEFAULT_IGNORE_RULES["subject_contains"]],
        "account_sender_exact": {},
        "account_sender_contains": {},
    }
    if not IGNORE_RULES_FILE.exists():
        return rules
    try:
        raw = json.loads(IGNORE_RULES_FILE.read_text())
    except Exception as exc:
        append_audit("ignore_rules_load_failed", error=str(exc))
        return rules
    for key in ("sender_exact", "sender_contains", "subject_contains"):
        values = raw.get(key)
        if isinstance(values, list):
            rules[key] = [str(v).strip().lower() for v in values if str(v).strip()]
    for key in ("account_sender_exact", "account_sender_contains"):
        account_map = raw.get(key)
        if isinstance(account_map, dict):
            normalized = {}
            for account, values in account_map.items():
                if isinstance(values, list):
                    normalized[str(account).strip().lower()] = [
                        str(v).strip().lower() for v in values if str(v).strip()
                    ]
            rules[key] = normalized
    return rules


def extract_sender_email(sender: str) -> str:
    match = re.search(r"<([^>]+)>", sender)
    if match:
        return match.group(1).strip().lower()
    return sender.strip().lower()


def ignored_reason(message: Dict, rules: Dict[str, object]) -> Optional[str]:
    account = (message.get("account") or "").strip().lower()
    sender_raw = (message.get("sender") or "").strip()
    sender_email = extract_sender_email(sender_raw)
    subject = (message.get("subject") or "").strip().lower()
    account_exact = rules.get("account_sender_exact", {}).get(account, [])
    for exact in account_exact:
        if sender_email == exact:
            return f"account_sender_exact:{account}:{exact}"
    account_contains = rules.get("account_sender_contains", {}).get(account, [])
    for token in account_contains:
        if token and (token in sender_email or token in sender_raw.lower()):
            return f"account_sender_contains:{account}:{token}"
    for exact in rules["sender_exact"]:
        if sender_email == exact:
            return f"sender_exact:{exact}"
    for token in rules["sender_contains"]:
        if token and (token in sender_email or token in sender_raw.lower()):
            return f"sender_contains:{token}"
    for token in rules["subject_contains"]:
        if token and token in subject:
            return f"subject_contains:{token}"
    return None


def load_state() -> Dict:
    if STATE_FILE.exists():
        return json.loads(STATE_FILE.read_text())
    return {"processed": {}}


def save_state(state: Dict) -> None:
    STATE_FILE.write_text(json.dumps(state, indent=2))


def run_applescript(script_path: Path) -> str:
    if not script_path.exists():
        raise FileNotFoundError(script_path)
    result = subprocess.run(
        ["osascript", str(script_path)],
        check=True,
        capture_output=True,
        text=True,
        timeout=90,
    )
    return result.stdout.strip()


def fetch_messages() -> List[Dict]:
    raw = run_applescript(FETCH_SCRIPT)
    if not raw:
        return []
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as exc:
        logging.error("Unable to parse Mail payload: %s\nRaw output: %s", exc, raw)
        raise
    return data


def load_messages_from_file(path_str: str) -> List[Dict]:
    path = Path(path_str)
    if not path.exists():
        raise FileNotFoundError(path)
    loaded = json.loads(path.read_text())
    if isinstance(loaded, dict):
        return [loaded]
    if not isinstance(loaded, list):
        raise ValueError("Message JSON must be an object or list of objects")
    return loaded


def classify_reasons(message: Dict) -> List[str]:
    reasons: List[str] = []
    if message.get("flagged"):
        reasons.append("flagged")
    if message.get("hasInvite"):
        reasons.append("invite attachment")
    subject_lower = (message.get("subject") or "").lower()
    body_lower = (message.get("body") or "").lower()
    keyword_hits = [kw for kw in KEYWORDS if kw in subject_lower or kw in body_lower]
    if keyword_hits:
        reasons.append("keywords: " + ", ".join(keyword_hits[:3]))
    return reasons


def parse_iso(date_string: str) -> datetime:
    return datetime.fromisoformat(date_string.replace("Z", "+00:00")).astimezone(LOCAL_TZ)


def find_explicit_time(message: Dict, received_dt: datetime) -> Optional[datetime]:
    snippet = (message.get("subject", "") + ". " + (message.get("body", "")[:MAX_BODY_FOR_PARSING]))
    settings = {
        "PREFER_DATES_FROM": "future",
        "RELATIVE_BASE": received_dt,
        "RETURN_AS_TIMEZONE_AWARE": True,
    }
    try:
        matches = search_dates(snippet, settings=settings)
    except Exception as exc:  # pragma: no cover - defensive
        logging.debug("date parsing failed for %s: %s", message.get("messageID"), exc)
        return None
    if not matches:
        return None
    for _, parsed_dt in matches:
        candidate = parsed_dt
        if candidate.tzinfo is None:
            candidate = candidate.replace(tzinfo=LOCAL_TZ)
        else:
            candidate = candidate.astimezone(LOCAL_TZ)
        if candidate >= received_dt - timedelta(minutes=5):
            return candidate
    return None


def next_business_morning(anchor: datetime, hour: int = 9, minute: int = 0) -> datetime:
    candidate = anchor.astimezone(LOCAL_TZ)
    candidate = candidate.replace(hour=hour, minute=minute, second=0, microsecond=0)
    if candidate <= anchor.astimezone(LOCAL_TZ):
        candidate += timedelta(days=1)
    while candidate.weekday() >= 5:
        candidate += timedelta(days=1)
    return candidate


def default_followup_time(received_dt: datetime) -> datetime:
    local = received_dt.astimezone(LOCAL_TZ)
    if local.hour < 15:
        candidate = local + timedelta(hours=2)
    else:
        candidate = local + timedelta(days=1)
    candidate = candidate.replace(minute=0, second=0, microsecond=0)
    if candidate.hour < 9 or candidate.hour > 18:
        candidate = candidate.replace(hour=9)
    while candidate.weekday() >= 5:
        candidate += timedelta(days=1)
    return candidate


def build_event_window(message: Dict, received_dt: datetime) -> Dict[str, datetime]:
    explicit_start = find_explicit_time(message, received_dt)
    if explicit_start:
        end = explicit_start + timedelta(minutes=EXPLICIT_DURATION_MINUTES)
        return {"start": explicit_start, "end": end, "source": "explicit"}
    start = default_followup_time(received_dt)
    end = start + timedelta(minutes=FOLLOW_UP_DURATION_MINUTES)
    return {"start": start, "end": end, "source": "default"}


def format_notes(message: Dict, reasons: List[str]) -> str:
    parts = [
        f"Sender: {message.get('sender', 'Unknown')}",
        f"Received: {message.get('receivedAt')}",
        f"Mailbox: {message.get('account')} / {message.get('mailbox')}",
        f"Reasons: {', '.join(reasons) if reasons else 'auto triage'}",
        f"Message link: message://{message.get('messageID')}",
        "",
        "Body preview:",
        message.get("body", "").strip(),
    ]
    return "\n".join(parts)


def escape_newlines(text: str) -> str:
    return text.replace("\r", " ").replace("\n", " ").strip()


def create_event(title: str, start: datetime, end: datetime, notes: str) -> Dict[str, str]:
    result = subprocess.run(
        [
            "osascript",
            str(CREATE_SCRIPT),
            title,
            start.astimezone(LOCAL_TZ).isoformat(),
            end.astimezone(LOCAL_TZ).isoformat(),
            notes,
            CALENDAR_NAME,
            str(ALERT_MINUTES),
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    return {
        "uid": result.stdout.strip(),
        "stderr": result.stderr.strip(),
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Mail triage → Calendar")
    parser.add_argument(
        "--message-json",
        help="Path to JSON file containing one or more message records (skips Mail fetch)",
    )
    parser.add_argument(
        "--trigger-source",
        default="manual",
        help="Origin of this run (for audit logs), e.g. mail-rule",
    )
    parser.add_argument(
        "--latest-only",
        action="store_true",
        help="Process only the most recent message after filtering",
    )
    parser.add_argument(
        "--received-after",
        help="Only process messages with receivedAt >= this ISO timestamp",
    )
    parser.add_argument(
        "--log-level",
        default="INFO",
        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
        help="Override log verbosity",
    )
    return parser.parse_args()


def build_response_preview(message: Dict, window: Dict[str, datetime], reasons: List[str]) -> str:
    subject = (message.get("subject") or "(no subject)").strip()
    if window["source"] == "explicit":
        return (
            f"I found a datetime in \"{subject}\". "
            f"I created a calendar event from {window['start'].strftime('%Y-%m-%d %H:%M')} "
            f"to {window['end'].strftime('%H:%M')}."
        )
    reason_text = ", ".join(reasons) if reasons else "auto triage"
    return (
        f"I flagged \"{subject}\" for follow-up ({reason_text}). "
        f"Please confirm if this time works: {window['start'].strftime('%Y-%m-%d %H:%M')}."
    )


def main() -> None:
    args = parse_args()
    setup_logging()
    logging.getLogger().setLevel(getattr(logging, args.log_level))
    append_audit("run_started", triggerSource=args.trigger_source, messageJson=bool(args.message_json))
    if not CREATE_SCRIPT.exists():
        logging.error("Calendar AppleScript is missing.")
        append_audit("run_failed", reason="calendar_script_missing")
        sys.exit(1)

    state = load_state()
    processed = state.setdefault("processed", {})
    ignore_rules = load_ignore_rules()
    append_audit(
        "ignore_rules_loaded",
        senderExact=len(ignore_rules["sender_exact"]),
        senderContains=len(ignore_rules["sender_contains"]),
        subjectContains=len(ignore_rules["subject_contains"]),
        accountSenderExact=sum(len(v) for v in ignore_rules.get("account_sender_exact", {}).values()),
        accountSenderContains=sum(len(v) for v in ignore_rules.get("account_sender_contains", {}).values()),
    )

    if args.message_json:
        messages = load_messages_from_file(args.message_json)
    else:
        if not FETCH_SCRIPT.exists():
            logging.error("Mail fetch AppleScript is missing and no message JSON provided.")
            append_audit("run_failed", reason="mail_fetch_script_missing")
            sys.exit(1)
        try:
            messages = fetch_messages()
        except subprocess.TimeoutExpired:
            logging.error("Mail fetch timed out after 90s.")
            append_audit("run_failed", reason="mail_fetch_timeout")
            sys.exit(1)
        except subprocess.CalledProcessError as exc:
            logging.error("AppleScript failed: %s", exc.stderr)
            append_audit("run_failed", reason="mail_fetch_failed", stderr=exc.stderr.strip())
            sys.exit(exc.returncode)

    if args.received_after:
        try:
            cutoff = parse_iso(args.received_after)
            before = len(messages)
            messages = [m for m in messages if m.get("receivedAt") and parse_iso(m["receivedAt"]) >= cutoff]
            append_audit(
                "messages_filtered_received_after",
                cutoff=args.received_after,
                before=before,
                after=len(messages),
            )
        except Exception as exc:
            append_audit("messages_filter_error", field="received_after", value=args.received_after, error=str(exc))
            logging.warning("Ignoring invalid --received-after value: %s", args.received_after)

    if args.latest_only and messages:
        messages = [max(messages, key=lambda m: m.get("receivedAt", ""))]
        append_audit("messages_filtered_latest_only", count=1)

    logging.info("Processing %d actionable messages", len(messages))
    append_audit("messages_loaded", count=len(messages))
    created = 0
    for message in sorted(messages, key=lambda m: m.get("receivedAt", "")):
        message_id = message.get("messageID")
        if not message_id:
            append_audit("message_skipped", reason="missing_message_id")
            continue
        append_audit(
            "message_processing_started",
            messageID=message_id,
            subject=message.get("subject", ""),
            sender=message.get("sender", ""),
            receivedAt=message.get("receivedAt", ""),
        )
        if message_id in processed:
            append_audit("message_skipped", messageID=message_id, reason="already_processed")
            continue
        ignore_reason = ignored_reason(message, ignore_rules)
        if ignore_reason:
            append_audit(
                "message_skipped",
                messageID=message_id,
                reason="ignore_list",
                ignoreRule=ignore_reason,
                sender=message.get("sender", ""),
                subject=message.get("subject", ""),
            )
            continue
        reasons = classify_reasons(message)
        received_at = parse_iso(message["receivedAt"])
        window = build_event_window(message, received_at)
        subject = message.get("subject") or "(no subject)"
        title = f"MAIL ⇢ {subject[:120]}"
        notes = format_notes(message, reasons)
        response_preview = build_response_preview(message, window, reasons)
        append_audit(
            "response_prepared",
            messageID=message_id,
            response=response_preview,
            scheduleSource=window["source"],
            start=window["start"].isoformat(),
            end=window["end"].isoformat(),
        )
        try:
            append_audit(
                "calendar_create_called",
                messageID=message_id,
                title=title,
                start=window["start"].isoformat(),
                end=window["end"].isoformat(),
            )
            create_result = create_event(title, window["start"], window["end"], notes)
            event_uid = create_result["uid"]
            stderr_text = create_result["stderr"]
            if stderr_text:
                append_audit("calendar_create_warning", messageID=message_id, warning=stderr_text)
        except subprocess.CalledProcessError as exc:
            logging.error("Failed to create event for %s: %s", message_id, exc.stderr)
            append_audit(
                "calendar_create_failed",
                messageID=message_id,
                stderr=(exc.stderr or "").strip(),
            )
            continue
        processed[message_id] = {
            "calendarUID": event_uid,
            "createdAt": datetime.now().astimezone().isoformat(),
            "window": {
                "start": window["start"].isoformat(),
                "end": window["end"].isoformat(),
            },
            "response": response_preview,
        }
        created += 1
        logging.info("Created calendar hold for %s (%s)", message_id, window["source"])
        append_audit(
            "calendar_create_success",
            messageID=message_id,
            calendarUID=event_uid,
            scheduleSource=window["source"],
            response=response_preview,
        )

    save_state(state)
    logging.info("Done. %d new events created.", created)
    append_audit("run_finished", created=created, totalMessages=len(messages))


if __name__ == "__main__":
    main()
