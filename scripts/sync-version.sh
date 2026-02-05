#!/usr/bin/env bash
# Sync version from VERSION file into package.json and all @version / version literals.
# Run from repo root: ./scripts/sync-version.sh
# Used by bump-version.sh; can be run alone after editing VERSION by hand.

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

VERSION_FILE="$ROOT/VERSION"
if [ ! -f "$VERSION_FILE" ]; then
  echo "error: VERSION not found at $VERSION_FILE" >&2
  exit 1
fi
VER="$(tr -d '\n\r' < "$VERSION_FILE")"
if [ -z "$VER" ]; then
  echo "error: VERSION is empty" >&2
  exit 1
fi

# Semver-ish: allow only digits and dots (e.g. 1.1.0)
if ! echo "$VER" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "warning: VERSION '$VER' does not look like semver (e.g. 1.1.0)" >&2
fi

echo "Syncing version to: $VER"

# package.json
if [ -f package.json ]; then
  perl -i -pe 's/"version":\s*"[^"]*"/"version": "'"$VER"'"/' package.json
fi

# App-facing files: @version and version = '...'
for f in \
  html/index.html \
  css/page-editor.css \
  js/nw-app.js js/web-app.js js/page-editor.js js/editor-config.js js/svg-canvas.js js/page-canvas.js \
  bin/visual-page-editor bin/visual-page-editor.ps1 bin/visual-page-editor.bat \
  web-app/index.php web-app/common.inc.php web-app/start-server.sh \
  scripts/test-platforms.sh
do
  if [ ! -f "$ROOT/$f" ]; then continue; fi
  # @version $Version: 1.0.0$ (PHP-style)
  perl -i -pe "s/(@version\s+\\\$Version:\s*)[0-9]+\\.[0-9]+\\.[0-9]+(?=\s*\\\$)/\${1}$VER/g" "$ROOT/$f"
  # @version 1.0.0 (plain)
  perl -i -pe "s/(@version\s+)[0-9]+\\.[0-9]+\\.[0-9]+/\${1}$VER/g" "$ROOT/$f"
  # version = '1.0.0'; (js)
  perl -i -pe "s/version\s*=\s*'[0-9]+\\.[0-9]+\\.[0-9]+'/version = '$VER'/g" "$ROOT/$f"
done

echo "Done. All app-facing version strings set to $VER."
