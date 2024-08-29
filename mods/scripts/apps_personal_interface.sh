#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
NC="\033[0m" # No color

# Source the defaults script
source /pg/scripts/apps_defaults.sh

# Function: check_deployment_status
check_deployment_status() {
    local container_status=$(docker ps --filter "name=^/${app_name}$" --format "{{.Names}}")

    if [[ "$container_status" == "$app_name" ]]; then
        echo -e "${GREEN}[Deployed]${NC} $app_name"
    else
        echo -e "${RED}[Not Deployed]${NC} $app_name"
    fi
}

# Function: execute_dynamic_menu
execute_dynamic_menu() {
    local selected_option=$1

    # Source the app script to load the menu functions
    echo "source /pg/p_apps/${raw_app_name}/${raw_app_name}.menu"  # Debugging: Echo the source command
    source /pg/p_apps/${raw_app_name}/${raw_app_name}.menu

    # Get the selected option name (e.g., "Admin Token" or "Token")
    local selected_name=$(echo "${dynamic_menu_items[$((selected_option-1))]}" | awk '{$1=""; print $0}' | xargs)  # Trim spaces and get full menu item name
    echo "Selected function name: $selected_name"  # Debugging: Check the function name extracted

    # Convert the selected_name to lowercase and replace spaces with underscores
    local function_name=$(echo "$selected_name" | tr '[:upper:]' '[:lower:]' | tr -s ' ' '_')
    function_name=$(echo "$function_name" | sed 's/_$//')  # Remove trailing underscore
    echo "Function name derived: $function_name"  # This will echo the function name

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
    local app_name=$1
    local raw_app_name=${app_name#p-}  # Remove the p- prefix temporarily for actual script and deployment

    local config_path="/pg/config/${app_name}.cfg"
    local app_menu_path="/pg/p_apps/${raw_app_name}/${raw_app_name}.menu" 2>/dev/null
    local dynamic_menu_items=()
    local dynamic_menu_count=1

    # Call parse_and_store_defaults to populate the config file
    parse_and_store_defaults "$app_name"

    # Parse the .menu file for dynamic menu items
    while IFS= read -r line; do
        if [[ "$line" =~ ^####\  ]]; then
            # Extract everything after the first four characters to account for multi-word titles
            local menu_item=$(echo "$line" | cut -d' ' -f2-)
            dynamic_menu_items+=("${dynamic_menu_count}) $menu_item")
            ((dynamic_menu_count++))
        fi
    done < "$app_menu_path"  # Change: Read from the .menu file

    # Menu
    while true; do
        clear

        check_deployment_status  # Display the initial status
        echo ""
        echo "D) Deploy $raw_app_name"
        echo "K) Kill Docker Container"
        echo "C) Configuration Options"

        # Print dynamic menu items if any
        for item in "${dynamic_menu_items[@]}"; do
            echo "$item"
        done

        echo "Z) Exit"
        echo ""

        read -p "Choose an option: " choice

        case ${choice,,} in  # Convert input to lowercase
            d)
                # Remove the p- prefix for deployment but pass the full app name with p- for config and logging
                bash /pg/scripts/apps_personal_deploy.sh "$app_name"
                ;;
            k)
                bash /pg/scripts/apps_kill_remove.sh "$app_name"
                ;;
            c)
                bash /pg/scripts/apps_config_menu.sh "$app_name"
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

# Run the interface with the provided app name
apps_interface "$1"
