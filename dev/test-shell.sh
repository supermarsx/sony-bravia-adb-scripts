#!/usr/bin/env bash
# Run shell script tests with bats

set -euo pipefail

echo "=== Running Bats Tests ==="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "${SCRIPT_DIR}")"
cd "${ROOT_DIR}"

# Check if bats is installed
if ! command -v bats &> /dev/null; then
  echo "✗ Error: bats not found"
  echo ""
  echo "Install bats:"
  echo "  macOS:       brew install bats-core"
  echo "  Ubuntu:      sudo apt-get install bats"
  echo "  From source: https://github.com/bats-core/bats-core"
  echo ""
  exit 1
fi

# Make scripts executable
echo "Setting executable permissions..."
chmod +x sony-bravia-scripts.sh

echo ""
echo "Running tests..."
echo ""

EXIT_CODE=0

# Run Unix launcher tests
echo "→ Testing sony-bravia-scripts.sh launcher..."
if bats tests/launcher.bats; then
  echo "  ✓ Unix launcher tests passed"
else
  EXIT_CODE=$?
  echo "  ✗ Unix launcher tests failed"
fi

echo ""

# Run Windows launcher tests (may not fully work on Unix)
echo "→ Testing sony-bravia-scripts.cmd launcher..."
if bats tests/launcher-windows.bats; then
  echo "  ✓ Windows launcher tests passed"
else
  # Don't fail on Windows tests in Unix environment
  echo "  ⚠ Windows launcher tests skipped/failed (expected on Unix)"
fi

echo ""
echo "=== Test Summary ==="

if [ "${EXIT_CODE}" -eq 0 ]; then
  echo "✓ All tests passed"
else
  echo "✗ Some tests failed"
fi

echo ""
exit "${EXIT_CODE}"
