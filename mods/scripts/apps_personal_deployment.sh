#!/bin/bash

# ANSI color codes for green, red, blue, and orange
GREEN="\033[0;32m"
RED="\033[0;31m"
BLUE="\033[0;34m"
ORANGE="\033[0;33m"
NC="\033[0m" # No color

# Clear the screen at the start
clear

# Terminal width and maximum character length per line
TERMINAL_WIDTH=80
MAX_LINE_LENGTH=72

# Function to create the /pg/personal directory if it doesn't exist
create_personal_directory() {
    [[ ! -d "/pg/personal" ]] && mkdir -p /pg/personal
}

# Function to list all available apps in /pg/personal, excluding those already running in Docker
list_available_apps() {
    # Use find to list only files and directories that do not start with a dot (.)
    local all_apps=$(find /pg/personal -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | grep -vE '^\.' | sort)
    local running_apps=$(docker ps --format '{{.Names}}' | sort)

    local available_apps=()
    for app in $all_apps; do
        # Only exclude those that are already running
        if ! echo "$running_apps" | grep -i -w "$app" >/dev/null; then
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
        local new_length=$((current_length + app_length + 1)) # +1 for the space

        # If adding the app would exceed the maximum length, start a new line
        if [[ $new_length -gt $TERMINAL_WIDTH ]]; then
            echo "$current_line"
            current_line="$app "
            current_length=$((app_length + 1)) # Reset with the new app and a space
        else
            current_line+="$app "
            current_length=$new_length
        fi
    done

    # Print the last line if it has content
    if [[ -n $current_line ]]; then
        echo "$current_line"
    fi
}

# Function to deploy the selected app
deploy_app() {
    local app_name=$1
    local app_script="/pg/scripts/apps_interface.sh"

    # Prefix the app name with 'p-' to indicate it's a personal app
    local prefixed_app_name="p-$app_name"

    # Ensure the app script exists before proceeding
    if [[ -f "$app_script" ]]; then
        # Execute the apps_interface.sh script with the prefixed app name as an argument
        bash "$app_script" "$prefixed_app_name"
    else
        echo "Error: Interface script $app_script not found!"
        read -p "Press Enter to continue..."
    fi
}

# Main deployment function
deployment_function() {
    while true; do
        clear

        create_personal_directory

        # Get the list of available apps
        APP_LIST=($(list_available_apps))

        echo -e "${RED}PG: Deployable Apps${NC}"
        echo ""  # Blank line for separation

        if [[ ${#APP_LIST[@]} -eq 0 ]]; then
            echo -e "${ORANGE}No More Apps To Deploy${NC}"
        else
            display_available_apps "${APP_LIST[@]}"
        fi
        
        echo "════════════════════════════════════════════════════════════════════════════════"
        # Prompt the user to enter an app name or exit
        read -p "$(echo -e "Type [${GREEN}App${NC}] to Deploy or [${RED}Exit${NC}]: ")" app_choice

        app_choice=$(echo "$app_choice" | tr '[:upper:]' '[:lower:]')

        # Check if the user input is "exit"
        if [[ "$app_choice" == "exit" ]]; then
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

# Call the main deployment function
deployment_function
