#!/bin/bash

# Removes any unmonitored Radarr movies, both from disk and database
#
# Set Radarr to only unmonitor movies not in any list, and remove empty folders
# Enable this script as a crontab job at Monday 5 in the morning:
# 0 5 * * 1 /path/to/your/script.sh > /dev/null 2>&1

HOST="http://localhost:7878"
API_KEY="<YOUR_RADARR_API_KEY>"

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
	json=$(fetch_radarr_movies)

	# Check if JSON response is empty
	if [ -z "$json" ]; then
		echo "Error: Unable to fetch movie data from Radarr API."
		exit 1
	fi

	removed=0
	total_movies=$(jq '. | length' <<< "$json") # Total number of movies

	# Loop through each movie in JSON
	for movie_id in $(jq -r '.[].id' <<< "$json"); do
		monitored=$(jq -r ".[] | select(.id==$movie_id).monitored" <<< "$json")
		if [ "$monitored" == "false" ]; then
			title=$(jq -r ".[] | select(.id==$movie_id).title" <<< "$json")
			echo "Deleting: $title"
			movie_file_id=$(jq -r ".[] | select(.id==$movie_id).movieFile.id" <<< "$json")

			delete_movie_from_drive "$movie_file_id"
			if [ $? -eq 0 ]; then
				delete_movie_from_database "$movie_id"
				if [ $? -eq 0 ]; then
					removed=$((removed + 1))
				else
					echo "Error: Failed to delete movie from database."
				fi
			else
				echo "Error: Failed to delete movie file from drive."
			fi
		fi
	done

	echo "Removed $removed unmonitored movies out of $total_movies total movies"
}

main