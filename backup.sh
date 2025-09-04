#!/bin/bash
# Automated backup script for Raspberry Pi NAS
# Author: Engineering Clinics Group
# Date: September 2024

# Configuration
BACKUP_SOURCE="/mnt/nasdata"
BACKUP_DEST="/mnt/backup"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/var/log/nas_backup.log"

# Create backup destination if it doesn't exist
if [ ! -d "$BACKUP_DEST" ]; then
    mkdir -p "$BACKUP_DEST/current"
    echo "Created backup destination directory: $BACKUP_DEST"
fi

# Check if backup destination is mounted
if ! mountpoint -q "$BACKUP_DEST"; then
    echo "ERROR: Backup destination is not mounted. Please mount an external drive to $BACKUP_DEST" | tee -a "$LOG_FILE"
    exit 1
fi

# Check if source is available
if [ ! -d "$BACKUP_SOURCE" ]; then
    echo "ERROR: Backup source directory does not exist: $BACKUP_SOURCE" | tee -a "$LOG_FILE"
    exit 1
fi

echo "Starting backup at $(date)" | tee -a "$LOG_FILE"

# Create incremental backup
rsync -av --delete --backup --backup-dir="$BACKUP_DEST/incremental_$DATE" \
    "$BACKUP_SOURCE/" "$BACKUP_DEST/current/" | tee -a "$LOG_FILE"

# Check backup status
if [ $? -eq 0 ]; then
    echo "Backup completed successfully at $(date)" | tee -a "$LOG_FILE"
else
    echo "Backup failed at $(date)" | tee -a "$LOG_FILE"
fi

# Clean up old backups (keep last 7 days)
echo "Cleaning old backups..." | tee -a "$LOG_FILE"
find "$BACKUP_DEST" -name "incremental_*" -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null

# Print disk usage
echo "Current disk usage:" | tee -a "$LOG_FILE"
df -h "$BACKUP_DEST" | tee -a "$LOG_FILE"
