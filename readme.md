<img width="270" height="270" alt="sony-bravia-adb-scripts" src="https://github.com/user-attachments/assets/367ba3e7-95f2-43c8-aab7-288cec64328c" />

# sony-bravia-adb-scripts
Sony Bravia TVs ADB scripts

A collection of small commands in a script to activate or disable features

## Requirements

- **PowerShell**: 
  - Windows: PowerShell 5.1+ (built-in) or PowerShell 7+
  - macOS: PowerShell Core 7+ (`brew install --cask powershell`)
  - Linux: PowerShell Core 7+ ([install guide](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux))
- **ADB**: Android `adb` on PATH (Android platform-tools)
  - Download: [Android SDK Platform Tools](https://developer.android.com/studio/releases/platform-tools)
- **TV**: Sony Bravia TV reachable via network ADB or USB ADB

## Installation

### Windows
1. Download and extract Android platform-tools
2. Add `adb` to your PATH
3. Clone or download this repository
4. Double-click `sony-bravia-scripts.cmd` or run `.\sony-bravia-scripts.ps1`

### macOS
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

### Linux
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

## Usage

### Interactive Menu (Recommended)

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

**In the interactive UI:**
- Use ↑/↓, PageUp/PageDown, Home/End to navigate
- Enter runs the selected action
- `/` opens a filter box to search actions
- `S` sets the target device serial (or blank for default)
- `:` runs an action by typing its id (e.g. `H10`)
- `Q` or Esc quits

### Command-Line Mode

Execute a single action:
```powershell
# Windows
.\sony-bravia-scripts.ps1 -Action a1

# macOS/Linux
pwsh -File sony-bravia-scripts.ps1 -Action a1
```

Target a specific device:
```powershell
.\sony-bravia-scripts.ps1 -Serial 192.168.1.20:5555 -Action d3
```

`-Action` accepts either the menu id (`A1`, `H10`, etc) or the lowercase action name (`a1`, `h10`, etc).
## Development

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

### Continuous Integration

The project uses GitHub Actions for automated testing and linting across multiple platforms.

**CI/CD Pipeline includes:**
- **PowerShell Tests** - Run on Windows, macOS, and Linux
- **Shell Script Tests** - Run on macOS and Linux (using Bats)
- **PowerShell Linting** - PSScriptAnalyzer checks
- **Shell Script Linting** - ShellCheck validation
- **Format Checking** - EditorConfig compliance, trailing whitespace, line endings

**View test results:** Check the Actions tab in the GitHub repository

**Manual CI simulation:**
```powershell
# Run all checks locally (PowerShell)
Invoke-Pester -Path ./tests
Invoke-ScriptAnalyzer -Path . -Recurse -Settings ./dev/PSScriptAnalyzerSettings.psd1
```

```bash
# Run all checks locally (Bash)
bats tests/
shellcheck -x sony-bravia-scripts.sh
editorconfig-checker
```

## Contributing

When contributing to this project:

1. **Run tests** before submitting PR
2. **Check linting** with PSScriptAnalyzer and ShellCheck
3. **Follow EditorConfig** formatting rules
4. **Add tests** for new features
5. **Update documentation** as needed

## Project Structure

```
sony-bravia-adb-scripts/
├── sony-bravia-scripts.ps1      # Main PowerShell script (cross-platform)
├── sony-bravia-scripts.cmd      # Windows launcher
├── sony-bravia-scripts.sh       # macOS/Linux launcher
├── tests/
│   ├── sony-bravia-scripts.Tests.ps1  # PowerShell unit tests
│   ├── launcher.bats                  # Shell script tests (Unix)
│   └── launcher-windows.bats          # Batch file tests (Windows)
├── dev/
│   ├── PSScriptAnalyzerSettings.psd1  # PowerShell linting config
│   ├── format-powershell.ps1          # Format check script
│   ├── lint-powershell.ps1            # Lint check script
│   ├── test-powershell.ps1            # Test runner script
│   ├── package.ps1                    # Package creator
│   └── run-ci.ps1                     # Full CI pipeline
├── .github/
│   └── workflows/
│       └── ci.yml                     # CI/CD pipeline
├── .shellcheckrc                      # Shell linting config
├── .editorconfig                      # Formatting rules
├── readme.md                          # This file
└── license.md                         # License information
```
