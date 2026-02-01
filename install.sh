#!/usr/bin/env bash
#
# Installation script for Sony Bravia ADB Scripts (macOS/Linux)
#
# Usage:
#   ./install.sh
#   ./install.sh --install-path ~/sony-bravia
#   ./install.sh --skip-adb --skip-pwsh

set -euo pipefail

# Configuration
INSTALL_PATH="${HOME}/.local/bin/sony-bravia-scripts"
SKIP_ADB=false
SKIP_PWSH=false
LOG_FILE="/tmp/sony-bravia-install.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Functions
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    case "$level" in
        INFO)
            echo -e "${NC}$message${NC}"
            ;;
        WARNING)
            echo -e "${YELLOW}$message${NC}"
            ;;
        ERROR)
            echo -e "${RED}$message${NC}"
            ;;
        SUCCESS)
            echo -e "${GREEN}$message${NC}"
            ;;
    esac
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

install_adb_macos() {
    log INFO "Checking for ADB installation..."
    
    if command_exists adb; then
        local adb_version
        adb_version=$(adb version | head -n1)
        log SUCCESS "ADB already installed: $adb_version"
        return 0
    fi
    
    log WARNING "ADB not found."
    
    # Check for Homebrew
    if command_exists brew; then
        log INFO "Installing ADB via Homebrew..."
        if brew install android-platform-tools; then
            log SUCCESS "ADB installed successfully via Homebrew"
            return 0
        else
            log WARNING "Homebrew installation failed"
        fi
    else
        log WARNING "Homebrew not found. Install from: https://brew.sh"
    fi
    
    # Manual download
    log INFO "Downloading platform-tools from Google..."
    local download_url="https://dl.google.com/android/repository/platform-tools-latest-darwin.zip"
    local download_path="/tmp/platform-tools.zip"
    local extract_path="${INSTALL_PATH}/platform-tools"
    
    if curl -L "$download_url" -o "$download_path"; then
        mkdir -p "$extract_path"
        if unzip -o "$download_path" -d "${INSTALL_PATH}"; then
            rm "$download_path"
            
            # Add to PATH in shell profiles
            local shell_profile
            if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == */zsh ]]; then
                shell_profile="${HOME}/.zshrc"
            else
                shell_profile="${HOME}/.bashrc"
            fi
            
            local path_export="export PATH=\"\$PATH:${extract_path}\""
            if ! grep -q "$extract_path" "$shell_profile" 2>/dev/null; then
                echo "$path_export" >> "$shell_profile"
                log INFO "Added platform-tools to PATH in $shell_profile"
            fi
            
            export PATH="$PATH:${extract_path}"
            log SUCCESS "ADB installed successfully at: $extract_path"
            return 0
        fi
    fi
    
    log ERROR "Failed to download/install ADB"
    return 1
}

install_adb_linux() {
    log INFO "Checking for ADB installation..."
    
    if command_exists adb; then
        local adb_version
        adb_version=$(adb version | head -n1)
        log SUCCESS "ADB already installed: $adb_version"
        return 0
    fi
    
    log WARNING "ADB not found."
    
    # Detect package manager
    if command_exists apt-get; then
        log INFO "Installing ADB via apt..."
        if sudo apt-get update && sudo apt-get install -y adb; then
            log SUCCESS "ADB installed successfully via apt"
            return 0
        fi
    elif command_exists dnf; then
        log INFO "Installing ADB via dnf..."
        if sudo dnf install -y android-tools; then
            log SUCCESS "ADB installed successfully via dnf"
            return 0
        fi
    elif command_exists pacman; then
        log INFO "Installing ADB via pacman..."
        if sudo pacman -S --noconfirm android-tools; then
            log SUCCESS "ADB installed successfully via pacman"
            return 0
        fi
    fi
    
    # Manual download
    log INFO "Downloading platform-tools from Google..."
    local download_url="https://dl.google.com/android/repository/platform-tools-latest-linux.zip"
    local download_path="/tmp/platform-tools.zip"
    local extract_path="${INSTALL_PATH}/platform-tools"
    
    if curl -L "$download_url" -o "$download_path"; then
        mkdir -p "$extract_path"
        if unzip -o "$download_path" -d "${INSTALL_PATH}"; then
            rm "$download_path"
            
            # Add to PATH
            local shell_profile
            if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == */zsh ]]; then
                shell_profile="${HOME}/.zshrc"
            else
                shell_profile="${HOME}/.bashrc"
            fi
            
            local path_export="export PATH=\"\$PATH:${extract_path}\""
            if ! grep -q "$extract_path" "$shell_profile" 2>/dev/null; then
                echo "$path_export" >> "$shell_profile"
                log INFO "Added platform-tools to PATH in $shell_profile"
            fi
            
            export PATH="$PATH:${extract_path}"
            log SUCCESS "ADB installed successfully at: $extract_path"
            return 0
        fi
    fi
    
    log ERROR "Failed to download/install ADB"
    return 1
}

