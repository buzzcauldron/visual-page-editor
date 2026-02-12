# Code review – version 1.1.0

Review date: 2025-01-28. Scope: changes on current branch vs main (new version 1.1.0).

---

## Automated checks

| Check | Result |
|-------|--------|
| `./scripts/code-review.sh` | Passed (exit 0) |
| HTML structure | index.html, test-example.html OK |
| Shell scripts | All syntax OK |
| Required files | package.json, README.md, LICENSE.md, html/index.html present |
| **Warning** | 65 `console.log` statements (consider reducing for production) |

Skipped in this environment (tools not installed): jshint, xmlstarlet, php, pwsh. Run locally with `npm run review` and install tools for full validation.

---

## Version and docs consistency

- **VERSION**, **package.json**, and `@version` in JS/CSS/HTML (html/index.html, js/*.js, css/page-editor.css, web-app/index.php, web-app/common.inc.php) are **1.1.0**.
- **README.md** was updated from 1.0.0 to 1.1.0 in this review.
- **debian/** and some web-app PHP (e.g. saveFile.php, logout.php, authGetFile.php) still have older version strings; update when cutting packages or if you standardize versions.

---

## Behaviour and logic

- **changePage / save on advance (nw-app):** When the user changes page, if there are unsaved changes the app calls `saveFile(loadFile)` with no confirm. Matches “automatically save on image advance” and is consistent.
- **restoreEditorUIOnLoad:** Correctly registered as first `onLoad` callback in page-editor.js; page-canvas calls it after `mode.current()`. nw-app comment correctly says not to call it again in app `onLoad`.
- **Drawer state:** Debounced `saveDrawerState` plus `saveDrawerStateNow()` on shortcuts and before unload is coherent; Create mode and other options persist across document loads.
- **Toasts:** `showFileExpectedToast` in nw-app is non-blocking and auto-dismisses; no duplicate handlers found.
- **Modal close:** Readme and shortcuts modals use `.close` and `#readme-content` in both html/index.html and web-app/index.php; CSS keeps the close button visible.

---

## Web vs desktop parity

- **Arrow keys (Left/Up, Right/Down):** Bound to prev/next page in **nw-app.js** only. They are **removed** in **web-app.js** (per branch diff). KEYBOARD-SHORTCUTS.md documents them without “desktop only”.
  - **Suggestion:** Either restore arrow key bindings in web-app.js for parity, or add a note in KEYBOARD-SHORTCUTS.md that arrow-key page navigation is desktop-only.

---

## Launcher and platform

- **bin/visual-page-editor:** Path cache (`~/.cache/visual-page-editor/nw-path`), absolute `APP_PATH`, and `--nwapp=$APP_PATH` on macOS are consistent; launch args use `NW_LAUNCH_ARGS` correctly.
- **DEBUG.md** matches current behaviour (startup, cache, ETIMEDOUT, “Cannot open app.nw”).

---

## Baseline type and UI

- **“Main” removed:** Code and UI consistently use only “default” and “margin”; CSS and JS no longer reference `baseline-main`. Legacy `main` in existing documents is still stripped by the regex in `setBaselineType` (e.g. page-canvas.js) where applicable.
- **Edit mode after create:** Default is unchecked in index.html, test-example.html, web-app/index.php; behaviour matches.

---

## TypeScript / tooling

- **tsconfig.json** (if present): `allowJs`, `noEmit: true`, `strict: false` are suitable for gradual adoption.
- **package.json:** `typecheck` and `ts` scripts and devDependencies are set up; run `npm run typecheck` when adding or editing TS/JS.

---

## Summary

- Automated review passes; only notable warning is `console.log` count.
- Version and docs (including README) are aligned to 1.1.0.
- Behaviour of save-on-advance, drawer state, toasts, and modals is consistent; no logic issues found.
- One optional improvement: clarify or restore arrow-key page navigation in the web app and/or KEYBOARD-SHORTCUTS.md.
