#!/bin/bash

CONFIG_FILE="/pg/config/trakt.cfg"
LOG_DIR="/pg/logs/traktpg"
LOG_FILE="$LOG_DIR/sync.log"

# Ensure the log directory exists
initialize_log() {
  if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
    echo "$(date): Created log directory at $LOG_DIR" >> "$LOG_FILE"
  fi
}

# Log message function
log_message() {
  echo "$(date): $1" | tee -a "$LOG_FILE"
}

# Load API keys and settings from config file
source "$CONFIG_FILE"

# Function to sync Trakt shows with Sonarr
sync_trakt_to_sonarr() {
    log_message "Starting sync with Trakt.tv for shows..."
    
    # Variables for pagination and total items to fetch
    page=1
    limit=10
    total_fetched=0
    max_shows=10000  # Limit to 10,000 shows

    while [ $total_fetched -lt $max_shows ]; do
        log_message "Fetching page $page with $limit shows per page..."

        # Fetch popular shows from Trakt.tv with pagination
        shows=$(curl -s "https://api.trakt.tv/shows/popular?page=$page&limit=$limit" \
            -H "Content-Type: application/json" \
            -H "trakt-api-key: $trakt_client_id" \
            -H "trakt-api-version: 2" | jq -r '.[] | {title, year, ids} | @base64')

        # If no shows are fetched, exit
        if [ -z "$shows" ]; then
            log_message "No more shows fetched from Trakt.tv."
            break
        fi

        # Process each show
        for show in $shows; do
            _jq() {
                echo $show | base64 --decode | jq -r ${1}
            }

            title=$(_jq '.title')
            tvdbId=$(_jq '.ids.tvdb')
            year=$(_jq '.year')

            log_message "Adding show: $title ($year) to Sonarr"

            # Send show to Sonarr
            curl -X POST "$sonarr_url/api/v3/series" \
              -H "X-Api-Key: $sonarr_api_key" \
              -H "Content-Type: application/json" \
              -d "{
                \"title\": \"$title\",
                \"qualityProfileId\": 1,
                \"tvdbId\": $tvdbId,
                \"year\": $year,
                \"rootFolderPath\": \"$sonarr_root_folder\",
                \"seasonFolder\": $sonarr_season_folder,
                \"monitored\": true
              }" >> "$LOG_FILE" 2>&1

            ((total_fetched+=1))
        done

        log_message "Fetched $total_fetched shows so far."

        # Increment the page number for the next request
        ((page+=1))

        # Delay 1 second between each request to be API compliant
        sleep 1
    done

    log_message "Sync with Sonarr completed."
}

# Initialize log directory
initialize_log

# Run the sync based on argument
case $1 in
    shows)
        sync_trakt_to_sonarr
        ;;
    *)
        log_message "Invalid argument. Use: shows"
        ;;
esac
