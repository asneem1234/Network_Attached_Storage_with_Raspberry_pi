#!/bin/bash
# System monitoring script for Raspberry Pi NAS
# Author: Engineering Clinics Group
# Date: September 2024

LOG_FILE="/var/log/nas_monitor.log"

echo "===========================================" | tee -a "$LOG_FILE"
echo "NAS System Status Check - $(date)" | tee -a "$LOG_FILE"
echo "===========================================" | tee -a "$LOG_FILE"

# Check disk usage
echo -e "\n### DISK USAGE ###" | tee -a "$LOG_FILE"
df -h /mnt/nasdata | tee -a "$LOG_FILE"

# Check Samba status
echo -e "\n### SAMBA SERVICE STATUS ###" | tee -a "$LOG_FILE"
systemctl status smbd --no-pager | tee -a "$LOG_FILE"

# Monitor network connections
echo -e "\n### ACTIVE SMB CONNECTIONS ###" | tee -a "$LOG_FILE"
echo "User connections:" | tee -a "$LOG_FILE"
smbstatus --brief | tee -a "$LOG_FILE"

echo -e "\n### NETWORK PORTS ###" | tee -a "$LOG_FILE"
netstat -tuln | grep -E ':445|:139' | tee -a "$LOG_FILE"

# Temperature monitoring
echo -e "\n### SYSTEM TEMPERATURE ###" | tee -a "$LOG_FILE"
vcgencmd measure_temp | tee -a "$LOG_FILE"

# CPU Usage
echo -e "\n### CPU USAGE ###" | tee -a "$LOG_FILE"
top -bn1 | head -n 20 | tee -a "$LOG_FILE"

# RAM Usage
echo -e "\n### MEMORY USAGE ###" | tee -a "$LOG_FILE"
free -h | tee -a "$LOG_FILE"

# Check system uptime
echo -e "\n### SYSTEM UPTIME ###" | tee -a "$LOG_FILE"
uptime | tee -a "$LOG_FILE"

# Check AI File Sorter status
echo -e "\n### AI FILE SORTING STATUS ###" | tee -a "$LOG_FILE"
if systemctl is-active --quiet file_sorter; then
    echo "AI File Sorter: ACTIVE" | tee -a "$LOG_FILE"
    systemctl status file_sorter --no-pager | head -n 5 | tee -a "$LOG_FILE"
else
    echo "AI File Sorter: INACTIVE" | tee -a "$LOG_FILE"
fi

# Check recent AI sorting activity
echo -e "\n### RECENT AI SORTING ACTIVITY ###" | tee -a "$LOG_FILE"
if [ -f /var/log/file_sorter.log ]; then
    tail -n 5 /var/log/file_sorter.log | tee -a "$LOG_FILE"
else
    echo "No AI sorting logs found." | tee -a "$LOG_FILE"
fi

echo -e "\nMonitoring complete - $(date)" | tee -a "$LOG_FILE"
echo "===========================================" | tee -a "$LOG_FILE"
