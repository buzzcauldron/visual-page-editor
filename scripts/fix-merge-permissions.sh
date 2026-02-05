#!/usr/bin/env bash
# Remove Debian package build output (so git merge can run) and merge origin/main.
# Build scripts are kept: build-deb.sh, debian/rules, control, changelog, etc.
# Run from repo root: ./scripts/fix-merge-permissions.sh (will prompt for sudo only for removal)

set -e
cd "$(dirname "$0")/.."
echo "Removing Debian build output (keeps build-deb.sh and debian/*.rules, control, etc.)..."
sudo rm -rf debian/visual-page-editor debian/.debhelper debian/debhelper-build-stamp
echo "Merging origin/main..."
git pull --no-rebase origin main
echo "Done. You can build a new package later with: ./build-deb.sh"
