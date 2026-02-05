# Merge blocked by Debian build output

The merge fails because root-owned build output under `debian/` is in the way. The **build scripts are kept** (e.g. `build-deb.sh`, `debian/rules`, `debian/control`); only the **build output** is removed so the merge can run.

**Run once (in a terminal; sudo is only used to remove the root-owned build dirs):**

```bash
cd /home/sethj/visual-page-editor
./scripts/fix-merge-permissions.sh
```

The script removes `debian/visual-page-editor`, `debian/.debhelper`, and `debian/debhelper-build-stamp`, then runs `git pull --no-rebase origin main`. Build scripts stay; you can build a new package anytime with `./build-deb.sh`.

After a successful merge you can delete this file.
