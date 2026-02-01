#!/usr/bin/env bash
# Launcher shim for the PowerShell version (macOS/Linux).
# Make executable: chmod +x sony-bravia-scripts.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PS1="${SCRIPT_DIR}/sony-bravia-scripts.ps1"

if [[ ! -f "${PS1}" ]]; then
  echo "ERROR: '${PS1}' not found."
  exit 1
fi

# Check if pwsh (PowerShell Core) is available
if ! command -v pwsh &> /dev/null; then
  echo "ERROR: 'pwsh' (PowerShell Core) not found on PATH."
  echo ""
  echo "Install PowerShell Core:"
  echo "  macOS:  brew install --cask powershell"
  echo "  Linux:  https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux"
  exit 1
fi

# Launch the PowerShell script
exec pwsh -NoProfile -ExecutionPolicy Bypass -File "${PS1}" "$@"
