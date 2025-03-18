#!/bin/bash

# Restoration Rollback Script
# Use this script to revert changes made during a failed restoration

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Set HOME for Windows (WSL) compatibility
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    HOME="$USERPROFILE"
fi

# Timestamp for versioned backups
TIMESTAMP=$(date +%Y%m%d%H%M%S)
BACKUP_ROOT="$HOME/.restoration_backup_$TIMESTAMP"

# Logging function
log() {
    echo -e "${YELLOW}[ROLLBACK]${NC} $1"
}

# Error handling function
error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Create backup directory if not exists
mkdir -p "$BACKUP_ROOT"

# Restore function for specific directories/files
restore_item() {
    local target="$1"
    local backup_path="$BACKUP_ROOT/$(basename "$target")"

    if [ -d "$backup_path" ]; then
        log "Restoring directory: $target"
        rm -rf "$target"
        mv "$backup_path" "$target"
    elif [ -f "$backup_path" ]; then
        log "Restoring file: $target"
        cp "$backup_path" "$target"
    else
        error "No backup found for $target"
    fi
}

# Backup and potentially remove items before restoration
backup_for_restoration() {
    local target="$1"
    local backup_path="$BACKUP_ROOT/$(basename "$target")"

    if [ -e "$target" ]; then
        log "Creating backup of $target"

        # Remove previous backup if exists
        rm -rf "$backup_path"

        # Create new backup
        if [ -d "$target" ]; then
            cp -R "$target" "$backup_path"
        else
            cp "$target" "$backup_path"
        fi
    fi
}

# Main restoration rollback function
rollback_restoration() {
    log "Starting restoration rollback process"

    # List of items to restore
    restore_targets=(
        "$HOME/.bashrc"
        "$HOME/.zshrc"
        "$HOME/.vimrc"
        "$HOME/.config/nvim"
        "$HOME/.local/share/nvim"
        "$HOME/.gitconfig"
        "$HOME/.ssh"
        "$HOME/.local/bin"
        "$HOME/.config/tmux"
        "$HOME/.profile"
        "$HOME/.aliases"
        "$HOME/.config/pgcli"
        "$HOME/.pgpass"
    )

    # Backup existing items before potential restoration
    for item in "${restore_targets[@]}"; do
        backup_for_restoration "$item"
    done

    # Restore from backups
    for item in "${restore_targets[@]}"; do
        restore_item "$item"
    done

    # Ensure correct permissions for restored files
    log "Fixing permissions for restored files..."
    chmod 600 "$HOME/.ssh/id_rsa" 2>/dev/null
    chmod 644 "$HOME/.ssh/id_rsa.pub" 2>/dev/null
    chmod 700 "$HOME/.ssh" 2>/dev/null
    chmod -R 755 "$HOME/.local/bin" 2>/dev/null
    chmod 600 "$HOME/.pgpass" 2>/dev/null

    log "Restoration rollback complete"
    echo -e "${GREEN}Your system has been restored to its pre-restoration state.${NC}"
}

# Execute rollback
rollback_restoration
