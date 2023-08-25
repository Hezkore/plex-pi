#!/bin/bash

# Removes any unmonitored Radarr movies, both from disk and database
#
# Set Radarr to only unmonitor movies not in any list, and remove empty folders
# Enable this script as a crontab job at Monday 5 in the morning:
# 0 5 * * 1 /path/to/your/script.sh --key=<YOUR_RADARR_API_KEY> > /dev/null 2>&1

HOST="http://localhost:7878"
API_KEY=""

# Fetch movie data from Radarr API
fetch_radarr_movies() {
	curl -sH "User-Agent: BASH" -H "X-Api-Key: $API_KEY" "$HOST/api/v3/movie"
}

# Delete a movie from Radarr database
delete_movie_from_database() {
	curl -sX DELETE -H "User-Agent: BASH" -H "X-Api-Key: $API_KEY" "$HOST/api/v3/movie/$1"
}

# Delete a movie file from drive
delete_movie_from_drive() {
	curl -sX DELETE -H "User-Agent: BASH" -H "X-Api-Key: $API_KEY" "$HOST/api/v3/moviefile/$1"
}

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

	json=$(fetch_radarr_movies)

	# Check if JSON response is empty
	if [ -z "$json" ]; then
		echo "Error: Unable to fetch movie data from Radarr API."
		exit 1
	fi

	removed=0
	total_movies=$(jq '. | length' <<< "$json") # Total number of movies

	# Loop through each movie in JSON
	for i in $(seq 0 $(($total_movies - 1))); do
		monitored=$(jq -r ".[$i].monitored" <<< "$json")
		in_lists=$(jq -r ".[$i].inLists" <<< "$json")
		path=$(jq -r ".[$i].path" <<< "$json")
		id=$(jq -r ".[$i].id" <<< "$json")
		title=$(jq -r ".[$i].title" <<< "$json")

		if [ "$monitored" == "false" ] && [ "$in_lists" == "[]" ]; then
			echo "Removing $title..."
			delete_movie_from_database "$id"
			delete_movie_from_drive "$id"
			removed=$((removed + 1))
			if [ -d "$path" ]; then
				rmdir "$path"
			fi
		fi
	done

	echo "Removed $removed unmonitored movies."
}

main "$@"