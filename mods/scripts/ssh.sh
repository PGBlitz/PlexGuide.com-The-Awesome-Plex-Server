#!/bin/bash

# Configuration file path
SSH_CONFIG_FILE="/pg/config/ssh.cfg"

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
HOTPINK="\033[1;35m"
BOLD="\033[1m"
NC="\033[0m" # No color

# Function to load or initialize SSH configuration
load_ssh_config() {
    if [[ -f "$SSH_CONFIG_FILE" ]]; then
        source "$SSH_CONFIG_FILE"
    else
        echo "PORT=22" > "$SSH_CONFIG_FILE"
        source "$SSH_CONFIG_FILE"
    fi
}

# Function to check if SSH is active
check_ssh_status() {
    systemctl is-active --quiet ssh && SSH_STATUS="${GREEN}Active - SSH Port Open${NC}" || SSH_STATUS="${RED}Inactive - SSH Port Closed${NC}"
}

# Function to detect the SSH port from the config
detect_ssh_port() {
    if [[ -f "$SSH_CONFIG_FILE" ]]; then
        source "$SSH_CONFIG_FILE"
    fi
    SSH_PORT=${PORT:-"unknown"}
}

# Function to display the SSH status and port
display_ssh_info() {
    check_ssh_status
    detect_ssh_port
    echo -e "${HOTPINK}PlexGuide SSH Management${NC}"
    echo ""  # Space for separation
    echo -e "SSH Status: $SSH_STATUS"
    echo "SSH Port: $SSH_PORT"
    echo ""  # Space for separation
}

# Function to prompt for a two-line random 4-digit PIN
require_pin() {
    clear
    local proceed_code=$(printf "%04d" $((RANDOM % 10000)))
    local exit_code=$(printf "%04d" $((RANDOM % 10000)))
    
    while true; do
        echo -e "To proceed, enter this PIN [${HOTPINK}${BOLD}${proceed_code}${NC}]"
        echo -e "To cancel, enter this PIN [${GREEN}${BOLD}${exit_code}${NC}]"
        echo ""
        read -p "Enter PIN > " user_input

        if [[ "$user_input" == "$proceed_code" ]]; then
            return 0  # PIN is correct
        elif [[ "$user_input" == "$exit_code" ]]; then
            echo "Operation cancelled."
            return 1  # User chose to exit
        else
            echo -e "${RED}Invalid response.${NC} Please try again."
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

            # Close the previous port if it was different
            if [[ "$new_port" != "$SSH_PORT" ]]; then
                sudo ufw delete allow $SSH_PORT/tcp
            fi

            # Reload and restart SSH service to apply changes
            sudo systemctl reload sshd
            sudo systemctl enable ssh
            sudo systemctl restart ssh

            # Update SSH configuration file
            echo "PORT=$new_port" > "$SSH_CONFIG_FILE"
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
        echo -e "${RED}Warning:${NC} Since SSH has been uninstalled, your remote session will end once you disconnect from the server."
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
        sudo ufw delete allow $SSH_PORT/tcp
        echo "SSH has been disabled."
        echo -e "${RED}Warning:${NC} Since SSH has been disabled, your remote session will end once you disconnect from the server."
    fi
    read -p "Press Enter to return to the menu..."
}

# Function to manage SSH port
port_management() {
    if require_pin; then
        echo -n "Enter the new SSH port number: "
        read new_port
        if [[ $new_port -gt 0 && $new_port -le 65000 ]]; then
            # Close the old SSH port
            sudo ufw delete allow $SSH_PORT/tcp

            # Update SSH configuration
            sudo sed -i "s/^Port .*/Port $new_port/" /etc/ssh/sshd_config
            sudo ufw allow $new_port/tcp
            sudo systemctl reload sshd

            # Update SSH configuration file
            echo "PORT=$new_port" > "$SSH_CONFIG_FILE"
            echo "SSH port has been changed to $new_port."

            # Display warning for remote SSH sessions
            echo -e "${RED}Warning:${NC} Since the port has changed, your remote session will end once you disconnect from the server."
            echo -e "You must use the command \`ssh -p $new_port <IP_ADDRESS>\` to reconnect."
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
    load_ssh_config  # Load or initialize SSH config
    display_ssh_info  # Display current SSH status and port

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
