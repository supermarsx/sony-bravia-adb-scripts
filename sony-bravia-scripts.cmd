@echo off
setlocal

REM Launcher shim for the PowerShell version.
REM Use this file if you want a double-clickable entry point.

set "SCRIPT_DIR=%~dp0"
set "PS1=%SCRIPT_DIR%sony-bravia-scripts.ps1"

if not exist "%PS1%" (
  echo ERROR: "%PS1%" not found.
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
exit /b %errorlevel%