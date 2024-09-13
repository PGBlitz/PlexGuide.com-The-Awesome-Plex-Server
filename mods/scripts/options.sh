#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No color

# Clear the screen at the start
clear

# Load the configuration
load_config

# Function for SSH Management option
ssh_management() {
    clear
    /pg/scripts/ssh.sh
}

# Function to exit the script
exit_script() {
    clear
    echo "Visit https://plexguide.com"
    echo -e "To Start Again - Type: [${RED}pg${NC}] or [${RED}plexguide${NC}]"
    echo ""  # Space before exiting
    exit 0
}

# Function for the main menu
main_menu() {
  while true; do
    clear
    echo -e "${BLUE}PlexGuide Options Interface${NC}"
    echo ""  # Blank line for separation
    # Display the main menu options
    echo "G) Graphics Cards"
    echo "S) SSH Management"
    echo "Z) Exit"
    echo ""  # Space between options and input prompt

    # Prompt the user for input
    read -p "Make a Choice > " choice

    case ${choice,,} in  # Convert input to lowercase for g/G, s/S, z/Z handling
      g)
        bash /pg/scripts/graphics.sh
        ;;
      s)
        ssh_management
        ;;
      z)
        exit_script
        ;;
      *)
        echo "Invalid option, please try again."
        read -p "Press Enter to continue..."
        ;;
    esac

  done
}

# Call the main menu function
main_menu
