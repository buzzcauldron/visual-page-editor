# Troubleshooting Guide

## macOS Crashes

### Common Issue: x64 NW.js on Apple Silicon

If you're experiencing crashes on Apple Silicon (M1/M2/M3) Macs, the most common cause is using the x64 (Intel) version of NW.js instead of the ARM64 version.

**Symptoms:**
- Application crashes immediately on launch
- Segmentation fault errors
- Crash reports in `~/Library/Logs/DiagnosticReports/`

**Solution:**

1. **Check your current NW.js version:**
   ```bash
   file /Applications/nwjs.app/Contents/MacOS/nwjs
   ```
   - Should show `arm64` for Apple Silicon
   - If it shows `x86_64`, you need to install ARM64 version

2. **Download ARM64 NW.js:**
   - Go to https://nwjs.io/downloads/
   - Download: `nwjs-sdk-v*-osx-arm64.zip` (NOT osx-x64)
   - Extract the ZIP file
   - Move `nwjs.app` to `/Applications/`

3. **Verify installation:**
   ```bash
   file /Applications/nwjs.app/Contents/MacOS/nwjs
   ```
   Should now show: `Mach-O 64-bit executable arm64`

4. **Remove old x64 version:**
   ```bash
   rm -rf /Applications/nwjs.app  # if it's x64
   ```

### Window Not Showing

If the application launches but no window appears:

1. **Check package.json:**
   - Ensure `"show": true` (not `false`)
   - The window should appear automatically

2. **Check console logs:**
   ```bash
   tail -f /tmp/visual-page-editor.log
   ```

3. **Try launching with dev tools:**
   ```bash
   ./bin/visual-page-editor --help
   ```

### Permission Issues

If you get permission errors:

1. **Make launcher executable:**
   ```bash
   chmod +x bin/visual-page-editor
   ```

2. **Check NW.js permissions:**
   ```bash
   ls -l /Applications/nwjs.app/Contents/MacOS/nwjs
   ```

3. **On macOS, you may need to allow the app:**
   - System Settings → Privacy & Security
   - Allow the application if prompted

### Log Files

Check log files for detailed error messages:

```bash
# Application log
cat /tmp/visual-page-editor.log

# macOS crash reports
ls -la ~/Library/Logs/DiagnosticReports/ | grep nwjs
```

### Rebuild .app Bundle

If you built a .app bundle and it's crashing:

1. **Ensure you built with correct architecture:**
   ```bash
   ./build-macos.sh
   ```
   The script automatically detects your Mac's architecture.

2. **Check the built app:**
   ```bash
   file build-macos/Visual\ Page\ Editor.app/Contents/MacOS/nwjs
   ```

3. **Rebuild if needed:**
   ```bash
   rm -rf build-macos
   ./build-macos.sh
   ```

## General Issues

### Application Won't Start

1. **Verify NW.js is installed:**
   ```bash
   which nw
   # or
   ls -la /Applications/nwjs.app
   ```

2. **Check application files:**
   ```bash
   ls -la js/nw-app.js
   ```

3. **Try running directly:**
   ```bash
   /Applications/nwjs.app/Contents/MacOS/nwjs /path/to/visual-page-editor
   ```

### Getting Help

If issues persist:

1. Check the log file: `/tmp/visual-page-editor.log`
2. Check crash reports: `~/Library/Logs/DiagnosticReports/`
3. Run with verbose output:
   ```bash
   ./bin/visual-page-editor --help
   ```
