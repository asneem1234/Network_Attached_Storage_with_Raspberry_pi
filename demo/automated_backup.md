# Automated Backup Solution Setup

This guide will walk you through setting up the Raspberry Pi NAS as a comprehensive automated backup solution for multiple devices in a home or small office environment.

## Overview

The Automated Backup Solution demo showcases how individuals and families can protect their important data across multiple devices without recurring subscription costs or complex enterprise solutions.

## Prerequisites

- Raspberry Pi NAS with Samba configured
- External storage with sufficient capacity (recommend 2TB+)
- Multiple client devices (Windows, macOS, or Linux computers)
- Sample data to back up

## Setup Instructions

### 1. Create Backup Structure

First, create a well-organized backup directory structure:

```bash
# Log in to your Raspberry Pi NAS
ssh pi@<NAS-IP-ADDRESS>

# Create the backup directory structure
sudo mkdir -p /mnt/nasdata/backups/{daily,weekly,monthly,devices}
sudo mkdir -p /mnt/nasdata/backups/devices/{laptop1,laptop2,desktop,phone}
sudo chmod -R 755 /mnt/nasdata/backups
sudo chown -R pi:pi /mnt/nasdata/backups
```

### 2. Configure the Backup Server

Set up the main backup script on the NAS:

```bash
# Create the backup script
cat << 'EOF' > /home/pi/backup_manager.sh
#!/bin/bash

# Configuration
BACKUP_ROOT="/mnt/nasdata/backups"
LOG_FILE="/var/log/nas_backup.log"
DATE=$(date +%Y%m%d)
DAY_OF_WEEK=$(date +%u)
DAY_OF_MONTH=$(date +%d)

# Log function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Check backup destination
if [ ! -d "$BACKUP_ROOT" ]; then
    log_message "ERROR: Backup destination $BACKUP_ROOT not found"
    exit 1
fi

# Daily backup rotation (keep 7 days)
log_message "Starting daily backup rotation"
mkdir -p "$BACKUP_ROOT/daily/$DATE"
find "$BACKUP_ROOT/daily/" -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null

# Weekly backup (keep 4 weeks)
if [ "$DAY_OF_WEEK" = "7" ]; then
    log_message "Starting weekly backup rotation"
    WEEK=$(date +%Y-week%V)
    mkdir -p "$BACKUP_ROOT/weekly/$WEEK"
    rsync -a "$BACKUP_ROOT/daily/$DATE/" "$BACKUP_ROOT/weekly/$WEEK/"
    find "$BACKUP_ROOT/weekly/" -type d -mtime +28 -exec rm -rf {} \; 2>/dev/null
fi

# Monthly backup (keep 12 months)
if [ "$DAY_OF_MONTH" = "01" ]; then
    log_message "Starting monthly backup rotation"
    MONTH=$(date +%Y-%m)
    mkdir -p "$BACKUP_ROOT/monthly/$MONTH"
    rsync -a "$BACKUP_ROOT/daily/$DATE/" "$BACKUP_ROOT/monthly/$MONTH/"
    find "$BACKUP_ROOT/monthly/" -type d -mtime +365 -exec rm -rf {} \; 2>/dev/null
fi

# Process incoming device backups
log_message "Processing device backups"
for DEVICE in laptop1 laptop2 desktop phone; do
    if [ -d "$BACKUP_ROOT/devices/$DEVICE/incoming" ]; then
        if [ "$(ls -A $BACKUP_ROOT/devices/$DEVICE/incoming)" ]; then
            log_message "Processing backup for $DEVICE"
            mkdir -p "$BACKUP_ROOT/daily/$DATE/$DEVICE"
            rsync -a "$BACKUP_ROOT/devices/$DEVICE/incoming/" "$BACKUP_ROOT/daily/$DATE/$DEVICE/"
            log_message "Backup for $DEVICE completed"
        fi
    fi
done

log_message "Backup rotation completed"
EOF

# Make the script executable
chmod +x /home/pi/backup_manager.sh

# Schedule with cron to run daily at 2 AM
(crontab -l 2>/dev/null; echo "0 2 * * * /home/pi/backup_manager.sh") | crontab -
```

### 3. Configure Windows Client Backup

1. Create a batch script for Windows clients:

