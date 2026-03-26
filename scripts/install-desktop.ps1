# One-shot desktop setup: Node (if needed) + npm install + verify NW.js (npm package nw).
# Usage: .\scripts\install-desktop.ps1 [-Start]
param([switch]$Start)

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $Root

Write-Host "==> Installing dependencies and NW.js (npm package nw)..."
& (Join-Path $Root "scripts\bootstrap-node.ps1")

$nwBin = Join-Path $Root "node_modules\.bin\nw.cmd"
$nwCli = Join-Path $Root "node_modules\nw\package.json"
if (-not (Test-Path $nwBin) -and -not (Test-Path $nwCli)) {
    Write-Error "node_modules nw package missing. Try: Remove-Item -Recurse -Force node_modules; .\scripts\install-desktop.ps1"
}
Write-Host "==> NW.js OK: local SDK via npm."

if ($Start) {
    Write-Host "==> Starting app..."
    npm start
} else {
    Write-Host ""
    Write-Host "Install complete. Run: npm start   or   .\bin\visual-page-editor.ps1"
}
