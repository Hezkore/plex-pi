#!/bin/bash

# Forces a search for missing media in Radarr or Sonarr
#
# Start with either "--radarr/-r" or "--sonarr/-s"
# Enable this script as a crontab job every day at around 04:30
# 30 4 * * * /path/to/your/script.sh --radarr > /dev/null 2>&1
# 31 4 * * * /path/to/your/script.sh --sonarr > /dev/null 2>&1

RADARR_URL="http://localhost:7878"
RADARR_API_KEY="<YOUR_RADARR_API_KEY>"

SONARR_URL="http://localhost:8989"
SONARR_API_KEY="<YOUR_SONARR_API_KEY>"

# Function to trigger a search for missing media in Radarr
force_search_radarr() {
    curl -sX POST -H "User-Agent: BASH" -H "X-Api-Key: $RADARR_API_KEY" "$RADARR_URL/api/v3/command" -d '{"name":"moviesSearch"}'
}

# Function to trigger a search for missing media in Sonarr
force_search_sonarr() {
    curl -sX POST -H "User-Agent: BASH" -H "X-Api-Key: $SONARR_API_KEY" "$SONARR_URL/api/command" -d '{"name":"missingsearch"}'
}

main() {
    if [ "$1" == "--radarr" ] || [ "$1" == "-r" ]; then
        force_search_radarr
        echo "Forcing a search for missing media in Radarr..."
    elif [ "$1" == "--sonarr" ] || [ "$1" == "-s" ]; then
        force_search_sonarr
        echo "Forcing a search for missing media in Sonarr..."
    else
        echo "Usage: $0 --radarr or -r or $0 --sonarr or -s"
        exit 1
    fi

    echo "Search initiated."
}

main "$@"