# Packaging nw-page-editor for RPM and DEB

This document explains how to build RPM and DEB packages that automatically include NW.js, making the packages self-contained with no external dependencies.

## Features

- **Bundled NW.js**: Both packages include NW.js runtime (v0.44.4 by default)
- **No External Dependencies**: Users don't need to install NW.js separately
- **Automatic Download**: Build scripts automatically download NW.js during build
- **Self-Contained**: Packages work out of the box after installation

## Building RPM Package

### Prerequisites

```bash
# Fedora/RHEL/CentOS
sudo dnf install rpm-build curl tar gzip

# openSUSE
sudo zypper install rpm-build curl tar gzip
```

### Build Process

1. **Navigate to the project directory:**
   ```bash
   cd /path/to/nw-page-editor
   ```

2. **Run the build script:**
   ```bash
   cd rpm
   ./build-rpm.sh
   ```

   Or specify a custom NW.js version:
   ```bash
   NWJS_VERSION=0.77.0 ./build-rpm.sh
   ```

3. **Find the built package:**
   ```bash
   ls -lh ~/rpmbuild/RPMS/x86_64/nw-page-editor-*.rpm
   ```

### Installing the RPM

```bash
sudo dnf install ~/rpmbuild/RPMS/x86_64/nw-page-editor-*.rpm
```

Or using yum:
```bash
sudo yum install ~/rpmbuild/RPMS/x86_64/nw-page-editor-*.rpm
```

## Building DEB Package

### Prerequisites

```bash
# Debian/Ubuntu
sudo apt-get install build-essential devscripts curl tar gzip
```

### Build Process

1. **Navigate to the project directory:**
   ```bash
   cd /path/to/nw-page-editor
   ```

2. **Run the build script:**
   ```bash
   ./build-deb.sh
   ```

   Or specify a custom NW.js version:
   ```bash
   NWJS_VERSION=0.77.0 ./build-deb.sh
   ```

3. **Find the built package:**
   ```bash
   ls -lh ../nw-page-editor_*.deb
   ```

### Installing the DEB

```bash
sudo dpkg -i ../nw-page-editor_*.deb
```

If there are dependency issues:
```bash
sudo apt-get install -f
sudo dpkg -i ../nw-page-editor_*.deb
```

## Manual Build (Advanced)

### RPM Manual Build

1. **Set up RPM build directories:**
   ```bash
   mkdir -p ~/rpmbuild/{SOURCES,SPECS,BUILD,RPMS,SRPMS}
   ```

2. **Create source tarball:**
   ```bash
   cd /path/to/nw-page-editor
   git archive --format=tar.gz \
       --prefix=nw-page-editor-2022.09.13/ \
       --output=~/rpmbuild/SOURCES/nw-page-editor-2022.09.13.tar.gz \
       HEAD
   ```

3. **Download NW.js (if not already present):**
   ```bash
   cd /path/to/nw-page-editor
   curl -fLSs -o nwjs-sdk-linux-x64.tar.gz \
       "https://dl.nwjs.io/v0.44.4/nwjs-sdk-v0.44.4-linux-x64.tar.gz"
   tar -xzf nwjs-sdk-linux-x64.tar.gz
   mv nwjs-sdk-v0.44.4-linux-x64 nwjs
   ```

4. **Build RPM:**
   ```bash
   cp rpm/nw-page-editor.spec ~/rpmbuild/SPECS/
   rpmbuild -ba ~/rpmbuild/SPECS/nw-page-editor.spec
   ```

### DEB Manual Build

1. **Download NW.js (if not already present):**
   ```bash
   cd /path/to/nw-page-editor
   curl -fLSs -o nwjs-sdk-linux-x64.tar.gz \
       "https://dl.nwjs.io/v0.44.4/nwjs-sdk-v0.44.4-linux-x64.tar.gz"
   tar -xzf nwjs-sdk-linux-x64.tar.gz
   mv nwjs-sdk-v0.44.4-linux-x64 nwjs
   ```

2. **Build DEB:**
   ```bash
   export NWJS_VERSION=0.44.4
   dpkg-buildpackage -b -us -uc
   ```

## Package Contents

Both packages install:

- **Application files**: `/usr/share/nw-page-editor/`
  - HTML, CSS, JavaScript files
  - XSD schemas and XSLT transforms
  - Example files
  - Node.js modules

- **NW.js runtime**: `/usr/lib/nw-page-editor/nwjs/` (DEB) or `/usr/lib64/nw-page-editor/nwjs/` (RPM)
  - Complete NW.js SDK runtime
  - No external dependency needed

- **Launcher script**: `/usr/bin/nw-page-editor`
  - Automatically uses bundled NW.js
  - Falls back to system NW.js if bundled version not found

- **Documentation**: `/usr/share/doc/nw-page-editor/`

## Customizing NW.js Version

To use a different version of NW.js:

**For RPM:**
```bash
NWJS_VERSION=0.77.0 ./rpm/build-rpm.sh
```

**For DEB:**
```bash
NWJS_VERSION=0.77.0 ./build-deb.sh
```

Or edit the spec file (`rpm/nw-page-editor.spec`) or rules file (`debian/rules`) and change the `NWJS_VERSION` variable.

## Troubleshooting

### Build fails with "Could not download NW.js"

- Check your internet connection
- Verify the NW.js version exists at https://dl.nwjs.io/
- Manually download and extract NW.js to the `nwjs` directory in the project root

### Package installs but application won't run

- Check that the launcher script is executable: `ls -l /usr/bin/nw-page-editor`
- Verify NW.js is present: `ls -l /usr/lib*/nw-page-editor/nwjs/nw`
- Check logs: `cat /tmp/nw-page-editor.log`

### Architecture mismatch

- RPM package is built for `x86_64` architecture
- DEB package is built for `amd64` architecture
- For other architectures, you'll need to download the appropriate NW.js build and modify the build scripts

## Distribution

The built packages can be distributed to users who can install them directly without needing to install NW.js separately. This makes deployment much easier, especially in enterprise environments.

## Notes

- The packages are larger (~100-150MB) because they include the NW.js runtime
- The launcher script automatically detects and uses the bundled NW.js
- If system NW.js is preferred, users can remove the bundled version and install system NW.js package
- Both packages follow standard Linux packaging conventions

