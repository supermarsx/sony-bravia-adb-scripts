<#
.SYNOPSIS
  Run all CI checks locally

.DESCRIPTION
  Executes all CI pipeline steps in sequence:
  1. Format checks (PowerShell and Shell)
  2. Lint checks (PowerShell and Shell)
  3. Tests (PowerShell and Shell)
  4. Package (if all checks pass)

  This mimics the GitHub Actions CI pipeline.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$SkipFormat,

    [Parameter()]
    [switch]$SkipLint,

    [Parameter()]
    [switch]$SkipTests,

    [Parameter()]
    [switch]$SkipPackage,

    [Parameter()]
    [switch]$Fast
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$devPath = $PSScriptRoot
$failed = $false

function Invoke-Step {
    param(
        [string]$Name,
        [string]$Script,
        [switch]$IsShell
    )

    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor DarkGray
    Write-Host "  $Name" -ForegroundColor Cyan
    Write-Host ("=" * 80) -ForegroundColor DarkGray
    Write-Host ""

    $startTime = Get-Date

    try {
        if ($IsShell) {
            # Run shell script
            if ($IsWindows) {
                Write-Host "⚠ Skipping shell script on Windows (run in WSL or Git Bash)" -ForegroundColor Yellow
                return $true
            }
            bash $Script
        }
        else {
            # Run PowerShell script
            & $Script
        }

        $exitCode = $LASTEXITCODE
        $duration = (Get-Date) - $startTime

        Write-Host ""
        Write-Host "  Completed in $($duration.TotalSeconds.ToString('0.00'))s" -ForegroundColor Gray

        if ($exitCode -eq 0) {
            return $true
        }
        else {
            $script:failed = $true
            return $false
        }
    }
    catch {
        $duration = (Get-Date) - $startTime
        Write-Host ""
        Write-Host "  Failed after $($duration.TotalSeconds.ToString('0.00'))s" -ForegroundColor Gray
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        $script:failed = $true
        return $false
    }
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Sony Bravia Scripts - CI Pipeline (Local)                        ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$startTotal = Get-Date

# Phase 1: Format Checks
if (-not $SkipFormat) {
    Write-Host "PHASE 1: FORMAT CHECKS" -ForegroundColor Magenta
    Write-Host ""

    $formatPs = Invoke-Step -Name "Format PowerShell" -Script (Join-Path $devPath "format-powershell.ps1")

    if (-not $Fast) {
        $formatSh = Invoke-Step -Name "Format Shell" -Script (Join-Path $devPath "format-shell.sh") -IsShell
    }
}
else {
    Write-Host "PHASE 1: FORMAT CHECKS - SKIPPED" -ForegroundColor Yellow
}

# Phase 2: Lint Checks
if (-not $SkipLint -and -not $failed) {
    Write-Host ""
    Write-Host "PHASE 2: LINT CHECKS" -ForegroundColor Magenta
    Write-Host ""

    $lintPs = Invoke-Step -Name "Lint PowerShell" -Script (Join-Path $devPath "lint-powershell.ps1")

    if (-not $Fast) {
        $lintSh = Invoke-Step -Name "Lint Shell" -Script (Join-Path $devPath "lint-shell.sh") -IsShell
    }
}
else {
    if ($SkipLint) {
        Write-Host ""
        Write-Host "PHASE 2: LINT CHECKS - SKIPPED" -ForegroundColor Yellow
    }
}

# Phase 3: Tests
if (-not $SkipTests -and -not $failed) {
    Write-Host ""
    Write-Host "PHASE 3: TESTS" -ForegroundColor Magenta
    Write-Host ""

    $testPs = Invoke-Step -Name "Test PowerShell" -Script (Join-Path $devPath "test-powershell.ps1")

    if (-not $Fast) {
        $testSh = Invoke-Step -Name "Test Shell" -Script (Join-Path $devPath "test-shell.sh") -IsShell
    }
}
else {
    if ($SkipTests) {
        Write-Host ""
        Write-Host "PHASE 3: TESTS - SKIPPED" -ForegroundColor Yellow
    }
}

# Phase 4: Package
if (-not $SkipPackage -and -not $failed) {
    Write-Host ""
    Write-Host "PHASE 4: PACKAGE" -ForegroundColor Magenta
    Write-Host ""

    $package = Invoke-Step -Name "Create Packages" -Script (Join-Path $devPath "package.ps1")
}
else {
    if ($SkipPackage) {
        Write-Host ""
        Write-Host "PHASE 4: PACKAGE - SKIPPED" -ForegroundColor Yellow
    }
    elseif ($failed) {
        Write-Host ""
        Write-Host "PHASE 4: PACKAGE - SKIPPED (previous failures)" -ForegroundColor Red
    }
}

# Summary
$durationTotal = (Get-Date) - $startTotal

Write-Host ""
Write-Host ("=" * 80) -ForegroundColor DarkGray
Write-Host ""
Write-Host "  CI PIPELINE SUMMARY" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Total Duration: $($durationTotal.TotalSeconds.ToString('0.00'))s" -ForegroundColor Gray
Write-Host ""

if ($failed) {
    Write-Host "  ✗ FAILED - Some checks did not pass" -ForegroundColor Red
    Write-Host ""
    exit 1
}
else {
    Write-Host "  ✓ SUCCESS - All checks passed!" -ForegroundColor Green
    Write-Host ""
    exit 0
}
