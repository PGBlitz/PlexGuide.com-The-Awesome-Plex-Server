#!/bin/bash

# ANSI color codes
CYAN='\033[0;36m'
GOLD='\033[0;33m'
RED="\033[0;31m"
ORANGE="\033[0;33m"
YELLOW="\033[1;33m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
NC='\033[0m' # No Color

# Function to display the menu
display_menu() {
    clear
    echo -e "${CYAN}PG Domain Configuration Interface${NC}"
    echo
    echo -e "[${YELLOW}${BOLD}C${NC}] CloudFlare Tunnel"
    echo -e "[${CYAN}${BOLD}T${NC}] Traefik Reverse Proxy"
    echo -e "[${RED}${BOLD}Z${NC}] Exit"
    echo
}

# Main loop
while true; do
    display_menu
    read -p "Enter your choice: " choice

    case $choice in
        [Cc])
            bash /pg/scripts/cf_tunnel.sh
            ;;
        [Tt])
            bash /pg/scripts/traefik_menu.sh
            ;;
        [Zz])
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac

    echo
done