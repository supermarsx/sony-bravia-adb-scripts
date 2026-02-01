# WinGet Manifest

This directory contains the Windows Package Manager (WinGet) manifest for Sony Bravia ADB Scripts.

## Installation

### Option 1: Install from WinGet repository (when published)

```powershell
# Install
winget install YourPublisher.SonyBraviaScripts

# Or use moniker
winget install sony-bravia
```

### Option 2: Install from local manifest

```powershell
# From this repository directory
winget install --manifest winget\
```

## Usage

After installation, the commands will be available:

```powershell
# Interactive mode
sony-bravia-scripts

# CLI mode
sony-bravia-scripts -Action a1

# Batch mode
sony-bravia-scripts -Action "a1,a2,a3"
```

## Requirements

WinGet automatically checks for external dependencies:
- **PowerShell 7+**: Install from Microsoft Store or `winget install Microsoft.PowerShell`
- **ADB**: Install platform-tools or use Chocolatey: `choco install adb`

## Updating

```powershell
# Update WinGet sources
winget source update

# Upgrade to latest version
winget upgrade YourPublisher.SonyBraviaScripts

# Or upgrade all packages
winget upgrade --all
```

## Uninstalling

```powershell
winget uninstall YourPublisher.SonyBraviaScripts
```

## Manifest Development

### Manifest structure

The manifest uses WinGet's singleton format (all data in one file). For more complex scenarios, you can split into:
- `sony-bravia-scripts.installer.yaml` - Installer details
- `sony-bravia-scripts.locale.en-US.yaml` - Localization
- `sony-bravia-scripts.yaml` - Version and metadata

### Testing the manifest

```powershell
# Validate manifest
winget validate --manifest winget\

# Test installation
winget install --manifest winget\

# Check installed package
winget list sony-bravia
```

### Updating SHA256

When a new release is published, update the SHA256 hash:

```powershell
# Calculate SHA256 for new release
(Get-FileHash sony-bravia-scripts-powershell.zip -Algorithm SHA256).Hash.ToLower()

# Update manifest with new hash
```

The CI/CD pipeline automatically updates this manifest on each rolling release.

## Submitting to WinGet Community Repository

To publish this package to the official WinGet repository:

### Prerequisites

1. Fork [microsoft/winget-pkgs](https://github.com/microsoft/winget-pkgs)
2. Clone your fork
3. Install WinGet tools:
   ```powershell
   winget install Microsoft.WingetCreate
   ```

### Submission process

1. **Create package directory**
   ```powershell
   cd winget-pkgs\manifests\y\YourPublisher\SonyBraviaScripts
   mkdir 2.0.0.0
   ```

2. **Copy manifest**
   ```powershell
   Copy-Item sony-bravia-scripts.yaml 2.0.0.0\
   ```

3. **Validate manifest**
   ```powershell
   winget validate --manifest manifests\y\YourPublisher\SonyBraviaScripts\2.0.0.0\
   ```

4. **Test installation**
   ```powershell
   winget install --manifest manifests\y\YourPublisher\SonyBraviaScripts\2.0.0.0\
   ```

5. **Submit pull request**
   - Commit changes
   - Push to your fork
   - Create PR to microsoft/winget-pkgs
   - Wait for automated validation and review

### Automated updates

Use WinGet Create for easier updates:

```powershell
# Update existing package
wingetcreate update YourPublisher.SonyBraviaScripts `
  --version 2.0.1.0 `
  --urls https://github.com/.../sony-bravia-scripts-powershell.zip `
  --submit
```

## Troubleshooting

### Manifest validation fails

Check common issues:
```powershell
# Validate with verbose output
winget validate --manifest winget\ --verbose

# Common issues:
# - Invalid package identifier format
# - Missing required fields
# - Invalid SHA256 hash
# - Incorrect YAML formatting
```

### Installation fails

```powershell
# Check WinGet version
winget --version

# Update WinGet
winget source update

# Check package details
winget show YourPublisher.SonyBraviaScripts

# Install with logs
winget install sony-bravia --logs
```

### Package not found

If package was recently published:
```powershell
# Refresh sources
winget source reset --force
winget source update
```

### Dependencies missing

Install dependencies manually:
```powershell
# PowerShell 7
winget install Microsoft.PowerShell

# ADB (via Scoop or Chocolatey)
scoop install adb
# or
choco install adb
```

## Manifest Fields

### Required Fields
- **PackageIdentifier**: Unique identifier (Publisher.PackageName)
- **PackageVersion**: Semantic version (x.y.z.w)
- **PackageName**: Display name
- **Publisher**: Publisher name
- **License**: License type
- **ShortDescription**: Brief description (< 100 chars)
- **InstallerUrl**: Download URL
- **InstallerSha256**: SHA256 hash
- **InstallerType**: zip, portable, exe, msi, etc.
- **ManifestVersion**: Manifest schema version

### Optional Fields
- **Moniker**: Short alias for installation
- **Tags**: Search keywords
- **Commands**: Executable commands provided
- **Dependencies**: External dependencies
- **ReleaseNotesUrl**: Link to release notes

## Contributing

To contribute improvements to the WinGet manifest:

1. Fork the repository
2. Edit `winget/sony-bravia-scripts.yaml`
3. Test locally: `winget install --manifest winget\`
4. Submit pull request

## Resources

- [WinGet Documentation](https://docs.microsoft.com/windows/package-manager/)
- [Manifest Schema](https://github.com/microsoft/winget-cli/tree/master/schemas)
- [WinGet Packages Repository](https://github.com/microsoft/winget-pkgs)
- [WinGet Create Tool](https://github.com/microsoft/winget-create)
- [Package Submission Guidelines](https://github.com/microsoft/winget-pkgs/blob/master/CONTRIBUTING.md)
