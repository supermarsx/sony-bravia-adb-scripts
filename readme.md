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
