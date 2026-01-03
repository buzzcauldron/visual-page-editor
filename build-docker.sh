#!/bin/bash
# Docker-based build script for creating RPM and DEB packages
# This allows building Linux packages from macOS or any other system

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PACKAGE_TYPE="${1:-both}"  # rpm, deb, or both
NWJS_VERSION="${NWJS_VERSION:-0.44.4}"

check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: Docker is not installed or not in PATH${NC}"
        echo "Please install Docker Desktop for macOS from https://www.docker.com/products/docker-desktop"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        echo -e "${RED}Error: Docker daemon is not running${NC}"
        echo "Please start Docker Desktop"
        exit 1
    fi
    
    echo -e "${GREEN}Docker is available and running${NC}"
}

build_rpm() {
    if [ ! -d "$PROJECT_ROOT/rpm" ]; then
        echo -e "${RED}Error: RPM build directory not found: $PROJECT_ROOT/rpm${NC}"
        echo "RPM build infrastructure has not been created yet."
        echo "Please create the rpm directory and build-rpm.sh script, or use 'deb' package type instead."
        exit 1
    fi
    
    if [ ! -f "$PROJECT_ROOT/rpm/build-rpm.sh" ]; then
        echo -e "${RED}Error: RPM build script not found: $PROJECT_ROOT/rpm/build-rpm.sh${NC}"
        echo "Please create the build-rpm.sh script in the rpm directory."
        exit 1
    fi
    
    echo -e "${YELLOW}Building RPM package using Docker...${NC}"
    
    docker run --rm -it \
        -v "$PROJECT_ROOT:/workspace" \
        -w /workspace \
        -e NWJS_VERSION="$NWJS_VERSION" \
        fedora:latest bash -c "
        dnf install -y rpm-build curl tar gzip git perl &&
        cd rpm &&
        ./build-rpm.sh
    "
    
    echo -e "${GREEN}RPM build completed!${NC}"
    echo "Check ~/rpmbuild/RPMS/x86_64/ in the container or copy files from /tmp/rpmbuild/"
}

build_deb() {
    echo -e "${YELLOW}Building DEB package using Docker...${NC}"
    
    docker run --rm -it \
        -v "$PROJECT_ROOT:/workspace" \
        -w /workspace \
        -e NWJS_VERSION="$NWJS_VERSION" \
        debian:latest bash -c "
        apt-get update &&
        apt-get install -y build-essential devscripts curl tar gzip git perl &&
        ./build-deb.sh
    "
    
    echo -e "${GREEN}DEB build completed!${NC}"
}

build_both() {
    echo "Building both RPM and DEB packages..."
    build_rpm
    build_deb
}

main() {
    echo "========================================="
    echo "Docker-based Package Builder"
    echo "Package Type: $PACKAGE_TYPE"
    echo "NW.js Version: $NWJS_VERSION"
    echo "========================================="
    echo ""
    
    check_docker
    
    case "$PACKAGE_TYPE" in
        rpm)
            build_rpm
            ;;
        deb)
            build_deb
            ;;
        both)
            build_both
            ;;
        *)
            echo -e "${RED}Error: Invalid package type '$PACKAGE_TYPE'${NC}"
            echo "Usage: $0 [rpm|deb|both]"
            exit 1
            ;;
    esac
    
    echo ""
    echo "========================================="
    echo -e "${GREEN}Build completed!${NC}"
    echo "========================================="
}

main

