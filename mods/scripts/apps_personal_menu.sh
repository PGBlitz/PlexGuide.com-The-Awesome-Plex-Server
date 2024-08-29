#!/bin/bash

# ANSI color codes for formatting
RED="\033[0;31m"
GREEN="\033[0;32m"
ORANGE="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No color

# Default values for personal apps configuration
DEFAULT_USER="Admin9705"
DEFAULT_REPO="apps"

# Function to load personal apps configuration
load_personal_apps_config() {
    local config_file="/pg/config/personal_apps.cfg"
    if [[ -f "$config_file" ]]; then
        source "$config_file"
    else
        user=$DEFAULT_USER
        repo=$DEFAULT_REPO
    fi
}

# Function to display the main personal apps menu
display_personal_menu() {
    clear
    echo -e "${BLUE}Personal App Interface [$status]${NC}"
    echo ""  # Blank line for separation

    echo -e "P) Personal: [${GREEN}${user}/${repo}${NC}]"
    echo ""
    echo -e "M) Personal: Manage Apps"
    echo -e "D) Personal: Deploy Apps"
    echo -e "Z) Exit"
    echo ""  # Space between options and input prompt
}

# Main logic
while true; do
    # Load the personal apps configuration
    load_personal_apps_config

    # Display the main menu
    display_personal_menu

    # Prompt the user for input
    read -p "Enter your choice: " choice

    case $choice in
        P|p)
            # Execute the script to view personal apps
            bash /pg/scripts/apps_personal_select.sh
            ;;
        M|m)
            # Execute the script to view personal apps
            bash /pg/scripts/apps_personal_view.sh
            ;;
        D|d)
            # Execute the script to deploy personal apps
            bash /pg/scripts/apps_personal_deploy.sh
            ;;
        Z|z)
            # Exit the script
            exit 0
            ;;
        *)
            # Handle invalid input
            echo "Invalid option, please try again."
            read -p "Press Enter to continue..."
            ;;
    esac
done