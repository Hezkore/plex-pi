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

* The `scripts` folder contains some useful scripts for managing the applications. These scripts are not installed by default, but can be run via cronjobs or manually.

* Plex stores its metadata in `/var/lib/plexmediaserver/Library/Application Support/Plex Media Server`. This folder can be symlinked to an external drive to save space on the root partition. Just make sure to stop the Plex service first, then copy the folder to the external drive and symlink it back to the original location.
	1. `sudo systemctl stop plexmediaserver`
	2. Replace <external_path> - `sudo mv /var/lib/plexmediaserver/Library/Application\ Support/Plex\ Media\ Server /<external_path>/plexmediaserver`
	3. Replace <external_path> - `sudo ln -s /<external_path>/plexmediaserver /var/lib/plexmediaserver/Library/Application\ Support/Plex\ Media\ Server`
	4. Reboot or call `sudo systemctl start plexmediaserver`

	You can verify that the symlink is working with - `ls -l /var/lib/plexmediaserver/Library/Application\ Support/Plex\ Media\ Server`

* I have setup Radarr to fetch movies from a number of "lists" on [Trakt](https://trakt.tv/), as well as Plex watchlists. These lists are updated automatically, and Radarr will unmonitor any movies not in a list. The script `radarr_remove_unmonitored.sh` then runs every Monday morning at 04:00 to remove any unmonitored movies, both from disk and Radarr itself. Every day at around 01:30 the `radarr_sonarr_search_missing.sh` script runs to make sure all movies and TV shows are fetched. Plex is also set to run its Scheduled Tasks at 05:00, where it generates all the media information, such as intro and credit markers, as well as preview and chapter thumbnails. The script `qbittorrent_remove_unfinished.sh` is set to run every hour.