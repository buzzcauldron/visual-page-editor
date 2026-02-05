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

**Linux / macOS:**
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

The launcher looks for NW.js in common locations and can offer to download it if missing. For packaged builds (e.g. from [BUILD.md](BUILD.md)), use the installed launcher instead.

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
npm install
./bin/visual-page-editor
```

Code review: `npm run review` or `./scripts/code-review.sh`. See [CODE_REVIEW.md](CODE_REVIEW.md).

## License and links

- **License:** MIT — [LICENSE.md](LICENSE.md)
- **This project:** [github.com/buzzcauldron/visual-page-editor](https://github.com/buzzcauldron/visual-page-editor)
- **Original:** [nw-page-editor](https://github.com/mauvilsa/nw-page-editor) by Mauricio Villegas
- **Page format:** [omni-us/pageformat](https://github.com/omni-us/pageformat)
