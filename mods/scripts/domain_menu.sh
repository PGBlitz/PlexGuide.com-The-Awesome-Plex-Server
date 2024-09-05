#!/bin/bash

# ANSI color codes
CYAN='\033[0;36m'
GOLD='\033[0;33m'
ORANGE='\033[0;91m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to display the menu
display_menu() {
    echo -e "${CYAN}PG Domain Configuration Interface${NC}"
    echo
    echo -e "${BOLD}${GOLD}[C]${NC} CloudFlare Tunnel"
    echo -e "${BOLD}${ORANGE}[T]${NC} Traefik Reverse Proxy"
    echo -e "${BOLD}${RED}[Z]${NC} Exit"
    echo
}

# Main loop
while true; do
    display_menu
    read -p "Enter your choice: " choice

    case $choice in
        [Cc])
            /pg/scripts/cf_tunnel.sh
            ;;
        [Tt])
            /pg/scripts/traefik_menu.sh
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