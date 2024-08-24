#!/bin/bash

# Configuration file path
CONFIG_FILE="/pg/config/config.cfg"

# ANSI color codes
RED="\033[0;31m"
NC="\033[0m" # No color

# Clear the screen at the start
clear

# Ensure /pg/scripts/basics.sh is executable, then run it in the background
run_basics() {
    chmod +x /pg/scripts/basics.sh
    /pg/scripts/basics.sh &
}

# Function to source the configuration file
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    else
        echo "VERSION=\"11.0 Beta\"" > "$CONFIG_FILE"
        source "$CONFIG_FILE"
    fi
}

# Function for Apps Management
apps_management() {
    /pg/scripts/apps_starter_menu.sh
}

# Function for HardDisk Management
harddisk_management() {
    /pg/scripts/drivemenu.sh
}

# Function for CloudFlare Tunnel Management
cloudflare_tunnel() {
    /pg/scripts/cf_tunnel.sh
}

# Function for Options Menu
options_menu() {
    /pg/scripts/options.sh
}

# Function to Exit the script
exit_script() {
    clear
    echo "Visit https://plexguide.com"
    echo -e "To Start Again - Type: [${RED}pg${NC}] or [${RED}plexguide${NC}]"
    echo ""  # Space before exiting
    exit 0
}

# Function for the main menu
main_menu() {
    while true; do
        clear
        echo -e "${RED}Welcome to PlexGuide: $VERSION${NC}"
        echo ""  # Blank line for separation
        # Display the main menu options
        echo "A) Apps Management"
        echo "H) HardDisk Management"
        echo "C) CloudFlare Tunnel (Domains)"
        echo "O) Options"
        echo "R) Reinstall PlexGuide"
        echo "Z) Exit"
        echo ""  # Space between options and input prompt

        # Prompt the user for input
        read -p "Enter your choice: " choice

        case ${choice,,} in  # Convert input to lowercase for a/A, c/C, r/R, o/O, z/Z handling
            a) apps_management ;;
            h) harddisk_management ;; 
            c) cloudflare_tunnel ;;
            r) bash /pg/scripts/reinstall.sh ;;  # Call the separate script for reinstalling PlexGuide
            o) options_menu ;;
            z) exit_script ;;
            *)
                clear  # Clear the screen for an invalid option and repeat the menu
                ;;
        esac

    done
}

# Run the script
load_config
run_basics
main_menu