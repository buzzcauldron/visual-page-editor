#!/bin/bash
# Build script for creating macOS .app bundle of visual-page-editor with bundled NW.js

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# Configuration (VERSION from VERSION file or package.json)
NAME="visual-page-editor"
VERSION="$([ -f "$SCRIPT_DIR/VERSION" ] && cat "$SCRIPT_DIR/VERSION" | tr -d '\n')"
[ -z "$VERSION" ] && VERSION="$(node -p "require('$SCRIPT_DIR/package.json').version" 2>/dev/null)" || true
VERSION="${VERSION:-1.0.0}"
# NW.js version: align with package.json dependencies.nw (same family as ./bin/visual-page-editor).
# Override with NWJS_VERSION=… if you need a different SDK for packaging experiments.
if [ -z "${NWJS_VERSION:-}" ]; then
    NWJS_VERSION="$(node -p "const p=require('$SCRIPT_DIR/package.json');const n=p.dependencies&&p.dependencies.nw;const m=String(n||'').match(/^(\d+\.\d+\.\d+)/);m?m[1]:''" 2>/dev/null || true)"
fi
if [ -z "$NWJS_VERSION" ]; then
    echo "Warning: could not read dependencies.nw from package.json; using legacy NW.js defaults." >&2
    if sysctl -n hw.optional.arm64 2>/dev/null | grep -q "1" || [ "$(uname -m)" = "arm64" ]; then
        NWJS_VERSION="0.77.0"
    else
        NWJS_VERSION="0.44.4"
    fi
fi
APP_NAME="Visual Page Editor.app"
BUILD_DIR="$PROJECT_ROOT/build-macos"
APP_DIR="$BUILD_DIR/$APP_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# Detect architecture automatically
# Check actual hardware architecture, not just process architecture
# This handles cases where Rosetta 2 is being used (uname -m returns x86_64 on Apple Silicon under Rosetta)
HARDWARE_ARCH=""
if [ "$(uname -s)" = "Darwin" ]; then
    # Check if hardware supports ARM64 (Apple Silicon)
    if sysctl -n hw.optional.arm64 2>/dev/null | grep -q "1"; then
        HARDWARE_ARCH="arm64"
    elif [ "$(uname -m)" = "arm64" ]; then
        HARDWARE_ARCH="arm64"
    elif [ "$(uname -m)" = "x86_64" ]; then
        # Check if this is Intel Mac or Apple Silicon running under Rosetta
        # On Apple Silicon, even under Rosetta, sysctl hw.optional.arm64 returns 1
        if sysctl -n hw.optional.arm64 2>/dev/null | grep -q "1"; then
            HARDWARE_ARCH="arm64"
        else
            HARDWARE_ARCH="x86_64"
        fi
    else
        HARDWARE_ARCH="$(uname -m)"
    fi
else
    HARDWARE_ARCH="$(uname -m)"
fi

# Use hardware architecture for NW.js selection (always prefer native ARM64 on Apple Silicon)
ARCH="$HARDWARE_ARCH"
if [ "$ARCH" = "arm64" ]; then
    NWJS_ARCH="osx-arm64"
    NWJS_SUFFIX="osx-arm64"
    ARCH_DESCRIPTION="Apple Silicon (M1/M2/M3)"
    if [ "$(uname -m)" = "x86_64" ]; then
        ARCH_DESCRIPTION="Apple Silicon (M1/M2/M3) - Running under Rosetta 2, but using ARM64 NW.js"
    fi
elif [ "$ARCH" = "x86_64" ]; then
    NWJS_ARCH="osx-x64"
    NWJS_SUFFIX="osx-x64"
    ARCH_DESCRIPTION="Intel (x86_64)"
else
    echo -e "${RED}Warning: Unknown architecture '$ARCH', defaulting to x64${NC}"
    NWJS_ARCH="osx-x64"
    NWJS_SUFFIX="osx-x64"
    ARCH_DESCRIPTION="Unknown (defaulting to x64)"
fi

