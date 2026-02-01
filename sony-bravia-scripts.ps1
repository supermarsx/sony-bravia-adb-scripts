<#
.SYNOPSIS
  Sony Bravia TV ADB helper script (interactive menu + CLI actions).

.DESCRIPTION
  A PowerShell port of the original sony-bravia-scripts.cmd.

  - If run with no parameters, opens an interactive menu.
  - If run with -Action, executes that action once.
  - Supports batch mode to run multiple actions.
  - Maintains command history and configuration.

  TUI shortcuts (interactive mode):
  - Use "/" to filter actions
  - Use "S" to set/clear the target adb serial

  Requires: adb on PATH (Android platform-tools).

.PARAMETER Action
  Menu action id (e.g. a1, b2, d3, h4, n1). Case-insensitive.
  Can be comma-separated for batch mode: "a1,d3,h1"

.PARAMETER Serial
  Optional adb device serial to target (passed as `adb -s <serial>`).

.PARAMETER Quiet
  Suppress informational output (errors only).

.PARAMETER Verbose
  Enable detailed diagnostic output.

.PARAMETER OutputFormat
  Output format: Text (default), JSON, or CSV.

.PARAMETER Batch
  Read actions from a file (one action per line).

.PARAMETER CheckConnection
  Verify ADB connection before running actions.

.EXAMPLE
  .\sony-bravia-scripts.ps1

.EXAMPLE
  .\sony-bravia-scripts.ps1 -Action a1

.EXAMPLE
  .\sony-bravia-scripts.ps1 -Serial 192.168.1.20:5555 -Action d3

.EXAMPLE
  .\sony-bravia-scripts.ps1 -Action "a1,d3,h1" -Quiet

.EXAMPLE
  .\sony-bravia-scripts.ps1 -Batch actions.txt -OutputFormat JSON
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Action,

    [string]$Serial,

    [switch]$Quiet,

    [ValidateSet('Text', 'JSON', 'CSV')]
    [string]$OutputFormat = 'Text',

    [string]$Batch,

    [switch]$CheckConnection
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ScriptVer = '2.0'
$script:QuietMode = $Quiet
$script:OutputFormat = $OutputFormat
$script:VerboseLogging = $VerbosePreference -eq 'Continue'

# Configuration and history paths
$homeDir = if ($IsWindows -or $PSVersionTable.PSVersion.Major -le 5) { $env:USERPROFILE } else { $env:HOME }
$script:ConfigDir = Join-Path $homeDir '.sony-bravia-scripts'
$script:ConfigFile = Join-Path $script:ConfigDir 'config.json'
$script:HistoryFile = Join-Path $script:ConfigDir 'history.json'
$script:MaxHistoryItems = 100

# Initialize configuration
function Initialize-Config {
    if (-not (Test-Path $script:ConfigDir)) {
        New-Item -ItemType Directory -Path $script:ConfigDir -Force | Out-Null
    }

    if (-not (Test-Path $script:ConfigFile)) {
        $defaultConfig = @{
            version                     = $script:ScriptVer
            defaultSerial               = $null
            deviceAliases               = @{}
            retryAttempts               = 3
            retryDelayMs                = 1000
            checkConnectionBeforeAction = $true
        }
        $defaultConfig | ConvertTo-Json | Set-Content $script:ConfigFile
    }
}

function Get-Config {
    if (Test-Path $script:ConfigFile) {
        return Get-Content $script:ConfigFile | ConvertFrom-Json
    }
    return $null
}

function Set-ConfigValue {
    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        $Value
    )

    $config = Get-Config
    if ($config) {
        $config.$Key = $Value
        $config | ConvertTo-Json | Set-Content $script:ConfigFile
    }
}

function Add-ToHistory {
    param(
        [Parameter(Mandatory)]
        [string]$Action,

        [string]$Serial,

        [bool]$Success,

        [string]$ErrorMessage
    )

    $history = @()
    if (Test-Path $script:HistoryFile) {
        $history = Get-Content $script:HistoryFile | ConvertFrom-Json
    }

    $entry = @{
        timestamp = (Get-Date).ToString('o')
        action    = $Action
        serial    = $Serial
        success   = $Success
        error     = $ErrorMessage
    }

    $history = @($entry) + $history | Select-Object -First $script:MaxHistoryItems
    $history | ConvertTo-Json | Set-Content $script:HistoryFile
}

function Get-History {
    param([int]$Last = 10)

    if (Test-Path $script:HistoryFile) {
        $history = Get-Content $script:HistoryFile | ConvertFrom-Json
        return $history | Select-Object -First $Last
    }
    return @()
}

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet('Info', 'Warning', 'Error', 'Verbose')]
        [string]$Level = 'Info'
    )

    if ($script:QuietMode -and $Level -ne 'Error') {
        return
    }

    if ($Level -eq 'Verbose' -and -not $script:VerboseLogging) {
        return
    }

    if ($script:OutputFormat -eq 'JSON' -or $script:OutputFormat -eq 'CSV') {
        # Don't write logs in structured formats, collect for final output
        return
    }

    $color = switch ($Level) {
        'Info' { 'Gray' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        'Verbose' { 'DarkGray' }
    }

    Write-Host $Message -ForegroundColor $color
}

function Test-AdbConnection {
    param(
        [int]$RetryCount = 3,
        [int]$RetryDelayMs = 1000
    )

    Write-Log "Checking ADB connection..." -Level Verbose

    for ($i = 0; $i -lt $RetryCount; $i++) {
        try {
            $devices = & adb devices 2>&1
            if ($LASTEXITCODE -eq 0) {
                $deviceLines = $devices | Where-Object { $_ -match '\t(device|offline|unauthorized)' }

                if ($deviceLines) {
                    Write-Log "ADB connection verified ($($deviceLines.Count) device(s) found)" -Level Verbose
                    return $true
                }
            }
        }
        catch {
            Write-Log "Connection check attempt $($i + 1) failed: $($_.Exception.Message)" -Level Verbose
        }

        if ($i -lt $RetryCount - 1) {
            Write-Log "Retrying in $($RetryDelayMs)ms..." -Level Verbose
            Start-Sleep -Milliseconds $RetryDelayMs
        }
    }

    Write-Log "No ADB devices found. Make sure your device is connected and ADB is enabled." -Level Warning
    return $false
}

function Test-AdbAvailable {
    $adb = Get-Command adb -ErrorAction SilentlyContinue
    if (-not $adb) {
        throw "adb was not found on PATH. Install Android platform-tools and ensure 'adb' is available."
    }

}

function Invoke-Adb {
    <#
  .SYNOPSIS
    Runs adb with optional -s <serial> targeting.

  .DESCRIPTION
    Central wrapper for calling adb.
    - Adds `-s <Serial>` when -Serial is provided.
    - Prints the command being executed (unless quiet mode).
    - Throws on non-zero exit unless -AllowFailure is set.
    - Supports retry logic for connection failures.
  #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Args,

        [switch]$AllowFailure,

        [int]$RetryCount = 0
    )

    Test-AdbAvailable

    $config = Get-Config
    if ($RetryCount -eq 0 -and $config) {
        $RetryCount = $config.retryAttempts
    }

    $fullArgs = @()
    if ($Serial) {
        $fullArgs += @('-s', $Serial)
    }
    $fullArgs += $Args

    $attempt = 0
    $lastError = $null

    while ($attempt -le $RetryCount) {
        if ($attempt -gt 0) {
            Write-Log "Retry attempt $attempt/$RetryCount..." -Level Verbose
            Start-Sleep -Milliseconds ($config.retryDelayMs)
        }

        try {
            if (-not $script:QuietMode -and $script:OutputFormat -eq 'Text') {
                Write-Host ""
                Write-Host "Executing: adb $($fullArgs -join ' ')" -ForegroundColor DarkGray
                Write-Host ""
            }

            $output = & adb @fullArgs 2>&1
            $exit = $LASTEXITCODE

            if ($output -and $script:OutputFormat -eq 'Text') {
                $output | ForEach-Object { Write-Host $_ }
            }

            if (-not $AllowFailure -and $exit -ne 0) {
                $errorMsg = $output -join "`n"

                # Check for common errors that might benefit from retry
                if ($errorMsg -match 'device offline|device not found|no devices|protocol fault') {
                    $lastError = "ADB connection error: $errorMsg"
                    $attempt++
                    continue
                }

                throw "adb exited with code ${exit}: $errorMsg"
            }

            return [pscustomobject]@{
                ExitCode = $exit
                Output   = ($output -join "`n")
                Success  = ($exit -eq 0)
            }
        }
        catch {
            $lastError = $_.Exception.Message

            if ($attempt -ge $RetryCount) {
                if ($AllowFailure) {
                    return [pscustomobject]@{
                        ExitCode = -1
                        Output   = $lastError
                        Success  = $false
                    }
                }
                throw
            }

            $attempt++
        }
    }

    if ($lastError) {
        throw $lastError
    }

    if (-not $AllowFailure -and $exit -ne 0) {
        throw "adb exited with code $exit"
    }

    return [pscustomobject]@{
        ExitCode = $exit
        Output   = ($output -join "`n")
    }
}

function Wait-ForContinue {
    param([string]$Message = 'Press any key to continue...')
    Write-Host ""
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

function Read-NonEmpty {
    param(
        [Parameter(Mandatory)]
        [string]$Prompt
    )

    while ($true) {
        $value = Read-Host $Prompt
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return $value
        }
    }
}

function Read-YesNo {
    param(
        [Parameter(Mandatory)]
        [string]$Prompt
    )

    while ($true) {
        $ans = (Read-Host "$Prompt (y/n)").Trim().ToLowerInvariant()
        if ($ans -in @('y', 'yes')) { return $true }
        if ($ans -in @('n', 'no')) { return $false }
    }
}

function Write-Title {
    param([Parameter(Mandatory)][string]$Text)
    $Host.UI.RawUI.WindowTitle = "Sony Bravia Scripts $script:ScriptVer - $Text"
    Write-Host ""
    Write-Host $Text -ForegroundColor Cyan
    Write-Host ""
}

