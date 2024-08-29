#!/bin/bash

# ANSI color codes for green, red, blue, and orange
GREEN="\033[0;32m"
RED="\033[0;31m"
BLUE="\033[0;34m"
ORANGE="\033[0;33m"
NC="\033[0m" # No color

# Function to count running Docker containers, excluding cf_tunnel
count_docker_apps() {
    docker ps --format '{{.Names}}' | grep -v 'cf_tunnel' | wc -l
}

# Load the App Store version from the config file
load_app_store_version() {
    if [ -f /pg/config/appstore_version.cfg ]; then
        source /pg/config/appstore_version.cfg
    else
        appstore_version="None"
    fi
}

# Function to display the App Store version with appropriate color
display_app_store_version() {
    if [ "$appstore_version" == "Alpha" ]; then
        echo -e "A) App Store Version: [${RED}$appstore_version${NC}]"
    elif [ "$appstore_version" == "None" ]; then
        echo -e "A) App Store Version: [${ORANGE}$appstore_version${NC}]"
    else
        echo -e "A) App Store Version: [${GREEN}$appstore_version${NC}]"
    fi
}

# Function to check if the plex app directory exists
check_plex_existence() {
    if [[ ! -d "/pg/apps/plex" ]]; then
        return 1  # plex does not exist
    else
        return 0  # plex exists
    fi
}

# Function to create /pg/apps directory if it does not exist
ensure_apps_directory() {
    if [[ ! -d "/pg/apps" ]]; then
        echo "Creating /pg/apps directory..."
        mkdir -p /pg/apps
        chown 1000:1000 /pg/apps
        chmod +x /pg/apps
    fi
}

# Main menu function
main_menu() {
  while true; do
    clear

    # Ensure /pg/apps directory exists with correct permissions
    ensure_apps_directory

    # Get the number of running Docker apps, excluding cf_tunnel
    APP_COUNT=$(count_docker_apps)

    # Load the App Store version
    load_app_store_version

    # Check if the plex app directory exists
    check_plex_existence
    local plex_exists=$?

    echo -e "${BLUE}PG: Docker Apps${NC}"
    echo ""  # Blank line for separation

    # Display the App Store Version at the top
    display_app_store_version
    echo ""  # Space for separation

    if [[ $plex_exists -eq 1 ]]; then
        # If plex doesn't exist, disable V and D options and show a warning
        echo -e "${RED}You need to select an App Store version.${NC}"
        echo ""  # Blank line for separation
    else
        # If plex exists, show the options V and D
        echo -e "V) Apps [${ORANGE}View${NC}] [ $APP_COUNT ]"
        echo -e "D) Apps [${ORANGE}Deploy${NC}]"
    fi

    echo "Z) Exit"
    echo ""  # Space between options and input prompt

    # Prompt the user for input
    read -p "Enter your choice: " choice

    case $choice in
      V|v)
        if [[ $plex_exists -eq 1 ]]; then
            echo -e "${RED}Option V is not available. Please select an App Store version first.${NC}"
            read -p "Press Enter to continue..."
        else
            bash /pg/scripts/running.sh
        fi
        ;;
      D|d)
        if [[ $plex_exists -eq 1 ]]; then
            echo -e "${RED}Option D is not available. Please select an App Store version first.${NC}"
            read -p "Press Enter to continue..."
        else
            bash /pg/scripts/deployment.sh
        fi
        ;;
      A|a)
        bash /pg/scripts/apps_version.sh
        ;;
      Z|z)
        exit 0
        ;;
      *)
        echo "Invalid option, please try again."
        read -p "Press Enter to continue..."
        ;;
    esac
  done
}

# Call the main menu function
main_menu
