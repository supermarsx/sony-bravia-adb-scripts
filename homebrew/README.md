# Homebrew Formula

This directory contains the Homebrew formula for Sony Bravia ADB Scripts.

## Installation

### Option 1: Install from tap (recommended when available)

```bash
# Add tap
brew tap yourusername/sony-bravia

# Install
brew install sony-bravia-scripts
```

### Option 2: Install directly from URL

```bash
brew install https://raw.githubusercontent.com/yourusername/sony-bravia-adb-scripts/main/homebrew/sony-bravia-scripts.rb
```

### Option 3: Install from local formula

```bash
# From this repository directory
brew install homebrew/sony-bravia-scripts.rb
```

## Usage

After installation, the command `sony-bravia` will be available:

```bash
# Interactive mode
sony-bravia

# CLI mode
sony-bravia -Action a1

# Batch mode
sony-bravia -Action "a1,a2,a3"

# Help
sony-bravia --help
```

## Dependencies

The formula automatically installs required dependencies:
- PowerShell (`powershell`)
- Android Platform Tools (`android-platform-tools`)

## Updating

```bash
# Update Homebrew
brew update

# Upgrade to latest version
brew upgrade sony-bravia-scripts
```

## Uninstalling

```bash
brew uninstall sony-bravia-scripts
```

## Formula Development

### Testing the formula

```bash
# Audit formula
brew audit --strict sony-bravia-scripts.rb

# Test installation
brew install --build-from-source homebrew/sony-bravia-scripts.rb

# Run tests
brew test sony-bravia-scripts
```

### Updating SHA256

When a new release is published, update the SHA256 hash:

```bash
# Calculate SHA256 for new release
shasum -a 256 sony-bravia-scripts-unix.zip

# Update formula with new hash
```

The CI/CD pipeline automatically updates this formula on each rolling release.

## Troubleshooting

### Formula fails to install

Check that dependencies are available:
```bash
brew doctor
brew install powershell
brew install android-platform-tools
```

### Command not found

Ensure Homebrew's bin directory is in your PATH:
```bash
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Permission issues

Homebrew requires write access to `/usr/local` (Intel) or `/opt/homebrew` (Apple Silicon):
```bash
# Fix permissions
sudo chown -R $(whoami) /opt/homebrew
```

## Contributing

To contribute improvements to the Homebrew formula:

1. Fork the repository
2. Edit `homebrew/sony-bravia-scripts.rb`
3. Test locally: `brew install --build-from-source homebrew/sony-bravia-scripts.rb`
4. Submit pull request

## Resources

- [Homebrew Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- [Homebrew Ruby API](https://rubydoc.brew.sh/Formula)
- [Creating Taps](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap)
