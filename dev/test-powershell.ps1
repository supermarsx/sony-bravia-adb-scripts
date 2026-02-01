<#
.SYNOPSIS
  Run PowerShell tests with Pester

.DESCRIPTION
  Executes the Pester test suite for the Sony Bravia scripts.
  Outputs detailed results and creates test result XML.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('Minimal', 'Normal', 'Detailed', 'Diagnostic')]
    [string]$Verbosity = 'Detailed',

    [Parameter()]
    [switch]$CodeCoverage
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "=== Running Pester Tests ===" -ForegroundColor Cyan
Write-Host ""

# Check if Pester is installed
$module = Get-Module -Name Pester -ListAvailable | Where-Object { $_.Version -ge '5.0.0' }
if (-not $module) {
    Write-Host "Pester 5.x not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name Pester -MinimumVersion 5.0.0 -Force -SkipPublisherCheck -Scope CurrentUser
    Write-Host ""
}

$scriptRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$testsPath = Join-Path $scriptRoot "tests"

Write-Host "Running tests from: $testsPath" -ForegroundColor Gray
Write-Host "Verbosity: $Verbosity" -ForegroundColor Gray
if ($CodeCoverage) {
    Write-Host "Code coverage: Enabled" -ForegroundColor Gray
}
Write-Host ""

# Configure Pester
$config = New-PesterConfiguration
$config.Run.Path = $testsPath
$config.Run.Exit = $true
$config.Output.Verbosity = $Verbosity
$config.TestResult.Enabled = $true
$config.TestResult.OutputFormat = 'NUnitXml'
$config.TestResult.OutputPath = Join-Path $scriptRoot 'testResults.xml'

if ($CodeCoverage) {
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.Path = Join-Path $scriptRoot '*.ps1'
    $config.CodeCoverage.OutputPath = Join-Path $scriptRoot 'coverage.xml'
}

# Run tests
Write-Host "Starting tests..." -ForegroundColor Gray
Write-Host ""

try {
    $result = Invoke-Pester -Configuration $config
    
    Write-Host ""
    Write-Host "=== Test Summary ===" -ForegroundColor Cyan
    Write-Host "Total: $($result.TotalCount)" -ForegroundColor Gray
    Write-Host "Passed: $($result.PassedCount)" -ForegroundColor Green
    Write-Host "Failed: $($result.FailedCount)" -ForegroundColor $(if ($result.FailedCount -gt 0) { 'Red' } else { 'Green' })
    Write-Host "Skipped: $($result.SkippedCount)" -ForegroundColor Yellow
    Write-Host ""
    
    if ($result.FailedCount -gt 0) {
        Write-Host "✗ Tests failed" -ForegroundColor Red
        Write-Host ""
        exit 1
    }
    
    Write-Host "✓ All tests passed" -ForegroundColor Green
    Write-Host ""
    
    if ($CodeCoverage -and $result.CodeCoverage) {
        Write-Host "Code Coverage: $($result.CodeCoverage.CoveragePercent)%" -ForegroundColor Cyan
        Write-Host ""
    }
    
    exit 0
}
catch {
    Write-Host ""
    Write-Host "✗ Test execution failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    exit 1
}
