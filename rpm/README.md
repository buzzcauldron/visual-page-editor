# RPM Packaging for visual-page-editor

This directory contains files for building an RPM package that includes a bundled NW.js runtime.

## Quick Start

```bash
cd rpm
./build-rpm.sh
```

Or from the project root:

```bash
./rpm/build-rpm.sh
```

The built RPM will be in `~/rpmbuild/RPMS/x86_64/` (or the equivalent for your architecture).

## Features

- **Bundled NW.js**: Build script downloads and includes NW.js (version from `VERSION` or package.json)
- **No Dependencies**: Package has no external runtime dependencies
- **Self-Contained**: Works immediately after installation

## Files

- `visual-page-editor.spec` - RPM spec file
- `build-rpm.sh` - Automated build script

## Customization

To use a different NW.js version:

```bash
NWJS_VERSION=0.50.0 ./build-rpm.sh
```

## Installation

After building:

```bash
sudo dnf install ~/rpmbuild/RPMS/x86_64/visual-page-editor-*.rpm
```

See the main `PACKAGING.md` file for more details.
