#!/usr/bin/env python3
"""Rename iCloud Notes titles based on note contents.

Default behavior is conservative: rename only notes with generic/bad titles.
Use --all to retitle every non-deleted note.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from collections import Counter
from datetime import datetime
from pathlib import Path
from typing import Dict, List
from urllib.parse import urlparse

REC_SEP = "\x1e"
FIELD_SEP = "\x1f"
PLACEHOLDER_CHARS = {"\ufffc", "\u200b"}
GENERIC_NAMES = {
    "",
    "new note",
    "newnote",
    "note",
    "notes",
    "untitled",
    "新备忘录",
    "g",
    "water",
}


def run_osascript(script: str, *args: str) -> str:
    cmd = ["osascript", "-", *args]
    proc = subprocess.run(cmd, input=script, text=True, capture_output=True)
    if proc.returncode != 0:
        raise RuntimeError((proc.stderr or proc.stdout or "osascript failed").strip())
    return proc.stdout


def fetch_notes(account: str) -> List[Dict[str, str]]:
    script = r'''
on run argv
set recSep to character id 30
set fieldSep to character id 31

tell application "Notes"
  set acc to account (item 1 of argv)
  set outText to ""
  repeat with f in folders of acc
    set fname to name of f as text
    repeat with n in notes of f
      set nid to id of n as text
      set nname to name of n as text
      set ptxt to ""
      try
        set ptxt to plaintext of n as text
      end try
      set outText to outText & nid & fieldSep & fname & fieldSep & nname & fieldSep & ptxt & recSep
    end repeat
  end repeat
end tell
return outText
end run
'''
    raw = run_osascript(script, account)
    rows: List[Dict[str, str]] = []
    for rec in raw.split(REC_SEP):
        if not rec.strip():
            continue
        parts = rec.split(FIELD_SEP)
        if len(parts) < 4:
            continue
        rows.append({"id": parts[0], "folder": parts[1], "name": parts[2], "plain": parts[3]})
    return rows


def fetch_note_body(note_id: str) -> str:
    script = r'''
on run argv
set noteID to item 1 of argv
tell application "Notes"
  set found to first note whose id is noteID
  return body of found as text
end tell
end run
'''
    return run_osascript(script, note_id)


def rename_note(note_id: str, new_name: str) -> None:
    script = r'''
on run argv
set noteID to item 1 of argv
set targetName to item 2 of argv

tell application "Notes"
  set found to first note whose id is noteID
  set name of found to targetName
end tell
end run
'''
    run_osascript(script, note_id, new_name)


def normalize_spaces(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def clean_plain(text: str) -> str:
    cleaned = "".join(ch for ch in text if ch not in PLACEHOLDER_CHARS)
    return cleaned.strip()


def looks_generic(name: str) -> bool:
    n = normalize_spaces(name).lower()
    if n in GENERIC_NAMES:
        return True
    if len(n) <= 2:
        return True
    if n.startswith("new note"):
        return True
    return False


def extract_urls(text: str) -> List[str]:
    return re.findall(r"https?://[^\s<>'\"]+", text)


def title_from_content(current_name: str, plain: str, body: str, note_id: str) -> str:
    lines = [normalize_spaces(x) for x in plain.splitlines() if normalize_spaces(x)]
    lname = normalize_spaces(current_name).lower()

    # Drop duplicated heading lines equal to current note name.
    filtered = [x for x in lines if x.lower() != lname]
    lines = filtered or lines

    for line in lines:
        if len(line) < 3:
            continue
        # URL-only line
        if re.fullmatch(r"https?://[^\s]+", line):
            u = urlparse(line)
            host = u.netloc or line
            return f"Link - {host}"[:60]
        return line[:60]

    urls = extract_urls(body)
    if urls:
        u = urlparse(urls[0])
        host = u.netloc or urls[0]
        return f"Link - {host}"[:60]

    pid = re.search(r"/p(\d+)$", note_id)
    suffix = pid.group(1) if pid else note_id[-6:]
    if lname in {"g", "water"}:
        return f"Sketch {current_name.strip().upper()} {suffix}"[:60]
    return f"Sketch Note {suffix}"[:60]


def uniquify(base: str, used: Counter) -> str:
    base = normalize_spaces(base)[:60]
    if not base:
        base = "Untitled Note"
    if used[base] == 0:
        used[base] += 1
        return base
    i = used[base] + 1
    while True:
        candidate = f"{base[:54]} ({i})"
        if used[candidate] == 0:
            used[base] += 1
            used[candidate] += 1
            return candidate
        i += 1


def main() -> int:
    parser = argparse.ArgumentParser(description="Rename iCloud note titles based on content")
    parser.add_argument("--account", default="iCloud")
    parser.add_argument("--all", action="store_true", help="Retitle all non-deleted notes")
    parser.add_argument("--apply", action="store_true", help="Apply changes (default is dry-run)")
    args = parser.parse_args()

    notes = fetch_notes(args.account)
    active_notes = [n for n in notes if n["folder"] != "Recently Deleted"]
    used_names = Counter(normalize_spaces(n["name"]) for n in active_notes if normalize_spaces(n["name"]))

    proposals = []
    for n in active_notes:
        current = normalize_spaces(n["name"])
        generic = looks_generic(current)
        if not args.all and not generic:
            continue

        plain = clean_plain(n["plain"])
        body = ""
        if not plain:
            try:
                body = fetch_note_body(n["id"])
            except Exception:
                body = ""

        new_base = title_from_content(current, plain, body, n["id"])
        if not new_base:
            continue
        if normalize_spaces(new_base) == current:
            continue

        # Reserve current name out of used set before assigning a new one.
        if current and used_names[current] > 0:
            used_names[current] -= 1
        new_name = uniquify(new_base, used_names)
        proposals.append({
            "id": n["id"],
            "folder": n["folder"],
            "old": current,
            "new": new_name,
        })

    ts = datetime.now().strftime("%Y%m%d-%H%M%S")
    log_dir = Path.home() / ".openclaw/workspace/logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    plan_path = log_dir / f"icloud_notes_rename_plan_{ts}.tsv"

    lines = ["folder\told_name\tnew_name\tnote_id"]
    for p in proposals:
        lines.append(f"{p['folder']}\t{p['old']}\t{p['new']}\t{p['id']}")
    plan_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(f"account={args.account} total_notes={len(active_notes)} proposals={len(proposals)}")
    print(f"plan={plan_path}")
    for p in proposals:
        print(f"- [{p['folder']}] {p['old']} -> {p['new']}")

    if not args.apply:
        print("mode=dry-run")
        return 0

    renamed = 0
    failed = 0
    for p in proposals:
        try:
            rename_note(p["id"], p["new"])
            renamed += 1
        except Exception as exc:
            failed += 1
            print(f"! rename_failed id={p['id']} err={exc}", file=sys.stderr)

    print(f"mode=apply renamed={renamed} failed={failed}")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
