<#
.SYNOPSIS
    Installation script for Sony Bravia ADB Scripts (Windows)

.DESCRIPTION
    Automatically installs dependencies (ADB, PowerShell 7+) and configures the environment
    for Sony Bravia ADB Scripts on Windows.

.EXAMPLE
    .\install.ps1
    
.EXAMPLE
    .\install.ps1 -InstallPath "C:\Tools\sony-bravia"
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$InstallPath = "$env:LOCALAPPDATA\Programs\sony-bravia-scripts",
    
    [Parameter()]
    [switch]$SkipAdb,
    
    [Parameter()]
    [switch]$SkipPowerShell
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:LogFile = Join-Path $env:TEMP "sony-bravia-install.log"

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $script:LogFile -Value $logEntry
    
    $color = switch ($Level) {
        'Info' { 'White' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        'Success' { 'Green' }
    }
    
    Write-Host $Message -ForegroundColor $color
}

function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-CommandExists {
    param([string]$Command)
    
    try {
        if (Get-Command $Command -ErrorAction SilentlyContinue) {
            return $true
        }
        return $false
    }
    catch {
        return $false
    }
}

function Install-Adb {
    Write-Log "Checking for ADB installation..." -Level Info
    
    if (Test-CommandExists 'adb') {
        $adbVersion = & adb version 2>&1 | Select-Object -First 1
        Write-Log "ADB already installed: $adbVersion" -Level Success
        return $true
    }
    
    Write-Log "ADB not found. Checking for platform-tools..." -Level Warning
    
    # Check for Chocolatey
    if (Test-CommandExists 'choco') {
        Write-Log "Installing ADB via Chocolatey..." -Level Info
        try {
            choco install adb -y
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            
            if (Test-CommandExists 'adb') {
                Write-Log "ADB installed successfully via Chocolatey" -Level Success
                return $true
            }
        }
        catch {
            Write-Log "Chocolatey installation failed: $($_.Exception.Message)" -Level Warning
        }
    }
    
    # Manual download
    Write-Log "Downloading platform-tools from Google..." -Level Info
    $platformToolsUrl = "https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
    $downloadPath = Join-Path $env:TEMP "platform-tools.zip"
    $extractPath = Join-Path $InstallPath "platform-tools"
    
    try {
        # Download
        Write-Log "Downloading from $platformToolsUrl..." -Level Info
        Invoke-WebRequest -Uri $platformToolsUrl -OutFile $downloadPath -UseBasicParsing
        
        # Extract
        Write-Log "Extracting to $extractPath..." -Level Info
        if (Test-Path $extractPath) {
            Remove-Item $extractPath -Recurse -Force
        }
        Expand-Archive -Path $downloadPath -DestinationPath $InstallPath -Force
        
        # Add to PATH
        $adbPath = Join-Path $extractPath "adb.exe"
        if (Test-Path $adbPath) {
            Write-Log "Adding platform-tools to PATH..." -Level Info
            
            $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
            if ($userPath -notlike "*$extractPath*") {
                [Environment]::SetEnvironmentVariable("Path", "$userPath;$extractPath", "User")
                $env:Path += ";$extractPath"
            }
            
            Write-Log "ADB installed successfully at: $extractPath" -Level Success
            return $true
        }
        
        Write-Log "ADB executable not found after extraction" -Level Error
        return $false
    }
    catch {
        Write-Log "Failed to download/install ADB: $($_.Exception.Message)" -Level Error
        return $false
    }
    finally {
        if (Test-Path $downloadPath) {
            Remove-Item $downloadPath -Force
        }
    }
}

function Install-PowerShell7 {
    Write-Log "Checking PowerShell version..." -Level Info
    
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        Write-Log "PowerShell $($PSVersionTable.PSVersion) is already installed" -Level Success
        return $true
    }
    
    Write-Log "PowerShell 7+ is recommended for best compatibility" -Level Warning
    Write-Log "Current version: PowerShell $($PSVersionTable.PSVersion)" -Level Info
    
    $response = Read-Host "Install PowerShell 7? (Y/N)"
    if ($response -notmatch '^[Yy]') {
        Write-Log "Skipping PowerShell 7 installation" -Level Warning
        return $false
    }
    
    # Check for winget
    if (Test-CommandExists 'winget') {
        Write-Log "Installing PowerShell 7 via winget..." -Level Info
        try {
            winget install --id Microsoft.PowerShell --source winget --silent
            Write-Log "PowerShell 7 installed successfully" -Level Success
            Write-Log "Please restart your terminal to use PowerShell 7" -Level Warning
            return $true
        }
        catch {
            Write-Log "winget installation failed: $($_.Exception.Message)" -Level Warning
        }
    }
    
    # Check for Chocolatey
    if (Test-CommandExists 'choco') {
        Write-Log "Installing PowerShell 7 via Chocolatey..." -Level Info
        try {
            choco install powershell-core -y
            Write-Log "PowerShell 7 installed successfully" -Level Success
            Write-Log "Please restart your terminal to use PowerShell 7" -Level Warning
            return $true
        }
        catch {
            Write-Log "Chocolatey installation failed: $($_.Exception.Message)" -Level Warning
        }
    }
    
    # Manual install
    Write-Log "Please install PowerShell 7 manually from:" -Level Info
    Write-Log "https://github.com/PowerShell/PowerShell/releases" -Level Info
    return $false
}

