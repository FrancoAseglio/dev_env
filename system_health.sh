#!/bin/bash

LOG_DIR="$HOME/health_logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/sys_health_$(date +%Y-%m-%d_%H-%M-%S).log"

# Function to log output
log_section() {
    echo -e "\n$1" | tee -a "$LOG_FILE"
    echo "------------------------------------" | tee -a "$LOG_FILE"
}

echo "===== macOS System Health Check =====" | tee "$LOG_FILE"

# Homebrew Casks
log_section "📦 Installed Homebrew Casks:"
brew list --cask | tee -a "$LOG_FILE"

log_section "🔄 Outdated Casks:"
brew outdated --quiet --cask | tee -a "$LOG_FILE" || echo "✅ All casks are up to date." | tee -a "$LOG_FILE"

# Check for PostgreSQL and pgcli
log_section "🐘 PostgreSQL Status:"
if command -v postgres &> /dev/null; then
    echo "PostgreSQL version: $(postgres --version)" | tee -a "$LOG_FILE"
    # Check if PostgreSQL service is running
    if command -v brew &> /dev/null && brew services list | grep -q postgresql; then
        brew services list | grep postgresql | tee -a "$LOG_FILE"
    else
        echo "PostgreSQL is installed but brew services entry not found" | tee -a "$LOG_FILE"
    fi
else
    echo "❌ PostgreSQL is not installed" | tee -a "$LOG_FILE"
fi

log_section "📊 PostgreSQL CLI Tools:"
if command -v pgcli &> /dev/null; then
    echo "pgcli version: $(pgcli --version)" | tee -a "$LOG_FILE"
    echo "pgcli config location: $HOME/.config/pgcli/" | tee -a "$LOG_FILE"
    if [ -f "$HOME/.pgpass" ]; then
        echo "✅ .pgpass file exists" | tee -a "$LOG_FILE"
        # Check if permissions are correct
        permissions=$(stat -f "%Lp" "$HOME/.pgpass")
        if [ "$permissions" = "600" ]; then
            echo "✅ .pgpass permissions are correct (600)" | tee -a "$LOG_FILE"
        else
            echo "⚠️ .pgpass permissions should be 600, current: $permissions" | tee -a "$LOG_FILE"
        fi
    else
        echo "⚠️ No .pgpass file found" | tee -a "$LOG_FILE"
    fi
else
    echo "❌ pgcli is not installed" | tee -a "$LOG_FILE"
fi

# Storage Analysis
log_section "🗑️  Largest Files in Home Directory (Top 10):"
du -ah ~ 2>/dev/null | sort -rh | head -10 | tee -a "$LOG_FILE"

log_section "📂 Empty Files (Top 10):"
find ~ -type f -empty | head -10 | tee -a "$LOG_FILE"

log_section "📁 Files Not Modified in 6+ Months (Top 10):"
find ~ -type f -mtime +180 | head -10 | tee -a "$LOG_FILE"

# Memory Usage
log_section "🧠 Memory Usage:"
vm_stat | awk 'NR>2{gsub("\\.",""); sum+=$2} END{printf "Used Memory: %.2f MB\\n", sum*4096/1024/1024}' | tee -a "$LOG_FILE"
top -l 1 | grep PhysMem | tee -a "$LOG_FILE"

# CPU Usage
log_section "⚙️  CPU Usage (Top 5 Processes):"
ps -eo pid,ppid,%mem,%cpu,comm | sort -k4 -nr | head -5 | tee -a "$LOG_FILE"

# Disk Space
log_section "💾 Disk Usage:"
df -h | awk '{print $1, $2, $3, $4, $5, $6}' | tee -a "$LOG_FILE"

# Homebrew Health
log_section "🛠️  Homebrew Health Check:"
brew doctor | tee -a "$LOG_FILE"

# Recent System Errors (excluding Bluetooth noise)
log_section "🚨 Recent System Errors (Last Hour):"
log show --predicate 'eventMessage contains[c] "error" AND subsystem != "com.apple.bluetooth"' --last 1h | tail -10 | tee -a "$LOG_FILE"

# Battery Health
log_section "🔋 Battery Health:"
pmset -g batt | tee -a "$LOG_FILE"

# Network Information
log_section "🌐 Network Information:"
ifconfig | tee -a "$LOG_FILE"

# Running Services
log_section "🛠 Running Services:"
brew services list | tee -a "$LOG_FILE"

echo -e "\n✅ System Health Check Complete! Log saved to: $LOG_FILE"
