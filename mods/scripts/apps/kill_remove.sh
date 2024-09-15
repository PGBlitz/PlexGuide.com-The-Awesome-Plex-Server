#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
HOTPINK="\033[1;35m"  # Hotpink color for the proceed PIN
BOLD="\033[1m"
NC="\033[0m" # No color

app_name=$1

# Function: stop_and_remove_app
stop_and_remove_app() {
    while true; do
        clear
        echo "This action will stop and remove the Docker container for $app_name."
        echo "Your appdata will not be lost."
        echo ""

        # Generate two random 4-digit codes: one to proceed, one to exit
        proceed_code=$(printf "%04d" $((RANDOM % 10000)))
        exit_code=$(printf "%04d" $((RANDOM % 10000)))

        # Prompt the user to confirm with the generated pin codes
        echo -e "To proceed, enter this PIN [${HOTPINK}${BOLD}${proceed_code}${NC}]"
        echo -e "To cancel, enter this PIN [${GREEN}${BOLD}${exit_code}${NC}]"
        
        # Read the user input
        echo ""
        read -p "Enter PIN > " user_input
        
        if [[ "$user_input" == "$proceed_code" ]]; then
            # If the user enters the correct proceed pin code, stop and remove the container
            echo ""
            echo "Stopping and removing the existing container for $app_name ..."
            docker stop "$app_name" && docker rm "$app_name"
            break
        elif [[ "$user_input" == "$exit_code" ]]; then
            # If the user enters the exit pin code, cancel the operation
            echo "Operation cancelled."
            break
        else
            # If the input is invalid, clear the screen and repeat the prompt
            clear
            echo -e "${RED}Invalid input. Please enter the correct PIN.${NC}"
        fi
    done
}

# Run the stop and remove function
stop_and_remove_app
