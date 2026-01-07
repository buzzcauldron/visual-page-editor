# Running Visual Page Editor in Docker

This guide explains how to run Visual Page Editor as a Docker container.

## Prerequisites

- Docker installed and running
- X11 server running (for GUI display)
- X11 forwarding enabled

## Quick Start

### Option 1: Using the convenience script

```bash
./docker-run.sh examples/*.xml
```

### Option 2: Using docker-compose

```bash
docker-compose up
```

### Option 3: Manual Docker command

```bash
# Build the image
docker build -f Dockerfile.desktop -t visual-page-editor:latest .

# Allow X11 connections
xhost +local:docker

# Run the container
docker run --rm -it \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v $HOME/.Xauthority:/root/.Xauthority:rw \
    -v $(pwd):/workspace:rw \
    visual-page-editor:latest examples/*.xml
```

## Building the Image

```bash
docker build -f Dockerfile.desktop -t visual-page-editor:latest .
```

To specify a different NW.js version:

```bash
docker build -f Dockerfile.desktop \
    --build-arg NWJS_VERSION=0.44.4 \
    -t visual-page-editor:latest .
```

## Usage

### Opening files

```bash
# Open specific files
./docker-run.sh examples/lorem.xml examples/lorem2.xml

# Open all XML files in examples directory
./docker-run.sh examples/*.xml

# Open files from current directory
./docker-run.sh *.xml
```

### Working with your data

Files are mounted at `/workspace` in the container. Any files you save will be written to your host machine's current directory.

### X11 Display Issues

If you encounter display issues:

1. **Allow X11 connections:**
   ```bash
   xhost +local:docker
   ```

2. **Check DISPLAY variable:**
   ```bash
   echo $DISPLAY
   # Should output something like :0 or :1
   ```

3. **For remote X11:**
   ```bash
   export DISPLAY=your-remote-ip:0
   ```

## Container Details

- **Base Image:** Ubuntu 22.04
- **NW.js Version:** 0.44.4 (configurable via build arg)
- **Working Directory:** `/app`
- **Data Mount:** `/workspace` (maps to current directory)

## Environment Variables

- `DISPLAY` - X11 display (default: `:0`)
- `NWJS_VERSION` - NW.js version to use (build-time only)

## Troubleshooting

### "Cannot connect to X server"

Make sure:
- X11 server is running
- `xhost +local:docker` has been run
- DISPLAY variable is set correctly

### "Permission denied" errors

Try running with:
```bash
docker run --rm -it --privileged \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    visual-page-editor:latest
```

### Application doesn't start

Check the logs:
```bash
docker logs visual-page-editor
```

## Headless Mode (Xvfb)

If you don't have an X server, the container will automatically use Xvfb (virtual framebuffer). Note that you won't see the GUI, but the application will run.

## Building for Different Platforms

To build for a specific platform:

```bash
docker buildx build --platform linux/amd64 \
    -f Dockerfile.desktop \
    -t visual-page-editor:latest .
```

