#!/bin/bash

# ANSI color codes for styling output
CYAN="\033[0;36m"
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
NC="\033[0m"  # No color

# Configuration file path for storing DNS provider and domain details
CONFIG_FILE="/pg/config/dns_provider.cfg"

# Function to check if Traefik is deployed
check_traefik_status() {
    if docker ps --filter "name=traefik" --format '{{.Names}}' | grep -q 'traefik'; then
        traefik_status="${GREEN}[Deployed]${NC}"
    else
        traefik_status="${RED}[Not Deployed]${NC}"
    fi
}

# Function to load the DNS provider configuration
load_dns_provider() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        if [[ -n "$provider" && "$provider" == "cloudflare" && -n "$api_key" && -n "$cf_email" ]]; then
            if test_cloudflare_credentials; then
                provider_display="${GREEN}[SET]${NC}"
                deploy_option_visible=true
            else
                provider_display="${RED}[Not-Set]${NC}"
                deploy_option_visible=false
            fi
        else
            provider_display="${RED}[Not-Set]${NC}"
            deploy_option_visible=false
        fi
    else
        provider_display="${RED}[Not-Set]${NC}"
        deploy_option_visible=false
    fi
}

# Function to test Cloudflare credentials
test_cloudflare_credentials() {
    response=$(curl -s -o /dev/null -w "%{http_code}" -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json")

    if [[ "$response" == "200" ]]; then
        return 0  # Valid credentials
    else
        return 1  # Invalid credentials
    fi
}

# Function to setup DNS provider
setup_dns_provider() {
    while true; do
        clear
        check_traefik_status
        load_dns_provider
        
        echo -e "${CYAN}PG: CloudFlare Traefik Interface ${traefik_status}${NC}"
        echo ""
        echo -e "[${CYAN}${BOLD}C${NC}] CF Information: ${provider_display}"
        echo -e "[${MAGENTA}${BOLD}E${NC}] E-Mail for Let's Encrypt"

        # Only show "D) Deploy" if credentials are valid
        if [[ "$deploy_option_visible" == true ]]; then
            echo -e "[${BLUE}${BOLD}D${NC}] Deploy Traefik"
        fi

        echo -e "[${RED}${BOLD}Z${NC}] Exit"
        echo ""
        
        read -p "Enter your choice: " choice
        case $choice in
            [Cc])
                configure_provider
                ;;
            [Ee])
                set_email
                ;;
            [Dd])
                if [[ "$deploy_option_visible" == false ]]; then
                    echo ""
                    echo -e "${RED}CloudFlare is not configured. Please configure CloudFlare first before deploying Traefik.${NC}"
                    read -p "Press Enter to continue..."
                else
                    bash /pg/scripts/traefik_deploy.sh
                    echo ""
                    read -p "Press Enter to continue..."
                fi
                ;;
            [Zz])
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Function to configure DNS provider (Cloudflare only)
configure_provider() {
    echo ""
    echo -e "${CYAN}Configuring Cloudflare DNS Provider${NC}"
    provider="cloudflare"
    read -p "Enter your Cloudflare email: " cf_email
    read -p "Enter your Cloudflare API key: " cf_api_key

    # Test the credentials before saving
    echo -e "${YELLOW}Testing Cloudflare credentials...${NC}"
    if test_cloudflare_credentials; then
        read -p "Enter the domain name to use (e.g., example.com): " domain_name
        echo "provider=cloudflare" > "$CONFIG_FILE"
        echo "email=$cf_email" >> "$CONFIG_FILE"
        echo "api_key=$cf_api_key" >> "$CONFIG_FILE"
        echo "domain_name=$domain_name" >> "$CONFIG_FILE"
        echo ""
        echo -e "${GREEN}Cloudflare DNS provider and domain have been configured successfully.${NC}"
    else
        echo ""
        echo -e "${RED}CloudFlare Information is Incorrect and/or the API Key may not have the proper permissions.${NC}"
        echo ""
    fi

    read -p "Press [ENTER] to continue..."
}

# Function to set email for Let's Encrypt
set_email() {
    read -p "Enter your email for Let's Encrypt notifications: " letsencrypt_email
    echo "letsencrypt_email=$letsencrypt_email" >> "$CONFIG_FILE"
    echo ""
    echo -e "${GREEN}Email has been configured successfully.${NC}"
    read -p "Press [ENTER] to continue..."
}

# Execute the setup function
setup_dns_provider
