# Network Attached Storage (NAS) Implementation using Raspberry Pi
## Engineering Clinics 2 - Team Project (September 2024)

## Abstract
This project presents the design, implementation, and evaluation of a Network Attached Storage (NAS) system using Raspberry Pi microcomputer. The project addresses the growing concerns of high cloud storage costs, data privacy issues, and dependency on third-party services by providing a locally hosted, scalable storage solution. Our implementation demonstrates significant cost savings compared to commercial cloud services while maintaining data security and providing faster local network access speeds.

## Overview
Developed as part of the Engineering Clinics 2 course, our team created a cost-effective Network Attached Storage (NAS) solution using Raspberry Pi. The system provides a locally hosted, scalable storage solution that addresses common cloud storage concerns such as recurring costs, data privacy issues, and dependency on third-party services.

## Features
- **Basic NAS Setup**: Automated Samba configuration and storage management
- **Network Configuration**: Static IP and network settings
- **User Management**: Create, delete, and manage users with individual private folders
- **RAID Configuration**: Option to set up RAID arrays for data redundancy
- **Remote Access**: Secure remote access via SSH and WireGuard VPN
- **Web Interfaces**: Optional Nextcloud, Jellyfin, FileBrowser, and monitoring services
- **Backup System**: Automated incremental backup solution
- **System Monitoring**: Tools to monitor system health and performance
- **AI File Sorting**: Intelligent file organization using content analysis and machine learning

## Hardware Requirements
- Raspberry Pi 4 Model B (4GB+ RAM recommended)
- MicroSD card (16GB+)
- External USB hard drive(s)
- Ethernet cable
- Power supply

## Total Cost Breakdown
| Component | Specification | Cost (₹) | Justification |
|-----------|--------------|----------|--------------|
| Raspberry Pi 4 | 4GB RAM, ARM Cortex-A72 | 4,000 | Sufficient processing power for file operations |
| MicroSD Card | 16GB Class 10 | 400 | Fast boot and OS storage |
| External HDD | 1TB USB 3.0 | 800 | Primary data storage with expansion capability |
| Power Supply | 5V 3A USB-C | 400 | Stable power delivery |
| Ethernet Cable | CAT6 1m | 120 | High-speed network connectivity |
| **Total Cost** |  | **5,820** | |

## Installation Guide

### Prerequisites
1. Raspberry Pi OS (Debian-based Linux distribution) installed on the MicroSD card
2. SSH enabled on the Raspberry Pi
3. Network connectivity

### Installation Steps
1. Clone this repository to your Raspberry Pi:
   ```
   git clone https://github.com/yourusername/raspberry-pi-nas.git
   cd raspberry-pi-nas
   ```

2. Make the installation script executable:
   ```
   chmod +x install.sh
   ```

3. Run the installation script as root:
   ```
   sudo ./install.sh
   ```

4. Follow the on-screen instructions to complete the setup

## Script Descriptions
- **install.sh**: Master installation script that guides through the entire setup process
- **setup.sh**: Basic NAS setup including Samba configuration and storage management
- **network_config.sh**: Network configuration for setting up static IP
- **user_manager.sh**: User management tools for creating, deleting, and managing users
- **raid_config.sh**: Tools for setting up and managing RAID arrays
- **remote_access.sh**: Configuration for secure remote access
- **web_interface.sh**: Installation of web-based management interfaces
- **backup.sh**: Setup and configuration of automated backup system
- **monitor.sh**: System monitoring tools

## Client Access Methods

### Windows Client
1. Open File Explorer
2. Navigate to `\\<nas-ip-address>`
3. Enter credentials: username=pi, password=[samba_password]
4. Map network drives for persistent access

### macOS Client
1. Open Finder
2. Go > Connect to Server
3. Enter: `smb://<nas-ip-address>`
4. Enter credentials and select shares

### Linux Client
```bash
# Install CIFS utilities
sudo apt install cifs-utils

# Create mount point
sudo mkdir /mnt/nas

# Mount share
sudo mount -t cifs //<nas-ip-address>/shared /mnt/nas -o username=pi
```

