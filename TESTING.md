# Testing and install verification

How to validate **visual-page-editor** on macOS, Linux, and Docker, and how to simulate **clean install** environments without cluttering the main [README](README.md).

## Version (single source)

App version comes from **[`VERSION`](VERSION)** and [`package.json`](package.json). Build scripts read it automatically. To bump: edit `VERSION` (and `package.json` if needed); keep `rpm/visual-page-editor.spec` `%define version` in sync if you run `rpmbuild` directly.

---

## Quick platform check

From the repo root:

```bash
./scripts/test-platforms.sh
```

- **macOS**: `bin/visual-page-editor --help` and required paths.
- **Docker (optional)**: builds image if missing, runs `docker run … --help` (fails gracefully if Docker is unavailable).
- **Arm64-branch alignment**: baseline types, `build-macos.sh`, ARM64-related strings.
- **Version / installers**: `VERSION`, `package.json`, packaging scripts.

---

## Install verification (NW.js / bootstrap)

| Goal | Command | Notes |
|------|---------|--------|
| **No global `nw` on PATH** | `npm run verify:nw` | Temp dir + `npm ci`; launcher `--help` with minimal `PATH`. |
| **Linux VM–style (Docker)** | `./scripts/test-install-docker.sh` or `npm run test:install-docker` | Fresh Ubuntu container, copies repo (no `node_modules`), runs `bootstrap-node.sh`. Requires Docker. |

The [`nw`](https://www.npmjs.com/package/nw) package installs the NW.js SDK under `node_modules/` (gitignored). The launcher prefers `node_modules/.bin/nw`, then `~/.nwjs`, then PATH, or (with `AUTO_DOWNLOAD_NWJS`) a download. Default **`NWJS_VERSION`** is **0.94.0** (see `package.json` and `bin/visual-page-editor`).

---

## Simulated clean macOS install (numbered folders)

Use this to test **bootstrap + npm + NW.js** without Homebrew/nvm/conda Node leaking from your shell. The script copies the tree (excluding `.git`, `node_modules`, `.tools`, …) into **`.vpe-fresh-install-runs/<N>/`**, then runs `install-desktop` with **`PATH=/usr/bin:/bin` only**.

```bash
./scripts/test-fresh-install-mac.sh 1
```

Use another integer (`2`, `3`, …) for a new disposable copy. Output is gitignored.

```bash
rm -rf .vpe-fresh-install-runs
```

npm script: **`npm run test:install-mac`**

See also **[INSTALL-MAC.md](INSTALL-MAC.md)** for user-facing install and troubleshooting (conda, ENOENT, cache).

---

## Manual test matrix

| Platform | How to run | Notes |
|----------|------------|--------|
| **macOS** | `./bin/visual-page-editor [files...]` | Prefers `node_modules/.bin/nw`, then `~/.nwjs/nwjs-sdk-v*-osx-*`, then versioned SDK under `/Applications` (not generic `nwjs.app`). |
| **Linux (native)** | `./bin/visual-page-editor [files...]` | Same launcher; `nw` on PATH or auto-download when enabled. |
| **Docker (Linux)** | `./docker-run.sh [files...]` | [`Dockerfile.desktop`](Dockerfile.desktop); Xvfb when no `DISPLAY`. On macOS host: XQuartz + allow network clients for GUI. |

---

## Arm64-branch features (reference)

After merging **arm64-support**, the tree should include baseline types (main/margin), drawer behavior, `build-macos.sh` ARM64 handling, XSD fallback in `nw-app.js`, and related XML/TextLine updates. `scripts/test-platforms.sh` greps for key strings to confirm alignment.
