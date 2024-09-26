#!/bin/bash

# ANSI color codes for green, red, blue, and orange
GREEN="\033[0;32m"
RED="\033[0;31m"
BLUE="\033[0;34m"
ORANGE="\033[0;33m"
CYAN="\033[0;36m"
NC="\033[0m" # No color

# Clear the screen at the start
clear

# Terminal width and maximum character length per line
TERMINAL_WIDTH=80
MAX_LINE_LENGTH=72

# Check if the script is being called for personal or official apps
app_type=$1  # 'personal' for personal configurations, 'official' for official configurations

# Function to list running Docker apps that match .app files
list_running_docker_apps() {
    local all_running_apps=$(docker ps --format '{{.Names}}' | grep -v 'cf_tunnel' | sort)
    local matching_apps=()

    for app in $all_running_apps; do
        # Only add the app if it has a corresponding .app file
        if [[ "$app_type" == "personal" && -f "/pg/p_apps/${app}.app" ]]; then
            matching_apps+=("$app")
        elif [[ "$app_type" == "official" && -f "/pg/apps/${app}.app" ]]; then
            matching_apps+=("$app")
        fi
    done

    echo "${matching_apps[@]}"
}

# Function to display running Docker apps in a formatted way
display_running_apps() {
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

# Function to manage the selected app
manage_app() {
    local app_name=$1
    local app_script="/pg/scripts/apps/interface.sh"

    # Ensure the apps_interface.sh script exists before proceeding
    if [[ -f "$app_script" ]]; then
        # Execute the apps_interface.sh script with the app name as an argument
        bash "$app_script" "$app_name" "$app_type"
    else
        echo "Error: Interface script $app_script not found!"
        read -p "Press Enter to continue..."
    fi
}

# Main running function
running_function() {
    while true; do
        clear

        # Get the list of running Docker apps that match .app files
        APP_LIST=($(list_running_docker_apps))

        if [[ ${#APP_LIST[@]} -eq 0 ]]; then
            clear
            echo -e "${RED}Cannot View/Edit Apps as None Exist.${NC}"
            echo ""  # Blank line for separation
            read -p "$(echo -e "${RED}Press Enter to continue...${NC}")"
            exit 0
        fi

        echo -e "${CYAN}${BOLD}PG: Running Apps [View | Edit]${NC}"
        echo ""  # Blank line for separation

        # Display the list of running Docker apps that match the selected type
        display_running_apps "${APP_LIST[@]}"

        echo "════════════════════════════════════════════════════════════════════════════════"
        # Prompt the user to enter an app name or exit
        read -p "$(echo -e "Type [${GREEN}App${NC}] to View/Edit or [${RED}Z${NC}]> ")" app_choice

        # Convert the user input to lowercase for case-insensitive matching
        app_choice=$(echo "$app_choice" | tr '[:upper:]' '[:lower:]')

        # Check if the user wants to exit
        if [[ "$app_choice" == "Z" ]]; then
            exit 0
        fi

        # Check if the app exists in the list of running Docker apps (case-insensitive)
        if echo "${APP_LIST[@]}" | grep -i -w "$app_choice" >/dev/null; then
            # Manage the selected app by calling the apps_interface script
            manage_app "$app_choice"
            exit 0
        else
            echo "Invalid choice. Please try again."
            read -p "Press Enter to continue..."
        fi
    done
}

# Call the main running function
running_function