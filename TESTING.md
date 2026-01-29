# Platform testing

This document describes how to verify visual-page-editor on **macOS**, **Linux**, and **Docker**, in line with the merged **arm64-support** branch.

## Version (single source)

App version is **1.0.0** from **`VERSION`** (or `package.json`). Build scripts read it automatically. To bump: edit `VERSION` (and optionally `package.json`); keep `rpm/visual-page-editor.spec` `%define version` in sync if running `rpmbuild` directly.

## Quick test (all platforms)

From the repo root:

```bash
./scripts/test-platforms.sh
```

- **macOS**: Runs `bin/visual-page-editor --help` and checks app paths.
- **Docker (Linux container)**: Builds image if needed, runs `docker run ... --help`.
- **Arm64-branch alignment**: Confirms baseline types (main/margin), `build-macos.sh`, and ARM64 logic are present.
- **Version and installers**: Checks `VERSION`, `package.json`, and presence of all installer scripts (build-macos.sh, build-windows.ps1, build-deb.sh, rpm/build-rpm.sh, Dockerfile.desktop).

## Manual test matrix

| Platform | How to run | Notes |
|----------|------------|--------|
| **macOS** | `./bin/visual-page-editor [files...]` | Uses NW.js from `/Applications/nwjs.app` or `~/.nwjs`; ARM64 via `build-macos.sh` or `NWJS_VERSION=0.50.0`. |
| **Linux (native)** | `./bin/visual-page-editor [files...]` | Same launcher; needs `nw` in PATH or auto-download. |
| **Docker (Linux)** | `./docker-run.sh [files...]` | Uses `Dockerfile.desktop` (Xvfb when no DISPLAY). On macOS host: XQuartz + “Allow connections from network clients” for GUI. |

## Arm64-branch features (merged into main)

After merging `origin/arm64-support`, the codebase should include:

- **Baseline types**: Main vs Margin (HTML radios, `getBaselineType` / `setBaselineType`, CSS `.baseline-main` / `.baseline-margin`).
- **Drawer**: Toggle, persistence, visibility.
- **build-macos.sh**: ARM64 detection, NW.js 0.50.0 for ARM64.
- **XSD fallback**: Load `pagecontent_omnius.xsd`; fallback path in `nw-app.js`.
- **TextLine / XML**: Baseline type in XML export, TextLine handling.

The script `scripts/test-platforms.sh` checks for baseline types and `build-macos.sh`/ARM64; run it to confirm alignment with the arm branch.
