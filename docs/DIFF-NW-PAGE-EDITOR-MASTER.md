# Differences: visual-page-editor (here) vs nw-page-editor-master

Comparison of **this repo** (`/home/sethj/visual-page-editor`) with **`/home/sethj/Documents/nw-page-editor-master`**.

---

## 1. Project identity

| | visual-page-editor (here) | nw-page-editor-master |
|---|---------------------------|------------------------|
| **package.json name** | `visual-page-editor` | `nw-page-editor` |
| **Version** | 1.1.0 | 2025.09.23 |
| **Window title** | Visual Page Editor | nw-page-editor |
| **Window** | 1200×800, show: true, min 800×600 | 600×700, show: false |
| **Main** | `./html/index.html` | `./html/index.html#1` |
| **Author** | buzzcauldron | Mauricio Villegas |
| **Launcher** | `bin/visual-page-editor` (+ .bat, .ps1) | `bin/nw-page-editor` only |
| **RPM spec** | `rpm/visual-page-editor.spec` | `rpm/nw-page-editor.spec` |
| **Debian** | visual-page-editor | nw-page-editor |

---

## 2. Only in visual-page-editor (here)

- **Bin:** `visual-page-editor.bat`, `visual-page-editor.ps1` (Windows).
- **Build:** `build-macos.sh`, `build-windows.bat`, `build-windows.ps1`, `Dockerfile.desktop`, `docker-compose.yml`, `docker-run.sh`, `build-macos/`.
- **Docs:** `ARM64-PRIVILEGE-CHOICES.md`, `CODE_REVIEW*.md`, `COMPARE-VERSION-5.md`, `CRASH_FIX_MAC.md`, `DEBUG.md`, `FEATURES-COMPARISON.md`, `KEYBOARD-SHORTCUTS.md`, `README-DOCKER.md`, `REPO-BRANCHES-1-22.md`, `TESTING.md`, `TROUBLESHOOTING.md`, `docs/`, `INSTALLATION_CHECK_REPORT.md`, `PERFORMANCE_*.md`, `STARTUP_BOTTLENECKS.md`, `test-startup-performance.sh`.
- **Tooling:** `.jshintrc`, `VERSION`, `scripts/`, `.github/workflows/code-review.yml`.
- **Web:** `html/test-example.html`.
- **XSD:** `xsd/pageformat/` (submodule: pagecontent XSDs, old/, README, etc.).
- **Debian:** `debian/visual-page-editor`, `.debhelper`, `debhelper-build-stamp`.
- **RPM:** `rpmbuild/`, `visual-page-editor-1.0.0-1.fc43.x86_64.rpm` (if built).

---

## 3. Only in nw-page-editor-master

- **.github:** `FUNDING.yaml` (no code-review workflow).
- **Debian:** `debian/source/`.
- **RPM:** `nw-page-editor.spec`, `nw-page-editor.spec.bak`, `rpm/README.md`.
- **Bin:** Only `nw-page-editor` (no .bat / .ps1).

---

## 4. Files that differ

Same set as vs nw-page-editor-packaged-master:

| Area | Files |
|------|--------|
| **Root** | .gitignore, .dockerignore, build-deb.sh, build-docker.sh, BUILD.md, Dockerfile, githook-pre-commit, LICENSE.md, package.json, README.md |
| **debian/** | changelog, compat, control, copyright, rules |
| **rpm/** | build-rpm.sh |
| **css/** | page-editor.css |
| **html/** | index.html |
| **js/** | nw-app.js, nw-winstate.js, page-canvas.js, page-editor.js, svg-canvas.js, web-app.js |
| **web-app/** | apache2_http.conf, common.inc.php, git-commit-daemon.sh, index.php, saveFile.php, start-server.sh |
| **xslt/** | svg2page.xslt |

**Behavior (here vs nw-page-editor-master):** Same as in [DIFF-NW-PAGE-EDITOR-PACKAGED-MASTER.md](DIFF-NW-PAGE-EDITOR-PACKAGED-MASTER.md): baseline types (default/margin), “Edit mode after create”, rAF throttling, mode panel cache, backspace/Mod+Backspace, launcher ARM64 + Windows scripts, VERSION, and visual-page-editor naming everywhere.

---

## 5. Note

**nw-page-editor-master** and **nw-page-editor-packaged-master** are effectively the same upstream layout (same package.json, same `bin/nw-page-editor`, same rpm/debian naming). This comparison matches that layout; the only difference between the two directories may be minor file-level or version details.
