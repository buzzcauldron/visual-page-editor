# Optimization and language choices

## Current stack

- **Runtime:** NW.js (Chromium + Node.js)
- **UI:** HTML, CSS, jQuery, SVG, interact.js, Mousetrap
- **Logic:** Plain JavaScript (ES6), ~15+ JS files, XSLT for Page XML ↔ SVG

The app is a **visual editor** that runs in a browser engine: DOM, SVG, and event-driven UI are central. Any alternative has to support that.

---

## Is there a better language?

### 1. **TypeScript (best low-friction upgrade)**

- **Same runtime:** Still JavaScript in the browser/NW.js.
- **Benefits:** Types catch bugs at edit time, improve refactoring and IDE support, and document APIs. No change to deployment or performance.
- **Effort:** Add `tsconfig.json`, rename `.js` → `.ts` gradually (or use `allowJs` and migrate file by file). Keep jQuery and existing libs.
- **Verdict:** Best “better language” for this codebase: safer and easier to maintain without a rewrite.

### 2. **Tauri (Rust backend, same web frontend)**

- **Change:** Replace NW.js with [Tauri](https://tauri.app/): Rust core, existing HTML/JS/CSS (or TS) in a webview.
- **Benefits:** Smaller binaries, no Node in the renderer (stronger security), system APIs via Rust. You keep the current editor UI and logic in JS/TS.
- **Effort:** New project layout and build; bridge for file I/O and any Node-only code (e.g. `image-size`). No need to rewrite the editor in another language.
- **Verdict:** Good if you want a different desktop stack; not required for “a better language” for the editor itself.

### 3. **Full rewrite in Rust / Swift / etc.**

- **Reality:** The heavy lifting is DOM/SVG and interaction (drag, zoom, modes). A native UI (e.g. SwiftUI, Qt, GTK) means reimplementing all of that.
- **Verdict:** Only worth it for specific targets (e.g. iOS app) or if you are deliberately leaving the web stack; not an optimization for the current desktop app.

---

## Code optimizations (within current JS)

Already applied in this repo:

- **Drawer state:** Debounced `saveDrawerState` (120 ms), flush on `beforeunload`, immediate save on mode shortcuts (c/b).
- **Load path:** One fewer UI restore per document load (app `onLoad` no longer calls `restoreEditorUIOnLoad`), re-apply drawer state once after `mode.current()` in page-canvas.
- **Selectors:** Single `$('#drawer')` per save/load and `.find()` instead of repeated `$('#drawer label')`.

Further improvements without changing language:

- **Lazy init:** Defer non-critical setup (e.g. version check already deferred by 3 s; XSD/timeouts in place).
- **Event delegation:** For large SVG trees, bind fewer listeners (e.g. one per container) and use event target.
- **Virtual scrolling:** Only if you have huge lists in the UI (e.g. thousands of elements in the drawer); not needed for typical Page XML sizes.
- **Worker:** Move heavy XSLT or geometry to a Web Worker so the UI thread stays responsive; measure first to see if it’s a bottleneck.

---

## Recommendation

- **For “optimize code”:** Stay in JavaScript (or move to TypeScript) and apply the patterns above; the main wins are already in place (debounce, load flow, selectors).
- **For “a better language”:** Use **TypeScript** for the same program with better safety and tooling; consider **Tauri** only if you want to move off NW.js and are willing to change the desktop shell.
