#!/bin/bash

# ANSI color codes
CYAN="\033[0;36m"
GOLD="\033[0;33m"
RED="\033[0;31m"
BOLD="\033[1m"
NC="\033[0m"  # No color

# Clear the screen at the start
clear

# Main menu loop for PG Cloud Server Deployment Interface
cloud_server_menu() {
    while true; do
        clear
        
        # Display the header
        echo -e "${CYAN}${BOLD}PG Cloud Server Deployment Interface${NC}"
        echo ""  # Blank line for separation

        # Display menu options
        echo -e "[${GOLD}${BOLD}H${NC}] Hetzner (HCloud)"
        echo -e "[${RED}${BOLD}Z${NC}] Exit"
        echo ""  # Space between options and input prompt

        # Prompt for user input
        read -p "Enter your choice: " choice

        # Process user input
        case ${choice,,} in
            h) bash /pg/scripts/cloud_hetzner.sh ;;
            z) exit 0 ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Run the menu
cloud_server_menu
