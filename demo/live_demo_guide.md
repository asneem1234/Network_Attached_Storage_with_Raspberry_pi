# Live Demo Guide: Smart Raspberry Pi NAS with AI in Action

This guide provides step-by-step instructions for presenting a compelling live demonstration of our Raspberry Pi Smart NAS solution with AI file sorting capabilities for various real-world use cases.

## Demo Setup Requirements

- Assembled Raspberry Pi Smart NAS (as per project specifications)
- AI file sorting system configured and running
- At least one connected external drive (1TB+)
- Local network with router
- 2-3 client devices (laptop, smartphone, tablet)
- Sample files of various types (photos, videos, documents, spreadsheets, etc.)
- Optional: IoT device (like a Raspberry Pi with sensors)

## Demo 1: AI File Sorting System

### Scenario
A user with a large collection of various file types needs an intelligent system that automatically organizes files without manual intervention.

### Setup
1. Ensure AI file sorter service is running (`sudo systemctl status file_sorter`)
2. Prepare a mix of sample files:
   - Various document types (.pdf, .docx, .xlsx, .txt)
   - Images of different types (.jpg, .png, .gif)
   - Media files (.mp3, .mp4)
   - Archive files (.zip, .rar)
   - Code files (.py, .js, .html)
   - Some duplicate files (exact copies of existing files)

### Demo Script
1. **Introduction** (30 seconds)
   - "Today I'll demonstrate our Smart NAS with AI-powered file organization that eliminates the tedious task of manual file sorting"

2. **Show the System Architecture** (1 minute)
   - Explain the AI file sorting components
   - Show the monitoring interface
   - Point out the "Incoming" folder that serves as the drop zone

3. **Live Demo of AI Sorting** (3 minutes)
   - Upload a mix of files to the "Incoming" folder
   - Watch in real-time as files get sorted into appropriate categories
   - Upload a duplicate file and show how it's detected
   - Upload an image and show content-based categorization

4. **Before & After Comparison** (1 minute)
   - Show a "before" scenario (messy folder with mixed file types)
   - Show the "after" result with AI-organized files
   - Demonstrate how easy it is to find specific content

### Key Talking Points
- Time saved from manual file organization
- Intelligent categorization based on content, not just file extensions
- Duplicate detection prevents wasted storage
- Consistent organization across all users
- Self-maintaining system that gets better with more usage

## Demo 2: Smart Home Media Center

### Scenario
A family of four needs an affordable way to store and stream their growing media collection to multiple devices.

### Setup
1. Ensure Jellyfin media server is installed on the NAS
2. Place sample media in organized folders:
   - Movies in `/mnt/nasdata/media/movies`
   - TV Shows in `/mnt/nasdata/media/tvshows`
   - Music in `/mnt/nasdata/media/music`
3. Configure the AI file sorter to work with media content

### Demo Script
1. **Introduction** (30 seconds)
   - "Today I'll demonstrate how our affordable Raspberry Pi NAS solution can replace expensive streaming services and hardware"

2. **Show the Hardware** (1 minute)
   - Point out the Raspberry Pi and external drive
   - Mention the total cost (₹5,820 vs ₹15,000+ for commercial NAS)

