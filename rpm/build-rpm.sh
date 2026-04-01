#!/bin/bash
# Build script for creating RPM package of visual-page-editor with bundled NW.js

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RPM_DIR="$SCRIPT_DIR"
PROJECT_ROOT="$(cd "$RPM_DIR/.." && pwd)"

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

    for tool in rpmbuild node npm; do
        if ! command -v $tool &> /dev/null; then
            missing_tools+=($tool)
        fi
    done

    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "${RED}Error: Missing required tools: ${missing_tools[*]}${NC}"
        echo "Please install them using your package manager:"
        echo "  Fedora/RHEL/CentOS: sudo dnf install rpm-build nodejs npm"
        echo "  openSUSE: sudo zypper install rpm-build nodejs npm"
        exit 1
    fi

    # Ensure rpmbuild directories exist
    mkdir -p ~/rpmbuild/{SOURCES,SPECS,BUILD,RPMS,SRPMS}

    echo -e "${GREEN}All requirements met!${NC}"
}

# Ensure npm dependencies including NW.js are installed, then symlink nwjs/ for the source tarball
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

    # Symlink nwjs/ -> npm-installed SDK so it can be dereferenced into the source tarball
    local nwjs_link="$PROJECT_ROOT/nwjs"
    [ -L "$nwjs_link" ] && rm "$nwjs_link"
    ln -s "$NWJS_SDK_DIR" "$nwjs_link"
    echo -e "${GREEN}NW.js v${NWJS_VERSION} ready (symlinked at $nwjs_link)${NC}"
}

# Build RPM package
build_rpm() {
    echo -e "${YELLOW}Building RPM package...${NC}"

    cd "$PROJECT_ROOT"

    # Copy spec file to rpmbuild directory
    cp "$RPM_DIR/${NAME}.spec" ~/rpmbuild/SPECS/

    # Create source tarball (dereference nwjs/ symlink so NW.js is embedded;
    # the spec %prep download is then skipped because nwjs/ is already present)
    echo "Creating source tarball (includes NW.js runtime ~87MB)..."
    tar -czh \
        -f ~/rpmbuild/SOURCES/${NAME}-${VERSION}.tar.gz \
        --transform "s,^\.,${NAME}-${VERSION}," \
        --exclude='.git' \
        --exclude='node_modules' \
        --exclude='*.deb' \
        --exclude='*.rpm' \
        --exclude='rpmbuild' \
        --exclude='.gitignore' \
        .

    # Build the RPM
    echo "Building RPM package..."
    echo "  Note: This includes a large NW.js runtime (~87MB), so packaging may take a minute or two."
    echo "  The build will first create a source RPM, then the binary RPM."
    cd ~/rpmbuild/SPECS
    rpmbuild -ba ${NAME}.spec \
        --define "_topdir %(echo $HOME)/rpmbuild" \
        --define "version ${VERSION}" \
        --define "nwjs_version ${NWJS_VERSION}"

    echo -e "${GREEN}RPM package built successfully!${NC}"

    # Show results
    local rpm_file=$(find ~/rpmbuild/RPMS -name "${NAME}-${VERSION}*.rpm" | head -1)

    if [ -n "$rpm_file" ]; then
        echo -e "${GREEN}RPM: $rpm_file${NC}"
        ls -lh "$rpm_file"
        echo ""

        # If running in Docker (detected by /workspace mount), copy RPM artifacts to workspace
        if [ -d "/workspace" ] && [ -w "/workspace" ]; then
            echo "Copying RPM artifacts to /workspace for Docker volume access..."
            mkdir -p /workspace/rpmbuild/RPMS
            mkdir -p /workspace/rpmbuild/SRPMS
            if [ -d ~/rpmbuild/RPMS ]; then
                cp -r ~/rpmbuild/RPMS/* /workspace/rpmbuild/RPMS/ 2>/dev/null || true
            fi
            if [ -d ~/rpmbuild/SRPMS ]; then
                cp -r ~/rpmbuild/SRPMS/* /workspace/rpmbuild/SRPMS/ 2>/dev/null || true
            fi
            cp "$rpm_file" /workspace/ 2>/dev/null || true
            echo -e "${GREEN}RPM artifacts copied to /workspace/rpmbuild/ and /workspace/$(basename "$rpm_file")${NC}"
            echo ""
        fi

        echo "To install: sudo dnf install $rpm_file"
        echo "Or: sudo yum install $rpm_file"
    fi
}

# Main execution
main() {
    echo "========================================="
    echo "Building RPM package for $NAME"
    echo "Version: $VERSION"
    echo "NW.js Version: $NWJS_VERSION"
    echo "========================================="
    echo ""

    check_requirements
    ensure_npm_deps
    build_rpm

    echo ""
    echo "========================================="
    echo -e "${GREEN}Build completed successfully!${NC}"
    echo "========================================="
    echo ""
    echo "The RPM package includes NW.js and has no external dependencies."
    echo "Users can install it with: sudo dnf install <rpm-file>"
}

# Run main function
main
