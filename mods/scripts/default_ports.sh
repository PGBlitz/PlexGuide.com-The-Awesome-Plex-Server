#!/bin/bash

# Define config file and load ports status
config_file="/pg/config/default_ports.cfg"
if [ ! -f "$config_file" ]; then
    echo "ports=open" > "$config_file"
fi
source "$config_file"

# Function to display the header
show_header() {
    clear
    if [ "$ports" == "open" ]; then
        port_status="\033[31m[Open]\033[0m"  # Red [Open]
    else
        port_status="\033[32m[Closed]\033[0m"  # Green [Closed]
    fi
    echo -e "\033[1;33mDefault Port Protection:\033[0m $port_status"  # Bold gold for Default Port Protection
}

# Menu options
show_menu() {
    echo ""
    if [ "$ports" == "open" ]; then
        echo -e "[\033[1;32mC\033[0m] Close Ports by Default"  # Bold Green 'C'
    else
        echo -e "[\033[1;31mO\033[0m] Open Ports by Default"  # Bold Red 'O'
    fi
    echo -e "[\033[1;35mZ\033[0m] Exit\n"  # Bold Purple 'Z'
}

# Function to prompt user for PIN
handle_pin() {
    local action=$1
    while true; do
        echo ""
        # Generate new PINs every time
        pin_forward=$((RANDOM % 9000 + 1000))  # 4-digit random number
        pin_exit=$((RANDOM % 9000 + 1000))     # 4-digit random number

        echo -e "To proceed, enter this PIN: \033[95m$pin_forward\033[0m"  # Hot pink forward PIN
        echo -e "To exit, enter this PIN: \033[32m$pin_exit\033[0m"        # Green exit PIN

        echo ""
        read -p "Enter PIN > " user_pin
        if [ "$user_pin" == "$pin_forward" ]; then
            if [ "$action" == "O" ]; then
                ports="open"
            else
                ports="closed"
            fi
            echo "ports=$ports" > "$config_file"
            echo -e "\n\033[33mNOTE: This is a default change and does not affect apps that are deployed.\033[0m"
            echo "Press [ENTER] to Acknowledge"
            read
            break
        elif [ "$user_pin" == "$pin_exit" ]; then
            # Return to the main menu if exit PIN is entered
            return
        else
            echo ""
            echo "Invalid PIN. Try again."
        fi
    done
}

# Function to prompt user for action
handle_choice() {
    local action=$1
    echo ""
    if [ "$action" == "O" ]; then
        echo -e "\033[31mWarning: Are you sure you want to OPEN all ports by default?\033[0m"
    elif [ "$action" == "C" ];then
        echo -e "\033[31mWarning: Are you sure you want to CLOSE all ports by default?\033[0m"
    fi
    handle_pin "$action"
}

# Main loop
while true; do
    show_header
    show_menu
    read -p "Select an Option > " choice

    case "$choice" in
        O|o)
            if [ "$ports" == "closed" ]; then
                handle_choice "O"
            else
                echo "Option is hidden. Please select a valid option."
            fi
            ;;
        C|c)
            if [ "$ports" == "open" ]; then
                handle_choice "C"
            else
                echo "Option is hidden. Please select a valid option."
            fi
            ;;
        Z|z)
            exit 0  # Truly exit the script when Z is selected
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
done
