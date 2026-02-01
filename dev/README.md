# Development Scripts

This folder contains scripts for running CI pipeline steps locally.

## Quick Start

**Windows (PowerShell):**
```powershell
# Run all CI checks
.\dev\run-ci.ps1

# Run quick checks (PowerShell only)
.\dev\run-ci.ps1 -Fast

# Run specific phases
.\dev\run-ci.ps1 -SkipPackage
```

**macOS/Linux (Bash):**
```bash
# Make scripts executable
chmod +x dev/*.sh

# Run all CI checks
./dev/run-ci.sh
```

## Individual Scripts

### Format Checks
- `format-powershell.ps1` - Check PowerShell formatting
- `format-shell.sh` - Check shell script formatting

### Lint Checks
- `lint-powershell.ps1` - Run PSScriptAnalyzer
- `lint-shell.sh` - Run ShellCheck

### Tests
- `test-powershell.ps1` - Run Pester tests
  - Options: `-Verbosity` (Minimal, Normal, Detailed, Diagnostic)
  - Options: `-CodeCoverage` (enable code coverage)
- `test-shell.sh` - Run Bats tests

### Package
- `package.ps1` - Create release packages

### Full CI Pipeline
- `run-ci.ps1` - Run all checks (PowerShell version)
  - Options: `-SkipFormat`, `-SkipLint`, `-SkipTests`, `-SkipPackage`
  - Options: `-Fast` (PowerShell checks only)
- `run-ci.sh` - Run all checks (Bash version)

## Usage Examples

```powershell
# Format check only
.\dev\format-powershell.ps1

# Lint with custom settings
.\dev\lint-powershell.ps1

# Run tests with code coverage
.\dev\test-powershell.ps1 -CodeCoverage

# Create packages
.\dev\package.ps1

# Full CI without packaging
.\dev\run-ci.ps1 -SkipPackage

# Quick validation (format + lint only)
.\dev\run-ci.ps1 -SkipTests -SkipPackage -Fast
```

## CI Pipeline Order

1. **Format** - Validate file formatting
2. **Lint** - Static code analysis
3. **Test** - Run unit tests
4. **Package** - Create distribution packages (only if all pass)

## Requirements

### PowerShell Scripts
- PowerShell 7+ (cross-platform)
- Pester 5.x (auto-installed if missing)
- PSScriptAnalyzer (auto-installed if missing)

### Shell Scripts
- Bash 4.0+
- Bats (testing framework)
- ShellCheck (linting tool)

Install on macOS:
```bash
brew install bats-core shellcheck
```

Install on Ubuntu/Debian:
```bash
sudo apt-get install bats shellcheck
```
