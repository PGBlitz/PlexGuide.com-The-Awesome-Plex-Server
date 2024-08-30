#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No color

# Clear the screen at the start
clear

# Load the configuration
load_config

# Function for SSH Management option
ssh_management() {
    clear
    /pg/scripts/ssh.sh
}

# Function to exit the script
exit_script() {
    clear
    echo "Visit https://plexguide.com"
    echo -e "To Start Again - Type: [${RED}pg${NC}] or [${RED}plexguide${NC}]"
    echo ""  # Space before exiting
    exit 0
}

# Function for the main menu loop
main_menu() {
    while true; do
        display_main_menu
        read -p "Select an option: " choice
        case "$choice" in
            G|g) echo "Graphics Cards option selected." ;;
            S|s) ssh_management ;;
            Z|z) exit_script ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ;;
        esac
    done
}

# Call the main menu function
main_menu
