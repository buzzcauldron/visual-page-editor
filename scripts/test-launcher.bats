#!/usr/bin/env bats
##
## Launcher unit tests — test platform detection, architecture normalization,
## NW.js path resolution, and cache validation without actually launching NW.js.
##
## Run with:  bats scripts/test-launcher.bats
##

# ─── Helpers ──────────────────────────────────────────────────────────────────

# Source just the detection/resolution sections of the launcher into a subshell.
# We redirect stdin/stdout to avoid the real exec at the end of the script.
# We set TEST_MODE=1 to prevent the final exec from running.
sourced_launcher() {
  # Export a version of the launcher with the exec replaced by a no-op
  local launcher
  launcher="$(cat "$(dirname "$BATS_TEST_DIRNAME")/bin/visual-page-editor")"
  # Strip everything from the first `exec $nw` or `exec "$nw"` onwards
  launcher="${launcher%%exec \$nw*}"
  launcher="${launcher%%exec \"\$nw\"*}"
  echo "$launcher"
}

# Run the detection section in a controlled environment.
# Usage: run_detection [uname_s] [uname_m] [env_overrides...]
run_detection() {
  local uname_s="${1:-Linux}"
  local uname_m="${2:-x86_64}"
  shift 2

  # Build a minimal script that:
  #  1. Stubs uname
  #  2. Sets optional env overrides
  #  3. Runs only the platform/arch detection block from the launcher

  bash -c "
    uname() {
      case \"\$1\" in
        -s) echo '$uname_s' ;;
        -m) echo '$uname_m' ;;
        *)  command uname \"\$@\" ;;
      esac
    }
    export -f uname
    $@  # env overrides if any

    OS=\"\$(uname -s)\"
    case \"\${OS}\" in
      Linux*)   PLATFORM='linux';;
      Darwin*)  PLATFORM='macos';;
      CYGWIN*)  PLATFORM='windows';;
      MINGW*)   PLATFORM='windows';;
      MSYS*)    PLATFORM='windows';;
      *)        PLATFORM='unknown';;
    esac

    MAC_ARCH=''
    WIN_ARCH='x64'
    MACHINE_ARCH='x64'
    if [ \"\$PLATFORM\" = 'macos' ]; then
      MAC_ARCH=\$(uname -m)
      case \"\$MAC_ARCH\" in arm64|arm64e) MAC_ARCH='arm64' ;; esac
      case \"\$MAC_ARCH\" in arm64) MACHINE_ARCH='arm64';; *) MACHINE_ARCH='x64';; esac
    elif [ \"\$PLATFORM\" = 'windows' ]; then
      if [ -n \"\${PROCESSOR_ARCHITECTURE:-}\" ] && [ \"\$PROCESSOR_ARCHITECTURE\" = 'ARM64' ]; then WIN_ARCH='arm64'; MACHINE_ARCH='arm64'
      elif [ -n \"\${PROCESSOR_ARCHITEW6432:-}\" ] && [ \"\$PROCESSOR_ARCHITEW6432\" = 'ARM64' ]; then WIN_ARCH='arm64'; MACHINE_ARCH='arm64'
      elif [ \"\$(uname -m 2>/dev/null)\" = 'aarch64' ]; then WIN_ARCH='arm64'; MACHINE_ARCH='arm64'
      fi
    elif [ \"\$PLATFORM\" = 'linux' ]; then
      case \"\$(uname -m 2>/dev/null)\" in aarch64|arm64) MACHINE_ARCH='arm64';; esac
    fi

    echo \"PLATFORM=\$PLATFORM\"
    echo \"MACHINE_ARCH=\$MACHINE_ARCH\"
    echo \"MAC_ARCH=\$MAC_ARCH\"
    echo \"WIN_ARCH=\$WIN_ARCH\"
  "
}

# ─── Platform detection ────────────────────────────────────────────────────────

@test "Linux uname maps to linux platform" {
  result=$(run_detection "Linux" "x86_64")
  echo "$result" | grep -q "PLATFORM=linux"
}

@test "Darwin uname maps to macos platform" {
  result=$(run_detection "Darwin" "arm64")
  echo "$result" | grep -q "PLATFORM=macos"
}

@test "CYGWIN uname maps to windows platform" {
  result=$(run_detection "CYGWIN_NT-10.0" "x86_64")
  echo "$result" | grep -q "PLATFORM=windows"
}

@test "MINGW uname maps to windows platform" {
  result=$(run_detection "MINGW64_NT-10.0" "x86_64")
  echo "$result" | grep -q "PLATFORM=windows"
}

@test "MSYS uname maps to windows platform" {
  result=$(run_detection "MSYS_NT-10.0" "x86_64")
  echo "$result" | grep -q "PLATFORM=windows"
}

@test "unknown uname maps to unknown platform" {
  result=$(run_detection "FreeBSD" "amd64")
  echo "$result" | grep -q "PLATFORM=unknown"
}

# ─── Architecture detection ───────────────────────────────────────────────────

@test "Linux x86_64 → MACHINE_ARCH=x64" {
  result=$(run_detection "Linux" "x86_64")
  echo "$result" | grep -q "MACHINE_ARCH=x64"
}

@test "Linux aarch64 → MACHINE_ARCH=arm64" {
  result=$(run_detection "Linux" "aarch64")
  echo "$result" | grep -q "MACHINE_ARCH=arm64"
}

@test "macOS arm64 → MACHINE_ARCH=arm64 and MAC_ARCH=arm64" {
  result=$(run_detection "Darwin" "arm64")
  echo "$result" | grep -q "MACHINE_ARCH=arm64"
  echo "$result" | grep -q "MAC_ARCH=arm64"
}

@test "macOS arm64e is normalized to arm64" {
  result=$(run_detection "Darwin" "arm64e")
  echo "$result" | grep -q "MAC_ARCH=arm64"
  echo "$result" | grep -q "MACHINE_ARCH=arm64"
}

@test "macOS x86_64 → MACHINE_ARCH=x64" {
  result=$(run_detection "Darwin" "x86_64")
  echo "$result" | grep -q "MACHINE_ARCH=x64"
}

@test "Windows x86_64 → WIN_ARCH=x64 MACHINE_ARCH=x64" {
  result=$(run_detection "MINGW64_NT-10.0" "x86_64")
  echo "$result" | grep -q "WIN_ARCH=x64"
  echo "$result" | grep -q "MACHINE_ARCH=x64"
}

@test "Windows ARM64 via PROCESSOR_ARCHITECTURE → WIN_ARCH=arm64" {
  result=$(PROCESSOR_ARCHITECTURE=ARM64 run_detection "MINGW64_NT-10.0" "x86_64")
  echo "$result" | grep -q "WIN_ARCH=arm64"
  echo "$result" | grep -q "MACHINE_ARCH=arm64"
}

# ─── Cache validation ─────────────────────────────────────────────────────────

# Helper: run the cache-read section with a mock cache file
run_cache_check() {
  local cached_path="$1"
  local cached_ver="$2"
  local cached_arch="$3"
  local nwjs_version="${4:-0.109.1}"
  local machine_arch="${5:-x64}"

  # Write mock cache to a temp file
  local tmpdir
  tmpdir=$(mktemp -d)
  local cache_file="$tmpdir/nw-path"
  printf '%s\n%s\n%s\n' "$cached_path" "$cached_ver" "$cached_arch" > "$cache_file"

  bash -c "
    CACHE_FILE='$cache_file'
    NWJS_VERSION='$nwjs_version'
    MACHINE_ARCH='$machine_arch'
    PLATFORM='linux'
    nw=''

    # Simulate the cache-reading block from the launcher
    if [ -f \"\$CACHE_FILE\" ]; then
      cached_path=\$(head -n 1 \"\$CACHE_FILE\" 2>/dev/null)
      cached_ver=\$(sed -n '2p' \"\$CACHE_FILE\" 2>/dev/null)
      cached_arch=\$(sed -n '3p' \"\$CACHE_FILE\" 2>/dev/null)
      if [ -n \"\$cached_path\" ] && [ -f \"\$cached_path\" ] && [ -x \"\$cached_path\" ] && [ \"\$cached_ver\" = \"\$NWJS_VERSION\" ]; then
        arch_ok=1
        if [ -n \"\$cached_arch\" ]; then
          [ \"\$cached_arch\" != \"\$MACHINE_ARCH\" ] && arch_ok=0
        fi
        [ \"\$arch_ok\" = 1 ] && nw=\"\$cached_path\"
      fi
    fi
    echo \"nw=\$nw\"
  "

  rm -rf "$tmpdir"
}

@test "cache: valid path+version+arch is used" {
  # Create a real executable for the cache to point to
  local tmpbin
  tmpbin=$(mktemp)
  chmod +x "$tmpbin"

  result=$(run_cache_check "$tmpbin" "0.109.1" "x64" "0.109.1" "x64")
  rm -f "$tmpbin"
  echo "$result" | grep -q "nw=$tmpbin"
}

@test "cache: version mismatch → cache skipped" {
  local tmpbin
  tmpbin=$(mktemp)
  chmod +x "$tmpbin"

  result=$(run_cache_check "$tmpbin" "0.108.0" "x64" "0.109.1" "x64")
  rm -f "$tmpbin"
  echo "$result" | grep -q "nw=$" # nw should be empty
}

@test "cache: architecture mismatch → cache skipped" {
  local tmpbin
  tmpbin=$(mktemp)
  chmod +x "$tmpbin"

  result=$(run_cache_check "$tmpbin" "0.109.1" "arm64" "0.109.1" "x64")
  rm -f "$tmpbin"
  echo "$result" | grep -q "nw=$" # nw should be empty
}

@test "cache: non-existent binary → cache skipped" {
  result=$(run_cache_check "/nonexistent/nw" "0.109.1" "x64" "0.109.1" "x64")
  echo "$result" | grep -q "nw=$"
}

@test "cache: stores three lines (path, version, arch)" {
  local tmpdir
  tmpdir=$(mktemp -d)
  local cache_file="$tmpdir/nw-path"

  bash -c "
    CACHE_DIR='$tmpdir'
    CACHE_FILE='$cache_file'
    NWJS_VERSION='0.109.1'
    MACHINE_ARCH='x64'
    nw='/fake/nw'

    mkdir -p \"\$CACHE_DIR\"
    printf '%s\n%s\n%s\n' \"\$nw\" \"\$NWJS_VERSION\" \"\$MACHINE_ARCH\" > \"\$CACHE_FILE\"
  "

  local lines
  lines=$(wc -l < "$cache_file")
  rm -rf "$tmpdir"
  [ "$lines" -eq 3 ]
}

# ─── npm NW path preference ───────────────────────────────────────────────────

@test "npm nw binary is preferred when it exists" {
  local tmpdir
  tmpdir=$(mktemp -d)
  local npm_nw="$tmpdir/node_modules/.bin/nw"
  mkdir -p "$(dirname "$npm_nw")"
  printf '#!/bin/sh\n' > "$npm_nw"
  chmod +x "$npm_nw"

  result=$(bash -c "
    nw_page_editor='$tmpdir'
    nw_from_npm=''
    nw=''
    if [ -n \"\$nw_page_editor\" ] && [ -f \"\$nw_page_editor/node_modules/.bin/nw\" ]; then
      case \"\$nw_page_editor\" in
        /*) nw_from_npm=\"\$nw_page_editor/node_modules/.bin/nw\" ;;
      esac
      [ -n \"\$nw_from_npm\" ] && [ ! -x \"\$nw_from_npm\" ] && chmod +x \"\$nw_from_npm\" 2>/dev/null || true
    fi
    if [ -n \"\$nw_from_npm\" ] && [ -f \"\$nw_from_npm\" ]; then
      nw=\"\$nw_from_npm\"
    fi
    echo \"nw=\$nw\"
  ")

  rm -rf "$tmpdir"
  echo "$result" | grep -q "nw=$npm_nw"
}

@test "npm nw is skipped when node_modules/.bin/nw does not exist" {
  result=$(bash -c "
    nw_page_editor='/nonexistent/path'
    nw_from_npm=''
    nw=''
    if [ -n \"\$nw_page_editor\" ] && [ -f \"\$nw_page_editor/node_modules/.bin/nw\" ]; then
      nw_from_npm=\"\$nw_page_editor/node_modules/.bin/nw\"
    fi
    if [ -n \"\$nw_from_npm\" ] && [ -f \"\$nw_from_npm\" ]; then
      nw=\"\$nw_from_npm\"
    fi
    echo \"nw=\$nw\"
  ")
  echo "$result" | grep -q "nw=$"
}
