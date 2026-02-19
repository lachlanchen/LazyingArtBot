#!/usr/bin/env python3
"""Apply life reverse-engineering reminder plans with dedupe and rollover logic."""

from __future__ import annotations

import argparse
import hashlib
import html
import json
import subprocess
import sys
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any
from zoneinfo import ZoneInfo

SLOT_ORDER = [
    "day_plan_8am",
    "tomorrow_plan_8pm",
    "week_plan",
    "tonight_milestone",
    "month_milestone",
    "season_milestone",
    "half_year_milestone",
    "one_year_milestone",
]

SLOT_LABEL = {
    "day_plan_8am": "Day Plan 08:00",
    "tomorrow_plan_8pm": "Tomorrow Plan 20:00",
    "week_plan": "Week Plan",
    "tonight_milestone": "Tonight Milestone",
    "month_milestone": "Month Milestone",
    "season_milestone": "Season Milestone",
    "half_year_milestone": "Half-Year Milestone",
    "one_year_milestone": "One-Year Milestone",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Apply life reverse reminder plan")
    parser.add_argument("--plan-json", required=True)
    parser.add_argument("--state-json", required=True)
    parser.add_argument("--state-md", required=True)
    parser.add_argument("--report-json", required=True)
    parser.add_argument("--report-md", required=True)
    parser.add_argument("--report-html", required=True)
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--list-name", default="LazyingArt")
    parser.add_argument("--timezone", default="Asia/Hong_Kong")
    parser.add_argument(
        "--create-reminder-script",
        default="/Users/lachlan/.openclaw/workspace/automation/create_reminder.applescript",
    )
    return parser.parse_args()


def ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def parse_iso(value: str, tz: ZoneInfo) -> datetime | None:
    raw = (value or "").strip()
    if not raw:
        return None
    try:
        dt = datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except ValueError:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=tz)
    return dt.astimezone(tz)


def first_of_next_month(now: datetime) -> datetime:
    y = now.year
    m = now.month + 1
    if m == 13:
        y += 1
        m = 1
    return now.replace(year=y, month=m, day=1, hour=9, minute=0, second=0, microsecond=0)


def next_quarter_start(now: datetime) -> datetime:
    quarter_months = [1, 4, 7, 10]
    next_month = None
    for m in quarter_months:
        if now.month < m:
            next_month = m
            break
    if next_month is None:
        return now.replace(year=now.year + 1, month=1, day=1, hour=9, minute=0, second=0, microsecond=0)
    return now.replace(month=next_month, day=1, hour=9, minute=0, second=0, microsecond=0)


def next_half_year_start(now: datetime) -> datetime:
    candidates = [(1, 1), (7, 1)]
    for month, day in candidates:
        cand = now.replace(month=month, day=day, hour=9, minute=0, second=0, microsecond=0)
        if cand > now:
            return cand
    return now.replace(year=now.year + 1, month=1, day=1, hour=9, minute=0, second=0, microsecond=0)


def fallback_due(slot: str, now: datetime) -> datetime:
    if slot == "day_plan_8am":
        dt = now.replace(hour=8, minute=0, second=0, microsecond=0)
        if dt <= now:
            dt += timedelta(days=1)
        return dt
    if slot == "tomorrow_plan_8pm":
        dt = now.replace(hour=20, minute=0, second=0, microsecond=0)
        if dt <= now:
            dt += timedelta(days=1)
        return dt
    if slot == "week_plan":
        # Sunday 20:00 local
        days = (6 - now.weekday()) % 7
        dt = (now + timedelta(days=days)).replace(hour=20, minute=0, second=0, microsecond=0)
        if dt <= now:
            dt += timedelta(days=7)
        return dt
    if slot == "tonight_milestone":
        dt = now.replace(hour=21, minute=0, second=0, microsecond=0)
        if dt <= now:
            dt += timedelta(days=1)
        return dt
    if slot == "month_milestone":
        return first_of_next_month(now)
    if slot == "season_milestone":
        return next_quarter_start(now)
    if slot == "half_year_milestone":
        return next_half_year_start(now)
    if slot == "one_year_milestone":
        return now.replace(year=now.year + 1, month=1, day=1, hour=10, minute=0, second=0, microsecond=0)
    return now + timedelta(days=1)


def run_osascript(script: str, *args: str) -> str:
    proc = subprocess.run(["osascript", "-", *args], input=script, text=True, capture_output=True)
    if proc.returncode != 0:
        raise RuntimeError((proc.stderr or proc.stdout or "osascript failed").strip())
    return proc.stdout


