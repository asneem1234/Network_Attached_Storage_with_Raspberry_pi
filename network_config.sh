#!/bin/bash
# Network Configuration Script for Raspberry Pi NAS
# Author: Engineering Clinics Group
# Date: September 2024

echo "Configuring network settings for NAS..."

# Backup current configuration
sudo cp /etc/dhcpcd.conf /etc/dhcpcd.conf.backup

# Prompt for network settings
echo "Enter static IP address (e.g., 192.168.1.100):"
read STATIC_IP
echo "Enter router/gateway IP (e.g., 192.168.1.1):"
read ROUTER_IP
echo "Enter DNS server (default: 8.8.8.8):"
read DNS_SERVER
DNS_SERVER=${DNS_SERVER:-8.8.8.8}

# Add static IP configuration
cat << EOF | sudo tee -a /etc/dhcpcd.conf

# Static IP configuration for NAS
interface eth0
static ip_address=$STATIC_IP/24
static routers=$ROUTER_IP
static domain_name_servers=$DNS_SERVER
EOF

echo "Network configuration complete! The system will use IP: $STATIC_IP"
echo "Please reboot the system for changes to take effect: sudo reboot"
