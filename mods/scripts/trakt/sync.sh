#!/bin/bash

CONFIG_FILE="/pg/config/trakt.cfg"

# Load API keys from config file
source "$CONFIG_FILE"

# Function to sync Trakt movies with Radarr
sync_trakt_to_radarr() {
    echo "Fetching popular movies from Trakt.tv..."
    movies=$(curl -s "https://api.trakt.tv/movies/popular" \
        -H "Content-Type: application/json" \
        -H "trakt-api-key: $trakt_client_id" \
        -H "trakt-api-version: 2" | jq -r '.[] | {title, year, ids} | @base64')

    echo "Adding movies to Radarr..."
    for movie in $movies; do
        _jq() {
            echo $movie | base64 --decode | jq -r ${1}
        }

        title=$(_jq '.title')
        tmdbId=$(_jq '.ids.tmdb')
        year=$(_jq '.year')

        # Send movie to Radarr
        curl -X POST "$radarr_url/api/v3/movie" \
          -H "X-Api-Key: $radarr_api_key" \
          -H "Content-Type: application/json" \
          -d "{
            \"title\": \"$title\",
            \"qualityProfileId\": 1,
            \"tmdbId\": $tmdbId,
            \"year\": $year,
            \"rootFolderPath\": \"/movies/\",
            \"monitored\": true
          }"
    done
}

# Function to sync Trakt shows with Sonarr
sync_trakt_to_sonarr() {
    echo "Fetching popular shows from Trakt.tv..."
    shows=$(curl -s "https://api.trakt.tv/shows/popular" \
        -H "Content-Type: application/json" \
        -H "trakt-api-key: $trakt_client_id" \
        -H "trakt-api-version: 2" | jq -r '.[] | {title, year, ids} | @base64')

    echo "Adding shows to Sonarr..."
    for show in $shows; do
        _jq() {
            echo $show | base64 --decode | jq -r ${1}
        }

        title=$(_jq '.title')
        tvdbId=$(_jq '.ids.tvdb')
        year=$(_jq '.year')

        # Send show to Sonarr
        curl -X POST "$sonarr_url/api/v3/series" \
          -H "X-Api-Key: $sonarr_api_key" \
          -H "Content-Type: application/json" \
          -d "{
            \"title\": \"$title\",
            \"qualityProfileId\": 1,
            \"tvdbId\": $tvdbId,
            \"year\": $year,
            \"rootFolderPath\": \"/tv/\",
            \"seasonFolder\": true,
            \"monitored\": true
          }"
    done
}

# Run the appropriate sync based on argument
case $1 in
    movies)
        sync_trakt_to_radarr
        ;;
    shows)
        sync_trakt_to_sonarr
        ;;
    *)
        echo "Invalid argument. Use: movies or shows"
        ;;
esac
