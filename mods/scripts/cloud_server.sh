#!/bin/bash

# ANSI color codes
CYAN="\033[0;36m"
GOLD="\033[0;33m"
RED="\033[0;31m"
BOLD="\033[1m"
NC="\033[0m"  # No color

# Configuration file path for storing the last update check timestamp
CONFIG_FILE="/pg/config/hcloud.cfg"
LAST_UPDATE_CHECK_KEY="last_update_check"

# GitHub repo and API URL
REPO_URL="https://raw.githubusercontent.com/plexguide/HCloud/main/cloud_hetzner.sh"
API_URL="https://api.github.com/repos/plexguide/HCloud/commits/main"
SCRIPT_PATH="/pg/scripts/cloud_hetzner.sh"

# Function to read the last update check timestamp from the config file
get_last_update_check() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        echo "${!LAST_UPDATE_CHECK_KEY}"
    else
        echo ""
    fi
}

# Function to store the current timestamp as the last update check in the config file
store_last_update_check() {
    local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "$LAST_UPDATE_CHECK_KEY=\"$current_time\"" > "$CONFIG_FILE"
}

# Function to download the cloud_hetzner.sh script
download_script() {
    echo -e "${CYAN}Downloading cloud_hetzner.sh...${NC}"
    curl -s -L "$REPO_URL" -o "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    store_last_update_check
}

# Function to check if there are updates using the GitHub API
check_for_updates() {
    local last_update_check=$(get_last_update_check)
    local latest_commit_time=$(curl -s "$API_URL" | jq -r '.commit.committer.date')

    # Check if there was an update after the last check
    if [[ -z "$last_update_check" ]] || [[ "$latest_commit_time" > "$last_update_check" ]]; then
        echo -e "${GOLD}Updates found. Downloading the latest version...${NC}"
        download_script
    else
        echo -e "${CYAN}No updates found. Running the current version.${NC}"
    fi
}

# Check if cloud_hetzner.sh exists; if not, download it
if [[ ! -f "$SCRIPT_PATH" ]]; then
    echo -e "${RED}cloud_hetzner.sh is missing. Downloading...${NC}"
    download_script
else
    check_for_updates
fi

# Clear the screen at the start
clear

# Main menu loop for PG Cloud Server Deployment Interface
cloud_server_menu() {
    while true; do
        clear
        
        # Display the header
        echo -e "${CYAN}${BOLD}PG Cloud Server Deployment Interface${NC}"
        echo ""  # Blank line for separation

        # Display menu options
        echo -e "[${GOLD}${BOLD}H${NC}] Hetzner (HCloud)"
        echo -e "[${RED}${BOLD}Z${NC}] Exit"
        echo ""  # Space between options and input prompt

        # Prompt for user input
        read -p "Enter your choice: " choice

        # Process user input
        case ${choice,,} in
            h) bash "$SCRIPT_PATH" ;;
            z) exit 0 ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Run the menu
cloud_server_menu