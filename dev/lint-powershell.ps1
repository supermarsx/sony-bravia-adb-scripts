<#
.SYNOPSIS
  Lint PowerShell files with PSScriptAnalyzer

.DESCRIPTION
  Runs PSScriptAnalyzer on all PowerShell files in the project.
  Uses PSScriptAnalyzerSettings.psd1 for configuration.
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "=== Running PSScriptAnalyzer ===" -ForegroundColor Cyan
Write-Host ""

# Check if PSScriptAnalyzer is installed
$module = Get-Module -Name PSScriptAnalyzer -ListAvailable
if (-not $module) {
    Write-Host "PSScriptAnalyzer not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name PSScriptAnalyzer -Force -SkipPublisherCheck -Scope CurrentUser
    Write-Host ""
}

$scriptRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$settingsPath = Join-Path $PSScriptRoot "PSScriptAnalyzerSettings.psd1"

Write-Host "Analyzing PowerShell files..." -ForegroundColor Gray
Write-Host "Settings: $settingsPath" -ForegroundColor Gray
Write-Host ""

# Scan specific PowerShell files to avoid settings file causing issues
$filesToScan = @(
    (Join-Path $scriptRoot "sony-bravia-scripts.ps1"),
    (Join-Path $scriptRoot "sony-bravia-remote.ps1"),
    (Join-Path $scriptRoot "install.ps1")
) | Where-Object { Test-Path $_ }

# Add dev scripts
$filesToScan += Get-ChildItem -Path (Join-Path $scriptRoot "dev") -Filter "*.ps1" -Exclude "*Settings.psd1" | Select-Object -ExpandProperty FullName

# Add test scripts
$testPath = Join-Path $scriptRoot "tests"
if (Test-Path $testPath) {
    $filesToScan += Get-ChildItem -Path $testPath -Filter "*.ps1" | Select-Object -ExpandProperty FullName
}

$results = @()
foreach ($file in $filesToScan) {
    try {
        $fileResults = Invoke-ScriptAnalyzer -Path $file -Settings $settingsPath
        if ($fileResults) {
            $results += $fileResults
        }
    }
    catch {
        Write-Host "Warning: Failed to analyze $file : $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

if ($results) {
    Write-Host ""
    $results | Format-Table -AutoSize

    $errorCount = ($results | Where-Object { $_.Severity -eq 'Error' }).Count
    $warningCount = ($results | Where-Object { $_.Severity -eq 'Warning' }).Count
    $infoCount = ($results | Where-Object { $_.Severity -eq 'Information' }).Count

    Write-Host ""
    Write-Host "=== Summary ===" -ForegroundColor Cyan
    Write-Host "Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { 'Red' } else { 'Green' })
    Write-Host "Warnings: $warningCount" -ForegroundColor $(if ($warningCount -gt 0) { 'Yellow' } else { 'Green' })
    Write-Host "Information: $infoCount" -ForegroundColor Gray
    Write-Host ""

    if ($errorCount -gt 0) {
        Write-Host "✗ PSScriptAnalyzer found $errorCount error(s)" -ForegroundColor Red
        Write-Host ""
        exit 1
    }
    elseif ($warningCount -gt 0) {
        Write-Host "⚠ PSScriptAnalyzer found $warningCount warning(s)" -ForegroundColor Yellow
        Write-Host ""
        exit 0
    }
}

Write-Host "✓ No issues found by PSScriptAnalyzer" -ForegroundColor Green
Write-Host ""
exit 0
