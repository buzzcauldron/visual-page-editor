#!/usr/bin/env bash
# Verifies default NW.js version literals match package.json dependencies.nw (e.g. 0.94.0-sdk -> 0.94.0).
# Read-only; does not modify files. Excludes build-macos.sh (different defaults for legacy .app packaging).
# Usage: from repo root, ./scripts/check-nwjs-version-alignment.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Prefer portable Node from bootstrap if PATH has no node (same as install-desktop flow)
if ! command -v node >/dev/null 2>&1; then
  for _tb in "$ROOT"/.tools/node-v*/bin; do
    if [ -x "$_tb/node" ]; then
      export PATH="$_tb:$PATH"
      break
    fi
  done
fi
if ! command -v node >/dev/null 2>&1; then
  echo "error: node required to read package.json (install Node or run ./scripts/install-desktop.sh)" >&2
  exit 1
fi

EXPECTED="$(
  node <<'NODE'
const p = require('./package.json');
const nw = p.dependencies && p.dependencies.nw;
if (!nw) {
  console.error('error: package.json missing dependencies.nw');
  process.exit(1);
}
const m = String(nw).match(/^(\d+\.\d+\.\d+)/);
if (!m) {
  console.error('error: dependencies.nw must start with semver X.Y.Z (e.g. 0.94.0-sdk)');
  process.exit(1);
}
process.stdout.write(m[1]);
NODE
)"

FAIL=0
err() {
  echo "check-nwjs-version-alignment: $*" >&2
  FAIL=1
}

if ! node -e "const p=require('./package.json');const n=p.dependencies.nw||'';process.exit(n.startsWith(process.argv[1])?0:1)" "$EXPECTED"; then
  err "package.json dependencies.nw should start with ${EXPECTED}-"
fi

must_contain() {
  local file="$1" needle="$2"
  if [ ! -f "$file" ]; then
    err "missing file: $file"
    return
  fi
  if ! grep -qF -- "$needle" "$file"; then
    err "$file — expected default NW.js $EXPECTED (look for: $needle)"
  fi
}

must_contain "bin/visual-page-editor" "NWJS_VERSION=\"\${NWJS_VERSION:-${EXPECTED}}\""
must_contain "Dockerfile.desktop" "ARG NWJS_VERSION=${EXPECTED}"
must_contain "docker-compose.yml" "\${NWJS_VERSION:-${EXPECTED}}"
must_contain "docker-run.sh" "NWJS_VERSION=\"\${NWJS_VERSION:-${EXPECTED}}\""
must_contain "scripts/test-platforms.sh" "NWJS_VERSION:-${EXPECTED}"
must_contain "build-deb.sh" "NWJS_VERSION:-${EXPECTED}"
must_contain "rpm/build-rpm.sh" "NWJS_VERSION:-${EXPECTED}"
must_contain "build-docker.sh" "NWJS_VERSION:-${EXPECTED}"
must_contain ".env.docker.example" "NWJS_VERSION=${EXPECTED}"

if [ "$FAIL" -ne 0 ]; then
  echo "" >&2
  echo "Fix: set dependencies.nw in package.json, run npm install, then update defaults in the files above." >&2
  echo "See TESTING.md (NW.js version alignment)." >&2
  exit 1
fi

echo "OK: NW.js default ${EXPECTED} matches package.json dependencies.nw across launcher, Docker, and packaging scripts."
