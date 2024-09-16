#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
NC="\033[0m" # No color

# Function to check if SSH is active
check_ssh_status() {
    systemctl is-active --quiet ssh && SSH_STATUS="${GREEN}Active - SSH Port Open${NC}" || SSH_STATUS="${RED}Inactive - SSH Port Closed${NC}"
}

# Function to detect the SSH port
detect_ssh_port() {
    SSH_PORT=$(ss -tuln | grep -E ':(22|[0-9]{2,5}) ' | grep ssh | awk '{print $5}' | cut -d: -f2)
    if [[ -z "$SSH_PORT" ]]; then
        SSH_PORT="unknown"
    fi
}

# Function to display the SSH status and port
display_ssh_info() {
    check_ssh_status
    detect_ssh_port
    echo -e "${BLUE}PlexGuide SSH Management${NC}"
    echo ""  # Space for separation
    echo -e "SSH Status: $SSH_STATUS"
    echo "SSH Port: $SSH_PORT"
    echo ""  # Space for separation
}

# Function to prompt for a random 4-digit PIN
require_pin() {
    clear
    local pin=$(printf "%04d" $((RANDOM % 10000)))
    while true; do
        read -p "$(echo -e "To proceed, type [${GREEN}${pin}${NC}] or type [${RED}exit${NC}] to cancel: ")" user_input
        if [[ "$user_input" == "$pin" ]]; then
            return 0  # PIN is correct
        elif [[ "${user_input,,}" == "exit" ]]; then
            echo "Operation cancelled."
            return 1  # User chose to exit
        else
            echo -e "${RED}Invalid response.${NC} Please type [${GREEN}${pin}${NC}] or [${RED}exit${NC}]."
        fi
    done
}

# Function to install SSH server
install_ssh() {
    if require_pin; then
        echo -n "Enter the SSH port number (1-65000): "
        read new_port
        if [[ $new_port -ge 1 && $new_port -le 65000 ]]; then
            if [[ $new_port -eq 80 || $new_port -eq 443 || $new_port -eq 563 ]]; then
                echo -e "${RED}Warning: Ports 80, 443, and 563 are commonly used by other services. Consider using a different port.${NC}"
            fi

            # Install SSH server
            sudo apt-get update
            sudo apt-get install -y openssh-server

            # Backup the current SSH configuration file
            sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

            # Change SSH port to the selected port
            sudo sed -i "s/^#Port 22/Port $new_port/" /etc/ssh/sshd_config

            # Allow the new port through the firewall
            sudo ufw allow $new_port/tcp

            # Reload and restart SSH service to apply changes
            sudo systemctl reload sshd
            sudo systemctl enable ssh
            sudo systemctl restart ssh

            echo "SSH has been installed and configured on port $new_port."
        else
            echo -e "${RED}Invalid port number. Please enter a value between 1 and 65000.${NC}"
        fi
    fi
    read -p "Press Enter to return to the menu..."
}

# Function to uninstall SSH server
uninstall_ssh() {
    if require_pin; then
        sudo apt-get remove -y openssh-server
        sudo apt-get purge -y openssh-server
        sudo ufw delete allow $SSH_PORT/tcp
        echo "SSH server has been uninstalled."
    fi
    read -p "Press Enter to return to the menu..."
}

# Function to enable SSH
enable_ssh() {
    if require_pin; then
        sudo systemctl enable ssh --now
        echo "SSH has been enabled."
    fi
    read -p "Press Enter to return to the menu..."
}

# Function to disable SSH
disable_ssh() {
    if require_pin; then
        sudo systemctl disable ssh --now
        echo "SSH has been disabled."
    fi
    read -p "Press Enter to return to the menu..."
}

# Function to manage SSH port
port_management() {
    if require_pin; then
        echo -n "Enter the new SSH port number: "
        read new_port
        if [[ $new_port -gt 0 && $new_port -le 65000 ]]; then
            sudo sed -i "s/^Port .*/Port $new_port/" /etc/ssh/sshd_config
            sudo ufw allow $new_port/tcp
            sudo systemctl reload sshd
            echo "SSH port has been changed to $new_port."
        else
            echo -e "${RED}Invalid port number. Please enter a value between 1 and 65000.${NC}"
        fi
    fi
    read -p "Press Enter to return to the menu..."
}

# Function for the main menu
main_menu() {
  while true; do
    clear
    display_ssh_info

    # Display the main menu options
    echo "I) Install SSH Server"
    echo "E) Enable SSH"
    echo "D) Disable SSH"
    echo "P) Port Management"
    echo "U) Uninstall SSH Server"
    echo "Z) Exit"
    echo ""  # Space between options and input prompt

    # Prompt the user for input
    read -p "Enter your choice [I/E/D/P/U/Z]: " choice

    case ${choice,,} in  # Convert input to lowercase for i/I, e/E, d/D, p/P, u/U, z/Z handling
      i) install_ssh ;;
      e) enable_ssh ;;
      d) disable_ssh ;;
      p) port_management ;;
      u) uninstall_ssh ;;
      z) exit 0 ;;
      *)
        echo "Invalid option, please try again."
        read -p "Press Enter to continue..."
        ;;
    esac
  done
}

# Call the main menu function
main_menu
