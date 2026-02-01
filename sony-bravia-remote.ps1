<#
.SYNOPSIS
  Interactive TV Remote Control TUI with mouse support.

.DESCRIPTION
  Graphical remote control interface for Sony Bravia TVs using ADB.
  Features mouse click support and keyboard shortcuts.

.PARAMETER Serial
  Optional ADB device serial to target.

.EXAMPLE
  .\sony-bravia-remote.ps1
  .\sony-bravia-remote.ps1 -Serial 192.168.1.100:5555
#>

param(
    [string]$Serial
)

# Load core functions from main script
$mainScript = Join-Path $PSScriptRoot 'sony-bravia-scripts.ps1'
if (Test-Path $mainScript) {
    . $mainScript
}

function Send-RemoteKey {
    param([string]$KeyCode)
    
    $args = @('shell', 'input', 'keyevent', $KeyCode)
    if ($Serial) {
        Invoke-Adb -Serial $Serial -Args $args -AllowFailure | Out-Null
    }
    else {
        Invoke-Adb -Args $args -AllowFailure | Out-Null
    }
}

function Show-Button {
    param(
        [int]$X,
        [int]$Y,
        [string]$Label,
        [int]$Width = 12,
        [ConsoleColor]$Color = 'White',
        [bool]$IsHighlighted = $false
    )
    
    $bg = if ($IsHighlighted) { [ConsoleColor]::DarkBlue } else { [ConsoleColor]::Black }
    $fg = if ($IsHighlighted) { [ConsoleColor]::Yellow } else { $Color }
    
    [Console]::SetCursorPosition($X, $Y)
    [Console]::BackgroundColor = $bg
    [Console]::ForegroundColor = $fg
    
    $topBottom = "┌" + ("─" * ($Width - 2)) + "┐"
    $middle = "│" + $Label.PadLeft(($Width - 2 + $Label.Length) / 2).PadRight($Width - 2) + "│"
    $bottom = "└" + ("─" * ($Width - 2)) + "┘"
    
    [Console]::WriteLine($topBottom)
    [Console]::SetCursorPosition($X, $Y + 1)
    [Console]::WriteLine($middle)
    [Console]::SetCursorPosition($X, $Y + 2)
    [Console]::WriteLine($bottom)
    
    [Console]::ResetColor()
}

function Get-ButtonAtPosition {
    param([int]$X, [int]$Y)
    
    foreach ($btn in $script:Buttons) {
        if ($X -ge $btn.X -and $X -lt ($btn.X + $btn.Width) -and
            $Y -ge $btn.Y -and $Y -lt ($btn.Y + 3)) {
            return $btn
        }
    }
    return $null
}

function Show-Remote {
    param([string]$HighlightedButton = $null)
    
    [Console]::Clear()
    [Console]::CursorVisible = $false
    
    # Title
    [Console]::SetCursorPosition(0, 0)
    [Console]::ForegroundColor = [ConsoleColor]::Cyan
    [Console]::WriteLine(" ╔══════════════════════════════════════╗")
    [Console]::WriteLine(" ║   Sony Bravia TV Remote Control     ║")
    [Console]::WriteLine(" ╚══════════════════════════════════════╝")
    [Console]::ResetColor()
    
    # Draw all buttons
    foreach ($btn in $script:Buttons) {
        $isHighlighted = ($btn.Id -eq $HighlightedButton)
        Show-Button -X $btn.X -Y $btn.Y -Label $btn.Label -Width $btn.Width -Color $btn.Color -IsHighlighted $isHighlighted
    }
    
    # Instructions
    [Console]::SetCursorPosition(0, 35)
    [Console]::ForegroundColor = [ConsoleColor]::DarkGray
    [Console]::WriteLine(" Mouse: Click buttons  │  Keyboard: Arrow keys, Enter, Esc")
    [Console]::WriteLine(" Press Q to quit")
    [Console]::ResetColor()
}

