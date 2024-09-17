#!/bin/bash

CONFIG_FILE="/pg/config/trakt.cfg"

# Ensure the .cfg file exists
initialize_cfg_file() {
  if [ ! -f "$CONFIG_FILE" ]; then
    echo "Initializing configuration file: $CONFIG_FILE"
    touch "$CONFIG_FILE"
  fi
}

# Helper function to update or add values in the .cfg file
update_cfg() {
  local key="$1"
  local value="$2"
  
  if grep -q "^$key=" "$CONFIG_FILE"; then
    sed -i "s|^$key=.*|$key=$value|" "$CONFIG_FILE"
  else
    echo "$key=$value" >> "$CONFIG_FILE"
  fi
}

# Display main menu for configuration
show_config_menu() {
  echo "Interactive Config Editor"
  echo "1) Configure Trakt"
  echo "2) Configure Radarr"
  echo "3) Configure Sonarr"
  echo "4) Configure Filters (Movies)"
  echo "5) Configure Filters (Shows)"
  echo "6) Exit"
  
  read -p "Select an option: " opt
  case $opt in
    1) configure_trakt ;;
    2) configure_radarr ;;
    3) configure_sonarr ;;
    4) configure_filters_movies ;;
    5) configure_filters_shows ;;
    6) exit ;;
    *) echo "Invalid option. Try again."; show_config_menu ;;
  esac
}

# Trakt configuration
configure_trakt() {
  read -p "Enter Trakt client_id: " TRAKT_CLIENT_ID
  read -p "Enter Trakt client_secret: " TRAKT_CLIENT_SECRET
  update_cfg "trakt_client_id" "$TRAKT_CLIENT_ID"
  update_cfg "trakt_client_secret" "$TRAKT_CLIENT_SECRET"
  echo "Trakt configuration updated."
  show_config_menu
}

# Radarr configuration
configure_radarr() {
  read -p "Enter Radarr API key: " RADARR_API_KEY
  read -p "Enter Radarr URL (default: http://localhost:7878): " RADARR_URL
  read -p "Enter Radarr root folder (default: /movies/): " RADARR_ROOT
  read -p "Enter Radarr quality profile (default: HD-1080p): " RADARR_QUALITY
  read -p "Enter minimum availability (default: released): " RADARR_AVAILABILITY
  RADARR_URL=${RADARR_URL:-"http://localhost:7878"}
  RADARR_ROOT=${RADARR_ROOT:-"/movies/"}
  RADARR_QUALITY=${RADARR_QUALITY:-"HD-1080p"}
  RADARR_AVAILABILITY=${RADARR_AVAILABILITY:-"released"}
  update_cfg "radarr_api_key" "$RADARR_API_KEY"
  update_cfg "radarr_url" "$RADARR_URL"
  update_cfg "radarr_root_folder" "$RADARR_ROOT"
  update_cfg "radarr_quality" "$RADARR_QUALITY"
  update_cfg "radarr_min_availability" "$RADARR_AVAILABILITY"
  echo "Radarr configuration updated."
  show_config_menu
}

# Sonarr configuration
configure_sonarr() {
  read -p "Enter Sonarr API key: " SONARR_API_KEY
  read -p "Enter Sonarr URL (default: http://localhost:8989): " SONARR_URL
  read -p "Enter Sonarr root folder (default: /tv/): " SONARR_ROOT
  read -p "Enter Sonarr quality profile (default: HD-1080p): " SONARR_QUALITY
  read -p "Enter Sonarr language (default: English): " SONARR_LANGUAGE
  read -p "Enable season folder? (true/false) (default: true): " SONARR_SEASON_FOLDER
  SONARR_URL=${SONARR_URL:-"http://localhost:8989"}
  SONARR_ROOT=${SONARR_ROOT:-"/tv/"}
  SONARR_QUALITY=${SONARR_QUALITY:-"HD-1080p"}
  SONARR_LANGUAGE=${SONARR_LANGUAGE:-"English"}
  SONARR_SEASON_FOLDER=${SONARR_SEASON_FOLDER:-true}
  update_cfg "sonarr_api_key" "$SONARR_API_KEY"
  update_cfg "sonarr_url" "$SONARR_URL"
  update_cfg "sonarr_root_folder" "$SONARR_ROOT"
  update_cfg "sonarr_quality" "$SONARR_QUALITY"
  update_cfg "sonarr_language" "$SONARR_LANGUAGE"
  update_cfg "sonarr_season_folder" "$SONARR_SEASON_FOLDER"
  echo "Sonarr configuration updated."
  show_config_menu
}

# Initialize the config file and show the config menu
initialize_cfg_file
show_config_menu
