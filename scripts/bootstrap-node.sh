#!/usr/bin/env bash
# Download a portable Node.js into .tools/ if none is available (or Node < 18), then run npm install.
# Does not modify system PATH permanently. Requires curl or wget, and tar.
# Usage: ./scripts/bootstrap-node.sh [--start] [--]
#   --start   run npm start after install
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Pin to current Node 20 LTS; override: NODE_BOOTSTRAP_VERSION=22.12.0 ./scripts/bootstrap-node.sh
NODE_BOOTSTRAP_VERSION="${NODE_BOOTSTRAP_VERSION:-20.18.0}"
MIN_NODE_MAJOR=18

have_good_node() {
  command -v node >/dev/null 2>&1 || return 1
  node -e 'process.exit(parseInt(process.versions.node.split(".")[0],10)>=18?0:1)' 2>/dev/null
}

ensure_portable_node() {
  if have_good_node; then
    echo "Using existing Node.js: $(command -v node) ($(node -v))"
    export PATH="$(dirname "$(command -v node)"):$PATH"
    return 0
  fi

  local os arch arch_n ext extract_dir dest
  os="$(uname -s)"
  arch="$(uname -m 2>/dev/null || echo unknown)"

  case "$os" in
    Linux*) os=linux ;;
    Darwin*) os=darwin ;;
    *) echo "This script only auto-downloads Node for Linux and macOS. Install Node.js from https://nodejs.org/ or use Docker (see README-DOCKER.md)." >&2
       exit 1 ;;
  esac

  case "$arch" in
    x86_64|amd64) arch_n=x64 ;;
    aarch64|arm64) arch_n=arm64 ;;
    *) echo "Unsupported CPU architecture: $arch" >&2; exit 1 ;;
  esac

  if [ "$os" = "linux" ]; then
    ext=tar.xz
  else
    ext=tar.gz
  fi

  extract_dir="node-v${NODE_BOOTSTRAP_VERSION}-${os}-${arch_n}"
  dest="$ROOT/.tools/${extract_dir}"

  mkdir -p "$ROOT/.tools"
  if [ -x "$dest/bin/node" ]; then
    echo "Using cached portable Node.js: $dest"
    export PATH="$dest/bin:$PATH"
    return 0
  fi

  url="https://nodejs.org/dist/v${NODE_BOOTSTRAP_VERSION}/${extract_dir}.${ext}"
  echo "No usable Node.js in PATH. Downloading Node ${NODE_BOOTSTRAP_VERSION} for ${os}-${arch_n}..." >&2
  echo "  $url" >&2

  tmp="$ROOT/.tools/${extract_dir}.${ext}"
  if command -v curl >/dev/null 2>&1; then
    curl -fLSs -o "$tmp" "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$tmp" "$url"
  else
    echo "Need curl or wget to download Node.js." >&2
    exit 1
  fi

  rm -rf "$dest"
  if [ "$os" = "linux" ]; then
    tar -xJf "$tmp" -C "$ROOT/.tools"
  else
    tar -xzf "$tmp" -C "$ROOT/.tools"
  fi
  rm -f "$tmp"

  if [ ! -x "$dest/bin/node" ]; then
    echo "Extract failed: expected $dest/bin/node" >&2
    exit 1
  fi

  export PATH="$dest/bin:$PATH"
  echo "Portable Node.js ready: $dest" >&2
}

DO_START=0
args=()
for a in "$@"; do
  if [ "$a" = "--start" ]; then DO_START=1
  else args+=("$a"); fi
done

ensure_portable_node

command -v npm >/dev/null 2>&1 || { echo "npm not found after bootstrap" >&2; exit 1; }

npm install "${args[@]}"

if [ "$DO_START" = 1 ]; then
  exec npm start
fi

echo ""
echo "Dependencies installed. Start the app with:"
echo "  npm start"
echo "  ./bin/visual-page-editor [files.xml]"
echo "(Use the same terminal so PATH still includes the portable Node, or run this script again before npm commands.)"