function Install-Scripts {
    Write-Log "Installing Sony Bravia ADB Scripts..." -Level Info
    
    $scriptDir = $PSScriptRoot
    
    if (-not (Test-Path $InstallPath)) {
        New-Item -Path $InstallPath -ItemType Directory -Force | Out-Null
    }
    
    # Copy main script
    $mainScript = Join-Path $scriptDir "sony-bravia-scripts.ps1"
    if (Test-Path $mainScript) {
        Copy-Item $mainScript -Destination $InstallPath -Force
        Write-Log "Copied main script to $InstallPath" -Level Success
    }
    else {
        Write-Log "Main script not found: $mainScript" -Level Error
        return $false
    }
    
    # Copy launcher
    $launcher = Join-Path $scriptDir "sony-bravia-scripts.cmd"
    if (Test-Path $launcher) {
        Copy-Item $launcher -Destination $InstallPath -Force
        Write-Log "Copied launcher to $InstallPath" -Level Success
    }
    
    # Copy documentation
    $readme = Join-Path $scriptDir "readme.md"
    if (Test-Path $readme) {
        Copy-Item $readme -Destination $InstallPath -Force
    }
    
    # Create desktop shortcut
    $response = Read-Host "Create desktop shortcut? (Y/N)"
    if ($response -match '^[Yy]') {
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = Join-Path $desktopPath "Sony Bravia Scripts.lnk"
        
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = Join-Path $InstallPath "sony-bravia-scripts.cmd"
        $shortcut.WorkingDirectory = $InstallPath
        $shortcut.Description = "Sony Bravia TV ADB Control Scripts"
        $shortcut.Save()
        
        Write-Log "Desktop shortcut created" -Level Success
    }
    
    # Add to PATH
    $response = Read-Host "Add installation directory to PATH? (Y/N)"
    if ($response -match '^[Yy]') {
        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($userPath -notlike "*$InstallPath*") {
            [Environment]::SetEnvironmentVariable("Path", "$userPath;$InstallPath", "User")
            $env:Path += ";$InstallPath"
            Write-Log "Added to PATH: $InstallPath" -Level Success
        }
        else {
            Write-Log "Already in PATH: $InstallPath" -Level Info
        }
    }
    
    return $true
}

function Show-Summary {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  Sony Bravia ADB Scripts - Installation  " -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Installation Path: $InstallPath" -ForegroundColor Green
    Write-Host "Log File: $script:LogFile" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Enable USB Debugging on your Sony Bravia TV:" -ForegroundColor White
    Write-Host "     Settings > Network & Internet > Home Network Setup > " -ForegroundColor Gray
    Write-Host "     IP Control > Authentication > Normal and Pre-Shared Key" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  2. Find your TV's IP address:" -ForegroundColor White
    Write-Host "     Settings > Network & Internet > Advanced Settings > Network Status" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  3. Connect via ADB:" -ForegroundColor White
    Write-Host "     adb connect <tv-ip>:5555" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  4. Run the script:" -ForegroundColor White
    Write-Host "     sony-bravia-scripts.cmd   (or double-click desktop shortcut)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Documentation: $InstallPath\readme.md" -ForegroundColor Cyan
    Write-Host ""
}

# Main installation flow
try {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  Sony Bravia ADB Scripts - Installer" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This installer will:" -ForegroundColor White
    Write-Host "  - Check/install ADB (Android Debug Bridge)" -ForegroundColor Gray
    Write-Host "  - Check/install PowerShell 7+ (optional)" -ForegroundColor Gray
    Write-Host "  - Install Sony Bravia scripts to: $InstallPath" -ForegroundColor Gray
    Write-Host ""
    
    $response = Read-Host "Continue? (Y/N)"
    if ($response -notmatch '^[Yy]') {
        Write-Log "Installation cancelled by user" -Level Warning
        exit 0
    }
    
    Write-Host ""
    
    # Install ADB
    if (-not $SkipAdb) {
        if (-not (Install-Adb)) {
            Write-Log "ADB installation failed. Please install manually." -Level Error
            exit 1
        }
    }
    
    # Install PowerShell 7
    if (-not $SkipPowerShell) {
        Install-PowerShell7 | Out-Null
    }
    
    # Install scripts
    if (-not (Install-Scripts)) {
        Write-Log "Script installation failed" -Level Error
        exit 1
    }
    
    Show-Summary
    
    Write-Host ""
    Write-Host "Installation completed successfully!" -ForegroundColor Green
    Write-Host ""
    
    Pause
    exit 0
}
catch {
    Write-Log "Installation failed: $($_.Exception.Message)" -Level Error
    Write-Log "See log file for details: $script:LogFile" -Level Error
    exit 1
}
