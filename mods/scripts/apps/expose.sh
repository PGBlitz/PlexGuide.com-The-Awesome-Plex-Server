#!/bin/bash

# Combined script to handle exposing the app's port

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
ORANGE="\033[0;33m"
NC="\033[0m" # No color

# Arguments
app_name="$1"
script_type="$2"  # 'personal' for personal configurations, 'official' for official configurations

# Determine the correct config path
if [[ "$script_type" == "personal" ]]; then
    config_path="/pg/personal_configs/${app_name}.cfg"
elif [[ "$script_type" == "official" ]]; then
    config_path="/pg/config/${app_name}.cfg"
else
    echo -e "${RED}Invalid script type specified. Use 'personal' or 'official'.${NC}"
    exit 1
fi

clear

# Default to expose="" if not set in config
if ! grep -q '^expose=' "$config_path"; then
    echo 'expose=""' >> "$config_path"
fi

# Source the config to get the current expose setting
source "$config_path"

# Generate random 4-digit codes for "yes" and "no"
yes_code=$(printf "%04d" $((RANDOM % 10000)))
no_code=$(printf "%04d" $((RANDOM % 10000)))

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
    echo -e "Type [${GREEN}${yes_code}${NC}] [${RED}${no_code}${NC}] or [${ORANGE}Z${NC}]: "
    read -p "" user_input

    if [[ "$user_input" == "$yes_code" ]]; then
        echo "Port will be exposed."
        sed -i 's|^expose=.*|expose=|' "$config_path"
        break
    elif [[ "$user_input" == "$no_code" ]]; then
        echo "Port will remain private."
        sed -i 's|^expose=.*|expose=127.0.0.1:|' "$config_path"
        break
    elif [[ "${user_input,,}" == "z" ]]; then
        echo "Operation cancelled."
        exit 0
    else
        clear
        echo -e "${RED}Invalid input. Please try again.${NC}"
    fi
done

# Stop and remove the Docker container
echo "Stopping and removing the Docker container..."
docker stop "$app_name" && docker rm "$app_name"
echo "Docker container has been stopped and removed."

# Inform the user to redeploy the container
echo ""
echo -e "${RED}Please redeploy the Docker container from the main menu.${NC}"
echo ""
read -p "Press Enter to acknowledge..."
