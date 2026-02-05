# Semantic versioning

This project follows [Semantic Versioning 2.0.0](https://semver.org/):

- **MAJOR** (x.0.0): Incompatible API or behavior changes.
- **MINOR** (0.x.0): New features, backwards compatible.
- **PATCH** (0.0.x): Bug fixes and backwards-compatible fixes.

**Source of truth:** `VERSION` (one line, e.g. `1.1.1`).

**Sync:** Run `./scripts/sync-version.sh` to propagate to `package.json` and all app-facing files, or use `./scripts/bump-version.sh patch|minor|major` to bump and sync in one step.

## Review (current renumbering)

- **1.1.0 → 1.1.1 (applied):** Document “snap to right” bug fix only → **PATCH** bump. No new features, no breaking changes.
- Future: new features → MINOR; breaking changes → MAJOR.
