#!/usr/bin/env bash
set -euo pipefail

DRIVER_URL="${1:-https://storage.googleapis.com/chrome-for-testing-public/145.0.7632.77/mac-x64/chromedriver-mac-x64.zip}"
DEST_DIR="${2:-$HOME/.local/share/web-search-selenium}"
TMP_DIR="$(mktemp -d)"
ZIP_PATH="${TMP_DIR}/chromedriver.zip"

trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "${DEST_DIR}"

if command -v curl >/dev/null 2>&1; then
  curl -L --fail --show-error --silent --output "${ZIP_PATH}" "${DRIVER_URL}"
elif command -v wget >/dev/null 2>&1; then
  wget -O "${ZIP_PATH}" "${DRIVER_URL}"
else
  echo "curl or wget is required" >&2
  exit 1
fi

python - "$ZIP_PATH" "$DEST_DIR" <<'PY'
import sys
import zipfile
from pathlib import Path

zip_path = Path(sys.argv[1])
out_dir = Path(sys.argv[2])
with zipfile.ZipFile(zip_path, 'r') as zf:
    zf.extractall(out_dir)

found = sorted(out_dir.rglob('chromedriver'))
if not found:
    print('chromedriver not found in archive', file=sys.stderr)
    raise SystemExit(1)

for p in found:
    p.chmod(0o755)
print(found[0])
PY

echo "Chromedriver installed under: ${DEST_DIR}"
