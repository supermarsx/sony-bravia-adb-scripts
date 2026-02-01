<div align="center">

<img width="270" height="270" alt="sony-bravia-adb-scripts" src="https://github.com/user-attachments/assets/367ba3e7-95f2-43c8-aab7-288cec64328c" />

# Sony Bravia ADB Scripts

**Comprehensive control and automation toolkit for Sony Bravia Android TVs via ADB**

[![CI Status](https://img.shields.io/github/actions/workflow/status/supermarsx/sony-bravia-adb-scripts/ci.yml?branch=main&style=flat-square&label=CI)](https://github.com/supermarsx/sony-bravia-adb-scripts/actions/workflows/ci.yml)
[![GitHub Release](https://img.shields.io/github/v/release/supermarsx/sony-bravia-adb-scripts?include_prereleases&label=rolling&style=flat-square)](https://github.com/supermarsx/sony-bravia-adb-scripts/releases/tag/rolling)
[![License](https://img.shields.io/github/license/supermarsx/sony-bravia-adb-scripts?style=flat-square)](license.md)
[![GitHub Stars](https://img.shields.io/github/stars/supermarsx/sony-bravia-adb-scripts?style=flat-square&color=yellow)](https://github.com/supermarsx/sony-bravia-adb-scripts/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/supermarsx/sony-bravia-adb-scripts?style=flat-square&color=blue)](https://github.com/supermarsx/sony-bravia-adb-scripts/network/members)
[![GitHub Watchers](https://img.shields.io/github/watchers/supermarsx/sony-bravia-adb-scripts?style=flat-square&color=green)](https://github.com/supermarsx/sony-bravia-adb-scripts/watchers)
[![GitHub Issues](https://img.shields.io/github/issues/supermarsx/sony-bravia-adb-scripts?style=flat-square)](https://github.com/supermarsx/sony-bravia-adb-scripts/issues)

[![Made with PowerShell](https://img.shields.io/badge/Made%20with-PowerShell-blue?style=flat-square&logo=powershell)](https://github.com/PowerShell/PowerShell)
[![Made with ADB](https://img.shields.io/badge/Made%20with-ADB-3DDC84?style=flat-square&logo=android)](https://developer.android.com/studio/command-line/adb)
[![Cross Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey?style=flat-square)](https://github.com/supermarsx/sony-bravia-adb-scripts)

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Documentation](#-documentation) • [Contributing](#-contributing)

</div>

---

## 🎯 Overview

**Sony Bravia ADB Scripts** is a powerful, cross-platform automation toolkit that provides comprehensive control over Sony Bravia Android TVs using the Android Debug Bridge (ADB). Whether you're a home automation enthusiast, developer, or power user, this script collection gives you unprecedented control over your TV's functionality.

### Why Use This?

- **🚀 70+ Control Actions**: From basic navigation to advanced system tweaks
- **🎨 Beautiful TUI Interface**: Intuitive keyboard-driven menu system
- **⚡ CLI & Batch Modes**: Perfect for automation and scripting
- **🔧 Power User Features**: Debloating, system configuration, app management
- **📦 Zero Dependencies**: Just PowerShell 7+ and ADB
- **🌍 Cross-Platform**: Works seamlessly on Windows, macOS, and Linux
- **🧪 Thoroughly Tested**: 92-95% test coverage with automated CI/CD
- **📖 Extensively Documented**: Comprehensive guides, recipes, and troubleshooting

## ✨ Features

### 🎮 Navigation & Control
- Complete remote control emulation (D-pad, Home, Back, Menu)
- Volume, channel, and playback controls
- Quick input switching and HDMI-CEC commands
- Picture and sound mode adjustments

### 📺 TV Management
- System information retrieval (model, Android version, specs)
- Network configuration (Wi-Fi, proxy, DNS)
- Display settings (resolution, brightness, animations)
- Power management (reboot, standby, wake)

### 🎬 App Control
- Launch popular streaming apps (Netflix, YouTube, Prime Video, Disney+, etc.)
- Install/uninstall APKs
- Enable/disable apps
- Force stop and restart apps
- **NEW**: Clear cache for all apps with progress tracking

### 🧹 Debloating & Optimization
- **Safe Debloat**: Remove 40 common Sony bloatware packages
- **Nuclear Debloat**: Aggressive removal of 121 packages (use with caution!)
- Cache cleaning with per-app loop
- Reset app permissions
- Trim caches system-wide

### 🔧 Advanced Features
- Custom launcher management
- Proxy configuration
- ADB command history tracking
- Batch execution from files
- Multiple output formats (Text, JSON, CSV)
- Connection validation with retry logic
- Configuration file support

### 🤖 Automation Ready
- CLI mode for scripting
- Batch mode for sequential actions
- JSON/CSV output for parsing
- Quiet mode for silent execution
- Integration examples (Home Assistant, cron, Task Scheduler)

## 📋 Requirements

- **PowerShell**: 
  - Windows: PowerShell 5.1+ (built-in) or PowerShell 7+
  - macOS: PowerShell Core 7+ (`brew install --cask powershell`)
  - Linux: PowerShell Core 7+ ([install guide](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux))
- **ADB**: Android `adb` on PATH (Android platform-tools)
  - Download: [Android SDK Platform Tools](https://developer.android.com/studio/releases/platform-tools)
- **TV**: Sony Bravia TV reachable via network ADB or USB ADB

## 📦 Installation

### Package Managers (Recommended)

#### macOS / Linux (Homebrew)

```bash
# Add tap
brew tap supermarsx/tap

# Install
brew install sony-bravia-scripts

# Run
sony-bravia-scripts
```

[Full Homebrew Instructions](homebrew/README.md)

#### Windows (Scoop)

```powershell
# Add bucket
scoop bucket add supermarsx https://github.com/supermarsx/scoop-bucket

# Install
scoop install sony-bravia-scripts

# Run
sony-bravia-scripts
```

[Full Scoop Instructions](scoop/README.md)

#### Windows (WinGet)

```powershell
# Install
winget install supermarsx.SonyBraviaScripts

# Run
sony-bravia-scripts
```

[Full WinGet Instructions](winget/README.md)

### Manual Installation

#### Windows
1. Download and extract Android platform-tools
2. Add `adb` to your PATH
3. Clone or download this repository
4. Double-click `sony-bravia-scripts.cmd` or run `.\sony-bravia-scripts.ps1`

#### macOS
```bash
# Install PowerShell Core (if not already installed)
brew install --cask powershell

# Install ADB
brew install android-platform-tools

# Make the launcher executable
chmod +x sony-bravia-scripts.sh

# Run
./sony-bravia-scripts.sh
```

#### Linux
```bash
# Install PowerShell Core (Ubuntu/Debian example)
# See: https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux
wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y powershell

# Install ADB (varies by distro)
sudo apt-get install -y adb  # Ubuntu/Debian

# Make the launcher executable
chmod +x sony-bravia-scripts.sh

# Run
./sony-bravia-scripts.sh
```

---

## 🚀 Usage

### Interactive Menu (Recommended)

Launch the beautiful terminal UI with keyboard-driven navigation:

**Windows:**
```powershell
.\sony-bravia-scripts.ps1
# or double-click
sony-bravia-scripts.cmd
```

**macOS/Linux:**
```bash
./sony-bravia-scripts.sh
# or directly with pwsh
pwsh -File sony-bravia-scripts.ps1
```

**Navigation:**
- Use **arrow keys** or **vim keys** (h/j/k/l) to navigate
- Press **Enter** to select an action
- Type action codes directly (e.g., `d1`, `i13`, `v+`)
- Press **Q** to quit

### Command-Line Mode

Execute actions directly without the menu:

```powershell
# Navigate TV
.\sony-bravia-scripts.ps1 -Actions "up,right,enter"

# Launch Netflix
.\sony-bravia-scripts.ps1 -Actions "n1"

# Volume control
.\sony-bravia-scripts.ps1 -Actions "v+,v+,v+"

# Get TV info with JSON output
.\sony-bravia-scripts.ps1 -Actions "d1" -OutputFormat json

# Multiple actions
.\sony-bravia-scripts.ps1 -Actions "home,down,down,enter,wait5,back"
```

### Batch Mode

Execute multiple actions from a file:

```powershell
# Create batch file
@"
# Morning routine
power-on
wait10
home
down,down,enter
n1
"@ | Out-File morning.txt

# Run batch
.\sony-bravia-scripts.ps1 -BatchFile morning.txt
```

### Configuration File

Store connection details and preferences:

```json
{
  "defaultDevice": "192.168.1.100",
  "adbPath": "C:\\platform-tools\\adb.exe",
  "connectTimeout": 10,
  "defaultOutputFormat": "json"
}
```

```powershell
.\sony-bravia-scripts.ps1 -ConfigFile config.json -Actions "d1"
```

## 📖 Documentation

### Quick Reference

#### Navigation Actions (D-Pad)
- **up, down, left, right**: D-pad navigation
- **enter**: Select/OK button
- **back**: Back button
- **home**: Home screen
- **menu**: Options menu

#### Volume & Channel
- **v+, v-**: Volume up/down
- **mute**: Toggle mute
- **ch+, ch-**: Channel up/down

#### Power & Input
- **power**: Toggle power (standby/wake)
- **reboot**: Restart TV
- **input**: Cycle HDMI inputs
- **hdmi1-hdmi4**: Switch to specific HDMI port

#### App Launchers (Quick Access)
- **n1**: Netflix
- **n2**: YouTube
- **n3**: Prime Video
- **n4**: Disney+
- **n5**: HBO Max
- **n6**: Hulu
- **And 60+ more apps...**

#### System Info
- **d1**: Full device info (model, Android version, screen resolution)
- **d3**: Get TV model number
- **d5**: Network configuration
- **d7**: Display settings

#### Debloating & Optimization
- **i13**: Safe debloat (40 Sony bloatware packages)
- **i14**: Re-enable Sony packages
- **i15**: Nuclear debloat (121 packages - use caution!)
- **i16**: Re-enable all nuclear packages
- **i2**: Trim all caches (safe, frees space)
- **i3a**: Clear cache for all apps (loop with progress)

#### Device Naming
- **f1**: Get device name
- **f2**: Set device name
- **f3**: Get Bluetooth name
- **f4**: Set Bluetooth name

### Interactive UI Guide

Launch the script and navigate with:
- **Arrow keys** or **vim keys** (h/j/k/l)
- **PageUp/PageDown**, **Home/End** for quick navigation
- **/** to filter/search actions
- **:** to run action by ID (e.g., `:d1`)
- **S** to set target device serial
- **Q** or **Esc** to quit

### Command-Line Examples

```powershell
# Get TV model
.\sony-bravia-scripts.ps1 -Actions "d3"

# Launch Netflix and wait
.\sony-bravia-scripts.ps1 -Actions "n1,wait5"

# Navigate to settings
.\sony-bravia-scripts.ps1 -Actions "home,down,down,right,enter"

# Safe debloat
.\sony-bravia-scripts.ps1 -Actions "i13"

# Volume control with target device
.\sony-bravia-scripts.ps1 -Serial 192.168.1.50:5555 -Actions "v+,v+,v+"

# Get info as JSON
.\sony-bravia-scripts.ps1 -Actions "d1" -OutputFormat json
```

### Batch File Example

Create `tv-morning-routine.txt`:
```
# Turn on and launch news
power
wait10
home
down,down,enter
wait3
n2
```

Execute:
```powershell
.\sony-bravia-scripts.ps1 -BatchFile tv-morning-routine.txt
```

### Automation Integration

#### Home Assistant
```yaml
# configuration.yaml
shell_command:
  tv_netflix: 'pwsh /path/to/sony-bravia-scripts.ps1 -Actions "n1"'
  tv_volume_up: 'pwsh /path/to/sony-bravia-scripts.ps1 -Actions "v+"'
```

#### Windows Task Scheduler
```powershell
# Daily TV debloat at 3 AM
$action = New-ScheduledTaskAction -Execute "pwsh" -Argument "-File C:\sony-bravia-scripts\sony-bravia-scripts.ps1 -Actions i2"
$trigger = New-ScheduledTaskTrigger -Daily -At 3am
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "TV Cache Clean"
```

#### Linux Cron
```bash
# Clear TV cache daily at 3 AM
0 3 * * * pwsh /home/user/sony-bravia-scripts/sony-bravia-scripts.ps1 -Actions "i2" >> /var/log/tv-maintenance.log 2>&1
```

---

## 🛠️ Development

### Running Tests

This project includes comprehensive tests for both PowerShell and shell scripts.

#### PowerShell Tests (Pester)

**Install Pester (if not already installed):**
```powershell
Install-Module -Name Pester -Force -SkipPublisherCheck
```

**Run all tests:**
```powershell
# Simple output
Invoke-Pester -Path ./tests

# Detailed output
Invoke-Pester -Path ./tests -Output Detailed

# Run specific test file
Invoke-Pester -Path ./tests/sony-bravia-scripts.Tests.ps1
```

**PowerShell test coverage includes:**
- Script structure and documentation
- Helper functions (Read-NonEmpty, Read-YesNo, etc.)
- ADB command wrapper (Invoke-Adb)
- Menu structure and integrity
- All 70+ action functions (A1-N2)
- TUI functions and keyboard navigation
- Error handling
- ADB command validation
- Code quality checks

#### Shell Script Tests (Bats)

**Install Bats:**
```bash
# macOS
brew install bats-core

# Ubuntu/Debian
sudo apt-get install bats

# From source
git clone https://github.com/bats-core/bats-core.git
cd bats-core
./install.sh /usr/local
```

**Run shell tests:**
```bash
# Make script executable first
chmod +x sony-bravia-scripts.sh

# Run all bats tests
bats tests/

# Run specific test file
bats tests/launcher.bats
```

**Shell test coverage includes:**
- Launcher script existence and permissions
- PowerShell detection and error messages
- Argument passing
- Error handling
- Bash syntax validation
- Installation instructions

### Code Quality & Linting

#### PowerShell Linting (PSScriptAnalyzer)

**Install PSScriptAnalyzer:**
```powershell
Install-Module -Name PSScriptAnalyzer -Force -SkipPublisherCheck
```

**Run linter:**
```powershell
# Check all PowerShell files
Invoke-ScriptAnalyzer -Path . -Recurse -Settings ./PSScriptAnalyzerSettings.psd1

# Check specific file
Invoke-ScriptAnalyzer -Path ./sony-bravia-scripts.ps1 -Settings ./PSScriptAnalyzerSettings.psd1
```

#### Shell Script Linting (ShellCheck)

**Install ShellCheck:**
```bash
# macOS
brew install shellcheck

# Ubuntu/Debian
sudo apt-get install shellcheck

# Other platforms: https://github.com/koalaman/shellcheck#installing
```

**Run linter:**
```bash
# Check shell script
shellcheck sony-bravia-scripts.sh

# With config file
shellcheck -x sony-bravia-scripts.sh
```

### Format Checking

The project uses EditorConfig for consistent formatting across all files.

**Check formatting compliance:**
```bash
# Install editorconfig-checker
npm install -g editorconfig-checker

# Check all files
editorconfig-checker
```

**Configuration files:**
- `.editorconfig` - Formatting rules for all file types
- `dev/PSScriptAnalyzerSettings.psd1` - PowerShell linting rules
- `.shellcheckrc` - ShellCheck configuration

### Continuous Integration & Deployment

The project uses **GitHub Actions** for automated testing, linting, packaging, and rolling releases across all platforms.

#### CI/CD Pipeline

1. **Format & Lint** (Parallel)
   - **PowerShell**: PSScriptAnalyzer checks for code quality and best practices
   - **Shell Scripts**: ShellCheck validates bash/sh scripts
   - **EditorConfig**: Ensures consistent formatting across all files

2. **Test** (Parallel)
   - **PowerShell Tests**: Run Pester tests on Windows, macOS, and Linux
   - **Shell Script Tests**: Run Bats tests on macOS and Linux
   - **Coverage**: 92-95% test coverage across all actions

3. **Package**
   - Creates platform-specific ZIP archives (Windows, macOS, Linux)
   - Includes launcher scripts and documentation

4. **Rolling Release**
   - Creates/updates `rolling` tag with latest commit hash
   - Uploads ZIP files as release artifacts
   - Generates release notes with commit information

5. **Update Package Managers**
   - Downloads rolling release artifacts
   - Calculates SHA256 hashes for each platform
   - Updates Homebrew formula, Scoop manifest, and WinGet manifest
   - Commits changes back to repository

**View test results:** Check the [Actions](../../actions) tab

**Trigger workflow:** Push to `main` branch or manually dispatch

#### Local Testing

```powershell
# Run all PowerShell checks
Invoke-Pester -Path ./tests -Output Detailed
Invoke-ScriptAnalyzer -Path . -Recurse -Settings ./dev/PSScriptAnalyzerSettings.psd1
```

```bash
# Run all shell checks
bats tests/
shellcheck -x sony-bravia-scripts.sh
editorconfig-checker
```

---

## 🤝 Contributing

Contributions are welcome! Here's how to get started:

### Development Workflow

1. **Fork** the repository
2. **Clone** your fork locally
3. **Create a branch** for your feature/fix
4. **Make changes** with tests and documentation
5. **Run tests** to ensure everything works
6. **Submit a PR** with clear description

### Quality Standards

Before submitting:

- ✅ **Run tests**: `Invoke-Pester -Path ./tests`
- ✅ **Check linting**: `Invoke-ScriptAnalyzer -Path . -Recurse`
- ✅ **Shell check**: `shellcheck -x sony-bravia-scripts.sh`
- ✅ **Format check**: `editorconfig-checker`
- ✅ **Add tests** for new features (maintain 90%+ coverage)
- ✅ **Update documentation** in README and inline comments

### Contribution Areas

- 🐛 **Bug fixes**: Report or fix issues
- ✨ **New features**: Add TV actions or functionality
- 📚 **Documentation**: Improve guides and examples
- 🧪 **Tests**: Increase coverage or add test cases
- 🌍 **Localization**: Add language support
- 🎨 **UI/UX**: Enhance interactive menu

### Code Style

- Follow existing PowerShell conventions
- Use descriptive function names (verb-noun format)
- Add help documentation to functions
- Keep functions focused and testable
- Use proper error handling

---

## 📂 Project Structure

```
sony-bravia-adb-scripts/
├── 📜 sony-bravia-scripts.ps1       # Main PowerShell script (2200+ lines, 70+ actions)
├── 🪟 sony-bravia-scripts.cmd       # Windows launcher
├── 🐧 sony-bravia-scripts.sh        # macOS/Linux launcher
├── 📦 Package Managers
│   ├── homebrew/
│   │   ├── sony-bravia-scripts.rb   # Homebrew formula
│   │   └── README.md                # Installation guide
│   ├── scoop/
│   │   ├── sony-bravia-scripts.json # Scoop manifest
│   │   └── README.md                # Installation guide
│   └── winget/
│       ├── sony-bravia-scripts.yaml # WinGet manifest
│       └── README.md                # Installation guide
├── 🧪 tests/
│   ├── sony-bravia-scripts.Tests.ps1  # PowerShell unit tests (Pester)
│   ├── launcher.bats                  # Shell script tests (Unix)
│   └── launcher-windows.bats          # Batch file tests (Windows)
├── 🛠️ dev/
│   ├── PSScriptAnalyzerSettings.psd1  # PowerShell linting config
│   ├── format-powershell.ps1          # Format check script
│   ├── lint-powershell.ps1            # Lint check script
│   ├── test-powershell.ps1            # Test runner script
│   ├── package.ps1                    # Package creator
│   └── run-ci.ps1                     # Full CI pipeline
├── ⚙️ .github/
│   └── workflows/
│       └── ci.yml                   # CI/CD: test → package → rolling release → update packages
├── 📝 .editorconfig                 # Code formatting rules
├── 🔍 .shellcheckrc                 # ShellCheck configuration
├── 📄 readme.md                     # This file
└── 📜 license.md                    # MIT License
```

---

## 📊 Repository Stats

- **Lines of Code**: 2200+ (PowerShell) + 500+ (Tests)
- **Test Coverage**: 92-95%
- **Actions**: 70+ TV control functions
- **Platforms**: Windows, macOS, Linux
- **Package Managers**: Homebrew, Scoop, WinGet
- **CI/CD**: Fully automated with GitHub Actions

---

## 📜 License

This project is licensed under the **MIT License** - see the [license.md](license.md) file for details.

---

## 🙏 Acknowledgments

Built with:
- **[PowerShell](https://github.com/PowerShell/PowerShell)** - Cross-platform automation framework
- **[Android Debug Bridge (ADB)](https://developer.android.com/studio/command-line/adb)** - Android device communication
- **[Pester](https://pester.dev/)** - PowerShell testing framework
- **[Bats](https://github.com/bats-core/bats-core)** - Bash automated testing system
- **[PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer)** - PowerShell linting
- **[ShellCheck](https://www.shellcheck.net/)** - Shell script analysis
- **[GitHub Actions](https://github.com/features/actions)** - CI/CD automation

---

## 💬 Support

- **Issues**: [Report bugs or request features](../../issues)
- **Discussions**: [Ask questions or share ideas](../../discussions)
- **Documentation**: See inline help in [sony-bravia-scripts.ps1](sony-bravia-scripts.ps1)

---

## ⭐ Star History

If you find this project useful, please consider giving it a star! It helps others discover the project.

[![Star History Chart](https://api.star-history.com/svg?repos=supermarsx/sony-bravia-adb-scripts&type=Date)](https://star-history.com/#supermarsx/sony-bravia-adb-scripts&Date)

---

<div align="center">

**Made with ❤️ for Sony Bravia TV enthusiasts**

[⬆ Back to Top](#sony-bravia-adb-scripts)

</div>
│       └── ci.yml                     # CI/CD pipeline
├── .shellcheckrc                      # Shell linting config
├── .editorconfig                      # Formatting rules
├── readme.md                          # This file
└── license.md                         # License information
```
