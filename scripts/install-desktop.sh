#!/usr/bin/env bash
# One-shot desktop setup: Node (if needed) + npm install + verify NW.js SDK from the nw package.
# Usage: ./scripts/install-desktop.sh [--start] [extra args passed to npm install]
#   --start   launch the app after a successful install (same as bootstrap-node.sh --start)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

START=0
forward=()
for a in "$@"; do
  if [ "$a" = "--start" ]; then START=1
  else forward+=("$a"); fi
done

echo "==> Installing dependencies and NW.js (npm package nw)..."
# With set -u, "${arr[@]}" errors if arr is empty on some Bash builds (e.g. conda); branch instead.
if [ "${#forward[@]}" -eq 0 ]; then
  ./scripts/bootstrap-node.sh
else
  ./scripts/bootstrap-node.sh "${forward[@]}"
fi

# bootstrap-node.sh runs in a subshell; PATH changes (e.g. portable Node under .tools/) are not inherited.
# Prepend so `npm start` and --start work in this same script.
prepend_portable_node_path() {
  local _tb
  for _tb in "$ROOT"/.tools/node-v*/bin; do
    if [ -x "$_tb/node" ] && [ -x "$_tb/npm" ]; then
      export PATH="$_tb:$PATH"
      return 0
    fi
  done
  return 0
}
prepend_portable_node_path

verify_nwjs() {
  if [ ! -e "$ROOT/node_modules/.bin/nw" ]; then
    echo "error: node_modules/.bin/nw missing — npm package nw did not install correctly." >&2
    echo "  Try: rm -rf node_modules && ./scripts/install-desktop.sh" >&2
    exit 1
  fi
  # postinstall should make the wrapper executable on Unix
  if [ ! -x "$ROOT/node_modules/.bin/nw" ] && [ -f "$ROOT/node_modules/.bin/nw" ]; then
    chmod +x "$ROOT/node_modules/.bin/nw" 2>/dev/null || true
  fi
  # macOS: the npm postinstall must extract nwjs.app; missing binary causes spawn ENOENT from cli.js
  if [ "$(uname -s)" = "Darwin" ]; then
    NW_MACHO="$(find "$ROOT/node_modules/nw" -path '*/nwjs.app/Contents/MacOS/nwjs' -type f 2>/dev/null | head -1)"
    if [ -z "$NW_MACHO" ] || [ ! -f "$NW_MACHO" ]; then
      echo "error: NW.js app bundle incomplete under node_modules/nw (expected .../nwjs.app/Contents/MacOS/nwjs)." >&2
      echo "  Fix: rm -rf node_modules/nw && npm install" >&2
      echo "  or:  rm -rf node_modules && ./scripts/install-desktop.sh" >&2
      exit 1
    fi
    echo "==> NW.js SDK on disk: $NW_MACHO"
  fi
  echo "==> NW.js OK: local SDK via npm (node_modules/.bin/nw)."
}

verify_nwjs

if [ "$START" = 1 ]; then
  echo "==> Starting app..."
  exec npm start
fi

echo ""
echo "Next: npm start   or   ./bin/visual-page-editor [page.xml ...]"
echo "(If portable Node was installed under .tools/, use this same terminal or run ./scripts/install-desktop.sh again before npm.)"
if [ "$(uname -s)" = "Darwin" ]; then
  echo "macOS tips: INSTALL-MAC.md — simulated clean install: TESTING.md"
fi
