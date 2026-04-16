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
# prepare runs npm run build (esbuild src/entry.js → js/bundle.js); copy real sources like a clone
cp -a "$ROOT/src" "$WORKDIR/"
cp -a "$ROOT/js" "$WORKDIR/"

# Minimal PATH: no global `nw`, but npm/node must exist (system or repo bootstrap under .tools/)
VERIFY_PATH="/usr/bin:/bin"
for _tb in "$ROOT"/.tools/node-v*/bin; do
  if [ -x "$_tb/node" ] && [ -x "$_tb/npm" ]; then
    VERIFY_PATH="$_tb:$VERIFY_PATH"
    break
  fi
done
export PATH="$VERIFY_PATH"
unset AUTO_DOWNLOAD_NWJS
cd "$WORKDIR"

npm ci

test -f "$WORKDIR/node_modules/.bin/nw" || { echo "FAIL: node_modules/.bin/nw missing after npm ci"; exit 1; }
test -x "$WORKDIR/node_modules/.bin/nw" || { echo "FAIL: node_modules/.bin/nw not executable"; exit 1; }

# Launcher still needs `node` for node_modules/.bin/nw shebang; keep same VERIFY_PATH (no global nw)
# Capture help first: piping to grep -q closes the pipe early and with pipefail the launcher gets SIGPIPE (141).
HELP_OUT="$(PATH="$VERIFY_PATH" "$WORKDIR/bin/visual-page-editor" --help 2>&1)" || {
  echo "FAIL: launcher --help exited non-zero"
  exit 1
}
echo "$HELP_OUT" | grep -q "NW.js" || {
  echo "FAIL: launcher help did not mention NW.js"
  exit 1
}

if command -v nw >/dev/null 2>&1; then
  echo "Note: a global 'nw' exists on PATH; still verified launcher uses node_modules when present."
fi

echo "OK: npm ci placed NW.js under node_modules; ./bin/visual-page-editor --help works (no global nw required)."
