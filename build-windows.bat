@echo off
REM Build script wrapper for Windows (calls PowerShell script)
REM This allows running the build from Command Prompt

setlocal

set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%build-windows.ps1"

if not exist "%PS_SCRIPT%" (
    echo Error: PowerShell build script not found at %PS_SCRIPT%
    exit /b 1
)

REM Check if PowerShell is available
where powershell.exe >nul 2>&1
if errorlevel 1 (
    echo Error: PowerShell is not available
    echo Please install PowerShell or run build-windows.ps1 directly
    exit /b 1
)

REM Run PowerShell script
powershell.exe -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*

exit /b %errorlevel%
