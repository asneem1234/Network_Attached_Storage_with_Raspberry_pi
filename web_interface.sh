#!/bin/bash
# Web Interface Installation Script for Raspberry Pi NAS
# Author: Engineering Clinics Group
# Date: September 2024

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}Raspberry Pi NAS Web Interface Setup${NC}"
echo -e "${BLUE}=======================================${NC}"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root${NC}"
    exit 1
fi

# Function to install Nextcloud
install_nextcloud() {
    echo -e "${YELLOW}Installing Nextcloud...${NC}"
    
    # Install dependencies
    apt update
    apt install -y apache2 mariadb-server libapache2-mod-php php-gd php-json php-mysql php-curl \
                   php-mbstring php-intl php-imagick php-xml php-zip php-apcu php-redis
    
    # Configure database
    echo -e "${YELLOW}Setting up MySQL database...${NC}"
    read -p "Enter database password for Nextcloud: " DB_PASSWORD
    
    mysql -e "CREATE DATABASE nextcloud;"
    mysql -e "CREATE USER 'nextclouduser'@'localhost' IDENTIFIED BY '$DB_PASSWORD';"
    mysql -e "GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextclouduser'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
    
    # Download and extract Nextcloud
    echo -e "${YELLOW}Downloading Nextcloud...${NC}"
    cd /var/www/
    wget https://download.nextcloud.com/server/releases/latest.zip
    apt install -y unzip
    unzip latest.zip
    rm latest.zip
    
    # Set permissions
    chown -R www-data:www-data /var/www/nextcloud
    
    # Configure Apache
    echo -e "${YELLOW}Configuring Apache...${NC}"
    cat > /etc/apache2/sites-available/nextcloud.conf << EOF
<VirtualHost *:80>
    DocumentRoot /var/www/nextcloud
    ServerName localhost
    
    <Directory /var/www/nextcloud>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
        <IfModule mod_dav.c>
            Dav off
        </IfModule>
        SetEnv HOME /var/www/nextcloud
        SetEnv HTTP_HOME /var/www/nextcloud
    </Directory>
    
    ErrorLog ${APACHE_LOG_DIR}/nextcloud_error.log
    CustomLog ${APACHE_LOG_DIR}/nextcloud_access.log combined
</VirtualHost>
EOF
    
    # Enable required Apache modules
    a2enmod rewrite headers env dir mime
    a2ensite nextcloud.conf
    
    # Restart Apache
    systemctl restart apache2
    
    # Create data directory on NAS storage
    mkdir -p /mnt/nasdata/nextcloud_data
    chown -R www-data:www-data /mnt/nasdata/nextcloud_data
    
    echo -e "${GREEN}Nextcloud installation complete!${NC}"
    IP_ADDR=$(hostname -I | awk '{print $1}')
    echo -e "${YELLOW}Access Nextcloud at http://$IP_ADDR${NC}"
    echo -e "${YELLOW}During setup, use:${NC}"
    echo -e "  ${YELLOW}Database: nextcloud${NC}"
    echo -e "  ${YELLOW}Database user: nextclouduser${NC}"
    echo -e "  ${YELLOW}Database password: $DB_PASSWORD${NC}"
    echo -e "  ${YELLOW}Data folder: /mnt/nasdata/nextcloud_data${NC}"
}

# Function to install Jellyfin Media Server
install_jellyfin() {
    echo -e "${YELLOW}Installing Jellyfin Media Server...${NC}"
    
    # Add jellyfin repository
    apt install -y apt-transport-https gnupg
    wget -O - https://repo.jellyfin.org/jellyfin_team.gpg.key | apt-key add -
    echo "deb [arch=$( dpkg --print-architecture )] https://repo.jellyfin.org/debian bullseye main" > /etc/apt/sources.list.d/jellyfin.list
    
    # Install Jellyfin
    apt update
    apt install -y jellyfin
    
    # Create media directories
    mkdir -p /mnt/nasdata/media/{movies,tvshows,music,photos}
    chown -R jellyfin:jellyfin /mnt/nasdata/media
    
    # Start and enable service
    systemctl start jellyfin
    systemctl enable jellyfin
    
    # Open firewall
    ufw allow 8096/tcp
    
    IP_ADDR=$(hostname -I | awk '{print $1}')
    echo -e "${GREEN}Jellyfin installation complete!${NC}"
    echo -e "${YELLOW}Access Jellyfin at http://$IP_ADDR:8096${NC}"
}

