# Features from upstream (nw-page-editor) – review and proposed updates

Comparison of **visual-page-editor** with **nw-page-editor-master** and **nw-page-editor-packaged-master** to identify any worthwhile upstream features to adopt.

---

## 1. What we already have or do better

| Area | Upstream | visual-page-editor |
|------|----------|--------------------|
| **XSD loading** | Single path, throws on fail | Fallback: submodule path → GitHub URL; clearer error. |
| **intercept-stdout** | Required (validation) | Optional try/catch; no hard dependency. |
| **global.pageNum** | `parseInt(hash)` (no radix/NaN check) | `parseInt(..., 10)` and NaN → 1. |
| **Arrow keys** | Left/Up = prev, Right/Down = next | Same (we have it). |
| **checkForUpdates** | Every 8 days, mauvilsa URL | Same logic, buzzcauldron/visual-page-editor URL. |
| **Save backup** | Writes `loadedFile~` before save | Same. |
| **Readme modal** | Single `../README.md` | Multiple paths (../README.md, ./README.md, README.md). |
| **Edit modes tooltip** | "Change via keyboard: ctrl[+shift]+..." | "Cycle via keyboard: Mod+, / Mod+. (element type / tool)...". |
| **Keyboard shortcuts** | mod+e, mod+h, mod+f, mod+enter, mod+,/., etc. | Same plus Mod+Backspace, more zoom/pan, doc in KEYBOARD-SHORTCUTS.md. |
| **Baseline / create** | No baseline types, always setEditing after create | Baseline default/margin, "Edit mode after create" option, polystripe min height. |
| **Selection / perf** | Synchronous onSelect, no mode cache | rAF for pan/onSelect, deferred updateSelectedInfo, mode panel cache, mousemove throttle. |

No need to revert or copy these; we already match or improve on them.

---

## 2. Worth adopting from upstream

### 2.1 RPM README (adopt)

**Upstream:** `rpm/README.md` – short instructions for building and installing the RPM.

**Proposal:** Add `rpm/README.md` for visual-page-editor (same structure, our package name and spec). Helps anyone building from source.

**Status:** Added in this change set.

---

### 2.2 Debian source format (adopt)

**Upstream:** `debian/source/format` with `3.0 (quilt)` for Debian source packages.

**Proposal:** Add `debian/source/format` so `dpkg-buildpackage -S` and other source-package workflows work as expected.

**Status:** Added in this change set.

---

### 2.3 Credit upstream / FUNDING (adopt)

**Upstream:** `.github/FUNDING.yaml` with `github: mauvilsa`.

**Proposal:** Add `.github/FUNDING.yaml` crediting the original author (e.g. `github: mauvilsa`) so the fork clearly attributes the original project. Optional but good practice.

**Status:** Added in this change set.

---

## 3. Not worth adopting (or already decided)

| Item | Reason |
|------|--------|
| **textedit `class="mousetrap"`** | Removed on purpose so Backspace edits text; Mod+Backspace deletes element. Keeping as-is. |
| **Simpler launcher (single script)** | We want ARM64, Windows .bat/.ps1, and optional auto-download. No change. |
| **package.json `"main": "...#1"`** | We use `./html/index.html` and handle hash in code. No need to match. |
| **package.json `"show": false`** | We prefer window visible by default (show: true). No change. |
| **Single README path for readme modal** | Our multi-path readme is more robust. No change. |
| **versionCheck.lastVersion on first run** | Current logic (no alert on first run, then store version) is correct. No change. |

---

## 4. Optional follow-ups (not in this set)

- **PACKAGING.md** – Replace remaining "nw-page-editor" references with "visual-page-editor" and update paths/names for consistency.
- **rpm/build-rpm.sh** – If you want to match upstream’s “run from rpm/” style, document that the script can be run as `cd rpm && ./build-rpm.sh` (if it already supports that).

---

## 5. Summary

- **Already in good shape:** XSD loading, optional intercept-stdout, version/page/window handling, shortcuts, readme, backup-on-save, and all recent UX/performance work (baseline types, editAfterCreate, rAF, mode cache).
- **Adopted in this set:** `rpm/README.md`, `debian/source/format`, `.github/FUNDING.yaml` (credit upstream).
- **Explicitly not adopted:** Reverting textedit/launcher/package.json/readme behavior; no code changes to nw-app or page-editor logic from upstream.
