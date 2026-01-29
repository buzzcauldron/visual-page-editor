# Debug & error checks

## Quick checks

| Check | Command | Notes |
|-------|--------|------|
| **Code review** | `./scripts/code-review.sh` | JS (jshint if installed), HTML, shell, batch, PHP, XSLT/XSD (xmlstarlet), required files |
| **Lint JS** | `npm run lint` or `npx jshint js/*.js --exclude js/*.min.js` | Needs Node/npm |
| **Platform tests** | `./scripts/test-platforms.sh` | macOS launcher, Docker, arm64 features, version, installers |
| **Version sync** | `./scripts/sync-version.sh` | Syncs `VERSION` into package.json and all @version strings |

## Current status (after last debug run)

- **Errors:** 0  
- **Warnings:** 1 — 64 `console.log` statements in app JS (consider removing for production)
- **Platform tests:** 16/16 passed (macOS launcher, Docker, arm64 features, version 1.1.0)
- **IDE linter:** No errors in js/html/css
- **eval():** Only in vendor (xmllint.js, *.min.js); excluded from review

## Optional tools (improve review coverage)

- **jshint** — `npm install` then `npm run lint`
- **xmlstarlet** — validate XSLT/XSD
- **php** — validate web-app PHP
- **pwsh / powershell** — validate .ps1 on Windows

## Common issues

- **XSD not found:** Run `./scripts/fetch-xsd.sh` or `git submodule update --init`
- **Launcher not executable:** `chmod +x bin/visual-page-editor scripts/*.sh`
