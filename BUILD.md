# Building Packages

## Current Status

✅ **All build files are ready and validated!**

- ✓ RPM spec file: `rpm/nw-page-editor.spec`
- ✓ RPM build script: `rpm/build-rpm.sh`
- ✓ DEB control file: `debian/control`
- ✓ DEB rules file: `debian/rules`
- ✓ DEB build script: `build-deb.sh`

## Building on Linux

### For RPM (Fedora/RHEL/CentOS):

```bash
cd /path/to/nw-page-editor
cd rpm
./build-rpm.sh
```

The RPM will be in: `~/rpmbuild/RPMS/x86_64/nw-page-editor-*.rpm`

### For DEB (Debian/Ubuntu):

```bash
cd /path/to/nw-page-editor
./build-deb.sh
```

The DEB will be in: `../nw-page-editor_*.deb`

## Building from macOS (or any system) using Docker

Since you're on macOS, you can use Docker to build Linux packages:

### Option 1: Use the Docker build script

```bash
# Build both RPM and DEB
./build-docker.sh both

# Or build just one:
./build-docker.sh rpm
./build-docker.sh deb
```

### Option 2: Manual Docker build

**For RPM:**
```bash
docker run --rm -it \
  -v $(pwd):/workspace \
  -w /workspace \
  fedora:latest bash -c "
  dnf install -y rpm-build curl tar gzip git perl &&
  cd rpm && ./build-rpm.sh
"
```

**For DEB:**
```bash
docker run --rm -it \
  -v $(pwd):/workspace \
  -w /workspace \
  debian:latest bash -c "
  apt-get update &&
  apt-get install -y build-essential devscripts curl tar gzip git perl &&
  ./build-deb.sh
"
```

## What Gets Built

Both packages will:
- ✅ Automatically download NW.js v0.44.4 (or specified version)
- ✅ Bundle NW.js with the application
- ✅ Create self-contained packages with no external dependencies
- ✅ Include all application files, examples, and documentation

## Custom NW.js Version

To use a different NW.js version:

```bash
NWJS_VERSION=0.50.0 ./rpm/build-rpm.sh
NWJS_VERSION=0.50.0 ./build-deb.sh
```

## Next Steps

1. **If you have access to a Linux system**: Use the build scripts directly
2. **If you're on macOS/Windows**: Use Docker (see above)
3. **For CI/CD**: Use the Docker approach in your pipeline

The packages are ready to build - you just need a Linux environment (native or Docker)!

