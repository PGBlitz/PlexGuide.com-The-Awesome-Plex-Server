#!/bin/bash

# Combined script for official and personal configuration menus

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m" # No color

# Arguments
app_name=$1
config_type=$2  # 'personal' for personal configurations, 'official' for official configurations

# Source default settings script
source /pg/scripts/apps_defaults.sh

# Determine paths based on config type
if [[ "$config_type" == "personal" ]]; then
    config_path="/pg/personal_configs/${app_name}.cfg"
    app_path="/pg/p_apps/${app_name}/${app_name}.app"
else
    config_path="/pg/config/${app_name}.cfg"
    app_path="/pg/apps/${app_name}/${app_name}.app"
fi

# Ensure config file exists
if [[ ! -f "$config_path" ]]; then
    echo "Config file not found at $config_path. Creating a new one."
    touch "$config_path"
    parse_and_store_defaults "$app_name"  # Create default entries
fi

# Function to set port number if not present
get_or_set_port_number() {
    if ! grep -q '^port_number=' "$config_path"; then
        port_number=$(awk '/# Default Port:/ {print $NF}' "$app_path")
        if [[ -n "$port_number" ]]; then
            echo "port_number=${port_number}" >> "$config_path"
        else
            echo "Error: Default port not found in $app_path."
            exit 1
        fi
    else
        source "$config_path"
    fi
}

# Function to validate or create a directory
validate_or_create_path() {
    [[ -d "$1" ]] || mkdir -p "$1"
}

# Function: stop_and_remove_app
stop_and_remove_app() {
    while true; do
        clear
        echo "This action will stop and remove the Docker container for $app_name."
        echo "Your appdata will not be lost."
        echo ""
        
        # Generate a random 4-digit code
        pin_code=$(printf "%04d" $((RANDOM % 10000)))
        
        # Prompt the user to confirm with the generated pin code or to cancel with 'Z'
        echo -e "To proceed, type [${RED}${pin_code}${NC}] to proceed or [${GREEN}Z${NC}] to cancel: "
        
        read -p "" user_input
        
        if [[ "$user_input" == "$pin_code" ]]; then
            # If the user enters the correct pin code, proceed to stop and remove the container
            echo ""
            echo "Stopping and removing the existing container for $app_name ..."
            docker stop "$app_name" && docker rm "$app_name"
            break
        elif [[ "${user_input,,}" == "z" ]]; then
            # If the user types 'Z' or 'z', cancel the operation
            echo "Operation cancelled."
            break
        else
            # If the input is invalid, clear the screen and repeat the prompt
            clear
            echo -e "${RED}Invalid input. Please enter the correct pin code or [Z] to cancel.${NC}"
        fi
    done
}

# Function to check Docker container status
check_deployment_status() {
    docker ps --filter "name=^/${app_name}$" --format "{{.Names}}" | grep -q "^${app_name}$" && \
        echo -e "${GREEN}[Deployed]${NC}" || echo -e "${RED}[Not Deployed]${NC}"
}

# Function to prompt and change the port number
change_port_number() {
    clear
    local port_code=$(printf "%04d" $((RANDOM % 10000)))
    echo "Current Port: $port_number - Change port number?"
    prompt_code "$port_code" || return
    read -p "Enter new port for $app_name (1-65000) or type 'exit' to cancel: " new_port_number
    if [[ "$new_port_number" =~ ^[0-9]+$ ]] && ((new_port_number >= 1 && new_port_number <= 65000)); then
        sed -i "s/^port_number=.*/port_number=${new_port_number}/" "$config_path"
        stop_and_remove_app
        redeploy_app
    elif [[ "$new_port_number" != "exit" ]]; then
        echo "Invalid input. Please enter a number between 1 and 65000."
        change_port_number  # Retry
    fi
}

# Function to move or delete app data
move_or_delete_appdata() {
    if [[ -z "$(ls -A "$appdata_path")" ]]; then
        echo "No data in the current appdata directory."
    else
        read -p "Move data to new location? Type: yes / no / exit: " move_choice
        case ${move_choice,,} in
            yes) mv "$appdata_path/"* "$1/" && echo "Data moved to $1";;
            no)  read -p "Delete old appdata? Type: yes / no: " delete_choice
                 [[ ${delete_choice,,} == "yes" ]] && rm -rf "$appdata_path" && echo "Old appdata deleted.";;
            exit) return;;
            *)    echo "Invalid input. Operation aborted." && return;;
        esac
    fi
    appdata_path=$1
    sed -i "s|^appdata_path=.*|appdata_path=${appdata_path}|" "$config_path"
}

# Function to prompt and change the appdata path
change_appdata_path() {
    clear
    local path_code=$(printf "%04d" $((RANDOM % 10000)))
    echo "Current Appdata Path: $appdata_path - Change path?"
    prompt_code "$path_code" || return
    while true; do
        read -p "Enter new Appdata Path for $app_name or type 'exit' to cancel: " new_appdata_path
        if [[ "$new_appdata_path" == "exit" ]]; then
            echo "No changes made."
            return
        elif validate_or_create_path "$new_appdata_path"; then
            move_or_delete_appdata "$new_appdata_path"
            stop_and_remove_app
            redeploy_app
            break
        else
            echo "Invalid path. Please provide a valid path."
        fi
    done
}

# Function to check exposure status
check_expose_status() {
    [[ -f "$config_path" ]] && source "$config_path"
    [[ "$expose" == "127.0.0.1:" ]] && echo "No - Closed/Internal" || echo "Yes - Remote Accessible"
}

# Function to prompt for code
prompt_code() {
    local expected_code=$1
    read -p "$(echo -e "Type [${RED}${expected_code}${NC}] to proceed or [${GREEN}Z${NC}] to cancel: ")" input_code
    [[ "$input_code" == "$expected_code" ]] && return 0
    [[ "${input_code,,}" == "z" ]] && echo "Operation cancelled." && return 1
    echo -e "${RED}Invalid response. Try again.${NC}"
    return 1
}

# Main menu loop
while true; do
    clear
    source "$config_path"
    deployment_status=$(check_deployment_status)
    expose_status=$(check_expose_status)

    echo -e "Configuration Interface - ${app_name} ${deployment_status}"
    echo ""
    echo "A) Appdata Path: $appdata_path"
    [[ -n "$port_number" ]] && echo "P) Port: $port_number" && echo "E) Exposed Port: $expose_status"
    echo "C) Config File - Edit"
    echo "R) Restore Default Settings"
    echo "Z) Exit"
    echo ""

    read -p "Choose an option: " choice

    case ${choice,,} in
        a) change_appdata_path;;
        p) [[ -n "$port_number" ]] && change_port_number || continue;;
        e) [[ -n "$port_number" ]] && bash /pg/scripts/apps_expose.sh "$app_name" "$config_type" || continue;;
        c) bash /pg/scripts/apps_config_edit.sh "$app_name" "$config_type";;
        r) reset_config_file "$app_name" "$config_type";;
        z) break;;
        *) echo "Invalid option, please try again." && read -p "Press Enter to continue...";;
    esac
done
