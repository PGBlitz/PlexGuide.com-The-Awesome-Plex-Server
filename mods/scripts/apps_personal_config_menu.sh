#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m" # No color

app_name=$1
config_path="/pg/personal_configs/${app_name}.cfg"
app_path="/pg/p_apps/${app_name}/${app_name}.app"

# Source the default and restore scripts
source /pg/scripts/apps_personal_defaults.sh
source /pg/scripts/apps_personal_restore_default_settings.sh

# Function: parse_and_store_defaults is already sourced from apps_defaults.sh

# Function: get_or_set_port_number
get_or_set_port_number() {
    if ! grep -q '^port_number=' "$config_path"; then
        port_number=$(awk '/# Default Port:/ {print $NF}' "$app_path")
        [[ -n "$port_number" ]] && echo "port_number=${port_number}" >> "$config_path" || {
            echo "Error: Default port not found in $app_path."
            exit 1
        }
    else
        source "$config_path"
    fi
}

# Function: validate_or_create_path
validate_or_create_path() {
    [[ -d "$1" ]] || mkdir -p "$1" || return 1
    return 0
}

# Function: check_deployment_status
check_deployment_status() {
    local container_status=$(docker ps --filter "name=^/${app_name}$" --format "{{.Names}}")
    if [[ "$container_status" == "$app_name" ]]; then
        echo -e "${GREEN}[Deployed]${NC}"
    else
        echo -e "${RED}[Not Deployed]${NC}"
    fi
}

# Function: change_port_number
change_port_number() {
    clear
    local port_code=$(printf "%04d" $((RANDOM % 10000)))
    echo "Current Port: $port_number - Do you want to change the port number?"
    echo ""
    while true; do
        read -p "$(echo -e "Type [${RED}${port_code}${NC}] to proceed or [${GREEN}Z${NC}] to cancel: ")" port_choice
        if [[ "$port_choice" == "$port_code" ]]; then
            break
        elif [[ "${port_choice,,}" == "z" ]]; then
            echo "Operation cancelled."
            return
        else
            echo -e "${RED}Invalid response.${NC} Please type [${RED}${port_code}${NC}] or [${GREEN}Z${NC}]."
        fi
    done
    read -p "Enter the new Port for $app_name (1-65000) or type [exit] to cancel: " new_port_number

    if [[ "$new_port_number" =~ ^[0-9]+$ ]] && ((new_port_number >= 1 && new_port_number <= 65000)); then
        sed -i "s/^port_number=.*/port_number=${new_port_number}/" "$config_path"
        stop_and_remove_app
        redeploy_app
    elif [[ "$new_port_number" == "exit" ]]; then
        echo "No changes made."
    else
        echo "Invalid input. Please enter a number between 1 and 65000."
        read -p "Press Enter to continue..."
        change_port_number  # Recursive call to retry port change
    fi
}

# Function: move_or_delete_appdata
move_or_delete_appdata() {
    if [[ -z "$(ls -A "$appdata_path")" ]]; then
        echo "The current appdata directory is empty. No data will be moved."
    else
        read -p "Do you want to move the prior appdata to the new location? Type: yes / no / exit: " move_choice
        case ${move_choice,,} in  # Convert input to lowercase
            yes)
                mv "$appdata_path/"* "$1/" && echo "Data moved to the new location: $1"
                ;;
            no)
                read -p "Do you want to delete the old appdata? Type: yes / no: " delete_choice
                [[ ${delete_choice,,} == "yes" ]] && rm -rf "$appdata_path" && echo "Old appdata deleted."
                ;;
            exit)
                echo "Operation aborted."
                return
                ;;
            *)
                echo "Invalid input. Operation aborted."
                return
                ;;
        esac
    fi
    appdata_path=$1
    sed -i "s|^appdata_path=.*|appdata_path=${appdata_path}|" "$config_path"
}

# Function: change_appdata_path
change_appdata_path() {
    clear
    local path_code=$(printf "%04d" $((RANDOM % 10000)))
    echo "Current Appdata Path: $appdata_path"
    echo "Do you want to change the appdata path?"
    echo ""
    while true; do
        read -p "$(echo -e "Type [${RED}${path_code}${NC}] to proceed or [${GREEN}Z${NC}] to cancel: ")" change_choice
        if [[ "$change_choice" == "$path_code" ]]; then
            break
        elif [[ "${change_choice,,}" == "z" ]]; then
            echo "Operation cancelled."
            return
        else
            echo -e "${RED}Invalid response.${NC} Please type [${RED}${path_code}${NC}] or [${GREEN}Z${NC}]."
        fi
    done
    while true; do
        read -p "Enter the new Appdata Path for $app_name or type [exit] to cancel: " new_appdata_path

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
            read -p "Press Enter to continue..."
        fi
    done
}

# Function: check_expose_status
check_expose_status() {
    local expose_status="Unknown"

    if [[ -f "$config_path" ]]; then
        source "$config_path"
        
        if [[ "$expose" == "127.0.0.1:" ]]; then
            expose_status="No - Closed/Internal"
        elif [[ "$expose" == "" ]]; then
            expose_status="Yes - Remote Accessible"
        fi
    else
        echo "Error: Configuration file for $app_name not found."
        exit 1
    fi

    echo "$expose_status"
}

# Menu
while true; do
    clear

    # Re-source the config file to refresh values
    source "$config_path"

    # Get deployment status and expose status
    deployment_status=$(check_deployment_status)
    expose_status=$(check_expose_status)

    echo -e "Configuration Interface - ${app_name} ${deployment_status}"
    echo ""
    echo "A) Appdata Path: $appdata_path"

    # Check if port_number is set before displaying Port options
    if grep -q '^port_number=' "$config_path"; then
        echo "P) Port: $port_number"
        echo "E) Exposed Port: $expose_status"
    fi

    echo "C) Config File - Edit"
    echo "R) Restore Default Settings"
    echo "Z) Exit"
    echo ""

    read -p "Choose an option: " choice

    case ${choice,,} in  # Convert input to lowercase
        a)
            change_appdata_path
            ;;
        p)
            if grep -q '^port_number=' "$config_path"; then
                change_port_number
            else
                clear
                continue
            fi
            ;;
        e)
            if grep -q '^port_number=' "$config_path"; then
                bash /pg/scripts/apps_personal_expose.sh "$app_name" "personal"
            else
                clear
                continue
            fi
            ;;
        c)
            bash /pg/scripts/apps_personal_config_edit.sh "$app_name"
            ;;
        r)
            reset_config_file "$app_name"
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
