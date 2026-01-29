# Where the 1/22-era changes live

The "significant changes around 1/22 and just before" are in **this same repo** (buzzcauldron/visual-page-editor) but on **remote branches**, not on `main`.

## Repos on this machine

| Location | Repo | Latest commits |
|----------|------|------------------|
| **Documents/visual-page-editor-master** | buzzcauldron/visual-page-editor (this workspace) | main @ 2026-01-08 |
| **~/nw-page-editor** | nw-page-editor (original upstream?) | main @ 2026-01-02 (RPM/DEB), then 2025-09-23 |
| **~/nw-page-editor-1** | same as above | same history |
| **Documents - Seth's MacBook Pro/visual-page-editor-master** | (path not accessible from here) | — |

None of these have commits dated exactly **2026-01-22**. The work you remember is the **2026-01-16** and **2026-01-24** work on the **remote** of this repo.

---

## Branches with significant changes (around 1/22 and just before)

All from **origin** of this repo (`git@github.com:buzzcauldron/visual-page-editor.git`).

### 1. **origin/arm64-support** (2026-01-16)

- ARM64 / Apple Silicon support (build-macos.sh, NW.js)
- Automatic NW.js download
- XSD loading fallback; intercept-stdout optional
- Preserve TextLine element syntax in XML export
- Baseline type CSS (svg-canvas, Debian package)
- Drawer visibility: restore toggle
- Baseline type handling (persist, default to main, etc.)

### 2. **origin/baseline-type-main-margin** (2026-01-16)

- Baseline type: **main** vs **margin**
- Refactor and bug fixes (includes 2026-01-07 fixes)

### 3. **origin/cursor-import-20260124-031256** (2026-01-24)

- Windows launcher: `bin/visual-page-editor.bat`, `bin/visual-page-editor.ps1`
- README updates

---

## How to get those changes into this repo

**Option A – use the branch that has the editor + ARM64/1/16 work**

```bash
cd /Users/halxiii/Documents/visual-page-editor-master
git checkout -b from-arm64 origin/arm64-support
# You’re now on the 1/16 state with baseline types, drawer fix, XSD, etc.
```

**Option B – merge into main**

```bash
git checkout main
git merge origin/arm64-support -m "Merge 1/16 arm64 and baseline/drawer changes"
# Resolve conflicts if any, then commit.
```

**Option C – also include the 1/24 Windows launcher**

```bash
git merge origin/cursor-import-20260124-031256 -m "Merge Windows launcher (1/24)"
```

---

## Summary

- The repo with the name (or similar) and **significant changes around 1/22 and just before** is **this repo**, on **origin/arm64-support** and **origin/baseline-type-main-margin** (1/16), and **origin/cursor-import-20260124-031256** (1/24).
- Your local **main** is still at 2026-01-08 and never had those branches merged.
- To get that “last working” feature set, check out or merge **origin/arm64-support** (and optionally the 1/24 branch) as above.