install_pwsh() {
    log INFO "Checking PowerShell installation..."
    
    if command_exists pwsh; then
        local pwsh_version
        pwsh_version=$(pwsh --version)
        log SUCCESS "PowerShell already installed: $pwsh_version"
        return 0
    fi
    
    log WARNING "PowerShell not found."
    echo -n "Install PowerShell? (y/N): "
    read -r response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log WARNING "Skipping PowerShell installation"
        return 1
    fi
    
    local os_type
    os_type=$(detect_os)
    
    if [[ "$os_type" == "macos" ]]; then
        if command_exists brew; then
            log INFO "Installing PowerShell via Homebrew..."
            if brew install --cask powershell; then
                log SUCCESS "PowerShell installed successfully"
                return 0
            fi
        fi
    elif [[ "$os_type" == "linux" ]]; then
        if command_exists snap; then
            log INFO "Installing PowerShell via snap..."
            if sudo snap install powershell --classic; then
                log SUCCESS "PowerShell installed successfully"
                return 0
            fi
        elif command_exists apt-get; then
            log INFO "Installing PowerShell via apt..."
            # Add Microsoft repository
            wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"
            sudo dpkg -i packages-microsoft-prod.deb
            rm packages-microsoft-prod.deb
            
            sudo apt-get update
            if sudo apt-get install -y powershell; then
                log SUCCESS "PowerShell installed successfully"
                return 0
            fi
        fi
    fi
    
    log INFO "Please install PowerShell manually from:"
    log INFO "https://github.com/PowerShell/PowerShell"
    return 1
}

install_scripts() {
    log INFO "Installing Sony Bravia ADB Scripts..."
    
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    mkdir -p "$INSTALL_PATH"
    
    # Copy main script
    if [[ -f "${script_dir}/sony-bravia-scripts.ps1" ]]; then
        cp "${script_dir}/sony-bravia-scripts.ps1" "$INSTALL_PATH/"
        log SUCCESS "Copied main script to $INSTALL_PATH"
    else
        log ERROR "Main script not found: ${script_dir}/sony-bravia-scripts.ps1"
        return 1
    fi
    
    # Copy launcher
    if [[ -f "${script_dir}/sony-bravia-scripts.sh" ]]; then
        cp "${script_dir}/sony-bravia-scripts.sh" "$INSTALL_PATH/"
        chmod +x "${INSTALL_PATH}/sony-bravia-scripts.sh"
        log SUCCESS "Copied launcher to $INSTALL_PATH"
    fi
    
    # Copy documentation
    if [[ -f "${script_dir}/readme.md" ]]; then
        cp "${script_dir}/readme.md" "$INSTALL_PATH/"
    fi
    
    # Create symlink in PATH
    echo -n "Create symlink in ~/.local/bin? (Y/n): "
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]] || [[ -z "$response" ]]; then
        mkdir -p "${HOME}/.local/bin"
        ln -sf "${INSTALL_PATH}/sony-bravia-scripts.sh" "${HOME}/.local/bin/sony-bravia"
        
        # Add to PATH if needed
        local shell_profile
        if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == */zsh ]]; then
            shell_profile="${HOME}/.zshrc"
        else
            shell_profile="${HOME}/.bashrc"
        fi
        
        local path_export="export PATH=\"\$PATH:\${HOME}/.local/bin\""
        if ! grep -q ".local/bin" "$shell_profile" 2>/dev/null; then
            echo "$path_export" >> "$shell_profile"
            log INFO "Added ~/.local/bin to PATH in $shell_profile"
        fi
        
        export PATH="$PATH:${HOME}/.local/bin"
        log SUCCESS "Symlink created: sony-bravia"
    fi
    
    return 0
}

