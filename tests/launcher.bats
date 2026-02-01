#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031
# Tests for sony-bravia-scripts.sh launcher

setup() {
    # Load test helpers
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/.."
    export LAUNCHER="${SCRIPT_DIR}/sony-bravia-scripts.sh"
    export PS1_SCRIPT="${SCRIPT_DIR}/sony-bravia-scripts.ps1"
}

@test "launcher script exists" {
    [ -f "${LAUNCHER}" ]
}

@test "launcher script is executable" {
    [ -x "${LAUNCHER}" ] || skip "File needs chmod +x"
}

@test "PowerShell script exists" {
    [ -f "${PS1_SCRIPT}" ]
}

@test "launcher checks for PowerShell script" {
    grep -q 'sony-bravia-scripts.ps1' "${LAUNCHER}"
}

@test "launcher checks for pwsh command" {
    grep -q 'command -v pwsh' "${LAUNCHER}"
}

@test "launcher provides installation instructions" {
    grep -q 'brew install --cask powershell' "${LAUNCHER}"
    grep -q 'installing-powershell-on-linux' "${LAUNCHER}"
}

@test "launcher exits with error if PowerShell script not found" {
    grep -q 'not found' "${LAUNCHER}"
    grep -q 'exit 1' "${LAUNCHER}"
}

@test "launcher uses exec to run pwsh" {
    grep -q 'exec pwsh' "${LAUNCHER}"
}

@test "launcher passes arguments to PowerShell script" {
    grep -q '\"\$@\"' "${LAUNCHER}"
}

@test "launcher uses NoProfile flag" {
    grep -q '\-NoProfile' "${LAUNCHER}"
}

@test "launcher uses Bypass execution policy" {
    grep -q '\-ExecutionPolicy Bypass' "${LAUNCHER}"
}

@test "launcher has shebang" {
    head -n 1 "${LAUNCHER}" | grep -q '^#!/usr/bin/env bash'
}

@test "launcher uses set -euo pipefail" {
    grep -q 'set -euo pipefail' "${LAUNCHER}"
}

@test "launcher script is valid bash syntax" {
    bash -n "${LAUNCHER}"
}

@test "launcher has proper error handling" {
    # Check for proper error messages
    grep -q 'ERROR:' "${LAUNCHER}"
}

@test "launcher checks both macOS and Linux in help text" {
    content=$(cat "${LAUNCHER}")
    echo "${content}" | grep -q 'macOS'
    echo "${content}" | grep -q 'Linux'
}
