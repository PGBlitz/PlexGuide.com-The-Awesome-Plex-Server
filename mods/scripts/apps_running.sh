#!/bin/bash

# ANSI color codes
declare -A COLORS=([GREEN]="\033[0;32m" [RED]="\033[0;31m" [BLUE]="\033[0;34m" [ORANGE]="\033[0;33m" [NC]="\033[0m")

TERMINAL_WIDTH=80
MAX_LINE_LENGTH=72
APP_SCRIPT="/pg/scripts/apps_interface.sh"

# Function to list running Docker apps that match personal or official app folders
list_running_docker_apps() {
    local app_dir="/pg/${app_type/_apps/apps}"
    docker ps --format '{{.Names}}' | grep -v 'cf_tunnel' | sort | while read -r app; do
        [[ -d "$app_dir/$app" ]] && echo "$app"
    done
}

# Function to display running Docker apps in a formatted way
display_running_apps() {
    local current_line="" current_length=0
    while read -r app; do
        if ((${#current_line} + ${#app} + 1 > TERMINAL_WIDTH)); then
            echo "$current_line"
            current_line="$app "
        else
            current_line+="$app "
        fi
    done
    [[ -n $current_line ]] && echo "$current_line"
}

# Function to manage the selected app
manage_app() {
    if [[ -f "$APP_SCRIPT" ]]; then
        bash "$APP_SCRIPT" "$1" "$app_type"
    else
        echo "Error: Interface script $APP_SCRIPT not found!"
        read -p "Press Enter to continue..."
    fi
}

# Main running function
running_function() {
    while true; do
        clear
        APP_LIST=$(list_running_docker_apps)

        if [[ -z $APP_LIST ]]; then
            echo -e "${COLORS[RED]}Cannot View/Edit Apps as None Exist.${COLORS[NC]}"
            echo
            read -p "$(echo -e "${COLORS[RED]}Press Enter to continue...${COLORS[NC]}")"
            exit 0
        fi

        echo -e "${COLORS[RED]}PG: Running Apps [View | Edit]${COLORS[NC]}"
        echo
        echo "$APP_LIST" | display_running_apps
        echo "═══════════════════════════════════════════════════════════════════════════════"
        
        read -p "$(echo -e "Type [${COLORS[GREEN]}App${COLORS[NC]}] to View/Edit or [${COLORS[RED]}Exit${COLORS[NC]}]: ")" app_choice

        case ${app_choice,,} in
            exit) exit 0 ;;
            *)
                if echo "$APP_LIST" | grep -qi "^$app_choice$"; then
                    manage_app "$app_choice"
                    exit 0
                else
                    echo "Invalid choice. Please try again."
                    read -p "Press Enter to continue..."
                fi
                ;;
        esac
    done
}

# Main execution
app_type=${1:-personal}  # Default to 'personal' if not specified
clear
running_function