# Docker (container) — stable, minimal setup

The container bundles **NW.js** and app files inside the image. You only need **Docker** on the host; no Node, no npm, no global NW.js.

**Default NW.js version:** **0.94.0** (same family as `package.json` / `./bin/visual-page-editor`). Override at build time with `--build-arg NWJS_VERSION=…`.

---

## Recommended: one command (GUI)

From the repository root:

```bash
./docker-run.sh examples/lorem.xml
```

The first run **builds** an image tagged `visual-page-editor:<version>` where `<version>` comes from the [`VERSION`](VERSION) file (for example `visual-page-editor:1.2.0`). The script also tags **`visual-page-editor:latest`** for convenience.

- **Rebuild** after pulling git changes or changing `VERSION`:  
  `./docker-run.sh --build examples/lorem.xml`

- **Help:** `./docker-run.sh --help`

### Prerequisites

| Host | What you need |
|------|----------------|
| **macOS** | [Docker Desktop](https://docs.docker.com/desktop/) and [XQuartz](https://www.xquartz.org/). XQuartz → Settings → Security → **Allow connections from network clients**, then quit and reopen XQuartz. `docker-run.sh` sets `DISPLAY=host.docker.internal:0`. |
| **Linux** | Docker Engine + local X11. `docker-run.sh` uses `DISPLAY=:0` and `xhost +local:docker` (or set `DISPLAY` yourself). Mounting `/tmp/.X11-unix` is handled by the script. |
| **Headless** | Omit GUI: run the image without a usable `DISPLAY`; the [entrypoint](Dockerfile.desktop) starts **Xvfb** on `:99` so the process still runs (no visible window). |

---

## Docker Compose (alternative)

For teams that prefer Compose:

1. Copy env template: `cp .env.docker.example .env`
2. Set **`DISPLAY`** in `.env` for your OS (see comments in [`.env.docker.example`](.env.docker.example)).
3. Optionally set **`VPE_VERSION`** to match [`VERSION`](VERSION) so the image name matches releases.
4. Build and run:

```bash
docker compose build
docker compose run --rm visual-page-editor examples/lorem.xml
```

`network_mode: host` is **not** used so the same file works on **Docker Desktop (macOS/Windows)** and Linux.

---

## Manual `docker build` / `docker run`

Pin the app version label and image tag to match [`VERSION`](VERSION):

```bash
V="$(tr -d '\n' < VERSION)"
docker build --platform linux/amd64 \
  --build-arg NWJS_VERSION=0.94.0 \
  --build-arg APP_VERSION="$V" \
  -f Dockerfile.desktop -t "visual-page-editor:${V}" .
```

Run (Linux X11 example):

```bash
xhost +local:docker
docker run --rm -it --platform linux/amd64 \
  -e DISPLAY=:0 \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -v "$HOME/.Xauthority:/root/.Xauthority:rw" \
  -v "$(pwd):/workspace:rw" \
  -v "$(pwd)/examples:/app/examples:ro" \
  "visual-page-editor:${V}" examples/lorem.xml
```

macOS + XQuartz: use `-e DISPLAY=host.docker.internal:0` and omit the `/tmp/.X11-unix` mount (see `./docker-run.sh`).

---

## Stability notes

- **Platform:** Images are **linux/amd64** NW.js. On Apple Silicon, Docker runs them via emulation; that is expected and keeps one image for everyone.
- **Reproducible tags:** Prefer `visual-page-editor:<VERSION>` over `:latest` when reporting bugs or deploying.
- **Data:** The repo is mounted at **`/workspace`**; saves from the app go to your host working tree. **`examples`** is mounted read-only at **`/app/examples`** so paths like `examples/lorem.xml` resolve with `WORKDIR` `/app`.

---

## Troubleshooting

| Issue | What to try |
|-------|----------------|
| **Cannot connect to X server** | macOS: XQuartz running + network clients enabled. Linux: `echo $DISPLAY`, `xhost +local:docker`, X server running. |
| **Rebuild after upgrade** | `./docker-run.sh --build …` or `docker compose build --no-cache` |
| **Wrong / old NW.js** | Rebuild with explicit `--build-arg NWJS_VERSION=0.94.0` |

Application logs inside the container go to stderr; NW.js/Chromium messages appear in the terminal you used for `docker run`.
