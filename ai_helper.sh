#!/bin/bash
# AI File Sorting Helper Script
# Author: Engineering Clinics Group
# Date: September 2024

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to check AI sorter status
check_status() {
    echo -e "${BLUE}Checking AI File Sorting Service Status...${NC}"
    if systemctl is-active --quiet file_sorter; then
        echo -e "${GREEN}AI File Sorting Service is running.${NC}"
        echo -e "${CYAN}Service details:${NC}"
        systemctl status file_sorter | grep -E "Active:|Memory:|Tasks:"
    else
        echo -e "${RED}AI File Sorting Service is not running.${NC}"
    fi
}

# Function to view AI sorter logs
view_logs() {
    echo -e "${BLUE}Recent AI File Sorting Logs:${NC}"
    if [ -f /var/log/file_sorter.log ]; then
        tail -n 20 /var/log/file_sorter.log
    else
        echo -e "${RED}Log file not found.${NC}"
    fi
}

# Function to display sorting statistics
show_stats() {
    echo -e "${BLUE}File Sorting Statistics:${NC}"
    
    # Count files in each category
    echo -e "${CYAN}Files by category:${NC}"
    for dir in /mnt/nasdata/{documents,images,videos,audio,archives,code,others}; do
        if [ -d "$dir" ]; then
            count=$(find "$dir" -type f | wc -l)
            name=$(basename "$dir")
            echo -e "  ${YELLOW}$name:${NC} $count files"
        fi
    done
    
    # Show disk usage
    echo -e "\n${CYAN}Storage usage:${NC}"
    df -h /mnt/nasdata | tail -n 1
    
    # Count recent files
    echo -e "\n${CYAN}Recently processed files:${NC}"
    recent=$(grep "Moved" /var/log/file_sorter.log | tail -n 5)
    if [ -z "$recent" ]; then
        echo "  No recent activity found."
    else
        echo "$recent"
    fi
}

# Function to restart AI sorter
restart_service() {
    echo -e "${BLUE}Restarting AI File Sorting Service...${NC}"
    systemctl restart file_sorter
    if systemctl is-active --quiet file_sorter; then
        echo -e "${GREEN}Service successfully restarted.${NC}"
    else
        echo -e "${RED}Failed to restart service.${NC}"
    fi
}

# Main menu
show_menu() {
    echo -e "${BLUE}\nAI File Sorting Helper:${NC}"
    echo -e "${CYAN}1: Check Service Status${NC}"
    echo -e "${CYAN}2: View Recent Logs${NC}"
    echo -e "${CYAN}3: Show Statistics${NC}"
    echo -e "${CYAN}4: Restart Service${NC}"
    echo -e "${CYAN}5: Exit${NC}"
    
    read -p "Select option (1-5): " OPTION
    
    case $OPTION in
        1)
            check_status
            ;;
        2)
            view_logs
            ;;
        3)
            show_stats
            ;;
        4)
            restart_service
            ;;
        5)
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option.${NC}"
            ;;
    esac
}

# Main loop
while true; do
    show_menu
    echo -e "\n"
    read -p "Press Enter to continue..."
done
