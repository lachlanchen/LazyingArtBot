#!/usr/bin/env python3
"""
Draft and optionally send an email via Apple Mail using Codex non-interactive output.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_PROMPT_TOOLS = SCRIPT_DIR / "prompt_tools"
DEFAULT_MODEL = "gpt-5.1-codex-mini"
DEFAULT_REASONING = "medium"

EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def parse_email_tokens(items: list[str] | None) -> list[str]:
    if not items:
        return []
    out: list[str] = []
    seen: set[str] = set()
    for item in items:
        for token in re.split(r"[,\n]", item):
            t = token.strip()
            if not t:
                continue
            lower = t.lower()
            if lower in seen:
                continue
            if not EMAIL_RE.match(lower):
                raise ValueError(f"Invalid email address: {t}")
            seen.add(lower)
            out.append(lower)
    return out


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8").strip()


def build_prompt(
    *,
    instruction: str,
    to_hint: list[str],
    cc_hint: list[str],
    bcc_hint: list[str],
    prompt_tools_dir: Path,
) -> str:
    base_prompt = read_text(prompt_tools_dir / "email_send_prompt.md")
    common_tools = read_text(prompt_tools_dir / "common_tools.md")
    now_iso = datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds")

    payload = {
        "now_local_iso": now_iso,
        "instruction": instruction,
        "recipient_hints": {"to": to_hint, "cc": cc_hint, "bcc": bcc_hint},
    }

    return (
        f"{base_prompt}\n\n"
        f"Common tools:\n{common_tools}\n\n"
        "Task payload JSON:\n"
        f"{json.dumps(payload, ensure_ascii=False, indent=2)}\n\n"
        "Return JSON only."
    )


def run_codex(
    *,
    codex_bin: str,
    model: str,
    reasoning: str,
    schema_path: Path,
    prompt: str,
    skip_git_check: bool,
) -> dict[str, Any]:
    with tempfile.NamedTemporaryFile(mode="w+", suffix=".json", delete=False) as out_file:
        out_path = Path(out_file.name)

    cmd = [
        codex_bin,
        "exec",
        "--model",
        model,
        "-c",
        f'model_reasoning_effort="{reasoning}"',
        "--output-schema",
        str(schema_path),
        "--output-last-message",
        str(out_path),
    ]
    if skip_git_check:
        cmd.append("--skip-git-repo-check")
    cmd.append("-")

    proc = subprocess.run(
        cmd,
        input=prompt,
        text=True,
        capture_output=True,
    )
    if proc.returncode != 0:
        err = (proc.stderr or proc.stdout or "codex exec failed").strip()
        raise RuntimeError(err)

    raw = out_path.read_text(encoding="utf-8").strip()
    out_path.unlink(missing_ok=True)
    if not raw:
        raise RuntimeError("codex output is empty")

    try:
        parsed = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"codex output is not valid JSON: {exc}") from exc

    if not isinstance(parsed, dict):
        raise RuntimeError("codex output JSON must be an object")
    return parsed


def normalize_action(
    action: dict[str, Any],
    *,
    to_override: list[str],
    cc_override: list[str],
    bcc_override: list[str],
    subject_override: str | None,
) -> dict[str, Any]:
    to_list = to_override or parse_email_tokens(action.get("to"))
    cc_list = cc_override or parse_email_tokens(action.get("cc"))
    bcc_list = bcc_override or parse_email_tokens(action.get("bcc"))

    if not to_list:
        raise RuntimeError("No recipient in result. Use --to or provide clearer instruction.")

    subject = (subject_override or str(action.get("subject", "")).strip()).strip()
    body = str(action.get("body", "")).strip()
    send = bool(action.get("send", False))
    confidence = float(action.get("confidence", 0.0))
    reason = str(action.get("reason", "")).strip()

    if not subject:
        raise RuntimeError("Generated subject is empty.")
    if not body:
        raise RuntimeError("Generated body is empty.")

    return {
        "to": to_list,
        "cc": cc_list,
        "bcc": bcc_list,
        "subject": subject,
        "body": body,
        "send": send,
        "confidence": confidence,
        "reason": reason,
    }


def send_via_mail(action: dict[str, Any]) -> str:
    to_text = "\n".join(action["to"])
    cc_text = "\n".join(action["cc"])
    bcc_text = "\n".join(action["bcc"])

    with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", delete=False) as subj_file:
        subj_file.write(action["subject"])
        subject_path = subj_file.name
    with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", delete=False) as body_file:
        body_file.write(action["body"])
        body_path = body_file.name

    applescript = r'''
on trimText(t)
	set txt to t as text
	set wsChars to {space, tab, return, linefeed}
	repeat while txt is not "" and wsChars contains character 1 of txt
		set txt to text 2 thru -1 of txt
	end repeat
	repeat while txt is not "" and wsChars contains character -1 of txt
		set txt to text 1 thru -2 of txt
	end repeat
	return txt
end trimText

on parseRecipients(rawText)
	set outList to {}
	if rawText is "" then return outList
	repeat with lineText in paragraphs of rawText
		set addr to my trimText(lineText as text)
		if addr is not "" then set end of outList to addr
	end repeat
	return outList
end parseRecipients

on addRecipients(msg, rawText, recipientKind)
	set addrs to my parseRecipients(rawText)
	repeat with addr in addrs
		if recipientKind is "to" then
			tell msg to make new to recipient at end of to recipients with properties {address:(addr as text)}
		else if recipientKind is "cc" then
			tell msg to make new cc recipient at end of cc recipients with properties {address:(addr as text)}
		else if recipientKind is "bcc" then
			tell msg to make new bcc recipient at end of bcc recipients with properties {address:(addr as text)}
		end if
	end repeat
end addRecipients

on run argv
	set toRaw to item 1 of argv
	set ccRaw to item 2 of argv
	set bccRaw to item 3 of argv
	set subjectPath to item 4 of argv
	set bodyPath to item 5 of argv
	set subjectText to read (POSIX file subjectPath) as «class utf8»
	set bodyText to read (POSIX file bodyPath) as «class utf8»

	tell application "Mail"
		set msg to make new outgoing message with properties {subject:subjectText, content:bodyText & return & return, visible:false}
		my addRecipients(msg, toRaw, "to")
		my addRecipients(msg, ccRaw, "cc")
		my addRecipients(msg, bccRaw, "bcc")
		tell msg to send
	end tell

	return "sent"
end run
'''

    proc = subprocess.run(
        ["osascript", "-", to_text, cc_text, bcc_text, subject_path, body_path],
        input=applescript,
        text=True,
        capture_output=True,
    )

    Path(subject_path).unlink(missing_ok=True)
    Path(body_path).unlink(missing_ok=True)

    if proc.returncode != 0:
        err = (proc.stderr or proc.stdout or "osascript failed").strip()
        raise RuntimeError(err)
    return (proc.stdout or "sent").strip()


def main() -> int:
    parser = argparse.ArgumentParser(description="Draft/send email via Codex + Apple Mail")
    parser.add_argument("--instruction", help="User request for the email content")
    parser.add_argument("--to", action="append", help="To recipient(s), comma-separated or repeated")
    parser.add_argument("--cc", action="append", help="CC recipient(s), comma-separated or repeated")
    parser.add_argument("--bcc", action="append", help="BCC recipient(s), comma-separated or repeated")
    parser.add_argument("--subject", help="Force subject override")
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--reasoning", default=DEFAULT_REASONING)
    parser.add_argument("--codex-bin", default="codex")
    parser.add_argument("--prompt-tools-dir", default=str(DEFAULT_PROMPT_TOOLS))
    parser.add_argument("--skip-git-check", action="store_true")
    parser.add_argument("--send", action="store_true", help="Actually send email via Apple Mail")
    parser.add_argument("--output-json", help="Write normalized action JSON to path")
    args = parser.parse_args()

    instruction = (args.instruction or "").strip()
    if not instruction:
        if sys.stdin.isatty():
            parser.error("Provide --instruction or pipe text via stdin.")
        instruction = sys.stdin.read().strip()
    if not instruction:
        parser.error("Instruction is empty.")

    to_hint = parse_email_tokens(args.to)
    cc_hint = parse_email_tokens(args.cc)
    bcc_hint = parse_email_tokens(args.bcc)

    prompt_tools_dir = Path(args.prompt_tools_dir).expanduser().resolve()
    schema_path = prompt_tools_dir / "email_send_schema.json"
    if not schema_path.exists():
        raise RuntimeError(f"Schema file missing: {schema_path}")

    prompt = build_prompt(
        instruction=instruction,
        to_hint=to_hint,
        cc_hint=cc_hint,
        bcc_hint=bcc_hint,
        prompt_tools_dir=prompt_tools_dir,
    )

    action_raw = run_codex(
        codex_bin=args.codex_bin,
        model=args.model,
        reasoning=args.reasoning,
        schema_path=schema_path,
        prompt=prompt,
        skip_git_check=args.skip_git_check,
    )

    action = normalize_action(
        action_raw,
        to_override=to_hint,
        cc_override=cc_hint,
        bcc_override=bcc_hint,
        subject_override=args.subject,
    )

    if args.output_json:
        Path(args.output_json).expanduser().write_text(
            json.dumps(action, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

    print("=== Email Action ===")
    print(f"to: {', '.join(action['to'])}")
    if action["cc"]:
        print(f"cc: {', '.join(action['cc'])}")
    if action["bcc"]:
        print(f"bcc: {', '.join(action['bcc'])}")
    print(f"subject: {action['subject']}")
    print(f"confidence: {action['confidence']:.2f}")
    print(f"send_suggested_by_model: {action['send']}")
    print("----- body -----")
    print(action["body"])

    if not args.send:
        print("-----")
        print("Dry run complete. Re-run with --send to send via Apple Mail.")
        return 0

    result = send_via_mail(action)
    print(f"Mail result: {result}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
