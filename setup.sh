#!/bin/bash

# Intro
clear
echo "Welcome to the Raspberry Pi4 Media Server Setup Script!"
echo "This script will help you set up Plex, Sonarr, Radarr, Prowlarr, qBittorrent and Fail2Ban on your Raspberry Pi4."
echo "Please make sure you have an active internet connection before proceeding."
echo

# Check if the version is 11 (Bullseye)
if [ "$(lsb_release -cs)" == "bullseye" ]; then
    read -p "Press Enter to continue or Ctrl+C to exit..."
else
    echo "You are using a version other than Debian 11 (Bullseye)."
    echo "Your version is $(lsb_release -d -s), which is not officially supported."
    read -p "Press Enter to continue at your own risk or Ctrl+C to exit..."
fi


# Update the system
echo
echo "Updating system..."
sudo apt update
sudo apt upgrade -y


# Install required dependencies
echo
echo "Installing dependencies..."
sudo apt install -y apt-transport-https curl gnupg


# Install Plex
echo
echo "Adding repository keys for Plex..."
curl https://downloads.plex.tv/plex-keys/PlexSign.key | gpg --dearmor | sudo tee /usr/share/keyrings/plex-archive-keyring.gpg >/dev/null

echo
echo "Adding Plex APT repository source..."
echo "deb [signed-by=/usr/share/keyrings/plex-archive-keyring.gpg] https://downloads.plex.tv/repo/deb public main" | sudo tee /etc/apt/sources.list.d/plexmediaserver.list > /dev/null

echo
echo "Updating repositories..."
sudo apt update

echo
echo "Installing Plex..."
sudo apt install -y plexmediaserver


# Install Sonarr
echo
echo "Installing Sonarr..."
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 2009837CBFFD68F45BC180471F4F90DE2A9B4BF8
echo "deb https://apt.sonarr.tv/debian buster main" | sudo tee /etc/apt/sources.list.d/sonarr.list
sudo apt update
sudo apt install -y sonarr


# Install Radarr
echo
echo "Installing Radarr..."
RADARR_URL="https://radarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=arm64"
curl -L "$RADARR_URL" | tar xz
sudo mv Radarr /opt/radarr

echo
echo "Creating a system user for Radarr..."
sudo useradd -r -s /usr/sbin/nologin radarr

echo
echo "Setting ownership and permissions for Radarr..."
sudo mkdir -p /var/lib/radarr
sudo chown -R radarr:radarr /var/lib/radarr
sudo chown -R radarr:radarr /opt/radarr

echo
echo "Setting up Radarr service..."
cat <<EOF | sudo tee /etc/systemd/system/radarr.service > /dev/null
[Unit]
Description=Radarr Daemon
After=network.target

[Service]
User=radarr
Group=radarr
Type=simple
ExecStart=/opt/radarr/Radarr -nobrowser -data=/var/lib/radarr
Restart=always

[Install]
WantedBy=default.target
EOF

sudo systemctl enable radarr.service
sudo systemctl start radarr


# Install Prowlarr
echo
echo "Installing Prowlarr..."
PROWLARR_URL="https://prowlarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=arm64"
curl -L "$PROWLARR_URL" | tar xz
sudo mv Prowlarr /opt/prowlarr

echo
echo "Creating a system user for Prowlarr..."
sudo useradd -r -s /usr/sbin/nologin prowlarr

echo
echo "Setting ownership and permissions for Prowlarr..."
sudo mkdir -p /var/lib/prowlarr
sudo chown -R prowlarr:prowlarr /var/lib/prowlarr
sudo chown -R prowlarr:prowlarr /opt/prowlarr

echo
echo "Setting up Prowlarr service..."
cat <<EOF | sudo tee /etc/systemd/system/prowlarr.service > /dev/null
[Unit]
Description=Prowlarr Daemon
After=network.target

[Service]
User=prowlarr
Group=prowlarr
Type=simple
ExecStart=/opt/prowlarr/Prowlarr -nobrowser -data=/var/lib/prowlarr
Restart=always

[Install]
WantedBy=default.target
EOF

sudo systemctl enable prowlarr.service
sudo systemctl start prowlarr


# Install qBittorrent-nox
echo
echo "Installing qBittorrent-nox..."
sudo apt install -y qbittorrent-nox
sudo adduser qbittorrent --system --no-create-home --group

echo
echo "Setting up qBittorrent service..."
cat <<EOF | sudo tee /etc/systemd/system/qbittorrent.service > /dev/null
[Unit]
Description=qBittorrent-nox
After=network.target

[Service]
Type=forking
ExecStart=/usr/bin/qbittorrent-nox -d --webui-port=8080
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable qbittorrent.service
#sudo systemctl start qbittorrent


# Install Fail2Ban
echo
echo "Installing Fail2Ban..."
sudo apt install -y fail2ban


# Reload systemd - might as well
sudo systemctl daemon-reload


# Done!
echo
echo "Setup complete!"


# Display security recommendations
clear
echo
echo "===== Security Recommendations ====="

# Check if SSH root login is allowed
if grep -q "PermitRootLogin yes" /etc/ssh/sshd_config; then
    echo "- Disable SSH root login:"
    echo "	Edit /etc/ssh/sshd_config and set 'PermitRootLogin' to 'no'"
fi

# Check if default username is 'pi'
if id pi &>/dev/null; then
    echo "- Change default username 'pi' if possible."
fi

echo "- Setting up login screens or authentication for Radarr, Sonarr and Prowlarr."
echo "- Changing default qBittorrent login admin/adminadmin"
echo "- Regularly update your system and applications to keep them secure."
echo "- Consider configuring a firewall to restrict unnecessary network access."
echo "==================================="

# Display service URLs and instructions
echo
echo "Service URLs and Instructions:"
echo "Plex: http://$(hostname -I | cut -d' ' -f1):32400/web"
echo "Radarr: http://$(hostname -I | cut -d' ' -f1):7878"
echo "Sonarr: http://$(hostname -I | cut -d' ' -f1):8989"
echo "Prowlarr: http://$(hostname -I | cut -d' ' -f1):9696"
echo "qBittorrent: Please run 'qbittorrent-nox' at least once to accept the terms and conditions."
echo "             qBittorrent will then be accessible at http://$(hostname -I | cut -d' ' -f1):8080 after reboot."