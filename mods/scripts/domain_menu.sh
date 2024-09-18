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
BOLD="\033[1m"

# Get the port status from /pg/config/default_ports.cfg
get_port_status() {
    config_file="/pg/config/default_ports.cfg"
    if [[ -f "$config_file" ]]; then
        source "$config_file"
        if [[ "$ports" == "open" ]]; then
            port_status="Open"
        elif [[ "$ports" == "closed" ]]; then
            port_status="Closed"
        else
            port_status="Unknown"
        fi
    else
        port_status="Unknown"
    fi
}

# Function to display the menu
display_menu() {
    clear
    get_port_status  # Fetch the port status
    echo -e "${CYAN}PG Domain Configuration Interface${NC}"
    echo
    echo -e "[${YELLOW}${BOLD}A${NC}] CloudFlare Tunnel"
    echo -e "[${CYAN}${BOLD}B${NC}] CloudFlare Traefik"
    echo -e "[${GREEN}${BOLD}P${NC}] Default Port Protection - (Default Ports: ${port_status})"
    echo -e "[${RED}${BOLD}Z${NC}] Exit"
    echo
}

# Main loop
while true; do
    display_menu
    read -p "Make a Choice > " choice

    case $choice in
        [Aa])
            bash /pg/scripts/cf_tunnel.sh
            ;;
        [Bb])
            bash /pg/scripts/traefik/traefik_menu.sh
            ;;
        [Pp])
            bash /pg/scripts/default_ports.sh
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
