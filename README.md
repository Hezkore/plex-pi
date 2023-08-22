# Raspberry Pi4 - Plex setup

This repository contains a script for setting up a media server on your Raspberry Pi4. The script installs and configures the following applications:

- [Plex](https://www.plex.tv/)
- [Sonarr](https://sonarr.tv/)
- [Radarr](https://radarr.video/)
- [Prowlarr](https://github.com/Prowlarr/Prowlarr)
- [qBittorrent](https://www.qbittorrent.org/)
- [Fail2Ban](https://www.fail2ban.org/)

## Prerequisites

Before running the script, you will need:

- A Raspberry Pi4 running [Raspberry Pi OS](https://www.raspberrypi.org/software/) _(tested on 64-bit)_
- An internet connection
- Sudo privileges

## Installation

To start the installation, follow these steps:

1. Clone or download this repository to your Raspberry Pi4.
2. Open a terminal and navigate to the cloned repository.
3. Run the following command to make the script executable: `chmod +x setup.sh`
4. Run the script with sudo privileges: `sudo ./setup.sh`

## Tips

The `scripts` folder contains some useful scripts for managing the applications. These scripts are not installed by default, but can be run via cronjobs or manually.

Plex stores its metadata in `/var/lib/plexmediaserver/Library/Application Support/Plex Media Server`. This folder can be symlinked to an external drive to save space on the root partition. Just make sure to stop the Plex service first, then copy the folder to the external drive and symlink it back to the original location.
1. `sudo systemctl stop plexmediaserver`
2. Replace <external_path> - `sudo mv /var/lib/plexmediaserver/Library/Application\ Support/Plex\ Media\ Server /<external_path>/plexmediaserver`
3. Replace <external_path> - `sudo ln -s /<external_path>/plexmediaserver /var/lib/plexmediaserver/Library/Application\ Support/Plex\ Media\ Server`
4. Reboot or call `sudo systemctl start plexmediaserver`

You can verify that the symlink is working with - `ls -l /var/lib/plexmediaserver/Library/Application\ Support/Plex\ Media\ Server`