# Define button layout
$script:Buttons = @(
    # Power row
    @{ Id = 'POWER'; Label = '⏻ Power'; X = 2; Y = 4; Width = 12; Color = 'Red'; KeyCode = 'KEYCODE_POWER' }
    @{ Id = 'INPUT'; Label = '⎙ Input'; X = 16; Y = 4; Width = 12; Color = 'Yellow'; KeyCode = 'KEYCODE_TV_INPUT' }
    @{ Id = 'MENU'; Label = '☰ Menu'; X = 30; Y = 4; Width = 12; Color = 'Yellow'; KeyCode = 'KEYCODE_MENU' }
    
    # D-Pad
    @{ Id = 'UP'; Label = '▲ Up'; X = 16; Y = 8; Width = 12; Color = 'White'; KeyCode = 'KEYCODE_DPAD_UP' }
    @{ Id = 'LEFT'; Label = '◄ Left'; X = 2; Y = 11; Width = 12; Color = 'White'; KeyCode = 'KEYCODE_DPAD_LEFT' }
    @{ Id = 'OK'; Label = '● OK'; X = 16; Y = 11; Width = 12; Color = 'Green'; KeyCode = 'KEYCODE_DPAD_CENTER' }
    @{ Id = 'RIGHT'; Label = 'Right ►'; X = 30; Y = 11; Width = 12; Color = 'White'; KeyCode = 'KEYCODE_DPAD_RIGHT' }
    @{ Id = 'DOWN'; Label = '▼ Down'; X = 16; Y = 14; Width = 12; Color = 'White'; KeyCode = 'KEYCODE_DPAD_DOWN' }
    
    # Navigation
    @{ Id = 'HOME'; Label = '⌂ Home'; X = 2; Y = 18; Width = 12; Color = 'Cyan'; KeyCode = 'KEYCODE_HOME' }
    @{ Id = 'BACK'; Label = '← Back'; X = 16; Y = 18; Width = 12; Color = 'Cyan'; KeyCode = 'KEYCODE_BACK' }
    @{ Id = 'OPTIONS'; Label = '⋮ Options'; X = 30; Y = 18; Width = 12; Color = 'Cyan'; KeyCode = 'KEYCODE_MENU' }
    
    # Volume
    @{ Id = 'VOL_UP'; Label = '+ Vol Up'; X = 2; Y = 22; Width = 12; Color = 'Magenta'; KeyCode = 'KEYCODE_VOLUME_UP' }
    @{ Id = 'VOL_DN'; Label = '- Vol Dn'; X = 2; Y = 25; Width = 12; Color = 'Magenta'; KeyCode = 'KEYCODE_VOLUME_DOWN' }
    @{ Id = 'MUTE'; Label = '🔇 Mute'; X = 16; Y = 22; Width = 12; Color = 'Magenta'; KeyCode = 'KEYCODE_VOLUME_MUTE' }
    
    # Channel
    @{ Id = 'CH_UP'; Label = '▲ CH Up'; X = 30; Y = 22; Width = 12; Color = 'Yellow'; KeyCode = 'KEYCODE_CHANNEL_UP' }
    @{ Id = 'CH_DN'; Label = '▼ CH Dn'; X = 30; Y = 25; Width = 12; Color = 'Yellow'; KeyCode = 'KEYCODE_CHANNEL_DOWN' }
    
    # Playback
    @{ Id = 'PLAY'; Label = '▶ Play'; X = 2; Y = 29; Width = 8; Color = 'Green'; KeyCode = 'KEYCODE_MEDIA_PLAY_PAUSE' }
    @{ Id = 'STOP'; Label = '■ Stop'; X = 12; Y = 29; Width = 8; Color = 'Red'; KeyCode = 'KEYCODE_MEDIA_STOP' }
    @{ Id = 'REW'; Label = '⏪ Rew'; X = 22; Y = 29; Width = 8; Color = 'White'; KeyCode = 'KEYCODE_MEDIA_REWIND' }
    @{ Id = 'FF'; Label = 'FF ⏩'; X = 32; Y = 29; Width = 8; Color = 'White'; KeyCode = 'KEYCODE_MEDIA_FAST_FORWARD' }
)

