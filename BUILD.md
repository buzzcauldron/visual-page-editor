# Building Packages

## Current Status

✅ **All build files are ready and validated!**

- ✓ RPM spec file: `rpm/visual-page-editor.spec`
- ✓ RPM build script: `rpm/build-rpm.sh`
- ✓ DEB control file: `debian/control`
- ✓ DEB rules file: `debian/rules`
- ✓ DEB build script: `build-deb.sh`
- ✓ macOS build script: `build-macos.sh`
- ✓ Windows build script: `build-windows.ps1` / `build-windows.bat`

## Building on Linux

### For RPM (Fedora/RHEL/CentOS):

```bash
cd /path/to/nw-page-editor
cd rpm
./build-rpm.sh
```

The RPM will be in: `~/rpmbuild/RPMS/x86_64/nw-page-editor-*.rpm`

### For DEB (Debian/Ubuntu):

```bash
cd /path/to/nw-page-editor
./build-deb.sh
```

The DEB will be in: `../nw-page-editor_*.deb`

## Building from macOS (or any system) using Docker

Since you're on macOS, you can use Docker to build Linux packages:

### Option 1: Use the Docker build script

```bash
# Build both RPM and DEB
./build-docker.sh both

# Or build just one:
./build-docker.sh rpm
./build-docker.sh deb
```

### Option 2: Manual Docker build

**For RPM:**
```bash
docker run --rm -it \
  -v $(pwd):/workspace \
  -w /workspace \
  fedora:latest bash -c "
  dnf install -y rpm-build curl tar gzip git perl &&
  cd rpm && ./build-rpm.sh
"
```

**For DEB:**
```bash
docker run --rm -it \
  -v $(pwd):/workspace \
  -w /workspace \
  debian:latest bash -c "
  apt-get update &&
  apt-get install -y build-essential devscripts curl tar gzip git perl &&
  ./build-deb.sh
"
```

## Building on macOS

### Prerequisites

- **Intel Mac**: macOS 10.13 or later
- **Apple Silicon (M1/M2/M3)**: macOS 11.0 (Big Sur) or later
- curl (usually pre-installed)
- unzip (usually pre-installed)

### Build macOS .app Bundle

The build script automatically detects your Mac's architecture and downloads the appropriate NW.js build:

```bash
cd /path/to/visual-page-editor
./build-macos.sh
```

**Architecture Detection:**
- On **Apple Silicon** (M1/M2/M3) Macs: Downloads `nwjs-sdk-v*-osx-arm64.zip` for native performance
- On **Intel** Macs: Downloads `nwjs-sdk-v*-osx-x64.zip`

The .app bundle will be in: `build-macos/Visual Page Editor.app`

**Apple Silicon Notes:**
- The build script automatically detects ARM64 architecture
- Creates a native ARM64 .app bundle (no Rosetta 2 needed)
- For best performance, ensure you're building on an Apple Silicon Mac

### Custom NW.js Version

```bash
NWJS_VERSION=0.50.0 ./build-macos.sh
```

### Create DMG (Optional)

After building, you can create a DMG file:

```bash
cd build-macos
hdiutil create -volname "Visual Page Editor" -srcfolder "Visual Page Editor.app" -ov -format UDZO visual-page-editor-1.0.0-macos.dmg
```

## Building on Windows

### Prerequisites

- Windows 10 or later
- PowerShell 5.0 or later (included with Windows 10+)
- curl (or use PowerShell's Invoke-WebRequest)

### Build Windows Portable Package

**Using PowerShell (recommended):**
```powershell
cd C:\path\to\visual-page-editor
.\build-windows.ps1
```

**Using Command Prompt:**
```cmd
cd C:\path\to\visual-page-editor
build-windows.bat
```

The package will be in: `build-windows\visual-page-editor\`

### Custom NW.js Version

```powershell
.\build-windows.ps1 -NWJS_VERSION 0.50.0
```

### Create ZIP Archive (Optional)

After building, you can create a ZIP file:

```powershell
Compress-Archive -Path "build-windows\visual-page-editor" -DestinationPath "build-windows\visual-page-editor-1.0.0-windows-x64.zip" -Force
```

## What Gets Built

All packages will:
- ✅ Automatically download NW.js v0.44.4 (or specified version)
- ✅ Bundle NW.js with the application
- ✅ Create self-contained packages with no external dependencies
- ✅ Include all application files, examples, and documentation

**Linux packages (RPM/DEB):**
- Standard Linux package format
- Can be installed via package manager
- Includes system integration

**macOS package:**
- Native .app bundle
- Can be double-clicked to run
- Can be distributed as DMG

**Windows package:**
- Portable folder structure
- No installation required
- Can be distributed as ZIP

## Custom NW.js Version

To use a different NW.js version:

**Linux:**
```bash
NWJS_VERSION=0.50.0 ./rpm/build-rpm.sh
NWJS_VERSION=0.50.0 ./build-deb.sh
```

**macOS:**
```bash
NWJS_VERSION=0.50.0 ./build-macos.sh
```

**Windows:**
```powershell
.\build-windows.ps1 -NWJS_VERSION 0.50.0
```

## Next Steps

1. **Linux**: Use the build scripts directly (RPM/DEB)
2. **macOS**: Use `build-macos.sh` to create .app bundle
3. **Windows**: Use `build-windows.ps1` to create portable package
4. **Cross-platform Linux builds**: Use Docker (see above)
5. **For CI/CD**: Use the appropriate build script for your target platform

The packages are ready to build for all platforms!

