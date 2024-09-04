#!/bin/bash

# ANSI color codes for styling output
CYAN="\033[0;36m"
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BOLD="\033[1m"
NC="\033[0m" # No color

# Configuration file path for storing the DNS provider details
CONFIG_FILE="/pg/config/dns_provider.cfg"

# Function to display the DNS provider setup menu
dns_provider_menu() {
    clear
    echo -e "${CYAN}${BOLD}PG Domain Provider Setup${NC}"
    echo ""
    echo -e "${YELLOW}Please select your domain provider:${NC}"
    echo -e "[1] Cloudflare"
    echo -e "[2] GoDaddy"
    echo -e "[Z] Exit"
    echo ""
    read -p "Enter your choice: " choice

    case ${choice,,} in
        1) setup_cloudflare ;;
        2) setup_godaddy ;;
        z) exit 0 ;;
        *) 
            echo -e "${RED}Invalid option. Please try again.${NC}"
            read -p "Press Enter to continue..."
            dns_provider_menu
            ;;
    esac
}

# Function to set up Cloudflare
setup_cloudflare() {
    echo -e "${CYAN}Setting up Cloudflare...${NC}"
    
    # Ask for Cloudflare-specific details
    read -p "Enter your Cloudflare Email: " cf_email
    read -p "Enter your Cloudflare API Key: " cf_api_key

    # Save the details to the configuration file
    echo "provider=cloudflare" > "$CONFIG_FILE"
    echo "cf_email=$cf_email" >> "$CONFIG_FILE"
    echo "cf_api_key=$cf_api_key" >> "$CONFIG_FILE"

    echo -e "${GREEN}Cloudflare setup complete!${NC}"
    read -p "Press Enter to continue..."
    dns_provider_menu
}

# Function to set up GoDaddy
setup_godaddy() {
    echo -e "${CYAN}Setting up GoDaddy...${NC}"

    # Ask for GoDaddy-specific details
    read -p "Enter your GoDaddy API Key: " gd_api_key
    read -p "Enter your GoDaddy API Secret: " gd_api_secret

    # Save the details to the configuration file
    echo "provider=godaddy" > "$CONFIG_FILE"
    echo "gd_api_key=$gd_api_key" >> "$CONFIG_FILE"
    echo "gd_api_secret=$gd_api_secret" >> "$CONFIG_FILE"

    echo -e "${GREEN}GoDaddy setup complete!${NC}"
    read -p "Press Enter to continue..."
    dns_provider_menu
}

# Run the DNS provider setup menu
dns_provider_menu