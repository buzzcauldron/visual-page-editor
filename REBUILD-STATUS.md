# REBUILD-PLAN: implementation status

This file tracks **what is not implemented yet** relative to [REBUILD-PLAN.md](REBUILD-PLAN.md). Update it when phases land. Design principles (DRY, orthogonality) for build and review live in [REBUILD-PLAN.md](REBUILD-PLAN.md) under “Design principles”.

---

## Phase 1 — Launcher

**Status:** Done per plan (stable launcher; invariants documented in REBUILD-PLAN).

---

## Phase 2 — Module system and bundler

### Done (aligned with plan)

- `esbuild`, [`src/entry.js`](src/entry.js) → `js/bundle.js`, [`html/index.html`](html/index.html) loading `bundle.js`, lazy vendor pattern retained.

### Not done (per plan’s file split list)

- `src/canvas/select.mjs`, `edit-points.mjs`, `edit-text.mjs` — still in [`js/svg-canvas.js`](js/svg-canvas.js).
- `src/page/render.mjs`, `baseline.mjs` — still in [`js/page-canvas.js`](js/page-canvas.js) (aside from [`src/page/image-loaders.mjs`](src/page/image-loaders.mjs)).
- `src/nw/app.mjs`, `src/nw/winstate.mjs` — still [`js/nw-app.js`](js/nw-app.js), [`js/nw-winstate.js`](js/nw-winstate.js).
- `src/ui/editor.mjs` — still [`js/page-editor.js`](js/page-editor.js).

**Naming:** The plan once referred to `src/main.mjs`; the repo uses [`src/entry.js`](src/entry.js).

---

## Phase 3 — Test harness

### Done

- [`scripts/test-launcher.bats`](scripts/test-launcher.bats) (bats).
- Vitest + [`src/utils/point2f.test.mjs`](src/utils/point2f.test.mjs).

### Not done or incomplete vs plan

- **Integration smoke:** Plan specifies `scripts/test-startup.sh` (fixture XML, window, exit 0). That script **does not exist**; only related assets such as [`test-startup-performance.sh`](test-startup-performance.sh) and docs references.
- **CI breadth:** [`.github/workflows/code-review.yml`](.github/workflows/code-review.yml) runs on `main` and `develop` only (not `rebuild`), and does **not** run `npm run build`, `npm run test:unit`, or `npm run test:launcher`. Bats in CI was called out as a risk in the plan; the workflow still does not install/run bats.
- **Vitest scope:** Plan lists baseline/polyrect math, Page XML serialization/deserialization, vendor-loader tests; currently only **Point2f** has a dedicated `*.test.mjs`.

---

## Phase 4 — Startup performance (“Remaining” in REBUILD-PLAN)

See [REBUILD-PLAN.md](REBUILD-PLAN.md) Phase 4 (lines ~127–131).

**Still open:**

- **XSD validation:** Move `loadPageXmlXsd()` in [`js/nw-app.js`](js/nw-app.js) to a **Web Worker** so it does not block the main thread.
- **`page-canvas.js` init:** Defer edit-mode setup until first file is opened (plan wording: `setupEditMode()`); treat as **open** until audited and checked off.
- **Profiling** in NW devtools — manual/operational, not a repo artifact.

**Already done (per plan):** Lazy vendors (`vendor-loader.js`), `runAfterFirstPaint()` in `nw-app.js`.

---

## Phase 5 — Packaging cleanup

### Done

- `npm install` as primary path; `download_nwjs()` removed from launcher (per rebuild branch).
- [`Makefile`](Makefile) with `install`, `build`, `test`, `clean`, etc.
- `build-macos.sh` / `build-deb.sh` oriented around npm-provided NW SDK.

### Gaps

- **`npm run verify` → [`scripts/verify-local-nw-install.sh`](scripts/verify-local-nw-install.sh):** The script copies a **minimal** tree (`package.json`, `package-lock.json`, `bin/`, stub `js`/`html`) without `src/`. `npm ci` runs `prepare` → `npm run build`, which requires `src/entry.js`, so verification can fail unless the script is extended or lifecycle scripts are skipped for that scenario. Align with [REBUILD-PLAN.md](REBUILD-PLAN.md) “Install verification” under Design principles.

---

## Suggested commit sequence (not yet done)

Typical remaining items from the bottom of [REBUILD-PLAN.md](REBUILD-PLAN.md):

- `refactor(canvas): extract select module`
- `refactor(canvas): extract edit-points module` (and edit-text if following the plan literally)
- `refactor(page): extract baseline module` (and render)
- `refactor(nw): move XSD load to Worker`
- `feat(test):` integration startup script as described, plus broader Vitest coverage
- `ci:` run `npm run build`, `npm run test:unit`, `npm run test:launcher` (and optionally extend branches)

**Already reflected on rebuild branch:** esbuild scaffold, pan-zoom + image-loaders extraction, bats + Vitest baseline, launcher simplification, packaging/Makefile direction.

---

## Summary

| Phase       | Status vs plan |
|-------------|----------------|
| 1 Launcher  | Done per plan |
| 2 Modules   | **Large remainder** — only pan-zoom, image-loaders, Point2f + entry |
| 3 Tests     | **Partial** — missing `test-startup.sh`, limited Vitest scope, CI not matching full npm test matrix |
| 4 Perf      | **Open** — Worker XSD, edit-mode deferral, profiling |
| 5 Packaging | **Mostly done** — verify script may need repair for bundle/`prepare` workflow |
