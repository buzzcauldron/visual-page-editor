# Privilege and design choices (ARM64 branch)

Summary of privilege, permission, and architecture choices made for ARM64 / Apple Silicon and Windows ARM64 support (from the arm64-support branch and current codebase).

## Architecture and runtime

| Choice | Detail |
|--------|--------|
| **Prefer native ARM64** | On Apple Silicon and Windows ARM64, the launcher prefers ARM64 NW.js. x64 is allowed as fallback (Rosetta 2 / Windows emulation) with a console warning. |
| **NW.js version** | When ARM64 is detected: **0.50.0** (first NW.js with ARM64 builds). On Intel/x64: **0.44.0** or **0.44.4** is acceptable. Override with `NWJS_VERSION`. |
| **Hardware vs process arch** | `build-macos.sh` and launchers use **hardware** architecture (e.g. `sysctl hw.optional.arm64`) so we pick ARM64 even when the shell is running under Rosetta (`uname -m` = x86_64). |

## macOS .app bundle

| Choice | Detail |
|--------|--------|
| **Minimum OS** | **11.0** for ARM64 builds (`LSMinimumSystemVersion`). **10.13** for Intel. |
| **No entitlements file** | Build does not add an entitlements plist; no hardened runtime or app-sandbox entitlements are set. The app runs with default app permissions. |
| **Info.plist** | `NSAppleEventsUsageDescription` for file access; `NSHighResolutionCapable` true; `NSRequiresAquaSystemAppearance` false. |
| **Launch guard** | If the .app contains **x64** NW.js on Apple Silicon, the bundled launcher **aborts** with an error (and optional macOS dialog) to avoid the usual immediate crash. |

## Launcher behavior (bin/visual-page-editor, .bat, .ps1)

| Choice | Detail |
|--------|--------|
| **Search order** | On macOS ARM64: look for ARM64 NW.js in `/Applications`, then `~/.nwjs`; if only x64 is found, use it and warn. On Windows ARM64: look in `Program Files\nwjs-arm64`, `%LOCALAPPDATA%\nwjs-arm64`, `%USERPROFILE%\nwjs`, then x64 paths. |
| **Auto-download** | When offering to download NW.js, the script chooses **arm64** build when on ARM64 (macOS or Windows). |
| **No elevation** | Launchers do not request admin/root; they run with the current user. |

## Docker

| Choice | Detail |
|--------|--------|
| **Default run** | Normal runs do **not** use `--privileged`. |
| **Troubleshooting** | README-DOCKER suggests `--privileged` only if you hit "Permission denied" with X11 or devices; not required for typical GUI use. |

## Summary

- **Privilege**: No extra privileges requested; no sandbox/hardened entitlements; launchers run as the current user. Docker defaults to non-privileged.
- **ARM64**: Native ARM64 is preferred when available; x64 is allowed with a warning. NW.js 0.50.0+ used when building or running on ARM64.
- **macOS**: ARM64 .app requires macOS 11.0+; launch is blocked if the bundle contains x64 NW.js on Apple Silicon to avoid crashes.
