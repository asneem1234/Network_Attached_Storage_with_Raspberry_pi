# Smart Home Media Server Setup with AI Organization

This guide will walk you through setting up the Raspberry Pi NAS as an intelligent home media server using Jellyfin integrated with our AI file sorting system.

## Overview

The Smart Home Media Server demo showcases how a family can store, automatically organize, and stream their entire media collection (movies, TV shows, music, and photos) to any device in the house without relying on subscription services or internet connectivity. The AI file sorting system eliminates the need for manual organization, automatically categorizing media files based on content analysis.

## Prerequisites

- Raspberry Pi NAS with Jellyfin installed (using `web_interface.sh`)
- At least 500GB of free storage space
- Sample media files (movies, TV shows, music)
- Client devices (Smart TV, tablets, phones, computers)

## Setup Instructions

### 1. AI Media Organization Setup

Configure the AI file sorting system to handle media files intelligently:

```bash
# Log in to your Raspberry Pi NAS
ssh pi@<NAS-IP-ADDRESS>

# Ensure the AI file sorting service is running
sudo systemctl status file_sorter

# Create symbolic links to connect AI-sorted content with media directories
sudo ln -s /mnt/nasdata/videos /mnt/nasdata/media/movies
sudo ln -s /mnt/nasdata/videos/tv_shows /mnt/nasdata/media/tvshows
sudo ln -s /mnt/nasdata/audio /mnt/nasdata/media/music
sudo ln -s /mnt/nasdata/images /mnt/nasdata/media/photos
```

### 2. Media Transfer with AI Sorting

Simply transfer your media to the "incoming" folder and let the AI system organize it automatically:

```bash
# For Linux/macOS, use scp:
scp /path/to/mixed_media/* pi@<NAS-IP-ADDRESS>:/mnt/nasdata/incoming/

# For Windows, use Windows File Explorer to copy files to:
# \\<NAS-IP-ADDRESS>\Incoming
```

The AI sorting system will:
1. Analyze each file and determine its type
2. For video files: 
   - Detect if it's a movie or TV show
   - Extract metadata like title, year, and episode info when available
   - Place it in the appropriate category with proper naming
3. For music files:
   - Extract artist and album information from ID3 tags when available
   - Organize by artist/album structure
4. For photos:
   - Analyze content to detect scenes, people, or events
   - Organize chronologically and by content type

### 3. Jellyfin Configuration

1. Access the Jellyfin web interface:
   - Open a web browser and navigate to `http://<NAS-IP-ADDRESS>:8096`

2. Complete the initial setup:
   - Create an admin user when prompted
   - Add your media libraries:
     - Select "Add Media Library"
     - Choose the appropriate content type (Movies, TV Shows, etc.)
     - Select the corresponding folder
     - Enable "Scan for new files automatically"

3. Configure remote access (optional):
   - Go to Admin > Dashboard > Networking
   - Enable remote access if you want to access media outside your home network

4. Configure transcoding settings:
   - Go to Admin > Dashboard > Playback
   - Adjust transcoding settings based on your Raspberry Pi's capabilities
   - Enable hardware acceleration if available

### 4. Client Setup

Install Jellyfin clients on your devices:

1. Smart TVs:
   - Most modern smart TVs have Jellyfin apps available in their app stores
   - For older TVs, use DLNA or a streaming stick

2. Mobile Devices:
   - Android: Install "Jellyfin for Android" from Google Play Store
   - iOS: Install "Jellyfin Mobile" from App Store

3. Computers:
   - Use any web browser to access `http://<NAS-IP-ADDRESS>:8096`
   - Alternatively, install Jellyfin Desktop or use VLC as a DLNA client

4. Configure each client:
   - Enter your server address: `http://<NAS-IP-ADDRESS>:8096`
   - Log in with your credentials

## Demo Preparation

1. Prepare sample content that will play smoothly on your network
2. Create different user accounts for family members with customized libraries
3. Set up parental controls for children's accounts
4. Prepare a comparison chart showing costs vs. commercial alternatives

## Performance Optimization

If you experience performance issues:

1. Lower transcoding quality for remote devices
2. Use direct play whenever possible (use media formats natively supported by clients)
3. Limit the number of simultaneous streams
4. Consider overclocking your Raspberry Pi if advanced cooling is installed

## Cost Savings Analysis

| Expense | Commercial NAS + Plex | Cloud Streaming Services | Our Raspberry Pi NAS |
|---------|----------------------|-------------------------|----------------------|
| Initial Hardware | ₹15,000-30,000 | ₹0 | ₹5,820 |
| Software License | ₹3,500 (Plex Lifetime) | ₹0 | ₹0 |
| Monthly Subscription | ₹0 | ₹500-1,500/month | ₹0 |
| Storage Expansion | ₹800/TB | Not applicable | ₹800/TB |
| 5-Year Total Cost | ₹18,500-33,500 | ₹30,000-90,000 | ₹5,820 |

## Troubleshooting

- **Buffering issues**: Check network bandwidth and transcoding settings
- **Missing metadata**: Ensure proper naming conventions are followed
- **Authentication problems**: Verify user permissions and passwords
- **Transcoding failures**: Check CPU usage and consider lower quality settings