# NW.js SDK path provided by 'npm install' — no separate download needed
NWJS_SDK_DIR="$PROJECT_ROOT/node_modules/nw/nwjs-sdk-v${NWJS_VERSION}-${NWJS_SUFFIX}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Ensure npm dependencies (including nw SDK) are installed
ensure_npm_deps() {
    if [ ! -d "$NWJS_SDK_DIR" ]; then
        echo -e "${YELLOW}NW.js SDK not found at $NWJS_SDK_DIR${NC}"
        echo "Running npm install to fetch it..."
        npm --prefix "$PROJECT_ROOT" install
    fi
    if [ ! -d "$NWJS_SDK_DIR/nwjs.app" ]; then
        echo -e "${RED}Error: NW.js SDK still missing after npm install: $NWJS_SDK_DIR${NC}"
        echo "Expected path: $NWJS_SDK_DIR/nwjs.app"
        echo "Check that package.json dependencies.nw matches NWJS_VERSION ($NWJS_VERSION)."
        exit 1
    fi
    echo -e "${GREEN}NW.js SDK ready at $NWJS_SDK_DIR${NC}"

    "$PROJECT_ROOT/scripts/ensure-bundle-for-packaging.sh"
}

# Check for required tools
check_requirements() {
    echo -e "${YELLOW}Checking requirements...${NC}"

    local missing_tools=()
    for tool in node npm; do
        if ! command -v $tool &> /dev/null; then
            missing_tools+=($tool)
        fi
    done

    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "${RED}Error: Missing required tools: ${missing_tools[*]}${NC}"
        echo "Install Node.js from https://nodejs.org/ or via Homebrew: brew install node"
        exit 1
    fi

    echo -e "${GREEN}All requirements met!${NC}"
}

# Create .app bundle structure
create_app_bundle() {
    echo -e "${YELLOW}Creating .app bundle structure...${NC}"

    # Clean previous build
    rm -rf "$BUILD_DIR"
    mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

    # Copy NW.js framework and resources from npm-installed SDK
    if [ ! -d "$NWJS_SDK_DIR/nwjs.app/Contents/Frameworks" ]; then
        echo -e "${RED}Error: NW.js SDK Frameworks missing: $NWJS_SDK_DIR/nwjs.app/Contents/Frameworks${NC}"
        echo "Re-run with: npm install"
        exit 1
    fi
    cp -R "$NWJS_SDK_DIR/nwjs.app/Contents/Frameworks" "$CONTENTS_DIR/"
    cp -R "$NWJS_SDK_DIR/nwjs.app/Contents/Resources/"* "$RESOURCES_DIR/"

    # Copy NW.js binary
    cp "$NWJS_SDK_DIR/nwjs.app/Contents/MacOS/nwjs" "$MACOS_DIR/nwjs"
    chmod +x "$MACOS_DIR/nwjs"
    
    # Copy application files
    echo -e "${YELLOW}Copying application files...${NC}"
    cp -R "$PROJECT_ROOT/html" "$RESOURCES_DIR/"
    cp -R "$PROJECT_ROOT/js" "$RESOURCES_DIR/"
    cp -R "$PROJECT_ROOT/css" "$RESOURCES_DIR/"
    cp -R "$PROJECT_ROOT/xslt" "$RESOURCES_DIR/"
    cp -R "$PROJECT_ROOT/xsd" "$RESOURCES_DIR/"
    cp -R "$PROJECT_ROOT/plugins" "$RESOURCES_DIR/" 2>/dev/null || true
    cp "$PROJECT_ROOT/package.json" "$RESOURCES_DIR/"
    
    # Create Info.plist
    create_info_plist
    
    # Create launcher script
    create_launcher_script
    
    echo -e "${GREEN}.app bundle created successfully!${NC}"
}

# Create Info.plist
create_info_plist() {
    # Set minimum macOS version based on architecture
    # Apple Silicon requires macOS 11.0 (Big Sur) or later
    if [ "$ARCH" = "arm64" ]; then
        MIN_OS_VERSION="11.0"
    else
        MIN_OS_VERSION="10.13"
    fi
    
    cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>launcher</string>
    <key>CFBundleIdentifier</key>
    <string>org.visual-page-editor</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Visual Page Editor</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>${MIN_OS_VERSION}</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
    <key>NSAppleEventsUsageDescription</key>
    <string>Visual Page Editor needs to access files to edit Page XML documents.</string>
</dict>
</plist>
EOF
}

