# Intelligent Business File Management Setup

This guide will walk you through setting up the Raspberry Pi Smart NAS with AI file sorting capabilities as a centralized intelligent file server for a small business or team environment.

## Overview

The Intelligent Business File Management demo showcases how a team can securely share, automatically organize, collaborate, and back up business files using our cost-effective Smart NAS solution with AI capabilities. The system intelligently categorizes business documents, automatically detects document types, and organizes files based on content analysis - eliminating manual filing and reducing administrative overhead.

## Prerequisites

- Raspberry Pi NAS with Samba configured
- External storage with at least 1TB capacity
- 2-5 client devices (computers/laptops)
- Sample business files (documents, spreadsheets, design files, etc.)

## Setup Instructions

### 1. User and Permission Structure

First, plan your user and permission structure:

| User Group | Permission Level | Access Areas |
|------------|------------------|--------------|
| Management | Read/Write All | All folders |
| Design Team | Read/Write Design | Design folder, Shared folder |
| Marketing | Read/Write Marketing | Marketing folder, Shared folder |
| Contractors | Read/Write Limited | Projects folder, Shared folder |
| Everyone | Read Only | Public folder |

### 2. Create User Accounts

Use the `user_manager.sh` script to create accounts for each team member:

```bash
# Log in to your Raspberry Pi NAS
ssh pi@<NAS-IP-ADDRESS>

# Create users with the user management script
sudo ./user_manager.sh --add
# Follow the prompts to create each user account
```

### 3. Configure AI-Powered Business Directory Structure

Set up an intelligent file system that automatically categorizes business documents:

```bash
# Create the main directory structure
sudo mkdir -p /mnt/nasdata/business/{management,design,marketing,projects,shared,public,incoming}

# Set up AI sorting for business documents
sudo cp /opt/nasai/scripts/file_sorter.py /opt/nasai/scripts/business_sorter.py

# Customize the AI sorter for business documents
sudo nano /opt/nasai/scripts/business_sorter.py
```

Modify the configuration section of the business_sorter.py file:

```python
# Configuration for business document sorting
WATCH_DIRECTORY = "/mnt/nasdata/business/incoming"
OUTPUT_BASE = "/mnt/nasdata/business"

# Define business document categories
BUSINESS_CATEGORIES = {
    'invoices': ['invoice', 'receipt', 'payment', 'bill'],
    'contracts': ['contract', 'agreement', 'legal', 'terms'],
    'marketing': ['marketing', 'campaign', 'advertisement', 'promotion'],
    'design': ['design', 'graphic', 'mockup', 'sketch', 'logo'],
    'reports': ['report', 'analysis', 'metrics', 'performance'],
    'presentations': ['presentation', 'slides', 'deck'],
    'spreadsheets': ['.xlsx', '.xls', '.csv', '.numbers'],
    'others': []  # Default category
}

# Add document classification function
def classify_business_document(file_path, content_text):
    """Classify business documents based on content"""
    lower_text = content_text.lower()
    
    for category, keywords in BUSINESS_CATEGORIES.items():
        for keyword in keywords:
            if keyword in lower_text:
                return category
    
    # Fall back to file extension classification if content analysis fails
    return classify_by_extension(file_path)
```

Create a service for the business document sorter:

```bash
# Create a service for the business document sorter
sudo bash -c 'cat > /etc/systemd/system/business_sorter.service << EOF
[Unit]
Description=AI Business Document Sorting Service
After=network.target smbd.service

[Service]
ExecStart=/opt/nasai/env/bin/python3 /opt/nasai/scripts/business_sorter.py
Restart=always
User=root
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF'

# Enable and start the service
sudo systemctl enable business_sorter
sudo systemctl start business_sorter

# Set base permissions
sudo chmod 755 /mnt/nasdata/business
sudo chmod 770 /mnt/nasdata/business/management
sudo chmod 770 /mnt/nasdata/business/design
sudo chmod 770 /mnt/nasdata/business/marketing
sudo chmod 770 /mnt/nasdata/business/projects
sudo chmod 775 /mnt/nasdata/business/shared
sudo chmod 755 /mnt/nasdata/business/public
```

### 4. Set Up Group Permissions

Create and configure groups for better permission management:

```bash
# Create user groups
sudo groupadd management
sudo groupadd design
sudo groupadd marketing
sudo groupadd contractors

# Assign directory ownership
sudo chown root:management /mnt/nasdata/business/management
sudo chown root:design /mnt/nasdata/business/design
sudo chown root:marketing /mnt/nasdata/business/marketing
sudo chown root:contractors /mnt/nasdata/business/projects

# Assign users to groups
sudo usermod -aG management john
sudo usermod -aG design sarah
sudo usermod -aG marketing mike
sudo usermod -aG contractors external1
```

### 5. Configure Samba Shares

Edit the Samba configuration to add business shares:

```bash
# Back up the current configuration
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.backup

# Edit the Samba configuration
sudo nano /etc/samba/smb.conf
```