def fetch_life_reminders(list_name: str) -> list[dict[str, str]]:
    script = r'''
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
	set cleanText to do shell script "printf '%s' " & quoted form of safeText & " | tr '\\r\\n' '  '"
	return cleanText
end oneLine

on run argv
	set listName to item 1 of argv
	set fs to character id 31
	set rs to character id 30
	set outText to ""
	tell application "Reminders"
		if not (exists list listName) then return ""
		set targetList to list listName
		repeat with r in reminders of targetList
			set rid to ""
			set rname to ""
			set rbody to ""
			set doneText to "0"
			set dueText to ""
			try
				set rid to id of r as text
			end try
			try
				set rname to my oneLine(name of r)
			end try
			try
				set rbody to my oneLine(body of r)
			end try
			try
				if completed of r then set doneText to "1"
			end try
			try
				set dueValue to due date of r
				if dueValue is not missing value then set dueText to my isoStringFromDate(dueValue)
			end try
			set outText to outText & rid & fs & rname & fs & rbody & fs & doneText & fs & dueText & rs
		end repeat
	end tell
	return outText
end run
'''
    out = run_osascript(script, list_name)
    fs = chr(31)
    rs = chr(30)
    reminders: list[dict[str, str]] = []
    for rec in out.split(rs):
        rec = rec.strip()
        if not rec:
            continue
        parts = rec.split(fs)
        if len(parts) < 5:
            continue
        reminders.append(
            {
                "id": parts[0],
                "name": parts[1],
                "body": parts[2],
                "completed": "1" if parts[3] == "1" else "0",
                "due_iso": parts[4],
            }
        )
    return reminders


def complete_reminder(list_name: str, reminder_id: str) -> str:
    script = r'''
on run argv
	set listName to item 1 of argv
	set rid to item 2 of argv
	tell application "Reminders"
		if not (exists list listName) then return "list_missing"
		set targetList to list listName
		repeat with r in reminders of targetList
			try
				if (id of r as text) is rid then
					set completed of r to true
					return "completed"
				end if
			end try
		end repeat
	end tell
	return "not_found"
end run
'''
    return run_osascript(script, list_name, reminder_id).strip() or "unknown"


def create_reminder(script_path: Path, title: str, due_iso: str, notes: str, list_name: str, minutes: int) -> str:
    proc = subprocess.run(
        ["osascript", str(script_path), title, due_iso, notes, list_name, str(minutes)],
        text=True,
        capture_output=True,
    )
    if proc.returncode != 0:
        raise RuntimeError((proc.stderr or proc.stdout or "create_reminder_failed").strip())
    return (proc.stdout or "").strip()


def parse_slot(name: str) -> tuple[str, str]:
    raw = (name or "").strip()
    if raw.startswith("[LA-LIFE][") and "]" in raw[10:]:
        rest = raw[10:]
        slot, tail = rest.split("]", 1)
        return slot.strip(), tail.strip()
    return "", raw


def extract_duplication_key(body: str) -> str:
    raw = (body or "").strip()
    if not raw:
        return ""
    markers = ("[DUP_KEY]", "[DUPLICATION_KEY]", "[DuplicationKey]")
    for line in raw.splitlines():
        clean = line.strip()
        for marker in markers:
            if clean.startswith(marker):
                return clean.replace(marker, "", 1).strip(" :")
    return ""


def normalize_plan(plan: dict[str, Any], now: datetime) -> list[dict[str, Any]]:
    by_slot: dict[str, dict[str, Any]] = {}
    for item in plan.get("reminders") or []:
        if not isinstance(item, dict):
            continue
        slot = str(item.get("slot", "")).strip()
        if slot in SLOT_ORDER and slot not in by_slot:
            by_slot[slot] = item

    out: list[dict[str, Any]] = []
    for slot in SLOT_ORDER:
        item = by_slot.get(slot, {})
        title = str(item.get("title", "")).strip() or SLOT_LABEL[slot]
        due_dt = parse_iso(str(item.get("due_iso", "")), now.tzinfo) or fallback_due(slot, now)
        minutes = int(item.get("reminder_minutes", 20) or 20)
        if minutes < 0:
            minutes = 0
        if minutes > 240:
            minutes = 240
        notes_md = str(item.get("notes_markdown", "")).strip() or f"- Keep {SLOT_LABEL[slot]} moving"
        duplication_key = str(item.get("duplication_key", f"{slot}:{title.lower()}"))
        rationale = str(item.get("rationale", "")).strip() or "stable slot"
        out.append(
            {
                "slot": slot,
                "title": title,
                "due_dt": due_dt,
                "due_iso": due_dt.isoformat(timespec="seconds"),
                "reminder_minutes": minutes,
                "notes_markdown": notes_md,
                "duplication_key": duplication_key,
                "rationale": rationale,
            }
        )
    return out