function Done {
    Write-Host ""
    Write-Host "Finished executing." -ForegroundColor Green
    Write-Host ""
    Wait-ForContinue
}

function NotImplemented {
    param([string]$Hint)
    Write-Host "Not implemented." -ForegroundColor Yellow
    if ($Hint) {
        Write-Host $Hint -ForegroundColor DarkYellow
    }
    Done
}

# --- Actions (menu ids mirror the original .cmd labels) ---

function a1 {
    # Connect
    Write-Title "Connect ADB"
    $hostport = Read-NonEmpty "Hostname/IP[:port]"
    Invoke-Adb -Args @('connect', $hostport) | Out-Null
    Done
}

function a2 {
    # Disconnect
    Write-Title "Disconnect ADB"
    Invoke-Adb -Args @('disconnect') | Out-Null
    Done
}

function a3 {
    # Devices
    Write-Title "List ADB devices"
    Invoke-Adb -Args @('devices') | Out-Null
    Done
}

function b1 {
    # Shell
    Write-Title "Start shell"
    Write-Host "Dropping you into interactive 'adb shell'. Exit to return." -ForegroundColor DarkGray
    Invoke-Adb -Args @('shell') -AllowFailure | Out-Null
    Done
}

function b2 {
    # Logcat
    Write-Title "Logcat"
    Write-Host "Streaming logcat. Press Ctrl+C to stop." -ForegroundColor DarkGray
    Invoke-Adb -Args @('logcat') -AllowFailure | Out-Null
    Done
}

function b3 {
    # adb help
    Write-Title "List ADB commands"
    Invoke-Adb -Args @('help') | Out-Null
    Done
}

function c1 {
    # ps
    Write-Title "List processes"
    $params = Read-Host "Additional 'ps' parameters (optional)"
    $cmd = if ([string]::IsNullOrWhiteSpace($params)) { 'ps' } else { "ps $params" }
    Invoke-Adb -Args @('shell', $cmd) | Out-Null
    Done
}

function c2 {
    # netstat
    Write-Title "List connections"
    $params = Read-Host "Additional 'netstat' parameters (optional)"
    $cmd = if ([string]::IsNullOrWhiteSpace($params)) { 'netstat' } else { "netstat $params" }
    Invoke-Adb -Args @('shell', $cmd) -AllowFailure | Out-Null
    Done
}

function c3 {
    # service list
    Write-Title "List services"
    Invoke-Adb -Args @('shell', 'service list') | Out-Null
    Done
}

function c4 {
    # service check
    Write-Title "Check specific service"
    $service = Read-NonEmpty "Service name"
    Invoke-Adb -Args @('shell', "service check $service") | Out-Null
    Done
}

function d1 {
    # serial
    Write-Title "Get serial number"
    Invoke-Adb -Args @('get-serialno') | Out-Null
    Done
}

function d2 {
    # state
    Write-Title "Get device state"
    Invoke-Adb -Args @('get-state') | Out-Null
    Done
}

function d3 {
    # model
    Write-Title "Get model"
    Invoke-Adb -Args @('shell', 'getprop ro.opera.tvstore.model') | Out-Null
    Done
}

function d4 {
    # features
    Write-Title "Get features list"
    Invoke-Adb -Args @('shell', 'pm list features') | Out-Null
    Done
}

function d5 {
    Write-Title "Memory information"
    Invoke-Adb -Args @('shell', 'cat /proc/meminfo') | Out-Null
    Done
}

function d6 {
    Write-Title "Free memory"
    Invoke-Adb -Args @('shell', 'free -h') -AllowFailure | Out-Null
    Done
}

function d7 {
    Write-Title "Processes (most cpu)"
    Invoke-Adb -Args @('shell', 'top -n 1 -s cpu') -AllowFailure | Out-Null
    Done
}

function d8 {
    Write-Title "Processes (most vss)"
    Invoke-Adb -Args @('shell', 'top -n 1 -s vss') -AllowFailure | Out-Null
    Done
}

function e1 {
    Write-Title "Reboot"
    if (Read-YesNo "Reboot the device now?") {
        Invoke-Adb -Args @('reboot') | Out-Null
    }
    Done
}

function e2 {
    Write-Title "Shutdown"
    if (Read-YesNo "Shut down (power off) the device now?") {
        Invoke-Adb -Args @('shell', 'reboot -p') -AllowFailure | Out-Null
    }
    Done
}

function f1 {
    Write-Title "Get device name"
    Invoke-Adb -Args @('shell', 'settings get global device_name') -AllowFailure | Out-Null
    Done
}

function f2 {
    Write-Title "Get bluetooth name"
    Invoke-Adb -Args @('shell', 'settings get global bluetooth_name') -AllowFailure | Out-Null
    Done
}

function f3 {
    Write-Title "Get both names"
    Invoke-Adb -Args @('shell', 'settings get global device_name') -AllowFailure | Out-Null
    Invoke-Adb -Args @('shell', 'settings get global bluetooth_name') -AllowFailure | Out-Null
    Done
}

function f4 {
    Write-Title "Set device name"
    $name = Read-NonEmpty "Device name"
    Invoke-Adb -Args @('shell', "settings put global device_name '$name'") -AllowFailure | Out-Null
    Done
}

function f5 {
    Write-Title "Set bluetooth name"
    $name = Read-NonEmpty "Bluetooth name"
    Invoke-Adb -Args @('shell', "settings put global bluetooth_name '$name'") -AllowFailure | Out-Null
    Done
}

function f6 {
    Write-Title "Set both names"
    $name = Read-NonEmpty "Both names"
    Invoke-Adb -Args @('shell', "settings put global device_name '$name'") -AllowFailure | Out-Null
    Invoke-Adb -Args @('shell', "settings put global bluetooth_name '$name'") -AllowFailure | Out-Null
    Done
}

function g1 {
    Write-Title "Start settings"
    Invoke-Adb -Args @('shell', 'am start -a android.settings.SETTINGS') -AllowFailure | Out-Null
    Done
}

function g2 {
    Write-Title "Open home"
    Invoke-Adb -Args @('shell', 'input keyevent 3') -AllowFailure | Out-Null
    Done
}

function g3 {
    Write-Title "Open URL"
    $url = Read-NonEmpty "URL"
    Invoke-Adb -Args @('shell', "am start -a android.intent.action.VIEW -d '$url'") -AllowFailure | Out-Null
    Done
}

function g4 {
    Write-Title "Clear recent apps"
    $cmd = "input keyevent KEYCODE_APP_SWITCH && while (dumpsys activity recents | grep -q 'Recent #'); do input keyevent DEL; done"
    Invoke-Adb -Args @('shell', $cmd) -AllowFailure | Out-Null
    Write-Host "Note: requires 'grep' on the device (toybox/busybox)." -ForegroundColor DarkGray
    Done
}

function h1 {
    Write-Title "Current screen density"
    Invoke-Adb -Args @('shell', 'wm density') -AllowFailure | Out-Null
    Done
}

function h2 {
    Write-Title "Set custom screen density"
    $density = Read-NonEmpty "New density (e.g. 260)"
    Invoke-Adb -Args @('shell', "wm density $density") -AllowFailure | Out-Null
    Done
}

function h3 {
    Write-Title "Set density to 260"
    Invoke-Adb -Args @('shell', 'wm density 260') -AllowFailure | Out-Null
    Done
}

function h4 {
    Write-Title "Reset density to default"
    Invoke-Adb -Args @('shell', 'wm density reset') -AllowFailure | Out-Null
    Done
}

function h5 {
    Write-Title "Current screen resolution"
    Invoke-Adb -Args @('shell', 'wm size') -AllowFailure | Out-Null
    Done
}

function h6 {
    Write-Title "Set custom screen resolution"
    $res = Read-NonEmpty "New resolution (e.g. 1920x1080)"
    Invoke-Adb -Args @('shell', "wm size $res") -AllowFailure | Out-Null
    Done
}

function h7 {
    Write-Title "Reset resolution to default"
    Invoke-Adb -Args @('shell', 'wm size reset') -AllowFailure | Out-Null
    Done
}

function h8 {
    Write-Title "Current animation scales"
    Invoke-Adb -Args @('shell', 'settings get global window_animation_scale') -AllowFailure | Out-Null
    Invoke-Adb -Args @('shell', 'settings get global transition_animation_scale') -AllowFailure | Out-Null
    Invoke-Adb -Args @('shell', 'settings get global animator_duration_scale') -AllowFailure | Out-Null
    Done
}

function h9 {
    Write-Title "Set animation scales"
    $scale = Read-NonEmpty "Scale (e.g. 0, 0.2, 0.5, 1, 2)"
    Invoke-Adb -Args @('shell', "settings put global window_animation_scale $scale") -AllowFailure | Out-Null
    Invoke-Adb -Args @('shell', "settings put global transition_animation_scale $scale") -AllowFailure | Out-Null
    Invoke-Adb -Args @('shell', "settings put global animator_duration_scale $scale") -AllowFailure | Out-Null
    Done
}

function h10 {
    Write-Title "Set fast animations (0.2x)"
    Invoke-Adb -Args @('shell', 'settings put global window_animation_scale 0.2') -AllowFailure | Out-Null
    Invoke-Adb -Args @('shell', 'settings put global transition_animation_scale 0.2') -AllowFailure | Out-Null
    Invoke-Adb -Args @('shell', 'settings put global animator_duration_scale 0.2') -AllowFailure | Out-Null
    Done
}

function h11 {
    Write-Title "Reset animations (1x)"
    Invoke-Adb -Args @('shell', 'settings put global window_animation_scale 1') -AllowFailure | Out-Null
    Invoke-Adb -Args @('shell', 'settings put global transition_animation_scale 1') -AllowFailure | Out-Null
    Invoke-Adb -Args @('shell', 'settings put global animator_duration_scale 1') -AllowFailure | Out-Null
    Done
}

function i1 {
    Write-Title "List installed applications (packages)"
    Invoke-Adb -Args @('shell', 'pm list packages') -AllowFailure | Out-Null
    Done
}

