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
NWJS_VERSION="${NWJS_VERSION:-0.109.1}"

install_docker() {
    if [ "$(uname -s)" = "Darwin" ]; then
        if ! command -v brew &> /dev/null; then
            echo -e "${YELLOW}Homebrew not found. Installing Homebrew...${NC}"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            if [ -f /opt/homebrew/bin/brew ]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [ -f /usr/local/bin/brew ]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        fi
        echo -e "${YELLOW}Installing Docker Desktop via Homebrew...${NC}"
        brew install --cask docker
        echo -e "${YELLOW}Opening Docker Desktop — waiting for daemon to start...${NC}"
        open -a Docker 2>/dev/null || true
    else
        echo -e "${RED}Error: Docker is not installed. Please install Docker for your platform.${NC}"
        exit 1
    fi
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Docker not found. Auto-installing...${NC}"
        install_docker
    fi

    if ! docker info &> /dev/null 2>&1; then
        echo -e "${YELLOW}Docker daemon is not running. Attempting to start Docker Desktop...${NC}"
        open -a Docker 2>/dev/null || true
        echo -n "Waiting for Docker daemon"
        local retries=30
        while [ $retries -gt 0 ]; do
            if docker info &> /dev/null 2>&1; then
                echo ""
                break
            fi
            echo -n "."
            sleep 2
            retries=$((retries - 1))
        done
        if ! docker info &> /dev/null 2>&1; then
            echo -e "\n${RED}Error: Docker daemon is still not running.${NC}"
            echo "Please start Docker Desktop manually and re-run this script."
            exit 1
        fi
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
    
    DOCKER_TTY=""
    [ -t 0 ] && DOCKER_TTY="-t"
    docker run --rm -i $DOCKER_TTY \
        -v "$PROJECT_ROOT:/workspace" \
        -w /workspace \
        -e NWJS_VERSION="$NWJS_VERSION" \
        fedora:latest bash -c "
        dnf install -y rpm-build curl tar gzip git perl &&
        cd rpm &&
        ./build-rpm.sh
    "
    
    echo -e "${GREEN}RPM build completed!${NC}"
    
    # Check for RPM files in the workspace
    local rpm_file=$(find "$PROJECT_ROOT" -maxdepth 1 -name "visual-page-editor-*.rpm" 2>/dev/null | head -1)
    if [ -z "$rpm_file" ]; then
        rpm_file=$(find "$PROJECT_ROOT/rpmbuild/RPMS" -name "visual-page-editor-*.rpm" 2>/dev/null | head -1)
    fi
    if [ -n "$rpm_file" ]; then
        echo -e "${GREEN}RPM package: $rpm_file${NC}"
        ls -lh "$rpm_file"
    else
        echo -e "${YELLOW}Note: RPM files should be in $PROJECT_ROOT/ or $PROJECT_ROOT/rpmbuild/RPMS/${NC}"
    fi
}

build_deb() {
    echo -e "${YELLOW}Building DEB package using Docker...${NC}"
    
    DOCKER_TTY=""
    [ -t 0 ] && DOCKER_TTY="-t"
    docker run --rm -i $DOCKER_TTY \
        -v "$PROJECT_ROOT:/workspace" \
        -w /workspace \
        -e NWJS_VERSION="$NWJS_VERSION" \
        debian:latest bash -c "
        apt-get update &&
        apt-get install -y build-essential devscripts curl tar gzip git perl \
          libx11-xcb1 libxcomposite1 libxdamage1 libxfixes3 libxi6 libxrender1 libxtst6 \
          libcups2 libdbus-1-3 libxss1 libxrandr2 libasound2 libatk1.0-0 \
          libpangocairo-1.0-0 libpango-1.0-0 libcairo2 libatspi2.0-0 libgtk-3-0 libgdk-pixbuf-2.0-0 \
          libnss3 libnspr4 &&
        ./build-deb.sh &&
        cp -v ../visual-page-editor_*.deb /workspace/ 2>/dev/null || true
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

