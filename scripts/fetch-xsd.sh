#!/usr/bin/env bash
# Download Page XML XSD files from omni-us/pageformat so the app works without
# initializing the git submodule. Run from repo root: ./scripts/fetch-xsd.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
XSD_DIR="$ROOT/xsd/pageformat"
BASE_URL="https://raw.githubusercontent.com/omni-us/pageformat/master"

mkdir -p "$XSD_DIR/old"

fetch() {
  local path="$1"
  local dest="$XSD_DIR/$path"
  if [ -s "$dest" ]; then
    echo "  (already present) $dest"
    return 0
  fi
  echo "  Fetching $path ..."
  if command -v curl >/dev/null 2>&1; then
    curl -fLSs -o "$dest" "$BASE_URL/$path"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$dest" "$BASE_URL/$path"
  else
    echo "error: need curl or wget" >&2
    exit 1
  fi
}

fetch "pagecontent_omnius.xsd"
fetch "old/pagecontent_searchink.xsd"
echo "Done. XSD files are in $XSD_DIR"
