#!/bin/bash

# ANSI color codes for styling output
CYAN="\033[0;36m"
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m" # No color

# Configuration file path for storing DNS provider and domain details
CONFIG_FILE="/pg/config/dns_provider.cfg"

# Function to setup DNS provider
setup_dns_provider() {
    clear
    echo -e "${CYAN}Choose a DNS Provider:${NC}"
    echo -e "1) Cloudflare"
    echo -e "2) GoDaddy"
    read -p "Enter your choice (1 or 2): " provider_choice

    if [[ "$provider_choice" == "1" ]]; then
        provider="cloudflare"
        read -p "Enter your Cloudflare email: " cf_email
        read -p "Enter your Cloudflare API key: " cf_api_key
    elif [[ "$provider_choice" == "2" ]]; then
        provider="godaddy"
        read -p "Enter your GoDaddy API key: " gd_api_key
        read -p "Enter your GoDaddy API secret: " gd_api_secret
    else
        echo -e "${RED}Invalid choice. Please try again.${NC}"
        setup_dns_provider
        return
    fi

    read -p "Enter the domain name to use (e.g., example.com): " domain_name

    # Save the configuration
    echo "provider=$provider" > "$CONFIG_FILE"
    echo "domain_name=$domain_name" >> "$CONFIG_FILE"

    if [[ "$provider" == "cloudflare" ]]; then
        echo "cf_email=$cf_email" >> "$CONFIG_FILE"
        echo "cf_api_key=$cf_api_key" >> "$CONFIG_FILE"
    elif [[ "$provider" == "godaddy" ]]; then
        echo "gd_api_key=$gd_api_key" >> "$CONFIG_FILE"
        echo "gd_api_secret=$gd_api_secret" >> "$CONFIG_FILE"
    fi

    echo -e "${GREEN}DNS provider and domain have been configured successfully.${NC}"
}

# Execute the setup function
setup_dns_provider