# Function to install FileBrowser
install_filebrowser() {
    echo -e "${YELLOW}Installing FileBrowser...${NC}"
    
    # Download the latest version
    curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
    
    # Create database directory
    mkdir -p /etc/filebrowser
    
    # Initialize database
    filebrowser -d /etc/filebrowser/filebrowser.db config init
    
    # Set root directory to NAS storage
    filebrowser -d /etc/filebrowser/filebrowser.db config set --root /mnt/nasdata
    
    # Set address to listen on all interfaces
    filebrowser -d /etc/filebrowser/filebrowser.db config set --address 0.0.0.0
    
    # Set port
    filebrowser -d /etc/filebrowser/filebrowser.db config set --port 8080
    
    # Create admin user
    read -p "Enter admin password for FileBrowser: " ADMIN_PASSWORD
    filebrowser -d /etc/filebrowser/filebrowser.db users add admin "$ADMIN_PASSWORD" --perm.admin
    
    # Create systemd service
    cat > /etc/systemd/system/filebrowser.service << EOF
[Unit]
Description=File Browser
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/filebrowser -d /etc/filebrowser/filebrowser.db

[Install]
WantedBy=multi-user.target
EOF
    
    # Enable and start service
    systemctl daemon-reload
    systemctl enable filebrowser
    systemctl start filebrowser
    
    # Open firewall
    ufw allow 8080/tcp
    
    IP_ADDR=$(hostname -I | awk '{print $1}')
    echo -e "${GREEN}FileBrowser installation complete!${NC}"
    echo -e "${YELLOW}Access FileBrowser at http://$IP_ADDR:8080${NC}"
    echo -e "${YELLOW}Login with:${NC}"
    echo -e "  ${YELLOW}Username: admin${NC}"
    echo -e "  ${YELLOW}Password: $ADMIN_PASSWORD${NC}"
}

# Function to install Grafana monitoring
install_grafana() {
    echo -e "${YELLOW}Installing Grafana and Prometheus for monitoring...${NC}"
    
    # Install dependencies
    apt update
    apt install -y adduser libfontconfig1
    
    # Install Prometheus
    echo -e "${YELLOW}Installing Prometheus...${NC}"
    wget https://github.com/prometheus/prometheus/releases/download/v2.37.0/prometheus-2.37.0.linux-armv7.tar.gz
    tar xfz prometheus-*.tar.gz
    
    # Create prometheus user
    useradd --no-create-home --shell /bin/false prometheus
    mkdir -p /etc/prometheus /var/lib/prometheus
    
    # Copy binaries
    cp prometheus-*/prometheus /usr/local/bin/
    cp prometheus-*/promtool /usr/local/bin/
    cp -r prometheus-*/consoles /etc/prometheus
    cp -r prometheus-*/console_libraries /etc/prometheus
    
    # Set ownership
    chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
    
    # Create prometheus configuration
    cat > /etc/prometheus/prometheus.yml << EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']
  
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
EOF
    
    chown prometheus:prometheus /etc/prometheus/prometheus.yml
    
    # Create service file
    cat > /etc/systemd/system/prometheus.service << EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF
    
    # Install Node Exporter
    echo -e "${YELLOW}Installing Node Exporter...${NC}"
    wget https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-armv7.tar.gz
    tar xfz node_exporter-*.tar.gz
    cp node_exporter-*/node_exporter /usr/local/bin/
    useradd --no-create-home --shell /bin/false node_exporter
    
    # Create Node Exporter service
    cat > /etc/systemd/system/node_exporter.service << EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF
    
    # Install Grafana
    echo -e "${YELLOW}Installing Grafana...${NC}"
    wget https://dl.grafana.com/oss/release/grafana_9.0.2_armhf.deb
    dpkg -i grafana_9.0.2_armhf.deb
    
    # Start services
    systemctl daemon-reload
    systemctl enable prometheus node_exporter grafana-server
    systemctl start prometheus node_exporter grafana-server
    
    # Open firewall
    ufw allow 3000/tcp
    
    # Clean up
    rm -rf prometheus-* node_exporter-* grafana_*.deb
    
    IP_ADDR=$(hostname -I | awk '{print $1}')
    echo -e "${GREEN}Monitoring setup complete!${NC}"
    echo -e "${YELLOW}Access Grafana at http://$IP_ADDR:3000${NC}"
    echo -e "${YELLOW}Default login:${NC}"
    echo -e "  ${YELLOW}Username: admin${NC}"
    echo -e "  ${YELLOW}Password: admin${NC}"
    echo -e "${YELLOW}Prometheus is available at http://$IP_ADDR:9090${NC}"
}

# Main menu
while true; do
    echo -e "${BLUE}\nWeb Interface Options:${NC}"
    echo "1: Install Nextcloud (File Sync & Share)"
    echo "2: Install Jellyfin Media Server"
    echo "3: Install FileBrowser (Simple File Manager)"
    echo "4: Install Grafana & Prometheus Monitoring"
    echo "5: Exit"
    read -p "Select option (1-5): " OPTION
    
    case $OPTION in
        1)
            install_nextcloud
            ;;
        2)
            install_jellyfin
            ;;
        3)
            install_filebrowser
            ;;
        4)
            install_grafana
            ;;
        5)
            echo -e "${BLUE}Exiting Web Interface Setup${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please select 1-5.${NC}"
            ;;
    esac
done
