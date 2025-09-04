#!/bin/bash
# Remote Access Configuration Script for Raspberry Pi NAS
# Author: Engineering Clinics Group
# Date: September 2024

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}Raspberry Pi NAS Remote Access Setup${NC}"
echo -e "${BLUE}=======================================${NC}"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root${NC}"
    exit 1
fi

# Install required packages if not present
install_packages() {
    echo -e "${YELLOW}Installing required packages...${NC}"
    apt update
    apt install -y openssh-server fail2ban ufw
}

# Configure SSH settings
configure_ssh() {
    echo -e "${YELLOW}Configuring SSH...${NC}"
    
    # Backup original SSH config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    # Ask for SSH port
    read -p "Enter custom SSH port (leave blank for default 22): " SSH_PORT
    SSH_PORT=${SSH_PORT:-22}
    
    # Ask for password authentication
    read -p "Enable password authentication? (y/n): " PASS_AUTH
    if [ "$PASS_AUTH" = "y" ]; then
        PASS_AUTH_CONF="yes"
    else
        PASS_AUTH_CONF="no"
    fi
    
    # Update SSH configuration
    sed -i "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
    sed -i "s/#PasswordAuthentication yes/PasswordAuthentication $PASS_AUTH_CONF/" /etc/ssh/sshd_config
    sed -i "s/PasswordAuthentication yes/PasswordAuthentication $PASS_AUTH_CONF/" /etc/ssh/sshd_config
    sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin no/" /etc/ssh/sshd_config
    
    # Set up SSH keys if requested
    if [ "$PASS_AUTH_CONF" = "no" ]; then
        echo -e "${YELLOW}Setting up SSH key authentication...${NC}"
        if [ ! -d "/home/pi/.ssh" ]; then
            mkdir -p /home/pi/.ssh
            chmod 700 /home/pi/.ssh
            chown pi:pi /home/pi/.ssh
        fi
        
        echo -e "${YELLOW}Please paste your public SSH key:${NC}"
        read SSH_KEY
        echo "$SSH_KEY" >> /home/pi/.ssh/authorized_keys
        chmod 600 /home/pi/.ssh/authorized_keys
        chown pi:pi /home/pi/.ssh/authorized_keys
    fi
    
    # Restart SSH service
    systemctl restart ssh
    
    # Update firewall
    ufw allow $SSH_PORT/tcp
    
    echo -e "${GREEN}SSH configured to use port $SSH_PORT${NC}"
}

# Configure Fail2ban for brute force protection
configure_fail2ban() {
    echo -e "${YELLOW}Configuring Fail2Ban...${NC}"
    
    # Create custom jail configuration
    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 86400
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 86400

[samba]
enabled = true
filter = samba
logpath = /var/log/samba/log.*
maxretry = 5
bantime = 3600
EOF
    
    # Restart fail2ban
    systemctl restart fail2ban
    
    echo -e "${GREEN}Fail2Ban configured for brute force protection${NC}"
}

# Set up Wireguard VPN for secure remote access
setup_wireguard() {
    echo -e "${YELLOW}Setting up WireGuard VPN...${NC}"
    
    # Install WireGuard
    apt install -y wireguard
    
    # Generate server keys
    cd /etc/wireguard
    wg genkey | tee /etc/wireguard/server_private.key | wg pubkey > /etc/wireguard/server_public.key
    SERVER_PRIVATE_KEY=$(cat /etc/wireguard/server_private.key)
    SERVER_PUBLIC_KEY=$(cat /etc/wireguard/server_public.key)
    
    # Get server interface details
    read -p "Enter VPN internal subnet (e.g., 10.0.0.1/24): " VPN_SUBNET
    VPN_SUBNET=${VPN_SUBNET:-10.0.0.1/24}
    
    # Get server public endpoint
    read -p "Enter server public IP or hostname: " SERVER_ENDPOINT
    read -p "Enter WireGuard port (default: 51820): " WG_PORT
    WG_PORT=${WG_PORT:-51820}
    
    # Create server config
    cat > /etc/wireguard/wg0.conf << EOF
[Interface]
Address = $VPN_SUBNET
SaveConfig = true
PrivateKey = $SERVER_PRIVATE_KEY
ListenPort = $WG_PORT
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF
    
    # Enable IP forwarding
    echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-wireguard.conf
    sysctl -p /etc/sysctl.d/99-wireguard.conf
    
    # Generate client configuration
    CLIENT_PRIVATE_KEY=$(wg genkey)
    CLIENT_PUBLIC_KEY=$(echo $CLIENT_PRIVATE_KEY | wg pubkey)
    CLIENT_IP="10.0.0.2/24"
    
    # Add client to server config
    cat >> /etc/wireguard/wg0.conf << EOF

[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = 10.0.0.2/32
EOF
    
    # Create client config
    mkdir -p /home/pi/wireguard-clients
    cat > /home/pi/wireguard-clients/client.conf << EOF
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = $CLIENT_IP
DNS = 8.8.8.8

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_ENDPOINT:$WG_PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF
    
    # Set permissions
    chmod 600 /etc/wireguard/wg0.conf
    chmod 600 /home/pi/wireguard-clients/client.conf
    chown -R pi:pi /home/pi/wireguard-clients
    
    # Enable and start WireGuard
    systemctl enable wg-quick@wg0
    systemctl start wg-quick@wg0
    
    # Update firewall
    ufw allow $WG_PORT/udp
    
    echo -e "${GREEN}WireGuard VPN configured!${NC}"
    echo -e "${YELLOW}Client configuration saved to /home/pi/wireguard-clients/client.conf${NC}"
    echo -e "${YELLOW}You can scan this QR code with the WireGuard mobile app:${NC}"
    qrencode -t ansiutf8 < /home/pi/wireguard-clients/client.conf
}

# Generate self-signed SSL certificate
generate_ssl_cert() {
    echo -e "${YELLOW}Generating self-signed SSL certificate...${NC}"
    
    # Install required packages
    apt install -y openssl
    
    # Create certificate directory
    mkdir -p /etc/ssl/nas
    
    # Ask for hostname/domain
    read -p "Enter your NAS hostname or domain: " NAS_DOMAIN
    NAS_DOMAIN=${NAS_DOMAIN:-raspberrypi.local}
    
    # Generate certificate
    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
      -keyout /etc/ssl/nas/nas.key -out /etc/ssl/nas/nas.crt \
      -subj "/CN=$NAS_DOMAIN" \
      -addext "subjectAltName = DNS:$NAS_DOMAIN,DNS:localhost,IP:127.0.0.1"
    
    # Set permissions
    chmod 600 /etc/ssl/nas/nas.key
    
    echo -e "${GREEN}SSL certificate generated at /etc/ssl/nas/nas.crt and /etc/ssl/nas/nas.key${NC}"
}

# Main menu
while true; do
    echo -e "${BLUE}\nRemote Access Options:${NC}"
    echo "1: Install Required Packages"
    echo "2: Configure SSH"
    echo "3: Configure Fail2Ban"
    echo "4: Setup WireGuard VPN"
    echo "5: Generate SSL Certificate"
    echo "6: Exit"
    read -p "Select option (1-6): " OPTION
    
    case $OPTION in
        1)
            install_packages
            ;;
        2)
            configure_ssh
            ;;
        3)
            configure_fail2ban
            ;;
        4)
            setup_wireguard
            ;;
        5)
            generate_ssl_cert
            ;;
        6)
            echo -e "${BLUE}Exiting Remote Access Setup${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please select 1-6.${NC}"
            ;;
    esac
done
