# main vs master: what main is “missing”

Comparison: **main** (current) vs **master**.  
Interpretation: **main is ahead**; this doc lists what **master** has that **main** doesn’t (i.e. what main would “lose” or “revert to” if you made main match master).

## Summary

- **Files only on master:** 0 (main has every file master has).
- **Files only on main (master lacks):** 22 (docs, scripts, workflows, VERSION, build-macos, build-windows, etc.).
- **Modified (both have, different content):** 27 files.

So **main is not missing any whole files**. The only differences are the **27 modified files**, where master has older/simpler content. Below is what **master** has that **main** doesn’t (the “+” side of `git diff main..master`), file by file.

---

## 1. Config / repo

| File | What master has (main doesn’t) |
|------|--------------------------------|
| **.gitignore** | Fewer ignores: no `nwjs-sdk-*/`, no `build-macos/`, no `repo-*-log.txt`, `repo-sync-*.txt`. |
| **BUILD.md** | Shorter: RPM spec named `nw-page-editor.spec`, no macOS/Windows build sections; “Both packages will” / CI note. |
| **README.md** | Older install (manual NW.js download, PATH), shorter shortcut list, “See original nw-page-editor documentation”, “Contributions welcome”, links to mauvilsa/nw-page-editor, pageformat, PRImA. |
| **package.json** | `"version": "1.0.0"`, `"main": "./html/index.html#1"`, `"show": false`, different deps (e.g. `image-size`). |
| **Dockerfile.desktop** | Simpler run: `/app/nwjs/nw /app "$@"`. |
| **docker-compose.yml** | `version: '3.8'`, `command: ["examples/*.xml"]`. |
| **docker-run.sh** | Build-if-missing, `xhost +local:docker`, `--network host`, older run pattern. |
| **githook-pre-commit** | Slightly different content (6 lines differ). |

---

## 2. Launchers (bin/)

| File | What master has (main doesn’t) |
|------|--------------------------------|
| **bin/visual-page-editor** | @version 1.0.0; simpler `readlinkf` (perl); older app path resolution; macOS uses `/Applications/nwjs.app` or `which nw`; no ARM64/multi-arch logic; `argv` with `--wd`, `-l`→`--list`, `--`→`++`; run `"$nw" "$nw_page_editor" "${argv[@]}"`; log to `/tmp/visual-page-editor.log`. |
| **bin/visual-page-editor.bat** | @version 1.0.0; alternate path `share\nw-page-editor`; NW.js lookup in Program Files, (x86), LOCALAPPDATA, PATH, nwjs.exe; validation of app path and nw; help; prefer PS1 then fallback to nw with `--wd` and `%*`; log file; note about `--list` and `++`. |
| **bin/visual-page-editor.ps1** | @version 1.0.0; `$BinDir`/`$ScriptDir`; `nw_page_editor` env and share path; common paths array; PATH/nwjs.exe fallback; validation; help; `$LogFile` in TEMP; `$argv` with `--wd` and `-l`/`--` handling; run `& $nw $allArgs`; no ARM64 logic. |

So on master: launchers are **simpler, 1.0.0, no ARM64, no auto-download**, and (Windows) prefer PS1 then fallback to bat.

---

## 3. Build / debian / rpm

| File | What master has (main doesn’t) |
|------|--------------------------------|
| **build-deb.sh** | `VERSION="1.0.0"` in script. |
| **debian/rules** | Patches launcher: bundled NW.js path, fallback to `which nw`; `nw-page-editor` path and fallback to `/usr/share/visual-page-editor`. |
| **rpm/build-rpm.sh** | `VERSION="1.0.0"`. |

---

## 4. CSS / HTML

| File | What master has (main doesn’t) |
|------|--------------------------------|
| **css/page-editor.css** | Version comment `@version $Version: 2020.11.16$`. |
| **html/index.html** | Version 1.0.0; `../node_modules/github-markdown-css/...`; textarea has `class="mousetrap"`; legend tooltip “Change via keyboard: ctrl[+shift]+, …”. |
| **html/test-example.html** | Same legend tooltip. |

---

## 5. JS (core app)

