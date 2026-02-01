# Troubleshooting Guide

This guide covers common issues and their solutions when using Sony Bravia ADB Scripts.

## Table of Contents

- [Connection Issues](#connection-issues)
- [ADB Issues](#adb-issues)
- [Script Execution Issues](#script-execution-issues)
- [TV-Specific Issues](#tv-specific-issues)
- [Performance Issues](#performance-issues)
- [Advanced Troubleshooting](#advanced-troubleshooting)

## Connection Issues

### Cannot connect to TV

**Symptoms:**
- `adb connect` fails with "connection refused" or timeout
- Script cannot communicate with TV
- "device offline" or "no devices" error

**Solutions:**

1. **Verify TV IP address**
   ```bash
   # Get TV IP from: Settings > Network & Internet > Advanced Settings > Network Status
   # Test network connectivity
   ping <tv-ip>
   ```

2. **Enable USB Debugging**
   - Navigate to: Settings > Network & Internet > Home Network Setup > IP Control
   - Set Authentication to "Normal and Pre-Shared Key"
   - Note: Location may vary by TV model and firmware version

3. **Check firewall**
   ```powershell
   # Windows: Allow ADB port
   New-NetFirewallRule -DisplayName "ADB" -Direction Outbound -LocalPort 5555 -Protocol TCP -Action Allow
   ```

4. **Reset ADB connection**
   ```bash
   adb kill-server
   adb start-server
   adb connect <tv-ip>:5555
   ```

5. **Verify ADB port**
   - Sony Bravia TVs use port 5555 by default
   - Ensure nothing else is using this port
   ```bash
   # Windows
   netstat -ano | findstr :5555
   
   # macOS/Linux
   lsof -i :5555
   ```

### Device shows as "offline"

**Symptoms:**
- `adb devices` shows device as "offline"
- Commands fail with "device offline" error

**Solutions:**

1. **Disconnect and reconnect**
   ```bash
   adb disconnect <tv-ip>
   sleep 2
   adb connect <tv-ip>:5555
   ```

2. **Check TV power state**
   - Ensure TV is fully powered on (not in standby)
   - Some TVs disable ADB in standby mode

3. **Restart ADB server**
   ```bash
   adb kill-server
   adb start-server
   ```

4. **Verify network stability**
   - Use wired connection if possible
   - Check for WiFi interference
   - Ensure TV has stable IP (consider DHCP reservation)

### Connection drops frequently

**Symptoms:**
- Need to reconnect frequently
- Commands intermittently fail
- "protocol fault" errors

**Solutions:**

1. **Use static IP or DHCP reservation**
   ```bash
   # In router settings, reserve IP for TV's MAC address
   ```

2. **Increase retry count in config**
   ```json
   {
     "retryCount": 5,
     "retryDelay": 2000,
     "checkConnectionBeforeAction": true
   }
   ```

3. **Check network quality**
   ```bash
   # Test connection stability
   ping -t <tv-ip>  # Windows
   ping <tv-ip>     # macOS/Linux (Ctrl+C to stop)
   ```

4. **Update TV firmware**
   - Check for Sony TV updates: Settings > System > About > System Software Update

## ADB Issues

### ADB not found

**Symptoms:**
- "adb: command not found" error
- Installation scripts fail to run

**Solutions:**

1. **Install ADB using installer**
   ```powershell
   # Windows
   .\install.ps1
   
   # macOS/Linux
   ./install.sh
   ```

2. **Manual installation**
   
   **Windows (Chocolatey):**
   ```powershell
   choco install adb
   ```
   
   **macOS (Homebrew):**
   ```bash
   brew install android-platform-tools
   ```
   
   **Linux (Ubuntu/Debian):**
   ```bash
   sudo apt-get install adb
   ```
   
   **Manual download:**
   - Download platform-tools from: https://developer.android.com/studio/releases/platform-tools
   - Extract and add to PATH

3. **Verify installation**
   ```bash
   adb version
   # Should show: Android Debug Bridge version X.X.X
   ```

### ADB version too old

**Symptoms:**
- Some commands fail unexpectedly
- Script reports compatibility issues

**Solutions:**

1. **Update platform-tools**
   ```bash
   # Check current version
   adb version
   
   # Update via package manager
   brew upgrade android-platform-tools  # macOS
   choco upgrade adb                    # Windows
   sudo apt-get update && sudo apt-get upgrade adb  # Linux
   ```

2. **Manual update**
   - Download latest platform-tools from Google
   - Replace existing installation
   - Restart terminal

### ADB server conflicts

**Symptoms:**
- "cannot bind to socket" error
- ADB fails to start
- Port 5037 conflicts

**Solutions:**

1. **Kill conflicting processes**
   ```bash
   # Find processes using ADB port
   # Windows
   netstat -ano | findstr :5037
   taskkill /PID <pid> /F
   
   # macOS/Linux
   lsof -t -i :5037 | xargs kill -9
   ```

2. **Restart ADB server**
   ```bash
   adb kill-server
   adb start-server
   ```

## Script Execution Issues

### PowerShell execution policy errors

**Symptoms:**
- "cannot be loaded because running scripts is disabled" error
- Script refuses to run

**Solutions:**

1. **Use launcher (recommended)**
   ```cmd
   # Windows
   sony-bravia-scripts.cmd
   
   # macOS/Linux
   ./sony-bravia-scripts.sh
   ```
   Launchers automatically handle execution policy.

2. **Bypass execution policy temporarily**
   ```powershell
   powershell -ExecutionPolicy Bypass -File sony-bravia-scripts.ps1
   ```

3. **Change execution policy (permanent)**
   ```powershell
   # Run as Administrator
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

### PowerShell 5 vs 7 issues

**Symptoms:**
- Script fails with syntax errors on Windows PowerShell 5
- Features work inconsistently

**Solutions:**

1. **Install PowerShell 7+** (recommended)
   ```powershell
   # Windows
   winget install Microsoft.PowerShell
   
   # macOS
   brew install --cask powershell
   
   # Linux
   sudo snap install powershell --classic
   ```

2. **Check PowerShell version**
   ```powershell
   $PSVersionTable.PSVersion
   # Should be 7.0 or higher
   ```

3. **Use pwsh command**
   ```bash
   pwsh sony-bravia-scripts.ps1
   ```

### Configuration file issues

**Symptoms:**
- Settings not persisting
- "Cannot parse config file" error

**Solutions:**

1. **Reset configuration**
   ```powershell
   Remove-Item ~/.sony-bravia-scripts/config.json
   # Script will recreate on next run
   ```

2. **Validate JSON**
   ```powershell
   Get-Content ~/.sony-bravia-scripts/config.json | ConvertFrom-Json
   ```

3. **Check permissions**
   ```bash
   # Ensure directory is writable
   ls -la ~/.sony-bravia-scripts/
   chmod 755 ~/.sony-bravia-scripts/
   ```

### History not recording

**Symptoms:**
- Command history file empty or not updating
- `Get-History` shows no results

**Solutions:**

1. **Check file permissions**
   ```bash
   ls -la ~/.sony-bravia-scripts/history.json
   chmod 644 ~/.sony-bravia-scripts/history.json
   ```

2. **Verify disk space**
   ```bash
   df -h ~  # Unix
   Get-PSDrive C  # Windows
   ```

3. **Reset history**
   ```powershell
   Remove-Item ~/.sony-bravia-scripts/history.json
   ```

## TV-Specific Issues

### Commands don't work on my TV model

**Symptoms:**
- Some actions have no effect
- Errors like "unknown command" or "not supported"

**Solutions:**

1. **Check TV model compatibility**
   - Script designed for Sony Bravia Android TVs (2015+)
   - Some features require specific Android versions
   - Verify TV runs Android TV OS

2. **Update TV firmware**
   - Settings > System > About > System Software Update
   - Some features added in newer firmware versions

3. **Try alternative actions**
   - Some functions have multiple implementations
   - Check action descriptions in menu

4. **Report compatibility issues**
   - Note TV model and Android version
   - Report non-working actions on GitHub

### TV enters standby after commands

**Symptoms:**
- TV turns off after certain actions
- Screen goes black unexpectedly

**Solutions:**

1. **Disable sleep timers**
   - Settings > System > Power & Energy > Sleep Timer
   - Set to "Off"

2. **Adjust idle TV off**
   - Settings > System > Power & Energy > Idle TV Off
   - Set to longer duration or "Never"

3. **Check eco mode**
   - Settings > System > Power & Energy > Eco
   - Disable eco features if interfering

### TV doesn't respond to input

**Symptoms:**
- Input commands sent but no effect
- Apps don't launch

**Solutions:**

1. **Verify TV focus**
   - Ensure TV is on and responsive
   - Not in a modal dialog or setup screen

2. **Check input delay**
   - Some commands need time between inputs
   - Use batch mode with delays if needed

3. **Test with basic commands**
   ```bash
   # Test simple navigation
   adb shell input keyevent KEYCODE_HOME
   adb shell input keyevent KEYCODE_BACK
   ```

### Screen mirroring issues

**Symptoms:**
- Cannot start screen recording/mirroring
- Blank screen when recording

**Solutions:**

1. **Check HDCP protection**
   - Some content protected by HDCP
   - Cannot be captured via screencap/screenrecord

2. **Verify permissions**
   ```bash
   adb shell dumpsys window policy | grep mInputRestricted
   ```

3. **Use alternative capture methods**
   - Some apps block screen capture
   - Try capturing different content

## Performance Issues

### Slow command execution

**Symptoms:**
- Commands take long to execute
- TUI feels sluggish

**Solutions:**

1. **Check network latency**
   ```bash
   ping -c 10 <tv-ip>
   # Look for average latency
   ```

2. **Use wired connection**
   - Switch TV to Ethernet
   - Reduces latency and improves stability

3. **Optimize batch operations**
   ```powershell
   # Use batch file instead of sequential commands
   sony-bravia-scripts.ps1 -Batch actions.txt
   ```

4. **Enable quiet mode**
   ```powershell
   # Suppress unnecessary output
   sony-bravia-scripts.ps1 -Action a1 -Quiet
   ```

### High CPU usage

**Symptoms:**
- PowerShell process uses excessive CPU
- System becomes unresponsive

**Solutions:**

1. **Close other ADB clients**
   - Android Studio
   - Other ADB tools
   - Scrcpy, Vysor, etc.

2. **Limit concurrent operations**
   - Don't run multiple script instances
   - Use batch mode instead

3. **Update PowerShell**
   ```powershell
   pwsh --version
   # Update if < 7.4
   ```

## Advanced Troubleshooting

### Enable verbose logging

```powershell
# Run with verbose output
sony-bravia-scripts.ps1 -Verbose

# Or set in config
{
  "verboseLogging": true
}
```

### Capture ADB traffic

```bash
# Enable ADB logging
export ADB_TRACE=all
adb logcat

# Windows
set ADB_TRACE=all
adb logcat
```

### Debug script execution

```powershell
# Enable PowerShell debugging
$DebugPreference = 'Continue'
.\sony-bravia-scripts.ps1

# Trace script execution
Set-PSDebug -Trace 2
.\sony-bravia-scripts.ps1
Set-PSDebug -Trace 0
```

### Network packet capture

```bash
# Capture ADB traffic (requires root/admin)
# Windows
netsh trace start capture=yes tracefile=adb.etl

# macOS/Linux
sudo tcpdump -i any port 5555 -w adb.pcap

# Stop capture
netsh trace stop  # Windows
# Ctrl+C on macOS/Linux
```

### Check TV system info

```bash
# Get Android version
adb shell getprop ro.build.version.release

# Get device model
adb shell getprop ro.product.model

# Get Sony model
adb shell getprop ro.semc.product.model

# List installed packages
adb shell pm list packages

# Check running services
adb shell dumpsys activity services
```

### Reset TV ADB

```bash
# Disable and re-enable debugging on TV
# Or restart TV
adb shell reboot

# Wait for TV to restart, then reconnect
adb connect <tv-ip>:5555
```

## Getting Help

If you're still experiencing issues:

1. **Check FAQ**: See [FAQ.md](FAQ.md) for common questions
2. **Search issues**: Check [GitHub Issues](https://github.com/yourusername/sony-bravia-adb-scripts/issues)
3. **Collect debug info**:
   ```bash
   # ADB version
   adb version
   
   # PowerShell version
   pwsh --version
   
   # TV info
   adb shell getprop ro.build.version.release
   adb shell getprop ro.product.model
   
   # Connection status
   adb devices -l
   ```

4. **Create issue**: Include debug info and steps to reproduce
5. **Check recipes**: See [RECIPES.md](RECIPES.md) for example workflows

## Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `error: no devices/emulators found` | Not connected to TV | Run `adb connect <tv-ip>:5555` |
| `error: device offline` | Connection lost | Disconnect and reconnect |
| `error: protocol fault (no status)` | Network issue | Check connection, restart ADB |
| `error: closed` | Connection closed by TV | Reconnect, check TV power state |
| `more than one device/emulator` | Multiple devices connected | Specify device with `-Serial` |
| `cannot be loaded because running scripts is disabled` | Execution policy | Use launcher or bypass policy |
| `The term 'adb' is not recognized` | ADB not in PATH | Install ADB or add to PATH |
| `The term 'pwsh' is not recognized` | PowerShell 7 not installed | Install PowerShell 7 |
| `unauthorized` | USB debugging not authorized | Check TV for authorization prompt |
| `insufficient permissions` | Permission denied | Check TV settings, restart ADB |

---

**Last Updated:** December 2024  
**Version:** 2.0
