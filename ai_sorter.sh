#!/bin/bash
# AI File Sorting Implementation Script
# Author: Engineering Clinics Group
# Date: September 2024

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}=================================================${NC}"
echo -e "${CYAN}AI File Sorting Implementation${NC}"
echo -e "${BLUE}=================================================${NC}"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root${NC}"
    echo -e "${YELLOW}Please run: sudo bash $(basename "$0")${NC}"
    exit 1
fi

# Check for Python installation
echo -e "${CYAN}Checking for Python...${NC}"
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}Python not found. Installing Python 3...${NC}"
    apt update
    apt install -y python3 python3-pip python3-venv
else
    echo -e "${GREEN}Python is already installed.${NC}"
fi

# Create virtual environment for Python packages
echo -e "${CYAN}Setting up Python environment...${NC}"
mkdir -p /opt/nasai
python3 -m venv /opt/nasai/env

# Install required Python packages
echo -e "${CYAN}Installing required Python packages...${NC}"
/opt/nasai/env/bin/pip install watchdog opencv-python scikit-learn pillow numpy

# Create directory for AI sorting scripts
echo -e "${CYAN}Creating directory structure for AI sorting...${NC}"
mkdir -p /opt/nasai/scripts

# Create Python script for file monitoring
echo -e "${CYAN}Creating file monitoring script...${NC}"
cat > /opt/nasai/scripts/file_sorter.py << 'EOF'
#!/usr/bin/env python3
# File Sorter with AI capabilities
# Author: Engineering Clinics Group

import os
import sys
import shutil
import time
import logging
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import mimetypes
import hashlib

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/file_sorter.log'),
        logging.StreamHandler()
    ]
)

# Try to import optional packages for enhanced classification
try:
    import numpy as np
    import cv2
    OPENCV_AVAILABLE = True
    logging.info("OpenCV is available - Enhanced image analysis enabled")
except ImportError:
    OPENCV_AVAILABLE = False
    logging.warning("OpenCV not available - Basic sorting only")

try:
    from sklearn.feature_extraction.text import CountVectorizer
    from sklearn.naive_bayes import MultinomialNB
    SKLEARN_AVAILABLE = True
    logging.info("scikit-learn is available - Enhanced document analysis enabled")
except ImportError:
    SKLEARN_AVAILABLE = False
    logging.warning("scikit-learn not available - Basic document sorting only")

# Configuration
WATCH_DIRECTORY = "/mnt/nasdata/incoming"
OUTPUT_BASE = "/mnt/nasdata"

# Make sure the incoming directory exists
os.makedirs(WATCH_DIRECTORY, exist_ok=True)

# Define category directories
CATEGORIES = {
    'documents': ['.pdf', '.doc', '.docx', '.txt', '.rtf', '.odt', '.xls', '.xlsx', '.ppt', '.pptx'],
    'images': ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.webp'],
    'videos': ['.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm', '.m4v'],
    'audio': ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a', '.wma'],
    'archives': ['.zip', '.rar', '.7z', '.tar', '.gz', '.bz2'],
    'code': ['.py', '.js', '.html', '.css', '.java', '.cpp', '.c', '.php', '.rb', '.go'],
    'others': []  # Default category
}

# Ensure all category directories exist
for category in CATEGORIES.keys():
    os.makedirs(os.path.join(OUTPUT_BASE, category), exist_ok=True)

# File classification functions
def get_file_hash(file_path):
    """Calculate MD5 hash of file to detect duplicates"""
    hash_md5 = hashlib.md5()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()

def classify_by_extension(file_path):
    """Classify file based on its extension"""
    _, ext = os.path.splitext(file_path.lower())
    
    for category, extensions in CATEGORIES.items():
        if ext in extensions:
            return category
    
    return "others"

def analyze_image(image_path):
    """Perform basic image analysis if OpenCV is available"""
    if not OPENCV_AVAILABLE:
        return None
    
    try:
        img = cv2.imread(image_path)
        if img is None:
            return None
            
        # Simple analysis - get image dimensions and detect if it's mostly dark
        height, width, _ = img.shape
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        avg_pixel = np.mean(gray)
        
        # Create subdirectory based on image characteristics
        if width > 1920 or height > 1080:
            return "high_resolution"
        elif avg_pixel < 50:
            return "dark"
        elif avg_pixel > 200:
            return "bright"
        else:
            return "normal"
    except Exception as e:
        logging.error(f"Error analyzing image {image_path}: {e}")
        return None

def is_duplicate(file_path, category):
    """Check if file is a duplicate by comparing hash"""
    file_hash = get_file_hash(file_path)
    hash_file = os.path.join(OUTPUT_BASE, ".file_hashes.txt")
    
    # Create hash file if it doesn't exist
    if not os.path.exists(hash_file):
        open(hash_file, 'a').close()
        
    with open(hash_file, 'r') as f:
        for line in f:
            if file_hash in line:
                return True
                
    # Add hash to the file
    with open(hash_file, 'a') as f:
        f.write(f"{file_hash}:{os.path.basename(file_path)}:{category}\n")
        
    return False

