<img width="270" height="270" alt="sony-bravia-adb-scripts" src="https://github.com/user-attachments/assets/367ba3e7-95f2-43c8-aab7-288cec64328c" />

# sony-bravia-adb-scripts
Sony Bravia TVs ADB scripts

A collection of small commands in a script to activate or disable features

## Requirements

- Windows PowerShell 5.1+ or PowerShell 7+
- Android `adb` on PATH (Android platform-tools)
- TV reachable via network ADB or USB ADB

## Run

- Interactive menu (recommended):
	- Run the PowerShell script: `./sony-bravia-scripts.ps1`
	- Or double-click / run the shim: `sony-bravia-scripts.cmd`

In the interactive UI:

- Use ↑/↓, PageUp/PageDown, Home/End to navigate
- Enter runs the selected action
- `/` opens a filter box
- `S` sets the target device serial (or blank for default)
- `:` runs an action by typing its id (e.g. `H10`)
- Esc quits

- Execute a single action:
	- `./sony-bravia-scripts.ps1 -Action a1`
	- `./sony-bravia-scripts.ps1 -Serial 192.168.1.20:5555 -Action d3`

`-Action` accepts either the menu id (`A1`, `H10`, etc) or the lowercase action name (`a1`, `h10`, etc).