```batch
@echo off
echo Starting backup to NAS at %TIME% on %DATE%

REM Configuration
set NAS_IP=<NAS-IP-ADDRESS>
set BACKUP_USER=backup
set BACKUP_SOURCE=C:\Users\%USERNAME%\Documents
set DEVICE_NAME=laptop1
set LOG_FILE=%USERPROFILE%\nas_backup_log.txt

REM Map network drive
net use Z: \\%NAS_IP%\backups /user:%BACKUP_USER% <PASSWORD>

REM Create incoming folder if it doesn't exist
if not exist Z:\devices\%DEVICE_NAME%\incoming mkdir Z:\devices\%DEVICE_NAME%\incoming

REM Run the backup using robocopy (Microsoft's robust file copy)
robocopy "%BACKUP_SOURCE%" "Z:\devices\%DEVICE_NAME%\incoming" /MIR /FFT /Z /XA:H /W:5 /R:2 /LOG+:%LOG_FILE%

REM Disconnect drive
net use Z: /delete

echo Backup completed at %TIME% on %DATE%
```

2. Save this as `backup_to_nas.bat` on the Windows client
3. Schedule it using Windows Task Scheduler:
   - Open Task Scheduler
   - Create Basic Task
   - Name it "Backup to NAS"
   - Set trigger (daily, when computer is idle)
   - Select "Start a program"
   - Browse to your batch file
   - Finish the wizard

### 4. Configure macOS Client Backup

1. Create a shell script for macOS clients:

```bash
#!/bin/bash

# Configuration
NAS_IP="<NAS-IP-ADDRESS>"
BACKUP_USER="backup"
BACKUP_PASSWORD="<PASSWORD>"
BACKUP_SOURCE="$HOME/Documents"
DEVICE_NAME="laptop2"
LOG_FILE="$HOME/Library/Logs/nas_backup.log"

# Log function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Create mount point if it doesn't exist
MOUNT_POINT="/Volumes/NASBackup"
if [ ! -d "$MOUNT_POINT" ]; then
    mkdir -p "$MOUNT_POINT"
fi

# Mount NAS share
log_message "Mounting NAS backup share"
mount_smbfs //backup:${BACKUP_PASSWORD}@${NAS_IP}/backups "$MOUNT_POINT"

if [ $? -ne 0 ]; then
    log_message "Failed to mount NAS share"
    exit 1
fi

# Create incoming folder if it doesn't exist
if [ ! -d "$MOUNT_POINT/devices/$DEVICE_NAME/incoming" ]; then
    mkdir -p "$MOUNT_POINT/devices/$DEVICE_NAME/incoming"
fi

# Run backup using rsync
log_message "Starting backup"
rsync -avz --delete --exclude ".DS_Store" --exclude "*.tmp" \
    "$BACKUP_SOURCE/" \
    "$MOUNT_POINT/devices/$DEVICE_NAME/incoming/" \
    >> "$LOG_FILE" 2>&1

# Unmount share
log_message "Backup complete, unmounting share"
umount "$MOUNT_POINT"
```

2. Save this as `backup_to_nas.sh` and make it executable:
   ```bash
   chmod +x backup_to_nas.sh
   ```

3. Schedule with cron:
   ```bash
   crontab -e
   # Add the following line to run daily at 3 AM:
   0 3 * * * /path/to/backup_to_nas.sh
   ```

### 5. Configure Linux Client Backup

1. Create a shell script for Linux clients:

```bash
#!/bin/bash

# Configuration
NAS_IP="<NAS-IP-ADDRESS>"
BACKUP_USER="backup"
BACKUP_PASSWORD="<PASSWORD>"
BACKUP_SOURCE="$HOME/Documents"
DEVICE_NAME="desktop"
LOG_FILE="$HOME/nas_backup.log"

# Log function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Create mount point if it doesn't exist
MOUNT_POINT="/mnt/nasbackup"
if [ ! -d "$MOUNT_POINT" ]; then
    sudo mkdir -p "$MOUNT_POINT"
fi

# Mount NAS share
log_message "Mounting NAS backup share"
sudo mount -t cifs //$NAS_IP/backups "$MOUNT_POINT" -o username=$BACKUP_USER,password=$BACKUP_PASSWORD,uid=$(id -u),gid=$(id -g)

if [ $? -ne 0 ]; then
    log_message "Failed to mount NAS share"
    exit 1
fi

# Create incoming folder if it doesn't exist
if [ ! -d "$MOUNT_POINT/devices/$DEVICE_NAME/incoming" ]; then
    mkdir -p "$MOUNT_POINT/devices/$DEVICE_NAME/incoming"
fi

# Run backup using rsync
log_message "Starting backup"
rsync -avz --delete --exclude ".*" --exclude "*.tmp" \
    "$BACKUP_SOURCE/" \
    "$MOUNT_POINT/devices/$DEVICE_NAME/incoming/" \
    >> "$LOG_FILE" 2>&1

# Unmount share
log_message "Backup complete, unmounting share"
sudo umount "$MOUNT_POINT"
```

