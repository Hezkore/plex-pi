#!/bin/bash

# Forces a search for missing media in Radarr or Sonarr
#
# Start with either "--radarr/-r" or "--sonarr/-s" and the API key "--key=<RADARR/SONARR_API_KEY>"
# Enable this script as a crontab job every day at around 05:00
# 0 5 * * * /path/to/your/script.sh --radarr --key=<YOUR_RADARR_API_KEY> > /dev/null 2>&1
# 5 5 * * * /path/to/your/script.sh --sonarr --key=<YOUR_SONARR_API_KEY> > /dev/null 2>&1

RADARR_URL="http://localhost:7878"
SONARR_URL="http://localhost:8989"

# Function to trigger a search for missing media in Radarr
force_search_radarr() {
	curl -sX POST -H "Content-Type: application/json" -H "X-Api-Key: $API_KEY" "$RADARR_URL/api/v3/command" -d '{"name":"cutOffUnmetMoviesSearch","filterKey":"monitored","filterValue":"true"}'
	curl -sX POST -H "Content-Type: application/json" -H "X-Api-Key: $API_KEY" "$RADARR_URL/api/v3/command" -d '{"name":"missingMoviesSearch","filterKey":"status","filterValue":"released"}'
}

# Function to trigger a search for missing media in Sonarr
force_search_sonarr() {
	curl -sX POST -H "Content-Type: application/json" -H "X-Api-Key: $API_KEY" "$SONARR_URL/api/v3/command" -d '{"name":"missingEpisodeSearch","filterKey":"monitored","filterValue":"true"}'
}

main() {
	if [ "$1" == "--radarr" ] || [ "$1" == "-r" ]; then
		for i in "$@"
		do
			case $i in
				--key=*)
				API_KEY="${i#*=}"
				shift
				;;
			esac
		done
		force_search_radarr
		echo "Forcing a search for missing media in Radarr..."
	elif [ "$1" == "--sonarr" ] || [ "$1" == "-s" ]; then
		for i in "$@"
		do
			case $i in
				--key=*)
				API_KEY="${i#*=}"
				shift
				;;
			esac
		done
		force_search_sonarr
		echo "Forcing a search for missing media in Sonarr..."
	else
		echo "Usage: $0 --radarr or -r --key=<RADARR_API_KEY> or $0 --sonarr or -s --key=<SONARR_API_KEY>"
		exit 1
	fi

	echo "Search initiated."
}

main "$@"