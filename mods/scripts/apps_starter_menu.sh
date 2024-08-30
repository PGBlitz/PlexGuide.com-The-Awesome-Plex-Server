#!/bin/bash

# ANSI color codes for formatting
RED="\033[0;31m"
GREEN="\033[0;32m"
ORANGE="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No color

# Default values for personal apps configuration
DEFAULT_USER="plexguide"
DEFAULT_REPO="AppsFork"

# Function to count running Docker containers that match official app names in /pg/apps
count_docker_apps() {
    local all_running_apps=$(docker ps --format '{{.Names}}' | grep -v 'cf_tunnel')
    local official_count=0

    for app in $all_running_apps; do
        if [[ -d "/pg/apps/$app" ]]; then
            ((official_count++))
        fi
    done

    echo $official_count
}

# Function to count running Docker containers that match personal app names in /pg/p_apps
count_personal_docker_apps() {
    local all_running_apps=$(docker ps --format '{{.Names}}' | grep -v 'cf_tunnel')
    local personal_count=0

    for app in $all_running_apps; do
        if [[ -d "/pg/p_apps/$app" ]]; then
            ((personal_count++))
        fi
    done

    echo $personal_count
}

# Function to load the App Store version from the config file
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
        printf "A) App Store Version      [%s]\n" "$appstore_version"
    elif [ "$appstore_version" == "None" ]; then
        printf "A) App Store Version      [%s]\n" "$appstore_version"
    else
        printf "A) App Store Version      [%s]\n" "$appstore_version"
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

# Function to create /pg/personal_configs/ directory if it doesn't exist
setup_personal_configs_directory() {
    local config_dir="/pg/personal_configs"
    if [[ ! -d "$config_dir" ]]; then
        echo "Creating $config_dir directory..."
        mkdir -p "$config_dir"
        chown 1000:1000 "$config_dir"
        chmod +x "$config_dir"
        echo -e "${GREEN}Directory $config_dir created and permissions set.${NC}"
    fi
}

# Function to load personal apps configuration
load_personal_apps_config() {
    local config_file="/pg/personal_configs/personal_apps.cfg"
    if [[ -f "$config_file" ]]; then
        source "$config_file"
    else
        user=$DEFAULT_USER
        repo=$DEFAULT_REPO
    fi
}

# Main menu function
main_menu() {
  while true; do
    clear

    # Ensure /pg/apps and /pg/personal_configs directories exist with correct permissions
    ensure_apps_directory
    setup_personal_configs_directory

    # Get the number of running Docker apps, excluding cf_tunnel
    APP_COUNT=$(count_docker_apps)

    # Get the number of running personal Docker apps, excluding cf_tunnel
    P_COUNT=$(count_personal_docker_apps)

    # Load the App Store version
    load_app_store_version

    # Load personal apps configuration
    load_personal_apps_config

    # Check if the plex app directory exists
    check_plex_existence
    local plex_exists=$?

    echo -e "${BLUE}PG: Docker Apps${NC}"
    echo ""  # Blank line for separation

    echo -e "${ORANGE}Official Applications${NC}"
    # Display the App Store Version at the top
    display_app_store_version
    printf "B) Official: Manage       [%d]\n" "$APP_COUNT"
    printf "C) Official: Deploy\n"
    echo ""  # Space for separation

    echo -e "${RED}Personal Applications${NC}"
    printf "P) Personal:              [%s/%s]\n" "$user" "$repo"
    printf "Q) Personal: Manage       [%d]\n" "$P_COUNT"
    printf "R) Personal: Deploy Apps\n"
    echo ""  # Space between options and input prompt

    # Display the prompt with colors and capture user input
    echo -e "Make a Selection or type [${GREEN}Z${NC}] to Exit: \c"
    read -r choice

    case $choice in
      B|b)
        if [[ $plex_exists -eq 1 ]]; then
            echo -e "${RED}Option B is not available. Please select an App Store version first.${NC}"
            read -p "Press Enter to continue..."
        else
            bash /pg/scripts/running.sh
        fi
        ;;
      C|c)
        if [[ $plex_exists -eq 1 ]]; then
            echo -e "${RED}Option C is not available. Please select an App Store version first.${NC}"
            read -p "Press Enter to continue..."
        else
            bash /pg/scripts/deployment.sh
        fi
        ;;
      A|a)
        bash /pg/scripts/apps_version.sh
        ;;
      P|p)
        bash /pg/scripts/apps_personal_select.sh
        ;;
      Q|q)
        bash /pg/scripts/apps_personal_view.sh
        ;;
      R|r)
        bash /pg/scripts/apps_personal_deployment.sh
        ;;
      Z|z)
        exit 0
        ;;
      *)
        echo -e "${RED}Invalid option, please try again.${NC}"
        read -p "Press Enter to continue..."
        ;;
    esac
  done
}

# Call the main menu function
main_menu
