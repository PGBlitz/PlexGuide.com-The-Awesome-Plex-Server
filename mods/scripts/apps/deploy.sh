#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m" # No color

# Arguments
app_name=$1
script_type=$2  # personal or official

#!/bin/bash

# Name of the Docker network to check or create
network_name="plexguide"

# Function to check and create the Docker network
check_and_create_network() {
    # Check if the Docker network exists
    if docker network ls --format '{{.Name}}' | grep -wq "$network_name"; then
        # Network exists, no action needed
        return 0
    else
        # Network does not exist, attempt to create it
        echo "Creating Docker network '${network_name}'..."
        if docker network create "$network_name" --driver bridge; then
            echo "Docker network '${network_name}' created successfully."
        else
            echo -e "\033[0;31mFailed to create Docker network '${network_name}'.\033[0m"
            read -p "Press [ENTER] to acknowledge the error and continue..."
        fi
    fi
}

# Function: Deploys / Redploys App
redeploy_app() {
    # Check if lspci is installed; detect NVIDIA graphics cards
    if ! command -v lspci &> /dev/null; then
        if [ -f /etc/debian_version ]; then
            sudo apt-get update && sudo apt-get install -y pciutils
        fi
    fi

    # Run the network check and creation function
    check_and_create_network

    echo "Deploying $app_name"
    
    # Determine which support script to source
    if [[ "$script_type" == "personal" ]]; then
        source /pg/scripts/apps/support.sh "$app_name" "$script_type" && appsourcing
        source "/pg/p_apps/$app_name.app"
    elif [[ "$script_type" == "official" ]]; then
        source /pg/scripts/apps/support.sh "$app_name" "$script_type" && appsourcing
        source "/pg/apps/$app_name.app"
    else
        echo -e "${RED}Invalid script type specified. Use 'personal' or 'official'.${NC}"
        exit 1
    fi

    deploy_container "$app_name"  # Call the deploy_container function

    # Create the app-specific directory before writing the docker-compose.yml
    mkdir -p /pg/ymals/${app_name}

    # Function to Deploy Docker Compose
    create_docker_compose

    # Navigate to the app-specific configuration directory
    cd /pg/ymals/${app_name} || {
        echo -e "${RED}Failed to navigate to /pg/ymals/${app_name}. Directory does not exist.${NC}"
        return 1
    }
    
    # Run docker-compose up within the app-specific directory
    docker-compose up -d

    echo ""
    read -p "Press [ENTER] to Continue"
}

# Deployment logic
echo ""
deploy_code=$(printf "%04d" $((RANDOM % 10000)))

while true; do
    # Check if the container is already running
    if docker ps --format '{{.Names}}' | grep -wq "$app_name"; then
        echo -e "Redeploy $app_name?"
        container_running=true
    else
        echo -e "Deploy $app_name?"
        container_running=false
    fi

    # Prompt user for deployment action with colors maintained
    echo -en "Type [${RED}${deploy_code}${NC}] to proceed or [${GREEN}Z${NC}] to cancel: "
    read deploy_choice

    if [[ "$deploy_choice" == "$deploy_code" ]]; then
        echo ""
        
        # Stop and remove the container if it's running
        if [ "$container_running" = true ]; then
            echo -n "Stopping $app_name Docker container..."
            docker stop "$app_name" &> /dev/null && echo -e " ${GREEN}Stopped${NC}"
            
            echo -n "Removing $app_name Docker container..."
            docker rm "$app_name" &> /dev/null && echo -e " ${GREEN}Removed${NC}"
        fi
        
        echo -e "${app_name} Docker Container - ${GREEN}Stopped & Removed${NC}"

        redeploy_app  # Deploy the container after stopping/removing (if it existed)
        break
    elif [[ "${deploy_choice,,}" == "z" ]]; then
        echo "Operation cancelled."
        break
    else
        echo ""
        echo "Invalid choice. Please try again."
        read -p "Press Enter to continue..."
    fi
done