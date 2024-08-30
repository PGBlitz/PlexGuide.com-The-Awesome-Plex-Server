#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m" # No color

# Arguments
app_name=$1

# Function: redeploy_app
redeploy_app() {
    echo "Debug: Entering redeploy_app function."  # Debugging
    read -p "Press Enter to continue..."

    # Check if lspci is installed; detect NVIDIA graphics cards
    echo "Debug: Checking for lspci command."  # Debugging
    read -p "Press Enter to continue..."
    if ! command -v lspci &> /dev/null; then
        echo "Debug: lspci not found, checking if the system is Debian-based."  # Debugging
        read -p "Press Enter to continue..."
        if [ -f /etc/debian_version ]; then
            echo "Debug: Installing pciutils on Debian-based system."  # Debugging
            read -p "Press Enter to continue..."
            sudo apt-get update && sudo apt-get install -y pciutils
        fi
    fi

    echo "Deploying $app_name"
    read -p "Press Enter to continue..."

    echo "Debug: Sourcing apps_personal_support.sh for $app_name."  # Debugging
    read -p "Press Enter to continue..."
    source /pg/scripts/apps_personal_support.sh "$app_name" && appsourcing

    echo "Debug: Sourcing the app-specific script /pg/p_apps/$app_name/$app_name.app."  # Debugging
    read -p "Press Enter to continue..."
    source "/pg/p_apps/$app_name/$app_name.app"  # Source the app script to load functions

    echo "Debug: Calling deploy_container for $app_name."  # Debugging
    read -p "Press Enter to continue..."
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
        echo "Debug: Correct deploy code entered. Stopping and removing Docker container."  # Debugging
        read -p "Press Enter to continue..."
        echo ""
        docker stop "$app_name" && docker rm "$app_name"

        echo "Debug: Calling redeploy_app function for $app_name."  # Debugging
        read -p "Press Enter to continue..."
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
