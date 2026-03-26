#!/usr/bin/env bash
# Simulate a fresh Linux VM/container: no system Node, minimal PATH, then bootstrap + NW.js via npm.
# Requires Docker. Uses the repo mounted read-only and copies into the container (excludes node_modules).
# Usage: ./scripts/test-install-docker.sh
# Override image: TEST_INSTALL_IMAGE=debian:bookworm-slim ./scripts/test-install-docker.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="${TEST_INSTALL_IMAGE:-ubuntu:22.04}"

if ! command -v docker >/dev/null 2>&1; then
  echo "error: docker not found; install Docker to run this viability test." >&2
  exit 1
fi

echo "Using image: $IMAGE"
# -i: attach stdin so the heredoc is passed to bash -s inside the container
docker run --rm -i \
  -e DEBIAN_FRONTEND=noninteractive \
  -v "$ROOT:/src:ro" \
  "$IMAGE" \
  bash -s << 'EOF'
set -euo pipefail
export PATH=/usr/bin:/bin
if command -v node >/dev/null 2>&1; then
  echo "error: unexpected: node already on PATH in fresh image" >&2
  exit 1
fi

apt-get update -qq
apt-get install -y -qq ca-certificates curl xz-utils >/dev/null

mkdir -p /work
cd /src
tar cf - \
  --exclude=node_modules \
  --exclude=.tools \
  --exclude=.git \
  . | (cd /work && tar xf -)

cd /work
chmod +x scripts/bootstrap-node.sh bin/visual-page-editor 2>/dev/null || true

echo "==> Running scripts/bootstrap-node.sh (downloads portable Node + npm install)..."
./scripts/bootstrap-node.sh

test -f node_modules/.bin/nw || { echo "FAIL: node_modules/.bin/nw missing"; exit 1; }
test -x node_modules/.bin/nw || { echo "FAIL: nw not executable"; exit 1; }

echo "==> Launcher with PATH=/usr/bin:/bin only (no global nw)..."
export PATH=/usr/bin:/bin
if command -v nw >/dev/null 2>&1; then
  echo "FAIL: nw should not be on PATH" >&2
  exit 1
fi
./bin/visual-page-editor --help | grep -q "NW.js" || { echo "FAIL: launcher help"; exit 1; }

echo ""
echo "DOCKER_INSTALL_TEST_OK — bootstrap + local NW.js work without system Node or nw on PATH."
EOF
