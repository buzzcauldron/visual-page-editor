#!/usr/bin/env bash
# Bump VERSION and sync to all app-facing files.
# Usage:
#   ./scripts/bump-version.sh 1.2.0       # set exact version
#   ./scripts/bump-version.sh patch       # 1.1.0 -> 1.1.1
#   ./scripts/bump-version.sh minor       # 1.1.0 -> 1.2.0
#   ./scripts/bump-version.sh major       # 1.1.0 -> 2.0.0
# Run from repo root.

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION_FILE="$ROOT/VERSION"

current() {
  [ -f "$VERSION_FILE" ] && tr -d '\n\r' < "$VERSION_FILE" || echo "0.0.0"
}

bump_patch() {
  local v; v="$(current)"
  local a b c
  IFS=. read -r a b c <<< "$v"
  echo "$a.$b.$((c + 1))"
}

bump_minor() {
  local v; v="$(current)"
  local a b c
  IFS=. read -r a b c <<< "$v"
  echo "$a.$((b + 1)).0"
}

bump_major() {
  local v; v="$(current)"
  local a b c
  IFS=. read -r a b c <<< "$v"
  echo "$((a + 1)).0.0"
}

if [ $# -eq 0 ]; then
  echo "Usage: $0 <version> | patch | minor | major" >&2
  echo "  version: e.g. 1.2.0" >&2
  echo "  patch/minor/major: bump from current $(current)" >&2
  exit 1
fi

arg="$1"
case "$arg" in
  patch)  NEW="$(bump_patch)" ;;
  minor)  NEW="$(bump_minor)" ;;
  major)  NEW="$(bump_major)" ;;
  *)
    if echo "$arg" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
      NEW="$arg"
    else
      echo "error: invalid version '$arg'; use semver (e.g. 1.2.0) or patch|minor|major" >&2
      exit 1
    fi
    ;;
esac

echo "$NEW" > "$VERSION_FILE"
echo "Set VERSION to $NEW"
"$SCRIPT_DIR/sync-version.sh"
