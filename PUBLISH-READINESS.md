# Publish readiness checklist (1.1.1)

Run this before tagging or releasing.

## Automated checks

| Step | Command | Expectation |
|------|---------|--------------|
| **Code review** | `./scripts/code-review.sh` | 0 errors (warnings acceptable) |
| **Lint** | `npm run lint` | No jshint errors |
| **Typecheck** | `npm run typecheck` | No TypeScript errors |
| **Platform tests** | `./scripts/test-platforms.sh` | Pass (Docker optional) |
| **Version sync** | `./scripts/sync-version.sh` | All files match `VERSION` |

## Version consistency

- **Source of truth:** `VERSION` = `1.1.1`
- **Must match:** `package.json` → `version`, `package-lock.json` (root and `""` package), all `@version` / `version = '...'` in JS/CSS/HTML/PHP/bin and README.

## Package audit

- `npm install` then `npm audit` — fix or document any high/critical vulnerabilities.
- Dependencies: `image-size`, `github-markdown-css` (runtime); `jshint`, `@types/jquery`, `typescript` (dev). No known fluke behaviour from these.

## Edge cases addressed (1.1.1)

- **Document snap to right:** Fixed in `snapImageToLeft()`; view keeps left edge at viewport left.
- **adjustSize first call:** Guarded so `prevW`/`prevH` undefined or zero do not produce NaN viewBox (resize before or without prior dimensions).
- **viewBoxLimits:** Zero `width`/`height` no longer cause Infinity in `factW`/`factH`.

## Manual / environment

- [ ] Launcher executable: `chmod +x bin/visual-page-editor scripts/*.sh`
- [ ] XSD present for offline use: `./scripts/fetch-xsd.sh` if needed
- [ ] README and DEBUG.md reflect current version and known issues
- [ ] LICENSE.md present (MIT)
- [ ] No secrets or local paths in committed files

## After publish

- Bump to next dev or patch as needed via `./scripts/bump-version.sh patch|minor|major`.
