#!/bin/bash

# Remove torrents active for more than a specified time from qBittorrent
#
# Run with "--time/-t" to set time threshold in hours, defaults to 6
# Enable this script as a crontab job every hour:
# 0 * * * * /path/to/your/script.sh > /dev/null 2>&1

QB_URL="http://localhost:8080"
QB_USERNAME="<YOUR_QBITTORRENT_USERNAME>"
QB_PASSWORD="<YOUR_QBITTORRENT_PASSWORD>"
DEFAULT_THRESHOLD=6  # Default time threshold in hours

# Fetch list of torrents from qBittorrent Web API
fetch_qb_torrents() {
    curl -sX GET "$QB_URL/api/v2/torrents/info?filter=active" -u "$QB_USERNAME:$QB_PASSWORD"
}

# Remove a torrent from qBittorrent Web API by its hash
remove_qb_torrent() {
    curl -sX POST "$QB_URL/api/v2/torrents/delete?hashes=$1" -u "$QB_USERNAME:$QB_PASSWORD"
}

main() {
    torrents=$(fetch_qb_torrents)

    if [ -z "$torrents" ]; then
        echo "No active torrents found."
        exit 0
    fi
	
    time_threshold=${DEFAULT_THRESHOLD}
    while [ "$#" -gt 0 ]; do
        case $1 in
            -t|--time) time_threshold="$2"; shift; shift ;;
            *) echo "Unknown parameter: $1"; exit 1 ;;
        esac
    done
	
    total_torrents=$(echo "$torrents" | wc -l)
    removed=0
    while IFS= read -r torrent_info; do
        hash=$(echo "$torrent_info" | cut -d'"' -f4)
        state=$(echo "$torrent_info" | cut -d',' -f6)
        active_seconds=$(echo "$torrent_info" | awk -F',' '{ print $13 }')

        # Convert active seconds to hours
        active_hours=$((active_seconds / 3600))

        if [[ "$active_hours" -ge "$time_threshold" && "$state" != "\"completed\"" ]]; then
            echo "Removing torrent with hash $hash (active for $active_hours hours)"
            remove_qb_torrent "$hash"
            removed=$((removed + 1))
        fi
    done <<< "$torrents"

    if [ $removed -gt 0 ]; then
        echo "Removed $removed torrents active for more than $time_threshold hours."
    else
        echo "No torrents were removed."
    fi

    echo "Total active torrents: $total_torrents"
}

if ! main "$@"; then
    echo "Error: Authentication failure. Please check your username and password."
fi