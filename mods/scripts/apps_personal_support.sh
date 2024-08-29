#!/bin/bash

# Function to verify if the Docker container is running
appsourcing() {
    source "/pg/config/p-${app_name}.cfg"
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
    config_path="/pg/config/p-${app_name}.cfg"
    if [ -f "$config_path" ]; then
        source "$config_path"
    else
        echo "Config file for ${app_name} not found at ${config_path}."
        exit 1
    fi
}
