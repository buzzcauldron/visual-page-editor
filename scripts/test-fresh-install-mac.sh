#!/usr/bin/env bash
# Simulate a fresh clone on macOS: copy the repo (no node_modules / .tools / .git),
# run install-desktop, then smoke-test the launcher.
#
# Usage (from repository root):
#   ./scripts/test-fresh-install-mac.sh [N]
#
# N defaults to 1. Creates ./.vpe-fresh-install-runs/N/ as a disposable copy (gitignored).
#
# Environment:
#   VPE_FRESH_PARENT  Override parent directory (default: repo/.vpe-fresh-install-runs)
#   SKIP_INSTALL      If set to 1, only re-run checks in the last copy (for debugging)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
N="${1:-1}"
PARENT="${VPE_FRESH_PARENT:-$ROOT/.vpe-fresh-install-runs}"
DEST="$PARENT/$N"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "warning: this script is aimed at macOS; continuing anyway ($(uname -s))." >&2
fi

if [ "${SKIP_INSTALL:-0}" != "1" ]; then
  if ! command -v rsync >/dev/null 2>&1; then
    echo "error: rsync is required (standard on macOS)." >&2
    exit 1
  fi

  echo "==> Fresh copy -> $DEST"
  rm -rf "$DEST"
  mkdir -p "$PARENT"
  rsync -a \
    --exclude '.git' \
    --exclude 'node_modules' \
    --exclude '.tools' \
    --exclude '.vpe-fresh-install-runs' \
    --exclude 'dist' \
    --exclude 'build' \
    --exclude 'build-macos' \
    --exclude '.DS_Store' \
    "$ROOT/" "$DEST/"

  chmod +x "$DEST/scripts/bootstrap-node.sh" "$DEST/scripts/install-desktop.sh" "$DEST/bin/visual-page-editor" 2>/dev/null || true

  echo "==> install-desktop (bootstrap Node if needed + npm install)"
  # Minimal PATH so we do not pick up Node from the parent repo, nvm, or Homebrew — simulates a clean shell.
  (
    cd "$DEST"
    export PATH="/usr/bin:/bin"
    ./scripts/install-desktop.sh
  )
fi

echo "==> Smoke tests in $DEST"
(
  cd "$DEST"
  # Ensure portable Node is on PATH for npm's nw wrapper and for any follow-up npm commands
  if [ -d "$DEST/.tools" ]; then
    # shellcheck disable=SC2012
    TOOLBIN="$(ls -d "$DEST"/.tools/node-v*/bin 2>/dev/null | head -1)"
    if [ -n "$TOOLBIN" ] && [ -x "$TOOLBIN/node" ]; then
      export PATH="$TOOLBIN:$PATH"
    fi
  fi
  test -x "$DEST/node_modules/.bin/nw" || { echo "FAIL: node_modules/.bin/nw missing"; exit 1; }
  HELP_OUT="$(./bin/visual-page-editor --help 2>&1)" || { echo "FAIL: launcher --help exit"; exit 1; }
  echo "$HELP_OUT" | grep -q "NW.js" || { echo "FAIL: launcher --help missing NW.js"; exit 1; }
  NW_BIN="$(find "$DEST/node_modules/nw" -path '*/Contents/MacOS/nwjs' -type f 2>/dev/null | head -1)"
  if [ -n "$NW_BIN" ]; then
    echo "    $(file "$NW_BIN")"
  fi
)

echo ""
echo "OK: fresh install test passed in $DEST"
echo "    Remove when done: rm -rf $(dirname "$DEST")"
