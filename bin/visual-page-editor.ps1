# Command line launcher for visual-page-editor (Windows PowerShell version).
#
# @version 1.0.0
# @author buzzcauldron
# @copyright Copyright(c) 2025, buzzcauldron
# @license MIT License
# Based on nw-page-editor by Mauricio Villegas

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Arguments
)

# Get the directory where this script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BinDir = Split-Path -Parent $ScriptDir

# Resolve the visual-page-editor app location
if (-not $env:nw_page_editor) {
    $nw_page_editor = $BinDir
} else {
    $nw_page_editor = $env:nw_page_editor
}

# Check for alternative locations
if (-not (Test-Path "$nw_page_editor\js\nw-app.js")) {
    if (Test-Path "$nw_page_editor\share\nw-page-editor\js\nw-app.js") {
        $nw_page_editor = "$nw_page_editor\share\nw-page-editor"
    }
}

# Find NW.js binary
$nw = $null

# Check common Windows locations first
$commonPaths = @(
    "C:\Program Files\nwjs\nw.exe",
    "C:\Program Files (x86)\nwjs\nw.exe",
    "$env:LOCALAPPDATA\nwjs\nw.exe"
)

foreach ($path in $commonPaths) {
    if (Test-Path $path) {
        $nw = $path
        break
    }
}

# Check if nw.exe is in PATH
if (-not $nw) {
    $nwPath = Get-Command nw.exe -ErrorAction SilentlyContinue
    if ($nwPath) {
        $nw = $nwPath.Source
    }
}

# Check for nwjs.exe (alternative name)
if (-not $nw) {
    $nwjsPath = Get-Command nwjs.exe -ErrorAction SilentlyContinue
    if ($nwjsPath) {
        $nw = $nwjsPath.Source
    }
}

# Validate app location
if (-not (Test-Path "$nw_page_editor\js\nw-app.js")) {
    Write-Host "$($MyInvocation.MyCommand.Name): error: unable to resolve the visual-page-editor app location" -ForegroundColor Red
    exit 1
}

# Validate NW.js binary
if (-not $nw) {
    Write-Host "$($MyInvocation.MyCommand.Name): error: unable to find the NW.js binary in the PATH" -ForegroundColor Red
    Write-Host "Please install NW.js and add it to your PATH, or place it in one of these locations:"
    Write-Host "  C:\Program Files\nwjs\nw.exe"
    Write-Host "  C:\Program Files (x86)\nwjs\nw.exe"
    Write-Host "  $env:LOCALAPPDATA\nwjs\nw.exe"
    exit 1
}

# Handle help
if ($Arguments.Count -eq 0 -or $Arguments[0] -eq "-h" -or $Arguments[0] -eq "--help") {
    Write-Host "Description: Simple app for visual editing of Page XML files"
    Write-Host "Usage: $($MyInvocation.MyCommand.Name) [page.xml]+ [pages_dir]+ [--list pages_list]+ [--css file.css]+ [--js file.js]+"
    exit 0
}

# Set log file location (Windows temp directory)
$LogFile = "$env:TEMP\visual-page-editor.log"

# Build arguments array with transformations
$argv = @("--wd", (Get-Location).Path)

# Process command line arguments
foreach ($arg in $Arguments) {
    # Replace -l with --list
    if ($arg -eq "-l") {
        $argv += "--list"
    }
    # Replace -- with ++ (only if it starts with --)
    elseif ($arg -match '^--') {
        $argv += $arg -replace '^--', '++'
    }
    else {
        $argv += $arg
    }
}

# Run NW.js with the application
# Build the full argument list
$allArgs = @($nw_page_editor) + $argv

# Execute with error redirection to log file
try {
    & $nw $allArgs 2>> $LogFile
    exit $LASTEXITCODE
}
catch {
    Write-Host "Error launching NW.js: $_" -ForegroundColor Red
    exit 1
}
