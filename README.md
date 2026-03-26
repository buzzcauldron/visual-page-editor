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

You do **not** need NW.js installed globally or on your `PATH`. After `npm install`, the app uses the local `nw` package (`node_modules/.bin/nw`). The launcher prefers that binary automatically.

**One command after clone (install deps + NW.js, then open the app):**
```bash
git clone https://github.com/buzzcauldron/visual-page-editor.git && cd visual-page-editor && npm install && npm start
```

**If `npm` is not installed yet** (no Node on the machine), use the bootstrap script instead of the line above, e.g. `git clone … && cd visual-page-editor && ./scripts/bootstrap-node.sh --start` (Linux/macOS) or `… && .\scripts\bootstrap-node.ps1 -Start` (Windows PowerShell).

**Linux / macOS (install then launch with a sample file):**
```bash
git clone https://github.com/buzzcauldron/visual-page-editor.git
cd visual-page-editor
npm install
./bin/visual-page-editor examples/lorem.xml
```

**Windows (PowerShell):**
```powershell
git clone https://github.com/buzzcauldron/visual-page-editor.git
cd visual-page-editor
npm install
.\bin\visual-page-editor.ps1 examples\lorem.xml
```

**GitHub ZIP (no Git):** Download the repository as a ZIP, extract it, open a terminal in that folder, then install and run as below.

**Without Node.js installed:** You can still set everything up automatically (downloads an official **portable Node.js** into `.tools/`, then runs `npm install`; nothing is added to your system `PATH` permanently):

- **Linux / macOS:** `./scripts/bootstrap-node.sh` then `npm start` (or `./scripts/bootstrap-node.sh --start` to do both). Requires `curl` or `wget`, and `tar` (usually present).
- **Windows (PowerShell):** `.\scripts\bootstrap-node.ps1` then `npm start` (or `.\scripts\bootstrap-node.ps1 -Start`).

If you **already have Node.js 18+** and `npm`, use `npm install` and `npm start` as usual—the bootstrap scripts detect that and skip the download.

You do **not** need to install NW.js separately or add it to your system `PATH`; the `nw` package installs under `node_modules/`.

**Docker:** The desktop image runs NW.js from a fixed path inside the container (`/app/nwjs/nw`); nothing is added to `PATH` on the host. See [README-DOCKER.md](README-DOCKER.md).

The [nw](https://www.npmjs.com/package/nw) package is a **regular dependency**; its postinstall downloads the **NW.js SDK** for your OS/arch into `node_modules/` (ignored by git). The launcher prefers `node_modules/.bin/nw` when present, then falls back to `~/.nwjs`, PATH, or (when `AUTO_DOWNLOAD_NWJS` is set) a download. To confirm a clean machine needs no global `nw`, run `npm run verify:nw`. To simulate a **fresh Linux VM** (no system Node, minimal `PATH`) and verify bootstrap + NW.js end-to-end, install [Docker](https://docs.docker.com/get-docker/) and run `./scripts/test-install-docker.sh` (or `npm run test:install-docker`). For packaged builds (e.g. from [BUILD.md](BUILD.md)), use the installed launcher instead.

On **Linux ARM64**, `uname -m` sets the architecture so auto-download and `~/.nwjs` lookups use **linux-arm64**; `npm install` does the same via the `nw` package. If only an x64 binary is found, the launcher warns and you can run `npm install` or set `AUTO_DOWNLOAD_NWJS=1` to fetch the matching SDK.

**Open multiple files:**
```bash
./bin/visual-page-editor examples/lorem.xml examples/lorem2.xml
```

---

## Container (Docker)

Run the editor in a container (no local NW.js needed).

**Build:**
```bash
docker build --platform linux/amd64 -f Dockerfile.desktop -t visual-page-editor .
```

**Run (headless, e.g. convert):**
```bash
docker run --rm --platform linux/amd64 -v $(pwd):/workspace visual-page-editor examples/lorem.xml
```

**Run with GUI (X11):**

- Linux: use `./docker-run.sh` or pass `-e DISPLAY` and mount `/tmp/.X11-unix`.
- macOS: install XQuartz, allow network clients, then:
  ```bash
  docker run --rm --platform linux/amd64 -e DISPLAY=host.docker.internal:0 -v $(pwd):/workspace visual-page-editor examples/lorem.xml
  ```
  The window appears in the XQuartz app.

See [README-DOCKER.md](README-DOCKER.md) for more options.

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
npm install   # installs deps + NW.js SDK (dependency `nw`)
./bin/visual-page-editor
# or: npm start   # runs NW.js from node_modules (.bin/nw); no global install
# Without Node: ./scripts/bootstrap-node.sh  (needs bash + curl/wget)
# Windows without Node: .\scripts\bootstrap-node.ps1  (PowerShell; or npm run bootstrap:win if npm exists from another install)
```

Smoke-test a PATH-only install: `npm run verify:nw`. The launcher uses `NWJS_VERSION` (default **0.94.0**, aligned with `nw@0.94.0-sdk` in `package.json`). Set `AUTO_DOWNLOAD_NWJS=1` if you rely on the launcher downloading NW.js to `~/.nwjs` when `node_modules` is not present.

Code review: `npm run review` or `./scripts/code-review.sh`. See [CODE_REVIEW.md](CODE_REVIEW.md).

## License and links

- **License:** MIT — [LICENSE.md](LICENSE.md)
- **This project:** [github.com/buzzcauldron/visual-page-editor](https://github.com/buzzcauldron/visual-page-editor)
- **Original:** [nw-page-editor](https://github.com/mauvilsa/nw-page-editor) by Mauricio Villegas
- **Page format:** [omni-us/pageformat](https://github.com/omni-us/pageformat)
