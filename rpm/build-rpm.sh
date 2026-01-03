#!/bin/bash
# Build script for creating RPM package of visual-page-editor with bundled NW.js

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RPM_DIR="$SCRIPT_DIR"
PROJECT_ROOT="$(cd "$RPM_DIR/.." && pwd)"

# Configuration
NAME="visual-page-editor"
VERSION="1.0.0"
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
    
    for tool in rpmbuild curl tar gzip; do
        if ! command -v $tool &> /dev/null; then
            missing_tools+=($tool)
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "${RED}Error: Missing required tools: ${missing_tools[*]}${NC}"
        echo "Please install them using your package manager:"
        echo "  Fedora/RHEL/CentOS: sudo dnf install rpm-build curl tar gzip"
        echo "  openSUSE: sudo zypper install rpm-build curl tar gzip"
        exit 1
    fi
    
    # Ensure rpmbuild directories exist
    mkdir -p ~/rpmbuild/{SOURCES,SPECS,BUILD,RPMS,SRPMS}
    
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

# Build RPM package
build_rpm() {
    echo -e "${YELLOW}Building RPM package...${NC}"
    
    cd "$PROJECT_ROOT"
    
    # Copy spec file to rpmbuild directory
    cp "$RPM_DIR/${NAME}.spec" ~/rpmbuild/SPECS/
    
    # Create source tarball
    echo "Creating source tarball..."
    tar -czf ~/rpmbuild/SOURCES/${NAME}-${VERSION}.tar.gz \
        --transform "s,^\.,${NAME}-${VERSION}," \
        --exclude='.git' \
        --exclude='node_modules' \
        --exclude='nwjs' \
        --exclude='*.deb' \
        --exclude='*.rpm' \
        --exclude='rpmbuild' \
        --exclude='.gitignore' \
        .
    
    # Build the RPM
    echo "Building RPM..."
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
    download_nwjs
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

