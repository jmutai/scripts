#!/bin/bash

# =====================================================================
# Linux System Backup Script
# =====================================================================
# Description: This script creates a backup of important system directories,
#              compresses them using tar, and includes timestamps
#              for easy identification.
# Usage: ./system_backups.sh [config_file]
# Author: Josphat Mutai, https://cloudspinx.com
# Date: 2025-05-15
# =====================================================================

# =====================================================================
# CONFIGURATION
# =====================================================================
# Default configuration (can be overridden by config file)
BACKUP_DIR="/backup"                        # Where backups are stored
DIRECTORIES_TO_BACKUP=("/etc" "/home" "/root" "/var/log" "/opt")  # Directories to backup
EXCLUDE_PATTERNS=("*.tmp" "*.swp" "/home/*/Downloads" "/home/*/Trash")  # Patterns to exclude
RETENTION_DAYS=30                           # How many days to keep backups
LOG_FILE="/var/log/system_backup.log"       # Log file location
DATE_FORMAT="%Y-%m-%d_%H-%M-%S"             # Format for date in backup name
COMPRESSION_TYPE="gzip"                     # Options: gzip, bzip2, xz
REQUIRED_SPACE_GB=1                         # Required free space in GB

# =====================================================================
# FUNCTIONS
# =====================================================================

# Function to write log messages
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Echo to console with color
    case "$level" in
        "INFO")
            echo -e "\e[32m[INFO]\e[0m $message"  # Green
            ;;
        "WARNING")
            echo -e "\e[33m[WARNING]\e[0m $message"  # Yellow
            ;;
        "ERROR")
            echo -e "\e[31m[ERROR]\e[0m $message"  # Red
            ;;
        *)
            echo -e "[${level}] $message"
            ;;
    esac
    
    # Append to log file
    if [ -w "$(dirname "$LOG_FILE")" ]; then
        echo "[$timestamp] [${level}] $message" >> "$LOG_FILE"
    else
        echo -e "\e[31m[ERROR]\e[0m Cannot write to log file $LOG_FILE" >&2
    fi
}

# Function to load configuration from file
load_config() {
    local config_file="$1"
    if [ -f "$config_file" ]; then
        log "INFO" "Loading configuration from $config_file"
        source "$config_file"
    else
        log "WARNING" "Configuration file $config_file not found. Using defaults."
    fi
}

# Function to check for root privileges
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log "ERROR" "This script must be run as root to properly backup system files"
        exit 1
    fi
}

# Function to check available disk space
check_disk_space() {
    # Convert GB to KB (1GB = 1048576KB)
    local required_space_kb=$((REQUIRED_SPACE_GB * 1048576))
    local available_space=$(df -k "$BACKUP_DIR" | awk 'NR==2 {print $4}')
    local available_space_gb=$(echo "scale=2; $available_space / 1048576" | bc)
    
    if [ "$available_space" -lt "$required_space_kb" ]; then
        log "ERROR" "Not enough disk space. Required: ${REQUIRED_SPACE_GB}GB, Available: ${available_space_gb}GB"
        exit 1
    else
        log "INFO" "Sufficient disk space available: ${available_space_gb}GB"
    fi
}

# Function to create backup directory if it doesn't exist
create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        log "INFO" "Creating backup directory: $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
        
        if [ $? -ne 0 ]; then
            log "ERROR" "Failed to create backup directory: $BACKUP_DIR"
            exit 1
        fi
    fi
}

# Function to create the backup
create_backup() {
    local timestamp=$(date +"$DATE_FORMAT")
    local hostname=$(hostname)
    local backup_file="${BACKUP_DIR}/system_backup_${hostname}_${timestamp}.tar"
    local exclude_args=""
    
    # Build exclude arguments
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        exclude_args="$exclude_args --exclude='$pattern'"
    done
    
    # Add appropriate compression extension and option
    case "$COMPRESSION_TYPE" in
        "gzip")
            backup_file="${backup_file}.gz"
            compression_opt="-z"
            ;;
        "bzip2")
            backup_file="${backup_file}.bz2"
            compression_opt="-j"
            ;;
        "xz")
            backup_file="${backup_file}.xz"
            compression_opt="-J"
            ;;
        *)
            backup_file="${backup_file}.gz"
            compression_opt="-z"
            ;;
    esac
    
    log "INFO" "Starting backup to $backup_file"
    log "INFO" "Backing up: ${DIRECTORIES_TO_BACKUP[*]}"
    
    # Create the backup command
    # We use eval because we need to expand the exclude_args array
    backup_cmd="tar $compression_opt -cvf \"$backup_file\" $exclude_args ${DIRECTORIES_TO_BACKUP[*]} 2>/tmp/backup_errors.log"
    
    log "INFO" "Executing: $backup_cmd"
    
    # Execute backup command
    eval $backup_cmd
    
    # Check for errors
    if [ $? -eq 0 ]; then
        log "INFO" "Backup completed successfully: $backup_file"
        log "INFO" "Backup size: $(du -h "$backup_file" | cut -f1)"
        
        # Store list of backed up files
        log "INFO" "Creating file list..."
        tar -tvf "$backup_file" > "${backup_file%.tar.*}.file_list.txt" 2>/dev/null
    else
        log "ERROR" "Backup failed! Check /tmp/backup_errors.log for details"
        
        if [ -f "/tmp/backup_errors.log" ]; then
            log "ERROR" "Errors during backup: $(cat /tmp/backup_errors.log)"
        fi
        
        exit 1
    fi
}

# Function to delete old backups
clean_old_backups() {
    if [ "$RETENTION_DAYS" -gt 0 ]; then
        log "INFO" "Cleaning backups older than $RETENTION_DAYS days"
        find "$BACKUP_DIR" -name "system_backup_*.tar.*" -mtime +$RETENTION_DAYS -delete
        
        if [ $? -eq 0 ]; then
            log "INFO" "Old backups cleaned successfully"
        else
            log "WARNING" "Failed to clean old backups"
        fi
    else
        log "INFO" "Backup retention disabled"
    fi
}

# =====================================================================
# MAIN SCRIPT
# =====================================================================

# Load configuration from file if provided
if [ $# -gt 0 ]; then
    load_config "$1"
fi

# Check if running as root
check_root

# Begin backup process
log "INFO" "=== BACKUP STARTED ==="

# Create backup directory if it doesn't exist
create_backup_dir

# Check available disk space
check_disk_space

# Create the backup
create_backup

# Clean old backups
clean_old_backups

log "INFO" "=== BACKUP COMPLETED ==="

exit 0