Add these share configurations:

```
[business]
   comment = Business Root
   path = /mnt/nasdata/business
   browseable = yes
   read only = no
   valid users = @management @design @marketing @contractors
   create mask = 0660
   directory mask = 0770
   force group = management

[design]
   comment = Design Team Files
   path = /mnt/nasdata/business/design
   browseable = yes
   read only = no
   valid users = @management @design
   create mask = 0660
   directory mask = 0770
   force group = design

[marketing]
   comment = Marketing Team Files
   path = /mnt/nasdata/business/marketing
   browseable = yes
   read only = no
   valid users = @management @marketing
   create mask = 0660
   directory mask = 0770
   force group = marketing

[projects]
   comment = Project Files
   path = /mnt/nasdata/business/projects
   browseable = yes
   read only = no
   valid users = @management @design @marketing @contractors
   create mask = 0660
   directory mask = 0770

[public]
   comment = Public Files
   path = /mnt/nasdata/business/public
   browseable = yes
   read only = yes
   guest ok = yes
```

Restart Samba to apply changes:

```bash
sudo systemctl restart smbd
sudo systemctl restart nmbd
```

### 6. Client Access Configuration

#### Windows Client Setup:

1. Open File Explorer
2. Right-click on "This PC" and select "Map network drive"
3. Enter `\\<NAS-IP-ADDRESS>\business` (or specific share)
4. Check "Connect using different credentials"
5. Enter username and password when prompted
6. Check "Remember my credentials" for convenience

#### macOS Client Setup:

1. In Finder, press Cmd+K
2. Enter `smb://<NAS-IP-ADDRESS>/business` (or specific share)
3. Click "Connect"
4. Select "Registered User"
5. Enter username and password
6. Add to Favorites for easy access

#### Linux Client Setup:

1. Install CIFS utilities:
   ```bash
   sudo apt install cifs-utils
   ```

2. Create a mount point:
   ```bash
   sudo mkdir /mnt/business
   ```

3. Create credentials file:
   ```bash
   echo "username=yourusername" > ~/.smbcredentials
   echo "password=yourpassword" >> ~/.smbcredentials
   chmod 600 ~/.smbcredentials
   ```

4. Mount the share:
   ```bash
   sudo mount -t cifs //<NAS-IP-ADDRESS>/business /mnt/business -o credentials=~/.smbcredentials,uid=$(id -u),gid=$(id -g)
   ```

5. For automatic mounting, add to `/etc/fstab`:
   ```
   //<NAS-IP-ADDRESS>/business /mnt/business cifs credentials=/home/username/.smbcredentials,uid=1000,gid=1000 0 0
   ```

### 7. File Version Control (Optional)

For simple version control, set up automatic file versioning:

```bash
# Create a versions folder
sudo mkdir -p /mnt/nasdata/business/versions

# Create a backup script
cat << 'EOF' > /home/pi/business_versions.sh
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
rsync -av --delete --backup --backup-dir="/mnt/nasdata/business/versions/$DATE" \
    /mnt/nasdata/business/ /mnt/nasdata/business_current/
EOF

# Make the script executable
chmod +x /home/pi/business_versions.sh

# Add a cron job to run daily
(crontab -l 2>/dev/null; echo "0 20 * * * /home/pi/business_versions.sh") | crontab -
```

## Demo Preparation

1. Create sample business files in each directory
2. Set up user accounts for the demo
3. Prepare a laptop with the necessary client configuration
4. Create a cost comparison chart with cloud alternatives

## Performance Considerations

- Enable jumbo frames on your network if supported (MTU 9000)
- Use wired connections for better performance
- Configure SMB protocol version for best compatibility and security:
  ```
  # Add to global section in smb.conf
  server min protocol = SMB2
  server max protocol = SMB3
  ```

## Security Enhancements

For sensitive business data, consider these security enhancements:

1. Enable encrypted connections:
   ```
   # Add to global section in smb.conf
   smb encrypt = required
   ```

2. Set up fail2ban to prevent brute force attacks
3. Configure regular security audits
4. Implement a secure password policy

## Cost Savings Analysis

| Solution | Initial Cost | Monthly Cost | 5-Year Total Cost |
|----------|--------------|--------------|-------------------|
| Cloud Storage (5 users) | ₹0 | ₹5,000 | ₹300,000 |
| Commercial NAS | ₹25,000 | ₹0 | ₹25,000 |
| Raspberry Pi NAS | ₹5,820 | ₹0 | ₹5,820 |
| **Savings vs. Cloud** | | | **₹294,180** |
| **Savings vs. Commercial NAS** | | | **₹19,180** |

## Troubleshooting

- **Access Denied**: Verify user group memberships and folder permissions
- **Slow Performance**: Check network configuration and Samba optimization settings
- **Connection Issues**: Verify firewall settings and network configuration
- **File Locks**: Check for open files preventing access
