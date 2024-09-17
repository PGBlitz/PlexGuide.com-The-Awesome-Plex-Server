#!/bin/bash

# Path to sync script
SYNC_SCRIPT="/pg/scripts/trakt/sync.sh"

# Path to config file
CONFIG_FILE="/pg/config/trakt.cfg"

# Load the configuration file
source "$CONFIG_FILE"

# Handle API options (for example, syncing movies/shows)
case $1 in
    sync_movies)
        bash "$SYNC_SCRIPT" movies
        ;;
    sync_shows)
        bash "$SYNC_SCRIPT" shows
        ;;
    *)
        echo "Invalid option. Use: sync_movies or sync_shows"
        ;;
esac
