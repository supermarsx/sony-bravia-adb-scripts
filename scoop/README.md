# Scoop Manifest

This directory contains the Scoop manifest for Sony Bravia ADB Scripts.

## Installation

### Option 1: Install from bucket (recommended when available)

```powershell
# Add bucket
scoop bucket add sony-bravia https://github.com/supermarsx/scoop-sony-bravia

# Install
scoop install sony-bravia-scripts
```

### Option 2: Install directly from URL

```powershell
scoop install https://raw.githubusercontent.com/supermarsx/sony-bravia-adb-scripts/main/scoop/sony-bravia-scripts.json
```

### Option 3: Install from local manifest

```powershell
# From this repository directory
scoop install scoop\sony-bravia-scripts.json
```

## Usage

After installation, the command `sony-bravia-scripts` will be available:

```powershell
# Interactive mode
sony-bravia-scripts

# CLI mode
sony-bravia-scripts -Action a1

# Batch mode
sony-bravia-scripts -Action "a1,a2,a3"

# From Start Menu
# Windows key > Sony Bravia Scripts
```

## Dependencies

The manifest automatically installs required dependencies:
- `adb` (Android Debug Bridge)
- `pwsh` (PowerShell 7+)

If dependencies are missing, Scoop will prompt you to install them.

## Updating

```powershell
# Update Scoop
scoop update

# Upgrade to latest version
scoop update sony-bravia-scripts
```

## Uninstalling

```powershell
scoop uninstall sony-bravia-scripts
```

## Manifest Development

### Testing the manifest

```powershell
# Validate manifest
scoop cat sony-bravia-scripts

# Test installation
scoop install scoop\sony-bravia-scripts.json

# Check installed files
scoop list sony-bravia-scripts
scoop prefix sony-bravia-scripts
```

### Updating hash

When a new release is published, update the hash:

```powershell
# Calculate SHA256 for new release
Get-FileHash sony-bravia-scripts-powershell.zip -Algorithm SHA256

# Update manifest with new hash
```

The CI/CD pipeline automatically updates this manifest on each rolling release.

## Manifest Structure

```json
{
    "version": "2.0.0-rolling",
    "description": "Sony Bravia TV ADB control scripts",
    "url": "https://github.com/.../sony-bravia-scripts-powershell.zip",
    "hash": "sha256:...",
    "depends": ["adb", "pwsh"],
    "bin": "sony-bravia-scripts.cmd",
    "shortcuts": [["sony-bravia-scripts.cmd", "Sony Bravia Scripts"]]
}
```

### Key Fields

- **version**: Current version (auto-updated by CI)
- **url**: Download URL for Windows package
- **hash**: SHA256 hash for verification
- **depends**: Required dependencies
- **bin**: Command-line executable
- **shortcuts**: Start Menu shortcuts
- **post_install**: Setup instructions displayed after installation
- **autoupdate**: Automatic version checking

## Troubleshooting

### Manifest fails to install

Check Scoop and dependencies:
```powershell
scoop --version
scoop info adb
scoop info pwsh
```

### Dependencies not found

Install manually:
```powershell
scoop install adb
scoop install pwsh
```

### Command not found after installation

Verify installation:
```powershell
scoop list
scoop which sony-bravia-scripts
```

Reset shims:
```powershell
scoop reset sony-bravia-scripts
```

### Hash mismatch error

This means the downloaded file doesn't match the expected hash. Either:
1. The manifest is outdated (wait for CI to update)
2. Download was corrupted (retry installation)
3. Release file changed (check release page)

```powershell
# Skip hash check (not recommended)
scoop install sony-bravia-scripts --skip
```

## Creating a Custom Bucket

To host your own Scoop bucket:

1. Create a new repository: `scoop-sony-bravia`
2. Add this manifest as `bucket/sony-bravia-scripts.json`
3. Users can add your bucket:
   ```powershell
   scoop bucket add sony-bravia https://github.com/yourusername/scoop-sony-bravia
   scoop install sony-bravia-scripts
   ```

## Contributing

To contribute improvements to the Scoop manifest:

1. Fork the repository
2. Edit `scoop/sony-bravia-scripts.json`
3. Test locally: `scoop install scoop\sony-bravia-scripts.json`
4. Submit pull request

## Resources

- [Scoop Documentation](https://scoop.sh/)
- [App Manifests](https://github.com/ScoopInstaller/Scoop/wiki/App-Manifests)
- [Autoupdate](https://github.com/ScoopInstaller/Scoop/wiki/App-Manifest-Autoupdate)
- [Creating Buckets](https://github.com/ScoopInstaller/Scoop/wiki/Buckets)
