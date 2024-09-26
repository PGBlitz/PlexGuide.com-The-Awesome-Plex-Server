#!/bin/bash

# Configuration file path
CONFIG_FILE="/pg/config/cf_tunnel.cfg"

# ANSI color codes for green, hot pink, and others
GREEN="\033[1;32m"  # Bold Green
HOT_PINK="\033[1;35m"  # Bold Hot Pink
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
    echo -n -e "${CYAN}${BOLD}PG: CloudFlare Tunnel${NC} - Container Deployed: "
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
    read -p "Select an Option > " choice
    case ${choice,,} in  # Convert input to lowercase for v/V, c/C, d/D, s/S, z/Z handling
        v)
            clear
            view_token
            ;;
        c)
            clear
            change_token
            ;;
        d)
            clear
            deploy_container
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
    local change_code
    change_code=$(printf "%04d" $((RANDOM % 10000)))  # Generate a 4-digit pin

    # Ask the user for the new token
    echo -e "Enter new Cloudflare token:"
    read -p "> " new_token  # Get the new token from the user
    echo  # Echo a blank line for spacing

    # Confirmation prompt with hot pink pin for proceed and green for cancel
    while true; do
        read -p "$(echo -e "To proceed with the new token, type [${HOT_PINK}${change_code}${NC}] to proceed or [${GREEN}exit${NC}] to cancel: ")" input_code
        if [[ "$input_code" == "$change_code" ]]; then
            # Save the token and confirm
            CLOUDFLARE_TOKEN="$new_token"
            save_token_to_config
            echo -e "${GREEN}Cloudflare token has been updated and saved to $CONFIG_FILE.${NC}"
            sleep 2
            show_menu
            prompt_choice
            break
        elif [[ "${input_code,,}" == "exit" ]]; then
            echo -e "${GREEN}Operation cancelled.${NC}"
            sleep 2
            show_menu
            prompt_choice
            break
        else
            echo -e "${RED}Invalid response.${NC} Please type [${HOT_PINK}${change_code}${NC}] or [${GREEN}exit${NC}]."
        fi
    done
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