# Create launcher script
create_launcher_script() {
    cat > "$MACOS_DIR/launcher" <<'EOF'
#!/bin/bash
# Launcher script for Visual Page Editor macOS app

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESOURCES_DIR="$APP_DIR/Resources"
NWJS_BIN="$APP_DIR/MacOS/nwjs"

# Detect macOS architecture
MAC_ARCH=$(uname -m)

# On Apple Silicon, check if we're using x64 NW.js (which causes crashes)
if [ "$MAC_ARCH" = "arm64" ]; then
  FILE_ARCH=$(file "$NWJS_BIN" 2>/dev/null | grep -i "arm64\|arm64e" || echo "")
  if [ -z "$FILE_ARCH" ]; then
    # Show macOS alert dialog
    osascript -e 'display dialog "ERROR: x64 NW.js detected in .app bundle on Apple Silicon!\n\nThis will cause immediate crashes. The .app bundle needs to be rebuilt with ARM64 NW.js.\n\nTo fix:\n1. Delete the current .app bundle\n2. Download ARM64 NW.js: nwjs-sdk-v*-osx-arm64.zip from https://nwjs.io/downloads/\n3. Extract and move nwjs.app to /Applications/\n4. Rebuild the .app bundle: ./build-macos.sh" buttons {"OK"} default button "OK" with icon stop' 2>/dev/null || true
    
    echo "" >&2
    echo "ERROR: x64 NW.js detected in .app bundle on Apple Silicon!" >&2
    echo "This will cause immediate crashes. The .app bundle needs to be rebuilt with ARM64 NW.js." >&2
    echo "" >&2
    echo "To fix:" >&2
    echo "1. Delete the current .app bundle" >&2
    echo "2. Download ARM64 NW.js: nwjs-sdk-v*-osx-arm64.zip from https://nwjs.io/downloads/" >&2
    echo "3. Extract and move nwjs.app to /Applications/" >&2
    echo "4. Rebuild the .app bundle: ./build-macos.sh" >&2
    echo "" >&2
    echo "Aborting launch to prevent crash..." >&2
    exit 1
  fi
fi

# Change to resources directory
cd "$RESOURCES_DIR"

# Launch NW.js with the application (--nwapp matches bin/visual-page-editor; avoids app.nw resolution issues on macOS)
exec "$NWJS_BIN" --nwapp "$RESOURCES_DIR" "$@"
EOF
    chmod +x "$MACOS_DIR/launcher"
}

# Main build function
main() {
    echo -e "${GREEN}Building macOS .app bundle for Visual Page Editor${NC}"
    echo "Version: $VERSION"
    echo "NW.js Version: $NWJS_VERSION"
    echo "Process Architecture: $(uname -m)"
    echo "Hardware Architecture: $ARCH ($ARCH_DESCRIPTION)"
    echo "NW.js Build: $NWJS_SUFFIX"
    if [ "$ARCH" = "arm64" ]; then
        if [ "$(uname -m)" = "x86_64" ]; then
            echo -e "${YELLOW}⚠ Running under Rosetta 2, but building with ARM64 NW.js for native performance${NC}"
        else
            echo -e "${GREEN}✓ Apple Silicon (M1/M2/M3) build - Native ARM64 performance${NC}"
        fi
    else
        echo "Intel (x86_64) build"
    fi
    echo ""
    
    check_requirements
    ensure_npm_deps
    create_app_bundle
    
    echo ""
    echo -e "${GREEN}Build complete!${NC}"
    echo "The .app bundle is located at: $APP_DIR"
    echo ""
    echo "To test the application:"
    echo "  open \"$APP_DIR\""
    echo ""
    echo "To create a DMG (optional):"
    echo "  hdiutil create -volname \"Visual Page Editor\" -srcfolder \"$APP_DIR\" -ov -format UDZO \"$BUILD_DIR/visual-page-editor-${VERSION}-macos-${ARCH}.dmg\""
    
    if [ "$ARCH" = "arm64" ]; then
        echo ""
        echo -e "${GREEN}Apple Silicon Notes:${NC}"
        echo "- This build is optimized for Apple Silicon (M1/M2/M3) Macs"
        echo "- The app will run natively without Rosetta 2"
        echo "- For best performance, ensure you're using ARM64 NW.js"
    fi
}

# Run main function
main
