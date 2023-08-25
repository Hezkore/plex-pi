#!/bin/bash

# Remove torrents active for more than a specified time from qBittorrent
#
# Run with "--time/-t" to set time threshold in hours, defaults to 6
# Enable this script as a crontab job every hour:
# 0 * * * * /path/to/your/script.sh --username=<YOUR_QBITTORRENT_USERNAME> --password=<YOUR_QBITTORRENT_PASSWORD> > /dev/null 2>&1

QB_URL="http://localhost:8080"
DEFAULT_THRESHOLD=6  # Default time threshold in hours

# Fetch list of torrents from qBittorrent Web API
fetch_qb_torrents() {
	curl -sX GET "$QB_URL/api/v2/torrents/info?filter=all" -u "$QB_USERNAME:$QB_PASSWORD"
}

# Remove a torrent from qBittorrent Web API by its hash
remove_qb_torrent() {
 	response=$(curl -sX GET "$QB_URL/api/v2/torrents/delete?hashes=$1&deleteFiles=true" -u "$QB_USERNAME:$QB_PASSWORD")
}

main() {
	for i in "$@"
	do
		case $i in
			--username=*)
			QB_USERNAME="${i#*=}"
			shift
			;;
			--password=*)
			QB_PASSWORD="${i#*=}"
			shift
			;;
			-t=*|--time=*)
			DEFAULT_THRESHOLD="${i#*=}"
			shift
			;;
			*)
			echo "Unknown parameter: $1"
			exit 1
			;;
		esac
	done
	
	torrents=$(fetch_qb_torrents)
	
	if [ -z "$torrents" ]; then
		echo "No active torrents found."
		exit 0
	fi
	
	time_threshold=${DEFAULT_THRESHOLD}
	
	echo "Removing torrents active for more than $time_threshold hours..."
	
	# Loop through each torrent in JSON
	while true; do
		torrents=$(fetch_qb_torrents)
		removed_count=0
		
		for i in $(jq -r '.[] | @base64' <<< "$torrents"); do
			_jq() {
				echo "${i}" | base64 --decode | jq -r "${1}"
			}
			
			added_on=$(_jq '.added_on')
			time_diff=$(( ($(date +%s) - $added_on) / 3600 ))
			
			if [ $time_diff -ge $time_threshold ] && [ $(_jq '.state') != "queuedDL" ] && [ $(_jq '.state') != "queuedUP" ]; then
				hash=$(_jq '.hash')
				name=$(_jq '.name')
				echo "Removing $name..."
				remove_qb_torrent "$hash"
				removed_count=$((removed_count+1))
			fi
		done
		
		if [ $removed_count -eq 0 ]; then
			break
		fi
	done
	
	echo "Torrent removal complete."
}

main "$@"