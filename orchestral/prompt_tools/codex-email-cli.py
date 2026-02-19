#!/usr/bin/env python3
"""
Draft and optionally send an email via Apple Mail using Codex non-interactive output.
"""

from __future__ import annotations

import argparse
import html
import json
import re
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
import os


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_PROMPT_TOOLS = SCRIPT_DIR
DEFAULT_MODEL = "gpt-5.3-codex-spark"
DEFAULT_REASONING = "high"
DEFAULT_SAFETY = os.environ.get("CODEX_SAFETY", "danger-full-access")
DEFAULT_APPROVAL = os.environ.get("CODEX_APPROVAL", "never")
BLOCKED_TEST_RECIPIENTS = {"lachlan.mia.chan@gmail.com"}

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


def parse_single_email(value: str | None) -> str | None:
    if value is None:
        return None
    v = value.strip().lower()
    if not v:
        return None
    if not EMAIL_RE.match(v):
        raise ValueError(f"Invalid email address: {value}")
    return v


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8").strip()


def build_prompt(
    *,
    instruction: str,
    to_hint: list[str],
    cc_hint: list[str],
    bcc_hint: list[str],
    from_hint: str | None,
    prompt_tools_dir: Path,
) -> str:
    base_prompt = read_text(prompt_tools_dir / "email_send_prompt.md")
    common_tools = read_text(prompt_tools_dir / "common_tools.md")
    now_iso = datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds")

    payload = {
        "now_local_iso": now_iso,
        "instruction": instruction,
        "from_hint": from_hint,
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
    safety: str,
    approval: str,
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
        "-s",
        safety,
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


def validate_recipients_for_send(action: dict[str, Any]) -> None:
    blocked = sorted(
        (set(action["to"]) | set(action["cc"]) | set(action["bcc"])) & BLOCKED_TEST_RECIPIENTS
    )
    if blocked:
        raise RuntimeError(
            "Blocked recipient for test sends: "
            + ", ".join(blocked)
            + ". Use lachchen@qq.com for test runs."
        )


def build_html_document(body: str) -> str:
    body_text = body.strip()
    if not body_text:
        return "<html><body><p>(empty)</p></body></html>"

    if re.search(r"<(html|body|div|p|table|ul|ol|li|h[1-6]|br)\b", body_text, re.IGNORECASE):
        if re.search(r"<html\b", body_text, re.IGNORECASE):
            return body_text
        return f"<html><body>{body_text}</body></html>"

    paragraphs = [p for p in re.split(r"(?:\r?\n){2,}", body_text) if p.strip()]
    if not paragraphs:
        paragraphs = [body_text]

    rendered: list[str] = []
    for para in paragraphs:
        escaped = html.escape(para.strip()).replace("\n", "<br/>")
        rendered.append(f"<p>{escaped}</p>")

    return (
        "<html><head><meta charset=\"utf-8\"/></head><body style=\"font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;"
        "line-height:1.45;color:#111;\">"
        + "".join(rendered)
        + "</body></html>"
    )


def ensure_utf8_meta(html_text: str) -> str:
    if re.search(r"<meta[^>]+charset\\s*=", html_text, re.IGNORECASE):
        return html_text

    if re.search(r"<head\\b[^>]*>", html_text, re.IGNORECASE):
        return re.sub(
            r"(?i)(<head\\b[^>]*>)",
            r'\1<meta charset="utf-8"/>',
            html_text,
            count=1,
        )

    if re.search(r"<html\\b[^>]*>", html_text, re.IGNORECASE):
        return re.sub(
            r"(?i)(<html\\b[^>]*>)",
            r'\1<head><meta charset="utf-8"/></head>',
            html_text,
            count=1,
        )

    return f'<html><head><meta charset="utf-8"/></head><body>{html_text}</body></html>'


def convert_html_to_rtf(html_text: str) -> Path:
    with tempfile.NamedTemporaryFile(mode="w", suffix=".html", encoding="utf-8", delete=False) as html_file:
        html_file.write(html_text)
        html_path = Path(html_file.name)

    with tempfile.NamedTemporaryFile(suffix=".rtf", delete=False) as rtf_file:
        rtf_path = Path(rtf_file.name)

    proc = subprocess.run(
        [
            "textutil",
            "-convert",
            "rtf",
            "-format",
            "html",
            "-inputencoding",
            "UTF-8",
            str(html_path),
            "-output",
            str(rtf_path),
        ],
        text=True,
        capture_output=True,
    )
    html_path.unlink(missing_ok=True)
    if proc.returncode != 0:
        rtf_path.unlink(missing_ok=True)
        err = (proc.stderr or proc.stdout or "textutil conversion failed").strip()
        raise RuntimeError(err)

    return rtf_path


def send_via_mail(action: dict[str, Any], from_address: str | None = None) -> str:
    to_text = "\n".join(action["to"])
    cc_text = "\n".join(action["cc"])
    bcc_text = "\n".join(action["bcc"])
    from_text = from_address or ""

    with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", delete=False) as subj_file:
        subj_file.write(action["subject"])
        subject_path = subj_file.name
    with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", delete=False) as body_file:
        body_file.write(action["body"])
        plain_body_path = body_file.name
    body_path = plain_body_path

    body_mode = "text"
    rich_body_path: str | None = None
    try:
        html_doc = ensure_utf8_meta(build_html_document(action["body"]))
        rich_body_path = str(convert_html_to_rtf(html_doc))
        body_mode = "rtf"
        body_path = rich_body_path
    except Exception:
        body_mode = "text"

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

using terms from application "Mail"
on addRecipients(msg, rawText, recipientKind)
	set addrs to my parseRecipients(rawText)
	repeat with addr in addrs
		if recipientKind is "to" then
			tell msg
				make new to recipient at end of to recipients of msg with properties {address:(addr as text)}
			end tell
		else if recipientKind is "cc" then
			tell msg
				make new cc recipient at end of cc recipients of msg with properties {address:(addr as text)}
			end tell
		else if recipientKind is "bcc" then
			tell msg
				make new bcc recipient at end of bcc recipients of msg with properties {address:(addr as text)}
			end tell
		end if
	end repeat
end addRecipients
end using terms from

on findAccountByAddress(fromAddr)
	if fromAddr is "" then return missing value
	tell application "Mail"
		repeat with acc in every account
			try
				set addrList to email addresses of acc
				repeat with addr in addrList
					if (addr as text) is equal to fromAddr then return acc
				end repeat
			end try
		end repeat
	end tell
	return missing value
end findAccountByAddress

on run argv
	set toRaw to item 1 of argv
	set ccRaw to item 2 of argv
	set bccRaw to item 3 of argv
	set fromRaw to item 4 of argv
	set subjectPath to item 5 of argv
	set bodyPath to item 6 of argv
	set bodyMode to item 7 of argv
	set subjectText to read (POSIX file subjectPath) as «class utf8»
	if bodyMode is "rtf" then
		set bodyContent to read (POSIX file bodyPath) as «class RTF »
	else
		set bodyContent to read (POSIX file bodyPath) as «class utf8»
	end if

	tell application "Mail"
		set msg to make new outgoing message with properties {subject:subjectText, content:bodyContent, visible:false}
		if fromRaw is not "" then
			set sender of msg to fromRaw
			set matchedAccount to my findAccountByAddress(fromRaw)
			if matchedAccount is not missing value then
				try
					set account of msg to matchedAccount
				end try
			end if
		end if
		my addRecipients(msg, toRaw, "to")
		my addRecipients(msg, ccRaw, "cc")
		my addRecipients(msg, bccRaw, "bcc")
		tell msg to send
	end tell

	return "sent"
end run
'''

    proc = subprocess.run(
        ["osascript", "-", to_text, cc_text, bcc_text, from_text, subject_path, body_path, body_mode],
        input=applescript,
        text=True,
        capture_output=True,
    )

    Path(subject_path).unlink(missing_ok=True)
    Path(plain_body_path).unlink(missing_ok=True)
    Path(body_path).unlink(missing_ok=True)
    if rich_body_path:
        Path(rich_body_path).unlink(missing_ok=True)

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
    parser.add_argument("--from", dest="from_address", help="Sender email address to use")
    parser.add_argument("--subject", help="Force subject override")
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--reasoning", default=DEFAULT_REASONING)
    parser.add_argument("--safety", default=DEFAULT_SAFETY)
    parser.add_argument(
        "--approval",
        default=DEFAULT_APPROVAL,
        help="Approval policy compatibility knob; not passed to codex directly",
    )
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
    from_hint = parse_single_email(args.from_address)

    prompt_tools_dir = Path(args.prompt_tools_dir).expanduser().resolve()
    schema_path = prompt_tools_dir / "email_send_schema.json"
    if not schema_path.exists():
        raise RuntimeError(f"Schema file missing: {schema_path}")

    prompt = build_prompt(
        instruction=instruction,
        to_hint=to_hint,
        cc_hint=cc_hint,
        bcc_hint=bcc_hint,
        from_hint=from_hint,
        prompt_tools_dir=prompt_tools_dir,
    )

    action_raw = run_codex(
        codex_bin=args.codex_bin,
        model=args.model,
        reasoning=args.reasoning,
        safety=args.safety,
        approval=args.approval,
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
    if from_hint:
        print(f"from: {from_hint}")
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

    validate_recipients_for_send(action)
    result = send_via_mail(action, from_address=from_hint)
    print(f"Mail result: {result}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
