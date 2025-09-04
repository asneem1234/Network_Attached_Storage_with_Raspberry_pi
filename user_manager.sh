#!/bin/bash
# User Management Script for Raspberry Pi NAS
# Author: Engineering Clinics Group
# Date: September 2024

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to display help
show_help() {
    echo -e "${YELLOW}Raspberry Pi NAS User Management${NC}"
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  -a, --add     Add a new user"
    echo "  -d, --delete  Delete an existing user"
    echo "  -l, --list    List all users"
    echo "  -h, --help    Show this help message"
    echo ""
}

# Function to add a new user
add_user() {
    echo -e "${YELLOW}Adding a new user${NC}"
    read -p "Enter username: " USERNAME
    
    # Check if user already exists
    if id "$USERNAME" &>/dev/null; then
        echo -e "${RED}Error: User $USERNAME already exists${NC}"
        return 1
    fi
    
    # Add Linux user
    sudo adduser "$USERNAME"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to create Linux user${NC}"
        return 1
    fi
    
    # Add Samba user
    sudo smbpasswd -a "$USERNAME"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to create Samba user${NC}"
        return 1
    fi
    
    # Create user directory
    sudo mkdir -p "/mnt/nasdata/users/$USERNAME"
    sudo chown "$USERNAME":"$USERNAME" "/mnt/nasdata/users/$USERNAME"
    sudo chmod 700 "/mnt/nasdata/users/$USERNAME"
    
    # Add user-specific share to Samba configuration
    cat << EOF | sudo tee -a /etc/samba/smb.conf

[$USERNAME-private]
    comment = $USERNAME's Private Folder
    path = /mnt/nasdata/users/$USERNAME
    browseable = no
    read only = no
    guest ok = no
    valid users = $USERNAME
    create mask = 0600
    directory mask = 0700
EOF
    
    # Restart Samba
    sudo systemctl restart smbd
    sudo systemctl restart nmbd
    
    echo -e "${GREEN}User $USERNAME successfully added!${NC}"
}

# Function to delete a user
delete_user() {
    echo -e "${YELLOW}Deleting a user${NC}"
    read -p "Enter username to delete: " USERNAME
    
    # Check if user exists
    if ! id "$USERNAME" &>/dev/null; then
        echo -e "${RED}Error: User $USERNAME does not exist${NC}"
        return 1
    fi
    
    # Confirm deletion
    read -p "Are you sure you want to delete $USERNAME? (y/n): " CONFIRM
    if [ "$CONFIRM" != "y" ]; then
        echo "Operation cancelled"
        return 0
    fi
    
    # Remove Samba user
    sudo smbpasswd -x "$USERNAME"
    
    # Remove user directory backup option
    echo -e "${YELLOW}Do you want to:${NC}"
    echo "1. Keep user data"
    echo "2. Backup user data"
    echo "3. Delete user data permanently"
    read -p "Select option (1/2/3): " DATA_OPTION
    
    case $DATA_OPTION in
        1)
            echo "Keeping user data in place"
            ;;
        2)
            echo "Backing up user data..."
            BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
            sudo mv "/mnt/nasdata/users/$USERNAME" "/mnt/nasdata/backups/user_$USERNAME-$BACKUP_DATE"
            echo "Backed up to /mnt/nasdata/backups/user_$USERNAME-$BACKUP_DATE"
            ;;
        3)
            echo "Deleting user data permanently..."
            sudo rm -rf "/mnt/nasdata/users/$USERNAME"
            ;;
        *)
            echo "Invalid option. Keeping user data in place."
            ;;
    esac
    
    # Remove Linux user
    sudo deluser --remove-home "$USERNAME"
    
    # Remove user share from Samba configuration
    sudo sed -i "/\[$USERNAME-private\]/,/directory mask = 0700/d" /etc/samba/smb.conf
    
    # Restart Samba
    sudo systemctl restart smbd
    sudo systemctl restart nmbd
    
    echo -e "${GREEN}User $USERNAME successfully deleted!${NC}"
}

# Function to list users
list_users() {
    echo -e "${YELLOW}List of Users:${NC}"
    echo -e "${GREEN}Linux Users:${NC}"
    getent passwd | grep -E "/home" | cut -d: -f1
    
    echo -e "\n${GREEN}Samba Users:${NC}"
    sudo pdbedit -L | cut -d: -f1
}

# Check if script is run with arguments
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

# Parse arguments
case "$1" in
    -a|--add)
        add_user
        ;;
    -d|--delete)
        delete_user
        ;;
    -l|--list)
        list_users
        ;;
    -h|--help|*)
        show_help
        ;;
esac
