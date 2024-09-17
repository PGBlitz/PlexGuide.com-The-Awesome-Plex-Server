#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
NC="\033[0m"  # No color

# Get the username of the user with UID 1000
REQUIRED_USER=$(getent passwd 1000 | cut -d: -f1)

# Function to check if the script is being run with sudo
is_sudo() {
    if [ -n "$SUDO_USER" ]; then
        return 0 # True, it's being run with sudo
    else
        return 1 # False, it's not being run with sudo
    fi
}

# Enhanced security check
if [[ -z "$SUDO_USER" ]]; then
    echo ""
    echo -e "${RED}Run as user '$REQUIRED_USER' by using typing 'su $REQUIRED_USER'"
    echo -e "Then type 'sudo plexguide'${NC}"
    echo ""
    read -p "Press [ENTER] to acknowledge"
    bash /pg/installer/menu_exit.sh
    exit 1
elif [[ $SUDO_UID -ne 1000 ]] || [[ $SUDO_GID -ne 1000 ]]; then
    echo ""
    echo -e "${RED}Run as user '$REQUIRED_USER' by using typing 'su $REQUIRED_USER'"
    echo -e "Then type 'sudo plexguide'${NC}"
    echo ""
    read -p "Press [ENTER] to acknowledge"
    bash /pg/installer/menu_exit.sh
    exit 1
elif [[ $EUID -ne 0 ]]; then
    echo ""
    echo -e "${RED}WARNING: This script must be run with sudo privileges."
    echo -e "Run as user '$REQUIRED_USER' by using typing 'su $REQUIRED_USER'"
    echo -e "Then type 'sudo plexguide'${NC}"
    echo ""
    read -p "Press [ENTER] to acknowledge"
    bash /pg/installer/menu_exit.sh
    exit 1
fi

# If we've made it here, the user is either UID 1000 or is UID 1000 using sudo
echo "Security check passed. Proceeding with the script..."

# Configuration file path
CONFIG_FILE="/pg/config/config.cfg"

# Additional ANSI color codes
ORANGE="\033[0;33m"
YELLOW="\033[1;33m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
BOLD="\033[1m"

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
    bash /pg/scripts/apps/starter_menu.sh
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
    
    menu_exit
    exit 0  # Ensure the script exits after executing the menu_exit.sh
}

# Function to exit the script
menu_exit() {
    bash /pg/installer/menu_exit.sh
    exit 0  # Ensure the script exits after executing the menu_exit.sh
}

# Function for CloudFlare Tunnel Management
cloudflare_tunnel() {
    bash /pg/scripts/cf_tunnel.sh
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
        echo -e "[${YELLOW}${BOLD}A${NC}] Apps Management"
        echo -e "[${CYAN}${BOLD}C${NC}] CloudFlare Tunnel (Domains)"
        echo -e "[${GREEN}${BOLD}S${NC}] Server: Cloud Deployments"
        echo -e "[${PURPLE}${BOLD}U${NC}] PG: Update Interface"
        echo -e "[${BLUE}${BOLD}O${NC}] Options"
        echo -e "[${RED}${BOLD}Z${NC}] Exit"
        echo ""  # Space between options and input prompt

        # Prompt for user input
        read -p "Choose and Option > " choice

        # Process user input
        case ${choice,,} in
            a) apps_management ;;
            s) server_cloud_deployments ;;
            c) cloudflare_tunnel ;;
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