3. **Access from Multiple Devices** (3 minutes)
   - Access the Jellyfin web interface from a laptop (http://[NAS-IP]:8096)
   - Browse the media library and start playing a video
   - Access the same interface from a smartphone
   - Demonstrate simultaneous streaming to multiple devices

4. **Cost Comparison** (1 minute)
   - Show a simple chart comparing costs:
     - Our solution: ₹5,820 one-time + minimal electricity
     - Commercial NAS: ₹15,000+ one-time + similar running costs
     - Streaming services: ₹500-1500/month (₹6,000-18,000/year)

### Key Talking Points
- One-time investment vs recurring subscription costs
- No internet dependency for local streaming
- Complete control over media organization
- No concerns about content being removed from streaming platforms

## Demo 2: Small Business File Sharing

### Scenario
A small design studio with 5 team members needs secure file sharing and collaboration.

### Setup
1. Create user accounts for each team member (use `user_manager.sh`)
2. Create shared project folders in `/mnt/nasdata/shared`
3. Set up appropriate permissions for different project folders

### Demo Script
1. **Introduction** (30 seconds)
   - "Now I'll show how this same system can support a small business's file sharing needs at a fraction of the cost of cloud solutions"

2. **User Management** (2 minutes)
   - Show the user management interface
   - Demonstrate adding a new user with custom permissions
   - Show how to create project-specific shared folders

3. **File Access Demo** (2 minutes)
   - Connect to the NAS from a Windows laptop (\\\\[NAS-IP])
   - Show how different users have different access permissions
   - Demonstrate file upload/download speeds (emphasize LAN speed advantage)
   - Show how to map network drives for permanent access

4. **Cost Comparison** (1 minute)
   - Our solution: ₹5,820 one-time (₹1,164/user for 5 users)
   - Business cloud storage: ₹750-1500/user/month (₹45,000-90,000 for 5 users over 5 years)

### Key Talking Points
- Data privacy and security advantages
- No recurring subscription costs
- Faster access speeds on local network
- Expandable storage at minimal cost

## Demo 3: Automatic Backup System

### Scenario
A family needs to automatically back up multiple computers to prevent data loss.

### Setup
1. Configure the backup script (`backup.sh`)
2. Set up a backup directory for each device
3. Configure a client computer with a scheduled backup task

### Demo Script
1. **Introduction** (30 seconds)
   - "Let me show you how this system provides peace of mind through automated backups"

2. **Backup Configuration** (2 minutes)
   - Show the backup script and explain its functionality
   - Demonstrate how to schedule automatic backups
   - Show how incremental backups save space

3. **Restore Process** (2 minutes)
   - Simulate data loss by deleting a file
   - Show the simple restore process
   - Demonstrate the version history feature

4. **Cost & Reliability Comparison** (1 minute)
   - Our solution: ₹5,820 one-time + expandable storage
   - Cloud backup services: ₹500-1000/month for multiple devices
   - External drives for each device: Less reliable, more expensive long-term

### Key Talking Points
- Protection against ransomware (offline backups)
- No size limitations (unlike many cloud services)
- Customizable backup schedules and retention policies
- Family-wide solution with individual private spaces

## Demo 4: IoT Data Collection Hub

### Scenario
A smart home enthusiast needs to collect and store data from various IoT sensors.

### Setup
1. Have a Raspberry Pi with a simple sensor sending data
2. Configure the NAS to receive and store this data
3. Set up a simple visualization dashboard

### Demo Script
1. **Introduction** (30 seconds)
   - "Finally, let's see how this NAS can serve as the backbone of a smart home"

2. **IoT Integration** (2 minutes)
   - Show a sensor sending data to the NAS
   - Demonstrate the data storage structure
   - Show how data is retained long-term unlike many cloud IoT platforms

3. **Data Visualization** (2 minutes)
   - Access the web dashboard showing sensor data
   - Show historical data trends
   - Demonstrate how alerts can be configured

4. **Comparison with Cloud IoT Platforms** (1 minute)
   - Our solution: Local control, no subscription, unlimited history
   - Cloud platforms: Monthly fees, limited history, internet dependency

### Key Talking Points
- Privacy concerns with cloud-based IoT platforms
- Resilience (continues working without internet)
- Integration possibilities with open-source home automation
- Unlimited data retention without additional costs

## Concluding the Demo

1. **Summarize the Versatility** (1 minute)
   - Recap the four different use cases demonstrated
   - Emphasize the single hardware solution meeting diverse needs

2. **Highlight the Financial Benefits** (1 minute)
   - Show the 5-year cost comparison chart
   - Emphasize the break-even point at 18 months

3. **Technical Skills Showcased** (1 minute)
   - Linux system administration
   - Networking configuration
   - Storage management
   - Security implementation
   - Shell scripting

4. **Q&A** (open-ended)
   - Be prepared to answer technical questions
   - Have specific performance metrics available if asked

## Troubleshooting Common Demo Issues

- **Network connectivity problems**: Ensure all devices are on the same network
- **Permission issues**: Verify user permissions before the demo
- **Slow performance**: Check for background processes that might impact demo
- **Media playback issues**: Test all media files before the demo

## Follow-up Materials

Have these ready to share after the demo:
- Project GitHub repository link
- Detailed cost breakdown spreadsheet
- Performance benchmarks PDF
- Technical architecture diagram
