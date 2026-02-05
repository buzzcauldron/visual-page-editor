# Differences: visual-page-editor (here) vs Desktop visual-page-editor-master

Comparison of **this repo** (`/home/sethj/visual-page-editor`) with **`/home/sethj/Desktop/visual-page-editor-master`**.

**Note:** The Desktop copy appears to be an older snapshot of visual-page-editor (e.g. version 1.0.0, `main: "./html/index.html#1"`). It may live inside another git repo (branch `rm-readme`). This doc summarizes what differs between the two directories.

---

## 1. Only in this repo (visual-page-editor here)

- **Docs:** `ARM64-PRIVILEGE-CHOICES.md`, `CODE_REVIEW.md`, `CODE_REVIEW_DETAILED.md`, `CODE_REVIEW_REPORT.md`, `COMPARE-VERSION-5.md`, `CRASH_FIX_MAC.md`, `DEBUG.md`, `FEATURES-COMPARISON.md`, `KEYBOARD-SHORTCUTS.md`, `INSTALLATION_CHECK_REPORT.md`, `PERFORMANCE_ANALYSIS.md`, `PERFORMANCE_OPTIMIZATIONS.md`, `REPO-BRANCHES-1-22.md`, `STARTUP_BOTTLENECKS.md`, `TESTING.md`, `TROUBLESHOOTING.md`, and the **`docs/`** folder (e.g. WORKFLOW-SPEED.md, MAIN-VS-MASTER-DIFF.md, DIFF-NW-PAGE-EDITOR-*.md, FEATURES-FROM-UPSTREAM-PROPOSAL.md).
- **Tooling / config:** `.jshintrc`, `VERSION`, **`scripts/`** (bump-version, code-review, fetch-xsd, sync-version, test-platforms, check-install), **`.github/`** (workflows/code-review.yml, FUNDING.yaml).
- **Build:** `build-macos.sh`, `build-windows.bat`, `build-windows.ps1`, `build-macos/` (output dir).
- **Bin:** `visual-page-editor.bat`, `visual-page-editor.ps1` (Windows launchers).
- **Packaging:** **`debian/source/`** (source format), **`rpm/README.md`**.
- **XSD:** **`xsd/pageformat/`** (submodule with pagecontent XSDs).
- **Other:** `test-startup-performance.sh`.

---

## 2. Only in Desktop visual-page-editor-master

- Nothing significant; the Desktop tree is a subset. It has no `docs/`, no `.github/`, no `scripts/`, no Windows/macOS build scripts, no `xsd/pageformat`, no `debian/source`, no `rpm/README.md`. Build artifacts (e.g. under `debian/`, `rpmbuild/`) may differ or be absent in one tree.

---

## 3. Files that differ (both have, different content)

| Area | Files |
|------|--------|
| **Root** | .gitignore, build-deb.sh, BUILD.md, docker-compose.yml, Dockerfile.desktop, docker-run.sh, githook-pre-commit, package.json, README.md |
| **bin/** | visual-page-editor |
| **css/** | page-editor.css |
| **debian/** | rules (and built files under debian/visual-page-editor) |
| **html/** | index.html, test-example.html |
| **js/** | nw-app.js, nw-winstate.js, page-canvas.js, page-editor.js, svg-canvas.js, web-app.js |
| **rpm/** | build-rpm.sh |
| **web-app/** | common.inc.php, index.php, start-server.sh |
| **xslt/** | svg2page.xslt |

(Compared with the Desktop copy, **here** typically has: version 1.1.0, no `#1` in main, editAfterCreate wiring, baseline default/margin, rAF throttling, mode panel cache, XSD fallback, optional intercept-stdout, arrow-key nav, and launcher/ARM64/Windows improvements.)

---

## 4. Summary

- **Desktop visual-page-editor-master** = older visual-page-editor layout (1.0.0-style, fewer docs and no scripts/workflows, no Windows/macOS builds, no xsd/pageformat, no debian/source or rpm README).
- **This repo** = current visual-page-editor with the above additions and the behavior/UX changes listed in the other diff docs (e.g. DIFF-NW-PAGE-EDITOR-MASTER.md, MAIN-VS-MASTER-DIFF.md).

So the Desktop folder is an **older snapshot** of the same project; there are no features present only there that are missing here.
