#!/bin/bash

# Removes any unmonitored Radarr movies, both from disk and database
#
# Set Radarr to only unmonitor movies not in any list, and remove empty folders
# Enable this script as a crontab job at Monday 5 in the morning:
# 0 5 * * 1 /path/to/your/script.sh --key=<YOUR_RADARR_API_KEY> > /dev/null 2>&1

HOST="http://localhost:7878"
API_KEY=""

main() {
	for i in "$@"
	do
		case $i in
			--key=*)
			API_KEY="${i#*=}"
			shift
			;;
		esac
	done
	
	if [ -z "$API_KEY" ]; then
		echo "Error: API key is missing. Usage: $0 --key=<YOUR_RADARR_API_KEY>"
		exit 1
	fi
	
	echo "Fetching unmonitored movies..."
	ids=$(curl --silent $HOST/api/v3/movie -X GET -H "X-Api-Key: $API_KEY" \
		| jq '[.[] | select(.monitored == false) | {id: .id, file_id: .movieFile.id}]')

	total=$(echo $ids | jq length)
	echo "Removing $total unmonitored movies..."
	removed=0
	for id in $(echo $ids | jq -r '.[] | @json'); do
		_jq() {
			echo ${id} | jq -r ${1}
		}
		movie_id=$(_jq '.id')
		file_id=$(_jq '.file_id')
		echo "Movie $removed out of $total"
		# Only if file_id is above 0
		if [ ! -z "$file_id" ] && [ "$file_id" != "null" ] && [ $file_id -gt 0 ]; then
			echo "Deleting from drive via ID $file_id" 
			curl -sX DELETE -H "User-Agent: BASH" -H "X-Api-Key: $API_KEY" "$HOST/api/v3/moviefile/$file_id"
		fi
		echo "Deleting from database via ID $movie_id"
		curl -sX DELETE -H "User-Agent: BASH" -H "X-Api-Key: $API_KEY" "$HOST/api/v3/movie/$movie_id"
		removed=$((removed+1))
	done

	echo "Removed $removed unmonitored movies."
}

main "$@"