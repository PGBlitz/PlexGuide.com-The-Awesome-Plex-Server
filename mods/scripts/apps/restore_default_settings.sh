#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
HOTPINK="\033[1;35m"
BOLD="\033[1m"
NC="\033[0m" # No color

source /pg/scripts/apps/defaults.sh

# Function: reset_config_file
reset_config_file() {
    local app_name="$1"
    local app_type="$2"
    local config_path

    # Determine the config path based on the app type
    if [[ "$app_type" == "personal" ]]; then
        config_path="/pg/personal_configs/${app_name}.cfg"
    else
        config_path="/pg/config/${app_name}.cfg"
    fi

    while true; do
        clear
        # Generate two random 4-digit codes: one to proceed, one to cancel
        proceed_code=$(printf "%04d" $((RANDOM % 10000)))
        exit_code=$(printf "%04d" $((RANDOM % 10000)))
        
        echo -e "${RED}Warning: This is an advanced option.${NC}"
        echo "Visit https://plexguide.com/wiki/link-not-set for more information."
        echo ""
        echo "This will erase the current config file and restore a default config file."
        echo "The Docker container will be stopped and removed if running."
        echo "This will not erase any data; your data will remain in its original location."
        echo ""
        echo -e "To proceed, enter this PIN [${HOTPINK}${BOLD}${proceed_code}${NC}]"
        echo -e "To cancel, enter this PIN [${GREEN}${BOLD}${exit_code}${NC}]"
        echo ""

        # Read user input
        read -p "Enter PIN > " reset_choice

        if [[ "$reset_choice" == "$proceed_code" ]]; then
            # Stop and remove the Docker container
            docker stop "$app_name" && docker rm "$app_name"
            echo "Docker container $app_name has been stopped and removed."
            
            # Reset the config file
            rm -f "$config_path"
            echo "Config file has been reset to default."
            touch "$config_path"
            parse_and_store_defaults "$app_name" "$app_type"
            echo "The config file has been regenerated."
            return
        elif [[ "$reset_choice" == "$exit_code" ]]; then
            echo "Operation Cancelled."
            return
        else
            # Invalid response: clear the screen and repeat the prompt
            clear
            echo -e "${RED}Invalid input. Please enter the correct PIN.${NC}"
        fi
    done
}
