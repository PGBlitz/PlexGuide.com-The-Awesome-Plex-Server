#!/bin/bash

# ANSI color codes for styling output
CYAN="\033[0;36m"
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
BOLD="\033[1m"
NC="\033[0m"  # No color

# Configuration file path
CONFIG_FILE="/pg/config/dns_provider.cfg"

# Ensure config file exists
ensure_config_file() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        mkdir -p "$(dirname "$CONFIG_FILE")"
        touch "$CONFIG_FILE"
    fi
}

# Function to check if Traefik is deployed
check_traefik_status() {
    if docker ps --filter "name=traefik" --format '{{.Names}}' | grep -q 'traefik'; then
        traefik_status="${GREEN}${BOLD}[Deployed]${NC}"
    else
        traefik_status="${RED}${BOLD}[Not Deployed]${NC}"
    fi
}

# Function to check if the Let's Encrypt email is set
check_email_status() {
    if grep -q "^letsencrypt_email=" "$CONFIG_FILE"; then
        letsencrypt_email=$(grep "^letsencrypt_email=" "$CONFIG_FILE" | cut -d'=' -f2)
        if [[ -z "$letsencrypt_email" || "$letsencrypt_email" == "notset" ]]; then
            email_status="${RED}${BOLD}Not Set${NC}"
        else
            email_status="${GREEN}${BOLD}Set${NC}"
        fi
    else
        email_status="${RED}${BOLD}Not Set${NC}"
    fi
}

# Function to check if the domain is set
check_domain_status() {
    if grep -q "^domain_name=" "$CONFIG_FILE"; then
        domain_name=$(grep "^domain_name=" "$CONFIG_FILE" | cut -d'=' -f2)
        if [[ -z "$domain_name" ]]; then
            domain_status="${RED}${BOLD}Not Set${NC}"
        else
            domain_status="${GREEN}${BOLD}${domain_name}${NC}"
        fi
    else
        domain_status="${RED}${BOLD}Not Set${NC}"
    fi
}

# Function to configure DNS provider (Cloudflare only)
configure_provider() {
    echo ""
    echo -e "${CYAN}Configuring Cloudflare DNS Provider${NC}"
    provider="cloudflare"
    
    # Prompt for Cloudflare email and API key
    read -p "Enter your Cloudflare email: " cf_email
    read -p "Enter your Cloudflare API key: " api_key

    # Trim any leading/trailing whitespace from the API key
    api_key=$(echo "$api_key" | xargs)

    # Test the credentials before saving
    echo -e "${YELLOW}Testing Cloudflare credentials...${NC}"
    if test_cloudflare_credentials; then
        echo "provider=cloudflare" > "$CONFIG_FILE"
        echo "email=$cf_email" >> "$CONFIG_FILE"
        echo "api_key=$api_key" >> "$CONFIG_FILE"
        echo ""
        echo -e "${GREEN}Cloudflare credentials have been configured successfully.${NC}"
    else
        # Blank out all information in the config file if credentials are invalid
        echo "" > "$CONFIG_FILE"
        echo ""
        echo -e "${RED}CloudFlare Information is Incorrect and/or the API Key may not have the proper permissions.${NC}"
        echo ""
    fi

    read -p "Press [ENTER] to continue..."
}

# Function to set domain name
set_domain() {
    while true; do
        read -p "Enter the domain name to use (e.g., example.com): " domain_name

        # Validate domain format
        if validate_domain "$domain_name"; then
            # Remove any existing domain_name entry
            sed -i '/^domain_name=/d' "$CONFIG_FILE"
            echo "domain_name=$domain_name" >> "$CONFIG_FILE"
            echo -e "${GREEN}Domain has been configured successfully.${NC}"
            read -p "Press Enter to continue..."
            break
        else
            echo -e "${RED}Invalid domain name. Please enter a valid domain (e.g., example.com).${NC}"
        fi
    done
}

# Function to validate domain format
validate_domain() {
    local domain="$1"
    if [[ "$domain" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0  # Domain is valid
    else
        return 1  # Domain is invalid
    fi
}

# Function to set email for Let's Encrypt
set_email() {
    while true; do
        read -p "Enter your email for Let's Encrypt notifications: " letsencrypt_email

        # Validate email format
        if validate_email "$letsencrypt_email"; then
            echo "letsencrypt_email=$letsencrypt_email" >> "$CONFIG_FILE"
            echo -e "${GREEN}Email has been configured successfully.${NC}"
            read -p "Press Enter to continue..."
            break
        else
            echo -e "${RED}Invalid email format. Please enter a valid email (e.g., user@example.com).${NC}"
        fi
    done
}

# Function to validate email format
validate_email() {
    local email="$1"
    if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0  # Email is valid
    else
        return 1  # Email is invalid
    fi
}

# Function to test Cloudflare credentials
test_cloudflare_credentials() {
    response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
      -H "Authorization: Bearer $api_key" \
      -H "Content-Type: application/json")

    if echo "$response" | grep -q "valid and active"; then
        return 0  # Valid credentials
    else
        return 1  # Invalid credentials
    fi
}

# Function to handle Traefik stop and removal warning with PINs
warn_traefik_removal() {
    echo ""
    echo -e "${RED}Warning: Changing the Cloudflare credentials will stop and remove Traefik.${NC}"
    echo ""

    # Generate two random 4-digit PINs
    proceed_pin=$(shuf -i 1000-9999 -n 1)
    cancel_pin=$(shuf -i 1000-9999 -n 1)

    # Display the PINs to the user
    echo -e "If you want to proceed and remove Traefik, enter: ${RED}${proceed_pin}${NC}"
    echo -e "If you do NOT want to proceed, enter: ${GREEN}${cancel_pin}${NC}"
    echo ""

    # Read user input for PIN
    read -p "Enter your choice (PIN): " user_pin

    # Check user's choice
    if [[ "$user_pin" == "$proceed_pin" ]]; then
        echo -e "${RED}Stopping and removing Traefik...${NC}"
        docker stop traefik >/dev/null 2>&1
        docker rm traefik >/dev/null 2>&1
        return 0  # Proceed with changing credentials
    elif [[ "$user_pin" == "$cancel_pin" ]]; then
        echo -e "${GREEN}Operation canceled. Traefik will not be stopped or removed.${NC}"
        return 1  # Do not proceed
    else
        echo -e "${RED}Invalid PIN entered. Operation aborted.${NC}"
        return 1  # Invalid entry, cancel operation
    fi
}