class FileHandler(FileSystemEventHandler):
    def on_created(self, event):
        if event.is_directory:
            return
            
        file_path = event.src_path
        
        # Wait for file to be completely written
        time.sleep(1)
        
        # Skip temporary files
        if file_path.endswith('.tmp') or os.path.basename(file_path).startswith('.'):
            return
            
        try:
            # Classify file by extension
            category = classify_by_extension(file_path)
            
            # Check if it's a duplicate
            if is_duplicate(file_path, category):
                logging.info(f"Duplicate file detected: {file_path}")
                duplicate_dir = os.path.join(OUTPUT_BASE, "duplicates")
                os.makedirs(duplicate_dir, exist_ok=True)
                shutil.move(file_path, os.path.join(duplicate_dir, os.path.basename(file_path)))
                return
                
            # Special handling for images
            if category == "images" and OPENCV_AVAILABLE:
                sub_category = analyze_image(file_path)
                if sub_category:
                    target_dir = os.path.join(OUTPUT_BASE, category, sub_category)
                    os.makedirs(target_dir, exist_ok=True)
                    target_path = os.path.join(target_dir, os.path.basename(file_path))
                    shutil.move(file_path, target_path)
                    logging.info(f"Moved {file_path} to {target_path}")
                    return
            
            # Move file to appropriate category directory
            target_dir = os.path.join(OUTPUT_BASE, category)
            target_path = os.path.join(target_dir, os.path.basename(file_path))
            shutil.move(file_path, target_path)
            logging.info(f"Moved {file_path} to {target_path}")
            
        except Exception as e:
            logging.error(f"Error processing {file_path}: {e}")

if __name__ == "__main__":
    logging.info("Starting AI File Sorting Service")
    
    # Set up file system observer
    event_handler = FileHandler()
    observer = Observer()
    observer.schedule(event_handler, WATCH_DIRECTORY, recursive=False)
    observer.start()
    
    try:
        logging.info(f"Watching directory: {WATCH_DIRECTORY}")
        logging.info("AI File Sorting Service is running. Press Ctrl+C to stop.")
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
        logging.info("AI File Sorting Service stopped")
    
    observer.join()
EOF

# Make the script executable
chmod +x /opt/nasai/scripts/file_sorter.py

# Create systemd service for automatic startup
echo -e "${CYAN}Creating systemd service for file sorting...${NC}"
cat > /etc/systemd/system/file_sorter.service << EOF
[Unit]
Description=AI File Sorting Service
After=network.target smbd.service

[Service]
ExecStart=/opt/nasai/env/bin/python3 /opt/nasai/scripts/file_sorter.py
Restart=always
User=root
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

# Create incoming directory
echo -e "${CYAN}Creating incoming directory for file monitoring...${NC}"
mkdir -p /mnt/nasdata/incoming
chmod 777 /mnt/nasdata/incoming

# Update Samba configuration to include incoming directory
echo -e "${CYAN}Updating Samba configuration...${NC}"
if grep -q "\[Incoming\]" /etc/samba/smb.conf; then
    echo -e "${YELLOW}Incoming share already exists in Samba config.${NC}"
else
    cat >> /etc/samba/smb.conf << EOF

[Incoming]
    path = /mnt/nasdata/incoming
    browseable = yes
    read only = no
    guest ok = yes
    create mask = 0777
    directory mask = 0777
    comment = Drop files here for AI sorting
EOF
    echo -e "${GREEN}Added Incoming share to Samba config.${NC}"
    
    # Restart Samba service
    systemctl restart smbd
fi

# Enable and start file sorter service
echo -e "${CYAN}Enabling and starting file sorter service...${NC}"
systemctl enable file_sorter
systemctl start file_sorter

# Create a simple web interface for monitoring
echo -e "${CYAN}Creating basic web interface for monitoring...${NC}"
mkdir -p /var/www/html/nasai

cat > /var/www/html/nasai/index.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Raspberry Pi NAS - AI File Sorting</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1 {
            color: #2c3e50;
            border-bottom: 2px solid #3498db;
            padding-bottom: 10px;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
        }
        .card {
            background: #f9f9f9;
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .category {
            background: #3498db;
            color: white;
            padding: 5px 10px;
            border-radius: 3px;
            font-size: 14px;
            display: inline-block;
            margin-right: 5px;
            margin-bottom: 5px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Raspberry Pi NAS - AI File Sorting</h1>
        
        <div class="card">
            <h2>How It Works</h2>
            <p>The AI file sorting system automatically organizes files uploaded to the Incoming folder.</p>
            <p>Simply drop your files into the Incoming share, and they will be automatically sorted based on file type and content analysis.</p>
        </div>
        
        <div class="card">
            <h2>Categories</h2>
            <span class="category">documents</span>
            <span class="category">images</span>
            <span class="category">videos</span>
            <span class="category">audio</span>
            <span class="category">archives</span>
            <span class="category">code</span>
            <span class="category">others</span>
        </div>
        
        <div class="card">
            <h2>Status</h2>
            <p>Service status: <span id="status">Checking...</span></p>
            <p>Last processed file: <span id="last-file">None</span></p>
        </div>
    </div>
</body>
</html>
EOF

echo -e "${GREEN}AI file sorting implementation completed!${NC}"
echo -e "${YELLOW}The system is now monitoring the /mnt/nasdata/incoming directory.${NC}"
echo -e "${YELLOW}Files added to this directory will be automatically sorted based on type and content.${NC}"
echo -e "${BLUE}=================================================${NC}"

# Helper Functions (integrated from ai_helper.sh)

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

# Helper Menu
show_helper_menu() {
    echo -e "${BLUE}\nAI File Sorting Helper:${NC}"
    echo -e "${CYAN}1: Check Service Status${NC}"
    echo -e "${CYAN}2: View Recent Logs${NC}"
    echo -e "${CYAN}3: Show Statistics${NC}"
    echo -e "${CYAN}4: Restart Service${NC}"
    echo -e "${CYAN}5: Return to Main Menu${NC}"
    
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
            return
            ;;
        *)
            echo -e "${RED}Invalid option.${NC}"
            ;;
    esac
    
    echo -e "\n"
    read -p "Press Enter to continue..."
    show_helper_menu
}
