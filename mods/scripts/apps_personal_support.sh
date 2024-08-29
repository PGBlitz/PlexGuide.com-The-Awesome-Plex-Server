#!/bin/bash

# Function to source configuration and functions for the app
appsourcing() {
    source "/pg/personal_configs/${app_name}.cfg"  # Updated config path
    source /pg/p_apps/${app_name}/${app_name}.functions 2>/dev/null
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
    config_path="/pg/personal_configs/${app_name}.cfg"  # Updated config path
    if [ -f "$config_path" ]; then
        source "$config_path"
    else
        echo "Config file for ${app_name} not found at ${config_path}."
        exit 1
    fi
}
