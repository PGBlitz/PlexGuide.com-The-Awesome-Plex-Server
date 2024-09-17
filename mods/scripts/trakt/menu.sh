#!/bin/bash

# Path to API script and config script
API_SCRIPT="/pg/scripts/trakt/api.sh"
CONFIG_SCRIPT="/pg/scripts/trakt/config.sh"  # New path for configuration script

# Display main menu
show_menu() {
  clear
  echo "Welcome to TraktPG"
  echo "1) Sync Movies (Trakt -> Radarr)"
  echo "2) Sync Shows (Trakt -> Sonarr)"
  echo "3) Configure TraktPG (Trakt, Radarr, Sonarr)"
  echo "4) Exit"
  
  read -p "Choose an option: " opt
  case $opt in
    1) bash "$API_SCRIPT" sync_movies ;;
    2) bash "$API_SCRIPT" sync_shows ;;
    3) bash "$CONFIG_SCRIPT" ;;  # Open the configuration script
    4) exit ;;
    *) echo "Invalid option, please try again."; show_menu ;;
  esac
}

# Loop through the menu
while true; do
  show_menu
done
