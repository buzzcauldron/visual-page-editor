# Visual Page Editor

A modern visual editor for Page XML files, based on [nw-page-editor](https://github.com/mauvilsa/nw-page-editor).

## Description

Visual Page Editor is an application for viewing and editing ground truth or predicted information for document processing and text recognition. The editing is done interactively and visually on top of images of scanned documents.

This project is a fork/evolution of the original nw-page-editor with improvements and modernizations.

## Features

- **Visual Editing**: Interactive editing of Page XML files with visual feedback
- **Multiple Format Support**: Supports omni:us Pages Format, PRImA Page XML, ALTO v2/v3, TET, and Poppler formats
- **Desktop Application**: Cross-platform desktop app using NW.js
- **Web Application**: Web-based version for remote collaboration
- **Keyboard Shortcuts**: Extensive keyboard shortcuts for efficient editing
- **Extensible**: Plugin system for custom functionality

## Installation

### Desktop Variant

#### Linux/macOS

1. Download the SDK version of NW.js from [http://nwjs.io/downloads](http://nwjs.io/downloads)
2. Extract NW.js to a location of your choice
3. Add the NW.js binary directory to your PATH
4. Clone this repository:
   ```bash
   git clone https://github.com/buzzcauldron/visual-page-editor.git
   cd visual-page-editor
   ```
5. Add the `bin` directory to your PATH or symlink `bin/visual-page-editor` to a directory in your PATH

#### Windows

1. Download the SDK version of NW.js for Windows from [http://nwjs.io/downloads](http://nwjs.io/downloads)
2. Extract NW.js to a location of your choice (e.g., `C:\Program Files\nwjs\`)
3. Add the NW.js directory (containing `nw.exe`) to your PATH, or the launcher will check common locations automatically
4. Clone this repository:
   ```cmd
   git clone https://github.com/buzzcauldron/visual-page-editor.git
   cd visual-page-editor
   ```
5. Use `bin\visual-page-editor.bat` (or `bin\visual-page-editor.ps1` for PowerShell) to launch the application, or add the `bin` directory to your PATH
   
   **Note:** The `.bat` file will automatically use the PowerShell script (`.ps1`) if available for better argument handling. Both launchers are provided for compatibility.

### Docker Desktop Variant

The application can also be run in a Docker container, which is useful for consistent environments across different platforms.

#### Prerequisites

- Docker Desktop installed and running
- For GUI support on macOS: XQuartz installed and configured

#### Building the Docker Image

```bash
docker build --platform linux/amd64 -f Dockerfile.desktop -t visual-page-editor .
```

#### Running with Docker

**Headless mode (no GUI):**
```bash
docker run --rm --platform linux/amd64 -v $(pwd):/workspace visual-page-editor examples/lorem.xml
```

**With GUI support (macOS):**

1. Install XQuartz if not already installed:
   ```bash
   brew install --cask xquartz
   ```

2. Enable network connections in XQuartz:
   - Open XQuartz → Preferences → Security
   - Check "Allow connections from network clients"
   - Restart XQuartz

3. Run the container:
   ```bash
   docker run --rm --platform linux/amd64 -e DISPLAY=host.docker.internal:0 -v $(pwd):/workspace visual-page-editor examples/lorem.xml
   ```

**Note:** The Docker image includes all necessary dependencies including `libxtst6` for X11 support. The entrypoint script has been fixed to properly generate without syntax errors.

### Quick Start

```bash
# Run with example files
./bin/visual-page-editor examples/*.xml
```

## Usage

### Command Line

```bash
visual-page-editor [page.xml]+ [pages_dir]+ [--list pages_list]+ [--css file.css]+ [--js file.js]+
```

### Example

```bash
visual-page-editor examples/lorem.xml examples/lorem2.xml
```

## Supported Formats

- omni:us Pages Format (latest version)
- PRImA Page XML (since 2013-07-15)
- PRImA 2010-03-19
- ALTO v2 and v3
- TET
- Poppler's pdftotext xhtml

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl/Cmd + O` | Open file |
| `Ctrl/Cmd + S` | Save file |
| `Ctrl/Cmd + Z` | Undo |
| `Ctrl/Cmd + Y` | Redo |
| `Ctrl/Cmd + E` | Open property editor |
| `Ctrl/Cmd + 0` | View full document |
| `Ctrl/Cmd + 1` | Zoom to page |
| `Ctrl/Cmd + 2` | Zoom to element |
| `Page Up/Down` | Navigate documents |
| `Tab` | Select next element |
| `Esc` | Deselect element |

See the original [nw-page-editor documentation](https://github.com/mauvilsa/nw-page-editor) for the complete list of shortcuts.

## Web Server Variant

The editor can also run as a web server for remote collaboration. See the `web-app` directory for setup instructions.

## Development

### Requirements

- NW.js SDK (for desktop development)
- Node.js (for dependencies)
- Git (for version control)

### Setup

```bash
git clone https://github.com/buzzcauldron/visual-page-editor.git
cd visual-page-editor
npm install
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE.md](LICENSE.md) for details.

## Acknowledgments

This project is based on [nw-page-editor](https://github.com/mauvilsa/nw-page-editor) by Mauricio Villegas. Special thanks to the original author and contributors.

## Links

- Original Project: https://github.com/mauvilsa/nw-page-editor
- Page XML Format: https://github.com/omni-us/pageformat
- PRImA Research: http://www.primaresearch.org/

