# Comparison: Current (1.1.0) vs Version 5 in Downloads

**Version 5** = contents of `~/Downloads/visual-page-editor-master 5.zip` (extracted as `visual-page-editor-master`).  
**Current** = this repo at version 1.1.0 (with your recent edits).

---

## Summary

- **Version 5** is an older snapshot (version 1.0.0, different launcher and build scripts, some extra docs and modals).
- **Current** has newer launcher (auto-download NW.js, multi-platform), version 1.1.0, and editor behavior changes (backspace, center-on-selection bias, baseline UI, textedit focus).
- **Baseline types:** Both have only **Default** and **Margin** in the UI (no Main). Current adds mapping of legacy "main" → "default" when selecting a line.

---

## 1. Version & package

| Item | Version 5 (downloads) | Current |
|------|------------------------|--------|
| **package.json version** | 1.0.0 | 1.1.0 |
| **package.json main** | `./html/index.html#1` | `./html/index.html` |
| **Optional dependency** | — | `github-markdown-css` (with onerror fallback in HTML) |
| **VERSION file** | Not present | Present: 1.1.0 |

---

## 2. Editor behavior (js/svg-canvas.js, js/page-editor.js, html/index.html)

| Feature | Version 5 | Current |
|---------|-----------|--------|
| **Backspace in text** | Can delete element when focus in text field (Mousetrap + textedit had `class="mousetrap"`). | Backspace only edits text when focus is in input/textarea; `#textedit` no longer has `class="mousetrap"`. |
| **Ctrl/Cmd+Backspace** | Not clearly separated. | Explicit “always delete line/element” (forceDelete), even when editing text. |
| **Center on selection** | Pans so selection is at 50% horizontal (can end up under side menu). | Pans so selection is at 35% horizontal (and 50% vertical) so it stays visible left of the drawer. Same bias in `panZoomTo()`. |
| **Delete key** | No explicit “skip when in text field” check. | `handleDeletion()` skips when focus is in INPUT/TEXTAREA/SELECT/contentEditable (unless forceDelete). |
| **Baseline type UI** | Default + Margin only (no Main). | Default + Margin only; when a line has legacy “main”, UI shows Default (main → default mapping in page-editor.js). |
| **Readme modal CSS** | Hard dependency on github-markdown-css. | Optional: link has `onerror="this.remove()"`. |

---

## 3. HTML (html/index.html)

| Item | Version 5 | Current |
|------|-----------|--------|
| **Script loading** | Some scripts use `defer`; PDF.js loaded lazily when opening PDF. | No `defer` on tiff/turf/xmllint; pdfjs loaded up front. |
| **#textedit** | `class="mousetrap"` (shortcuts fire even when focused). | No `class="mousetrap"` so Backspace/Del are native in text box. |
| **Edit modes tooltip** | “Change via keyboard: ctrl[+shift]+, …” | “Cycle via keyboard: Mod+, / Mod+. … Mod = Ctrl (Win/Linux) or Cmd (macOS)” |
| **No-file modal** | Present: countdown + “No File Loaded” + OK. | Removed. |
| **Delete-confirm modal** | Present: “WARNING” + message + Cancel/Delete. | Removed. |

So in Version 5 there are two extra modals (no-file and delete-confirm) that are not in the current tree.

---

## 4. Launcher & build (bin/, build scripts)

| Item | Version 5 | Current |
|------|-----------|--------|
| **bin/visual-page-editor** | Shorter script; Linux arch detection (e.g. arm64); no auto-download of NW.js. | Longer script; `AUTO_DOWNLOAD_NWJS`; `NWJS_VERSION`; auto-download into ~/.nwjs (Linux/macOS) or ~/nwjs (Windows); interactive prompt or env-driven. |
| **bin/visual-page-editor.bat / .ps1** | Present but simpler. | Updated for Windows (e.g. finding nw.exe, paths, PowerShell fallback). |
| **build-macos.sh / build-deb.sh / build-windows.ps1** | Different (e.g. NW.js version, no auto-download). | Updated (e.g. NW.js 0.94, auto-download, ARM64). |
| **docker-run.sh, Dockerfile.desktop** | Different (e.g. no XSD fetch, no --disable-gpu). | Current has XSD fetch, GPU flags, docker-run.sh with DISPLAY/preflight. |

---

## 5. Docs and scripts (only in one tree)

| Only in Version 5 (downloads) | Only in Current |
|-------------------------------|------------------|
| CODE_REVIEW_DETAILED.md, CODE_REVIEW_REPORT.md | ARM64-PRIVILEGE-CHOICES.md |
| INSTALLATION_CHECK_REPORT.md | DEBUG.md |
| PERFORMANCE_ANALYSIS.md, PERFORMANCE_OPTIMIZATIONS.md | FEATURES-COMPARISON.md |
| STARTUP_BOTTLENECKS.md, test-startup-performance.sh | KEYBOARD-SHORTCUTS.md, REPO-BRANCHES-1-22.md, TESTING.md |
| build-macos (binary/script) | VERSION, scripts: bump-version.sh, fetch-xsd.sh, sync-version.sh, test-platforms.sh |
| scripts/check-install.sh | — |
| xsd/pageformat/ (submodule-style: githook, .gitignore, .gitmodules, old/, pagecontent_omnius.xsd, README, xs3p) | xsd/ has only pagecontent_omnius.xsd, pagecontent_searchink.xsd at top level |

