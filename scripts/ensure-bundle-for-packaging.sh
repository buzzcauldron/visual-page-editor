#!/usr/bin/env bash
# Run esbuild so js/bundle.js matches src/ before DEB/RPM/macOS/Windows packaging copies js/.
# Safe to call after npm install; does not install NW.js SDK by itself.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
echo "Building js/bundle.js (esbuild) for packaging..."
npm run build