show_summary() {
    echo ""
    echo -e "${CYAN}============================================${NC}"
    echo -e "${CYAN}  Sony Bravia ADB Scripts - Installation  ${NC}"
    echo -e "${CYAN}============================================${NC}"
    echo ""
    echo -e "${GREEN}Installation Path: $INSTALL_PATH${NC}"
    echo -e "${GRAY}Log File: $LOG_FILE${NC}"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo -e "  ${NC}1. Enable USB Debugging on your Sony Bravia TV:${NC}"
    echo -e "     ${GRAY}Settings > Network & Internet > Home Network Setup >${NC}"
    echo -e "     ${GRAY}IP Control > Authentication > Normal and Pre-Shared Key${NC}"
    echo ""
    echo -e "  ${NC}2. Find your TV's IP address:${NC}"
    echo -e "     ${GRAY}Settings > Network & Internet > Advanced Settings > Network Status${NC}"
    echo ""
    echo -e "  ${NC}3. Connect via ADB:${NC}"
    echo -e "     ${GRAY}adb connect <tv-ip>:5555${NC}"
    echo ""
    echo -e "  ${NC}4. Run the script:${NC}"
    echo -e "     ${GRAY}sony-bravia   (if symlink created)${NC}"
    echo -e "     ${GRAY}OR${NC}"
    echo -e "     ${GRAY}${INSTALL_PATH}/sony-bravia-scripts.sh${NC}"
    echo ""
    echo -e "${CYAN}Documentation: ${INSTALL_PATH}/readme.md${NC}"
    echo ""
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --install-path)
            INSTALL_PATH="$2"
            shift 2
            ;;
        --skip-adb)
            SKIP_ADB=true
            shift
            ;;
        --skip-pwsh)
            SKIP_PWSH=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --install-path PATH    Installation directory (default: ~/.local/bin/sony-bravia-scripts)"
            echo "  --skip-adb             Skip ADB installation"
            echo "  --skip-pwsh            Skip PowerShell installation"
            echo "  -h, --help             Show this help message"
            exit 0
            ;;
        *)
            log ERROR "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Main installation flow
echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}  Sony Bravia ADB Scripts - Installer${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
echo -e "${NC}This installer will:${NC}"
echo -e "  ${GRAY}- Check/install ADB (Android Debug Bridge)${NC}"
echo -e "  ${GRAY}- Check/install PowerShell 7+ (optional)${NC}"
echo -e "  ${GRAY}- Install Sony Bravia scripts to: $INSTALL_PATH${NC}"
echo ""
echo -n "Continue? (Y/n): "
read -r response

if [[ "$response" =~ ^[Nn]$ ]]; then
    log WARNING "Installation cancelled by user"
    exit 0
fi

echo ""

# Detect OS
OS_TYPE=$(detect_os)
if [[ "$OS_TYPE" == "unknown" ]]; then
    log ERROR "Unsupported operating system: $OSTYPE"
    exit 1
fi

log INFO "Detected OS: $OS_TYPE"

# Install ADB
if [[ "$SKIP_ADB" == false ]]; then
    if [[ "$OS_TYPE" == "macos" ]]; then
        install_adb_macos || {
            log ERROR "ADB installation failed. Please install manually."
            exit 1
        }
    else
        install_adb_linux || {
            log ERROR "ADB installation failed. Please install manually."
            exit 1
        }
    fi
fi

# Install PowerShell
if [[ "$SKIP_PWSH" == false ]]; then
    install_pwsh || log WARNING "PowerShell installation skipped"
fi

# Install scripts
install_scripts || {
    log ERROR "Script installation failed"
    exit 1
}

show_summary

echo ""
log SUCCESS "Installation completed successfully!"
echo ""
echo "Please restart your terminal or run: source ~/.bashrc (or ~/.zshrc)"
echo ""

exit 0
