#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── 1. Node.js check ────────────────────────────────────────────────────────
if ! command -v node >/dev/null 2>&1; then
  echo "❌ Node.js not found. Install v22+: https://nodejs.org"
  exit 1
fi
NODE_MAJOR=$(node -p 'process.versions.node.split(".")[0]')
if [ "$NODE_MAJOR" -lt 22 ]; then
  echo "❌ Node.js v${NODE_MAJOR} too old. Need >= 22. Install: https://nodejs.org"
  exit 1
fi
echo "✅ Node.js $(node --version)"

# ── 2. pnpm check ───────────────────────────────────────────────────────────
if ! command -v pnpm >/dev/null 2>&1; then
  echo "📦 pnpm not found — installing..."
  if command -v corepack >/dev/null 2>&1; then
    corepack enable pnpm 2>/dev/null || npm install -g pnpm@latest
  else
    npm install -g pnpm@latest
  fi
fi
echo "✅ pnpm $(pnpm --version)"

# ── 3. Dependencies ─────────────────────────────────────────────────────────
echo ""
echo "📦 Installing dependencies (this may take a minute)..."
pnpm install --frozen-lockfile

# ── 4. Build UI ─────────────────────────────────────────────────────────────
echo ""
echo "🔨 Building UI..."
pnpm ui:build
echo "✅ UI built"

# ── 5. Build gateway ────────────────────────────────────────────────────────
echo ""
echo "🔨 Building gateway..."
pnpm build
echo "✅ Gateway built"

# ── 6. Hand off to setup wizard ─────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Build complete! Entering interactive setup wizard..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

exec bash "$SCRIPT_DIR/scripts/setup.sh" "$@"
