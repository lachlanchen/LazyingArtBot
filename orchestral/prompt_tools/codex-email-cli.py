#!/usr/bin/env python3
from pathlib import Path
import runpy
import sys

target = Path(__file__).resolve().parent / "runtime/codex-email-cli.py"
sys.argv[0] = str(target)
runpy.run_path(str(target), run_name="__main__")
