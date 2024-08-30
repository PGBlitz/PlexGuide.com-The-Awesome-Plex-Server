#!/bin/bash

# Combined deployment script for official and personal apps

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

# Arguments
deployment_type=$1  # 'personal' for personal deployment, 'official' for official deployment

# Function to create the appropriate apps directory if it doesn't exist
create_apps_directory() {
    if [[ "$deployment_type" == "personal" ]]; then
        [[ ! -d "/pg/personal_apps" ]] && mkdir -p /pg/personal_apps
    else
        [[ ! -d "/pg/apps" ]] && mkdir -p /pg/apps
    fi
}

# Function to list all available apps, excluding those already running in Docker
list_available_apps() {
    local app_dir

    if [[ "$deployment_type" == "personal" ]]; then
        app_dir="/pg/personal_apps"
    else
        app_dir="/pg/apps"
    fi

    local all_apps=$(ls -1 "$app_dir" | sort)
    local running_apps=$(docker ps --format '{{.Names}}' | sort)

    local available_apps=()
    for app in $all_apps; do
        # Check if the app name matches a folder in the app directory
        if [[ -d "$app_dir/$app" ]]; then
            # Only exclude those that are already running
            if ! echo "$running_apps" | grep -i -w "$app" >/dev/null; then
                available_apps+=("$app")
            fi
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

    # Ensure the app script exists before proceeding
    if [[ -f "$app_script" ]]; then
        # Execute the apps_interface.sh script with the app name as an argument
        bash "$app_script" "$app_name"
    else
        echo "Error: Interface script $app_script not found!"
        read -p "Press Enter to continue..."
    fi
}

# Main deployment function
deployment_function() {
    while true; do
        clear

        create_apps_directory

        # Get the list of available apps, ensuring they match app folders
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
        read -p "$(echo -e "Type [${RED}App${NC}] to Deploy or [${GREEN}Z${NC}] to Exit: ")" app_choice

        app_choice=$(echo "$app_choice" | tr '[:upper:]' '[:lower:]')

        # Check if the user input is "z"
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
