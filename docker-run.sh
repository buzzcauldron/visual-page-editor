#!/usr/bin/env bash
# Recommended way to run Visual Page Editor in Docker with a GUI.
# Pins the image tag to ./VERSION for reproducible builds (override with VPE_IMAGE).

set -euo pipefail

show_help() {
  cat <<'EOF'
Usage: ./docker-run.sh [options] [--] [files...]

  Run the editor in Docker. Builds the image once as visual-page-editor:<VERSION>
  (from ./VERSION), then runs the container with X11 set up for macOS or Linux.

Options:
  --build, --rebuild   Force rebuild the image
  -h, --help           Show this help

Examples:
  ./docker-run.sh examples/lorem.xml
  ./docker-run.sh --build examples/lorem.xml

Environment:
  VPE_IMAGE         Override image name:tag (default: visual-page-editor:<VERSION>)
  NWJS_VERSION      Docker build-arg for NW.js SDK (default: 0.109.1)
  DOCKER_DEFAULT_PLATFORM  Default: linux/amd64 (same image on Apple Silicon and Intel)

See README-DOCKER.md for prerequisites (XQuartz on macOS, X11 on Linux).
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_FILE="$SCRIPT_DIR/VERSION"
NWJS_VERSION="${NWJS_VERSION:-0.109.1}"

VERSION="$(tr -d ' \t\n\r' <"$VERSION_FILE" 2>/dev/null || echo 0.0.0)"
DEFAULT_IMAGE="visual-page-editor:${VERSION}"
IMAGE_NAME="${VPE_IMAGE:-$DEFAULT_IMAGE}"
CONTAINER_NAME="${VPE_CONTAINER_NAME:-visual-page-editor-run}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

FORCE_BUILD=0
PASS_ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    --build|--rebuild)
      FORCE_BUILD=1
      shift
      ;;
    --)
      shift
      PASS_ARGS+=("$@")
      break
      ;;
    *)
      PASS_ARGS+=("$1")
      shift
      ;;
  esac
done

PLATFORM="${DOCKER_DEFAULT_PLATFORM:-linux/amd64}"

if [ "$FORCE_BUILD" = 1 ] || ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
  echo -e "${YELLOW}Building Docker image ${IMAGE_NAME} (${PLATFORM})...${NC}"
  docker build --platform "$PLATFORM" \
    --build-arg "NWJS_VERSION=$NWJS_VERSION" \
    --build-arg "APP_VERSION=$VERSION" \
    -f "$SCRIPT_DIR/Dockerfile.desktop" \
    -t "$IMAGE_NAME" \
    "$SCRIPT_DIR"
  # Convenience tag for tooling that still expects :latest
  docker tag "$IMAGE_NAME" "visual-page-editor:latest" 2>/dev/null || true
fi

# --- X11 / display ---
if [ "$(uname)" = "Darwin" ]; then
  if ! pgrep -x XQuartz >/dev/null 2>&1; then
    echo -e "${RED}Error: XQuartz is not running.${NC}" >&2
    echo "Install from https://www.xquartz.org/ then run:  open -a XQuartz" >&2
    echo "Enable: XQuartz → Settings → Security → Allow connections from network clients" >&2
    echo "Quit and reopen XQuartz after changing that setting." >&2
    exit 1
  fi
  if ! lsof -i :6000 >/dev/null 2>&1; then
    echo -e "${RED}Error: XQuartz is not listening on TCP (port 6000).${NC}" >&2
    echo "Enable network clients (see above), quit XQuartz fully, then start it again." >&2
    exit 1
  fi
  export DISPLAY="${DISPLAY:-host.docker.internal:0}"
  X11_VOLUME=()
  XAUTH_OPTS=()
  [ -f "${HOME}/.Xauthority" ] && XAUTH_OPTS=(-v "${HOME}/.Xauthority:/root/.Xauthority:ro")
else
  export DISPLAY="${DISPLAY:-:0}"
  xhost +local:docker 2>/dev/null || true
  X11_VOLUME=(-v /tmp/.X11-unix:/tmp/.X11-unix:rw)
  XAUTH_OPTS=(-v "${HOME}/.Xauthority:/root/.Xauthority:rw")
fi

TTY_OPTS=(-i)
[ -t 0 ] && [ -t 1 ] && TTY_OPTS=(-it)

echo -e "${GREEN}Starting Visual Page Editor (${IMAGE_NAME})...${NC}"
if [ "$(uname)" = "Darwin" ]; then
  echo -e "${YELLOW}DISPLAY=${DISPLAY}${NC}"
  echo -e "${YELLOW}(Ignore harmless Rosetta messages if shown.)${NC}"
fi

docker run --rm "${TTY_OPTS[@]}" \
  --name "$CONTAINER_NAME" \
  --platform "$PLATFORM" \
  -e DISPLAY="$DISPLAY" \
  "${X11_VOLUME[@]}" \
  "${XAUTH_OPTS[@]}" \
  -v "${SCRIPT_DIR}:/workspace:rw" \
  -v "${SCRIPT_DIR}/examples:/app/examples:ro" \
  "$IMAGE_NAME" "${PASS_ARGS[@]}"
