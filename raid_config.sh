#!/bin/bash
# RAID Configuration Script for Raspberry Pi NAS
# Author: Engineering Clinics Group
# Date: September 2024

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=================================${NC}"
echo -e "${BLUE}Raspberry Pi NAS RAID Configuration${NC}"
echo -e "${BLUE}=================================${NC}"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root${NC}"
    exit 1
fi

# Install mdadm if not already installed
if ! command -v mdadm &> /dev/null; then
    echo -e "${YELLOW}Installing mdadm for RAID management...${NC}"
    apt update
    apt install -y mdadm
fi

# Function to list available drives
list_drives() {
    echo -e "${YELLOW}Available Drives:${NC}"
    echo -e "${GREEN}$(lsblk -d -o NAME,SIZE,MODEL,SERIAL)${NC}"
    echo ""
}

# Function to create RAID array
create_raid() {
    echo -e "${YELLOW}RAID Level Options:${NC}"
    echo "1: RAID 0 (Striping - Improved performance, NO redundancy)"
    echo "2: RAID 1 (Mirroring - Full redundancy, uses 50% of space)"
    echo "5: RAID 5 (Striping with parity - Redundancy with better space efficiency)"
    echo "10: RAID 10 (Mirroring and Striping - Good performance and redundancy)"
    read -p "Select RAID level (1/2/5/10): " RAID_LEVEL
    
    case $RAID_LEVEL in
        1)
            RAID_LEVEL=0
            MIN_DRIVES=2
            ;;
        2)
            RAID_LEVEL=1
            MIN_DRIVES=2
            ;;
        5)
            RAID_LEVEL=5
            MIN_DRIVES=3
            ;;
        10)
            RAID_LEVEL=10
            MIN_DRIVES=4
            ;;
        *)
            echo -e "${RED}Invalid RAID level selected${NC}"
            return 1
            ;;
    esac
    
    list_drives
    
    # Get drives for the array
    echo -e "${YELLOW}Enter drive names to include in RAID (without /dev/, e.g., sda sdb sdc)${NC}"
    read -p "Space-separated drive list: " DRIVE_LIST
    
    # Convert to array and check minimum drive count
    DRIVES=($DRIVE_LIST)
    if [ ${#DRIVES[@]} -lt $MIN_DRIVES ]; then
        echo -e "${RED}Error: RAID $RAID_LEVEL requires at least $MIN_DRIVES drives${NC}"
        return 1
    fi
    
    # Confirm drive selection
    echo -e "${RED}WARNING: This will erase ALL data on the following drives:${NC}"
    for DRIVE in "${DRIVES[@]}"; do
        echo -e "  - /dev/$DRIVE"
    done
    read -p "Are you absolutely sure you want to continue? (yes/no): " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo -e "${YELLOW}Operation cancelled${NC}"
        return 1
    fi
    
    # Create the device paths
    DEVICE_PATHS=""
    for DRIVE in "${DRIVES[@]}"; do
        DEVICE_PATHS+=" /dev/$DRIVE"
    done
    
    # Create RAID array
    echo -e "${YELLOW}Creating RAID $RAID_LEVEL array...${NC}"
    mdadm --create --verbose /dev/md0 --level=$RAID_LEVEL --raid-devices=${#DRIVES[@]} $DEVICE_PATHS
    
    # Format the array
    echo -e "${YELLOW}Formatting RAID array with ext4 filesystem...${NC}"
    mkfs.ext4 /dev/md0
    
    # Create mount point
    echo -e "${YELLOW}Creating mount point...${NC}"
    mkdir -p /mnt/raid_storage
    
    # Update fstab for persistent mounting
    echo -e "${YELLOW}Updating /etc/fstab for persistent mounting...${NC}"
    echo "/dev/md0 /mnt/raid_storage ext4 defaults 0 0" >> /etc/fstab
    
    # Save RAID configuration
    echo -e "${YELLOW}Saving RAID configuration...${NC}"
    mdadm --detail --scan >> /etc/mdadm/mdadm.conf
    
    # Update initramfs
    echo -e "${YELLOW}Updating initramfs...${NC}"
    update-initramfs -u
    
    # Mount the array
    echo -e "${YELLOW}Mounting RAID array...${NC}"
    mount /mnt/raid_storage
    
    echo -e "${GREEN}RAID array successfully created and mounted at /mnt/raid_storage${NC}"
    echo -e "${YELLOW}RAID details:${NC}"
    mdadm --detail /dev/md0
}

# Function to check RAID status
check_raid() {
    if [ -e /dev/md0 ]; then
        echo -e "${YELLOW}RAID Status:${NC}"
        mdadm --detail /dev/md0
    else
        echo -e "${RED}No RAID array found${NC}"
    fi
}

# Function to repair RAID array
repair_raid() {
    if [ ! -e /dev/md0 ]; then
        echo -e "${RED}No RAID array found${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}RAID Status Before Repair:${NC}"
    mdadm --detail /dev/md0
    
    list_drives
    
    # Check for failed drives
    FAILED_DRIVES=$(mdadm --detail /dev/md0 | grep "faulty" | wc -l)
    
    if [ "$FAILED_DRIVES" -eq 0 ]; then
        echo -e "${GREEN}No failed drives detected. RAID array is healthy.${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Failed drives detected. Starting repair process...${NC}"
    
    # Get the failed drive
    read -p "Enter the drive to replace (without /dev/, e.g., sdb): " FAILED_DRIVE
    
    # Remove the failed drive
    echo -e "${YELLOW}Removing failed drive /dev/$FAILED_DRIVE from array...${NC}"
    mdadm /dev/md0 --fail /dev/$FAILED_DRIVE --remove /dev/$FAILED_DRIVE
    
    # Add new drive
    read -p "Enter the new drive to add (without /dev/, e.g., sdc): " NEW_DRIVE
    echo -e "${YELLOW}Adding new drive /dev/$NEW_DRIVE to array...${NC}"
    mdadm /dev/md0 --add /dev/$NEW_DRIVE
    
    echo -e "${YELLOW}RAID Status After Repair:${NC}"
    mdadm --detail /dev/md0
    
    echo -e "${GREEN}Repair process initiated. RAID array is rebuilding...${NC}"
    echo -e "${YELLOW}This process may take several hours depending on array size.${NC}"
    echo -e "${YELLOW}Monitor the progress with: cat /proc/mdstat${NC}"
}

# Main menu
while true; do
    echo -e "${BLUE}\nRAID Management Options:${NC}"
    echo "1: List Available Drives"
    echo "2: Create RAID Array"
    echo "3: Check RAID Status"
    echo "4: Repair RAID Array"
    echo "5: Exit"
    read -p "Select option (1-5): " OPTION
    
    case $OPTION in
        1)
            list_drives
            ;;
        2)
            create_raid
            ;;
        3)
            check_raid
            ;;
        4)
            repair_raid
            ;;
        5)
            echo -e "${BLUE}Exiting RAID Configuration Tool${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please select 1-5.${NC}"
            ;;
    esac
done
