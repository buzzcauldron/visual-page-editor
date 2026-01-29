# Build script for creating Windows portable package of visual-page-editor with bundled NW.js
# Requires PowerShell 5.1 or later

param(
    [string]$NWJS_VERSION = "0.44.4",
    [string]$VERSION = "1.0.0"
)

$ErrorActionPreference = "Stop"

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = $SCRIPT_DIR
$NAME = "visual-page-editor"
$BUILD_DIR = Join-Path $PROJECT_ROOT "build-windows"
$PACKAGE_DIR = Join-Path $BUILD_DIR $NAME

# Detect architecture
$WindowsArch = $env:PROCESSOR_ARCHITECTURE
if ($WindowsArch -eq "ARM64") {
    $ARCH = "arm64"
    $NWJS_SUFFIX = "win-arm64"
} elseif ($WindowsArch -eq "AMD64") {
    $ARCH = "x64"
    $NWJS_SUFFIX = "win-x64"
} else {
    # Default to x64 for unknown architectures
    $ARCH = "x64"
    $NWJS_SUFFIX = "win-x64"
    Write-Warning "Unknown architecture '$WindowsArch', defaulting to x64"
}

$NWJS_ARCHIVE = "nwjs-sdk-v$NWJS_VERSION-$NWJS_SUFFIX.zip"
$NWJS_URL = "https://dl.nwjs.io/v$NWJS_VERSION/$NWJS_ARCHIVE"
$NWJS_EXTRACTED = Join-Path $PROJECT_ROOT "nwjs-sdk-v$NWJS_VERSION-$NWJS_SUFFIX"

function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Check-Requirements {
    Write-ColorOutput Yellow "Checking requirements..."
    
    $missingTools = @()
    
    if (-not (Get-Command curl -ErrorAction SilentlyContinue)) {
        $missingTools += "curl"
    }
    
    if (-not (Get-Command Expand-Archive -ErrorAction SilentlyContinue)) {
        # Expand-Archive is available in PowerShell 5.0+
        Write-ColorOutput Red "Error: PowerShell 5.0 or later is required for Expand-Archive"
        exit 1
    }
    
    if ($missingTools.Count -gt 0) {
        Write-ColorOutput Red "Error: Missing required tools: $($missingTools -join ', ')"
        Write-Output "Please install them or use Chocolatey:"
        Write-Output "  choco install curl"
        exit 1
    }
    
    Write-ColorOutput Green "All requirements met!"
}

