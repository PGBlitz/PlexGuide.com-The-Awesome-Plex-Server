#!/bin/bash

# Configuration file path
CONFIG_FILE="/pg/config/config.cfg"

# ANSI color codes
RED="\033[0;31m"
NC="\033[0m" # No color

# Clear the screen at the start
clear

# Function to source the configuration file
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    else
        echo "VERSION=\"PG Alpha\"" > "$CONFIG_FILE"
        source "$CONFIG_FILE"
    fi
}

# Function for Apps Management
apps_management() {
    bash /pg/scripts/apps_starter_menu.sh
}

# Updated Function to Reinstall PlexGuide
reinstall_plexguide() {
    # Download and execute the install script from the specified URL
    curl -s https://raw.githubusercontent.com/plexguide/Installer/v11/install_menu.sh | bash
    # Alternatively, you could use wget instead of curl:
    # wget -qO- https://raw.githubusercontent.com/plexguide/Installer/v11/install_menu.sh | bash

    # Execute the exit script
    bash /pg/scripts/menu_exit.sh
    exit 0  # Ensure the script exits after executing the menu_exit.sh
}

# Function to exit the script
menu_exit() {
    bash /pg/scripts/menu_exit.sh
    exit 0  # Ensure the script exits after executing the menu_exit.sh
}

# Function for HardDisk Management
harddisk_management() {
    bash /pg/scripts/drivemenu.sh
}

# Function for CloudFlare Tunnel Management
cloudflare_tunnel() {
    bash /pg/scripts/cf_tunnel.sh
}

# Function for Options Menu
options_menu() {
    bash /pg/scripts/options.sh
}

# Main menu loop
main_menu() {
    while true; do
        clear
        echo -e "${RED}Welcome to PlexGuide: $VERSION${NC}"
        echo ""  # Blank line for separation
        echo "A) Apps Management"
        echo "H) HardDisk Management"
        echo "C) CloudFlare Tunnel (Domains)"
        echo "O) Options"
        echo "R) Reinstall PlexGuide"
        echo "Z) Exit"
        echo ""  # Space between options and input prompt

        read -p "Enter your choice: " choice

        case ${choice,,} in
            a) apps_management ;;
            h) harddisk_management ;;
            c) cloudflare_tunnel ;;
            r) reinstall_plexguide ;;  # Call the updated function
            o) options_menu ;;
            z) menu_exit ;;  # Call the updated menu_exit function
            *)
                clear
                ;;
        esac
    done
}

# Run the script
load_config
main_menu
