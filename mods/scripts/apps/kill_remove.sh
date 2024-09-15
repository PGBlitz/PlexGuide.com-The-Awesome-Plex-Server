#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m" # No color

app_name=$1

# Function: stop_and_remove_app
stop_and_remove_app() {
    while true; do
        clear
        echo "This action will stop and remove the Docker container for $app_name."
        echo "Your appdata will not be lost."
        echo ""
        
        # Generate a random 4-digit code
        pin_code=$(printf "%04d" $((RANDOM % 10000)))
        
        # Prompt the user to confirm with the generated pin code or to cancel with 'Z'
        echo -e "To proceed, type [${RED}${pin_code}${NC}] to proceed or [${GREEN}Z${NC}] to cancel: "
        
        read -p "" user_input
        
        if [[ "$user_input" == "$pin_code" ]]; then
            # If the user enters the correct pin code, proceed to stop and remove the container
            echo ""
            echo "Stopping and removing the existing container for $app_name ..."
            docker stop "$app_name" && docker rm "$app_name"
            break
        elif [[ "${user_input,,}" == "z" ]]; then
            # If the user types 'Z' or 'z', cancel the operation
            echo "Operation cancelled."
            break
        else
            # If the input is invalid, clear the screen and repeat the prompt
            clear
            echo -e "${RED}Invalid input. Please enter the correct pin code or [Z] to cancel.${NC}"
        fi
    done
}

# Run the stop and remove function
stop_and_remove_app
