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
NWJS_VERSION="${NWJS_VERSION:-0.44.4}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for required tools
check_requirements() {
    echo -e "${YELLOW}Checking requirements...${NC}"
    
    local missing_tools=()
    
    for tool in dpkg-buildpackage curl tar gzip; do
        if ! command -v $tool &> /dev/null; then
            missing_tools+=($tool)
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "${RED}Error: Missing required tools: ${missing_tools[*]}${NC}"
        echo "Please install them using your package manager:"
        echo "  Debian/Ubuntu: sudo apt-get install build-essential devscripts curl tar gzip"
        exit 1
    fi
    
    echo -e "${GREEN}All requirements met!${NC}"
}

# Download NW.js if needed
download_nwjs() {
    echo -e "${YELLOW}Checking for NW.js v${NWJS_VERSION}...${NC}"
    
    local nwjs_dir="$PROJECT_ROOT/nwjs"
    local nwjs_archive="$PROJECT_ROOT/nwjs-sdk-linux-x64.tar.gz"
    local nwjs_url="https://dl.nwjs.io/v${NWJS_VERSION}/nwjs-sdk-v${NWJS_VERSION}-linux-x64.tar.gz"
    
    if [ -d "$nwjs_dir" ] && [ -f "$nwjs_dir/nw" ]; then
        echo -e "${GREEN}NW.js already present at $nwjs_dir${NC}"
        return 0
    fi
    
    echo "Downloading NW.js v${NWJS_VERSION} from $nwjs_url..."
    if curl -fLSs -o "$nwjs_archive" "$nwjs_url"; then
        echo "Extracting NW.js..."
        tar -xzf "$nwjs_archive" -C "$PROJECT_ROOT"
        local extracted_dir=$(find "$PROJECT_ROOT" -maxdepth 1 -type d -name "nwjs-sdk-v${NWJS_VERSION}-linux-x64" | head -1)
        if [ -n "$extracted_dir" ]; then
            mv "$extracted_dir" "$nwjs_dir"
        fi
        rm -f "$nwjs_archive"
        echo -e "${GREEN}NW.js downloaded and extracted successfully!${NC}"
    else
        echo -e "${RED}Warning: Could not download NW.js automatically.${NC}"
        echo "You can download it manually from: $nwjs_url"
        echo "Extract it to: $nwjs_dir"
        return 1
    fi
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
    download_nwjs
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

