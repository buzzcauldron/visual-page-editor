# Installing on macOS

Use a **native Apple Silicon terminal** when you are on an M-series Mac (Terminal.app or iTerm2 **without** “Open using Rosetta”). If you must use a Rosetta terminal, `scripts/bootstrap-node.sh` still prefers **arm64** Node and NW.js when it detects translation (`sysctl.proc_translated`).

## One-shot install (Node optional)

From the repository root:

```bash
./scripts/install-desktop.sh
```

This downloads **portable Node 20** into `.tools/` only if there is no usable **Node 18+** on your `PATH`, then runs **`npm install`** (which pulls the **NW.js** SDK into `node_modules/`).

Start the app:

```bash
./bin/visual-page-editor examples/lorem.xml
```

Or:

```bash
npm start
```

Keep using the **same terminal** after install so `PATH` still includes `.tools/.../bin` when portable Node was used. Otherwise run `./scripts/install-desktop.sh` again before `npm` commands, or open a new shell and rely on system Node if you installed one.

## Same steps via repo root wrapper

```bash
./install.sh
```

## Prerequisites

- **curl** or **wget**, and **tar** (standard on macOS)
- **Git** (for clone); install [Xcode Command Line Tools](https://developer.apple.com/documentation/xcode) if `git` is missing: `xcode-select --install`

## If something goes wrong

- **`Error: spawn .../node_modules/nw/nwjs-sdk-.../nwjs.app/Contents/MacOS/nwjs ENOENT`**  
  The NW.js download inside `node_modules/nw` is **missing or incomplete** (interrupted install, disk full, or antivirus). Reinstall that tree:
  ```bash
  rm -rf node_modules/nw
  npm install
  ```
  Or wipe dependencies and run the installer again:
  ```bash
  rm -rf node_modules .tools
  ./scripts/install-desktop.sh
  ```
  Then confirm the binary exists:
  ```bash
  ls -la node_modules/nw/nwjs-sdk-v*/nwjs.app/Contents/MacOS/nwjs
  ```

- **`env: node: No such file or directory`** when running `node_modules/.bin/nw`: run **`./bin/visual-page-editor`** from the repo (it prepends `.tools/node-v*/bin` to `PATH`), or run `./scripts/install-desktop.sh` again.

- **Conda `(base)` / mixed Node**: A conda environment can put a different `node`/`npm` on your `PATH` than the one used when `node_modules` was built. Prefer **`conda deactivate`** before `./scripts/install-desktop.sh`, or run **`./scripts/test-fresh-install-mac.sh 1`** (uses a minimal `PATH` like a clean Mac).

### Full reinstall (copy-paste safe)

Run **one block at a time**. Do **not** put `#` comments on the **same line** as a command—some paste targets or tools pass the `#` text into `conda` or `npm`, which causes errors like `deactivate does not accept arguments` or `Invalid tag name "#"`.

If you use conda, deactivate first (line must contain only this):

```bash
conda deactivate
```

Then from your clone directory (change the path if yours differs):

```bash
cd ~/visual-page-editor
```

```bash
rm -rf node_modules .tools
```

```bash
./scripts/install-desktop.sh
```

- **Wrong or cached NW.js path**:  
  `rm -f ~/.cache/visual-page-editor/nw-path`  
  then run `./bin/visual-page-editor` again.

- **Scripts not executable**:  
  `chmod +x scripts/bootstrap-node.sh scripts/install-desktop.sh bin/visual-page-editor`

- **Log mentions `/Applications/nwjs.app` or Rosetta on an M-series Mac**: You may have a **generic x64** NW.js on `PATH` or in Applications. Remove or avoid `/Applications/nwjs.app`, clear the cache (above), and rely on **`node_modules/nw`** after a full `npm install`.

## Test a “fresh clone” locally (numbered folders)

Without re-cloning from GitHub, you can copy the tree (excluding `node_modules`, `.tools`, `.git`) into a disposable folder and run the installer. The script runs install with **`PATH=/usr/bin:/bin` only** so it does not accidentally use Node from Homebrew, `nvm`, or another checkout—matching a clean Terminal session as closely as possible.

```bash
./scripts/test-fresh-install-mac.sh 1
./scripts/test-fresh-install-mac.sh 2
```

Copies live under **`.vpe-fresh-install-runs/<N>/`** (gitignored). Use another number whenever you want a clean tree. Remove when done:

```bash
rm -rf .vpe-fresh-install-runs
```

Equivalent npm script: **`npm run test:install-mac`**.

## Docker alternative

No local Node/NW.js: see **[README-DOCKER.md](README-DOCKER.md)** and **`./docker-run.sh`**.
