# Visual Page Editor

A modern visual editor for Page XML files, based on [nw-page-editor](https://github.com/mauvilsa/nw-page-editor).

**GitHub Repository:** [https://github.com/buzzcauldron/visual-page-editor](https://github.com/buzzcauldron/visual-page-editor)

**Version:** 1.1.1

**Fixes in 1.1.1:** The bug where the document view would snap to the right (showing the right edge of the page instead of the left) in certain edit/zoom conditions (e.g. TextLine + Baseline mode, horizontal baseline, ltr, baselines visible) is **fixed**. The view now correctly keeps the left edge of the document at the left of the viewport. See `DEBUG.md` → "Document snaps to the right" for details.

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

Visual Page Editor is cross-platform and works on **Linux**, **macOS**, and **Windows**.

#### Prerequisites

- Download the SDK version of NW.js from [http://nwjs.io/downloads](http://nwjs.io/downloads)
- Choose the appropriate version for your platform:
  - **Linux**: `nwjs-sdk-v*-linux-x64.tar.gz`
  - **macOS**: `nwjs-sdk-v*-osx-x64.zip` or `nwjs-sdk-v*-osx-arm64.zip` (for Apple Silicon)
  - **Windows**: `nwjs-sdk-v*-win-x64.zip`

#### Installation Steps

1. **Clone this repository:**
   ```bash
   git clone https://github.com/buzzcauldron/visual-page-editor.git
   cd visual-page-editor
   ```

2. **Install NW.js:**

   **Linux:**
   ```bash
   # Extract NW.js to a location of your choice
   tar -xzf nwjs-sdk-v*-linux-x64.tar.gz
   # Add to PATH (add to ~/.bashrc or ~/.zshrc)
   export PATH="$PATH:/path/to/nwjs-sdk-v*-linux-x64"
   ```

   **macOS:**
   ```bash
   # Detect your Mac's architecture
   uname -m  # Returns "arm64" for Apple Silicon (M1/M2/M3) or "x86_64" for Intel
   
   # For Apple Silicon (M1/M2/M3) Macs:
   unzip nwjs-sdk-v*-osx-arm64.zip
   mv nwjs.app /Applications/
   
   # For Intel Macs:
   unzip nwjs-sdk-v*-osx-x64.zip
   mv nwjs.app /Applications/
   
   # The launcher script will automatically find it in /Applications
   # Note: On Apple Silicon, the launcher prefers ARM64 builds for better performance
   ```

   **Windows:**
   ```powershell
   # Detect your Windows architecture
   echo $env:PROCESSOR_ARCHITECTURE  # Returns "ARM64" for ARM or "AMD64" for x64
   
   # For Windows ARM64 (Surface Pro X, Windows 11 on ARM):
   # Extract nwjs-sdk-v*-win-arm64.zip to:
   # C:\Program Files\nwjs-arm64\
   # or
   # %LOCALAPPDATA%\nwjs-arm64\
   
   # For Windows x64 (Intel/AMD):
   # Extract nwjs-sdk-v*-win-x64.zip to:
   # C:\Program Files\nwjs\
   # or
   # %LOCALAPPDATA%\nwjs\
   
   # The launcher scripts will automatically find it in common locations
   # Note: On ARM64, x64 NW.js will run via emulation (slower performance)
   ```

3. **Add launcher to PATH:**

   **Linux/macOS:**
   ```bash
   # Add the bin directory to your PATH (add to ~/.bashrc, ~/.zshrc, etc.)
   export PATH="$PATH:/path/to/visual-page-editor/bin"
   
   # Or create a symlink
   sudo ln -s /path/to/visual-page-editor/bin/visual-page-editor /usr/local/bin/
   ```

   **Windows:**
   - Add the `bin` directory to your system PATH, or
   - Use the full path to the launcher: `C:\path\to\visual-page-editor\bin\visual-page-editor.bat`
   - For PowerShell, you can use: `C:\path\to\visual-page-editor\bin\visual-page-editor.ps1`

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

3. Run the container (or use `./docker-run.sh` which auto-detects macOS):
   ```bash
   docker run --rm --platform linux/amd64 -e DISPLAY=host.docker.internal:0 -v $(pwd):/workspace visual-page-editor examples/lorem.xml
   ```

4. On macOS, the app window is drawn by XQuartz: it appears **inside the XQuartz window** (the red X icon in the Dock). Bring XQuartz to the foreground if you don’t see the editor.

**Note:** The Docker image includes all necessary dependencies including `libxtst6` for X11 support. The entrypoint script has been fixed to properly generate without syntax errors.

### Quick Start

**Linux/macOS:**
```bash
# Run with example files
./bin/visual-page-editor examples/*.xml
```

**Windows (Command Prompt):**
```cmd
bin\visual-page-editor.bat examples\*.xml
```

**Windows (PowerShell):**
```powershell
.\bin\visual-page-editor.ps1 examples\*.xml
```

## Usage

### Command Line

**Linux/macOS:**
```bash
visual-page-editor [page.xml]+ [pages_dir]+ [--list pages_list]+ [--css file.css]+ [--js file.js]+
```

**Windows:**
```cmd
visual-page-editor.bat [page.xml]+ [pages_dir]+ [--list pages_list]+ [--css file.css]+ [--js file.js]+
```

Or with PowerShell:
```powershell
visual-page-editor.ps1 [page.xml]+ [pages_dir]+ [--list pages_list]+ [--css file.css]+ [--js file.js]+
```

### Example

**Linux/macOS:**
```bash
visual-page-editor examples/lorem.xml examples/lorem2.xml
```

**Windows:**
```cmd
visual-page-editor.bat examples\lorem.xml examples\lorem2.xml
```

## Supported Formats

- omni:us Pages Format (latest version)
- PRImA Page XML (since 2013-07-15)
- PRImA 2010-03-19
- ALTO v2 and v3
- TET
- Poppler's pdftotext xhtml

## Keyboard Shortcuts

**Mod** = `Ctrl` (Windows/Linux) or `Cmd` (macOS).

| Shortcut | Action |
|----------|--------|
| `Mod + O` | Open file |
| `Mod + S` | Save file |
| `Mod + Shift + S` | Save As |
| `Mod + Z` / `Mod + Y` | Undo / Redo |
| `Mod + E` | Open property editor |
| `Mod + 0` / `Mod + 1` / `Mod + 2` | Fit page / Zoom to page / Zoom to element |
| `Page Up/Down` or **Arrow keys** | Navigate documents |
| `Mod + ,` / `Mod + .` | Cycle edit mode (element type / tool) |
| `Tab` / `Shift + Tab` | Next / previous element |
| `Esc` | Deselect, close modal or drawer |

Full list: [KEYBOARD-SHORTCUTS.md](KEYBOARD-SHORTCUTS.md).

## Web Server Variant

The editor can also run as a web server for remote collaboration. See the `web-app` directory for setup instructions.

## Development

### Requirements

- NW.js SDK (for desktop development)
  - **Apple Silicon (M1/M2/M3)**: Use `nwjs-sdk-v*-osx-arm64.zip` for native performance
  - **Intel Mac**: Use `nwjs-sdk-v*-osx-x64.zip`
  - **Windows ARM64**: Use `nwjs-sdk-v*-win-arm64.zip` for native performance (launchers prefer ARM64 over x64 emulation)
  - **Windows x64**: Use `nwjs-sdk-v*-win-x64.zip`
- Node.js (for dependencies)
- Git (for version control)

### Setup

```bash
git clone https://github.com/buzzcauldron/visual-page-editor.git
cd visual-page-editor
npm install
```

### Code Review

The project includes automated code review tools:

```bash
# Run code review
npm run review

# Or directly
./scripts/code-review.sh
```

The review checks:
- JavaScript syntax and style (JSHint)
- HTML/XSLT/XSD validation
- PHP syntax
- Shell script syntax
- Common code issues

See [CODE_REVIEW.md](CODE_REVIEW.md) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request on GitHub.

**How to contribute:**
1. Fork the repository on GitHub
2. Create a feature branch
3. Make your changes
4. Submit a Pull Request

For more details, visit the [GitHub repository](https://github.com/buzzcauldron/visual-page-editor).

## License

MIT License - see [LICENSE.md](LICENSE.md) for details.

## Acknowledgments

This project is based on [nw-page-editor](https://github.com/mauvilsa/nw-page-editor) by Mauricio Villegas. Special thanks to the original author and contributors.

## Links

- **This Project:** [https://github.com/buzzcauldron/visual-page-editor](https://github.com/buzzcauldron/visual-page-editor)
- **Original Project:** [https://github.com/mauvilsa/nw-page-editor](https://github.com/mauvilsa/nw-page-editor)
- **Page XML Format:** [https://github.com/omni-us/pageformat](https://github.com/omni-us/pageformat)
- **PRImA Research:** [http://www.primaresearch.org/](http://www.primaresearch.org/)

## GitHub

For the latest updates, bug reports, feature requests, and contributions, please visit the GitHub repository:

**🔗 [https://github.com/buzzcauldron/visual-page-editor](https://github.com/buzzcauldron/visual-page-editor)**

Before tagging a release, run the checks in **PUBLISH-READINESS.md**.

### Reporting Issues

If you encounter any bugs or have feature requests, please open an issue on GitHub.

See the [Contributing](#contributing) section above for information on how to contribute.

