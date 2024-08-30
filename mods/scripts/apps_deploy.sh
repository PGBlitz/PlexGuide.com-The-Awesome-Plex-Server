#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m" # No color

# Arguments
app_name=$1
script_type=$2  # 'personal' for apps_personal_support, 'official' for apps_support

# Function: redeploy_app
redeploy_app() {
    # Check if lspci is installed; detect NVIDIA graphics cards
    if ! command -v lspci &> /dev/null; then
        if [ -f /etc/debian_version ]; then
            sudo apt-get update && sudo apt-get install -y pciutils
        fi
    fi

    echo "Deploying $app_name"
    
    # Determine which support script to source
    if [[ "$script_type" == "personal" ]]; then
        source /pg/scripts/apps_support.sh "$app_name" "$script_type" && appsourcing
        source "/pg/p_apps/$app_name/$app_name.app"
    elif [[ "$script_type" == "official" ]]; then
        source /pg/scripts/apps_support.sh "$app_name" "$script_type" && appsourcing
        source "/pg/apps/$app_name/$app_name.app"
    else
        echo -e "${RED}Invalid script type specified. Use 'personal' or 'official'.${NC}"
        exit 1
    fi

    deploy_container "$app_name"  # Call the deploy_container function
}

# Deployment logic
clear
deploy_code=$(printf "%04d" $((RANDOM % 10000)))

while true; do
    clear
    echo -e "Deploy/Redeploy $app_name?"
    echo -e "Type [${RED}${deploy_code}${NC}] to proceed or [${GREEN}Z${NC}] to cancel: "
    
    read -p "" deploy_choice
    
    if [[ "$deploy_choice" == "$deploy_code" ]]; then
        echo ""
        docker stop "$app_name" && docker rm "$app_name"
        redeploy_app  # Deploy the container after stopping/removing
        break
    elif [[ "${deploy_choice,,}" == "z" ]]; then
        echo "Operation cancelled."
        break
    else
        echo "Invalid choice. Please try again."
        read -p "Press Enter to continue..."
    fi
done
