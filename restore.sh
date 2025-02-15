#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Enable debug mode
DEBUG=true

# Fixed debug_print function
debug_print() {
    if [ "$DEBUG" = true ]; then
        echo -e "${BLUE}[DEBUG] $1${NC}" >&2
    fi
}

# Function to detect OS
detect_os() {
    local os_type
    os_type="$(uname -s)"
    debug_print "Detected OS type: $os_type"
    
    case "$os_type" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                debug_print "Linux distribution: $ID"
                echo "${ID}"
            else
                echo "linux"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Function to install package manager and packages
setup_package_manager() {
    local os=$1
    debug_print "Setting up package manager for OS: $os"
    
    case "$os" in
        macos)
            if ! command -v brew &> /dev/null; then
                debug_print "Installing Homebrew"
                if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
                    echo -e "${RED}Error: Failed to install Homebrew${NC}" >&2
                    return 1
                fi
            fi
            if [ -f "Brewfile" ]; then
                debug_print "Installing packages from Brewfile"
                if ! brew bundle install --file="Brewfile" 2>&1 | while read -r line; do
                    debug_print "brew bundle: $line"
                done; then
                    echo -e "${RED}Error: Failed to install Homebrew packages${NC}" >&2
                    return 1
                fi
            fi
            ;;
        ubuntu|debian)
            debug_print "Updating apt package lists"
            sudo apt-get update 2>&1 | while read -r line; do
                debug_print "apt update: $line"
            done
            debug_print "Installing essential packages"
            sudo apt-get install -y git curl wget zsh neovim 2>&1 | while read -r line; do
                debug_print "apt install: $line"
            done
            ;;
        fedora)
            debug_print "Installing essential packages via dnf"
            sudo dnf install -y git curl wget zsh neovim 2>&1 | while read -r line; do
                debug_print "dnf install: $line"
            done
            ;;
        arch)
            debug_print "Installing essential packages via pacman"
            sudo pacman -Syu --noconfirm git curl wget zsh neovim 2>&1 | while read -r line; do
                debug_print "pacman install: $line"
            done
            ;;
        windows)
            if ! command -v winget &> /dev/null; then
                echo -e "${RED}Error: Windows Package Manager (winget) not found${NC}" >&2
                echo "Visit: https://apps.microsoft.com/store/detail/app-installer/9NBLGGH4NNS1"
                return 1
            fi
            debug_print "Installing essential packages via winget"
            for pkg in "Git.Git" "Microsoft.PowerShell" "Neovim.Neovim"; do
                debug_print "Installing $pkg"
                winget install -e --id "$pkg" 2>&1 | while read -r line; do
                    debug_print "winget install: $line"
                done
            done
            ;;
    esac
}

OS=$(detect_os)
debug_print "Operating system detected: $OS"

