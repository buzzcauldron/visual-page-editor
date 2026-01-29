# Features comparison: last working vs current

## Date note

There is **no commit dated exactly 2026-01-22** in this repo. Closest:

- **2026-01-24** – `6600e9e` – Add Windows launcher docs and scripts (README, `bin/visual-page-editor.bat`, `bin/visual-page-editor.ps1`)
- **2026-01-16** – several commits on `origin/baseline-type-main-margin` (baseline main/margin, drawer visibility, XSD/export fixes, etc.)
- **2026-01-08** – `014c509` – last commit currently on `main` (RPM/docs only)

So “last working from 1/22” is approximated by **1/24** (6600e9e) or the **1/16** feature branch.

---

## Last committed version on `main` (014c509, 2026-01-08)

| Item | State |
|------|--------|
| **package.json** | `"show": false` |
| **Dockerfile.desktop** | No `libatomic1`, `libgl1`, `libgl1-mesa-dri`; no XSD fetch step; entrypoint runs `/app/nwjs/nw /app` (no `--disable-gpu`) |
| **docker-run.sh** | Not in repo at this commit (Docker usage was via README/docker run only) |
| **App features** | Same editor as now: drawer, baselines, regions, coords, text edit, etc. |

---

## Version from 2026-01-24 (6600e9e) – closest to “1/22”

| Item | State |
|------|--------|
| **package.json** | Same as 014c509: `"show": false` |
| **Dockerfile.desktop** | Same as 014c509 (no extra libs, no XSD fetch, no `--disable-gpu`) |
| **New in 1/24** | Windows launcher: `bin/visual-page-editor.bat`, `bin/visual-page-editor.ps1`; README updates |
| **App features** | Unchanged from main (same editor behavior) |

---

## Remote branch `origin/baseline-type-main-margin` (2026-01-16)

Adds features not on `main`:

- Baseline type: **main** vs **margin**
- Drawer visible by default
- Baseline type persisted when creating new baselines
- CSS/color for margin baselines
- Fixes: XSD loading fallback, TextLine export, build-macos.sh ARM64, etc.

---

## Current working tree (uncommitted changes)

| File | Change vs last commit (014c509) |
|------|---------------------------------|
| **package.json** | `"show": true` (was `false`) – to try to get window to show under Docker/XQuartz |
| **Dockerfile.desktop** | Added `libatomic1`, `libgl1`, `libgl1-mesa-dri`; XSD fetch if missing; entrypoint uses `--disable-gpu --disable-gpu-compositing`; XSD fetch block |
| **docker-run.sh** | New file: macOS DISPLAY=host.docker.internal:0, XQuartz preflight, TTY handling, platform linux/amd64 |
| **README.md** | Docker/Desktop and XQuartz instructions, note that window appears inside XQuartz |

---

## Summary

- **“Last working” around 1/22** is best approximated by the **1/24** commit (6600e9e): same app and Docker setup as 1/8, plus Windows launcher; no `docker-run.sh`, and `package.json` had **`"show": false`**.
- **Editor features** on `main` have not been removed; drawer and baselines are still there. Extra editor features (main/margin baseline type, etc.) live on **origin/baseline-type-main-margin** and are not on `main`.
- Your **local** changes are all about Docker/macOS and window visibility (`show: true`, DISPLAY, preflight, GPU flags, XSD fetch). Reverting those would bring you back to the 1/24-style “last working” setup; the “Unable to open X display” issue would still depend on XQuartz running with TCP, not on those app features.

If you want to **restore committed behavior** for a specific file (e.g. `package.json` or `Dockerfile.desktop`), say which and we can revert only that.
