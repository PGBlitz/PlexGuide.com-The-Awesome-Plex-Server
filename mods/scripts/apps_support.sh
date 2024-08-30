#!/bin/bash

# Combined script for official and personal app support

# Arguments
app_name=$1
config_type=$2  # 'personal' for personal apps, 'official' for official apps

# Function to source configuration and functions for the app
appsourcing() {
    if [[ "$config_type" == "personal" ]]; then
        source "/pg/personal_configs/${app_name}.cfg"
        source "/pg/p_apps/${app_name}/${app_name}.functions" 2>/dev/null
    else
        source "/pg/config/${app_name}.cfg"
        source "/pg/apps/${app_name}/${app_name}.functions" 2>/dev/null
    fi
}

# Function to verify if the Docker container is running
appverify() {
    echo ""
    
    # Check if the app_name is present in the list of running Docker containers
    if docker ps | grep -q "$app_name"; then
        echo -e "${GREEN}${app_name}${NC} has been deployed."
    else
        echo -e "${RED}${app_name}${NC} failed to deploy."
    fi
    
    echo ""
    read -p "Press Enter to continue"
}

# Function to source configuration from the config file
configsource() {
    local app_name="$1"
    if [[ "$config_type" == "personal" ]]; then
        config_path="/pg/personal_configs/${app_name}.cfg"
    else
        config_path="/pg/config/${app_name}.cfg"
    fi

    if [ -f "$config_path" ]; then
        source "$config_path"
    else
        echo "Config file for ${app_name} not found at ${config_path}."
        exit 1
    fi
}