function i2 {
    Write-Title "Clear / trim app caches"
    Write-Host "Android doesn’t expose a safe per-app 'clear cache only' for all apps." -ForegroundColor DarkGray
    Write-Host "This uses 'pm trim-caches' as a best-effort cache cleanup." -ForegroundColor DarkGray
    Invoke-Adb -Args @('shell', 'pm trim-caches 999G') -AllowFailure | Out-Null
    Done
}

function i3 {
    Write-Title "Reset app permissions"
    if (Read-YesNo "Reset runtime permissions for all packages?") {
        Invoke-Adb -Args @('shell', 'pm reset-permissions') -AllowFailure | Out-Null
    }
    Done
}

function i3a {
    Write-Title "Clear cache for all apps (loop)"

    Write-Host "Fetching installed packages..." -ForegroundColor Yellow
    $packagesOutput = Invoke-Adb -Args @('shell', 'pm list packages') -AllowFailure

    if (-not $packagesOutput -or $packagesOutput.ExitCode -ne 0) {
        Write-Host "Failed to retrieve packages" -ForegroundColor Red
        Done
        return
    }

    # Parse package names from output (format: "package:com.example.app")
    $packages = $packagesOutput.Output -split "`n" | Where-Object { $_ -match '^package:' } | ForEach-Object {
        $_.Replace('package:', '').Trim()
    } | Where-Object { $_ }

    if ($packages.Count -eq 0) {
        Write-Host "No packages found" -ForegroundColor Red
        Done
        return
    }

    Write-Host "Found $($packages.Count) packages" -ForegroundColor Green
    Write-Host ""

    $confirm = Read-YesNo "Clear cache for all $($packages.Count) packages? (may take several minutes)"
    if (-not $confirm) {
        Write-Host "Cache clear cancelled" -ForegroundColor Yellow
        Done
        return
    }

    Write-Host ""
    Write-Host "Clearing cache for all packages..." -ForegroundColor Yellow
    Write-Host "(This may take a while, please wait...)" -ForegroundColor Gray
    Write-Host ""

    $successCount = 0
    $failCount = 0
    $current = 0

    foreach ($pkg in $packages) {
        $current++
        $percentage = [math]::Round(($current / $packages.Count) * 100)

        # Show progress every 10 packages or always in verbose mode
        if (($current % 10 -eq 0) -or $current -eq 1 -or $current -eq $packages.Count -or $script:VerboseMode) {
            Write-Host "[$percentage%] Processing $current/$($packages.Count): $pkg" -ForegroundColor Gray
        }

        try {
            # Use pm clear which properly clears cache and data
            # With -AllowFailure to not break on system packages that can't be cleared
            $result = Invoke-Adb -Args @('shell', "pm clear $pkg 2>/dev/null || echo 'skip'") -AllowFailure

            if ($result.Output -notmatch 'Failed|failed|error') {
                $successCount++
            }
            else {
                $failCount++
            }
        }
        catch {
            $failCount++
        }
    }

    Write-Host ""
    Write-Host "Cache clear complete!" -ForegroundColor Green
    Write-Host "  Cleared: $successCount packages" -ForegroundColor Green
    if ($failCount -gt 0) {
        Write-Host "  Skipped: $failCount packages (system apps or already clear)" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "💡 Tip: Freed cache space may take a moment to reflect in storage" -ForegroundColor Cyan
    Done
}

function i4 {
    Write-Title "Disable apps (debloat)"
    $packages = Read-NonEmpty "Package names (comma-separated)"
    foreach ($pkg in ($packages -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
        Invoke-Adb -Args @('shell', "pm disable-user --user 0 $pkg") -AllowFailure | Out-Null
    }
    Done
}

function i5 {
    Write-Title "Enable apps (reverse debloat)"
    $packages = Read-NonEmpty "Package names (comma-separated)"
    foreach ($pkg in ($packages -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
        Invoke-Adb -Args @('shell', "pm enable $pkg") -AllowFailure | Out-Null
        Invoke-Adb -Args @('shell', "cmd package install-existing --user 0 $pkg") -AllowFailure | Out-Null
    }
    Done
}

function i6 {
    Write-Title "Install APK"
    $apkPath = Read-NonEmpty "Path to .apk"
    Invoke-Adb -Args @('install', '-r', $apkPath) -AllowFailure | Out-Null
    Done
}

function i7 {
    Write-Title "Install multi-package APKs"
    Write-Host "Enter paths separated by semicolon (;)" -ForegroundColor DarkGray
    $paths = Read-NonEmpty "APK paths"
    $apkPaths = $paths -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    if ($apkPaths.Count -lt 2) {
        throw "Need at least two APK paths for install-multiple."
    }
    Invoke-Adb -Args (@('install-multiple') + $apkPaths) -AllowFailure | Out-Null
    Done
}

function i8 {
    Write-Title "Enable app"
    $pkg = Read-NonEmpty "Package name"
    Invoke-Adb -Args @('shell', "pm enable $pkg") -AllowFailure | Out-Null
    Invoke-Adb -Args @('shell', "cmd package install-existing --user 0 $pkg") -AllowFailure | Out-Null
    Done
}

function i9 {
    Write-Title "Disable app"
    $pkg = Read-NonEmpty "Package name"
    Invoke-Adb -Args @('shell', "pm disable-user --user 0 $pkg") -AllowFailure | Out-Null
    Done
}

function i10 {
    Write-Title "Uninstall app"
    $pkg = Read-NonEmpty "Package name"
    if (Read-YesNo "Uninstall for user 0 (recommended)?") {
        Invoke-Adb -Args @('shell', "pm uninstall -k --user 0 $pkg") -AllowFailure | Out-Null
    }
    else {
        Invoke-Adb -Args @('shell', "pm uninstall $pkg") -AllowFailure | Out-Null
    }
    Done
}

function i11 {
    Write-Title "Force stop app"
    $pkg = Read-NonEmpty "Package name"
    Invoke-Adb -Args @('shell', "am force-stop $pkg") -AllowFailure | Out-Null
    Done
}

function i12 {
    Write-Title "Restart app"
    $pkg = Read-NonEmpty "Package name"
    Invoke-Adb -Args @('shell', "am force-stop $pkg") -AllowFailure | Out-Null
    Invoke-Adb -Args @('shell', "monkey -p $pkg -c android.intent.category.LAUNCHER 1") -AllowFailure | Out-Null
    Done
}

function j1 {
    Write-Title "Get current HOME (launcher)"
    Invoke-Adb -Args @('shell', 'cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME') -AllowFailure | Out-Null
    Done
}

function j2 {
    Write-Title "Set custom HOME (launcher)"
    Write-Host "This is device/Android-version dependent." -ForegroundColor DarkGray
    $component = Read-NonEmpty "Component name (e.g. com.example.launcher/.MainActivity)"
    Invoke-Adb -Args @('shell', "cmd package set-home-activity $component") -AllowFailure | Out-Null
    Done
}

function j3 {
    Write-Title "Enable launcher package"
    $pkg = Read-NonEmpty "Launcher package"
    Invoke-Adb -Args @('shell', "pm enable $pkg") -AllowFailure | Out-Null
    Done
}

function j4 {
    Write-Title "Disable launcher package"
    $pkg = Read-NonEmpty "Launcher package"
    Invoke-Adb -Args @('shell', "pm disable-user --user 0 $pkg") -AllowFailure | Out-Null
    Done
}

function i13 {
    Write-Title "Debloat: Disable Sony bloatware (preset)"

    $bloatwarePackages = @(
        'com.gameloft.android.HEP.GloftANHP',
        'com.google.android.inputmethod.japanese',
        'com.google.android.play.games',
        'com.opera.sdk.example',
        'com.qterics.da.product',
        'com.sony.dtv.b2b.hotellanguage',
        'com.sony.dtv.b2b.hotellanguange',
        'com.sony.dtv.b2b.hotelmenu',
        'com.sony.dtv.b2b.hotelmode',
        'com.sony.dtv.bleadvertiseservice',
        'com.sony.dtv.bravialifehack',
        'com.sony.dtv.imanual',
        'com.sony.dtv.interactivetvplatform',
        'com.sony.dtv.interactivetvutil',
        'com.sony.dtv.interactivetvutil.output',
        'com.sony.dtv.interactivetvutil.ppbridge',
        'com.sony.dtv.irbrecommendation',
        'com.sony.dtv.netflixmanager',
        'com.sony.dtv.networkapp.wifidirect',
        'com.sony.dtv.networkrecommendation',
        'com.sony.dtv.osat.album',
        'com.sony.dtv.photosharingplus',
        'com.sony.dtv.recommendationservice',
        'com.sony.dtv.shopsettings',
        'com.sony.dtv.sonyselect',
        'com.sony.dtv.sonyshelf',
        'com.sony.dtv.tvx',
        'com.sony.dtv.tvx.search.s101.tvprograms.cam',
        'com.sony.dtv.tvx.search.s101.tvprograms.digital',
        'com.sony.dtv.tvx.search.s101.tvprograms.vt',
        'com.sony.dtv.tvx.search.s201.netepg',
        'com.sony.dtv.tvx.search.s301.rec',
        'com.sony.dtv.tvx.search.s501.psv',
        'com.sony.dtv.watchtvrecommendation',
        'com.sony.dtv.woprecommendation',
        'com.sony.dtv.youview',
        'com.sony.snei.video.hhvu',
        'com.sonyericsson.dlna',
        'com.sonyericsson.dlna.dtcpplayer',
        'tv.samba.ssm'
    )

    $confirm = Read-YesNo "Disable $($bloatwarePackages.Count) bloatware packages? (recommended)"
    if ($confirm) {
        Write-Host "Disabling bloatware packages..." -ForegroundColor Yellow
        $successCount = 0
        $failCount = 0

        foreach ($pkg in $bloatwarePackages) {
            Write-Host "  Disabling: $pkg" -ForegroundColor Gray
            try {
                Invoke-Adb -Args @('shell', "pm disable-user --user 0 $pkg") -AllowFailure | Out-Null
                $successCount++
            }
            catch {
                $failCount++
            }
        }

        Write-Host ""
        Write-Host "Debloat complete!" -ForegroundColor Green
        Write-Host "  Disabled: $successCount packages" -ForegroundColor Green
        if ($failCount -gt 0) {
            Write-Host "  Failed: $failCount packages (may not be installed)" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Debloat cancelled" -ForegroundColor Yellow
    }
    Done
}

function i14 {
    Write-Title "Debloat: Re-enable Sony packages (undo)"

    $bloatwarePackages = @(
        'com.gameloft.android.HEP.GloftANHP',
        'com.google.android.inputmethod.japanese',
        'com.google.android.play.games',
        'com.opera.sdk.example',
        'com.qterics.da.product',
        'com.sony.dtv.b2b.hotellanguage',
        'com.sony.dtv.b2b.hotellanguange',
        'com.sony.dtv.b2b.hotelmenu',
        'com.sony.dtv.b2b.hotelmode',
        'com.sony.dtv.bleadvertiseservice',
        'com.sony.dtv.bravialifehack',
        'com.sony.dtv.imanual',
        'com.sony.dtv.interactivetvplatform',
        'com.sony.dtv.interactivetvutil',
        'com.sony.dtv.interactivetvutil.output',
        'com.sony.dtv.interactivetvutil.ppbridge',
        'com.sony.dtv.irbrecommendation',
        'com.sony.dtv.netflixmanager',
        'com.sony.dtv.networkapp.wifidirect',
        'com.sony.dtv.networkrecommendation',
        'com.sony.dtv.osat.album',
        'com.sony.dtv.photosharingplus',
        'com.sony.dtv.recommendationservice',
        'com.sony.dtv.shopsettings',
        'com.sony.dtv.sonyselect',
        'com.sony.dtv.sonyshelf',
        'com.sony.dtv.tvx',
        'com.sony.dtv.tvx.search.s101.tvprograms.cam',
        'com.sony.dtv.tvx.search.s101.tvprograms.digital',
        'com.sony.dtv.tvx.search.s101.tvprograms.vt',
        'com.sony.dtv.tvx.search.s201.netepg',
        'com.sony.dtv.tvx.search.s301.rec',
        'com.sony.dtv.tvx.search.s501.psv',
        'com.sony.dtv.watchtvrecommendation',
        'com.sony.dtv.woprecommendation',
        'com.sony.dtv.youview',
        'com.sony.snei.video.hhvu',
        'com.sonyericsson.dlna',
        'com.sonyericsson.dlna.dtcpplayer',
        'tv.samba.ssm'
    )

    $confirm = Read-YesNo "Re-enable $($bloatwarePackages.Count) packages?"
    if ($confirm) {
        Write-Host "Re-enabling packages..." -ForegroundColor Yellow
        $successCount = 0
        $failCount = 0

        foreach ($pkg in $bloatwarePackages) {
            Write-Host "  Enabling: $pkg" -ForegroundColor Gray
            try {
                Invoke-Adb -Args @('shell', "pm enable $pkg") -AllowFailure | Out-Null
                Invoke-Adb -Args @('shell', "cmd package install-existing --user 0 $pkg") -AllowFailure | Out-Null
                $successCount++
            }
            catch {
                $failCount++
            }
        }

        Write-Host ""
        Write-Host "Re-enable complete!" -ForegroundColor Green
        Write-Host "  Enabled: $successCount packages" -ForegroundColor Green
        if ($failCount -gt 0) {
            Write-Host "  Failed: $failCount packages" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Re-enable cancelled" -ForegroundColor Yellow
    }
    Done
}

function i15 {
    Write-Title "Debloat: NUCLEAR - Disable all bloatware (aggressive)"

    $nuclearPackages = @(
        'pt.dreamia.pandaplus',
        'com.uei.quicksetsdk.sony',
        'com.sony.dtv.b2b.noderuntime.normal',
        'com.google.android.apps.mediashell',
        'com.google.android.katniss',
        'com.sony.dtv.hddmgr',
        'com.android.providers.calendar',
        'com.sony.dtv.timers',
        'com.sony.dtv.tvx.search.s101.tvprograms.prefsat',
        'com.sony.dtv.tvinput.tuner',
        'android.autoinstalls.config.sony.bravia',
        'com.sony.dtv.common.base.AccessibilityText',
        'com.sony.dtv.rcplayer',
        'com.sony.dtv.usbmsgservice',
        'com.qterics.da.product',
        'com.sony.dtv.imanual',
        'com.sony.dtv.sonyshelf',
        'com.sony.dtv.rcplayer.service',
        'com.spotify.tv.android',
        'com.sony.dtv.browser.webappruntime',
        'com.android.pacprocessor',
        'com.sony.dtv.QuickSetupCustomizer',
        'com.sony.dtv.b2b.noderuntime',
        'com.sony.dtv.interactivetvplatform',
        'com.google.android.marvin.talkback',
        'com.sony.dtv.bleadvertiseservice',
        'com.sony.dtv.tvx.search.s101.tvprograms.vt',
        'com.sony.dtv.tvx.search.s301.rec',
        'com.google.android.speech.pumpkin',
        'com.sony.dtv.servicemode',
        'com.sony.dtv.osat.album',
        'com.sony.dtv.osat.music',
        'com.android.backupconfirm',
        'com.sony.dtv.osat.video',
        'com.sony.dtv.netproxyservice',
        'com.sony.dtv.webapi.core',
        'com.sony.dtv.b2b.hotellanguage',
        'com.sony.dtv.reminderservice',
        'com.sony.dtv.browser.webappservice',
        'com.sony.dtv.interactivetvutil.output',
        'com.sony.dtv.systemupdate',
        'com.sony.dtv.shopsettings',
        'com.sony.dtv.hbbtvlauncher',
        'com.sony.dtv.customersupport',
        'com.sony.huey.dlna.renderersettings',
        'com.sony.dtv.privacypolicy',
        'com.sony.dtv.browser.webappinstaller',
        'com.amazon.amazonvideo.livingroom',
        'com.android.sharedstoragebackup',
        'com.google.android.music',
        'com.android.printspooler',
        'com.sony.dtv.seconddispsetting',
        'com.sony.dtv.b2b.hotelmenu',
        'com.wbd.stream',
        'com.sony.dtv.ime.chww',
        'com.sony.dtv.imeproxy',
        'com.sony.dtv.enclave.service',
        'com.sony.dtv.youview',
        'com.sony.dtv.tvx.search.s101.tvprograms.cam',
        'com.sony.dtv.countrysetting',
        'com.sony.dtv.softwarelicense',
        'com.youview.tv.servicehost',
        'com.sony.dtv.recommendationservice',
        'com.google.android.syncadapters.contacts',
        'com.sony.dtv.quicksetup',
        'com.sony.dtv.woprecommendation',
        'com.sony.dtv.tvx.search.s201.netepg',
        'com.sony.dtv.tvx.search.s101.tvprograms.digital',
        'com.teamsmart.videomanager.tv',
        'com.google.android.tts',
        'com.impresa.opta',
        'com.google.android.videos',
        'com.sony.dtv.browser.ceb',
        'com.sony.dtv.dialservice',
        'com.sony.dtv.sonyselect',
        'com.android.proxyhandler',
        'com.google.android.feedback',
        'com.google.android.syncadapters.calendar',
        'com.sony.dtv.b2b.prosettings',
        'com.sony.dtv.b2b.importexport',
        'com.sony.dtv.smarthelp',
        'com.google.android.tv.bugreportsender',
        'mtktvapi.agent',
        'com.sony.dtv.netflixmanager',
        'com.sony.dtv.tvx.search.s501.psv',
        'com.sony.dtv.tuningconfirmation_dvbs',
        'com.sony.dtv.tuningconfirmation_dvbt',
        'com.sony.dtv.touchpad.tutorial',
        'screnmirroring.com',
        'ca.dstudio.atvlauncher.pro',
        'com.sony.dtv.watchtvrecommendation',
        'com.google.android.leanbacklauncher',
        'com.google.android.backuptransport',
        'com.sony.dtv.interactivetvutil',
        'com.opera.sdk.example',
        'com.sony.dtv.bravialifehack',
        'com.sony.dtv.nfcservice',
        'com.sony.dtv.tvx.search.s101.tvprograms.gensat',
        'com.android.vpndialogs',
        'com.sonyericsson.dlna.dtcpplayer',
        'com.android.wallpaperbackup',
        'com.sony.dtv.networkrecommendation',
        'com.sony.dtv.irbrecommendation',
        'com.sony.dtv.scrums.action',
        'com.sony.dtv.demomode',
        'com.google.android.tv.remote.service',
        'com.google.android.inputmethod.japanese',
        'com.b_lam.resplash',
        'com.sony.dtv.tvplayer',
        'com.amazon.aiv.eu',
        'com.google.android.play.games',
        'com.sony.dtv.bivlinfo',
        'com.sony.dtv.servermgr',
        'com.android.providers.contacts',
        'com.android.captiveportallogin',
        'com.disney.disneyplus',
        'com.sony.dtv.discovery',
        'com.sony.huey.dlna.module'
    )

    Write-Host ""
    Write-Host "⚠️  WARNING: NUCLEAR DEBLOAT ⚠️" -ForegroundColor Red
    Write-Host "This will disable $($nuclearPackages.Count) packages including:" -ForegroundColor Yellow
    Write-Host "  - System services (tuner, timers, HDD manager)" -ForegroundColor Yellow
    Write-Host "  - Google services (TTS, sync, backup)" -ForegroundColor Yellow
    Write-Host "  - Streaming apps (Netflix, Amazon, Disney+, etc.)" -ForegroundColor Yellow
    Write-Host "  - TV-specific features (EPG, recordings, etc.)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This may break TV functionality! Use with caution." -ForegroundColor Red
    Write-Host ""

    $confirm = Read-YesNo "Proceed with NUCLEAR debloat?"
    if ($confirm) {
        Write-Host ""
        Write-Host "Starting nuclear debloat..." -ForegroundColor Yellow
        $successCount = 0
        $failCount = 0

        foreach ($pkg in $nuclearPackages) {
            Write-Host "  Disabling: $pkg" -ForegroundColor Gray
            try {
                Invoke-Adb -Args @('shell', "pm disable-user --user 0 $pkg") -AllowFailure | Out-Null
                $successCount++
            }
            catch {
                $failCount++
            }
        }

        Write-Host ""
        Write-Host "Nuclear debloat complete!" -ForegroundColor Green
        Write-Host "  Disabled: $successCount packages" -ForegroundColor Green
        if ($failCount -gt 0) {
            Write-Host "  Failed: $failCount packages (may not be installed)" -ForegroundColor Yellow
        }
        Write-Host ""
        Write-Host "💡 Tip: Reboot TV for changes to take full effect" -ForegroundColor Cyan
    }
    else {
        Write-Host "Nuclear debloat cancelled" -ForegroundColor Yellow
    }
    Done
}

function i16 {
    Write-Title "Debloat: Re-enable all packages (undo nuclear)"

    $nuclearPackages = @(
        'pt.dreamia.pandaplus',
        'com.uei.quicksetsdk.sony',
        'com.sony.dtv.b2b.noderuntime.normal',
        'com.google.android.apps.mediashell',
        'com.google.android.katniss',
        'com.sony.dtv.hddmgr',
        'com.android.providers.calendar',
        'com.sony.dtv.timers',
        'com.sony.dtv.tvx.search.s101.tvprograms.prefsat',
        'com.sony.dtv.tvinput.tuner',
        'android.autoinstalls.config.sony.bravia',
        'com.sony.dtv.common.base.AccessibilityText',
        'com.sony.dtv.rcplayer',
        'com.sony.dtv.usbmsgservice',
        'com.qterics.da.product',
        'com.sony.dtv.imanual',
        'com.sony.dtv.sonyshelf',
        'com.sony.dtv.rcplayer.service',
        'com.spotify.tv.android',
        'com.sony.dtv.browser.webappruntime',
        'com.android.pacprocessor',
        'com.sony.dtv.QuickSetupCustomizer',
        'com.sony.dtv.b2b.noderuntime',
        'com.sony.dtv.interactivetvplatform',
        'com.google.android.marvin.talkback',
        'com.sony.dtv.bleadvertiseservice',
        'com.sony.dtv.tvx.search.s101.tvprograms.vt',
        'com.sony.dtv.tvx.search.s301.rec',
        'com.google.android.speech.pumpkin',
        'com.sony.dtv.servicemode',
        'com.sony.dtv.osat.album',
        'com.sony.dtv.osat.music',
        'com.android.backupconfirm',
        'com.sony.dtv.osat.video',
        'com.sony.dtv.netproxyservice',
        'com.sony.dtv.webapi.core',
        'com.sony.dtv.b2b.hotellanguage',
        'com.sony.dtv.reminderservice',
        'com.sony.dtv.browser.webappservice',
        'com.sony.dtv.interactivetvutil.output',
        'com.sony.dtv.systemupdate',
        'com.sony.dtv.shopsettings',
        'com.sony.dtv.hbbtvlauncher',
        'com.sony.dtv.customersupport',
        'com.sony.huey.dlna.renderersettings',
        'com.sony.dtv.privacypolicy',
        'com.sony.dtv.browser.webappinstaller',
        'com.amazon.amazonvideo.livingroom',
        'com.android.sharedstoragebackup',
        'com.google.android.music',
        'com.android.printspooler',
        'com.sony.dtv.seconddispsetting',
        'com.sony.dtv.b2b.hotelmenu',
        'com.wbd.stream',
        'com.sony.dtv.ime.chww',
        'com.sony.dtv.imeproxy',
        'com.sony.dtv.enclave.service',
        'com.sony.dtv.youview',
        'com.sony.dtv.tvx.search.s101.tvprograms.cam',
        'com.sony.dtv.countrysetting',
        'com.sony.dtv.softwarelicense',
        'com.youview.tv.servicehost',
        'com.sony.dtv.recommendationservice',
        'com.google.android.syncadapters.contacts',
        'com.sony.dtv.quicksetup',
        'com.sony.dtv.woprecommendation',
        'com.sony.dtv.tvx.search.s201.netepg',
        'com.sony.dtv.tvx.search.s101.tvprograms.digital',
        'com.teamsmart.videomanager.tv',
        'com.google.android.tts',
        'com.impresa.opta',
        'com.google.android.videos',
        'com.sony.dtv.browser.ceb',
        'com.sony.dtv.dialservice',
        'com.sony.dtv.sonyselect',
        'com.android.proxyhandler',
        'com.google.android.feedback',
        'com.google.android.syncadapters.calendar',
        'com.sony.dtv.b2b.prosettings',
        'com.sony.dtv.b2b.importexport',
        'com.sony.dtv.smarthelp',
        'com.google.android.tv.bugreportsender',
        'mtktvapi.agent',
        'com.sony.dtv.netflixmanager',
        'com.sony.dtv.tvx.search.s501.psv',
        'com.sony.dtv.tuningconfirmation_dvbs',
        'com.sony.dtv.tuningconfirmation_dvbt',
        'com.sony.dtv.touchpad.tutorial',
        'screnmirroring.com',
        'ca.dstudio.atvlauncher.pro',
        'com.sony.dtv.watchtvrecommendation',
        'com.google.android.leanbacklauncher',
        'com.google.android.backuptransport',
        'com.sony.dtv.interactivetvutil',
        'com.opera.sdk.example',
        'com.sony.dtv.bravialifehack',
        'com.sony.dtv.nfcservice',
        'com.sony.dtv.tvx.search.s101.tvprograms.gensat',
        'com.android.vpndialogs',
        'com.sonyericsson.dlna.dtcpplayer',
        'com.android.wallpaperbackup',
        'com.sony.dtv.networkrecommendation',
        'com.sony.dtv.irbrecommendation',
        'com.sony.dtv.scrums.action',
        'com.sony.dtv.demomode',
        'com.google.android.tv.remote.service',
        'com.google.android.inputmethod.japanese',
        'com.b_lam.resplash',
        'com.sony.dtv.tvplayer',
        'com.amazon.aiv.eu',
        'com.google.android.play.games',
        'com.sony.dtv.bivlinfo',
        'com.sony.dtv.servermgr',
        'com.android.providers.contacts',
        'com.android.captiveportallogin',
        'com.disney.disneyplus',
        'com.sony.dtv.discovery',
        'com.sony.huey.dlna.module'
    )

    Write-Host ""
    Write-Host "This will re-enable $($nuclearPackages.Count) packages" -ForegroundColor Yellow
    Write-Host ""

    $confirm = Read-YesNo "Re-enable all packages?"
    if ($confirm) {
        Write-Host ""
        Write-Host "Re-enabling packages..." -ForegroundColor Yellow
        $successCount = 0
        $failCount = 0

        foreach ($pkg in $nuclearPackages) {
            Write-Host "  Enabling: $pkg" -ForegroundColor Gray
            try {
                Invoke-Adb -Args @('shell', "pm enable $pkg") -AllowFailure | Out-Null
                Invoke-Adb -Args @('shell', "cmd package install-existing --user 0 $pkg") -AllowFailure | Out-Null
                $successCount++
            }
            catch {
                $failCount++
            }
        }

        Write-Host ""
        Write-Host "Re-enable complete!" -ForegroundColor Green
        Write-Host "  Enabled: $successCount packages" -ForegroundColor Green
        if ($failCount -gt 0) {
            Write-Host "  Failed: $failCount packages" -ForegroundColor Yellow
        }
        Write-Host ""
        Write-Host "💡 Tip: Reboot TV for changes to take full effect" -ForegroundColor Cyan
    }
    else {
        Write-Host "Re-enable cancelled" -ForegroundColor Yellow
    }
    Done
}

function k1 {
    Write-Title "Get current proxy"
    Invoke-Adb -Args @('shell', 'settings get global http_proxy') -AllowFailure | Out-Null
    Done
}

function k2 {
    Write-Title "Set custom proxy"
    $proxy = Read-NonEmpty "Proxy (host:port)"
    Invoke-Adb -Args @('shell', "settings put global http_proxy $proxy") -AllowFailure | Out-Null
    Done
}

function k3 {
    Write-Title "Reset proxy"
    Invoke-Adb -Args @('shell', 'settings delete global http_proxy') -AllowFailure | Out-Null
    Invoke-Adb -Args @('shell', 'settings put global http_proxy :0') -AllowFailure | Out-Null
    Done
}

function k4 {
    Write-Title "Get proxy exclusion list"
    Invoke-Adb -Args @('shell', 'settings get global global_http_proxy_exclusion_list') -AllowFailure | Out-Null
    Done
}

function k5 {
    Write-Title "Set proxy exclusion list"
    Write-Host "Comma-separated hosts (e.g. localhost,127.0.0.1,*.example.com)" -ForegroundColor DarkGray
    $list = Read-NonEmpty "Exclusion list"
    Invoke-Adb -Args @('shell', "settings put global global_http_proxy_exclusion_list '$list'") -AllowFailure | Out-Null
    Done
}

function k6 {
    Write-Title "Reset proxy exclusion list"
    Invoke-Adb -Args @('shell', 'settings delete global global_http_proxy_exclusion_list') -AllowFailure | Out-Null
    Done
}

function l1 {
    Write-Title "Current Wi-Fi network"
    $status = Invoke-Adb -Args @('shell', 'cmd wifi status') -AllowFailure
    if ($status.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($status.Output)) {
        Write-Host "cmd wifi status not available; falling back to dumpsys wifi." -ForegroundColor DarkGray
        Invoke-Adb -Args @('shell', 'dumpsys wifi') -AllowFailure | Out-Null
    }
    Done
}

function l2 {
    Write-Title "Wi-Fi detailed information"
    Invoke-Adb -Args @('shell', 'dumpsys wifi') -AllowFailure | Out-Null
    Done
}

function l3 {
    Write-Title "Connect to known Wi-Fi network"
    $ssid = Read-NonEmpty "SSID"
    $help = Invoke-Adb -Args @('shell', 'cmd wifi help') -AllowFailure
    if ($help.Output -match 'connect-network|connectNetwork') {
        Invoke-Adb -Args @('shell', "cmd wifi connect-network '$ssid'") -AllowFailure | Out-Null
    }
    else {
        Write-Host "This Android build doesn't expose a stable 'cmd wifi connect-network' API." -ForegroundColor Yellow
        Write-Host "Opening Wi-Fi settings for manual selection." -ForegroundColor DarkGray
        Invoke-Adb -Args @('shell', 'am start -n com.android.settings/.wifi.WifiSettings') -AllowFailure | Out-Null
    }
    Done
}

function l4 {
    Write-Title "Connect to a new Wi-Fi network"
    $ssid = Read-NonEmpty "SSID"
    $pass = Read-NonEmpty "Password"
    $help = Invoke-Adb -Args @('shell', 'cmd wifi help') -AllowFailure
    if ($help.Output -match 'connect-network|connectNetwork') {
        Invoke-Adb -Args @('shell', "cmd wifi connect-network '$ssid' '$pass'") -AllowFailure | Out-Null
    }
    else {
        Write-Host "This Android build doesn't expose a stable 'cmd wifi connect-network' API." -ForegroundColor Yellow
        Write-Host "Opening Wi-Fi settings; you may need to enter credentials manually." -ForegroundColor DarkGray
        Invoke-Adb -Args @('shell', 'am start -n com.android.settings/.wifi.WifiSettings') -AllowFailure | Out-Null
    }
    Done
}

function l5 {
    Write-Title "Enable Wi-Fi display"
    Invoke-Adb -Args @('shell', 'settings put global wifi_display_on 1') -AllowFailure | Out-Null
    Done
}

function l6 {
    Write-Title "Disable Wi-Fi display"
    Invoke-Adb -Args @('shell', 'settings put global wifi_display_on 0') -AllowFailure | Out-Null
    Done
}

function m1 {
    Write-Title "Print custom text"
    $text = Read-NonEmpty "Text"
    Write-Host ""
    Write-Host $text
    Done
}

function n1 {
    Write-Title "Factory reset (MASTER_CLEAR broadcast)"
    Write-Host "DANGER: This will wipe the device." -ForegroundColor Red
    if (Read-YesNo "Really factory reset now?") {
        Invoke-Adb -Args @('shell', 'am broadcast -a android.intent.action.MASTER_CLEAR') -AllowFailure | Out-Null
    }
    Done
}

function n2 {
    Write-Title "Factory reset (recovery --wipe_data)"
    Write-Host "DANGER: This will wipe the device." -ForegroundColor Red
    if (Read-YesNo "Really factory reset via recovery now?") {
        Invoke-Adb -Args @('shell', 'recovery --wipe_data') -AllowFailure | Out-Null
    }
    Done
}

# --- Menu ---

$script:Menu = @(
    @('A1', 'Connect', 'a1'), @('A2', 'Disconnect', 'a2'), @('A3', 'List devices', 'a3'),
    @('B1', 'Start shell', 'b1'), @('B2', 'Logcat', 'b2'), @('B3', 'List ADB commands', 'b3'),
    @('C1', 'List processes', 'c1'), @('C2', 'List connections', 'c2'), @('C3', 'List services', 'c3'), @('C4', 'Check specific service', 'c4'),
    @('D1', 'Serial number', 'd1'), @('D2', 'Device state', 'd2'), @('D3', 'Get model', 'd3'), @('D4', 'Get features', 'd4'),
    @('D5', 'Memory information', 'd5'), @('D6', 'Free memory', 'd6'), @('D7', 'Processes (most cpu)', 'd7'), @('D8', 'Processes (most vss)', 'd8'),
    @('E1', 'Reboot', 'e1'), @('E2', 'Shutdown', 'e2'),
    @('F1', 'Get device name', 'f1'), @('F2', 'Get bluetooth name', 'f2'), @('F3', 'Get both names', 'f3'),
    @('F4', 'Set device name', 'f4'), @('F5', 'Set bluetooth name', 'f5'), @('F6', 'Set both names', 'f6'),
    @('G1', 'Start settings', 'g1'), @('G2', 'Open home', 'g2'), @('G3', 'Open URL', 'g3'), @('G4', 'Clear recent apps', 'g4'),
    @('H1', 'Density: current', 'h1'), @('H2', 'Density: set custom', 'h2'), @('H3', 'Density: set 260', 'h3'), @('H4', 'Density: reset', 'h4'),
    @('H5', 'Resolution: current', 'h5'), @('H6', 'Resolution: set custom', 'h6'), @('H7', 'Resolution: reset', 'h7'),
    @('H8', 'Animations: current', 'h8'), @('H9', 'Animations: set custom', 'h9'), @('H10', 'Animations: set 0.2x', 'h10'), @('H11', 'Animations: reset', 'h11'),
    @('I1', 'Apps: list all', 'i1'), @('I2', 'Apps: clear caches (trim)', 'i2'), @('I2A', 'Apps: clear cache all (loop)', 'i3a'), @('I3', 'Apps: reset permissions', 'i3'),
    @('I4', 'Apps: disable (debloat)', 'i4'), @('I5', 'Apps: enable (reverse)', 'i5'),
    @('I6', 'Apps: install', 'i6'), @('I7', 'Apps: install multi package', 'i7'),
    @('I8', 'Apps: enable', 'i8'), @('I9', 'Apps: disable', 'i9'),
    @('I10', 'Apps: uninstall', 'i10'), @('I11', 'Apps: force stop', 'i11'), @('I12', 'Apps: restart', 'i12'),
    @('I13', 'Apps: debloat Sony (preset)', 'i13'), @('I14', 'Apps: re-enable Sony (undo)', 'i14'),
    @('I15', 'Apps: debloat NUCLEAR ⚠️', 'i15'), @('I16', 'Apps: re-enable all (undo nuclear)', 'i16'),
    @('J1', 'Launcher: get current', 'j1'), @('J2', 'Launcher: set custom', 'j2'), @('J3', 'Launcher: enable', 'j3'), @('J4', 'Launcher: disable', 'j4'),
    @('K1', 'Proxy: get current', 'k1'), @('K2', 'Proxy: set custom', 'k2'), @('K3', 'Proxy: reset', 'k3'),
    @('K4', 'Proxy: get exclusions', 'k4'), @('K5', 'Proxy: set exclusions', 'k5'), @('K6', 'Proxy: reset exclusions', 'k6'),
    @('L1', 'Wi-Fi: current network', 'l1'), @('L2', 'Wi-Fi: detailed info', 'l2'),
    @('L3', 'Wi-Fi: connect known', 'l3'), @('L4', 'Wi-Fi: connect new', 'l4'),
    @('L5', 'Wi-Fi: enable display', 'l5'), @('L6', 'Wi-Fi: disable display', 'l6'),
    @('M1', 'Misc: print custom text', 'm1'),
    @('N1', 'Factory reset', 'n1'), @('N2', 'Factory reset (alt)', 'n2')
)

$script:ActionMap = @{}
foreach ($entry in $script:Menu) {
    $script:ActionMap[$entry[0].ToLowerInvariant()] = $entry[2]
    $script:ActionMap[$entry[2].ToLowerInvariant()] = $entry[2]
}

function Show-Menu {
    Clear-Host
    $Host.UI.RawUI.WindowTitle = "Sony Bravia Scripts $script:ScriptVer"

    Write-Host "Sony Bravia Scripts $script:ScriptVer" -ForegroundColor Black -BackgroundColor White
    Write-Host ""

    Write-Host "+ ADB connection" -ForegroundColor Red
    Write-Host "  (A1) Connect | (A2) Disconnect | (A3) List devices"

    Write-Host "+ General" -ForegroundColor Red
    Write-Host "  (B1) Start shell | (B2) Logcat | (B3) List ADB commands"

    Write-Host "+ Equipment processes" -ForegroundColor Red
    Write-Host "  (C1) List processes | (C2) List connections | (C3) List services"
    Write-Host "  (C4) Check specific service"

    Write-Host "+ Equipment information" -ForegroundColor Red
    Write-Host "  (D1) Serial number | (D2) Device state | (D3) Get model | (D4) Get features"
    Write-Host "  (D5) Memory information | (D6) Free memory | (D7) Processes (most cpu)"
    Write-Host "  (D8) Processes (most vss)"

    Write-Host "+ Power management" -ForegroundColor Red
    Write-Host "  (E1) Reboot | (E2) Shutdown"

    Write-Host "+ Device name" -ForegroundColor Red
    Write-Host "  (F1) Get device name | (F2) Get bluetooth name | (F3) Get both names"
    Write-Host "  (F4) Set device name | (F5) Set bluetooth name | (F6) Set both names"

    Write-Host "+ Activities" -ForegroundColor Red
    Write-Host "  (G1) Start settings | (G2) Open home | (G3) Open URL | (G4) Clear recent apps"

    Write-Host "+ Screen density" -ForegroundColor Red
    Write-Host "  (H1) Current | (H2) Set custom | (H3) Set to 260 | (H4) Reset"

    Write-Host "+ Screen resolution" -ForegroundColor Red
    Write-Host "  (H5) Current | (H6) Set custom | (H7) Reset"

    Write-Host "+ Screen animations" -ForegroundColor Red
    Write-Host "  (H8) Current | (H9) Set custom | (H10) Set to 0.2x | (H11) Reset"

    Write-Host "+ Applications" -ForegroundColor Red
    Write-Host "  (I1) List all | (I2) Clear caches (trim) | (I3) Reset permissions"
    Write-Host "  (I4) Disable apps | (I5) Enable apps"
    Write-Host "  (I6) Install | (I7) Install multi package | (I8) Enable | (I9) Disable"
    Write-Host "  (I10) Uninstall | (I11) Force stop | (I12) Restart"

    Write-Host "+ Default launcher (Home)" -ForegroundColor Red
    Write-Host "  (J1) Get current | (J2) Set custom | (J3) Enable | (J4) Disable"

    Write-Host "+ Proxy" -ForegroundColor Red
    Write-Host "  (K1) Get current | (K2) Set custom | (K3) Reset"
    Write-Host "  (K4) Get exclusions | (K5) Set exclusions | (K6) Reset exclusion list"

    Write-Host "+ Wi-Fi (Wireless networking)" -ForegroundColor Red
    Write-Host "  (L1) Current network | (L2) Current detailed network information"
    Write-Host "  (L3) Connect to known network | (L4) Connect to new network"
    Write-Host "  (L5) Enable Wi-Fi display | (L6) Disable Wi-Fi display"

    Write-Host "+ Miscellaneous" -ForegroundColor Red
    Write-Host "  (M1) Print custom text"

    Write-Host "+ Factory reset (danger zone)" -ForegroundColor Red
    Write-Host "  (N1) Factory reset | (N2) Factory reset (alternative method)"

    Write-Host ""
    Write-Host "(X) Exit script"
    Write-Host ""
}

function Invoke-Action {
    <#
  .SYNOPSIS
    Executes a menu action by its id (e.g. A1, h10).

  .PARAMETER Id
    The action identifier.

  .PARAMETER Quiet
    Suppresses the "Selected option"/"invalid option" prompt messages.
    Used by the TUI to reduce flicker.
  #>
    param(
        [Parameter(Mandatory)]
        [string]$Id,

        [switch]$Quiet
    )

    $key = $Id.Trim().ToLowerInvariant()
    if ($key -eq 'x') { return $false }

    if (-not $script:ActionMap.ContainsKey($key)) {
        if (-not $Quiet) {
            Write-Host ""
            Write-Host "Selected option '$Id' isn't valid. Please try again." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
        return $true
    }

    $fn = $script:ActionMap[$key]
    if (-not $Quiet) {
        Write-Host ""
        Write-Host "Selected option $Id." -ForegroundColor DarkGray
        Start-Sleep -Milliseconds 300
    }

    & $fn
    return $true
}

function Get-SectionTitleForId {
    <#
  .SYNOPSIS
    Maps an action id (A1, H10, etc) to a human section title.

  .DESCRIPTION
    Used by the TUI to group actions into readable sections.
    Screen-related ids (H*) are split into density/resolution/animations.
  #>
    param([Parameter(Mandatory)][string]$Id)

    $idUpper = $Id.Trim().ToUpperInvariant()

    if ($idUpper -match '^H(\d+)$') {
        $num = [int]$Matches[1]
        if ($num -ge 1 -and $num -le 4) { return 'Screen density' }
        if ($num -ge 5 -and $num -le 7) { return 'Screen resolution' }
        if ($num -ge 8 -and $num -le 11) { return 'Screen animations' }
        return 'Screen'
    }

    switch -Regex ($idUpper) {
        '^A\d+$' { return 'ADB connection' }
        '^B\d+$' { return 'General' }
        '^C\d+$' { return 'Equipment processes' }
        '^D\d+$' { return 'Equipment information' }
        '^E\d+$' { return 'Power management' }
        '^F\d+$' { return 'Device name' }
        '^G\d+$' { return 'Activities' }
        '^I\d+$' { return 'Applications' }
        '^J\d+$' { return 'Default launcher (Home)' }
        '^K\d+$' { return 'Proxy' }
        '^L\d+$' { return 'Wi‑Fi' }
        '^M\d+$' { return 'Miscellaneous' }
        '^N\d+$' { return 'Factory reset (danger zone)' }
        default { return 'Other' }
    }
}

function New-TuiModel {
    <#
  .SYNOPSIS
    Builds the list model that the TUI renders.

  .PARAMETER Filter
    Optional substring filter applied to "<id> <label>".

  .OUTPUTS
    A list of objects with Kind=header|item.
  #>
    param([string]$Filter)

    $filterText = ($Filter ?? '').Trim().ToLowerInvariant()

    $bySection = @{}
    foreach ($entry in $script:Menu) {
        $id = $entry[0]
        $label = $entry[1]
        $fn = $entry[2]

        $section = Get-SectionTitleForId -Id $id
        if (-not $bySection.ContainsKey($section)) { $bySection[$section] = @() }

        $search = ("$id $label".ToLowerInvariant())
        if ($filterText -and $search -notlike "*$filterText*") {
            continue
        }

        $bySection[$section] += [pscustomobject]@{
            Kind  = 'item'
            Id    = $id
            Label = $label
            Fn    = $fn
        }
    }

    $sectionOrder = @(
        'ADB connection',
        'General',
        'Equipment processes',
        'Equipment information',
        'Power management',
        'Device name',
        'Activities',
        'Screen density',
        'Screen resolution',
        'Screen animations',
        'Applications',
        'Default launcher (Home)',
        'Proxy',
        'Wi‑Fi',
        'Miscellaneous',
        'Factory reset (danger zone)',
        'Other'
    )

    $result = New-Object System.Collections.Generic.List[object]
    foreach ($sec in $sectionOrder) {
        if (-not $bySection.ContainsKey($sec)) { continue }
        $items = $bySection[$sec]
        if (-not $items -or $items.Count -eq 0) { continue }

        $result.Add([pscustomobject]@{ Kind = 'header'; Title = $sec })
        foreach ($it in $items) {
            $result.Add($it)
        }
    }

    return , $result
}

function Get-NextSelectableIndex {
    <#
  .SYNOPSIS
    Finds the next selectable row (skips headers).

  .DESCRIPTION
    The TUI list contains both headers and items; navigation must skip headers.
  #>
    param(
        [Parameter(Mandatory)]$Items,
        [Parameter(Mandatory)][int]$StartIndex,
        [Parameter(Mandatory)][int]$Direction
    )

    if ($Items.Count -eq 0) { return -1 }

    $idx = $StartIndex
    while ($true) {
        if ($idx -lt 0) { $idx = 0 }
        if ($idx -ge $Items.Count) { $idx = $Items.Count - 1 }

        if ($Items[$idx].Kind -eq 'item') { return $idx }

        $idx += $Direction
        if ($idx -lt 0 -or $idx -ge $Items.Count) {
            return -1
        }
    }
}

function Start-Tui {
    <#
  .SYNOPSIS
    Starts the interactive terminal UI.

  .DESCRIPTION
    Renders a simple, dependency-free TUI using Console APIs.
    Keyboard shortcuts:
      - Arrow keys: move selection
      - Enter: run selected action
      - / : filter actions
      - S : set/clear adb serial target
      - : : run by typing an action id
      - Esc/Q: quit
  #>
    [CmdletBinding()]
    param()

    # Keep the cursor invisible for a cleaner UI.
    $origCursorVisible = [Console]::CursorVisible
    $origTreatCtrlCAsInput = [Console]::TreatControlCAsInput
    [Console]::TreatControlCAsInput = $true

    try {
        [Console]::CursorVisible = $false

        $filter = ''
        $items = New-TuiModel -Filter $filter
        $selected = Get-NextSelectableIndex -Items $items -StartIndex 0 -Direction 1
        if ($selected -lt 0) { $selected = 0 }
        $scroll = 0

        $mode = 'browse' # browse | filter
        $filterEdit = ''

        while ($true) {
            # --- Render ---
            $width = [Math]::Max([Console]::WindowWidth, 40)
            $height = [Math]::Max([Console]::WindowHeight, 20)
            $listTop = 4
            $footerLines = 2
            $listHeight = [Math]::Max($height - $listTop - $footerLines, 5)

            if ($selected -lt $scroll) { $scroll = $selected }
            if ($selected -ge ($scroll + $listHeight)) { $scroll = $selected - $listHeight + 1 }
            if ($scroll -lt 0) { $scroll = 0 }

            [Console]::SetCursorPosition(0, 0)

            $title = " Sony Bravia Scripts $script:ScriptVer "
            $serialText = if ([string]::IsNullOrWhiteSpace($Serial)) { 'default' } else { $Serial }
            $right = "Serial: $serialText"
            $headerLine = $title
            if (($headerLine.Length + 1 + $right.Length) -lt $width) {
                $headerLine = $headerLine + (' ' * ($width - $headerLine.Length - $right.Length)) + $right
            }

            $oldFg = [Console]::ForegroundColor
            $oldBg = [Console]::BackgroundColor

            [Console]::ForegroundColor = [ConsoleColor]::Black
            [Console]::BackgroundColor = [ConsoleColor]::White
            [Console]::Write(($headerLine.PadRight($width)).Substring(0, $width))
            [Console]::WriteLine()

            [Console]::ForegroundColor = [ConsoleColor]::Gray
            [Console]::BackgroundColor = [ConsoleColor]::Black
            $filterShown = if ($mode -eq 'filter') { $filterEdit } else { $filter }
            $hint = if ($mode -eq 'filter') { 'Type to filter, Enter=apply, Esc=cancel' } else { '↑↓ move • Enter run • / filter • S serial • : command • Esc quit' }
            $line2 = "Filter: $filterShown"
            if ($line2.Length -lt $width) {
                $line2 = $line2 + (' ' * ($width - $line2.Length))
            }
            [Console]::Write(($line2).Substring(0, $width))
            [Console]::WriteLine()
            $line3 = $hint
            [Console]::Write(($line3.PadRight($width)).Substring(0, $width))
            [Console]::WriteLine()
            [Console]::WriteLine(('─' * $width).Substring(0, $width))

            # List
            for ($row = 0; $row -lt $listHeight; $row++) {
                $idx = $scroll + $row
                if ($idx -ge $items.Count) {
                    [Console]::ForegroundColor = [ConsoleColor]::DarkGray
                    [Console]::BackgroundColor = [ConsoleColor]::Black
                    [Console]::WriteLine((' ' * $width).Substring(0, $width))
                    continue
                }

                $it = $items[$idx]
                if ($it.Kind -eq 'header') {
                    [Console]::ForegroundColor = [ConsoleColor]::Yellow
                    [Console]::BackgroundColor = [ConsoleColor]::Black
                    $text = "  $($it.Title)"
                    [Console]::WriteLine(($text.PadRight($width)).Substring(0, $width))
                    continue
                }

                $isSelected = ($idx -eq $selected)
                if ($isSelected) {
                    [Console]::ForegroundColor = [ConsoleColor]::Black
                    [Console]::BackgroundColor = [ConsoleColor]::Cyan
                }
                else {
                    [Console]::ForegroundColor = [ConsoleColor]::Gray
                    [Console]::BackgroundColor = [ConsoleColor]::Black
                }

                $text = "  [$($it.Id)] $($it.Label)"
                [Console]::WriteLine(($text.PadRight($width)).Substring(0, $width))
            }

            [Console]::ForegroundColor = [ConsoleColor]::DarkGray
            [Console]::BackgroundColor = [ConsoleColor]::Black
            [Console]::WriteLine(('─' * $width).Substring(0, $width))
            $footer = "Actions: $($items | Where-Object { $_.Kind -eq 'item' } | Measure-Object | Select-Object -ExpandProperty Count)"
            [Console]::WriteLine(($footer.PadRight($width)).Substring(0, $width))

            [Console]::ForegroundColor = $oldFg
            [Console]::BackgroundColor = $oldBg

            # --- Input ---
            $key = [Console]::ReadKey($true)

            if ($mode -eq 'filter') {
                switch ($key.Key) {
                    'Escape' {
                        $mode = 'browse'
                        $filterEdit = ''
                        continue
                    }
                    'Enter' {
                        $filter = $filterEdit
                        $filterEdit = ''
                        $mode = 'browse'
                        $items = New-TuiModel -Filter $filter
                        $selected = Get-NextSelectableIndex -Items $items -StartIndex 0 -Direction 1
                        if ($selected -lt 0) { $selected = 0 }
                        $scroll = 0
                        continue
                    }
                    'Backspace' {
                        if ($filterEdit.Length -gt 0) {
                            $filterEdit = $filterEdit.Substring(0, $filterEdit.Length - 1)
                        }
                        continue
                    }
                    default {
                        if ($key.KeyChar -and -not [char]::IsControl($key.KeyChar)) {
                            $filterEdit += $key.KeyChar
                        }
                        continue
                    }
                }
            }

            switch ($key.Key) {
                'Escape' { return }
                'Q' { return }

                'UpArrow' {
                    $next = $selected - 1
                    if ($next -lt 0) { $next = 0 }
                    $sel = Get-NextSelectableIndex -Items $items -StartIndex $next -Direction -1
                    if ($sel -ge 0) { $selected = $sel }
                }
                'DownArrow' {
                    $next = $selected + 1
                    if ($next -ge $items.Count) { $next = $items.Count - 1 }
                    $sel = Get-NextSelectableIndex -Items $items -StartIndex $next -Direction 1
                    if ($sel -ge 0) { $selected = $sel }
                }
                'PageUp' {
                    $next = [Math]::Max($selected - 10, 0)
                    $sel = Get-NextSelectableIndex -Items $items -StartIndex $next -Direction -1
                    if ($sel -ge 0) { $selected = $sel }
                }
                'PageDown' {
                    $next = [Math]::Min($selected + 10, $items.Count - 1)
                    $sel = Get-NextSelectableIndex -Items $items -StartIndex $next -Direction 1
                    if ($sel -ge 0) { $selected = $sel }
                }
                'Home' {
                    $sel = Get-NextSelectableIndex -Items $items -StartIndex 0 -Direction 1
                    if ($sel -ge 0) { $selected = $sel }
                }
                'End' {
                    $sel = Get-NextSelectableIndex -Items $items -StartIndex ($items.Count - 1) -Direction -1
                    if ($sel -ge 0) { $selected = $sel }
                }
                'Enter' {
                    if ($items.Count -eq 0) { break }
                    $it = $items[$selected]
                    if ($it.Kind -ne 'item') { break }

                    [Console]::Clear()
                    Invoke-Action -Id $it.Id -Quiet | Out-Null

                    # Back to TUI
                    [Console]::Clear()
                    $items = New-TuiModel -Filter $filter
                    $selected = Get-NextSelectableIndex -Items $items -StartIndex $selected -Direction 1
                    if ($selected -lt 0) { $selected = Get-NextSelectableIndex -Items $items -StartIndex 0 -Direction 1 }
                    if ($selected -lt 0) { $selected = 0 }
                }
                default {
                    # Character shortcuts
                    if ($key.KeyChar -eq '/') {
                        $mode = 'filter'
                        $filterEdit = $filter
                        continue
                    }

                    if ($key.KeyChar -eq ':') {
                        [Console]::Clear()
                        $cmd = Read-Host "Action (e.g. A1, h10) or X"
                        if ($cmd) {
                            Invoke-Action -Id $cmd | Out-Null
                        }
                        [Console]::Clear()
                        continue
                    }

                    if ($key.KeyChar -and $key.KeyChar.ToString().ToLowerInvariant() -eq 's') {
                        [Console]::Clear()
                        $newSerial = Read-Host "ADB Serial (blank = default)"
                        $script:Serial = ($newSerial ?? '').Trim()
                        [Console]::Clear()
                        continue
                    }
                }
            }
        }
    }
    finally {
        [Console]::CursorVisible = $origCursorVisible
        [Console]::TreatControlCAsInput = $origTreatCtrlCAsInput
    }
}

# Skip script execution if being sourced for testing
if ($env:PESTER_RUN) {
    return
}

try {
    # Initialize configuration and history
    Initialize-Config

    # Load configuration
    $config = Get-Config

    # Use default serial from config if not specified
    if (-not $Serial -and $config -and $config.defaultSerial) {
        $Serial = $config.defaultSerial
        Write-Log "Using default serial from config: $Serial" -Level Verbose
    }

    # Check connection if requested or configured
    if ($CheckConnection -or ($config -and $config.checkConnectionBeforeAction)) {
        if (-not (Test-AdbConnection)) {
            Write-Log "Warning: No ADB connection detected. Some operations may fail." -Level Warning
        }
    }

    # Batch mode from file
    if ($Batch) {
        if (-not (Test-Path $Batch)) {
            throw "Batch file not found: $Batch"
        }

        $actions = Get-Content $Batch | Where-Object { $_ -and $_ -notmatch '^\s*#' }
        Write-Log "Processing $($actions.Count) actions from batch file..." -Level Info

        $results = @()
        foreach ($batchAction in $actions) {
            try {
                Write-Log "Executing: $batchAction" -Level Info
                $result = Invoke-Action -Id $batchAction -Quiet
                $results += [pscustomobject]@{
                    Action  = $batchAction
                    Success = $true
                    Error   = $null
                }
                Add-ToHistory -Action $batchAction -Serial $Serial -Success $true -ErrorMessage $null
            }
            catch {
                $results += [pscustomobject]@{
                    Action  = $batchAction
                    Success = $false
                    Error   = $_.Exception.Message
                }
                Add-ToHistory -Action $batchAction -Serial $Serial -Success $false -ErrorMessage $_.Exception.Message
                Write-Log "Error executing $batchAction : $($_.Exception.Message)" -Level Error
            }
        }

        # Output results
        if ($OutputFormat -eq 'JSON') {
            $results | ConvertTo-Json
        }
        elseif ($OutputFormat -eq 'CSV') {
            $results | ConvertTo-Csv -NoTypeInformation
        }
        else {
            Write-Host "`nBatch Summary:" -ForegroundColor Cyan
            $results | Format-Table -AutoSize
        }

        $failedCount = ($results | Where-Object { -not $_.Success }).Count
        exit $(if ($failedCount -gt 0) { 1 } else { 0 })
    }

    # Comma-separated batch mode
    if ($Action -and $Action.Contains(',')) {
        $actions = $Action -split ',' | ForEach-Object { $_.Trim() }
        Write-Log "Processing $($actions.Count) actions in batch mode..." -Level Info

        $results = @()
        foreach ($batchAction in $actions) {
            try {
                Write-Log "Executing: $batchAction" -Level Info
                $result = Invoke-Action -Id $batchAction -Quiet
                $results += [pscustomobject]@{
                    Action  = $batchAction
                    Success = $true
                    Error   = $null
                }
                Add-ToHistory -Action $batchAction -Serial $Serial -Success $true -ErrorMessage $null
            }
            catch {
                $results += [pscustomobject]@{
                    Action  = $batchAction
                    Success = $false
                    Error   = $_.Exception.Message
                }
                Add-ToHistory -Action $batchAction -Serial $Serial -Success $false -ErrorMessage $_.Exception.Message
                Write-Log "Error executing $batchAction : $($_.Exception.Message)" -Level Error
            }
        }

        # Output results
        if ($OutputFormat -eq 'JSON') {
            $results | ConvertTo-Json
        }
        elseif ($OutputFormat -eq 'CSV') {
            $results | ConvertTo-Csv -NoTypeInformation
        }
        else {
            Write-Host "`nBatch Summary:" -ForegroundColor Cyan
            $results | Format-Table -AutoSize
        }

        $failedCount = ($results | Where-Object { -not $_.Success }).Count
        exit $(if ($failedCount -gt 0) { 1 } else { 0 })
    }

    # Single action mode
    if ($Action) {
        try {
            Invoke-Action -Id $Action | Out-Null
            Add-ToHistory -Action $Action -Serial $Serial -Success $true -ErrorMessage $null
            exit 0
        }
        catch {
            Add-ToHistory -Action $Action -Serial $Serial -Success $false -ErrorMessage $_.Exception.Message
            throw
        }
    }

    # Interactive TUI mode
    Start-Tui
}
catch {
    if ($script:OutputFormat -eq 'JSON') {
        @{
            success   = $false
            error     = $_.Exception.Message
            timestamp = (Get-Date).ToString('o')
        } | ConvertTo-Json
    }
    else {
        Write-Host ""
        Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        if (-not $script:QuietMode) {
            Write-Host "Troubleshooting tips:" -ForegroundColor Yellow
            Write-Host "  1. Verify ADB is installed and in PATH: adb version" -ForegroundColor Gray
            Write-Host "  2. Check device connection: adb devices" -ForegroundColor Gray
            Write-Host "  3. Enable USB debugging on your TV" -ForegroundColor Gray
            Write-Host "  4. Try reconnecting: adb disconnect; adb connect <ip>:5555" -ForegroundColor Gray
            Write-Host "  5. See troubleshooting guide: docs/TROUBLESHOOTING.md" -ForegroundColor Gray
            Write-Host ""
        }
        Wait-ForContinue
    }
    exit 1
}
