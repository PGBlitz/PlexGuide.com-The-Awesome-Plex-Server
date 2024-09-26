#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
HOTPINK="\033[1;35m"  # Hotpink color for the proceed PIN
BOLD="\033[1m"
NC="\033[0m" # No color

# Arguments
app_name=$1
script_type=$2  # personal or official

# Configuration file paths
dns_provider_config="/pg/config/dns_provider.cfg"
app_config_official="/pg/config/${app_name}.cfg"
app_config_personal="/pg/personal_configs/${app_name}.cfg"

# Name of the Docker network to check or create
network_name="plexguide"

# Function to check and create the Docker network
check_and_create_network() {
    # Check if the Docker network exists
    if docker network ls --format '{{.Name}}' | grep -wq "$network_name"; then
        # Network exists, no action needed
        return 0
    else
        # Network does not exist, attempt to create it
        echo "Creating Docker network '${network_name}'..."
        if docker network create "$network_name" --driver bridge; then
            echo "Docker network '${network_name}' created successfully."
        else
            echo -e "${RED}Failed to create Docker network '${network_name}'.${NC}"
            read -p "Press [ENTER] to acknowledge the error and continue..."
        fi
    fi
}

# Function to source configuration and functions for the app
appsourcing() {
    if [[ "$script_type" == "personal" ]]; then
        source "$app_config_personal"
        source "/pg/p_apps/${app_name}/${app_name}.functions" 2>/dev/null
    else
        source "$app_config_official"
        source "/pg/apps/${app_name}/${app_name}.functions" 2>/dev/null
    fi
}

# Function to update traefik_domain in the app's config
update_traefik_domain() {
    # Ensure dns_provider.cfg exists
    if [[ ! -f "$dns_provider_config" ]]; then
        mkdir -p "$(dirname "$dns_provider_config")"
        touch "$dns_provider_config"
    fi

    # Read domain_name from dns_provider.cfg
    if grep -q "^domain_name=" "$dns_provider_config"; then
        domain_name=$(grep "^domain_name=" "$dns_provider_config" | cut -d'=' -f2)
    else
        domain_name=""
    fi

    # Set traefik_domain value based on domain_name
    if [[ -z "$domain_name" ]]; then
        # No domain set, use empty value
        traefik_domain="traefik_domain=\"\""
    else
        # Domain exists, use it in the traefik_domain
        traefik_domain="traefik_domain=\"$domain_name\""
    fi

    # Update the app's configuration file
    if [[ "$script_type" == "personal" ]]; then
        # Overwrite traefik_domain in the personal config file
        if grep -q "^traefik_domain=" "$app_config_personal"; then
            sed -i "s/^traefik_domain=.*/$traefik_domain/" "$app_config_personal"
        else
            echo "$traefik_domain" >> "$app_config_personal"
        fi
    else
        # Overwrite traefik_domain in the official config file
        if grep -q "^traefik_domain=" "$app_config_official"; then
            sed -i "s/^traefik_domain=.*/$traefik_domain/" "$app_config_official"
        else
            echo "$traefik_domain" >> "$app_config_official"
        fi
    fi
}

# Function: Deploys / Redploys App
redeploy_app() {
    # Check if lspci is installed; detect NVIDIA graphics cards
    if ! command -v lspci &> /dev/null; then
        if [ -f /etc/debian_version ]; then
            sudo apt-get update && sudo apt-get install -y pciutils
        fi
    fi

    # Run the network check and creation function
    check_and_create_network

    echo "Deploying $app_name"

    # Update traefik_domain based on the domain_name in dns_provider.cfg
    update_traefik_domain
    
    # Determine which support script to source
    if [[ "$script_type" == "personal" ]]; then
        appsourcing
        source "/pg/p_apps/$app_name.app"
    elif [[ "$script_type" == "official" ]]; then
        appsourcing
        source "/pg/apps/$app_name.app"
    else
        echo -e "${RED}Invalid script type specified. Use 'personal' or 'official'.${NC}"
        exit 1
    fi

    deploy_container "$app_name"  # Call the deploy_container function

    # Create the app-specific directory before writing the docker-compose.yml
    mkdir -p /pg/ymals/${app_name}

    # Function to Deploy Docker Compose
    create_docker_compose

    # Navigate to the app-specific configuration directory
    cd /pg/ymals/${app_name} || {
        echo -e "${RED}Failed to navigate to /pg/ymals/${app_name}. Directory does not exist.${NC}"
        return 1
    }
    
    # Run docker-compose up within the app-specific directory
    docker-compose up -d

    echo ""
    read -p "Press [ENTER] to Continue"
}

# Deployment logic
echo ""
deploy_proceed_code=$(printf "%04d" $((RANDOM % 10000)))  # PIN for proceeding
deploy_exit_code=$(printf "%04d" $((RANDOM % 10000)))  # PIN for exiting

while true; do
    # Check if the container is already running
    if docker ps --format '{{.Names}}' | grep -wq "$app_name"; then
        echo -e "Redeploy $app_name?"
        container_running=true
    else
        echo -e "Deploy $app_name?"
        container_running=false
    fi

    # Prompt user for deployment action with colors maintained
    echo "" && echo -en "To proceed, enter this PIN [${HOTPINK}${BOLD}${deploy_proceed_code}${NC}]\n"
    echo -en "To cancel, enter this PIN [${GREEN}${BOLD}${deploy_exit_code}${NC}]"

    echo && read -p "Enter PIN > " deploy_choice

    if [[ "$deploy_choice" == "$deploy_proceed_code" ]]; then
        echo ""
        
        # Stop and remove the container if it's running
        if [ "$container_running" = true ]; then
            echo -n "Stopping $app_name Docker container..."
            docker stop "$app_name" &> /dev/null && echo -e " ${GREEN}Stopped${NC}"
            
            echo -n "Removing $app_name Docker container..."
            docker rm "$app_name" &> /dev/null && echo -e " ${GREEN}Removed${NC}"
        fi
        
        echo -e "${app_name} Docker Container - ${GREEN}Stopped & Removed${NC}"

        redeploy_app  # Deploy the container after stopping/removing (if it existed)
        break
    elif [[ "$deploy_choice" == "$deploy_exit_code" ]]; then
        echo "Operation exited."
        break
    else
        echo ""
        read -p "${RED}Invalid Choice. Press [ENTER] to continue${NC}"
    fi
done
