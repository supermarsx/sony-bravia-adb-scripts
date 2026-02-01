# Frequently Asked Questions (FAQ)

Common questions and answers about Sony Bravia ADB Scripts.

## General Questions

### What is this project?

Sony Bravia ADB Scripts is a cross-platform PowerShell script that provides comprehensive control over Sony Bravia Android TVs using the Android Debug Bridge (ADB). It offers both an interactive TUI menu and CLI interface with 70+ control actions.

### Which TVs are supported?

The script supports Sony Bravia Android TVs from 2015 onwards that run Android TV OS. This includes most modern Sony smart TVs. Check your TV model's specifications to confirm it runs Android TV.

### Do I need to root my TV?

No, rooting is not required. The script uses standard ADB commands that work on unrooted Android TV devices with USB debugging enabled.

### Is this official Sony software?

No, this is an independent, community-developed project. It is not affiliated with or endorsed by Sony Corporation.

### Is it safe to use?

Yes, the script only uses standard ADB commands. However, some actions (like factory reset, clearing app data) are destructive. The script prompts for confirmation before executing dangerous operations.

## Installation and Setup

### How do I install the script?

**Windows:**
```powershell
.\install.ps1
```

**macOS/Linux:**
```bash
chmod +x install.sh
./install.sh
```

The installer will automatically install dependencies (ADB, PowerShell 7) if needed.

### Do I need PowerShell 7?

PowerShell 7+ is highly recommended for full cross-platform compatibility. The script may work on PowerShell 5.1 (Windows PowerShell), but some features might not function correctly.

### How do I enable USB debugging on my TV?

1. Go to TV Settings
2. Navigate to: Network & Internet > Home Network Setup > IP Control
3. Set Authentication to "Normal and Pre-Shared Key"

Note: Menu paths may vary slightly by TV model and firmware version.

### How do I find my TV's IP address?

Go to TV Settings > Network & Internet > Advanced Settings > Network Status. The IP address will be displayed there.

Alternatively, check your router's connected devices list.

### The script can't find my TV. What should I do?

