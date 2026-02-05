# Command line launcher for visual-page-editor (Windows PowerShell).
#
# @version 1.1.2
# @author buzzcauldron
# @copyright Copyright(c) 2025, buzzcauldron
# @license MIT License
# Based on nw-page-editor by Mauricio Villegas
#

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Arguments
)

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AppDir = Split-Path -Parent $ScriptDir

# Check if we're in the bin directory, if not try parent
if (-not (Test-Path "$AppDir\js\nw-app.js")) {
    $AppDir = $ScriptDir
}

# Detect Windows architecture (PROCESSOR_ARCHITEW6432 = native arch when running 32-bit process on 64-bit OS)
$WindowsArch = $env:PROCESSOR_ARCHITEW6432
if ([string]::IsNullOrEmpty($WindowsArch)) {
    $WindowsArch = $env:PROCESSOR_ARCHITECTURE
}
if ($WindowsArch -eq "ARM64") {
    $WindowsArch = "ARM64"
} elseif ($WindowsArch -eq "AMD64") {
    $WindowsArch = "x64"
} else {
    $WindowsArch = "x64"  # Default to x64
}

# Try to find NW.js in common locations
# On ARM64, prefer ARM64 builds, but allow x64 via emulation
$NwjsExe = $null

$PossiblePaths = @()
if ($WindowsArch -eq "ARM64") {
    # ARM64: Try ARM64 first, then x64 locations
    $PossiblePaths += @(
        "C:\Program Files\nwjs-arm64\nw.exe",
        "$env:LOCALAPPDATA\nwjs-arm64\nw.exe",
        "$env:USERPROFILE\nwjs-arm64\nw.exe",
        "C:\Program Files\nwjs\nw.exe",
        "C:\Program Files (x86)\nwjs\nw.exe",
        "$env:LOCALAPPDATA\nwjs\nw.exe",
        "$env:USERPROFILE\nwjs\nw.exe"
    )
} else {
    # x64: Standard locations
    $PossiblePaths += @(
        "C:\Program Files\nwjs\nw.exe",
        "C:\Program Files (x86)\nwjs\nw.exe",
        "$env:LOCALAPPDATA\nwjs\nw.exe",
        "$env:USERPROFILE\nwjs\nw.exe"
    )
}

foreach ($Path in $PossiblePaths) {
    if (Test-Path $Path) {
        $NwjsExe = $Path
        break
    }
}

# Try to find in PATH
if ($null -eq $NwjsExe) {
    $NwjsInPath = Get-Command nw.exe -ErrorAction SilentlyContinue
    if ($null -ne $NwjsInPath) {
        $NwjsExe = $NwjsInPath.Path
    } else {
        $NwjsInPath = Get-Command nw -ErrorAction SilentlyContinue
        if ($null -ne $NwjsInPath) {
            $NwjsExe = $NwjsInPath.Path
        }
    }
}

# Validate paths
if (-not (Test-Path "$AppDir\js\nw-app.js")) {
    Write-Host "$($MyInvocation.MyCommand.Name): error: unable to resolve the visual-page-editor app location" -ForegroundColor Red
    Write-Host "  Tried: $AppDir" -ForegroundColor Red
    exit 1
}

if ($null -eq $NwjsExe -or -not (Test-Path $NwjsExe)) {
    Write-Host "$($MyInvocation.MyCommand.Name): error: unable to find the NW.js binary" -ForegroundColor Red
    Write-Host "  Architecture detected: $WindowsArch" -ForegroundColor Yellow
    if ($WindowsArch -eq "ARM64") {
        Write-Host "  For Windows ARM64, download: nwjs-sdk-v*-win-arm64.zip from https://nwjs.io/downloads/" -ForegroundColor Yellow
        Write-Host "  Or use x64 version (will run via emulation): nwjs-sdk-v*-win-x64.zip" -ForegroundColor Yellow
    } else {
        Write-Host "  Please install NW.js from https://nwjs.io/downloads/" -ForegroundColor Yellow
    }
    Write-Host "  Or add NW.js to your PATH" -ForegroundColor Yellow
    exit 1
}

# Warn if using x64 NW.js on ARM64 Windows
if ($WindowsArch -eq "ARM64" -and $NwjsExe -notlike "*arm64*") {
    Write-Host "Note: Using x64 NW.js on Windows ARM64. It will run via emulation." -ForegroundColor Yellow
    Write-Host "      For better performance, install ARM64 version: nwjs-sdk-v*-win-arm64.zip" -ForegroundColor Yellow
}

# Help message
if ($Arguments.Count -gt 0 -and ($Arguments[0] -eq "-h" -or $Arguments[0] -eq "--help")) {
    Write-Host "Description: Simple app for visual editing of Page XML files"
    Write-Host "Usage: $($MyInvocation.MyCommand.Name) [page.xml]+ [pages_dir]+ [--list pages_list]+ [--css file.css]+ [--js file.js]+"
    exit 0
}

# Prepare arguments
$ProcessArgs = @("--wd", (Get-Location).Path)

foreach ($Arg in $Arguments) {
    # Replace -l with --list
    if ($Arg -eq "-l") {
        $ProcessArgs += "--list"
    }
    # Replace -- with ++
    elseif ($Arg.StartsWith("--")) {
        $ProcessArgs += "++" + $Arg.Substring(2)
    }
    else {
        $ProcessArgs += $Arg
    }
}

# Set log file location
$LogFile = Join-Path $env:TEMP "visual-page-editor.log"

# Launch application
# Flatten arguments: combine $AppDir with $ProcessArgs array elements
# Using @() ensures proper array flattening instead of nested array
try {
    $AllArgs = @($AppDir) + $ProcessArgs
    $Process = Start-Process -FilePath $NwjsExe -ArgumentList $AllArgs -NoNewWindow -PassThru -RedirectStandardError $LogFile
    $Process.WaitForExit()
    exit $Process.ExitCode
}
catch {
    Write-Host "Error launching NW.js: $_" -ForegroundColor Red
    exit 1
}
