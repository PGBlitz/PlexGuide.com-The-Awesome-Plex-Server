#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m" # No color

app_name=$1
config_path="/pg/personal_configs/$app_name.cfg"

# Function to install nano if it's not installed
install_nano_if_missing() {
    if ! command -v nano &> /dev/null; then
        echo -e "${RED}Nano editor is not installed. Installing nano...${NC}"

        # Detect package manager and install nano
        if [ -f /etc/debian_version ]; then
            sudo apt-get update && sudo apt-get install -y nano
        elif [ -f /etc/redhat-release ]; then
            sudo yum install -y nano
        elif [ -f /etc/alpine-release ]; then
            sudo apk add nano
        else
            echo -e "${RED}Unsupported OS. Please install nano manually.${NC}"
            exit 1
        fi

        # Verify installation
        if command -v nano &> /dev/null; then
            echo -e "${GREEN}Nano editor installed successfully.${NC}"
        else
            echo -e "${RED}Failed to install nano. Please install it manually.${NC}"
            exit 1
        fi
    fi
}

# Check and install nano if missing
install_nano_if_missing

clear
edit_code=$(printf "%04d" $((RANDOM % 10000)))

while true; do
    clear
    echo -e "${RED}Warning: This is an advanced option.${NC}"
    echo "Visit https://plexguide.com/wiki/link-not-set for more information."
    echo ""
    echo "This will allow you to modify the current config file."
    echo "The Docker container will be stopped and removed if running."
    echo "You must deploy the Docker container again to accept your changes."
    echo ""
    echo -e "Do you want to proceed? Type [${RED}${edit_code}${NC}] to proceed or [${GREEN}Z${NC}] to cancel: "
    
    read -p "" edit_choice
    if [[ "$edit_choice" == "$edit_code" ]]; then
        # Check if the config file exists
        if [[ ! -f "$config_path" ]]; then
            echo "Config file $config_path does not exist. Creating a new one."
            touch "$config_path"
        fi

        # Capture file's modification time before editing
        before_edit=$(stat -c %Y "$config_path")

        # Open the config file in nano for editing
        nano "$config_path"
        
        # Check if nano exited successfully
        if [[ $? -ne 0 ]]; then
            echo -e "${RED}Error: Failed to edit the config file.${NC}"
            continue
        fi

        # Capture file's modification time after editing
        after_edit=$(stat -c %Y "$config_path")

        # Check if the config file was modified
        if [[ "$before_edit" != "$after_edit" ]]; then
            # Check if Docker is installed
            if ! command -v docker &> /dev/null; then
                echo "Docker is not installed or not running."
                continue
            fi

            # Stop and remove the Docker container if running
            if docker ps --filter "name=^/${app_name}$" --format "{{.Names}}" | grep -w "$app_name" &> /dev/null; then
                echo ""
                echo "Stopping and removing the existing container for $app_name ..."
                docker stop "$app_name" && docker rm "$app_name"
            else
                echo "Container $app_name is not running."
            fi
        else
            echo "No changes detected in the config file. No need to stop the container."
        fi

        break
    elif [[ "${edit_choice,,}" == "z" ]]; then
        echo "Operation cancelled."
        break
    else
        # Invalid response: clear the screen and repeat the prompt without any message
        clear
    fi
done