| File | What master has (main doesn’t) |
|------|--------------------------------|
| **js/nw-app.js** | Version 1.0.0; `global.pageNum` from hash; `global.pageWindows[...]=false`; hash-based window index; XSD load fail “schema is included as git submodule…”; `pagexml_xsd` serialized and unescaped; `pageCanvas.cfg.pagexmlns` from data; `intercept-stdout` require and unhook. |
| **js/nw-winstate.js** | `require('nw.gui')`; `gui.App.manifest.window.frame`; `gui.Screen.Init()` / `gui.Screen.screens`. |
| **js/page-canvas.js** | Version 2023.08.24; `getVersion()`; `setPolystripe` with `height<=0 \|\| offset` check and `polystripe` attribute; no `editAfterCreate` branch—always `setTimeout` 50ms then `setEditing` + `selectElem`. |
| **js/page-editor.js** | Version 2022.01.31; **synchronous** `updateSelectedInfo()` in onSelect; baseline info block without “TextLine”/baselineType; `$('#prop-modal .close').click(closePropModal)`; readme via `../README.md` and `marked.parse`; readme modal content/versions; **no** mode panel cache—fresh `$('#textMode input')` etc. every time; `$('#otherMode [list="other-regions"]').val(...)`; `$('#coordsRestriction')`, `$('#editModesFieldset input')`. |
| **js/svg-canvas.js** | Version 2021.02.22; `getVersion()`; `setConfig` with `hasOwnProperty`, `$.isArray`, `onSetConfig`; `registerChange` with `getElementPath`; **no mousemove rAF throttle**—direct `onMouseMove[k](point)`; **synchronous** pan and onSelect in `selectElem` (no rAF); `handleDeletion` without text-field check; Mousetrap mod+backspace calls `handleDeletion()`; `editModeOff` finds and removes `.dragpoint`, `.draggable`, `.dropzone`, `.no-pointer-events` (no early exit for no `.editing`). |
| **js/web-app.js** | Version 2022.09.13. |

So on master: **no** editAfterCreate option, **no** rAF for selection/pan or mousemove, **no** mode panel cache, **no** deferred updateSelectedInfo, older startup/XSD/intercept and version strings.

---

## 6. Web-app PHP

| File | What master has (main doesn’t) |
|------|--------------------------------|
| **web-app/common.inc.php** | Version 1.0.0. |
| **web-app/index.php** | Version 1.0.0. |
| **web-app/start-server.sh** | Version 1.0.0. |

---

## 7. XSLT

| File | What master has (main doesn’t) |
|------|--------------------------------|
| **xslt/svg2page.xslt** | Templates for `svg:g[@class='Page']`, `TextRegion`/…/`TextEquiv`, `svg:text[@class='Unicode']`, `svg:g[@class='TextEquiv']`, `svg:polygon[@class='Coords']` \| `svg:polyline[@class='Baseline']`; `xsl:element name="{@class}"`; conditional Coords and TextEquiv. |

(Main may have refactored or extended the same logic; this is the older structure.)

---

## 8. Files that exist only on main (master “missing”)

These are **not** things main is missing; they’re things **master** doesn’t have:

- `.github/workflows/code-review.yml`
- `.jshintrc`
- `ARM64-PRIVILEGE-CHOICES.md`, `CODE_REVIEW.md`, `CRASH_FIX_MAC.md`, `DEBUG.md`, `FEATURES-COMPARISON.md`, `KEYBOARD-SHORTCUTS.md`, `REPO-BRANCHES-1-22.md`, `TESTING.md`, `TROUBLESHOOTING.md`
- `VERSION`
- `build-macos.sh`, `build-windows.bat`, `build-windows.ps1`
- `docs/WORKFLOW-SPEED.md`
- `scripts/bump-version.sh`, `scripts/code-review.sh`, `scripts/fetch-xsd.sh`, `scripts/sync-version.sh`, `scripts/test-platforms.sh`
- `xsd/pageformat` (submodule)

---

## Bottom line

- **main is not missing any files**; it has more files and more code (launchers, builds, docs, workflows).
- **What “main is missing”** is only the **older/simpler behavior and text** from the 27 modified files above (older versions, no ARM64, no editAfterCreate, no rAF throttling, no mode cache, synchronous onSelect/updateSelectedInfo, older XSD/startup, etc.).  
- If you want main to behave and document like master, you’d **revert** those 27 files (or selected parts) toward master; there is nothing to “add from master” that main doesn’t already have in some form.
