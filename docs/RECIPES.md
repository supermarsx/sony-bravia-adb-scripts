# Recipes

This document provides practical examples and workflows for using Sony Bravia ADB Scripts.

## Table of Contents

- [Basic Operations](#basic-operations)
- [Connection Management](#connection-management)
- [Content Navigation](#content-navigation)
- [App Management](#app-management)
- [Media Control](#media-control)
- [System Management](#system-management)
- [Automation](#automation)
- [Advanced Workflows](#advanced-workflows)

## Basic Operations

### First-time setup

```powershell
# 1. Install dependencies
.\install.ps1

# 2. Find TV IP address
# On TV: Settings > Network & Internet > Advanced Settings > Network Status

# 3. Enable USB debugging
# On TV: Settings > Network & Internet > Home Network Setup > IP Control
# Set Authentication to "Normal and Pre-Shared Key"

# 4. Connect to TV
adb connect 192.168.1.100:5555

# 5. Run script
.\sony-bravia-scripts.cmd

# 6. Set default serial
sony-bravia-scripts.ps1 -Action a1
# Config will be created at ~/.sony-bravia-scripts/config.json
# Edit to set defaultSerial
```

### Quick TV control

```powershell
# Launch script in interactive mode
.\sony-bravia-scripts.cmd

# Or use CLI for specific actions
sony-bravia-scripts.ps1 -Action a1  # Home
sony-bravia-scripts.ps1 -Action a2  # Back
sony-bravia-scripts.ps1 -Action f11 # Volume up
sony-bravia-scripts.ps1 -Action f12 # Volume down
```

### Daily workflow

```powershell
# Morning routine: Turn on TV and launch news
sony-bravia-scripts.ps1 -Action "a1,g5"  # Home, launch YouTube

# Evening: Launch streaming service
sony-bravia-scripts.ps1 -Action "a1,g1"  # Home, launch Netflix

# Night: Mute and sleep timer
sony-bravia-scripts.ps1 -Action "f14,h7"  # Mute, enable sleep mode
```

## Connection Management

### Connect to TV

```powershell
# Basic connection
adb connect 192.168.1.100:5555

# With script connection check
sony-bravia-scripts.ps1 -CheckConnection

# Auto-retry connection
sony-bravia-scripts.ps1 -Action a1 -CheckConnection
```

### Multi-TV environment

```powershell
# List all connected devices
adb devices

# Connect to specific TV
adb connect 192.168.1.100:5555  # Living room
adb connect 192.168.1.101:5555  # Bedroom

# Run command on specific TV
sony-bravia-scripts.ps1 -Action a1 -Serial 192.168.1.100:5555

# Batch command to multiple TVs
@("192.168.1.100:5555", "192.168.1.101:5555") | ForEach-Object {
    sony-bravia-scripts.ps1 -Action f14 -Serial $_ -Quiet
}
# Mutes both TVs
```

### Persistent connection

```powershell
# Keep connection alive script
while ($true) {
    $devices = adb devices | Select-String "device$"
    if ($devices.Count -eq 0) {
        Write-Host "Reconnecting..."
        adb connect 192.168.1.100:5555
    }
    Start-Sleep -Seconds 30
}
```

## Content Navigation

### Navigate home screen

```powershell
# Go to home and navigate apps
sony-bravia-scripts.ps1 -Action a1   # Home
sony-bravia-scripts.ps1 -Action a7   # Right
sony-bravia-scripts.ps1 -Action a5   # Down
sony-bravia-scripts.ps1 -Action a9   # Select/OK

# Quick grid navigation
$moves = @("a7", "a7", "a5", "a9")  # Right, Right, Down, Select
$moves | ForEach-Object {
    sony-bravia-scripts.ps1 -Action $_ -Quiet
    Start-Sleep -Milliseconds 200
}
```

### Search for content

```powershell
# Open search
sony-bravia-scripts.ps1 -Action b14

# Type search query (requires manual typing via TUI)
# Or use input text action
$query = "Breaking Bad"
$query.ToCharArray() | ForEach-Object {
    adb shell input text $_
    Start-Sleep -Milliseconds 100
}

# Select first result
sony-bravia-scripts.ps1 -Action a9  # OK
```

### Access settings quickly

```powershell
# Open settings submenu
sony-bravia-scripts.ps1 -Action a1   # Home
Start-Sleep -Seconds 1
sony-bravia-scripts.ps1 -Action d1   # Settings

# Navigate to specific setting
# Network settings
sony-bravia-scripts.ps1 -Action "a1,d1,a5,a5,a9"  # Home > Settings > Down x2 > Select

# Display settings
sony-bravia-scripts.ps1 -Action "a1,d1,a5,a5,a5,a9"
```

## App Management

### Launch streaming apps

```powershell
# Launch Netflix
sony-bravia-scripts.ps1 -Action g1

# Launch YouTube
sony-bravia-scripts.ps1 -Action g5

# Launch Prime Video
sony-bravia-scripts.ps1 -Action g2

# Launch Disney+
sony-bravia-scripts.ps1 -Action g3

# Launch Spotify
sony-bravia-scripts.ps1 -Action g4
```

### App switching workflow

```powershell
# Quick app switcher
sony-bravia-scripts.ps1 -Action b13  # Recent apps

# Cycle through apps
1..3 | ForEach-Object {
    sony-bravia-scripts.ps1 -Action b13 -Quiet
    Start-Sleep -Seconds 1
    sony-bravia-scripts.ps1 -Action a9 -Quiet  # Select
}
```

### Install app from Play Store

```powershell
# Open Play Store
sony-bravia-scripts.ps1 -Action a1   # Home
# Navigate to Play Store manually or:
# Search and install via adb
adb shell am start -a android.intent.action.VIEW -d "market://details?id=com.app.package"
```

### Manage installed apps

```powershell
# List installed apps
adb shell pm list packages | Sort-Object

# Launch specific app by package name
adb shell monkey -p com.netflix.ninja -c android.intent.category.LAUNCHER 1

# Force stop app
adb shell am force-stop com.netflix.ninja

# Clear app data
adb shell pm clear com.netflix.ninja

# Uninstall app
adb shell pm uninstall com.app.package
```

## Media Control

### Video playback control

```powershell
# Play/Pause
sony-bravia-scripts.ps1 -Action e1

# Fast forward
sony-bravia-scripts.ps1 -Action e3

# Rewind
sony-bravia-scripts.ps1 -Action e2

# Next/Previous
sony-bravia-scripts.ps1 -Action e5  # Next
sony-bravia-scripts.ps1 -Action e6  # Previous

# Stop
sony-bravia-scripts.ps1 -Action e7
```

### Audio control

```powershell
# Volume up/down
sony-bravia-scripts.ps1 -Action f11  # Up
sony-bravia-scripts.ps1 -Action f12  # Down

# Mute/Unmute
sony-bravia-scripts.ps1 -Action f14

# Set specific volume level (indirect)
# Mute first, then volume up N times
sony-bravia-scripts.ps1 -Action f14 -Quiet  # Mute
1..10 | ForEach-Object {
    sony-bravia-scripts.ps1 -Action f11 -Quiet
    Start-Sleep -Milliseconds 100
}
```

### Screen capture

```powershell
# Take screenshot
sony-bravia-scripts.ps1 -Action j1

# Screenshot saved on TV, pull to PC
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
adb pull /sdcard/screenshot.png "screenshot_${timestamp}.png"

# Record screen
sony-bravia-scripts.ps1 -Action j3  # Start recording
# Perform actions...
# Stop manually via ADB
adb shell pkill -SIGINT screenrecord
adb pull /sdcard/screenrecord.mp4 "recording_${timestamp}.mp4"
```

## System Management

### Power management

```powershell
# Reboot TV
sony-bravia-scripts.ps1 -Action h1

# Power off
sony-bravia-scripts.ps1 -Action h2

# Sleep mode
sony-bravia-scripts.ps1 -Action h7

# Wake TV (if supported)
# Use WoL (Wake-on-LAN) if configured
# Or reconnect ADB
adb connect 192.168.1.100:5555
```

### System updates

```powershell
# Check for system updates
sony-bravia-scripts.ps1 -Action h5

# View system info
sony-bravia-scripts.ps1 -Action i1

# Check Android version
adb shell getprop ro.build.version.release

# Check TV model
adb shell getprop ro.product.model
```

### Network management

```powershell
# Open network settings
sony-bravia-scripts.ps1 -Action d8

# Check network status
adb shell dumpsys connectivity | Select-String "NetworkAgentInfo"

# Test internet connectivity
adb shell ping -c 4 8.8.8.8

# Get IP address
adb shell ip addr show wlan0
```

## Automation

### Scheduled tasks

**Windows Task Scheduler:**

```powershell
# Create task to mute TV at 11 PM
$action = New-ScheduledTaskAction -Execute "pwsh" -Argument "-File C:\Path\To\sony-bravia-scripts.ps1 -Action f14 -Quiet"
$trigger = New-ScheduledTaskTrigger -Daily -At "11:00PM"
Register-ScheduledTask -TaskName "Mute TV Nightly" -Action $action -Trigger $trigger
```

**macOS/Linux Cron:**

```bash
# Crontab entry: Mute TV at 11 PM daily
0 23 * * * /usr/local/bin/pwsh /path/to/sony-bravia-scripts.ps1 -Action f14 -Quiet

# Turn on TV and launch YouTube at 7 AM weekdays
0 7 * * 1-5 /usr/bin/adb connect 192.168.1.100:5555 && /usr/local/bin/pwsh /path/to/sony-bravia-scripts.ps1 -Action "a1,g5" -Quiet
```

### Batch operations

Create `actions.txt`:
```
# Morning routine
a1    # Home
g5    # YouTube
f11   # Volume up
f11   # Volume up
```

Execute:
```powershell
sony-bravia-scripts.ps1 -Batch actions.txt
```

### Conditional automation

```powershell
# Auto-mute if TV volume too high
$currentHour = (Get-Date).Hour
if ($currentHour -ge 22 -or $currentHour -lt 7) {
    Write-Host "Quiet hours - ensuring TV is muted"
    sony-bravia-scripts.ps1 -Action f14 -Quiet
}

# Launch news in the morning
if ($currentHour -ge 6 -and $currentHour -lt 9) {
    Write-Host "Morning - launching news"
    sony-bravia-scripts.ps1 -Action "a1,g5" -Quiet  # YouTube
}
```

### Integration with Home Assistant

```yaml
# configuration.yaml
shell_command:
  tv_home: "pwsh /path/to/sony-bravia-scripts.ps1 -Action a1 -Quiet"
  tv_netflix: "pwsh /path/to/sony-bravia-scripts.ps1 -Action g1 -Quiet"
  tv_volume_up: "pwsh /path/to/sony-bravia-scripts.ps1 -Action f11 -Quiet"
  tv_volume_down: "pwsh /path/to/sony-bravia-scripts.ps1 -Action f12 -Quiet"
  tv_mute: "pwsh /path/to/sony-bravia-scripts.ps1 -Action f14 -Quiet"

automation:
  - alias: "TV Mute at Night"
    trigger:
      platform: time
      at: "23:00:00"
    action:
      service: shell_command.tv_mute
```

## Advanced Workflows

### Programmatic control

```powershell
# Function to navigate TV menu
function Navigate-TvMenu {
    param(
        [string[]]$Path,
        [int]$DelayMs = 300
    )
    
    sony-bravia-scripts.ps1 -Action a1 -Quiet  # Home
    Start-Sleep -Milliseconds $DelayMs
    
    foreach ($step in $Path) {
        sony-bravia-scripts.ps1 -Action $step -Quiet
        Start-Sleep -Milliseconds $DelayMs
    }
}

# Navigate to network settings
Navigate-TvMenu -Path @("d1", "a5", "a5", "a9")
```

### JSON output for scripting

```powershell
# Get action results as JSON
$result = sony-bravia-scripts.ps1 -Action a1 -OutputFormat JSON | ConvertFrom-Json

if ($result.success) {
    Write-Host "Command succeeded"
} else {
    Write-Error "Command failed: $($result.error)"
}

# Batch with JSON output
$results = sony-bravia-scripts.ps1 -Action "a1,a2,a3" -OutputFormat JSON | ConvertFrom-Json

$results | Where-Object { -not $_.Success } | ForEach-Object {
    Write-Warning "Failed action: $($_.Action) - $($_.Error)"
}
```

### CSV export for analysis

```powershell
# Run batch and export results
sony-bravia-scripts.ps1 -Batch actions.txt -OutputFormat CSV | Out-File results.csv

# Analyze results
$results = Import-Csv results.csv
$successRate = ($results | Where-Object Success -eq $true).Count / $results.Count * 100
Write-Host "Success rate: ${successRate}%"
```

### Command history analysis

```powershell
# View command history
$history = Get-Content ~/.sony-bravia-scripts/history.json | ConvertFrom-Json

# Most used actions
$history | Group-Object Action | Sort-Object Count -Descending | Select-Object -First 10

# Recent failures
$history | Where-Object { -not $_.Success } | Select-Object -Last 10

# Success rate by action
$history | Group-Object Action | ForEach-Object {
    $successCount = ($_.Group | Where-Object Success).Count
    [PSCustomObject]@{
        Action = $_.Name
        SuccessRate = [math]::Round($successCount / $_.Count * 100, 2)
    }
} | Sort-Object SuccessRate
```

### Remote control server

```powershell
# Simple HTTP server for TV control
# Install: Install-Module -Name Pode
Import-Module Pode

Start-PodeServer {
    Add-PodeEndpoint -Address localhost -Port 8080 -Protocol Http
    
    Add-PodeRoute -Method Get -Path '/tv/:action' -ScriptBlock {
        param($WebEvent)
        
        $action = $WebEvent.Parameters['action']
        
        try {
            sony-bravia-scripts.ps1 -Action $action -Quiet
            Write-PodeJsonResponse -Value @{ success = $true; action = $action }
        }
        catch {
            Write-PodeJsonResponse -Value @{ success = $false; error = $_.Exception.Message } -StatusCode 500
        }
    }
}

# Use with curl:
# curl http://localhost:8080/tv/a1  # Home
# curl http://localhost:8080/tv/f11 # Volume up
```

### Voice control integration

```powershell
# Example with Windows Speech Recognition
Add-Type -AssemblyName System.Speech
$recognizer = New-Object System.Speech.Recognition.SpeechRecognitionEngine

$grammar = New-Object System.Speech.Recognition.DictationGrammar
$recognizer.LoadGrammar($grammar)

$recognizer.SetInputToDefaultAudioDevice()

$recognizer.add_SpeechRecognized({
    param($sender, $e)
    
    $text = $e.Result.Text.ToLower()
    
    switch -Wildcard ($text) {
        "*home*" { sony-bravia-scripts.ps1 -Action a1 -Quiet }
        "*back*" { sony-bravia-scripts.ps1 -Action a2 -Quiet }
        "*volume up*" { sony-bravia-scripts.ps1 -Action f11 -Quiet }
        "*volume down*" { sony-bravia-scripts.ps1 -Action f12 -Quiet }
        "*mute*" { sony-bravia-scripts.ps1 -Action f14 -Quiet }
        "*play*" { sony-bravia-scripts.ps1 -Action e1 -Quiet }
        "*pause*" { sony-bravia-scripts.ps1 -Action e1 -Quiet }
        "*netflix*" { sony-bravia-scripts.ps1 -Action g1 -Quiet }
        "*youtube*" { sony-bravia-scripts.ps1 -Action g5 -Quiet }
    }
})

$recognizer.RecognizeAsync([System.Speech.Recognition.RecognizeMode]::Multiple)
Write-Host "Voice control active. Say commands..."
```

### Monitoring and alerting

```powershell
# Monitor TV connectivity
while ($true) {
    $connected = Test-AdbConnection
    
    if (-not $connected) {
        Write-Warning "TV disconnected at $(Get-Date)"
        
        # Send notification (requires notification tool)
        # Send-Notification -Title "TV Offline" -Message "Sony Bravia disconnected"
        
        # Attempt reconnect
        adb connect 192.168.1.100:5555
    }
    
    Start-Sleep -Seconds 60
}
```

## Tips and Tricks

### Speed up batch operations

```powershell
# Reduce delay between commands
$actions = @("a1", "a7", "a5", "a9")
$actions | ForEach-Object {
    sony-bravia-scripts.ps1 -Action $_ -Quiet
    Start-Sleep -Milliseconds 100  # Minimal delay
}
```

### Debugging commands

```powershell
# Run with verbose output
sony-bravia-scripts.ps1 -Action a1 -Verbose

# Check ADB connection
adb devices -l

# View TV logs
adb logcat | Select-String "error"

# Test specific ADB command
adb shell input keyevent KEYCODE_HOME
```

### Custom action shortcuts

```powershell
# Create functions for common actions
function tv-home { sony-bravia-scripts.ps1 -Action a1 -Quiet }
function tv-back { sony-bravia-scripts.ps1 -Action a2 -Quiet }
function tv-volup { sony-bravia-scripts.ps1 -Action f11 -Quiet }
function tv-voldown { sony-bravia-scripts.ps1 -Action f12 -Quiet }
function tv-mute { sony-bravia-scripts.ps1 -Action f14 -Quiet }
function tv-netflix { sony-bravia-scripts.ps1 -Action g1 -Quiet }
function tv-youtube { sony-bravia-scripts.ps1 -Action g5 -Quiet }

# Add to PowerShell profile for persistence
# $PROFILE

# Usage:
# tv-home
# tv-netflix
```

---

**Last Updated:** December 2024  
**Version:** 2.0

See also:
- [README](../readme.md) - Getting started
- [Troubleshooting](TROUBLESHOOTING.md) - Common issues
- [FAQ](FAQ.md) - Frequently asked questions