---

## 6. Other differing files (same path, different content)

- **css/page-editor.css** – style differences (exact changes not listed here).
- **debian/rules** – packaging differences (e.g. bundled NW.js path, install paths).
- **.gitignore** – different ignores.
- **README.md** – current has Docker/Windows/auto-download and updated instructions.
- **js/nw-app.js, js/nw-winstate.js** – NW.js app and window state behavior.
- **js/page-canvas.js, js/page-editor.js** – baseline type handling, modals, config (e.g. main→default, only default/margin in UI).
- **js/web-app.js** – web-app behavior.
- **web-app/common.inc.php, index.php, start-server.sh** – small server/config differences.
- **xslt/svg2page.xslt** – export XSLT differences.
- **rpm/build-rpm.sh, scripts/code-review.sh** – build and review script updates.

---

## 7. Debian package layout

- **Current** has `debian/visual-page-editor/usr/lib/` (e.g. bundled nwjs) and `DEBIAN` control; **Version 5** does not have that `usr/lib` layout and differs in packaged files (e.g. README.md.gz, no test-example.html in v5 debian tree).

---

## What is “different” in practice

1. **Keyboard:** Backspace and Del are safe in the text box in current; Ctrl/Cmd+Backspace always deletes the line. Center-on-selection no longer hides the line under the menu.
2. **UI:** Baseline types are Default + Margin in both; current drops the Main option and maps main→default when loading/selecting.
3. **Modals:** Version 5 has “No File Loaded” and “Delete confirm” modals; current does not.
4. **Launcher:** Current can auto-download NW.js and supports more platforms and versions.
5. **Version:** 1.0.0 (v5) vs 1.1.0 (current), with extra docs and scripts in current.

If you want to **match Version 5** in a specific area (e.g. restore the delete-confirm or no-file modals, or revert a keyboard/center-on-selection change), say which and we can do a targeted diff or revert.

---

## Restorations applied (Version 5 behaviour and v5-only material)

### Baseline type behaviour (restored)

- **getBaselineType** (page-canvas.js): When the stored type is `main`, it now calls `setBaselineType(g[0], 'default')` (converts in DOM) and returns `'default'`, so the UI only ever sees default or margin. Matches Version 5.
- **setBaselineType** (page-canvas.js): Writes the type literally to `custom` (`type {type:default;}`, `type {type:margin;}`, or `type {type:main;}`). Removed `baselineTypeForXml` from the write path so internal storage matches v5.
- **New baseline creation** (page-canvas.js): Uses `baselineType` literally when setting `custom` for a newly created baseline, not `baselineTypeForXml(baselineType)`.
- **page-editor.js**: Removed the redundant `if (baselineType === 'main') baselineType = 'default'` before setting the radio, since `getBaselineType` now always returns default or margin.
- **CSS**: Kept `.baseline-main` (blue) for backward compatibility when loading old files; UI still offers only Default and Margin.
- **Load path** (svg-canvas.js): Unchanged: on load, any `main` in `custom` is revised to `default`, then classes are applied. Same as before and consistent with v5.

### Version-5–only files added to current tree

- **Docs**: `CODE_REVIEW_DETAILED.md`, `CODE_REVIEW_REPORT.md`, `INSTALLATION_CHECK_REPORT.md`, `PERFORMANCE_ANALYSIS.md`, `PERFORMANCE_OPTIMIZATIONS.md`, `STARTUP_BOTTLENECKS.md`
- **Scripts**: `test-startup-performance.sh`, `scripts/check-install.sh`
- **Build**: `build-macos/` (directory; contains `Visual Page Editor.app`; already in `.gitignore` as `build-macos/`)
- **XSD**: `xsd/pageformat/` (pageformat schema, old versions, README, githook; includes its own `.git`)

### Usability and debug checklist

- **Baseline types**: Only Default and Margin are selectable; legacy `main` is converted to default on read and on load, and is stored as default when set. No “Main” option in the UI.
- **Keyboard**: Backspace in the text box edits text; Ctrl/Cmd+Backspace deletes the line; Del deletes the element only when focus is not in a text field. Centre-on-selection uses a 35% horizontal bias so the line stays visible.
- **Compatibility**: Files with `type {type:main;}` open correctly, show as Default, and are updated to default when the line is selected or when the type is set. New baselines get the selected radio value (default or margin) stored literally in `custom`.
- **Export**: Baseline CSS classes are still stripped before export; `custom` (including `type {type:...}`) is exported as in v5. If a schema allows only default/margin, any remaining `main` would need normalisation in the export pipeline; currently the load and getBaselineType paths convert main to default so new edits don’t leave main in the DOM.
