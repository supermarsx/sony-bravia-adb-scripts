#!/usr/bin/env bats
# Tests for sony-bravia-scripts.cmd launcher (Windows)

setup() {
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/.."
    export LAUNCHER="${SCRIPT_DIR}/sony-bravia-scripts.cmd"
    export PS1_SCRIPT="${SCRIPT_DIR}/sony-bravia-scripts.ps1"
}

@test "Windows launcher exists" {
    [ -f "${LAUNCHER}" ]
}

@test "Windows launcher is a batch file" {
    head -n 1 "${LAUNCHER}" | grep -q '@echo off'
}

@test "Windows launcher checks for PowerShell script" {
    grep -q 'sony-bravia-scripts.ps1' "${LAUNCHER}"
}

@test "Windows launcher uses setlocal" {
    grep -q 'setlocal' "${LAUNCHER}"
}

@test "Windows launcher sets SCRIPT_DIR" {
    grep -q 'SCRIPT_DIR=' "${LAUNCHER}"
}

@test "Windows launcher checks if PS1 exists" {
    grep -q 'if not exist' "${LAUNCHER}"
}

@test "Windows launcher shows error if script not found" {
    grep -q 'ERROR:' "${LAUNCHER}"
    grep -q 'not found' "${LAUNCHER}"
}

@test "Windows launcher runs PowerShell with NoProfile" {
    grep -q 'powershell.*-NoProfile' "${LAUNCHER}"
}

@test "Windows launcher runs PowerShell with Bypass" {
    grep -q 'powershell.*-ExecutionPolicy Bypass' "${LAUNCHER}"
}

@test "Windows launcher passes arguments" {
    grep -q '%\*' "${LAUNCHER}"
}

@test "Windows launcher exits with error code" {
    grep -q 'exit /b' "${LAUNCHER}"
}

@test "Windows launcher preserves errorlevel" {
    grep -q 'errorlevel' "${LAUNCHER}"
}
