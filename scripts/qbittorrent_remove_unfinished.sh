#!/bin/bash

# Remove torrents active for more than a specified time from qBittorrent
#
# Run with "--time/-t" to set time threshold in hours, defaults to 6
# Enable this script as a crontab job every hour:
# 0 * * * * /path/to/your/script.sh --username=<YOUR_QBITTORRENT_USERNAME> --password=<YOUR_QBITTORRENT_PASSWORD> > /dev/null 2>&1

QB_URL="http://localhost:8080"
DEFAULT_THRESHOLD=6

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
		time_threshold="${i#*=}"
		shift
		;;
		*)
		echo "Unknown parameter: $1"
		exit 1
		;;
	esac
done

if [ -z "$time_threshold" ]; then
	time_threshold=$DEFAULT_THRESHOLD
fi

if [ -z "$QB_USERNAME" ] || [ -z "$QB_PASSWORD" ]; then
	echo "Please provide qBittorrent username and password."
	exit 1
fi

fetch_qb_torrents() {
	curl -sX GET "$QB_URL/api/v2/torrents/info?filter=all" -u "$QB_USERNAME:$QB_PASSWORD"
}

remove_qb_torrent() {
 	response=$(curl -sX GET "$QB_URL/api/v2/torrents/delete?hashes=$1&deleteFiles=true" -u "$QB_USERNAME:$QB_PASSWORD")
}

echo "Fetching active torrents..."
torrents=$(fetch_qb_torrents)

if [ -z "$torrents" ]; then
	echo "No active torrents found."
	exit 0
fi

#echo "Torrents: $torrents"
# Loop thorugh each torrent
echo "Removing torrents active for more than $time_threshold hours..."
echo "$torrents" | jq -r '.[] | "\(.name),\(.added_on),\(.hash),\(.state)"' |
while IFS=',' read -r name added_on hash state; do
	# Process each torrent
	#echo "Processing torrent: $name"
	#echo "State: $state"
	timestamp=$(date +%s)
	
	# Calculate the time difference in hours
	time_diff=$(( (timestamp - added_on) / 3600 ))
	
	# Reomve any stalled torrents
	if [ "$state" == "stalledUP" ] || [ "$state" == "stalledDL" ]; then
		echo "Removing (stalled) $name"
	  	remove_qb_torrent $hash
		#removed_count=$((removed_count+1))
		continue
	fi
	
	# Remove any torrents that meet our time threshold
	if [ $time_diff -ge $time_threshold ]; then
		echo "Removing (time) $name"
	  	remove_qb_torrent $hash
		#removed_count=$((removed_count+1))
		continue
	fi
done

#echo "Removed $removed_count torrents."