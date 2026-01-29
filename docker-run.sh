#!/bin/bash
# Convenience script to run Visual Page Editor in Docker

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="visual-page-editor:latest"
CONTAINER_NAME="visual-page-editor"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# On macOS, XQuartz must be running and listening on TCP or the container cannot open a display.
if [ "$(uname)" = "Darwin" ]; then
    if ! pgrep -x XQuartz >/dev/null 2>&1; then
        echo -e "${RED}Error: XQuartz is not running.${NC}"
        echo "Start XQuartz (e.g. run:  open -a XQuartz)"
        echo "Then enable: XQuartz → Preferences → Security → Allow connections from network clients"
        echo "Quit and reopen XQuartz after changing that setting."
        exit 1
    fi
    if ! lsof -i :6000 >/dev/null 2>&1; then
        echo -e "${RED}Error: XQuartz is not listening on TCP (port 6000).${NC}"
        echo "Enable: XQuartz → Preferences → Security → Allow connections from network clients"
        echo "Then quit XQuartz completely and start it again (e.g.  open -a XQuartz)."
        exit 1
    fi
fi

# Check if image exists for our platform, build if not
# Use linux/amd64 so the same image is used on Apple Silicon and Intel Macs (avoids "image not found" when run specifies --platform)
PLATFORM="linux/amd64"
if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
    echo -e "${YELLOW}Building Docker image (${PLATFORM})...${NC}"
    docker build --platform "$PLATFORM" -f Dockerfile.desktop -t "$IMAGE_NAME" .
fi

# On macOS, Docker runs in a VM. XQuartz must be running with "Allow connections from network clients"
# and we must use the host's display via TCP. The host's DISPLAY (e.g. /tmp/.../org.xquartz:0) is a
# socket path that doesn't exist inside the container, so always use host.docker.internal:0.
if [ "$(uname)" = "Darwin" ]; then
    export DISPLAY="host.docker.internal:0"
    X11_VOLUME=()
    XAUTH_OPTS=()
    # Optional: pass through .Xauthority if present (XQuartz may use it)
    [ -f "${HOME}/.Xauthority" ] && XAUTH_OPTS=(-v "${HOME}/.Xauthority:/root/.Xauthority:ro")
else
    export DISPLAY="${DISPLAY:-:0}"
    xhost +local:docker 2>/dev/null || true
    X11_VOLUME=(-v /tmp/.X11-unix:/tmp/.X11-unix:rw)
    XAUTH_OPTS=(-v "${HOME}/.Xauthority:/root/.Xauthority:rw")
fi

# Extra run options (e.g. --network host on Linux only)
EXTRA_OPTS=()
[ "$(uname)" != "Darwin" ] && EXTRA_OPTS+=(--network host)

# TTY: use -it when we have a terminal, else -i so Docker doesn't fail (e.g. when run from IDE)
TTY_OPTS=(-i)
[ -t 0 ] && [ -t 1 ] && TTY_OPTS=(-it)

# Run container
echo -e "${GREEN}Starting Visual Page Editor...${NC}"
if [ "$(uname)" = "Darwin" ]; then
    echo -e "${YELLOW}Using DISPLAY=${DISPLAY}.${NC}"
    echo -e "${YELLOW}(Ignore any \"Failed to open file: /run/rosetta/rosetta\" messages—they are harmless.)${NC}"
fi
docker run --rm "${TTY_OPTS[@]}" \
    --name "$CONTAINER_NAME" \
    --platform "$PLATFORM" \
    -e DISPLAY="$DISPLAY" \
    "${X11_VOLUME[@]}" \
    "${XAUTH_OPTS[@]}" \
    -v "${SCRIPT_DIR}:/workspace:rw" \
    -v "${SCRIPT_DIR}/examples:/app/examples:ro" \
    "${EXTRA_OPTS[@]}" \
    "$IMAGE_NAME" "$@"

