#!/bin/bash

# ANSI color codes for formatting
RED="\033[0;31m"
GREEN="\033[0;32m"
ORANGE="\033[0;33m"
BLUE="\033[0;34m"
WHITE="\033[1;37m"
CYAN="\033[0;36m"
BOLD="\033[1m"
NC="\033[0m"  # No color

# Default values for personal apps configuration
DEFAULT_USER="None"
DEFAULT_REPO="None"

# Function to get the Default Port Status from /pg/config/default_ports.cfg
get_port_status() {
    config_file="/pg/config/default_ports.cfg"
    if [[ -f "$config_file" ]]; then
        source "$config_file"
        if [[ "$ports" == "open" ]]; then
            port_status="Open"
        elif [[ "$ports" == "closed" ]]; then
            port_status="Closed"
        else
            port_status="Unknown"
        fi
    else
        port_status="Unknown"
    fi
}

# Function to count running Docker containers that match official app names from .app files in /pg/apps
count_docker_apps() {
    local all_running_apps=$(docker ps --format '{{.Names}}' | grep -v 'cf_tunnel')
    local official_count=0

    for app in $all_running_apps; do
        if [[ -f "/pg/apps/${app}.app" ]]; then
            ((official_count++))
        fi
    done

    echo $official_count
}

# Function to count running Docker containers that match personal app names from .app files in /pg/p_apps
count_personal_docker_apps() {
    local all_running_apps=$(docker ps --format '{{.Names}}' | grep -v 'cf_tunnel')
    local personal_count=0

    for app in $all_running_apps; do
        if [[ -f "/pg/p_apps/${app}.app" ]]; then
            ((personal_count++))
        fi
    done

    echo $personal_count
}

# Function to load the App Store version from the config file
load_app_store_version() {
    if [ -f /pg/config/appstore_version.cfg ]; then
        source /pg/config/appstore_version.cfg
    else
        appstore_version="None"
    fi
}

# Function to create /pg/apps directory if it does not exist
ensure_apps_directory() {
    if [[ ! -d "/pg/apps" ]]; then
        mkdir -p /pg/apps
        chown 1000:1000 /pg/apps
        chmod +x /pg/apps
    fi
}

# Function to create /pg/personal_configs/ directory if it doesn't exist
setup_personal_configs_directory() {
    local config_dir="/pg/personal_configs"
    if [[ ! -d "$config_dir" ]]; then
        mkdir -p "$config_dir"
        chown 1000:1000 "$config_dir"
        chmod +x "$config_dir"
        echo -e "${GREEN}Directory $config_dir created and permissions set.${NC}"
    fi
}

# Function to load personal apps configuration
load_personal_apps_config() {
    local config_file="/pg/personal_configs/personal_apps.cfg"
    if [[ -f "$config_file" ]]; then
        source "$config_file"
    else
        user=$DEFAULT_USER
        repo=$DEFAULT_REPO
    fi
}

# Main menu function
main_menu() {
    while true; do
        clear

        # Ensure /pg/apps and /pg/personal_configs directories exist with correct permissions
        ensure_apps_directory
        setup_personal_configs_directory

        # Get the number of running Docker apps, excluding cf_tunnel
        APP_COUNT=$(count_docker_apps)

        # Get the number of running personal Docker apps, excluding cf_tunnel
        P_COUNT=$(count_personal_docker_apps)

        # Load the App Store version
        load_app_store_version

        # Load personal apps configuration
        load_personal_apps_config

        # Get Default Port Status
        get_port_status

        clear
        echo -e "${BLUE}${BOLD}PlexGuide: Applications Interface${NC}"
        echo -e "${WHITE}────────────────────────────────────────────────────${NC}"
        echo ""  # Blank line for separation

        echo -e "${ORANGE}${BOLD}Official Applications${NC}"
        # Display the App Store Version at the top
        printf "  A) App Store Version     [%s]\n" "$appstore_version"
        
        # Conditionally display other menu options only if appstore_version is not "None"
        if [[ "$appstore_version" != "None" ]]; then
            printf "  B) Official: Manage      [%d]\n" "$APP_COUNT"
            printf "  C) Official: Deploy\n"
            echo ""  # Space for separation

            echo -e "${RED}${BOLD}Personal Applications${NC}"
            printf "  P) Personal:             [%s/%s]\n" "$user" "$repo"
            
            # Conditionally hide options Q and R if the repo is set to "None"
            if [[ "$repo" != "None" ]]; then
                printf "  Q) Personal: Manage      [%d]\n" "$P_COUNT"
                printf "  R) Personal: Deploy Apps\n"
            fi
            
            echo ""  # Space for separation
        else
            echo ""  # Space for separation
            echo -e "${RED}Please select an App Store version by choosing option A.${NC}"
        fi

        # Default Ports section
        echo -e "${CYAN}${BOLD}Default Ports${NC}"
        printf "  Y) Default Port Status:  [%s]\n" "$port_status"
        
        echo ""  # Space between options and input prompt
        echo -e "${WHITE}────────────────────────────────────────────────────${NC}"
        # Display the prompt with colors and capture user input
        echo -e "Make a Choice or [${GREEN}Z${NC}] to Exit >${NC} \c"
        read -r choice

        case $choice in
            A|a)
                bash /pg/scripts/apps_version.sh
                ;;
            B|b)
                if [[ "$appstore_version" == "None" ]]; then
                    echo -e "${RED}Option B is not available. Please select an App Store version first.${NC}"
                    read -p "Press Enter to continue..."
                else
                    bash /pg/scripts/apps_running.sh "official"
                fi
                ;;
            C|c)
                if [[ "$appstore_version" == "None" ]]; then
                    echo -e "${RED}Option C is not available. Please select an App Store version first.${NC}"
                    read -p "Press Enter to continue..."
                else
                    bash /pg/scripts/apps_stage.sh "official"
                fi
                ;;
            P|p)
                bash /pg/scripts/apps_personal_select.sh
                ;;
            Q|q)
                if [[ "$repo" == "None" ]]; then
                    echo -e "${RED}Option Q is not available. Please use P to set a User and Repo first.${NC}"
                    read -p "Press Enter to continue..."
                else
                    bash /pg/scripts/apps_running.sh "personal"
                fi
                ;;
            R|r)
                if [[ "$repo" == "None" ]]; then
                    echo -e "${RED}Option R is not available. Please use P to set a User and Repo first.${NC}"
                    read -p "Press Enter to continue..."
                else
                    bash /pg/scripts/apps_stage.sh "personal"
                fi
                ;;
            Y|y)
                bash /pg/scripts/default_ports.sh
                ;;
            Z|z)
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option, please try again.${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Call the main menu function
main_menu
