#!/bin/bash
# Raspberry Pi NAS Setup Script
# Author: Engineering Clinics Group
# Date: September 2024

echo "Starting Raspberry Pi NAS Setup..."

# Update system
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required packages
echo "Installing Samba and required utilities..."
sudo apt install samba samba-common-bin cifs-utils -y

# Create mount point and directory structure
echo "Creating directory structure..."
sudo mkdir -p /mnt/nasdata/{documents,media,backups,shared,users}

# Detect and mount external drive
echo "Detecting external drives..."
lsblk
echo "Please enter the drive to mount (e.g., sda1):"
read DRIVE_ID

# Mount external drive
echo "Mounting drive /dev/$DRIVE_ID to /mnt/nasdata..."
sudo mkfs.ext4 /dev/$DRIVE_ID
sudo mount /dev/$DRIVE_ID /mnt/nasdata

# Add to fstab for persistent mounting
echo "Configuring automatic mounting..."
echo "/dev/$DRIVE_ID /mnt/nasdata ext4 defaults 0 0" | sudo tee -a /etc/fstab

# Set permissions
echo "Setting permissions..."
sudo chown -R pi:pi /mnt/nasdata
sudo chmod -R 755 /mnt/nasdata

# Configure Samba
echo "Configuring Samba..."
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.backup

# Create Samba user
echo "Setting up Samba user..."
sudo smbpasswd -a pi

# Add Samba configuration
echo "Writing Samba configuration..."
cat > /tmp/smb.conf << 'EOL'
[global]
    workgroup = WORKGROUP
    server string = Raspberry Pi NAS
    security = user
    encrypt passwords = yes
    smb passwd file = /etc/samba/smbpasswd
    socket options = TCP_NODELAY SO_RCVBUF=8192 SO_SNDBUF=8192
    local master = yes
    os level = 33
    domain master = yes
    preferred master = yes
    wins support = yes
    dns proxy = no
    log file = /var/log/samba/log.%m
    max log size = 1000
    syslog = 0

[shared]
    comment = Shared Folder
    path = /mnt/nasdata/shared
    browseable = yes
    read only = no
    guest ok = no
    create mask = 0777
    directory mask = 0777
    valid users = pi

[documents]
    comment = Document Storage
    path = /mnt/nasdata/documents
    browseable = yes
    read only = no
    guest ok = no
    create mask = 0644
    directory mask = 0755
    valid users = pi

[media]
    comment = Media Files
    path = /mnt/nasdata/media
    browseable = yes
    read only = no
    guest ok = no
    create mask = 0644
    directory mask = 0755
    valid users = pi

[backups]
    comment = Backup Storage
    path = /mnt/nasdata/backups
    browseable = yes
    read only = no
    guest ok = no
    create mask = 0600
    directory mask = 0700
    valid users = pi
EOL

sudo cp /tmp/smb.conf /etc/samba/smb.conf

# Test configuration syntax
echo "Testing Samba configuration..."
testparm -s

# Restart services
echo "Restarting Samba services..."
sudo systemctl restart smbd
sudo systemctl enable smbd
sudo systemctl restart nmbd
sudo systemctl enable nmbd

# Configure firewall
echo "Configuring firewall..."
sudo ufw allow ssh
sudo ufw allow samba
sudo ufw --force enable

echo "NAS setup complete! Access via \\\\$(hostname -I | awk '{print $1}')"
