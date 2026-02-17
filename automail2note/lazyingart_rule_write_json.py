#!/usr/bin/env python3
"""Build one stable message JSON payload for lazingart_simple pipeline."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description="Write Lazyingart message JSON")
    parser.add_argument("--out", required=True)
    parser.add_argument("--message-id", required=True)
    parser.add_argument("--subject", required=True)
    parser.add_argument("--sender", required=True)
    parser.add_argument("--received-at", required=True)
    parser.add_argument("--mailbox", required=True)
    parser.add_argument("--account", required=True)
    parser.add_argument("--body-file", required=True)
    args = parser.parse_args()

    body_path = Path(args.body_file).expanduser()
    body_text = body_path.read_text(encoding="utf-8") if body_path.exists() else ""

    payload = {
        "messageID": args.message_id,
        "subject": args.subject,
        "sender": args.sender,
        "receivedAt": args.received_at,
        "mailbox": args.mailbox,
        "account": args.account,
        "body": body_text,
    }

    out_path = Path(args.out).expanduser()
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
