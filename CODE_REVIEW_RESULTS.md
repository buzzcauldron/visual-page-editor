# Code Review Results

**Date:** 2025-01-28  
**Scope:** visual-page-editor (main app + recent changes)

---

## Automated Review

| Check | Result |
|-------|--------|
| **Code review script** (`./scripts/code-review.sh`) | ✓ Passed (0 errors) |
| **HTML** (index, test-example) | ✓ Basic checks passed |
| **Shell scripts** | ✓ All validated |
| **Batch / PowerShell** | ✓ Basic checks (pwsh/php/xmlstarlet optional, skipped if missing) |
| **Required files** | ✓ package.json, README.md, LICENSE.md, html/index.html |
| **IDE linter** (js/page-editor.js, js/nw-app.js, css) | ✓ No errors |

**Warnings (non-blocking):**

- **65 `console.log` statements** in JS — consider removing or gating behind a debug flag for production.
- **jshint** — not run in this environment (npm/npx not in PATH). Run locally: `npm run lint`.
- **xmlstarlet / php / pwsh** — skipped when tools not installed; optional for full review.

---

## Manual Review Notes

### Strengths

- **Structure:** Clear separation — `page-editor.js` (UI/config), `nw-app.js` (NW.js/file), `page-canvas.js` / `svg-canvas.js` (canvas logic). Launcher in `bin/`, scripts in `scripts/`.
- **Config:** Single `handleWarning` / `onLoad` / `registerChange` flow; `registerChangeEnabled` used to avoid spurious dirty state on load.
- **UX:** File-expected toast (3s auto-dismiss), deferred version check, and save-on-advance keep startup and workflow smooth.
- **Security:** `eval()` only in vendor (xmllint, minified); code-review script excludes them.

### Recent Change Areas (quick check)

| Area | Notes |
|------|--------|
| **Toast (`showFileExpectedToast`)** | Uses `.text(msg)` (XSS-safe). Timeouts 3000ms + 300ms; toast removed from DOM. No leak. |
| **Drawer / baseline type** | `loadDrawerState()` on `onLoad`; baseline type applied to selection without confirm. Logic consistent. |
| **Save on advance** | `changePage` always saves when `hasChanged()` then loads; no prompt. Matches “auto-save on image advance” when autosave off. |
| **Drawer close (×)** | 40×30px, flexbox-centered; matches hamburger size. |
| **CSS** | `.file-expected-toast` hidden in `@media print`. |

### Suggestions

1. **console.log:** Add a small debug helper (e.g. `debugLog()` that no-ops when `!DEBUG`) and replace or wrap `console.log` in app code so production builds stay quiet.
2. **jshint:** Run `npm run lint` (or `npx jshint js/*.js --exclude js/*.min.js`) in CI and before release to catch style/errors.
3. **Toast stacking:** If multiple toasts can show (e.g. rapid file-open failures), consider a single toast element and queue or replace message instead of appending many divs.

---

## Session review (recent changes)

**Scope:** nw-app.js (file open, XSD), page-editor.js (safeStylesheet), svg-canvas.js (mode off / disablers).

### nw-app.js

| Change | Review |
|--------|--------|
| **Last-open file at startup** | We now check existence of the file we actually load (`fileList[fileNum-1]`), not just the first. Bounds on `fileNum` are correct; `idx` defaults to 0 if `fileNum` missing or out of range. ✓ |
| **ENOENT in loadFile** | On `err.code === 'ENOENT'` we call `finishFileLoad()`, show toast, `console.warn`, and return without calling `handleError`. Other errors still go to `handleError`. ✓ |
| **XSD load failure** | `onXsdFail` no longer calls `pageCanvas.throwError`. Uses `showFileExpectedToast` + `console.warn` so startup is not blocked when submodule is missing. ✓ |
| **validatePageXml** | After `loadPageXmlXsd(false)` we check `if ( ! pagexml_xsd )` and show toast and return. With `async: false`, the sync load completes before we read `pagexml_xsd`. ✓ |

**Minor:** If the user clicks "Validate" very soon after startup, the initial async XSD load may still be in flight; we then run a second sync load in `validatePageXml`. Acceptable; worst case we show the same toast. Optional improvement: expose a small “XSD ready” promise and have Validate wait for it with a short timeout.

### page-editor.js

| Change | Review |
|--------|--------|
| **safeStylesheet(selector, prop, value)** | try/catch around `$.stylesheet(selector).css(prop, value)`; on failure we infer a fallback selector from the string (e.g. `page_container` → `#xpg`) and apply the same prop with `$(fallback).css(prop, value)`. ✓ |
| **Fallback mapping** | Heuristic (indexOf on selector string) is brittle if selector format changes but matches current usage. Only used for `#page_styles { ... }`-style selectors. ✓ |
| **adjustSize** | Uses `safeStylesheet` for `.page_container` and `#cursor`; calls `pageCanvas.adjustViewBox` only if `typeof pageCanvas.adjustViewBox === 'function'`. ✓ |

**Suggestion:** If more selectors are added, consider a small map (selector fragment → fallback) instead of repeated indexOf.

### svg-canvas.js

| Change | Review |
|--------|--------|
| **editModeOff** | No longer calls `finishDrawing()` on teardown. In-progress draw is cancelled by the mode’s disabler (delpoly/delrect). ✓ |
| **setDrawPoly / setDrawRect disablers** | Each disabler: try { if (elem) delpoly/delrect(elem); elem = false } catch { console.warn; elem = false }; then unbind and clear finishDrawing. Ensures in-progress element is removed on mode switch and errors don’t leave state half-cleaned. ✓ |
| **editModeOff disabler loop** | Each disabler run in try/catch; on throw we log and continue, then clear `disablers`. Prevents one bad disabler from blocking teardown. ✓ |

**Note:** `elem` in the disabler is the closure variable from setDrawPoly/setDrawRect; it’s the correct reference for the in-progress shape. No leak after remove.

### Summary

- **Correctness:** Last-open check, ENOENT path, XSD non-fatal, and create-line cancel behavior are consistent and correct.
- **Robustness:** Stylesheet fallback and disabler try/catch improve resilience to missing CSS and mode-teardown errors.
- **UX:** Missing file and missing XSD no longer block with alerts; toasts and console messages are used instead.

---

## How to Run Review Again

```bash
# Full automated review
./scripts/code-review.sh
# or
npm run review

# JS only (requires Node/npm)
npm run lint

# Platform tests (launcher, Docker, version)
./scripts/test-platforms.sh
```

---

*Generated for the current codebase; re-run after significant changes.*