function Start-RemoteControl {
    # Check if ADB is available
    try {
        $null = Get-Command adb -ErrorAction Stop
    }
    catch {
        Write-Host "Error: ADB not found in PATH" -ForegroundColor Red
        Write-Host "Install Android platform-tools and add to PATH" -ForegroundColor Yellow
        return
    }
    
    # Check connection
    if ($Serial) {
        Write-Host "Connecting to $Serial..." -ForegroundColor Cyan
        & adb connect $Serial 2>&1 | Out-Null
    }
    
    $devices = & adb devices | Select-String -Pattern '\w+\s+device$'
    if (-not $devices) {
        Write-Host "Error: No ADB devices connected" -ForegroundColor Red
        Write-Host "Connect with: adb connect <tv-ip>:5555" -ForegroundColor Yellow
        return
    }
    
    $selectedButton = 0
    Show-Remote -HighlightedButton $script:Buttons[$selectedButton].Id
    
    # Enable mouse input if available (Windows only)
    if ($PSVersionTable.Platform -eq 'Win32NT' -or [string]::IsNullOrEmpty($PSVersionTable.Platform)) {
        try {
            [Console]::TreatControlCAsInput = $true
        }
        catch {
            Write-Host "Mouse support not available on this platform" -ForegroundColor DarkGray
        }
    }
    
    while ($true) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            
            switch ($key.Key) {
                'Q' { 
                    [Console]::Clear()
                    [Console]::CursorVisible = $true
                    return 
                }
                'Escape' { 
                    [Console]::Clear()
                    [Console]::CursorVisible = $true
                    return 
                }
                'UpArrow' {
                    $selectedButton = ($selectedButton - 1 + $script:Buttons.Count) % $script:Buttons.Count
                    Show-Remote -HighlightedButton $script:Buttons[$selectedButton].Id
                }
                'DownArrow' {
                    $selectedButton = ($selectedButton + 1) % $script:Buttons.Count
                    Show-Remote -HighlightedButton $script:Buttons[$selectedButton].Id
                }
                'LeftArrow' {
                    # Find button to the left
                    $current = $script:Buttons[$selectedButton]
                    $leftButtons = $script:Buttons | Where-Object { $_.Y -eq $current.Y -and $_.X -lt $current.X } | Sort-Object X -Descending
                    if ($leftButtons) {
                        $selectedButton = $script:Buttons.IndexOf($leftButtons[0])
                        Show-Remote -HighlightedButton $script:Buttons[$selectedButton].Id
                    }
                }
                'RightArrow' {
                    # Find button to the right
                    $current = $script:Buttons[$selectedButton]
                    $rightButtons = $script:Buttons | Where-Object { $_.Y -eq $current.Y -and $_.X -gt $current.X } | Sort-Object X
                    if ($rightButtons) {
                        $selectedButton = $script:Buttons.IndexOf($rightButtons[0])
                        Show-Remote -HighlightedButton $script:Buttons[$selectedButton].Id
                    }
                }
                'Enter' {
                    $btn = $script:Buttons[$selectedButton]
                    [Console]::SetCursorPosition(0, 33)
                    [Console]::ForegroundColor = [ConsoleColor]::Green
                    Write-Host " Sending: $($btn.Label)                    "
                    [Console]::ResetColor()
                    Send-RemoteKey -KeyCode $btn.KeyCode
                    Start-Sleep -Milliseconds 200
                    Show-Remote -HighlightedButton $btn.Id
                }
                'W' { Send-RemoteKey -KeyCode 'KEYCODE_DPAD_UP'; Show-Remote }
                'A' { Send-RemoteKey -KeyCode 'KEYCODE_DPAD_LEFT'; Show-Remote }
                'S' { Send-RemoteKey -KeyCode 'KEYCODE_DPAD_DOWN'; Show-Remote }
                'D' { Send-RemoteKey -KeyCode 'KEYCODE_DPAD_RIGHT'; Show-Remote }
                'H' { Send-RemoteKey -KeyCode 'KEYCODE_HOME'; Show-Remote }
                'B' { Send-RemoteKey -KeyCode 'KEYCODE_BACK'; Show-Remote }
                'Spacebar' { Send-RemoteKey -KeyCode 'KEYCODE_MEDIA_PLAY_PAUSE'; Show-Remote }
            }
        }
        
        Start-Sleep -Milliseconds 50
    }
}

# Start the remote
Start-RemoteControl

