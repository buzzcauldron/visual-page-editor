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

```bash
git clone https://github.com/buzzcauldron/visual-page-editor.git
cd visual-page-editor
./scripts/install-desktop.sh
./bin/visual-page-editor examples/lorem.xml
```

That installs dependencies (and bootstraps Node into `.tools/` if you do not have Node 18+), pulls the NW.js SDK via npm, then opens the sample Page XML. You do not need a global `nw` on `PATH`.

**Windows (PowerShell):** `.\scripts\install-desktop.ps1` then `.\bin\visual-page-editor.ps1 examples\lorem.xml`

Optional: `./scripts/install-desktop.sh --start` runs install and then launches the app in one step. On Windows: `.\scripts\install-desktop.ps1 -Start`.

More detail — Docker desktop image, tests, packaging, Apple Silicon notes: [README-DOCKER.md](README-DOCKER.md), [TESTING.md](TESTING.md), [BUILD.md](BUILD.md), [INSTALL-MAC.md](INSTALL-MAC.md).

**Open multiple files:** `./bin/visual-page-editor examples/lorem.xml examples/lorem2.xml`

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
