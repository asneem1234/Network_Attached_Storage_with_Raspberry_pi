#!/bin/bash
# Raspberry Pi NAS Master Installation Script
# Author: Engineering Clinics Group
# Date: September 2024

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Clear screen
clear

# Display ASCII art banner
cat << "EOF"
 _____                 _                            _____ _   _____  _____ 
|  __ \               | |                          |  __ (_) |  __ \|  _  |
| |__) |__ _ ___ _ __ | |__   ___ _ __ _ __ _   _ | |__) |  | |  \/| |_| |
|  _  // _` / __| '_ \| '_ \ / _ \ '__| '__| | | ||  ___/|  | | __ \____ |
| | \ \ (_| \__ \ |_) | |_) |  __/ |  | |  | |_| || |   _|  | |_\ \___| |
|_|  \_\__,_|___/ .__/|_.__/ \___|_|  |_|   \__, ||_|  (_)   \____/\_____|
                | |                          __/ |                         
                |_|                         |___/                          
 _   _          _______                     _____                      
| \ | |        | | ___ \                   /  ___|                     
|  \| | ___  __| | |_/ /_   _  __ _ _ __  \ `--.  ___ _ ____   _____ 
| . ` |/ _ \/ _` |    /| | | |/ _` | '__|  `--. \/ _ \ '__\ \ / / _ \
| |\  |  __/ (_| | |\ \| |_| | (_| | |    /\__/ /  __/ |   \ V /  __/
\_| \_/\___|\__,_\_| \_|\__, |\__,_|_|    \____/ \___|_|    \_/ \___|
                         __/ |                                        
                        |___/                                         
EOF

echo -e "${BLUE}=================================================${NC}"
echo -e "${CYAN}Raspberry Pi Network Attached Storage Setup${NC}"
echo -e "${BLUE}=================================================${NC}"
echo -e "${YELLOW}Engineering Clinics Group - September 2024${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root${NC}"
    echo -e "${YELLOW}Please run: sudo bash $(basename "$0")${NC}"
    exit 1
fi

# Function to check script availability
check_scripts() {
    REQUIRED_SCRIPTS=("setup.sh" "network_config.sh" "backup.sh" "monitor.sh" "user_manager.sh" "raid_config.sh" "remote_access.sh" "web_interface.sh" "ai_sorter.sh")
    MISSING_SCRIPTS=()
    
    for script in "${REQUIRED_SCRIPTS[@]}"; do
        if [ ! -f "$script" ]; then
            MISSING_SCRIPTS+=("$script")
        else
            chmod +x "$script"
        fi
    done
    
    if [ ${#MISSING_SCRIPTS[@]} -gt 0 ]; then
        echo -e "${RED}Error: The following required scripts are missing:${NC}"
        for missing in "${MISSING_SCRIPTS[@]}"; do
            echo -e "${YELLOW}  - $missing${NC}"
        done
        echo -e "${YELLOW}Please ensure all required scripts are in the same directory as this master script.${NC}"
        exit 1
    fi
}

# Function to check system requirements
check_system() {
    echo -e "${BLUE}Checking system requirements...${NC}"
    
    # Check if running on Raspberry Pi
    if ! grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
        echo -e "${YELLOW}Warning: This does not appear to be a Raspberry Pi.${NC}"
        read -p "Continue anyway? (y/n): " CONTINUE
        if [ "$CONTINUE" != "y" ]; then
            exit 1
        fi
    else
        MODEL=$(tr -d '\0' < /proc/device-tree/model)
        echo -e "${GREEN}Detected: $MODEL${NC}"
    fi
    
    # Check memory
    MEM_TOTAL=$(free -m | awk '/^Mem:/ {print $2}')
    echo -e "${BLUE}Memory: ${MEM_TOTAL}MB${NC}"
    
    if [ "$MEM_TOTAL" -lt 1024 ]; then
        echo -e "${YELLOW}Warning: Less than 1GB RAM detected. Performance may be limited.${NC}"
    fi
    
    # Check disk space
    ROOT_SPACE=$(df -h / | awk 'NR==2 {print $4}')
    echo -e "${BLUE}Available root space: ${ROOT_SPACE}${NC}"
    
    # Check network
    echo -e "${BLUE}Network interfaces:${NC}"
    ip -br addr show
    
    echo -e "${GREEN}System check completed.${NC}"
}

# Function to collect initial configuration
collect_configuration() {
    echo -e "${BLUE}Collecting initial configuration...${NC}"
    
    # Set hostname
    read -p "Enter hostname for your NAS [raspberrypi-nas]: " NAS_HOSTNAME
    NAS_HOSTNAME=${NAS_HOSTNAME:-raspberrypi-nas}
    
    # Confirm configuration
    echo -e "${YELLOW}Configuration Summary:${NC}"
    echo -e "  Hostname: ${CYAN}$NAS_HOSTNAME${NC}"
    
    read -p "Is this correct? (y/n): " CONFIRM
    if [ "$CONFIRM" != "y" ]; then
        echo -e "${YELLOW}Configuration canceled. Please run the script again.${NC}"
        exit 1
    fi
    
    # Apply hostname
    echo "$NAS_HOSTNAME" > /etc/hostname
    sed -i "s/127.0.1.1.*/127.0.1.1\t$NAS_HOSTNAME/" /etc/hosts
    
    echo -e "${GREEN}Configuration saved.${NC}"
}

# Main installation menu
main_menu() {
    while true; do
        echo -e "${BLUE}\nRaspberry Pi NAS Setup Menu:${NC}"
        echo -e "${CYAN}1: Basic NAS Setup${NC} (Storage & Samba)"
        echo -e "${CYAN}2: Network Configuration${NC} (Static IP)"
        echo -e "${CYAN}3: User Management${NC}"
        echo -e "${CYAN}4: RAID Configuration${NC}"
        echo -e "${CYAN}5: Remote Access Setup${NC}"
        echo -e "${CYAN}6: Web Interface Installation${NC}"
        echo -e "${CYAN}7: Setup Backup System${NC}"
        echo -e "${CYAN}8: System Monitoring${NC}"
        echo -e "${CYAN}9: AI File Sorting${NC}"
        echo -e "${CYAN}10: Exit${NC}"
        read -p "Select option (1-9): " OPTION
        
        case $OPTION in
            1)
                ./setup.sh
                ;;
            2)
                ./network_config.sh
                ;;
            3)
                ./user_manager.sh
                ;;
            4)
                ./raid_config.sh
                ;;
            5)
                ./remote_access.sh
                ;;
            6)
                ./web_interface.sh
                ;;
            7)
                ./backup.sh
                ;;
            8)
                ./monitor.sh
                ;;
            9)
                ./ai_sorter.sh
                ;;
            10)
                echo -e "${GREEN}Thank you for using the Raspberry Pi NAS Setup!${NC}"
                echo -e "${YELLOW}Engineering Clinics Group - September 2024${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please select 1-9.${NC}"
                ;;
        esac
    done
}

# Run functions
check_scripts
check_system
collect_configuration
main_menu
