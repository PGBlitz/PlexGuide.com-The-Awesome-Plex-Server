#!/bin/bash

# Configuration file path
CONFIG_FILE="/pg/config/cf_tunnel.cfg"

# ANSI color codes for green, red, and blue
GREEN="\033[0;32m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No color

# Clear the screen when the script starts
clear

# Function to source the configuration file
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    fi
}

# Function to save the Cloudflare token to the config file
save_token_to_config() {
    echo "CLOUDFLARE_TOKEN=\"$CLOUDFLARE_TOKEN\"" > "$CONFIG_FILE"
}

# Load existing configuration
load_config

# Check if the Docker container is running or exists
container_running() {
    docker ps --filter "name=^cf_tunnel$" --format "{{.Names}}" | grep -q "^cf_tunnel$"
}

container_exists() {
    docker ps -a --filter "name=cf_tunnel" --format "{{.Names}}" | grep -q "cf_tunnel"
}

# Function to display the main menu
show_menu() {
    clear
    echo "PG: CloudFlare Tunnel"

    # Display container deployment status
    echo -n "Container Deployed: "
    if container_running; then
        echo -e "${GREEN}Yes${NC}"
    else
        echo -e "${RED}No${NC}"
    fi

    echo
    echo "V) View Token"
    echo "C) Change Token"
    echo "D) Deploy Container"
    if container_exists; then
        echo "S) Stop & Destroy Container"
        echo "Z) Exit"
    else
        echo "Z) Exit"
    fi
    echo
}

# Function to prompt the user with a choice
prompt_choice() {
    read -p "Select an option: " choice
    case ${choice,,} in  # Convert input to lowercase for v/V, c/C, d/D, s/S, z/Z handling
        v)
            clear
            view_token
            ;;
        c)
            clear
            local change_code=$(printf "%04d" $((RANDOM % 10000)))  # Generate a 4-digit code
            while true; do
                read -p "$(echo -e "To change the Cloudflare token, type [${RED}${change_code}${NC}] to proceed or [${GREEN}no${NC}] to cancel: ")" input_code
                if [[ "$input_code" == "$change_code" ]]; then
                    change_token
                    break
                elif [[ "${input_code,,}" == "no" ]]; then
                    echo "Operation cancelled."
                    break
                else
                    echo -e "${RED}Invalid response.${NC} Please type [${RED}${change_code}${NC}] or [${GREEN}no${NC}]."
                fi
            done
            ;;
        d)
            clear
            local deploy_code=$(printf "%04d" $((RANDOM % 10000)))  # Generate a 4-digit code
            while true; do
                read -p "$(echo -e "Deploy CF Tunnel? Type [${RED}${deploy_code}${NC}] to proceed or [${GREEN}no${NC}] to cancel: ")" input_code
                if [[ "$input_code" == "$deploy_code" ]]; then
                    deploy_container
                    break
                elif [[ "${input_code,,}" == "no" ]]; then
                    echo "Operation cancelled."
                    break
                else
                    echo -e "${RED}Invalid response.${NC} Please type [${RED}${deploy_code}${NC}] or [${GREEN}no${NC}]."
                fi
            done
            ;;
        s)
            clear
            stop_destroy_container
            ;;
        z)
            clear
            exit 0
            ;;
        *)
            clear
            echo "Invalid choice. Please select a valid option."
            sleep 2
            show_menu
            prompt_choice
            ;;
    esac
}

# Function to view the Cloudflare token
view_token() {
    clear
    echo "Current Cloudflare Token:"
    echo
    if [[ -z "$CLOUDFLARE_TOKEN" || "$CLOUDFLARE_TOKEN" == "null" ]]; then
        echo "No Stored Token"
    else
        echo "$CLOUDFLARE_TOKEN"
    fi
    echo
    echo -e "${BLUE}[Press Enter]${NC} to Exit"
    read
    show_menu
    prompt_choice
}

# Function to change the Cloudflare token
change_token() {
    clear
    read -p "Enter new Cloudflare token: " CLOUDFLARE_TOKEN
    save_token_to_config
    echo "Cloudflare token has been updated and saved to $CONFIG_FILE."
    sleep 2
    show_menu
    prompt_choice
}

# Function to deploy or redeploy the container
deploy_container() {
    clear
    if container_exists; then
        echo "Redeploying container..."
        docker stop cf_tunnel
        docker rm cf_tunnel
    else
        echo "Deploying CF Tunnel"
    fi

    docker run -d --name cf_tunnel cloudflare/cloudflared:latest tunnel --no-autoupdate run --token $CLOUDFLARE_TOKEN

    # Wait for the container to start and check its status
    echo "Waiting 3 seconds..."
    sleep 3

    if container_running; then
        echo "Cloudflare Tunnel Docker container deployed successfully."
    else
        echo -e "${RED}Token is invalid. The container failed to start.${NC}"
        docker stop cf_tunnel &>/dev/null
        docker rm cf_tunnel &>/dev/null
        echo "Invalid container stopped and removed."
    fi

    echo
    echo -e "${BLUE}[Press Enter]${NC} to continue"
    read
    show_menu
    prompt_choice
}

# Function to stop and destroy the container
stop_destroy_container() {
    clear
    echo "Stopping and destroying the container..."
    docker stop cf_tunnel
    docker rm cf_tunnel
    echo "Container stopped and removed."
    sleep 2
    show_menu
    prompt_choice
}

# Main script execution
show_menu
prompt_choice
