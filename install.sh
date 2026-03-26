#!/usr/bin/env bash
# Convenience wrapper (repo root): full desktop install + NW.js via npm.
exec "$(cd "$(dirname "$0")" && pwd)/scripts/install-desktop.sh" "$@"