def fingerprint(slot: str, title: str, due_iso: str, notes: str, minutes: int) -> str:
    base = f"{slot}|{title.strip().lower()}|{due_iso[:16]}|{notes.strip().lower()}|{minutes}"
    return hashlib.sha1(base.encode("utf-8")).hexdigest()[:16]


def due_close(a: str, b: str, tz: ZoneInfo) -> bool:
    da = parse_iso(a, tz)
    db = parse_iso(b, tz)
    if da is None or db is None:
        return False
    return abs((da - db).total_seconds()) <= 15 * 60


def render_markdown(run_id: str, summary: str, strategy_md: str, results: list[dict[str, Any]]) -> str:
    lines = [
        f"# LazyingArt Life Reverse Plan ({run_id})",
        "",
        f"- Updated: {datetime.now().astimezone().isoformat(timespec='seconds')}",
        f"- Summary: {summary}",
        "",
        "## Strategy",
        "",
        strategy_md.strip() or "(empty)",
        "",
        "## Reminder Slots",
        "",
        "| Slot | Title | Due | Action | Status |",
        "|---|---|---|---|---|",
    ]
    for r in results:
        lines.append(
            "| {slot} | {title} | {due} | {action} | {status} |".format(
                slot=r.get("slot", ""),
                title=str(r.get("title", "")).replace("|", "/"),
                due=r.get("due_iso", ""),
                action=r.get("action", ""),
                status=r.get("status", ""),
            )
        )
    lines.append("")
    lines.append("## Detailed Results")
    lines.append("")
    for r in results:
        lines.append(f"### {r.get('slot', '')} · {r.get('title', '')}")
        lines.append(f"- Action: {r.get('action', '')}")
        lines.append(f"- Status: {r.get('status', '')}")
        lines.append(f"- Reminder ID: {r.get('new_id', '') or r.get('existing_id', '')}")
        if r.get("error"):
            lines.append(f"- Error: {r.get('error')}")
        lines.append(f"- Rationale: {r.get('rationale', '')}")
        lines.append("")
    return "\n".join(lines).strip() + "\n"


def markdown_to_html(md_text: str) -> str:
    lines = md_text.splitlines()
    html_lines = [
        "<h1>🗓️ LazyingArt Life Reverse Plan</h1>",
        "<table border='1' cellpadding='6' cellspacing='0' style='border-collapse:collapse;'>",
        "<tr><th>Slot</th><th>Title</th><th>Due</th><th>Action</th><th>Status</th></tr>",
    ]
    in_table = False
    for line in lines:
        if line.startswith("| ") and not line.startswith("|---"):
            cols = [c.strip() for c in line.strip().strip("|").split("|")]
            if len(cols) == 5 and cols[0] != "Slot":
                in_table = True
                html_lines.append(
                    "<tr>"
                    + "".join(f"<td>{html.escape(c)}</td>" for c in cols)
                    + "</tr>"
                )
    if in_table:
        html_lines.append("</table>")
    html_lines.append("<p><em>See markdown mirror for full details.</em></p>")
    return "\n".join(html_lines)


