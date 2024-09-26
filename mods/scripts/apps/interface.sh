#!/bin/bash

# Combined script for official and personal app interfaces

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
NC="\033[0m" # No color
BOLD="\033[1m"

# Source the defaults script
source /pg/scripts/apps/defaults.sh

# Arguments
app_name=$1
config_type=$2  # 'personal' for personal configurations, 'official' for official configurations

# Function: check_deployment_status
check_deployment_status() {
    # Load the configuration file to get the port_number and expose value
    if [[ "$config_type" == "personal" ]]; then
        config_file="/pg/personal_configs/${app_name}.cfg"
    else
        config_file="/pg/config/${app_name}.cfg"
    fi

    if [[ -f "$config_file" ]]; then
        source "$config_file"
    fi

    # Determine port status based on the 'expose' variable
    if [[ "$expose" == "127.0.0.1"* ]]; then
        port_status="Closed"
    else
        port_status="Open"
    fi

    # Check if the app's Docker container is running
    local container_status=$(docker ps --filter "name=^/${app_name}$" --format "{{.Names}}")

    if [[ "$container_status" == "$app_name" ]]; then
        echo -e "${GREEN}${BOLD}[Deployed]${NC} $app_name - Port: $port_number/$port_status"
    else
        # App is not deployed, show potential port status if deployed
        if [[ "$port_status" == "Closed" ]]; then
            echo -e "${RED}${BOLD}[Not Deployed]${NC} $app_name - Port Closed if Deployed"
        else
            echo -e "${RED}${BOLD}[Not Deployed]${NC} $app_name - Port Open if Deployed"
        fi
    fi
}

# Function: execute_dynamic_menu
execute_dynamic_menu() {
    local selected_option=$1

    # Source the app script to load the menu functions
    if [[ "$config_type" == "personal" ]]; then
        source "/pg/p_apps/${app_name}.app"
    else
        source "/pg/apps/${app_name}.app"
    fi

    # Construct the function name as menuN where N is the selected_option
    local function_name="menu${selected_option}"

    # Check if the function exists and execute it
    if declare -f "$function_name" > /dev/null; then
        echo "Executing commands for ${function_name}..."
        "$function_name"  # Execute the function
    else
        echo "Error: No corresponding function found for ${function_name}."
    fi

    read -p "Press Enter to continue..."  # Pause to observe output
}

# Main Interface
# Function: apps_interface
apps_interface() {
    if [[ "$config_type" == "personal" ]]; then
        config_path="/pg/personal_configs/${app_name}.cfg"
        app_file_path="/pg/p_apps/${app_name}.app"
    else
        config_path="/pg/config/${app_name}.cfg"
        app_file_path="/pg/apps/${app_name}.app"
    fi

    local dynamic_menu_items=()
    local dynamic_menu_count=1

    # Call parse_and_store_defaults to populate the config file
    parse_and_store_defaults "$app_name" "$config_type"

    # Check if the .app file exists before parsing
    if [[ -f "$app_file_path" ]]; then
        while IFS= read -r line; do
            if [[ "$line" =~ ^####\  ]]; then
                # Extract everything after the four hashes to account for multi-word titles
                local menu_item=$(echo "$line" | cut -d' ' -f2-)
                dynamic_menu_items+=("${dynamic_menu_count}) $menu_item")
                ((dynamic_menu_count++))
            fi
        done < "$app_file_path"
    else
        echo -e "${RED}Warning: App file $app_file_path does not exist. Skipping parsing step.${NC}"
    fi

    # Menu
    while true; do
        clear

        check_deployment_status  # Display the initial status
        echo ""
        echo "D) Deploy $app_name"
        echo "K) Kill Docker Container"
        echo "C) Configuration Options"

        # Print dynamic menu items if any
        for item in "${dynamic_menu_items[@]}"; do
            echo "$item"
        done

        echo "Z) Exit"
        echo ""

        read -p "Choose an option > " choice

        case ${choice,,} in  # Convert input to lowercase
            d)
                bash /pg/scripts/apps/deploy.sh "$app_name" "$config_type"
                ;;
            k)
                bash /pg/scripts/apps/kill_remove.sh "$app_name"
                ;;
            c)
                bash /pg/scripts/apps/config_menu.sh "$app_name" "$config_type"
                ;;
            [0-9]*)
                if [[ $choice -le ${#dynamic_menu_items[@]} ]]; then
                    execute_dynamic_menu "$choice"
                else
                    echo "Invalid option, please try again."
                    read -p "Press Enter to continue..."
                fi
                ;;
            z)
                break
                ;;
            *)
                echo "Invalid option, please try again."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Run the interface with the provided app name and type
apps_interface