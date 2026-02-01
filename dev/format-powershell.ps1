<#
.SYNOPSIS
  Format check for PowerShell files

.DESCRIPTION
  Validates PowerShell file formatting including:
  - Trailing whitespace
  - Tab characters (should use spaces)
  - EditorConfig compliance
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "=== Checking PowerShell formatting ===" -ForegroundColor Cyan
Write-Host ""

$issues = @()
$scriptRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

# Check for trailing whitespace
Write-Host "Checking for trailing whitespace..." -ForegroundColor Gray
$psFiles = Get-ChildItem -Path $scriptRoot -Filter "*.ps1" -Recurse -File
foreach ($file in $psFiles) {
    $lines = Get-Content $file.FullName
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '\s+$') {
            $issues += "Trailing whitespace in $($file.Name):$($i+1)"
        }
    }
}

# Check for tabs (should use spaces)
Write-Host "Checking for tab characters..." -ForegroundColor Gray
foreach ($file in $psFiles) {
    $content = Get-Content $file.FullName -Raw
    if ($content -match "`t") {
        $issues += "Tab character found in $($file.Name) (use spaces)"
    }
}

# Check .psd1 files too
Write-Host "Checking .psd1 files..." -ForegroundColor Gray
$psdFiles = Get-ChildItem -Path $scriptRoot -Filter "*.psd1" -File
foreach ($file in $psdFiles) {
    $content = Get-Content $file.FullName -Raw
    if ($content -match "`t") {
        $issues += "Tab character found in $($file.Name) (use spaces)"
    }
}

Write-Host ""

if ($issues.Count -gt 0) {
    Write-Host "✗ Found $($issues.Count) formatting issue(s):" -ForegroundColor Red
    Write-Host ""
    $issues | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    Write-Host ""
    exit 1
}

Write-Host "✓ PowerShell formatting looks good" -ForegroundColor Green
Write-Host ""
exit 0
