# Home Media Server Setup

This guide will walk you through setting up the Raspberry Pi NAS as a comprehensive home media server using Jellyfin.

## Overview

The Home Media Server demo showcases how a family can store, organize, and stream their entire media collection (movies, TV shows, music, and photos) to any device in the house without relying on subscription services or internet connectivity.

## Prerequisites

- Raspberry Pi NAS with Jellyfin installed (using `web_interface.sh`)
- At least 500GB of free storage space
- Sample media files (movies, TV shows, music)
- Client devices (Smart TV, tablets, phones, computers)

## Setup Instructions

### 1. Media Organization

Create an organized folder structure for your media:

```bash
# Log in to your Raspberry Pi NAS
ssh pi@<NAS-IP-ADDRESS>

# Create the media directory structure
sudo mkdir -p /mnt/nasdata/media/{movies,tvshows,music,photos}
sudo chmod -R 775 /mnt/nasdata/media
sudo chown -R pi:pi /mnt/nasdata/media
```

### 2. Media Transfer

Transfer your sample media to the appropriate folders:

```bash
# For Linux/macOS, use scp:
scp /path/to/movie.mp4 pi@<NAS-IP-ADDRESS>:/mnt/nasdata/media/movies/

# For Windows, use Windows File Explorer to copy files to:
# \\<NAS-IP-ADDRESS>\media\movies
```

Organize content following these conventions:
- Movies: `/movies/MovieName (Year)/MovieName (Year).mp4`
- TV Shows: `/tvshows/ShowName/Season XX/ShowName - SXXEXX - Episode Title.mp4`
- Music: `/music/Artist/Album/XX - Song Title.mp3`

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
