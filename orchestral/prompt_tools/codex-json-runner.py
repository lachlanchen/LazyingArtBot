#!/usr/bin/env python3
"""
Standardized Codex JSON runner.

Inputs:
- JSON file (--input-json)
- Output directory (--output-dir)

Outputs (per run):
- request.json
- input.json
- prompt.txt
- result.raw.json
- result.json
- meta.json
- codex.stdout.log
- codex.stderr.log
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
import os

SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_MODEL = "gpt-5.3-codex-spark"
DEFAULT_REASONING = "high"
DEFAULT_SAFETY = os.environ.get("CODEX_SAFETY", "danger-full-access")
DEFAULT_APPROVAL = os.environ.get("CODEX_APPROVAL", "never")
DEFAULT_PROMPT_FILE = SCRIPT_DIR / "json_task_prompt.md"


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, data: Any) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def build_prompt(prompt_template: str, payload: dict[str, Any]) -> str:
    input_json = json.dumps(payload, ensure_ascii=False, indent=2)
    return (
        f"{prompt_template}\n\n"
        "Task payload JSON:\n"
        f"{input_json}\n\n"
        "Return JSON only."
    )


def run_codex(
    *,
    codex_bin: str,
    model: str,
    reasoning: str,
    prompt: str,
    schema_path: Path | None,
    skip_git_check: bool,
    safety: str,
    approval: str,
    output_last_message: Path,
    stdout_log: Path,
    stderr_log: Path,
) -> int:
    cmd = [
        codex_bin,
        "exec",
        "--model",
        model,
        "-s",
        safety,
        "-c",
        f'model_reasoning_effort="{reasoning}"',
        "--output-last-message",
        str(output_last_message),
    ]
    if schema_path is not None:
        cmd.extend(["--output-schema", str(schema_path)])
    if skip_git_check:
        cmd.append("--skip-git-repo-check")
    cmd.append("-")

    with stdout_log.open("w", encoding="utf-8") as out, stderr_log.open(
        "w", encoding="utf-8"
    ) as err:
        proc = subprocess.run(cmd, input=prompt, text=True, stdout=out, stderr=err)
    return proc.returncode


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run Codex with JSON-in / JSON-out standard contract.")
    parser.add_argument("--input-json", required=True, help="Input JSON file path")
    parser.add_argument("--output-dir", required=True, help="Output directory for run artifacts")
    parser.add_argument(
        "--prompt-file",
        default=str(DEFAULT_PROMPT_FILE),
        help="Prompt template file path",
    )
    parser.add_argument(
        "--schema",
        help="Optional JSON schema path for strict output validation",
    )
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--reasoning", default=DEFAULT_REASONING)
    parser.add_argument(
        "--safety",
        default=DEFAULT_SAFETY,
        help="Codex safety mode passed to -s (default: danger-full-access)",
    )
    parser.add_argument(
        "--approval",
        default=DEFAULT_APPROVAL,
        help="Codex approval policy (compatibility shim; currently not passed explicitly)",
    )
    parser.add_argument("--codex-bin", default="codex")
    parser.add_argument("--label", default="json-task", help="Run label prefix")
    parser.add_argument("--skip-git-check", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    input_path = Path(args.input_json).expanduser().resolve()
    output_dir = Path(args.output_dir).expanduser().resolve()
    prompt_file = Path(args.prompt_file).expanduser().resolve()
    schema_path = Path(args.schema).expanduser().resolve() if args.schema else None

    if not input_path.exists():
        raise FileNotFoundError(f"Input JSON not found: {input_path}")
    if not prompt_file.exists():
        raise FileNotFoundError(f"Prompt file not found: {prompt_file}")
    if schema_path and not schema_path.exists():
        raise FileNotFoundError(f"Schema file not found: {schema_path}")

    input_obj = read_json(input_path)
    prompt_template = prompt_file.read_text(encoding="utf-8").strip()

    started_at = utc_now_iso()
    run_id = datetime.now().strftime("%Y%m%d-%H%M%S")
    run_dir = output_dir / f"{args.label}-{run_id}"
    run_dir.mkdir(parents=True, exist_ok=True)

    request_obj: dict[str, Any] = {
        "run_id": run_id,
        "started_at": started_at,
        "model": args.model,
        "reasoning": args.reasoning,
        "input_json_path": str(input_path),
        "prompt_file": str(prompt_file),
        "schema_path": str(schema_path) if schema_path else None,
        "label": args.label,
    }

    write_json(run_dir / "request.json", request_obj)
    write_json(run_dir / "input.json", input_obj)

    payload = {
        "now_local_iso": datetime.now().astimezone().isoformat(timespec="seconds"),
        "input_file": str(input_path),
        "data": input_obj,
    }
    prompt = build_prompt(prompt_template, payload)
    (run_dir / "prompt.txt").write_text(prompt, encoding="utf-8")

    raw_result_path = run_dir / "result.raw.json"
    stdout_log = run_dir / "codex.stdout.log"
    stderr_log = run_dir / "codex.stderr.log"

    rc = run_codex(
        codex_bin=args.codex_bin,
        model=args.model,
        reasoning=args.reasoning,
        prompt=prompt,
        schema_path=schema_path,
        skip_git_check=args.skip_git_check,
        safety=args.safety,
        approval=args.approval,
        output_last_message=raw_result_path,
        stdout_log=stdout_log,
        stderr_log=stderr_log,
    )

    meta: dict[str, Any] = {
        "run_id": run_id,
        "status": "failed" if rc != 0 else "ok",
        "return_code": rc,
        "started_at": started_at,
        "finished_at": utc_now_iso(),
        "run_dir": str(run_dir),
        "stdout_log": str(stdout_log),
        "stderr_log": str(stderr_log),
    }

    if rc != 0:
        write_json(run_dir / "meta.json", meta)
        print(f"status=failed run_dir={run_dir}")
        return rc

    raw_text = raw_result_path.read_text(encoding="utf-8").strip()
    if not raw_text:
        meta["status"] = "failed"
        meta["error"] = "empty_result"
        write_json(run_dir / "meta.json", meta)
        print(f"status=failed run_dir={run_dir}")
        return 1

    try:
        parsed = json.loads(raw_text)
    except json.JSONDecodeError as exc:
        meta["status"] = "failed"
        meta["error"] = f"invalid_json: {exc}"
        write_json(run_dir / "meta.json", meta)
        print(f"status=failed run_dir={run_dir}")
        return 1

    write_json(run_dir / "result.json", parsed)
    write_json(run_dir / "meta.json", meta)

    latest_path = output_dir / "latest-run.txt"
    latest_result = output_dir / "latest-result.json"
    latest_path.parent.mkdir(parents=True, exist_ok=True)
    latest_path.write_text(str(run_dir) + "\n", encoding="utf-8")
    shutil.copyfile(run_dir / "result.json", latest_result)

    print(f"status=ok run_dir={run_dir}")
    print(f"result_json={run_dir / 'result.json'}")
    print(f"latest_result={latest_result}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
