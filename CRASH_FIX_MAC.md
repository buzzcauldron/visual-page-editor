# Fix for Mac Crashes on Apple Silicon

## Problem
The application is crashing immediately on launch because the `.app` bundle contains **x64 NW.js** instead of **ARM64 NW.js**.

## Quick Fix

### Step 1: Install ARM64 NW.js
1. Go to https://nwjs.io/downloads/
2. Download: `nwjs-sdk-v*-osx-arm64.zip` (NOT `osx-x64`)
3. Extract the ZIP file
4. Move `nwjs.app` to `/Applications/`

### Step 2: Verify Installation
```bash
file /Applications/nwjs.app/Contents/MacOS/nwjs
```
Should show: `Mach-O 64-bit executable arm64`

### Step 3: Rebuild the .app Bundle
```bash
cd /path/to/visual-page-editor-master
./build-macos.sh
```

### Step 4: Use the New .app Bundle
The rebuilt `.app` bundle will be in: `build-macos/Visual Page Editor.app`

## Why This Happens
- Apple Silicon (M1/M2/M3) Macs need ARM64 binaries
- x64 binaries run via Rosetta 2 emulation, which causes crashes in NW.js
- The `.app` bundle was built with x64 NW.js instead of ARM64

## Alternative: Use the Shell Script Launcher
Instead of using the `.app` bundle, you can use the shell script launcher which will automatically detect and prevent crashes:

```bash
./bin/visual-page-editor
```

The shell script will:
- Detect x64 NW.js on Apple Silicon
- Show an error message and exit (preventing crash)
- Guide you to install the correct ARM64 version
