# Download portable Node.js into .tools\ if needed, then npm install.
# Usage: .\scripts\bootstrap-node.ps1 [-Start]
param([switch]$Start)

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $Root

$NodeVer = if ($env:NODE_BOOTSTRAP_VERSION) { $env:NODE_BOOTSTRAP_VERSION } else { "20.18.0" }

function Test-GoodNode {
    $n = Get-Command node -ErrorAction SilentlyContinue
    if (-not $n) { return $false }
    try {
        $maj = [int]((node -p "process.versions.node.split('.')[0]") -as [int])
        return $maj -ge 18
    } catch { return $false }
}

function Ensure-PortableNode {
    if (Test-GoodNode) {
        Write-Host "Using existing Node.js: $(Get-Command node | Select-Object -ExpandProperty Source) ($(node -v))"
        return
    }

    $arch = $env:PROCESSOR_ARCHITECTURE
    $plat = "win"
    $suffix = "x64"
    if ($arch -eq "ARM64") { $suffix = "arm64" }

    $extractName = "node-v$NodeVer-$plat-$suffix"
    $dest = Join-Path $Root ".tools\$extractName"
    $zipName = "$extractName.zip"
    $url = "https://nodejs.org/dist/v$NodeVer/$zipName"

    New-Item -ItemType Directory -Force -Path (Join-Path $Root ".tools") | Out-Null

    if (Test-Path (Join-Path $dest "node.exe")) {
        Write-Host "Using cached portable Node.js: $dest"
        $env:PATH = "$dest;$env:PATH"
        return
    }

    Write-Host "Downloading Node.js $NodeVer for $plat-$suffix..." -ForegroundColor Yellow
    Write-Host "  $url"

    $tmp = Join-Path $Root ".tools\$zipName"
    Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing
    if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
    Expand-Archive -Path $tmp -DestinationPath (Join-Path $Root ".tools") -Force
    Remove-Item $tmp -Force

    if (-not (Test-Path (Join-Path $dest "node.exe"))) {
        Write-Error "Extract failed: expected $dest\node.exe"
    }

    $env:PATH = "$dest;$env:PATH"
    Write-Host "Portable Node.js ready: $dest" -ForegroundColor Green
}

Ensure-PortableNode

npm install
if ($Start) {
    npm start
} else {
    Write-Host ""
    Write-Host "Dependencies installed. Start with: npm start   or   .\bin\visual-page-editor.ps1"
}
