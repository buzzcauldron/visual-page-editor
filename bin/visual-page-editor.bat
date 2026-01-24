@echo off
REM
REM Command line launcher for visual-page-editor (Windows version).
REM
REM @version 1.0.0
REM @author buzzcauldron
REM @copyright Copyright(c) 2025, buzzcauldron
REM @license MIT License
REM Based on nw-page-editor by Mauricio Villegas
REM

setlocal enabledelayedexpansion

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

REM Resolve the visual-page-editor app location
if "%nw_page_editor%"=="" (
    REM Get the parent directory of bin/
    for %%F in ("%SCRIPT_DIR%") do set "nw_page_editor=%%~dpF"
    set "nw_page_editor=!nw_page_editor:~0,-1!"
)

REM Check for alternative locations
if not exist "!nw_page_editor!\js\nw-app.js" (
    if exist "!nw_page_editor!\share\nw-page-editor\js\nw-app.js" (
        set "nw_page_editor=!nw_page_editor!\share\nw-page-editor"
    )
)

REM Find NW.js binary
set "nw="

REM Check common Windows locations first
if exist "C:\Program Files\nwjs\nw.exe" (
    set "nw=C:\Program Files\nwjs\nw.exe"
)
if exist "C:\Program Files (x86)\nwjs\nw.exe" (
    set "nw=C:\Program Files (x86)\nwjs\nw.exe"
)
if exist "%LOCALAPPDATA%\nwjs\nw.exe" (
    set "nw=%LOCALAPPDATA%\nwjs\nw.exe"
)

REM Check if nw.exe is in PATH
if "!nw!"=="" (
    where nw.exe >nul 2>&1
    if !errorlevel! equ 0 (
        for /f "delims=" %%i in ('where nw.exe') do set "nw=%%i"
    )
)

REM Check for nwjs.exe (alternative name)
if "!nw!"=="" (
    where nwjs.exe >nul 2>&1
    if !errorlevel! equ 0 (
        for /f "delims=" %%i in ('where nwjs.exe') do set "nw=%%i"
    )
)

REM Validate app location
if not exist "!nw_page_editor!\js\nw-app.js" (
    echo %~nx0: error: unable to resolve the visual-page-editor app location
    exit /b 1
)

REM Validate NW.js binary
if "!nw!"=="" (
    echo %~nx0: error: unable to find the NW.js binary in the PATH
    echo Please install NW.js and add it to your PATH, or place it in one of these locations:
    echo   C:\Program Files\nwjs\nw.exe
    echo   C:\Program Files (x86)\nwjs\nw.exe
    echo   %LOCALAPPDATA%\nwjs\nw.exe
    exit /b 1
)

REM Handle help
if "%1"=="-h" goto :help
if "%1"=="--help" goto :help

REM Try to use PowerShell script if available (better argument handling)
if exist "!SCRIPT_DIR!\visual-page-editor.ps1" (
    powershell.exe -ExecutionPolicy Bypass -File "!SCRIPT_DIR!\visual-page-editor.ps1" %*
    exit /b %errorlevel%
)

REM Fallback: Execute NW.js directly with arguments
REM Note: This version doesn't transform -l to --list or -- to ++
REM For full compatibility, use the PowerShell script version
set "LOG_FILE=%TEMP%\visual-page-editor.log"
"!nw!" "!nw_page_editor!" --wd "!CD!" %* 2>>"!LOG_FILE!"
exit /b %errorlevel%

:help
echo Description: Simple app for visual editing of Page XML files
echo Usage: %~nx0 [page.xml]+ [pages_dir]+ [--list pages_list]+ [--css file.css]+ [--js file.js]+
echo.
echo Note: On Windows, use --list instead of -l, and ++ instead of -- for internal options
exit /b 0
