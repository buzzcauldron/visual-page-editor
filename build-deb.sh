#!/bin/bash
# Build script for creating DEB package of visual-page-editor with bundled NW.js

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# Configuration (VERSION from VERSION file or package.json)
NAME="visual-page-editor"
VERSION="$([ -f "$PROJECT_ROOT/VERSION" ] && cat "$PROJECT_ROOT/VERSION" | tr -d '\n')"
[ -z "$VERSION" ] && VERSION="$(node -p "require('$PROJECT_ROOT/package.json').version" 2>/dev/null)" || true
VERSION="${VERSION:-1.0.0}"
NWJS_VERSION="${NWJS_VERSION:-0.109.1}"
_HOST_ARCH="$(uname -m)"
case "$_HOST_ARCH" in aarch64|arm64) NWJS_LINUX_SUFFIX="linux-arm64" ;; *) NWJS_LINUX_SUFFIX="linux-x64" ;; esac
NWJS_SDK_DIR="$PROJECT_ROOT/node_modules/nw/nwjs-sdk-v${NWJS_VERSION}-${NWJS_LINUX_SUFFIX}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for required tools
check_requirements() {
    echo -e "${YELLOW}Checking requirements...${NC}"

    local missing_tools=()

    for tool in dpkg-buildpackage node npm; do
        if ! command -v $tool &> /dev/null; then
            missing_tools+=($tool)
        fi
    done

    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "${RED}Error: Missing required tools: ${missing_tools[*]}${NC}"
        echo "Please install them using your package manager:"
        echo "  Debian/Ubuntu: sudo apt-get install build-essential devscripts nodejs npm"
        exit 1
    fi

    echo -e "${GREEN}All requirements met!${NC}"
}

# Ensure npm dependencies including NW.js are installed, then symlink nwjs/ for debian/rules
ensure_npm_deps() {
    echo -e "${YELLOW}Checking npm dependencies and NW.js v${NWJS_VERSION}...${NC}"

    if [ ! -d "$NWJS_SDK_DIR" ] || [ ! -f "$NWJS_SDK_DIR/nw" ]; then
        echo "Running npm install to fetch NW.js v${NWJS_VERSION}..."
        cd "$PROJECT_ROOT"
        npm install
    fi

    if [ ! -d "$NWJS_SDK_DIR" ] || [ ! -f "$NWJS_SDK_DIR/nw" ]; then
        echo -e "${RED}Error: NW.js SDK not found at $NWJS_SDK_DIR after npm install${NC}"
        echo "Expected: $NWJS_SDK_DIR/nw"
        exit 1
    fi

    # Symlink nwjs/ -> npm-installed SDK so debian/rules can cp -r nwjs
    local nwjs_link="$PROJECT_ROOT/nwjs"
    [ -L "$nwjs_link" ] && rm "$nwjs_link"
    ln -s "$NWJS_SDK_DIR" "$nwjs_link"
    echo -e "${GREEN}NW.js v${NWJS_VERSION} ready (symlinked at $nwjs_link)${NC}"

    # Fresh bundle even if npm skipped prepare (lockfile unchanged)
    "$PROJECT_ROOT/scripts/ensure-bundle-for-packaging.sh"
}

# Build DEB package
build_deb() {
    echo -e "${YELLOW}Building DEB package...${NC}"

    cd "$PROJECT_ROOT"

    # Export NW.js version for debian/rules
    export NWJS_VERSION="$NWJS_VERSION"

    # Build the package
    dpkg-buildpackage -b -us -uc

    echo -e "${GREEN}DEB package built successfully!${NC}"

    # Show results
    local deb_file=$(find "$PROJECT_ROOT/.." -maxdepth 1 -name "${NAME}_${VERSION}*.deb" | head -1)

    if [ -n "$deb_file" ]; then
        echo -e "${GREEN}DEB: $deb_file${NC}"
        ls -lh "$deb_file"
        echo ""
        echo "To install: sudo dpkg -i $deb_file"
        echo "Or: sudo apt-get install -f && sudo dpkg -i $deb_file"
    fi
}

# Main execution
main() {
    echo "========================================="
    echo "Building DEB package for $NAME"
    echo "Version: $VERSION"
    echo "NW.js Version: $NWJS_VERSION"
    echo "========================================="
    echo ""

    check_requirements
    ensure_npm_deps
    build_deb

    echo ""
    echo "========================================="
    echo -e "${GREEN}Build completed successfully!${NC}"
    echo "========================================="
    echo ""
    echo "The DEB package includes NW.js and has no external dependencies."
    echo "Users can install it with: sudo dpkg -i <deb-file>"
}

# Run main function
main
