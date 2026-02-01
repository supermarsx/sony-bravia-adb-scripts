<#
.SYNOPSIS
  Package release artifacts

.DESCRIPTION
  Creates zip packages for distribution:
  - PowerShell package (Windows)
  - Unix package (macOS/Linux)
  - Complete package (all files + tests)
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "=== Creating Release Packages ===" -ForegroundColor Cyan
Write-Host ""

$scriptRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$distPath = Join-Path $scriptRoot "dist"

# Create dist directory
if (Test-Path $distPath) {
    Write-Host "Cleaning existing dist folder..." -ForegroundColor Gray
    Remove-Item $distPath -Recurse -Force
}
New-Item -ItemType Directory -Path $distPath | Out-Null

Write-Host "Output directory: $distPath" -ForegroundColor Gray
Write-Host ""

# Package 1: PowerShell package (Windows)
Write-Host "→ Creating PowerShell package..." -ForegroundColor Yellow
$psPackage = Join-Path $distPath "sony-bravia-scripts-powershell.zip"
Compress-Archive -Path @(
    (Join-Path $scriptRoot "sony-bravia-scripts.ps1"),
    (Join-Path $scriptRoot "sony-bravia-scripts.cmd"),
    (Join-Path $scriptRoot "readme.md"),
    (Join-Path $scriptRoot "license.md")
) -DestinationPath $psPackage -Force
Write-Host "  ✓ Created: sony-bravia-scripts-powershell.zip" -ForegroundColor Green

# Package 2: Unix package (macOS/Linux)
Write-Host "→ Creating Unix package..." -ForegroundColor Yellow
$unixPackage = Join-Path $distPath "sony-bravia-scripts-unix.zip"
Compress-Archive -Path @(
    (Join-Path $scriptRoot "sony-bravia-scripts.ps1"),
    (Join-Path $scriptRoot "sony-bravia-scripts.sh"),
    (Join-Path $scriptRoot "readme.md"),
    (Join-Path $scriptRoot "license.md")
) -DestinationPath $unixPackage -Force
Write-Host "  ✓ Created: sony-bravia-scripts-unix.zip" -ForegroundColor Green

# Package 3: Complete package (all files)
Write-Host "→ Creating complete package..." -ForegroundColor Yellow
$completePackage = Join-Path $distPath "sony-bravia-scripts-complete.zip"
Compress-Archive -Path @(
    (Join-Path $scriptRoot "sony-bravia-scripts.ps1"),
    (Join-Path $scriptRoot "sony-bravia-scripts.cmd"),
    (Join-Path $scriptRoot "sony-bravia-scripts.sh"),
    (Join-Path $scriptRoot "readme.md"),
    (Join-Path $scriptRoot "license.md"),
    (Join-Path $scriptRoot "PSScriptAnalyzerSettings.psd1"),
    (Join-Path $scriptRoot ".shellcheckrc"),
    (Join-Path $scriptRoot ".editorconfig"),
    (Join-Path $scriptRoot "tests")
) -DestinationPath $completePackage -Force
Write-Host "  ✓ Created: sony-bravia-scripts-complete.zip" -ForegroundColor Green

Write-Host ""
Write-Host "=== Package Information ===" -ForegroundColor Cyan
Write-Host ""

Get-ChildItem $distPath -Filter "*.zip" | ForEach-Object {
    $sizeKB = [math]::Round($_.Length / 1KB, 2)
    $sizeMB = [math]::Round($_.Length / 1MB, 2)
    $sizeStr = if ($sizeMB -gt 1) { "$sizeMB MB" } else { "$sizeKB KB" }
    
    Write-Host "  $($_.Name)" -ForegroundColor White
    Write-Host "    Size: $sizeStr" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Packages created in: $distPath" -ForegroundColor Gray
Write-Host ""
Write-Host "✓ Packaging complete" -ForegroundColor Green
Write-Host ""
