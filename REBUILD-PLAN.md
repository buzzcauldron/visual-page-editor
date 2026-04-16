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

**What is implemented vs still open** (living checklist): [REBUILD-STATUS.md](REBUILD-STATUS.md).

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

## Design principles — DRY and orthogonality (build and review)

These principles guide how we evolve the rebuild so tooling stays maintainable and review stays trustworthy.

### DRY (single sources, no accidental forks)

- **Version and NW pin:** Treat [`VERSION`](VERSION) and `package.json` (`version`, `dependencies.nw`) as canonical. Propagate with [`scripts/sync-version.sh`](scripts/sync-version.sh) / [`scripts/bump-version.sh`](scripts/bump-version.sh) so RPM spec, launchers, Docker defaults, and docs do not drift.
- **One bundle command:** `npm run build` (esbuild `src/entry.js` → `js/bundle.js`) is the only supported app bundle. CI, Docker builder stages, and local dev should all invoke this same script—not a copy-pasted esbuild line that can diverge.
- **Docker builder stages:** [`Dockerfile`](Dockerfile) and [`Dockerfile.desktop`](Dockerfile.desktop) repeat the same Node builder pattern (`npm install --ignore-scripts`, copy `js` + `src`, `npm run build`). When changing that flow, update both or extract a shared snippet (e.g. `docker build` with `--target` from one file, or a small `scripts/docker-bundle-stage.sh` invoked by both) so the bundle step stays one logical path.
- **Install verification:** [`scripts/verify-local-nw-install.sh`](scripts/verify-local-nw-install.sh) must either copy everything required for `prepare` / `npm run build` (including `src/`) or explicitly skip lifecycle scripts—same rules as a real clone, not a second broken mini-tree.
- **Lint vs review:** [`package.json`](package.json) `lint` excludes generated/vendor files (`js/bundle.js`, `js/xmllint.js`). [`scripts/code-review.sh`](scripts/code-review.sh) should apply the same exclusions (or delegate to `npm run lint`) so “review” and “lint” are not two competing definitions of clean JS.

### Orthogonality (separation of concerns)

- **Builder vs runtime:** Build-time Node/esbuild lives only in the builder stage or dev machine; container runtimes install what they need to run (Apache + PHP for web image; NW.js binary for desktop image)—no mixing “download NW in the Dockerfile builder” with “bundle JS” unless strictly necessary.
- **Launcher vs application:** The launcher resolves NW and invokes the app; application code does not re-implement NW discovery, caching rules, or bootstrap policy.
- **Test layers:** Bats tests assert launcher behavior only; Vitest targets pure modules (`src/utils`, extracted canvas/page helpers); future integration smoke (`scripts/test-startup.sh`) asserts end-to-end once. Avoid duplicating the same expectation in both unit and shell tests without a clear boundary.
- **Review pipeline:** Prefer a **fast, deterministic** path—`npm run build`, `npm run typecheck`, `npm run test:unit`, `npm run test:launcher`, `npm run lint`—as the gate; use full `./scripts/code-review.sh` (and optional XML/shell checks) as a broader sweep. Orthogonal steps make failures easy to attribute (build vs test vs lint vs assets).

Applying these consistently reduces duplicate work in packaging scripts, keeps CI aligned with local commands, and makes code review reflect the same rules developers run before push.

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
4. Add `npm run build` → `esbuild src/entry.js --bundle --outfile=js/bundle.js` (entry file may stay `entry.js` unless renamed deliberately)
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
