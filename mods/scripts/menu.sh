#!/bin/bash

# Configuration file path
CONFIG_FILE="/pg/config/config.cfg"

# ANSI color codes for blue
BLUE="\033[0;34m"
NC="\033[0m" # No color

# Clear the screen at the start
clear

# Ensure /pg/scripts/basics.sh is executable, then run it in the background
chmod +x /pg/scripts/basics.sh
/pg/scripts/basics.sh &

# Function to source the configuration file
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    else
        echo "VERSION=\"11.0 Beta\"" > "$CONFIG_FILE"
        source "$CONFIG_FILE"
    fi
}

# Load the configuration
load_config

# Function for the main menu
main_menu() {
  while true; do
    clear
    echo -e "${BLUE}Welcome to PlexGuide: $VERSION${NC}"
    echo ""  # Blank line for separation
    # Display the main menu options
    echo "Please select an option:"
    echo "1) CloudFlare Tunnel (Domains)"
    echo "2) Apps Management"
    echo "3) Update PlexGuide"
    echo "4) Exit"
    echo ""  # Space between options and input prompt

    # Prompt the user for input
    read -p "Enter your choice [1-4]: " choice

    case $choice in
      1)
        /pg/scripts/cf_tunnel.sh
        ;;
      2)
        /pg/scripts/apps.sh
        ;;
      3)
        clear
        echo "Updating PlexGuide..."
        # Add the code or script to update PlexGuide here
        read -p "Press Enter to continue..."
        ;;
      4)
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