1. Verify USB debugging is enabled on TV
2. Ensure TV and computer are on same network
3. Test connectivity: `ping <tv-ip>`
4. Manually connect: `adb connect <tv-ip>:5555`
5. Check firewall settings
6. See [Troubleshooting Guide](TROUBLESHOOTING.md#connection-issues)

### Can I use this wirelessly?

Yes! ADB over TCP/IP is wireless. Once you connect using `adb connect <tv-ip>:5555`, all subsequent commands are sent over WiFi/Ethernet.

## Usage Questions

### How do I run the script?

**Interactive TUI mode:**
```powershell
.\sony-bravia-scripts.cmd  # Windows
./sony-bravia-scripts.sh   # macOS/Linux
```

**CLI mode:**
```powershell
sony-bravia-scripts.ps1 -Action a1  # Execute action a1 (Home)
```

### What are action codes?

Action codes are short identifiers (like `a1`, `f11`, `g1`) that map to specific TV functions:
- `a*` - Navigation (a1=Home, a2=Back, etc.)
- `b*` - System functions
- `d*` - Settings
- `e*` - Media controls
- `f*` - Audio controls
- `g*` - App launchers
- `h*` - Power management
- `i*` - Information
- `j*` - Display

See the interactive menu for a complete list.

### Can I execute multiple actions at once?

Yes, using batch mode:

**Comma-separated:**
```powershell
sony-bravia-scripts.ps1 -Action "a1,a7,a5,a9"  # Home, Right, Down, OK
```

**From file:**
```powershell
sony-bravia-scripts.ps1 -Batch actions.txt
```

### How do I automate TV control?

Use scheduled tasks (Windows) or cron (macOS/Linux):

**Windows Task Scheduler:**
```powershell
$action = New-ScheduledTaskAction -Execute "pwsh" -Argument "-File C:\Path\To\sony-bravia-scripts.ps1 -Action f14 -Quiet"
$trigger = New-ScheduledTaskTrigger -Daily -At "11:00PM"
Register-ScheduledTask -TaskName "Mute TV" -Action $action -Trigger $trigger
```

**Cron:**
```bash
0 23 * * * /usr/local/bin/pwsh /path/to/sony-bravia-scripts.ps1 -Action f14 -Quiet
```

See [Recipes](RECIPES.md#automation) for more examples.

### Can I control multiple TVs?

Yes, use the `-Serial` parameter:

```powershell
sony-bravia-scripts.ps1 -Action f14 -Serial 192.168.1.100:5555  # TV 1
sony-bravia-scripts.ps1 -Action f14 -Serial 192.168.1.101:5555  # TV 2
```

Or set a default in config:
```json
{
  "defaultSerial": "192.168.1.100:5555"
}
```

### What output formats are supported?

- **Text** (default): Human-readable output
- **JSON**: Machine-readable structured data
- **CSV**: Tabular format for spreadsheets

```powershell
sony-bravia-scripts.ps1 -Action a1 -OutputFormat JSON
sony-bravia-scripts.ps1 -Batch actions.txt -OutputFormat CSV > results.csv
```

### How do I suppress output?

Use the `-Quiet` flag:

```powershell
sony-bravia-scripts.ps1 -Action a1 -Quiet
```

### Where is command history stored?

Command history is stored in `~/.sony-bravia-scripts/history.json` (up to 100 most recent commands).

View history:
```powershell
Get-Content ~/.sony-bravia-scripts/history.json | ConvertFrom-Json | Select-Object -Last 20
```

## Configuration

### Where is the configuration file?

`~/.sony-bravia-scripts/config.json`

- Windows: `C:\Users\<username>\.sony-bravia-scripts\config.json`
- macOS/Linux: `/home/<username>/.sony-bravia-scripts/config.json`

### What can I configure?

```json
{
  "defaultSerial": "192.168.1.100:5555",
  "retryCount": 3,
  "retryDelay": 2000,
  "checkConnectionBeforeAction": true,
  "verboseLogging": false
}
```

- `defaultSerial`: Default TV to connect to
- `retryCount`: Number of retry attempts for failed commands
- `retryDelay`: Milliseconds between retries
- `checkConnectionBeforeAction`: Validate connection before executing
- `verboseLogging`: Enable detailed logging

### How do I reset configuration?

Delete the config file:
```powershell
Remove-Item ~/.sony-bravia-scripts/config.json
```

The script will recreate it with defaults on next run.

## Features

### Does it support voice control?

Not natively, but you can integrate with voice assistants:
- Windows Speech Recognition
- Google Assistant (via Home Assistant)
- Alexa (via custom skills)

See [Recipes](RECIPES.md#voice-control-integration) for examples.

### Can I use this with Home Assistant?

Yes! Use shell commands:

```yaml
shell_command:
  tv_home: "pwsh /path/to/sony-bravia-scripts.ps1 -Action a1 -Quiet"
  tv_netflix: "pwsh /path/to/sony-bravia-scripts.ps1 -Action g1 -Quiet"
```

See [Recipes](RECIPES.md#integration-with-home-assistant) for complete example.

### Can I launch any app?

Yes, via direct ADB commands:

```powershell
# Launch by package name
adb shell monkey -p com.netflix.ninja -c android.intent.category.LAUNCHER 1

# Or use deep links
adb shell am start -a android.intent.action.VIEW -d "https://www.youtube.com/watch?v=VIDEO_ID"
```

Predefined app launchers (g1-g12) are available for common apps.

### Does it support screen mirroring?

The script can capture screenshots and record video, but live mirroring requires additional tools like [scrcpy](https://github.com/Genymobile/scrcpy).

### Can I transfer files to/from TV?

Yes, using ADB:

```bash
# Push file to TV
adb push local_file.txt /sdcard/

# Pull file from TV
adb pull /sdcard/file.txt local_file.txt
```

### Does it work with Sony projectors?

If the projector runs Android TV and supports ADB, it should work. However, this hasn't been extensively tested.

## Troubleshooting

### Why do commands fail intermittently?

Common causes:
1. Network instability (use wired connection)
2. TV in standby/low-power mode
3. ADB server issues (restart with `adb kill-server; adb start-server`)
4. Firewall blocking port 5555

Enable connection checking:
```powershell
sony-bravia-scripts.ps1 -CheckConnection
```

### Connection keeps dropping

1. Use static IP or DHCP reservation for TV
2. Increase retry settings in config
3. Check network quality: `ping -t <tv-ip>`
4. Update TV firmware
5. See [Troubleshooting Guide](TROUBLESHOOTING.md#connection-drops-frequently)

### Some actions don't work on my TV

TV models and firmware versions have varying feature support. Some actions may not work on older models or may require specific firmware versions.

If an action doesn't work:
1. Update TV firmware
2. Try alternative actions
3. Report compatibility issue on GitHub

### Script hangs or freezes

1. Check if TV is responsive
2. Restart ADB server: `adb kill-server; adb start-server`
3. Run with verbose logging: `sony-bravia-scripts.ps1 -Verbose`
4. Check for multiple ADB clients running
5. See [Troubleshooting Guide](TROUBLESHOOTING.md#performance-issues)

### Error: "execution policy"

Windows PowerShell restricts script execution by default.

**Solution 1:** Use launcher (recommended)
```cmd
sony-bravia-scripts.cmd
```

**Solution 2:** Bypass policy temporarily
```powershell
powershell -ExecutionPolicy Bypass -File sony-bravia-scripts.ps1
```

**Solution 3:** Change policy (permanent)
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Error: "adb not found"

ADB is not installed or not in PATH.

**Solution:** Run installer
```powershell
.\install.ps1  # Automatically installs ADB
```

**Or install manually:**
- Windows: `choco install adb`
- macOS: `brew install android-platform-tools`
- Linux: `sudo apt-get install adb`

## Advanced Usage

### Can I extend the script with custom actions?

Yes, you can modify the PowerShell script to add custom functions. The script is open-source and documented.

### Can I use this in CI/CD?

Yes, the script supports non-interactive mode:

```bash
# CI pipeline example
adb connect $TV_IP:5555
sony-bravia-scripts.ps1 -Action a1 -Quiet -OutputFormat JSON
```

### How do I contribute?

1. Fork the repository
2. Create feature branch
3. Run tests: `.\dev\run-ci.ps1`
4. Submit pull request

See [Contributing Guidelines](../readme.md#contributing).

### Can I use this commercially?

Check the [license](../license.md). Typically MIT or similar permissive license allows commercial use.

### How do I report bugs?

1. Check [existing issues](https://github.com/yourusername/sony-bravia-adb-scripts/issues)
2. Gather debug information:
   ```bash
   adb version
   pwsh --version
   adb shell getprop ro.build.version.release
   adb devices -l
   ```
3. Create new issue with:
   - Description of problem
   - Steps to reproduce
   - Expected vs actual behavior
   - Debug information
   - Error messages/logs

## Performance

### How fast are commands?

Command execution depends on:
- Network latency (typically 50-200ms)
- ADB overhead (~50-100ms)
- TV response time (varies)

Most commands complete in 100-300ms on a good network.

### Can I speed up batch operations?

Yes:
1. Reduce delays between commands (but not too low)
2. Use wired connection
3. Enable quiet mode to suppress output
4. Run commands in parallel (for multiple TVs)

Example:
```powershell
$actions = @("a1", "a7", "a5")
$actions | ForEach-Object {
    sony-bravia-scripts.ps1 -Action $_ -Quiet
    Start-Sleep -Milliseconds 100  # Minimal delay
}
```

### Does the script use a lot of resources?

No, the script is lightweight. PowerShell and ADB have minimal resource usage. CPU and memory usage should be negligible during normal operation.

## Security and Privacy

### Is my data collected?

No, the script runs entirely locally. No data is sent to external servers (except ADB communication with your TV on your local network).

### Is the connection encrypted?

ADB connections are not encrypted by default. All communication with your TV is in plaintext on your local network. Ensure your network is secure.

### Can someone else control my TV?

If your TV's USB debugging is enabled and accessible on the network, anyone on the same network could potentially control it. Recommendations:
1. Use network isolation/VLANs
2. Disable USB debugging when not needed
3. Use firewall rules to restrict access to port 5555

### Does this expose my TV to the internet?

Not by default. ADB listens on local network only. Do NOT forward port 5555 to the internet.

## Compatibility

### What PowerShell versions are supported?

- **Recommended:** PowerShell 7.0 or higher (cross-platform)
- **Supported:** PowerShell 5.1 (Windows PowerShell) with limited features
- **Not Supported:** PowerShell 4 or earlier

### What operating systems are supported?

- Windows 10/11
- macOS 10.15+
- Linux (Ubuntu, Debian, Fedora, Arch, etc.)

### What ADB versions are required?

Any modern ADB version should work. Recommended: Android SDK Platform-Tools 30.0.0 or newer.

### Does it work with Android TV boxes?

The script is designed for Sony Bravia TVs, but it may work with other Android TV devices. Some features might not work or behave differently.

### Does it work with Google TV?

Sony TVs running Google TV (Android 10+) should work. The underlying ADB interface is similar.

## Comparison

### How is this different from the Sony TV Remote app?

- **Sony Remote App:** Official app with streaming, keyboard input, voice control
- **This Script:** Automation-focused, CLI/TUI interface, batch operations, programmable control

Use the script for automation and advanced control. Use the official app for everyday remote control.

### How is this different from BRAVIA IP Control?

- **IP Control:** Proprietary Sony protocol, requires authentication
- **This Script:** Uses standard ADB (Android Debug Bridge)

This script is easier to set up and more flexible for automation.

### Alternatives to this script?

- **Official Sony Remote App:** Mobile app
- **Sony IP Control:** Official Sony protocol
- **scrcpy:** Screen mirroring and control
- **Home Assistant Sony Bravia integration:** Smart home integration
- **Direct ADB commands:** Manual control

This script provides a convenient middle ground with automation and scripting capabilities.

---

**Last Updated:** December 2024  
**Version:** 2.0

**Still have questions?**
- Check [Troubleshooting Guide](TROUBLESHOOTING.md)
- Review [Recipes](RECIPES.md) for examples
- Search [GitHub Issues](https://github.com/yourusername/sony-bravia-adb-scripts/issues)
- Create new issue if problem persists
