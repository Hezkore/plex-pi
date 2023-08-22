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

## Useful scripts

This repository also contains a couple of useful scripts in the `scripts` folder.