# Check for backup zip file
if [ $# -eq 0 ]; then
    echo -e "${RED}Error: Please provide the backup zip file${NC}" >&2
    echo "Usage: $0 <backup_zip_file>" >&2
    exit 1
fi

BACKUP_ZIP=$1
debug_print "Using backup file: $BACKUP_ZIP"

if [ ! -f "$BACKUP_ZIP" ]; then
    echo -e "${RED}Error: Backup file not found: $BACKUP_ZIP${NC}" >&2
    exit 1
fi

# Create temporary directory for extraction
TEMP_DIR="/tmp/env_restore_$(date +%s)"
debug_print "Creating temporary directory: $TEMP_DIR"
mkdir -p "$TEMP_DIR"

# List contents of zip file before extraction
debug_print "Listing contents of zip file:"
unzip -l "$BACKUP_ZIP" | while read -r line; do
    debug_print "zip contents: $line"
done

# Extract the backup
debug_print "Extracting backup archive"
if ! unzip -q "$BACKUP_ZIP" -d "$TEMP_DIR"; then
    echo -e "${RED}Error: Failed to extract backup archive${NC}" >&2
    rm -rf "$TEMP_DIR"
    exit 1
fi

# List contents of temp directory
debug_print "Contents of temp directory:"
ls -la "$TEMP_DIR" | while read -r line; do
    debug_print "temp dir: $line"
done

# Find the backup directory - improved detection
BACKUP_DIR=""
for dir in "$TEMP_DIR"/*; do
    if [ -d "$dir" ]; then
        debug_print "Found directory: $dir"
        # Check if this is a valid backup directory by looking for common files/directories
        if [ -d "$dir/.config" ] || [ -d "$dir/.local" ] || [ -f "$dir/.zshrc" ]; then
            BACKUP_DIR="$dir"
            break
        fi
    fi
done

debug_print "Using backup directory: $BACKUP_DIR"

if [ -z "$BACKUP_DIR" ] || [ ! -d "$BACKUP_DIR" ]; then
    echo -e "${RED}Error: Invalid backup archive structure${NC}" >&2
    debug_print "No valid backup directory found in: $TEMP_DIR"
    ls -la "$TEMP_DIR" | while read -r line; do
        debug_print "$line"
    done
    rm -rf "$TEMP_DIR"
    exit 1
fi

cd "$BACKUP_DIR" || {
    echo -e "${RED}Error: Could not change to backup directory${NC}" >&2
    rm -rf "$TEMP_DIR"
    exit 1
}

# List contents of backup directory
debug_print "Contents of backup directory:"
ls -la | while read -r line; do
    debug_print "backup dir: $line"
done

# Function to create directory if it doesn't exist
ensure_dir() {
    local dir="$1"
    debug_print "Ensuring directory exists: $dir"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" 2>/dev/null
        debug_print "Created directory: $dir"
    fi
}

# Special handling for Neovim lazy directory
debug_print "Handling Neovim lazy directory restoration"
if [ -d ".local/share/nvim/lazy" ]; then
    ensure_dir "$HOME/.local/share/nvim"
    debug_print "Removing existing Neovim lazy directory if it exists"
    rm -rf "$HOME/.local/share/nvim/lazy"
    debug_print "Copying Neovim lazy directory"
    if ! cp -R ".local/share/nvim/lazy" "$HOME/.local/share/nvim/" 2>&1 | while read -r line; do
        debug_print "cp: $line"
    done; then
        echo -e "${RED}Error: Failed to restore Neovim lazy directory${NC}" >&2
    fi
else
    debug_print "No Neovim lazy directory found in backup"
fi

# Restore config directories
for dir in .config/*/; do
    if [ -d "$dir" ]; then
        debug_print "Restoring config directory: $dir"
        ensure_dir "$HOME/$dir"
        if ! cp -R "$dir" "$HOME/$(dirname "$dir")/" 2>&1 | while read -r line; do
            debug_print "cp: $line"
        done; then
            echo -e "${RED}Error: Failed to restore $dir${NC}" >&2
        fi
    fi
done

# Restore dotfiles
for file in .*; do
    if [ -f "$file" ] && [ "$file" != "." ] && [ "$file" != ".." ] && [ "$file" != ".DS_Store" ]; then
        debug_print "Restoring dotfile: $file"
        if ! cp "$file" "$HOME/$file" 2>&1 | while read -r line; do
            debug_print "cp: $line"
        done; then
            echo -e "${RED}Error: Failed to restore $file${NC}" >&2
        fi
    fi
done

# Clean up
debug_print "Cleaning up temporary directory"
cd || true
rm -rf "$TEMP_DIR"

echo -e "${GREEN}Restoration complete${NC}"

case "$OS" in
    macos)
        echo -e "${YELLOW}Run: source ~/.zshrc${NC}"
        ;;
    linux*)
        echo -e "${YELLOW}Run: chsh -s $(which zsh)${NC}"
        ;;
    windows)
        echo -e "${YELLOW}Note: Some paths may need manual adjustment${NC}"
        echo -e "${YELLOW}Consider using WSL for better compatibility${NC}"
        ;;
esac