## Performance Analysis
| File Size | Local Network Transfer | Internet Upload (Cloud) | Performance Gain |
|-----------|----------------------|------------------------|------------------|
| 100MB | 45 MB/s | 5 MB/s | 9x faster |
| 1GB | 42 MB/s | 4.8 MB/s | 8.75x faster |
| 10GB | 40 MB/s | 4.5 MB/s | 8.89x faster |

## Cost Analysis (5-Year TCO)
| Solution | Initial Cost (₹) | Annual Cost (₹) | 5-Year Total (₹) |
|----------|---------------|--------------|-----------------|
| Raspberry Pi NAS | 5,820 | 200* | 6,820 |
| Cloud Storage (1TB) | 0 | 3,600 | 18,000 |
| **Savings** | | | **11,180** |

*Annual cost includes electricity consumption

## Future Enhancements
- RAID 1 configuration for data redundancy
- UPS integration for power backup
- Multiple drive bays for expansion
- Web-based management interface improvements
- Automated backup scheduling
- Media streaming capabilities (Plex/Jellyfin)
- Cloud synchronization hybrid approach
- Enhanced AI file analysis with video content recognition
- Machine learning for personalized file organization
- Intelligent data deduplication based on content analysis

## Troubleshooting
### Cannot access NAS from Windows
- Verify SMB1 is enabled in Windows features
- Check firewall settings on both devices
- Verify Samba service status

### Slow transfer speeds
- Check Ethernet cable quality (use CAT6)
- Verify network switch capabilities
- Monitor system resources during transfers

### Permission denied errors
- Verify Samba user exists: `sudo pdbedit -L`
- Check directory permissions: `ls -la /mnt/nasdata`
- Review Samba configuration syntax: `testparm`

## Academic Project Documentation
This implementation represents the culmination of our Engineering Clinics 2 course project. As part of this academic endeavor, we've prepared the following documentation:

### Project Approach
For a detailed understanding of our project methodology, refer to the `approach` folder which contains:
- [Complete Process Flow](approach/process_flow.md): Visual representation of the NAS with AI file sorting workflow
- [AI Sorting Implementation](approach/ai_sorting_implementation.md): Detailed documentation of the intelligent file organization system
- [Project Requirements](approach/project_requirements.md): Technical and functional requirements
- [Challenges and Solutions](approach/challenges_solutions.md): Issues encountered and how they were resolved
- [Lessons Learned](approach/lessons_learned.md): Key insights gained throughout the project
- [Project Conclusion](approach/project_conclusion.md): Final assessment of project outcomes and achievements

### Project Report
The complete project report includes:
- Detailed background research on NAS technologies
- Problem statement and objectives
- Comprehensive methodology
- Performance evaluation metrics and results
- Security implementation details
- Cost-benefit analysis
- Future enhancement opportunities

### Presentation Materials
- Project demonstration slides
- Live demonstration workflow
- Performance comparison charts
- Implementation timeline

### Learning Outcomes
Through this project, our team gained practical experience in:
- Linux system administration
- Network protocols and security
- Storage technologies and file systems
- Performance optimization techniques
- Project management and collaboration
- Technical documentation and reporting

## Project Team
This project was developed as part of the Engineering Clinics 2 course by:

| Roll Number | Team Member       | Contributions                                    |
|-------------|-------------------|--------------------------------------------------|
| 22BCE8807   | Asneem Athar      | Team Lead, System Architecture, Base System Setup |
| 22BCE20311  | Lakshmi Nikhitha  | Storage Configuration, RAID Implementation       |
| 22BCE8368   | M.A Afsheen       | Network Configuration, Web Interface Integration |
| 22BCE9050   | A.Kohima          | User Management, Security Implementation, AI Development |
| 22BCE9489   | K.Saidivya        | Testing, AI File Sorting, Performance Evaluation |
| 22BCE7192   | Sravan Kumar      | Documentation, Web Interface, Security Testing   |

### Course Information
- **Course**: Engineering Clinics 2
- **Supervisor**: Dr. SK. Kareemulla
- **Institution**: School of Computer Science and Engineering
- **Date**: September 2024

### Acknowledgments
We would like to express our sincere gratitude to our supervisor Dr. SK. Kareemulla for his invaluable guidance throughout this project. We also thank the department for providing us with the necessary resources and equipment to complete this implementation successfully.
