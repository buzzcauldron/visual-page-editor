@echo off
REM
REM Command line launcher for visual-page-editor (Windows).
REM
REM @version 1.1.0
REM @author buzzcauldron
REM @copyright Copyright(c) 2025, buzzcauldron
REM @license MIT License
REM Based on nw-page-editor by Mauricio Villegas
REM

setlocal enabledelayedexpansion

REM Get script directory
set "SCRIPT_DIR=%~dp0"
REM Go up one level from bin directory
for %%F in ("%SCRIPT_DIR%..") do set "APP_DIR=%%~fF"

REM Check if we're in the bin directory, if not try current directory
if not exist "%APP_DIR%\js\nw-app.js" (
  set "APP_DIR=%SCRIPT_DIR%"
)

REM Detect Windows architecture
set "WIN_ARCH=x64"
if "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "WIN_ARCH=ARM64"
if "%PROCESSOR_ARCHITEW6432%"=="ARM64" set "WIN_ARCH=ARM64"

REM Try to find NW.js in common locations
set "NWJS_EXE="

REM Check Program Files (architecture-specific first for ARM64)
if "%WIN_ARCH%"=="ARM64" (
  if exist "C:\Program Files\nwjs-arm64\nw.exe" (
    set "NWJS_EXE=C:\Program Files\nwjs-arm64\nw.exe"
  ) else if exist "%LOCALAPPDATA%\nwjs-arm64\nw.exe" (
    set "NWJS_EXE=%LOCALAPPDATA%\nwjs-arm64\nw.exe"
  ) else if exist "%USERPROFILE%\nwjs-arm64\nw.exe" (
    set "NWJS_EXE=%USERPROFILE%\nwjs-arm64\nw.exe"
  )
)

REM Fallback to standard locations (x64 or ARM64)
if "%NWJS_EXE%"=="" (
  if exist "C:\Program Files\nwjs\nw.exe" (
    set "NWJS_EXE=C:\Program Files\nwjs\nw.exe"
  ) else if exist "C:\Program Files (x86)\nwjs\nw.exe" (
    set "NWJS_EXE=C:\Program Files (x86)\nwjs\nw.exe"
  ) else if exist "%LOCALAPPDATA%\nwjs\nw.exe" (
    set "NWJS_EXE=%LOCALAPPDATA%\nwjs\nw.exe"
  ) else if exist "%USERPROFILE%\nwjs\nw.exe" (
    set "NWJS_EXE=%USERPROFILE%\nwjs\nw.exe"
  ) else (
    REM Try to find in PATH
    where nw.exe >nul 2>&1
    if !errorlevel! equ 0 (
      set "NWJS_EXE=nw.exe"
    ) else (
      where nw >nul 2>&1
      if !errorlevel! equ 0 (
        set "NWJS_EXE=nw"
      )
    )
  )
)

REM Validate paths
if not exist "%APP_DIR%\js\nw-app.js" (
  echo %~nx0: error: unable to resolve the visual-page-editor app location
  echo   Tried: %APP_DIR%
  exit /b 1
)

if "%NWJS_EXE%"=="" (
  echo %~nx0: error: unable to find the NW.js binary
  echo   Architecture detected: %WIN_ARCH%
  if "%WIN_ARCH%"=="ARM64" (
    echo   For Windows ARM64, download: nwjs-sdk-v*-win-arm64.zip from https://nwjs.io/downloads/
    echo   Or use x64 version (will run via emulation): nwjs-sdk-v*-win-x64.zip
  ) else (
    echo   Please install NW.js from https://nwjs.io/downloads/
  )
  echo   Or add NW.js to your PATH
  exit /b 1
)

REM Warn if using x64 NW.js on ARM64 Windows
if "%WIN_ARCH%"=="ARM64" (
  echo %NWJS_EXE% | findstr /i "arm64" >nul 2>&1
  if !errorlevel! neq 0 (
    echo Note: Using x64 NW.js on Windows ARM64. It will run via emulation.
    echo       For better performance, install ARM64 version: nwjs-sdk-v*-win-arm64.zip
  )
)

REM Help message
if "%1"=="-h" goto :help
if "%1"=="--help" goto :help

REM Prepare arguments
set "ARGS=--wd %CD%"
set "FIRST_ARG=1"

:arg_loop
if "%1"=="" goto :run
set "ARG=%1"

REM Replace -l with --list
if "%ARG%"=="-l" set "ARG=--list"

REM Replace -- with ++
if "%ARG:~0,2%"=="--" (
  set "ARG=++%ARG:~2%"
)

set "ARGS=%ARGS% %ARG%"
shift
goto :arg_loop

:run
REM Set log file location
set "LOG_FILE=%TEMP%\visual-page-editor.log"

REM Launch application
"%NWJS_EXE%" "%APP_DIR%" %ARGS% 2>>"%LOG_FILE%"
exit /b %errorlevel%

:help
echo Description: Simple app for visual editing of Page XML files
echo Usage: %~nx0 [page.xml]+ [pages_dir]+ [--list pages_list]+ [--css file.css]+ [--js file.js]+
exit /b 0
