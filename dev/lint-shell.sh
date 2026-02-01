#!/usr/bin/env bash
# Lint shell scripts with shellcheck

set -euo pipefail

echo "=== Running ShellCheck ==="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "${SCRIPT_DIR}")"
cd "${ROOT_DIR}"

# Check if shellcheck is installed
if ! command -v shellcheck &> /dev/null; then
  echo "✗ Error: shellcheck not found"
  echo ""
  echo "Install shellcheck:"
  echo "  macOS:       brew install shellcheck"
  echo "  Ubuntu:      sudo apt-get install shellcheck"
  echo "  Other:       https://github.com/koalaman/shellcheck#installing"
  echo ""
  exit 1
fi

echo "Analyzing shell scripts..."
echo ""

EXIT_CODE=0

# Run shellcheck on the main launcher script
echo "Checking sony-bravia-scripts.sh..."
if shellcheck -x sony-bravia-scripts.sh; then
  echo "  ✓ No issues found"
else
  EXIT_CODE=$?
  echo "  ✗ Issues found"
fi

echo ""

if [ "${EXIT_CODE}" -eq 0 ]; then
  echo "✓ No issues found by ShellCheck"
else
  echo "✗ ShellCheck found issues"
fi

echo ""
exit "${EXIT_CODE}"