def main() -> int:
    args = parse_args()
    tz = ZoneInfo(args.timezone)
    now = datetime.now(tz)

    plan_path = Path(args.plan_json).expanduser().resolve()
    state_json_path = Path(args.state_json).expanduser().resolve()
    state_md_path = Path(args.state_md).expanduser().resolve()
    report_json_path = Path(args.report_json).expanduser().resolve()
    report_md_path = Path(args.report_md).expanduser().resolve()
    report_html_path = Path(args.report_html).expanduser().resolve()
    create_script = Path(args.create_reminder_script).expanduser().resolve()

    ensure_parent(state_json_path)
    ensure_parent(state_md_path)
    ensure_parent(report_json_path)
    ensure_parent(report_md_path)
    ensure_parent(report_html_path)

    if not plan_path.exists():
        raise FileNotFoundError(f"Missing plan JSON: {plan_path}")
    if not create_script.exists():
        raise FileNotFoundError(f"Missing reminder script: {create_script}")

    plan = json.loads(plan_path.read_text(encoding="utf-8"))
    summary = str(plan.get("summary", "")).strip()
    strategy_md = str(plan.get("strategy_markdown", "")).strip()
    desired = normalize_plan(plan, now)

    existing = fetch_life_reminders(args.list_name)
    open_by_slot: dict[str, list[dict[str, str]]] = {slot: [] for slot in SLOT_ORDER}
    done_by_slot: dict[str, list[dict[str, str]]] = {slot: [] for slot in SLOT_ORDER}

    for item in existing:
        slot, bare = parse_slot(item.get("name", ""))
        if slot not in open_by_slot:
            continue
        item["bare_title"] = bare
        item["duplication_key"] = extract_duplication_key(item.get("body", ""))
        if item.get("completed") == "1":
            done_by_slot[slot].append(item)
        else:
            open_by_slot[slot].append(item)

    created_count = 0
    kept_count = 0
    completed_old_count = 0
    failed_count = 0
    results: list[dict[str, Any]] = []
    slot_state: dict[str, Any] = {}

    for item in desired:
        slot = item["slot"]
        planned_title = item["title"]
        reminder_title = f"[LA-LIFE][{slot}] {planned_title}"
        due_iso = item["due_iso"]
        desired_key = item["duplication_key"]
        notes = (
            f"[LA-LIFE slot] {slot}\n"
            f"[Generated] {now.isoformat(timespec='seconds')}\n"
            f"[Rationale] {item['rationale']}\n\n"
            f"[DuplicationKey] {desired_key}\n\n"
            f"{item['notes_markdown']}"
        )
        sig = fingerprint(slot, planned_title, due_iso, item["notes_markdown"], item["reminder_minutes"])

        open_items = open_by_slot.get(slot, [])
        same_open = None
        for ex in open_items:
            if desired_key and ex.get("duplication_key") and ex.get("duplication_key") == desired_key:
                same_open = ex
                break
            if ex.get("bare_title", "").strip() == planned_title.strip() and due_close(ex.get("due_iso", ""), due_iso, tz):
                same_open = ex
                break

        result: dict[str, Any] = {
            "slot": slot,
            "title": planned_title,
            "due_iso": due_iso,
            "rationale": item["rationale"],
            "fingerprint": sig,
            "action": "",
            "status": "",
            "existing_id": "",
            "new_id": "",
            "error": "",
        }

        # If same reminder already open, keep it.
        if same_open is not None:
            kept_count += 1
            for ex in open_items:
                if ex.get("id") == same_open.get("id"):
                    continue
                outcome = complete_reminder(args.list_name, ex.get("id", ""))
                if outcome in {"completed", "ok"}:
                    completed_old_count += 1
            result["action"] = "keep"
            result["status"] = "ok"
            result["existing_id"] = same_open.get("id", "")
            slot_state[slot] = {
                "status": "kept",
                "id": same_open.get("id", ""),
                "title": planned_title,
                "due_iso": due_iso,
                "fingerprint": sig,
                "updated_at": now.isoformat(timespec="seconds"),
            }
            results.append(result)
            continue

        try:
            # Complete old open reminders for this slot to prevent duplication.
            for ex in open_items:
                outcome = complete_reminder(args.list_name, ex.get("id", ""))
                if outcome in {"completed", "ok"}:
                    completed_old_count += 1

            # Create the new slot reminder.
            new_id = create_reminder(
                create_script,
                reminder_title,
                due_iso,
                notes,
                args.list_name,
                int(item["reminder_minutes"]),
            )
            created_count += 1
            result["action"] = "replace_or_create"
            result["status"] = "ok"
            result["new_id"] = new_id
            slot_state[slot] = {
                "status": "created",
                "id": new_id,
                "title": planned_title,
                "due_iso": due_iso,
                "fingerprint": sig,
                "updated_at": now.isoformat(timespec="seconds"),
            }
        except Exception as exc:  # noqa: BLE001
            failed_count += 1
            result["action"] = "replace_or_create"
            result["status"] = "failed"
            result["error"] = str(exc)
            slot_state[slot] = {
                "status": "failed",
                "id": "",
                "title": planned_title,
                "due_iso": due_iso,
                "fingerprint": sig,
                "updated_at": now.isoformat(timespec="seconds"),
                "error": str(exc),
            }

        results.append(result)

    status = "ok" if failed_count == 0 else "partial"
    summary_out = (
        f"life reminders: created={created_count}, kept={kept_count}, "
        f"completed_old={completed_old_count}, failed={failed_count}"
    )

    state_payload = {
        "updated_at": now.isoformat(timespec="seconds"),
        "run_id": args.run_id,
        "list_name": args.list_name,
        "summary": summary,
        "strategy_markdown": strategy_md,
        "slots": slot_state,
    }
    state_json_path.write_text(json.dumps(state_payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    report_md = render_markdown(args.run_id, summary, strategy_md, results)
    report_html = markdown_to_html(report_md)

    report_md_path.write_text(report_md, encoding="utf-8")
    report_html_path.write_text(report_html, encoding="utf-8")
    state_md_path.write_text(report_md, encoding="utf-8")

    report = {
        "status": status,
        "summary": summary_out,
        "planner_summary": summary,
        "created_count": created_count,
        "kept_count": kept_count,
        "completed_old_count": completed_old_count,
        "failed_count": failed_count,
        "state_json": str(state_json_path),
        "state_md": str(state_md_path),
        "report_md": str(report_md_path),
        "report_html": str(report_html_path),
        "slots": results,
    }

    report_json_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
