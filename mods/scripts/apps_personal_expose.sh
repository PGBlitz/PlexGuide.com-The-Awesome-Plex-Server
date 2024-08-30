#!/bin/bash

# External script to handle exposing the app's port

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
ORANGE="\033[0;33m"
NC="\033[0m" # No color

app_name="$1"
config_path="/pg/personal_configs/${app_name}.cfg"

clear

echo "Debug: Script started with app_name=$app_name and config_path=$config_path"  # Debugging
read -p "Press Enter to continue..."

# Default to expose="" if not set in config
if ! grep -q '^expose=' "$config_path"; then
    echo "Debug: 'expose' not found in config, adding default 'expose=\"\"'"  # Debugging
    read -p "Press Enter to continue..."
    echo 'expose=""' >> "$config_path"
fi

# Source the config to get the current expose setting
echo "Debug: Sourcing configuration from $config_path"  # Debugging
read -p "Press Enter to continue..."
source "$config_path"

# Generate random 4-digit codes for "yes" and "no"
yes_code=$(printf "%04d" $((RANDOM % 10000)))
no_code=$(printf "%04d" $((RANDOM % 10000)))

echo "Debug: Generated yes_code=$yes_code and no_code=$no_code"  # Debugging
read -p "Press Enter to continue..."

# Display the prompt
echo -e "${BLUE}Expose Port Configuration for ${app_name}${NC}"
echo ""
echo "Current Setting: ${expose:-"Port Exposed"}"
echo ""
echo -e "Would you like to expose the port?"
echo -e " - Type [${GREEN}${yes_code}${NC}] to expose the port. (access remotely)"
echo -e " - Type [${RED}${no_code}${NC}] to keep it private (127.0.0.1; localhost only)."
echo ""

# Prompt the user for input and validate
while true; do
    echo "Debug: Waiting for user input..."  # Debugging
    echo -e "Type [${GREEN}${yes_code}${NC}] [${RED}${no_code}${NC}] or [${ORANGE}Z${NC}]: "
    read -p "" user_input

    echo "Debug: User input received: $user_input"  # Debugging
    read -p "Press Enter to continue..."

    if [[ "$user_input" == "$yes_code" ]]; then
        echo "Port will be exposed."
        echo "Debug: Changing 'expose' setting in config to expose=."  # Debugging
        read -p "Press Enter to continue..."
        sed -i 's|^expose=.*|expose=|' "$config_path"
        break
    elif [[ "$user_input" == "$no_code" ]]; then
        echo "Port will remain private."
        echo "Debug: Changing 'expose' setting in config to expose=127.0.0.1:."  # Debugging
        read -p "Press Enter to continue..."
        sed -i 's|^expose=.*|expose=127.0.0.1:|' "$config_path"
        break
    elif [[ "${user_input,,}" == "z" ]]; then
        echo "Operation cancelled."
        exit 0
    else
        echo ""
        echo "Debug: Invalid input, waiting for valid input."  # Debugging
        read -p "Press Enter to continue..."
        # Invalid input; clear screen and repeat
    fi
done

# Stop and remove the Docker container
echo "Stopping and removing the Docker container..."
echo "Debug: Executing docker stop and rm for $app_name."  # Debugging
read -p "Press Enter to continue..."
docker stop "$app_name" && docker rm "$app_name"
echo "Docker container has been stopped and removed."

# Inform the user to redeploy the container
echo ""
echo -e "${RED}Please redeploy the Docker container from the main menu.${NC}"
echo ""
read -p "Press Enter to acknowledge..."
