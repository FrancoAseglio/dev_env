#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Enable debug mode
DEBUG=true

debug_print() {
    if [ "$DEBUG" = true ]; then
        echo -e "${BLUE}[DEBUG] $1${NC}" >&2
    fi
}

# Create backup directory with timestamp
BACKUP_DIR="$HOME/mac_env_backup_$(date +%Y%m%d_%H%M%S)"
debug_print "Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Function to verify backup of a file or directory
verify_backup() {
    local source="$1"
    local dest="$2"
    debug_print "Verifying backup: $source -> $dest"
    
    if [ -f "$source" ]; then
        # For files, compare checksums
        local source_md5=$(md5 -q "$source")
        local dest_md5=$(md5 -q "$dest")
        debug_print "File MD5 comparison: $source_md5 vs $dest_md5"
        if [ "$source_md5" = "$dest_md5" ]; then
            return 0
        fi
    elif [ -d "$source" ]; then
        # For directories, compare sizes and file counts
        local source_count=$(find "$source" -type f | wc -l)
        local dest_count=$(find "$dest" -type f | wc -l)
        debug_print "Directory file count comparison: $source_count vs $dest_count"
        if [ "$source_count" = "$dest_count" ]; then
            return 0
        fi
    fi
    echo -e "${RED}Error: Verification failed for $source${NC}" >&2
    return 1
}

# Backup Homebrew
if command -v brew &> /dev/null; then
    debug_print "Backing up Homebrew configuration"
    brew bundle dump --force --file="$BACKUP_DIR/Brewfile" 2>/dev/null
    brew leaves > "$BACKUP_DIR/brew_leaves.txt" 2>/dev/null
    brew list --formula > "$BACKUP_DIR/brew_formulae.txt" 2>/dev/null
    brew list --cask > "$BACKUP_DIR/brew_casks.txt" 2>/dev/null
    cp -R "$(brew --repository)/.git/config" "$BACKUP_DIR/homebrew_git_config" 2>/dev/null
else
    echo -e "${YELLOW}Warning: Homebrew not installed${NC}" >&2
fi

# Define config directories to backup
CONFIG_DIRS=(
    ".config/nvim"
    ".config/wezterm"
    ".config/bat"
    ".config/btop"
    ".config/yazi"
    ".config/lazygit"
    ".config/jdtls"
    ".config/macchina"
    ".config/pgcli"
)

# Backup config directories
for config in "${CONFIG_DIRS[@]}"; do
    if [ -d "$HOME/$config" ]; then
        debug_print "Backing up directory: $config"
        mkdir -p "$BACKUP_DIR/$config"
        cp -Rv "$HOME/$config/." "$BACKUP_DIR/$config/" 2>&1 | while read -r line; do
            debug_print "$line"
        done
        verify_backup "$HOME/$config" "$BACKUP_DIR/$config"
    else
        debug_print "Directory not found: $config"
    fi
done

# Backup Neovim plugins with detailed logging
NVIM_LAZY_DIR="$HOME/.local/share/nvim/lazy"
if [ -d "$NVIM_LAZY_DIR" ]; then
    debug_print "Backing up Neovim plugins from: $NVIM_LAZY_DIR"
    mkdir -p "$BACKUP_DIR/.local/share/nvim"
    cp -Rv "$NVIM_LAZY_DIR" "$BACKUP_DIR/.local/share/nvim/" 2>&1 | while read -r line; do
        debug_print "$line"
    done
    verify_backup "$NVIM_LAZY_DIR" "$BACKUP_DIR/.local/share/nvim/lazy"
else
    debug_print "Neovim lazy directory not found: $NVIM_LAZY_DIR"
fi

# Backup dotfiles
DOTFILES=(
    ".zshrc"
    ".bashrc"
    ".bash_profile"
    ".profile"
    ".gitconfig"
    ".zsh_history"
    ".zprofile"
    ".zshenv"
    ".zlogin"
    ".pgpass"
)

for file in "${DOTFILES[@]}"; do
    if [ -f "$HOME/$file" ]; then
        debug_print "Backing up dotfile: $file"
        cp -v "$HOME/$file" "$BACKUP_DIR/$file" 2>&1 | while read -r line; do
            debug_print "$line"
        done
        verify_backup "$HOME/$file" "$BACKUP_DIR/$file"
    else
        debug_print "Dotfile not found: $file"
    fi
done

# Create zip archive with verbose output
BACKUP_FILENAME="mac_env_backup_$(date +%Y%m%d_%H%M%S).zip"
debug_print "Creating backup archive: $BACKUP_FILENAME"
cd "$(dirname "$BACKUP_DIR")"
if ! zip -rv "$BACKUP_FILENAME" "$(basename "$BACKUP_DIR")" -x "*.DS_Store" 2>&1 | while read -r line; do
    debug_print "$line"
done; then
    echo -e "${RED}Error: Failed to create backup archive${NC}" >&2
    exit 1
fi

# Cleanup
debug_print "Cleaning up temporary directory: $BACKUP_DIR"
rm -rf "$BACKUP_DIR"

echo -e "${GREEN}Backup complete: $BACKUP_FILENAME${NC}"
