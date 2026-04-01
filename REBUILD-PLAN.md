# Visual Page Editor — Rebuild Plan

## Why this document exists

The project has accumulated significant technical debt through repeated patch-on-patch fixes,
particularly around the NW.js launcher and startup sequence. The "questionable merge" that
triggered the recent instability was commit `2f221f7` (open(1) macOS launch approach), but
it exposed deeper structural issues: ~10,000 lines of vanilla ES5 with no module system,
a multi-hundred-line bash launcher that had to be rewritten four times to handle NW.js quirks,
and a monolithic architecture that makes every change risky.

The goals of a rebuild are:
1. A launcher that works reliably on all three platforms with zero platform-specific hacks
2. A startup sequence that never hangs (first paint < 300 ms)
3. A module system so bugs stay isolated
4. A test harness that catches regressions before they reach users

---

## Current state summary (post-fix)

| File | Lines | Problem |
|---|---|---|
| `js/svg-canvas.js` | 3,343 | Monolithic — pan, zoom, select, edit, draw all entangled |
| `js/page-canvas.js` | 4,240 | Page XML rendering + all image loaders + all edit modes |
| `js/page-editor.js` | 1,578 | UI glue + shortcut handling + mode state |
| `js/nw-app.js` | 678 | NW.js integration + file I/O + XSD validation |
| `bin/visual-page-editor` | 559 | Bash launcher — platform detection, NW path resolution, caching |

Immediate fixes already landed (current HEAD):
- `vendor-loader.js`: PDF.js / tiff.js / turf.js load lazily after first paint
- `nw-app.js`: `runAfterFirstPaint()` defers argv parsing until chrome is visible
- `bin/visual-page-editor`: npm nw SDK preferred, no `open(1)`, no `--nwapp`, arm64e normalized

---

## Rebuild phases

### Phase 1 — Stabilize the launcher (done)

The launcher is now stable. Do not touch it further unless NW.js releases a breaking change.

Key invariants to preserve:
- `node_modules/.bin/nw` is always the preferred binary (npm `nw` package installs SDK)
- Never use `--nwapp` with the npm CLI wrapper
- Never use `open(1)` — non-blocking, loses exit codes and stderr
- Always prepend `.tools/node-*/bin` to PATH before running the npm CLI wrapper
- Cache file stores three lines: path, version, arch

### Phase 2 — Module system and bundler

**Goal:** Convert the four core JS files to ES modules, bundle for NW.js (no network needed).

Steps:
1. Add `esbuild` as a dev dependency (`npm i -D esbuild`)
2. Create `src/` directory; move core files there with `.mjs` extensions
3. Split each monolith by responsibility:
   - `src/canvas/pan-zoom.mjs` — viewport transforms from `svg-canvas.js`
   - `src/canvas/select.mjs` — selection logic from `svg-canvas.js`
   - `src/canvas/edit-points.mjs` — point editing from `svg-canvas.js`
   - `src/canvas/edit-text.mjs` — text editing from `svg-canvas.js`
   - `src/page/render.mjs` — Page XML rendering from `page-canvas.js`
   - `src/page/image-loaders.mjs` — pdf/tiff/image from `page-canvas.js`
   - `src/page/baseline.mjs` — baseline/polyrect from `page-canvas.js`
   - `src/nw/app.mjs` — NW.js integration from `nw-app.js`
   - `src/nw/winstate.mjs` — window state from `nw-winstate.js`
   - `src/ui/editor.mjs` — UI + shortcuts from `page-editor.js`
4. Add `npm run build` → `esbuild src/main.mjs --bundle --outfile=js/bundle.js`
5. Update `html/index.html` to load `bundle.js` instead of individual files
6. Keep vendor-loader.js pattern for PDF.js / tiff.js / turf (large, rarely needed)

**Do not** convert to React/Vue/etc. — the SVG canvas is bespoke and benefits from direct DOM.

### Phase 3 — Test harness

**Goal:** Catch launcher and startup regressions before commit.

1. Unit tests for the bash launcher using `bats-core`:
   - Platform detection (mock `uname`)
   - NW path resolution (mock file existence)
   - Cache validation (version + arch mismatch)
2. Integration smoke test:
   - `scripts/test-startup.sh` — launches with a fixture XML, waits for window, checks exit 0
   - Run in CI (CircleCI already configured in `.circleci/config.yml`)
3. JS unit tests with `vitest` (zero-config, works with ESM):
   - Test baseline/polyrect math
   - Test Page XML serialization/deserialization
   - Test vendor-loader deduplication

Add to `package.json`:
```json
"test:unit": "vitest run",
"test:launcher": "bats scripts/test-launcher.bats"
```

### Phase 4 — Startup performance

**Goal:** Window visible < 300 ms, first file loaded < 1 s on cold start.

Already done:
- Heavy vendors lazy-loaded (vendor-loader.js)
- File parsing deferred with `runAfterFirstPaint()`

Remaining:
- XSD validation: move `loadPageXmlXsd()` to a Web Worker so it doesn't block the main thread
- Window state restore (`nw-winstate.js`): already async, keep as-is
- `page-canvas.js` init: defer `setupEditMode()` until first file is opened (not on window load)
- Profile with NW.js devtools: open `chrome-devtools://devtools/bundled/inspector.html`

### Phase 5 — Packaging cleanup

**Goal:** One install command, deterministic output, no manual NW.js hunting.

1. `npm install` should be the only required step (nw SDK already a dependency)
2. Remove the `download_nwjs()` function from the launcher — if `npm install` ran, it's not needed;
   if it didn't run, that's the user error to fix, not the launcher's job to paper over
3. Add `npm run verify` → `scripts/verify-local-nw-install.sh` (already exists)
4. Simplify `build-macos.sh` / `build-deb.sh` to call `npm ci` then package — no NW hunting
5. Ship a `Makefile` with targets: `install`, `build`, `test`, `clean`

---

## What NOT to rebuild

- The Page XML data model — it works and matches the XSD
- The SVG coordinate math — it is correct, just needs extraction into a module
- The shortcut system (Mousetrap) — it works fine
- The XSD validation pipeline — works, just needs to move to a Worker
- Docker support — already cleaned up, keep as-is

---

## Risk register

| Risk | Mitigation |
|---|---|
| ESM `import` breaks NW.js content security policy | Use esbuild to bundle back to IIFE/CJS; no dynamic imports in the bundle |
| Splitting svg-canvas.js introduces circular deps | Draw dependency graph first; `select.mjs` must not import `edit-points.mjs` |
| bats not available in CI | Install via `npm i -D bats` or pin a release tarball |
| XSD Worker breaks CORS in NW.js | Use `nw.App.dataPath` as origin; test with devtools Network panel |

---

## Suggested commit sequence for rebuild

```
feat(build): add esbuild and src/ scaffold
refactor(canvas): extract pan-zoom module
refactor(canvas): extract select module
refactor(canvas): extract edit-points module
refactor(page): extract image-loaders module
refactor(page): extract baseline module
feat(test): add bats launcher tests
feat(test): add vitest unit tests
refactor(nw): move XSD load to Worker
chore(pkg): simplify launcher — remove download_nwjs fallback
```

Each commit should leave the app in a working state (no broken builds mid-refactor).
