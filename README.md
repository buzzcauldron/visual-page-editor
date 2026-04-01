# Visual Page Editor

A modern visual editor for Page XML files, based on [nw-page-editor](https://github.com/mauvilsa/nw-page-editor).

**Repository:** [https://github.com/buzzcauldron/visual-page-editor](https://github.com/buzzcauldron/visual-page-editor)

## Description

Visual Page Editor is an application for viewing and editing ground truth or predicted information for document processing and text recognition. Editing is done interactively on top of images of scanned documents.

## Features

- Visual editing of Page XML with live feedback
- Supports omni:us Pages Format, PRImA Page XML, ALTO v2/v3, TET, Poppler
- Desktop app (NW.js) and web-app variant
- Keyboard shortcuts (see [KEYBOARD-SHORTCUTS.md](KEYBOARD-SHORTCUTS.md))

---

## Quick start (desktop)

You do **not** need NW.js installed globally or on your `PATH`. The **`nw` npm package** downloads the NW.js SDK into `node_modules/` during install. Launchers prefer the npm-installed SDK (`node_modules/.bin/nw` on Unix, `node_modules/nw/nwjs-sdk-*/nw.exe` on Windows) and prepend portable Node from `.tools/` to `PATH` when `install-desktop` has bootstrapped it.

**Automatic install (Node optional):** one block installs dependencies, verifies NW.js, and optionally starts the app.

- **Linux / macOS / Git Bash:**
  ```bash
  git clone https://github.com/buzzcauldron/visual-page-editor.git && cd visual-page-editor && ./scripts/install-desktop.sh --start
  ```
  Install only (no launch): `./scripts/install-desktop.sh`  
  Same from repo root: `./install.sh` or `npm run install-desktop`

- **Windows (PowerShell):**
  ```powershell
  git clone https://github.com/buzzcauldron/visual-page-editor.git; cd visual-page-editor; .\scripts\install-desktop.ps1 -Start
  ```

`install-desktop` runs `./scripts/bootstrap-node.sh` when Node 18+ is missing (portable Node into `.tools/`), then **`npm install`** (pulls **NW.js**), then checks that **`node_modules/.bin/nw`** exists.

**Manual path (if you already have Node + npm):**
```bash
git clone https://github.com/buzzcauldron/visual-page-editor.git && cd visual-page-editor && npm install && npm start
```

**Linux / macOS (install then open a sample file):**
```bash
cd visual-page-editor
./scripts/install-desktop.sh
./bin/visual-page-editor examples/lorem.xml
```

**macOS only:** use a **native Apple Silicon** terminal on M-series Macs when possible; portable Node and NW.js target **arm64**. Troubleshooting and Rosetta notes: **[INSTALL-MAC.md](INSTALL-MAC.md)**.

**Windows (PowerShell), install then sample:**
```powershell
cd visual-page-editor
.\scripts\install-desktop.ps1
.\bin\visual-page-editor.ps1 examples\lorem.xml
```

**GitHub ZIP (no Git):** Extract the archive, open a terminal in that folder, then run **`./scripts/install-desktop.sh --start`** (Unix) or **`.\scripts\install-desktop.ps1 -Start`** (Windows) — same automatic sequence as above.

**Details:** `install-desktop` uses **`./scripts/bootstrap-node.sh`** when Node 18+ is missing (portable Node under `.tools/`; requires `curl`/`wget` + `tar` on Unix). You can still run bootstrap alone if you prefer.

You do **not** need to install NW.js separately or add it to your system `PATH`; the `nw` package installs under `node_modules/`.

**Docker:** The desktop image runs NW.js from a fixed path inside the container (`/app/nwjs/nw`); nothing is added to `PATH` on the host. See [README-DOCKER.md](README-DOCKER.md).

The [nw](https://www.npmjs.com/package/nw) package is a **regular dependency**; its postinstall downloads the **NW.js SDK** for your OS/arch into `node_modules/` (ignored by git). The launcher prefers `node_modules/.bin/nw` when present, then falls back to `~/.nwjs` and PATH. **Install checks and simulated clean environments:** [TESTING.md](TESTING.md). For packaged builds (e.g. from [BUILD.md](BUILD.md)), use the installed launcher.

On **Linux ARM64**, `uname -m` detects the architecture so `~/.nwjs` lookups use **linux-arm64**; `npm install` does the same via the `nw` package. If only an x64 binary is found, the launcher warns and you can run `npm install` to fetch the matching SDK.

**Open multiple files:**
```bash
./bin/visual-page-editor examples/lorem.xml examples/lorem2.xml
```

---

## Container (Docker)

**Recommended:** from the repo root, use **`./docker-run.sh`** — it builds a version-tagged image (`visual-page-editor:<VERSION>` from [`VERSION`](VERSION)), configures **XQuartz** on macOS or **X11** on Linux, and mounts your project so saves stay on the host. First run builds the image; after upgrades use `./docker-run.sh --build …`.

```bash
./docker-run.sh examples/lorem.xml
```

No Node or NW.js is required on the host—only Docker (and XQuartz on macOS for a visible window). Full prerequisites, Compose, and manual `docker` commands: **[README-DOCKER.md](README-DOCKER.md)**.

---

## Usage

| Shortcut | Action |
|----------|--------|
| `Mod + O` / `Mod + S` | Open / Save |
| `Page Up/Down` or arrows | Navigate pages (arrows pan when zoomed) |
| `Mod + 0` / `Mod + 2` | Fit page / Zoom to selection |
| `Tab` / `Shift + Tab` | Next / previous element |
| Full list | [KEYBOARD-SHORTCUTS.md](KEYBOARD-SHORTCUTS.md) |

## Supported formats

- omni:us Pages Format, PRImA Page XML (2013-07-15, 2010-03-19), ALTO v2/v3, TET, Poppler

## Web app

The `web-app` directory provides a web-based variant for remote use. See that directory for setup.

## Development

```bash
git clone https://github.com/buzzcauldron/visual-page-editor.git
cd visual-page-editor
./scripts/install-desktop.sh   # or: npm install
./bin/visual-page-editor
# or: npm start
```

Verification scripts (`verify:nw`, Docker bootstrap test, clean macOS copy): [TESTING.md](TESTING.md). The launcher uses `NWJS_VERSION` (default **0.109.1**, aligned with `nw@0.109.1-sdk` in `package.json`).

**Testing:**
- `npm run test:unit` — vitest unit tests (Point2f, PanZoom, etc.)
- `npm run test:launcher` — bats launcher tests (20 tests across platforms)
- `npm run review` / `./scripts/code-review.sh` — code review; see [CODE_REVIEW.md](CODE_REVIEW.md)

**Build:** `npm run build` bundles `src/entry.js` → `js/bundle.js` via esbuild (runs automatically on `npm install` via the `prepare` script). Use `npm run build:watch` during development.

## License and links

- **License:** MIT — [LICENSE.md](LICENSE.md)
- **This project:** [github.com/buzzcauldron/visual-page-editor](https://github.com/buzzcauldron/visual-page-editor)
- **Original:** [nw-page-editor](https://github.com/mauvilsa/nw-page-editor) by Mauricio Villegas
- **Page format:** [omni-us/pageformat](https://github.com/omni-us/pageformat)
