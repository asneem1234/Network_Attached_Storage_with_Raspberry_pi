# Instructions for Pushing to GitHub

## Option 1: Using Git with Personal Access Token

1. **Create a Personal Access Token (PAT) on GitHub:**
   - Go to GitHub.com and log in
   - Click on your profile picture in the top right corner
   - Go to Settings
   - Scroll down to Developer settings (near the bottom of the left sidebar)
   - Select "Personal access tokens" and then "Tokens (classic)"
   - Click "Generate new token" and select "Generate new token (classic)"
   - Give your token a descriptive name (e.g., "RaspberryPi-NAS-Project")
   - Select the scopes/permissions needed (at minimum "repo" for repository access)
   - Click "Generate token"
   - Copy the token immediately (it won't be shown again)

2. **Push to GitHub:**
   ```powershell
   cd d:\ecs2\raspberry-pi-nas
   git push -u origin main
   ```
   
   When prompted for credentials:
   - For username, enter your GitHub username
   - For password, paste your personal access token

## Option 2: Using GitHub Desktop

If you prefer a graphical interface:

1. **Install GitHub Desktop** from https://desktop.github.com/

2. **Add the local repository:**
   - Open GitHub Desktop
   - Select File > Add Local Repository
   - Browse to `d:\ecs2\raspberry-pi-nas`
   - Click "Add Repository"

3. **Publish to GitHub:**
   - Click "Publish repository" button
   - Enter repository details:
     - Name: ecs2
     - Description: Network Attached Storage (NAS) Implementation using Raspberry Pi - Engineering Clinics 2 Project
     - Keep the code private (optional)
   - Click "Publish Repository"

## Option 3: Creating a New Repository Manually

1. **Create a New Repository on GitHub:**
   - Go to https://github.com/new
   - Repository name: ecs2
   - Description: Network Attached Storage (NAS) Implementation using Raspberry Pi - Engineering Clinics 2 Project
   - Choose public or private
   - Do NOT initialize with README, .gitignore, or license
   - Click "Create repository"

2. **Push the Existing Repository from the Command Line:**
   ```powershell
   cd d:\ecs2\raspberry-pi-nas
   git remote add origin https://github.com/asneem1234/ecs2.git
   git push -u origin main
   ```
   
   When prompted for credentials:
   - For username, enter your GitHub username
   - For password, paste your personal access token

3. **Store Credentials in Git Credential Manager (Optional):**
   ```powershell
   git config --global credential.helper manager
   ```
   
   This will store your credentials securely so you don't have to enter them each time.

## After Pushing to GitHub

Once your code is on GitHub, you can:

1. Enable GitHub Pages to create a website for your project documentation
2. Add other team members as collaborators
3. Create issues for future enhancements
4. Set up workflows for continuous integration