function Download-NWJS {
    Write-ColorOutput Yellow "Checking for NW.js v$NWJS_VERSION ($NWJS_SUFFIX)..."
    
    $nwjsArchive = Join-Path $PROJECT_ROOT $NWJS_ARCHIVE
    $nwjsExe = Join-Path $NWJS_EXTRACTED "nw.exe"
    
    # Check if already downloaded and verify architecture
    if ((Test-Path $NWJS_EXTRACTED) -and (Test-Path $nwjsExe)) {
        $fileInfo = Get-Item $nwjsExe -ErrorAction SilentlyContinue
        if ($null -ne $fileInfo) {
            # Check file architecture using file command equivalent
            $fileOutput = & file $nwjsExe 2>$null
            if ($null -eq $fileOutput) {
                # Fallback: try to check via PowerShell
                $fileOutput = (Get-Content $nwjsExe -TotalCount 1 -ErrorAction SilentlyContinue | Format-Hex | Select-String -Pattern "PE" -Quiet)
            }
            
            $expectedArch = if ($ARCH -eq "arm64") { "ARM64" } else { "x64" }
            if ($fileOutput -match $expectedArch -or $fileOutput -match "PE32") {
                Write-ColorOutput Green "NW.js already present at $NWJS_EXTRACTED"
                Write-ColorOutput Green "✓ Architecture verified: $expectedArch"
                return
            } else {
                Write-ColorOutput Yellow "Warning: Existing NW.js may have wrong architecture, re-downloading..."
                Remove-Item $NWJS_EXTRACTED -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item $nwjsArchive -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    Write-Output "Downloading NW.js v$NWJS_VERSION ($NWJS_SUFFIX) from $NWJS_URL..."
    
    try {
        Invoke-WebRequest -Uri $NWJS_URL -OutFile $nwjsArchive -UseBasicParsing
        Write-Output "Extracting NW.js..."
        Expand-Archive -Path $nwjsArchive -DestinationPath $PROJECT_ROOT -Force
        Remove-Item $nwjsArchive -Force
        
        # Verify downloaded binary exists
        if (Test-Path $nwjsExe) {
            Write-ColorOutput Green "NW.js downloaded and extracted successfully!"
            Write-ColorOutput Green "✓ Architecture: $ARCH ($NWJS_SUFFIX)"
        } else {
            Write-ColorOutput Red "ERROR: NW.js binary not found after extraction!"
            throw "NW.js extraction failed"
        }
    }
    catch {
        Write-ColorOutput Red "Warning: Could not download NW.js automatically."
        Write-Output "You can download it manually from: $NWJS_URL"
        Write-Output "Extract it to: $NWJS_EXTRACTED"
        throw
    }
}

function Create-Package {
    Write-ColorOutput Yellow "Creating Windows package..."
    
    # Clean previous build
    if (Test-Path $BUILD_DIR) {
        Remove-Item $BUILD_DIR -Recurse -Force
    }
    New-Item -ItemType Directory -Path $PACKAGE_DIR -Force | Out-Null
    
    # Check NW.js
    if (-not (Test-Path $NWJS_EXTRACTED)) {
        Write-ColorOutput Red "Error: NW.js not found at $NWJS_EXTRACTED"
        exit 1
    }
    
    # Copy NW.js files
    Write-ColorOutput Yellow "Copying NW.js files..."
    $nwjsFiles = @(
        "nw.exe",
        "nw_100_percent.pak",
        "nw_200_percent.pak",
        "resources.pak",
        "icudtl.dat",
        "v8_context_snapshot.bin",
        "locales",
        "swiftshader"
    )
    
    foreach ($file in $nwjsFiles) {
        $source = Join-Path $NWJS_EXTRACTED $file
        $dest = Join-Path $PACKAGE_DIR $file
        if (Test-Path $source) {
            Copy-Item -Path $source -Destination $dest -Recurse -Force
        }
    }
    
    # Copy application files
    Write-ColorOutput Yellow "Copying application files..."
    $appFiles = @(
        "html",
        "js",
        "css",
        "xslt",
        "xsd",
        "plugins",
        "package.json"
    )
    
    foreach ($dir in $appFiles) {
        $source = Join-Path $PROJECT_ROOT $dir
        if (Test-Path $source) {
            Copy-Item -Path $source -Destination (Join-Path $PACKAGE_DIR $dir) -Recurse -Force
        }
    }
    
    # Copy launcher scripts
    Write-ColorOutput Yellow "Copying launcher scripts..."
    Copy-Item -Path (Join-Path $PROJECT_ROOT "bin\visual-page-editor.bat") -Destination (Join-Path $PACKAGE_DIR "visual-page-editor.bat") -Force
    Copy-Item -Path (Join-Path $PROJECT_ROOT "bin\visual-page-editor.ps1") -Destination (Join-Path $PACKAGE_DIR "visual-page-editor.ps1") -Force
    
    # Create a simple launcher that uses bundled NW.js
    $launcherContent = @"
@echo off
REM Launcher for Visual Page Editor (Windows portable)
setlocal

set "APP_DIR=%~dp0"
set "NWJS_EXE=%APP_DIR%nw.exe"

if not exist "%NWJS_EXE%" (
    echo Error: NW.js not found at %NWJS_EXE%
    pause
    exit /b 1
)

cd /d "%APP_DIR%"
"%NWJS_EXE%" "%APP_DIR%" %*
"@
    
    $launcherPath = Join-Path $PACKAGE_DIR "visual-page-editor-portable.bat"
    Set-Content -Path $launcherPath -Value $launcherContent
    
    # Create README
    $readmeContent = @"
Visual Page Editor - Windows Portable Package
Version: $VERSION
NW.js Version: $NWJS_VERSION

INSTALLATION:
=============
This is a portable package. No installation required!

Simply extract this folder to any location and run:
  visual-page-editor-portable.bat

Or use the standard launchers:
  visual-page-editor.bat (requires NW.js in PATH)
  visual-page-editor.ps1 (PowerShell version)

USAGE:
======
visual-page-editor-portable.bat [page.xml]+ [pages_dir]+ [--list pages_list]+ [--css file.css]+ [--js file.js]+

EXAMPLES:
=========
visual-page-editor-portable.bat examples\lorem.xml
visual-page-editor-portable.bat examples\*.xml

NOTES:
======
- This package includes NW.js, so no additional installation is needed
- All files are relative to this directory
- Logs are written to %TEMP%\visual-page-editor.log
"@
    
    Set-Content -Path (Join-Path $PACKAGE_DIR "README.txt") -Value $readmeContent
    
    Write-ColorOutput Green "Windows package created successfully!"
}

function Main {
    Write-ColorOutput Green "Building Windows package for Visual Page Editor"
    Write-Output "Version: $VERSION"
    Write-Output "NW.js Version: $NWJS_VERSION"
    Write-Output "Architecture: $ARCH ($NWJS_SUFFIX)"
    Write-Output ""
    
    Check-Requirements
    Download-NWJS
    Create-Package
    
    Write-Output ""
    Write-ColorOutput Green "Build complete!"
    Write-Output "The package is located at: $PACKAGE_DIR"
    Write-Output ""
    Write-Output "To create a ZIP archive (optional):"
    Write-Output "  Compress-Archive -Path `"$PACKAGE_DIR`" -DestinationPath `"$BUILD_DIR\visual-page-editor-${VERSION}-windows-${ARCH}.zip`" -Force"
}

# Run main function
Main
