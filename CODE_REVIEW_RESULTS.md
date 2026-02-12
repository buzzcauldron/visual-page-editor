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

## Careful code review

**Scope:** nw-winstate.js (window clamp), nw-app.js, page-editor.js, svg-canvas.js. Edge cases, robustness, and consistency.

### nw-winstate.js — Window position clamping

| Item | Finding | Action |
|------|--------|--------|
| **Union bounds** | Union of screen bounds is computed correctly; clamp keeps window inside union so it can’t open “above” the screen. | ✓ |
| **Window larger than union** | When `w > union.width` or `h > union.height`, `clampX`/`clampY` become `union.x`/`union.y` (Math.min with value &lt; union edge forces Math.max to union edge). Window then extends off right/bottom but top-left is on-screen. | ✓ Acceptable |
| **Invalid winState dimensions** | If `winState.width`/`height` are missing, NaN, or ≤ 0 (e.g. corrupted localStorage), `resizeTo(w, h)` could misbehave. | **Fixed:** `w`/`h` now use `Math.max(1, Number(winState.width) \|\| 800)` and same for height so we always pass sane values. |
| **screens.length === 0** | Union stays `{x:0,y:0,width:0,height:0}`; clamp yields (0,0); resize still uses w,h. | ✓ Safe |

### svg-canvas.js — editModeOff and callbacks

| Item | Finding | Action |
|------|--------|--------|
| **onModeOff callbacks** | Loop `for (n = 0; n < onModeOff.length; n++) onModeOff[n]();` had no try/catch. A throwing callback could leave mode half-torn-down (disablers already run, interactables cleared). | **Fixed:** Each `onModeOff[n]()` is now inside try/catch; errors are logged and the loop continues. |
| **Variable `n` reuse** | `n` is used in interactables loop, then disablers loop, then onModeOff loop. Correct as long as each loop sets `n`; no leak. | ✓ |

### nw-app.js — File and XSD

| Item | Finding | Action |
|------|--------|--------|
| **lastOpen.fileList[idx]** | `idx` is 0 when `fileNum` is missing or out of range; we then check `existsSync(lastOpen.fileList[0])`. If `fileList` is empty we already required `lastOpen.fileList.length > 0`, so idx is always valid. | ✓ |
| **loadFile ENOENT** | Only `err.code === 'ENOENT'` gets toast path; other codes (EACCES, EISDIR, etc.) still go to `handleError`. Intentional. | ✓ |
| **validatePageXml sync load** | `loadPageXmlXsd(false)` runs the full chain synchronously; when it returns, `pagexml_xsd` is set or all paths failed. So the `if (! pagexml_xsd)` check is correct. | ✓ |
| **XSD message in toast** | User-visible string includes path and “Run git submodule update --init…”. No user input; safe to show. | ✓ |

### page-editor.js — safeStylesheet

| Item | Finding | Action |
|------|--------|--------|
| **Fallback order** | Checks: page_container → #cursor → (#textedit && #textinfo) → #textinfo → #textedit. Selectors like `#textedit, #textinfo` match the third branch; single #textinfo/#textedit match the right branch. | ✓ |
| **Unknown selector** | If selector doesn’t match any branch, `fallback` is null and we only log; no inline style applied. Preferable to guessing. | ✓ |

### Summary of fixes applied in this review

1. **nw-winstate.js:** Guard `winState.width`/`height` with `Math.max(1, Number(winState.width) || 800)` (and same for height) before clamp and `resizeTo`, so corrupted or missing dimensions don’t cause bad resize.
2. **svg-canvas.js:** Wrap each `onModeOff[n]()` in try/catch so a throwing callback doesn’t abort mode teardown.

### Remaining suggestions (non-blocking)

- **nw-winstate:** Consider falling back to `win.setPosition('center')` when union width/height is 0 (e.g. no screens or API quirk).
- **Validate + XSD:** Optional: when XSD is loading asynchronously at startup, have Validate wait briefly for that load before starting a sync load, to avoid duplicate work.

---

## Optimization and functionality review

**Date:** 2026-01-24  
**Scope:** svg-canvas.js (delete/canvas focus), page-editor.js (safeStylesheet, adjustSize), editables cache correctness.

### Optimizations applied

| File | Change | Rationale |
|------|--------|-----------|
| **svg-canvas.js** | `invalidateEditablesCache()` after successful delete | Cache was stale after deleting an element; Tab cycle and `getSortedEditables()` could reference removed nodes. |
| **svg-canvas.js** | `canvasClick(e)` helper; `$(svgRoot).click(canvasClick)` in both restoreState and setCanvas | Single place for “focus container + removeEditings”; avoids duplicated logic. |
| **page-editor.js** | `stylesheetFallbacks` as ordered array of [fragment, fallback] | Deterministic fallback (e.g. `#textedit, #textinfo` matched before `#textedit`); easier to add selectors. |
| **page-editor.js** | `adjustSize()`: cache `hideTextEdit` and `texteditHeight` in one pass | Fewer DOM/jQuery queries per resize; same behavior. |

### Functionality verified

| Area | Check |
|------|--------|
| **Backspace/Delete** | Canvas is focusable (`tabindex="-1"`); focused on SVG click and on select; handleDeletion consumes key when no selection (no browser back). |
| **Editables cache** | Invalidated on: SVG load, history restore, mode change, and **after delete**. Tab cycle and sorted editables stay correct. |
| **safeStylesheet fallback** | Order of entries ensures combined selectors (e.g. `#textedit, #textinfo`) get the correct fallback before single-id matches. |

### Summary

- **Correctness:** Delete path invalidates editables cache; canvas focus ensures Backspace/Delete are handled when working on the page.
- **Maintainability:** Canvas click and stylesheet fallbacks are centralized; resize avoids redundant lookups.

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
