#!/usr/bin/env bash
# Run all CI checks locally (Unix version)

set -euo pipefail

DEV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAILED=false

run_step() {
  local name="$1"
  local script="$2"
  
  echo ""
  echo "================================================================================"
  echo "  ${name}"
  echo "================================================================================"
  echo ""
  
  START=$(date +%s)
  
  if bash "${script}"; then
    END=$(date +%s)
    DURATION=$((END - START))
    echo ""
    echo "  Completed in ${DURATION}s"
    return 0
  else
    END=$(date +%s)
    DURATION=$((END - START))
    echo ""
    echo "  Failed after ${DURATION}s"
    FAILED=true
    return 1
  fi
}

echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║  Sony Bravia Scripts - CI Pipeline (Local)                        ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

START_TOTAL=$(date +%s)

# Phase 1: Format Checks
echo "PHASE 1: FORMAT CHECKS"
echo ""

run_step "Format Shell" "${DEV_DIR}/format-shell.sh" || true

# Phase 2: Lint Checks
if [ "${FAILED}" = false ]; then
  echo ""
  echo "PHASE 2: LINT CHECKS"
  echo ""
  
  run_step "Lint Shell" "${DEV_DIR}/lint-shell.sh" || true
fi

# Phase 3: Tests
if [ "${FAILED}" = false ]; then
  echo ""
  echo "PHASE 3: TESTS"
  echo ""
  
  run_step "Test Shell" "${DEV_DIR}/test-shell.sh" || true
fi

# Summary
END_TOTAL=$(date +%s)
DURATION_TOTAL=$((END_TOTAL - START_TOTAL))

echo ""
echo "================================================================================"
echo ""
echo "  CI PIPELINE SUMMARY"
echo ""
echo "  Total Duration: ${DURATION_TOTAL}s"
echo ""

if [ "${FAILED}" = true ]; then
  echo "  ✗ FAILED - Some checks did not pass"
  echo ""
  exit 1
else
  echo "  ✓ SUCCESS - All checks passed!"
  echo ""
  
  # Run PowerShell steps if pwsh is available
  if command -v pwsh &> /dev/null; then
    echo "  Running PowerShell checks..."
    echo ""
    pwsh -File "${DEV_DIR}/run-ci.ps1" -Fast
  else
    echo "  ℹ Install PowerShell Core to run PowerShell checks"
    echo ""
  fi
  
  exit 0
fi
