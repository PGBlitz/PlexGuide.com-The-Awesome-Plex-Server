#!/bin/bash

# Combined deployment script for official and personal apps

# ANSI color codes for green, red, blue, and orange
GREEN="\033[0;32m"
RED="\033[0;31m"
BLUE="\033[0;34m"
ORANGE="\033[0;33m"
NC="\033[0m" # No color
BOLD="\033[1m"
CYAN="\033[0;36m"

# Clear the screen at the start
clear

# Terminal width and maximum character length per line
TERMINAL_WIDTH=80
MAX_LINE_LENGTH=72

# Arguments
deployment_type=$1  # 'personal' for personal deployment, 'official' for official deployment

# Base directory (adjust this to your actual base directory)
BASE_DIR="/pg"

# Function to safely check if a directory exists
directory_exists() {
    if [[ -d "$1" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to create the appropriate apps directory if it doesn't exist
create_apps_directory() {
    local target_dir
    if [[ "$deployment_type" == "personal" ]]; then
        target_dir="$BASE_DIR/p_apps"
    else
        target_dir="$BASE_DIR/apps"
    fi
    
    if ! directory_exists "$target_dir"; then
        echo "Error: Directory $target_dir does not exist and cannot be created."
        return 1
    fi
}

# Function to list all available apps, excluding those already running in Docker
list_available_apps() {
    local app_dir
    if [[ "$deployment_type" == "personal" ]]; then
        app_dir="$BASE_DIR/p_apps"
    else
        app_dir="$BASE_DIR/apps"
    fi

    if ! directory_exists "$app_dir"; then
        echo "Error: App directory $app_dir does not exist."
        return 1
    fi

    local all_apps=$(find "$app_dir" -maxdepth 1 -name "*.app" -type f -exec basename {} .app \; 2>/dev/null | sort)
    local running_apps=$(docker ps --format '{{.Names}}' 2>/dev/null | sort)

    local available_apps=()
    for app in $all_apps; do
        if ! echo "$running_apps" | grep -q -i -w "$app"; then
            available_apps+=("$app")
        fi
    done

    echo "${available_apps[@]}"
}

# Function to display the available apps in a formatted way
display_available_apps() {
    local apps_list=("$@")
    local current_line=""
    local current_length=0

    for app in "${apps_list[@]}"; do
        local app_length=${#app}
        local new_length=$((current_length + app_length + 1))

        if [[ $new_length -gt $TERMINAL_WIDTH ]]; then
            echo "$current_line"
            current_line="$app "
            current_length=$((app_length + 1))
        else
            current_line+="$app "
            current_length=$new_length
        fi
    done

    if [[ -n $current_line ]]; then
        echo "$current_line"
    fi
}

# Function to deploy the selected app
deploy_app() {
    local app_name=$1
    local app_script="$BASE_DIR/scripts/apps/interface.sh"

    if [[ -f "$app_script" ]]; then
        bash "$app_script" "$app_name" "$deployment_type"
    else
        echo "Error: Interface script $app_script not found!"
        read -p "Press Enter to continue..."
    fi
}

# Main deployment function
deployment_function() {
    while true; do
        clear

        if ! create_apps_directory; then
            echo "Error: Unable to access or create necessary directories."
            exit 1
        fi

        APP_LIST=($(list_available_apps))

        echo -e "${CYAN}${BOLD}PG Deployable Apps${NC}"
        echo ""

        if [[ ${#APP_LIST[@]} -eq 0 ]]; then
            echo -e "${ORANGE}No More Apps To Deploy${NC}"
        else
            display_available_apps "${APP_LIST[@]}"
        fi

        echo "════════════════════════════════════════════════════════════════════════════════"
        read -p "$(echo -e "Type [${RED}${BOLD}App${NC}] to Deploy or [${GREEN}${BOLD}Z${NC}] to Exit > ")" app_choice

        app_choice=$(echo "$app_choice" | tr '[:upper:]' '[:lower:]')

        if [[ "$app_choice" == "z" ]]; then
            exit 0
        elif [[ " ${APP_LIST[@]} " =~ " $app_choice " ]]; then
            deploy_app "$app_choice"
            exit 0
        else
            echo -e "${RED}Invalid choice. Please try again.${NC}"
            read -p "Press Enter to continue..."
        fi
    done
}

# Validate the deployment type and call the main deployment function
if [[ "$deployment_type" == "personal" || "$deployment_type" == "official" ]]; then
    deployment_function
else
    echo -e "${RED}Invalid deployment type specified. Use 'personal' or 'official'.${NC}"
    exit 1
fi