2. Save this as `backup_to_nas.sh` and make it executable:
   ```bash
   chmod +x backup_to_nas.sh
   ```

3. Schedule with cron:
   ```bash
   crontab -e
   # Add the following line to run daily at 3 AM:
   0 3 * * * /path/to/backup_to_nas.sh
   ```

### 6. Mobile Device Backup (Android Example)

For Android devices:

1. Install an app like "FolderSync"
2. Configure a connection to your NAS using SMB/CIFS
3. Set up automated sync profiles for important folders
4. Configure to run on schedule and/or when connected to home WiFi

## Demo Preparation

1. Set up demo devices with the backup scripts
2. Create sample files to back up
3. Prepare a scenario to show file restoration (accidentally deleted file)
4. Set up a visualization of the backup structure

## Backup Verification and Testing

Create a verification script to check backup integrity:

```bash
#!/bin/bash
# backup_verify.sh

LOG_FILE="/var/log/backup_verify.log"
BACKUP_ROOT="/mnt/nasdata/backups"
DATE=$(date +%Y%m%d)

echo "===== Backup Verification: $(date) =====" >> "$LOG_FILE"

# Check if daily backup exists
if [ ! -d "$BACKUP_ROOT/daily/$DATE" ]; then
    echo "ERROR: Today's daily backup not found!" >> "$LOG_FILE"
else
    echo "Daily backup for $DATE found" >> "$LOG_FILE"
    
    # Check backup sizes
    echo "Backup sizes:" >> "$LOG_FILE"
    du -sh "$BACKUP_ROOT/daily/$DATE"/* >> "$LOG_FILE"
    
    # Check most recent files
    echo "Most recent files:" >> "$LOG_FILE"
    find "$BACKUP_ROOT/daily/$DATE" -type f -mtime -1 -exec ls -la {} \; | head -10 >> "$LOG_FILE"
fi

# Check backup disk space
echo "Backup disk space:" >> "$LOG_FILE"
df -h "$BACKUP_ROOT" >> "$LOG_FILE"

echo "===== Verification Complete =====" >> "$LOG_FILE"
```

## Restoration Process

Create a simple restore script for demo purposes:

```bash
#!/bin/bash
# restore_file.sh

if [ $# -lt 3 ]; then
    echo "Usage: $0 <device> <backup_date> <file_path>"
    echo "Example: $0 laptop1 20240903 Documents/important.docx"
    exit 1
fi

DEVICE=$1
BACKUP_DATE=$2
FILE_PATH=$3
BACKUP_ROOT="/mnt/nasdata/backups"
RESTORE_DIR="/mnt/nasdata/restore"

# Create restore directory
mkdir -p "$RESTORE_DIR"

# Find the file in backups
BACKUP_FILE="$BACKUP_ROOT/daily/$BACKUP_DATE/$DEVICE/incoming/$FILE_PATH"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "File not found in backup!"
    exit 1
fi

# Copy file to restore directory
cp "$BACKUP_FILE" "$RESTORE_DIR/"

echo "File restored to: $RESTORE_DIR/$(basename "$FILE_PATH")"
```

## Cost Savings Analysis

| Solution | Initial Cost | Annual Cost | 5-Year Total |
|----------|--------------|-------------|--------------|
| Raspberry Pi NAS | ₹5,820 | ₹0 | ₹5,820 |
| Cloud Backup (3 devices) | ₹0 | ₹3,600 | ₹18,000 |
| External Drives (3x1TB) | ₹12,000 | ₹0 | ₹12,000 |
| **Savings vs. Cloud** | | | **₹12,180** |
| **Savings vs. Ext. Drives** | | | **₹6,180** |

## Advantages to Highlight

1. **Centralized Management**: All backups in one place
2. **Incremental Backups**: Save space and bandwidth
3. **Automated Scheduling**: "Set and forget" reliability
4. **Versioning**: Recover previous versions of files
5. **No Size Limits**: Unlike many cloud services
6. **No Monthly Fees**: One-time investment
7. **Privacy Control**: Data never leaves your network
8. **Faster Restoration**: No need to download from cloud

## Troubleshooting

- **Mount Failures**: Check network connectivity and credentials
- **Permission Issues**: Verify user permissions on NAS and client
- **Slow Backups**: Consider running during off-hours or optimizing network
- **Backup Size Problems**: Use exclusion patterns for temp files and caches
