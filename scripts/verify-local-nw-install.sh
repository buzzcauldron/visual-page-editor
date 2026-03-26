#!/usr/bin/env bash
# Verifies a fresh npm install provides NW.js locally so the app runs without a global `nw` on PATH.
# Uses a temporary copy (does not remove this repo's node_modules).
# Usage: from repo root, ./scripts/verify-local-nw-install.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/vpe-nw-verify.XXXXXX")"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

cp "$ROOT/package.json" "$ROOT/package-lock.json" "$WORKDIR/"
cp -a "$ROOT/bin" "$WORKDIR/"
mkdir -p "$WORKDIR/js" && : >"$WORKDIR/js/nw-app.js"
mkdir -p "$WORKDIR/html" && echo '<!DOCTYPE html><html><head><title>t</title></head><body></body></html>' >"$WORKDIR/html/index.html"

export PATH="/usr/bin:/bin"
unset AUTO_DOWNLOAD_NWJS
cd "$WORKDIR"

npm ci

test -f "$WORKDIR/node_modules/.bin/nw" || { echo "FAIL: node_modules/.bin/nw missing after npm ci"; exit 1; }
test -x "$WORKDIR/node_modules/.bin/nw" || { echo "FAIL: node_modules/.bin/nw not executable"; exit 1; }

PATH="/usr/bin:/bin" "$WORKDIR/bin/visual-page-editor" --help | grep -q "NW.js" || {
  echo "FAIL: launcher help did not run"
  exit 1
}

if command -v nw >/dev/null 2>&1; then
  echo "Note: a global 'nw' exists on PATH; still verified launcher works with PATH=/usr/bin:/bin only."
fi

echo "OK: npm ci placed NW.js under node_modules; ./bin/visual-page-editor --help works with minimal PATH (no global nw required)."
