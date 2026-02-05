# Debug & error checks

## Quick checks

| Check | Command | Notes |
|-------|--------|------|
| **Code review** | `./scripts/code-review.sh` | JS (jshint if installed), HTML, shell, batch, PHP, XSLT/XSD (xmlstarlet), required files |
| **Lint JS** | `npm run lint` or `npx jshint js/*.js --exclude js/*.min.js` | Needs Node/npm |
| **Platform tests** | `./scripts/test-platforms.sh` | macOS launcher, Docker, arm64 features, version, installers |
| **Version sync** | `./scripts/sync-version.sh` | Syncs `VERSION` into package.json and all @version strings |

## Debug all branches thoroughly & relaunch

Run every check, then relaunch the desktop app:

1. **Code review**  
   `./scripts/code-review.sh`

2. **Lint & typecheck**  
   `npm run lint && npm run typecheck`

3. **Platform tests**  
   `./scripts/test-platforms.sh`  
   (Docker is optional; script exits 0 if only Docker build/run fails.)

4. **Relaunch (clean)**  
   - Clear NW.js path cache so the launcher re-detects the binary (use ARM64 on Apple Silicon):  
     `rm -f ~/.cache/visual-page-editor/nw-path`  
   - Run:  
     `./bin/visual-page-editor`  
   - If it crashes, see **Project crashed** below and **CRASH_FIX_MAC.md**.

**Launcher logic branches (bin/visual-page-editor):** Platform and **hardware architecture** (MAC_ARCH, WIN_ARCH, MACHINE_ARCH) detected first → cache hit only if path + version + **arch match this machine** (attune version to hardware) → NW.js lookup (version, arch) → ARM64 preference on Apple Silicon → validate app path → help / download prompt → launch with `--nwapp` on macOS .app → on non-zero exit (macOS arm64) clear cache and print troubleshooting. Cache file stores path, version, and binary arch so the next run reuses only when hardware matches.

## Current status (after last debug run)

- **Errors:** 0  
- **Warnings:** 1 — 65 `console.log` statements in app JS (consider removing for production)
- **Platform tests:** 15 passed, 1 failed (Docker build optional; script exits 0)
- **IDE linter:** No errors in js/html/css
- **eval():** Only in vendor (xmllint.js, *.min.js); excluded from review

## Optional tools (improve review coverage)

- **jshint** — `npm install` then `npm run lint`
- **xmlstarlet** — validate XSLT/XSD
- **php** — validate web-app PHP
- **pwsh / powershell** — validate .ps1 on Windows

## Why is startup slow?

1. **Launcher (bin/visual-page-editor)**  
   The script looks for the NW.js binary in several places. **Path cache:** the resolved path is saved in `~/.cache/visual-page-editor/nw-path` (with the NW.js version). On the next run, if that file exists and the path is still executable and the version matches, the launcher uses it immediately and skips all lookups. If the cache is missing or invalid, the launcher checks `~/.nwjs` first (then fixed `/Applications` paths, then `find`/`mdfind` only if needed).

2. **NW.js / Chromium**  
   The app runs inside NW.js (Chromium + Node). First launch loads the full runtime (V8, GPU process, etc.), so a few seconds of delay is normal. Subsequent launches in the same session are faster.

3. **Apple Silicon + x64 NW.js**  
   If you use the x64 build on an M-series Mac, Rosetta 2 adds overhead. Install the ARM64 build (`nwjs-sdk-v*-osx-arm64.zip`) for faster startup and better performance.

4. **App scripts**  
   The HTML loads many JS files (jQuery, interact, mousetrap, page-canvas, etc.) synchronously. That’s a one-time cost; the XSD is loaded asynchronously and does not block the UI.

## Project crashed

If the desktop app crashes on launch or soon after:

1. **Check the log**  
   `tail -50 /tmp/visual-page-editor.log` — look for `ERROR`, `Rosetta`, `x64`, `GPU process exited`, `app.nw`.

2. **Apple Silicon (M1/M2/M3): use ARM64 NW.js**  
   See **CRASH_FIX_MAC.md**. Do **not** use x64 NW.js (e.g. from `/Applications/nwjs.app` if it’s x64); use `nwjs-sdk-v*-osx-arm64.zip` and put `nwjs.app` in `/Applications/` or let the launcher download it to `~/.nwjs`.

3. **Clear the launcher path cache**  
   If the launcher is reusing the wrong NW.js (e.g. x64), clear the cache and run again:  
   `rm -f ~/.cache/visual-page-editor/nw-path`  
   Then run `./bin/visual-page-editor` again so it re-detects (and can pick ARM64 if present).

4. **NW.js version**  
   The launcher expects NW.js **0.94.0** by default. If you have an older SDK (e.g. 0.77.0) in `~/.nwjs`, either install 0.94.0 (see README / launcher download prompt) or set `NWJS_VERSION=0.77.0` when running the launcher.

## Common issues

- **ETIMEDOUT: connection timed out, read:** The app fetches the Page XML schema (XSD) from the local `xsd/` folder first; if missing it falls back to GitHub. A slow or blocked network can cause the request to time out. **Fix:** Run `./scripts/fetch-xsd.sh` to download the XSD into `xsd/pageformat/` so the app works offline and no network call is needed. XSD and version-check requests now use a 12s/10s timeout so the app fails fast with a clear message instead of hanging.
- **Program didn't start / "Cannot open app.nw":** NW.js inside an `.app` bundle (e.g. `/Applications/nwjs.app`) often ignores the first argument and looks for `app.nw` in its bundle. The launcher uses `--nwapp=/absolute/path` on macOS when the binary is inside an `.app` so your app path is used. Ensure the app path is absolute (the script resolves it). If it still fails, use the SDK from `~/.nwjs` (run the launcher once and choose to download NW.js) instead of a packaged `/Applications/nwjs.app`.
- **XSD not found:** Run `./scripts/fetch-xsd.sh` or `git submodule update --init`
- **Launcher not executable:** `chmod +x bin/visual-page-editor scripts/*.sh`
