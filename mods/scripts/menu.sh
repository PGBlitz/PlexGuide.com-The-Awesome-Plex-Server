#!/bin/bash

# Configuration file path
CONFIG_FILE="/pg/config/config.cfg"

# ANSI color codes
RED="\033[0;31m"
ORANGE="\033[0;33m"
YELLOW="\033[1;33m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
BOLD="\033[1m"
NC="\033[0m"  # No color

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

# Function to determine the color based on the version
get_color() {
    if [[ "$VERSION" == *"PG Dev"* ]]; then
        echo "$RED"
    elif [[ "$VERSION" == *".B"* ]]; then
        echo "$ORANGE"
    elif [[ "$VERSION" == *"Fork -"* ]]; then
        echo "$CYAN"
    else
        echo "$WHITE"
    fi
}

# Function for Apps Management
apps_management() {
    bash /pg/scripts/apps_starter_menu.sh
}

# Function to Update PG Interface
update_pg_interface() {
    # Define the destination path
    INSTALL_SCRIPT_PATH="/pg/installer/install_menu.sh"

    # Create the directory if it doesn't exist
    mkdir -p /pg/installer

    # Download the install script from the specified URL
    curl -s https://raw.githubusercontent.com/plexguide/Installer/v11/install_menu.sh -o "$INSTALL_SCRIPT_PATH"

    # Set ownership to 1000:1000 and make the script executable
    chown 1000:1000 "$INSTALL_SCRIPT_PATH"
    chmod +x "$INSTALL_SCRIPT_PATH"

    # Execute the downloaded script
    bash "$INSTALL_SCRIPT_PATH"
    
    exit 0  # Ensure the script exits after executing the menu_exit.sh
}

# Function to exit the script
menu_exit() {
    bash /pg/installer/menu_exit.sh
    exit 0  # Ensure the script exits after executing the menu_exit.sh
}

# Traefik & Cloudflare Tunnel
domain_interface() {
    bash /pg/scripts/domain_menu.sh
}

# Function for Server Cloud Deployments
server_cloud_deployments() {
    bash /pg/scripts/cloud_server.sh
}

# Function for Options Menu
options_menu() {
    bash /pg/scripts/options.sh
}

# Main menu loop
main_menu() {
    while true; do
        clear
        
        # Get the color based on the version
        COLOR=$(get_color)

        # Display the header
        echo -e "${COLOR}${BOLD}Welcome to PlexGuide: $VERSION${NC}"
        echo ""  # Blank line for separation

        # Display menu options with bold colored letters
        echo -e "[${YELLOW}${BOLD}A${NC}] Application Management"
        echo -e "[${CYAN}${BOLD}C${NC}] CloudFlare Tunnel & Traefik"
        echo -e "[${GREEN}${BOLD}S${NC}] Cloud Servers"
        echo -e "[${PURPLE}${BOLD}U${NC}] PG Updates"
        echo -e "[${BLUE}${BOLD}O${NC}] Options"
        echo -e "[${RED}${BOLD}Z${NC}] Exit"
        echo ""  # Space between options and input prompt

        # Prompt for user input
        read -p "Enter your choice: " choice

        # Process user input
        case ${choice,,} in
            a) apps_management ;;
            s) server_cloud_deployments ;;
            c) domain_interface ;;
            u) update_pg_interface ;;
            o) options_menu ;;
            z) menu_exit ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Run the script
load_config
main_menu
