#!/bin/bash
# Build script for creating macOS .app bundle of visual-page-editor with bundled NW.js

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# Configuration
NAME="visual-page-editor"
VERSION="1.0.0"
NWJS_VERSION="${NWJS_VERSION:-0.44.4}"
APP_NAME="Visual Page Editor.app"
BUILD_DIR="$PROJECT_ROOT/build-macos"
APP_DIR="$BUILD_DIR/$APP_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    NWJS_ARCH="osx-arm64"
    NWJS_SUFFIX="osx-arm64"
else
    NWJS_ARCH="osx-x64"
    NWJS_SUFFIX="osx-x64"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for required tools
check_requirements() {
    echo -e "${YELLOW}Checking requirements...${NC}"
    
    local missing_tools=()
    
    for tool in curl unzip; do
        if ! command -v $tool &> /dev/null; then
            missing_tools+=($tool)
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "${RED}Error: Missing required tools: ${missing_tools[*]}${NC}"
        echo "Please install them using Homebrew:"
        echo "  brew install curl"
        exit 1
    fi
    
    echo -e "${GREEN}All requirements met!${NC}"
}

# Download NW.js if needed
download_nwjs() {
    echo -e "${YELLOW}Checking for NW.js v${NWJS_VERSION} (${NWJS_ARCH})...${NC}"
    
    local nwjs_archive="$PROJECT_ROOT/nwjs-sdk-v${NWJS_VERSION}-${NWJS_SUFFIX}.zip"
    local nwjs_url="https://dl.nwjs.io/v${NWJS_VERSION}/nwjs-sdk-v${NWJS_VERSION}-${NWJS_SUFFIX}.zip"
    local nwjs_extracted="$PROJECT_ROOT/nwjs-sdk-v${NWJS_VERSION}-${NWJS_SUFFIX}"
    
    if [ -d "$nwjs_extracted" ] && [ -d "$nwjs_extracted/nwjs.app" ]; then
        echo -e "${GREEN}NW.js already present at $nwjs_extracted${NC}"
        return 0
    fi
    
    echo "Downloading NW.js v${NWJS_VERSION} from $nwjs_url..."
    if curl -fLSs -o "$nwjs_archive" "$nwjs_url"; then
        echo "Extracting NW.js..."
        unzip -q "$nwjs_archive" -d "$PROJECT_ROOT"
        rm -f "$nwjs_archive"
        echo -e "${GREEN}NW.js downloaded and extracted successfully!${NC}"
    else
        echo -e "${RED}Warning: Could not download NW.js automatically.${NC}"
        echo "You can download it manually from: $nwjs_url"
        echo "Extract it to: $nwjs_extracted"
        return 1
    fi
}

# Create .app bundle structure
create_app_bundle() {
    echo -e "${YELLOW}Creating .app bundle structure...${NC}"
    
    # Clean previous build
    rm -rf "$BUILD_DIR"
    mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
    
    # Copy NW.js app
    local nwjs_extracted="$PROJECT_ROOT/nwjs-sdk-v${NWJS_VERSION}-${NWJS_SUFFIX}"
    if [ ! -d "$nwjs_extracted/nwjs.app" ]; then
        echo -e "${RED}Error: NW.js app not found at $nwjs_extracted/nwjs.app${NC}"
        exit 1
    fi
    
    # Copy NW.js framework and resources
    cp -R "$nwjs_extracted/nwjs.app/Contents/Frameworks" "$CONTENTS_DIR/" 2>/dev/null || true
    cp -R "$nwjs_extracted/nwjs.app/Contents/Resources"/* "$RESOURCES_DIR/" 2>/dev/null || true
    
    # Copy NW.js binary
    cp "$nwjs_extracted/nwjs.app/Contents/MacOS/nwjs" "$MACOS_DIR/nwjs"
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

# Launch NW.js with the application
exec "$NWJS_BIN" "$RESOURCES_DIR" "$@"
EOF
    chmod +x "$MACOS_DIR/launcher"
}

# Main build function
main() {
    echo -e "${GREEN}Building macOS .app bundle for Visual Page Editor${NC}"
    echo "Version: $VERSION"
    echo "NW.js Version: $NWJS_VERSION"
    echo "Architecture: $ARCH ($NWJS_ARCH)"
    if [ "$ARCH" = "arm64" ]; then
        echo -e "${GREEN}✓ Apple Silicon (M1/M2/M3) build${NC}"
    else
        echo "Intel (x86_64) build"
    fi
    echo ""
    
    check_requirements
    download_nwjs
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
