#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
NC="\033[0m" # No color

# Function to clear the screen and display the main header
clear_screen() {
    clear
    echo -e "${RED}PG: Firewall Port Security${NC}"
    echo
}

# Function to generate a random 4-digit code
generate_code() {
    echo $((RANDOM % 9000 + 1000))
}

# Function to check if a port is open
is_port_open() {
    local port=$1
    sudo ufw status | grep -qw "$port"
}

# Function to validate the port number
validate_port() {
    local port=$1
    if [[ $port -ge 1 && $port -le 65535 ]]; then
        return 0
    else
        echo -e "${RED}Invalid port number. Please enter a valid port between 1 and 65535.${NC}"
        return 1
    fi
}

# Function to print wrapped text with color support
print_wrapped_text() {
    local text="$1"
    local color="$2"
    echo -e "$color$(echo "$text" | fold -s -w 80)$NC"
}

# Function to open a port for both IPv4 and IPv6, TCP and UDP
open_port() {
    clear_screen
    print_wrapped_text "PG: Firewall Security - Open Port" "$BLUE"
    echo
    print_wrapped_text "WARNING: This is an advanced configuration." "$RED"
    print_wrapped_text "Opening a port will open it for IPv4 and IPv6 addresses and for TCP and UDP. Understand the consequences of opening a firewall port and the security risk involved." "$NC"
    echo

    read -p "$(echo -e "Enter the port number you would like to open or type [${GREEN}exit${NC}] to cancel: ")" port_number

    if [[ "${port_number,,}" == "exit" ]]; then
        echo "Operation cancelled."
        return
    fi

    if is_port_open $port_number; then
        print_wrapped_text "Port $port_number is already open." "$RED"
    elif validate_port $port_number; then
        code=$(generate_code)
        while true; do
            read -p "$(echo -e "Enter the 4-digit code [${RED}${code}${NC}] to proceed or [${GREEN}exit${NC}] to cancel: ")" input_code
            if [[ "$input_code" == "$code" ]]; then
                sudo ufw allow $port_number/tcp
                sudo ufw allow $port_number/udp
                print_wrapped_text "Port $port_number has been opened for TCP and UDP on both IPv4 and IPv6." "$GREEN"
                break
            elif [[ "${input_code,,}" == "exit" ]]; then
                print_wrapped_text "Operation cancelled." "$NC"
                break
            else
                print_wrapped_text "Incorrect code. Please try again." "$RED"
            fi
        done
    fi

    read -p "Press Enter to return..."
}

# Function to close a port for both IPv4 and IPv6, TCP and UDP
close_port() {
    clear_screen
    print_wrapped_text "PG: Firewall Security - Close Port" "$BLUE"
    echo
    print_wrapped_text "WARNING: Closing a port will restrict access." "$RED"
    print_wrapped_text "Closing a port will close it for both IPv4 and IPv6 addresses and for TCP and UDP. Understand the consequences of closing a firewall port and the potential access restrictions involved." "$NC"
    echo

    read -p "$(echo -e "Enter the port number you would like to close or type [${GREEN}exit${NC}] to cancel: ")" port_number

    if [[ "${port_number,,}" == "exit" ]]; then
        echo "Operation cancelled."
        return
    fi

    if ! is_port_open $port_number; then
        print_wrapped_text "Port $port_number is already closed." "$RED"
    elif validate_port $port_number; then
        code=$(generate_code)
        while true; do
            read -p "$(echo -e "Enter the 4-digit code [${RED}${code}${NC}] to proceed or [${GREEN}exit${NC}] to cancel: ")" input_code
            if [[ "$input_code" == "$code" ]]; then
                sudo ufw deny $port_number/tcp
                sudo ufw deny $port_number/udp
                print_wrapped_text "Port $port_number has been closed for TCP and UDP on both IPv4 and IPv6." "$GREEN"
                break
            elif [[ "${input_code,,}" == "exit" ]]; then
                print_wrapped_text "Operation cancelled." "$NC"
                break
            else
                print_wrapped_text "Incorrect code. Please try again." "$RED"
            fi
        done
    fi

    read -p "Press Enter to return..."
}

# Function to view open ports on the firewall
view_open_ports() {
    clear_screen
    echo -e "${RED}PG: Firewall Open Ports Checker${NC}"
    echo

    # Gather the list of unique open ports
    open_ports=$(sudo ufw status | grep -i "allow" | awk '{print $1}' | sed 's/\/.*//' | sort -n | uniq | tr '\n' ', ' | sed 's/, $//')

    # Print open ports in wrapped lines
    print_wrapped_text "$open_ports" "$NC"

    echo -e "Press [${GREEN}Enter${NC}] to Exit"
    read -p ""
}

# Main menu function
main_menu() {
    while true; do
        clear_screen
        echo "V) View Open Ports"
        echo "O) Open a Port"
        echo "C) Close a Port"
        echo "Z) Exit"
        echo

        read -p "Choose an option: " choice

        case "${choice,,}" in  # Convert input to lowercase
            v) view_open_ports ;;
            o) open_port ;;
            c) close_port ;;
            z) exit 0 ;;
            *) echo "Invalid option. Please try again." ;;
        esac
    done
}

# Start the main menu
main_menu
