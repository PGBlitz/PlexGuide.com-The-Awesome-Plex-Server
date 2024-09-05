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
    while true; do
        clear
        echo -e "${CYAN}PG: Traefki DNS Configuration Interface${NC}"
        echo ""
        echo -e "1) Configure DNS Provider"
        echo -e "2) Set Email for Let's Encrypt"
        echo -e "3) Deploy Traefik"
        echo -e "4) Exit"
        echo ""
        read -p "Enter your choice (1-4): " choice
        case $choice in
            1)
                configure_provider
                ;;
            2)
                set_email
                ;;
            3)
                bash /pg/scripts/traefik_menu.sh
                ;;
            4)
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Function to configure DNS provider
configure_provider() {
    clear
    echo -e "${CYAN}Choose a DNS Provider:${NC}"
    echo -e "1) Cloudflare"
    echo -e "2) GoDaddy"
    read -p "Enter your choice (1 or 2): " provider_choice

    if [[ "$provider_choice" == "1" ]]; then
        provider="cloudflare"
        read -p "Enter your Cloudflare email: " cf_email
        read -p "Enter your Cloudflare API key: " cf_api_key
        echo "provider=cloudflare" > "$CONFIG_FILE"
        echo "email=$cf_email" >> "$CONFIG_FILE"
        echo "api_key=$cf_api_key" >> "$CONFIG_FILE"
    elif [[ "$provider_choice" == "2" ]]; then
        provider="godaddy"
        read -p "Enter your GoDaddy API key: " gd_api_key
        read -p "Enter your GoDaddy API secret: " gd_api_secret
        echo "provider=godaddy" > "$CONFIG_FILE"
        echo "api_key=$gd_api_key" >> "$CONFIG_FILE"
        echo "api_secret=$gd_api_secret" >> "$CONFIG_FILE"
    else
        echo -e "${RED}Invalid choice. Please try again.${NC}"
        configure_provider
        return
    fi

    read -p "Enter the domain name to use (e.g., example.com): " domain_name
    echo "domain_name=$domain_name" >> "$CONFIG_FILE"
    echo -e "${GREEN}DNS provider and domain have been configured successfully.${NC}"
    read -p "Press Enter to continue..."
}

# Function to set email for Let's Encrypt
set_email() {
    read -p "Enter your email for Let's Encrypt notifications: " letsencrypt_email
    echo "letsencrypt_email=$letsencrypt_email" >> "$CONFIG_FILE"
    echo -e "${GREEN}Email has been configured successfully.${NC}"
    read -p "Press Enter to continue..."
}

# Execute the setup function
setup_dns_provider