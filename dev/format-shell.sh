#!/usr/bin/env bash
# Format check for shell scripts

set -euo pipefail

echo "=== Checking shell script formatting ==="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "${SCRIPT_DIR}")"
cd "${ROOT_DIR}"

EXIT_CODE=0

# Check for CRLF line endings (should be LF only)
echo "Checking line endings..."
if file *.sh 2>/dev/null | grep -q CRLF; then
  echo "✗ Error: CRLF line endings detected in shell scripts"
  EXIT_CODE=1
fi

# Check for trailing whitespace
echo "Checking for trailing whitespace..."
if grep -n '[[:blank:]]$' *.sh 2>/dev/null; then
  echo "✗ Trailing whitespace found in shell scripts"
  EXIT_CODE=1
fi

# Check for executable bit
echo "Checking executable permissions..."
if [ ! -x sony-bravia-scripts.sh ]; then
  echo "⚠ Warning: sony-bravia-scripts.sh should be executable"
  echo "  Run: chmod +x sony-bravia-scripts.sh"
fi

# Check batch file line endings
echo "Checking Windows batch file line endings..."
if ! file *.cmd 2>/dev/null | grep -q CRLF; then
  echo "⚠ Warning: Windows batch files should have CRLF line endings"
else
  echo "  ✓ Batch file line endings look good"
fi

echo ""

if [ "${EXIT_CODE}" -eq 0 ]; then
  echo "✓ Shell script formatting looks good"
else
  echo "✗ Shell script formatting has issues"
fi

exit "${EXIT_CODE}"
