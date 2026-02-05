# Differences: visual-page-editor (here) vs nw-page-editor-packaged-master

Comparison of **this repo** (`/home/sethj/visual-page-editor`) with **`/home/sethj/Documents/nw-page-editor-packaged-master`**.

---

## 1. Project identity

| | visual-page-editor (here) | nw-page-editor-packaged-master |
|---|---------------------------|--------------------------------|
| **package.json name** | `visual-page-editor` | `nw-page-editor` |
| **Version** | 1.1.0 | 2025.09.23 |
| **Window title** | Visual Page Editor | nw-page-editor |
| **Window** | 1200×800, show: true, min 800×600 | 600×700, show: false |
| **Main** | `./html/index.html` | `./html/index.html#1` |
| **Author** | buzzcauldron | Mauricio Villegas |
| **Launcher** | `bin/visual-page-editor` (+ .bat, .ps1) | `bin/nw-page-editor` only |
| **RPM spec** | `rpm/visual-page-editor.spec` | `rpm/nw-page-editor.spec` |
| **Debian package** | visual-page-editor | nw-page-editor (in control/changelog) |

---

## 2. Only in visual-page-editor (here)

- **Bin:** `visual-page-editor.bat`, `visual-page-editor.ps1` (Windows).
- **Build:** `build-macos.sh`, `build-windows.bat`, `build-windows.ps1`, `Dockerfile.desktop`, `docker-compose.yml`, `docker-run.sh`, `build-macos/` (output dir).
- **Docs:** `ARM64-PRIVILEGE-CHOICES.md`, `CODE_REVIEW.md`, `CODE_REVIEW_DETAILED.md`, `CODE_REVIEW_REPORT.md`, `COMPARE-VERSION-5.md`, `CRASH_FIX_MAC.md`, `DEBUG.md`, `FEATURES-COMPARISON.md`, `KEYBOARD-SHORTCUTS.md`, `README-DOCKER.md`, `REPO-BRANCHES-1-22.md`, `TESTING.md`, `TROUBLESHOOTING.md`, `docs/` (e.g. WORKFLOW-SPEED.md, MAIN-VS-MASTER-DIFF.md).
- **Tooling:** `.jshintrc`, `VERSION`, `scripts/` (bump-version, code-review, fetch-xsd, sync-version, test-platforms), `.github/workflows/code-review.yml`.
- **Web:** `html/test-example.html`.
- **XSD:** `xsd/pageformat/` (submodule with pagecontent XSDs).
- **Debian:** `debian/visual-page-editor` (built package dir), `.debhelper`, `debhelper-build-stamp` (build artifacts).
- **RPM:** `rpmbuild/`, `visual-page-editor-1.0.0-1.fc43.x86_64.rpm` (if built).
- **Other:** `INSTALLATION_CHECK_REPORT.md`, `PERFORMANCE_ANALYSIS.md`, `PERFORMANCE_OPTIMIZATIONS.md`, `STARTUP_BOTTLENECKS.md`, `test-startup-performance.sh`.

---

## 3. Only in nw-page-editor-packaged-master

- **.github:** `FUNDING.yaml` (no code-review workflow).
- **Debian:** `debian/source/` (source format).
- **RPM:** `nw-page-editor.spec`, `nw-page-editor.spec.bak`, `rpm/README.md`.
- **Bin:** Only `nw-page-editor` (no .bat / .ps1).

---

## 4. Files that differ (summary)

| File | Difference (here vs packaged-master) |
|------|--------------------------------------|
| **.gitignore** | Here: more entries (nwjs-sdk-*, build-macos/, repo-*-log.txt, etc.). |
| **.dockerignore** | Different patterns. |
| **build-deb.sh** | Here: VERSION file / visual-page-editor naming. |
| **build-docker.sh** | Different image/context. |
| **BUILD.md** | Here: longer (VERSION, macOS/Windows, visual-page-editor). |
| **Dockerfile** | Here: likely different base/steps. |
| **githook-pre-commit** | Slight content differences. |
| **LICENSE.md** | Different copyright / project name. |
| **package.json** | See table in §1; here: github-markdown-css, jshint, scripts, repo URL. |
| **README.md** | Here: longer (Visual Page Editor, install, Docker, shortcuts, etc.). |
| **debian/** | changelog, compat, control, copyright, rules: visual-page-editor vs nw-page-editor naming and versions. |
| **rpm/build-rpm.sh** | Here: VERSION / visual-page-editor. |
| **css/page-editor.css** | Here: extra styles (e.g. baseline types, UI). |
| **html/index.html** | Here: different layout, readme modal, no #1 in main, possibly no mousetrap on textedit. |
| **js/nw-app.js** | Here: hash/startup handling, XSD loading, no intercept-stdout; different file-open flow. |
| **js/nw-winstate.js** | Here: NW.js 0.13+ API (no require('nw.gui')). |
| **js/page-canvas.js** | Here: editAfterCreate, polystripe min height, baseline default/margin, setPolystripe always, VERSION. |
| **js/page-editor.js** | Here: editAfterCreate checkbox wiring, mode panel cache, deferred updateSelectedInfo, baseline type UI, readme from multiple paths, more modes. |
| **js/svg-canvas.js** | Here: rAF for pan/onSelect and mousemove, handleDeletion text-field check, Mod+Backspace, dragpoint cleanup, setConfig/registerChange tweaks, no getVersion. |
| **js/web-app.js** | Here: small fixes / version. |
| **web-app/*.php, *.sh** | Here: visual-page-editor naming, version, apache2_http.conf differences. |
| **xslt/svg2page.xslt** | Here: likely baseline/Coords/TextEquiv and attribute handling. |

Rough diff size (lines) for key app files (packaged-master → here): **nw-app.js** ~120, **page-canvas.js** ~144, **page-editor.js** ~271, **svg-canvas.js** ~609, **html/index.html** ~38.

---

## 5. Functional differences (here vs packaged-master)

- **Baseline types:** Here has default/margin (and legacy “main”→default); packaged-master has older baseline handling.
- **Create flow:** Here has “Edit mode after create” option and skips setEditing when unchecked for faster second create; packaged-master always does setEditing after create.
- **Selection/UI:** Here defers updateSelectedInfo to rAF and caches mode panel refs; packaged-master is synchronous.
- **Mousemove:** Here throttles cursor/onMouseMove with rAF; packaged-master does not.
- **Deletion:** Here allows backspace in text fields and uses Mod+Backspace for line delete; packaged-master may differ.
- **Launchers:** Here has multi-arch (ARM64), optional auto-download, and Windows .bat/.ps1; packaged-master has single `nw-page-editor` script and PATH/mdfind only.
- **Packaging:** Here builds as “visual-page-editor” (Debian, RPM); packaged-master as “nw-page-editor”.
- **XSD:** Here has `xsd/pageformat` submodule; packaged-master has only the two xsd files in `xsd/`.

---

## 6. Quick reference

- **Same in both:** Core structure (examples/, plugins/, xslt except svg2page), most minified js, web-app structure.
- **Here adds:** Windows/macOS builds, Docker desktop flow, docs, scripts, baseline types, editAfterCreate, performance tweaks, VERSION, and the “visual-page-editor” name everywhere.
- **Packaged-master has:** Simpler launcher, FUNDING.yaml, rpm README/spec backup, and “nw-page-editor” naming.
