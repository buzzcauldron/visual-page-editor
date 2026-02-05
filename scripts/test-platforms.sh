#!/usr/bin/env bash
# Quick platform tests: macOS launcher, Docker (Linux), and arm64-branch feature presence.
# Run from repo root: ./scripts/test-platforms.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

PASS=0
FAIL=0

check() {
  if "$@"; then
    echo "  OK: $*"
    PASS=$((PASS + 1))
    return 0
  else
    echo "  FAIL: $*"
    FAIL=$((FAIL + 1))
    return 1
  fi
}

echo "=== 1. macOS (native launcher) ==="
if [ "$(uname -s)" = "Darwin" ]; then
  check ./bin/visual-page-editor --help
  check [ -f "$ROOT/js/nw-app.js" ]
  check [ -f "$ROOT/html/index.html" ]
else
  echo "  SKIP: not macOS"
fi

echo ""
echo "=== 2. Linux / Docker (container) ==="
if command -v docker >/dev/null 2>&1; then
  if ! docker image inspect visual-page-editor:latest &>/dev/null 2>&1; then
    echo "  Building Docker image..."
    if ! docker build --platform linux/amd64 -f Dockerfile.desktop -t visual-page-editor:latest . 2>/dev/null; then
      echo "  FAIL: docker build (see output above if not suppressed)"
      FAIL=$((FAIL + 1))
    fi
  fi
  if docker image inspect visual-page-editor:latest &>/dev/null 2>&1; then
    check docker run --rm --platform linux/amd64 -e DISPLAY=:99 visual-page-editor:latest --help
  else
    echo "  SKIP: no image (build failed or skipped)"
  fi
else
  echo "  SKIP: docker not found"
fi

echo ""
echo "=== 3. Arm64-branch feature presence ==="
check grep -q 'getBaselineType\|setBaselineType' js/page-canvas.js
check grep -q 'baseline-main\|baseline-margin' css/page-editor.css
check [ -f "$ROOT/build-macos.sh" ]
check grep -q 'arm64\|ARM64' build-macos.sh

echo ""
echo "=== 4. Version and installers ==="
check [ -f "$ROOT/VERSION" ]
check [ -f "$ROOT/package.json" ]
check [ -f "$ROOT/build-macos.sh" ]
check [ -f "$ROOT/build-windows.ps1" ]
check [ -f "$ROOT/build-deb.sh" ]
check [ -f "$ROOT/rpm/build-rpm.sh" ]
check [ -f "$ROOT/Dockerfile.desktop" ]
# Build scripts read VERSION (or package.json)
VER=$(cat "$ROOT/VERSION" 2>/dev/null | tr -d '\n')
check [ "$VER" = "1.1.0" ]

echo ""
echo "=== Result: $PASS passed, $FAIL failed ==="
# Docker (section 2) is optional: may fail without Docker or if build fails; other checks must pass
if [ "$FAIL" -eq 0 ]; then
  exit 0
fi
# If only Docker failed, still exit 0 so CI/local without Docker can pass
DOCKER_FAIL_ONLY=0
if [ "$FAIL" -eq 1 ] && command -v docker >/dev/null 2>&1; then
  if ! docker image inspect visual-page-editor:latest &>/dev/null 2>&1; then
    DOCKER_FAIL_ONLY=1
  fi
fi
[ "$DOCKER_FAIL_ONLY" -eq 1 ] && exit 0 || exit 1
