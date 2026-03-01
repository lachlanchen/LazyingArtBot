#!/usr/bin/env python3
"""Force iCloud Notes title sync by prepending title into note body when first line is empty/image-only."""

from __future__ import annotations

import argparse
import html
import subprocess
from pathlib import Path

REC = "\x1e"
SEP = "\x1f"
PLACEHOLDER = "\ufffc"


def run_osascript(script: str, *args: str) -> str:
    proc = subprocess.run(["osascript", "-", *args], input=script, text=True, capture_output=True)
    if proc.returncode != 0:
        raise RuntimeError((proc.stderr or proc.stdout or "osascript failed").strip())
    return proc.stdout


def fetch_index(account: str):
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
        set firstLine to ""
        try
          set firstLine to paragraph 1 of ptxt
        end try
        set outText to outText & nid & fieldSep & fname & fieldSep & nname & fieldSep & firstLine & recSep
      end repeat
    end repeat
  end tell
  return outText
end run
'''
    raw = run_osascript(script, account)
    rows = []
    for rec in raw.split(REC):
        if not rec.strip():
            continue
        parts = rec.split(SEP)
        if len(parts) < 4:
            continue
        rows.append({"id": parts[0], "folder": parts[1], "name": parts[2], "first": parts[3]})
    return rows


def fetch_body(note_id: str) -> str:
    script = r'''
on run argv
  tell application "Notes"
    set n to first note whose id is (item 1 of argv)
    return body of n as text
  end tell
end run
'''
    return run_osascript(script, note_id)


def set_body_and_name(note_id: str, new_body: str, title: str) -> None:
    script = r'''
on run argv
  set noteID to item 1 of argv
  set noteBody to item 2 of argv
  set noteName to item 3 of argv
  tell application "Notes"
    set n to first note whose id is noteID
    set body of n to noteBody
    set name of n to noteName
  end tell
  return "ok"
end run
'''
    run_osascript(script, note_id, new_body, title)


def is_blank_first(first: str) -> bool:
    cleaned = first.replace(PLACEHOLDER, "").strip()
    return cleaned == ""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--account", default="iCloud")
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()

    rows = fetch_index(args.account)
    candidates = [r for r in rows if r["folder"] != "Recently Deleted" and is_blank_first(r["first"]) and r["name"].strip()]

    print(f"account={args.account} total={len(rows)} candidates={len(candidates)}")

    changed = 0
    for r in candidates:
      title = r["name"].strip()
      body = fetch_body(r["id"])
      prefix = f"<div><b>{html.escape(title)}</b></div><div><br></div>"
      if body.startswith(prefix):
          print(f"skip_already_prefixed id={r['id']} name={title}")
          continue
      print(f"plan id={r['id']} folder={r['folder']} name={title}")
      if args.apply:
          set_body_and_name(r["id"], prefix + body, title)
          changed += 1

    print(f"mode={'apply' if args.apply else 'dry-run'} changed={changed}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
