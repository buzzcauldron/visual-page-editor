#!/bin/bash
# Convenience script to run Visual Page Editor in Docker

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="visual-page-editor:latest"
CONTAINER_NAME="visual-page-editor"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if image exists, build if not
if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
    echo -e "${YELLOW}Building Docker image...${NC}"
    docker build -f Dockerfile.desktop -t "$IMAGE_NAME" .
fi

# Allow X11 connections
xhost +local:docker 2>/dev/null || true

# Run container
echo -e "${GREEN}Starting Visual Page Editor...${NC}"
docker run --rm -it \
    --name "$CONTAINER_NAME" \
    -e DISPLAY="${DISPLAY:-:0}" \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v "${HOME}/.Xauthority:/root/.Xauthority:rw" \
    -v "${SCRIPT_DIR}:/workspace:rw" \
    -v "${SCRIPT_DIR}/examples:/app/examples:ro" \
    --network host \
    "$IMAGE_NAME" "$@"

