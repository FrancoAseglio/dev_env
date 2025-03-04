# Mac Environment Backup & System Health Check Scripts

A set of scripts for backing up and monitoring your macOS development environment, including configurations for various tools, dotfiles, Homebrew packages, and system health checks.

## Features

- **Backup Script:**

  - Backs up:
    - Homebrew packages (formulae and casks)
    - Config directories (.config/\*)
    - Neovim configuration and plugins
    - Various dotfiles (.zshrc, .gitconfig, etc.)
    - Terminal configurations (WezTerm, etc.)
  - Cross-platform restore capability
  - Verification of backed-up files
  - Automatic package manager setup on restore

- **System Health Check Script:**

  - Checks:
    - Installed and outdated Homebrew casks
    - Large files, empty files, and old files
    - Memory usage and compression status
    - CPU usage and active processes
    - Disk space and running services
    - Network status and battery health
    - Security settings (Gatekeeper, SIP, Firewall)
  - Saves a detailed log file in `~/macos-health-logs/`

- **Rollback Script (Restoration Undo):**
  - Restores system to its pre-restoration state
  - Backs up current configurations before rolling back
  - Supports:
    - Dotfiles (.zshrc, .gitconfig, etc.)
    - Config directories (.config/nvim, .ssh, etc.)
    - Permissions reset for .ssh and .local/bin
    - Works cross-platform with macOS, Linux, and WS

---

## Prerequisites

- macOS (for backup and health check)
- Any Unix-like system or Windows with WSL (for restore)
- Bash shell
- `zip` utility (for backup)
- `unzip` utility (for restore)

---

## Usage

### System Health Check (macOS only)

```bash
chmod +x system_health.sh
./system_health.sh
```

This will generate a log file in `~/macos-health-logs/` with detailed system health information.

### Backup (macOS only)

```bash
chmod +x backup.sh
./backup.sh
```

This will create a zip file named `mac_env_backup_YYYYMMDD_HHMMSS.zip` in your current directory.

### Restore (Cross-platform)

```bash
chmod +x restore.sh
./restore.sh mac_env_backup_20250304_123456.zip
```

### Rollback (Undo a Failed Restoration)

If a restoration introduces issues, you can rollback to the previous state:

```bash
chmod +x rollback.sh
./rollback.sh
```

---

## Post-Restore Steps

Depending on your OS:

- macOS: `source ~/.zshrc`
- Linux: `chsh -s $(which zsh)`
- Windows: Consider using WSL for better compatibility

## Customization

To add more directories or files to backup, edit the `CONFIG_DIRS` and `CONFIG_FILES` arrays in `backup.sh`.

## Troubleshooting

If you encounter issues:

1. Check file permissions
2. Ensure all required utilities are installed
3. Verify the backup zip file exists and isn't corrupted
4. Check available disk space in the destination
5. Run the rollback script if needed
