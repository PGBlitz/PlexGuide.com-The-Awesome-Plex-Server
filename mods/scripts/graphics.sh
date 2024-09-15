#!/bin/bash

# Combined GPU Driver Management Script

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
HOTPINK="\033[1;35m"
BOLD="\033[1m"
NC="\033[0m" # No color

# Function to check if Intel Top is installed
check_intel_top_installed() {
    if command -v intel_gpu_top &> /dev/null; then
        echo -e "${GREEN}[Installed]${NC}"
        return 0
    else
        echo -e "${RED}[Not Installed]${NC}"
        return 1
    fi
}

# Function to install Intel Top
install_intel_top() {
    if command -v intel_gpu_top &> /dev/null; then
        echo "Intel Top is already installed. Upgrading to the latest version..."
        sudo apt-get update && sudo apt-get upgrade intel-gpu-tools -y
    else
        echo "Installing Intel Top..."
        sudo apt-get update && sudo apt-get install intel-gpu-tools -y
    fi
    echo -e "${GREEN}Intel Top installation/upgrade complete.${NC}"
}

# Function to uninstall Intel Top
uninstall_intel_top() {
    if command -v intel_gpu_top &> /dev/null; then
        echo "Uninstalling Intel Top..."
        sudo apt-get remove intel-gpu-tools -y
        echo -e "${GREEN}Intel Top has been uninstalled.${NC}"
    else
        echo -e "${RED}Intel Top cannot be uninstalled because it is not installed.${NC}"
    fi
}

# Function to check if NVIDIA drivers are installed
check_nvidia_drivers_installed() {
    if command -v nvidia-smi &> /dev/null; then
        echo -e "${GREEN}[Installed]${NC}"
        return 0
    else
        echo -e "${RED}[Not Installed]${NC}"
        return 1
    fi
}

# Function to install NVIDIA drivers
install_nvidia_drivers() {
    if command -v nvidia-smi &> /dev/null; then
        echo "NVIDIA drivers are already installed. Upgrading to the latest version..."
        sudo apt-get update && sudo apt-get upgrade -y
    else
        echo "Installing NVIDIA drivers..."
        sudo apt-get update
        sudo apt-get install -y nvidia-driver-460  # Example, adjust as needed
    fi
    echo -e "${GREEN}NVIDIA drivers installation/upgrade complete.${NC}"
}

# Function to uninstall NVIDIA drivers
uninstall_nvidia_drivers() {
    if command -v nvidia-smi &> /dev/null; then
        echo "Uninstalling NVIDIA drivers..."
        sudo apt-get remove --purge nvidia-driver-* -y
        echo -e "${GREEN}NVIDIA drivers have been uninstalled.${NC}"
    else
        echo -e "${RED}NVIDIA drivers cannot be uninstalled because they are not installed.${NC}"
    fi
}

# Function to generate a random 4-digit code
generate_code() {
    echo $((RANDOM % 9000 + 1000))
}

# Main menu for Intel GPU management
intel_top_menu() {
    while true; do
        clear
        echo -e "${HOTPINK}PG: Intel Top Management${NC}"
        echo -n "Status: "
        
        if check_intel_top_installed; then
            echo ""
            echo "I) Reinstall/Upgrade Intel Top"
            echo "U) Uninstall Intel Top"
        else
            echo ""
            echo "I) Install Intel Top"
        fi
        
        echo "Z) Exit"
        echo ""  # Space between options and input prompt

        # Prompt the user for input
        read -p "Enter your choice: " choice

        case ${choice,,} in  # Convert input to lowercase for i/I, u/U, z/Z handling
            i)
                clear
                proceed_code=$(generate_code)
                exit_code=$(generate_code)

                echo -e "To proceed, enter this PIN [${HOTPINK}${BOLD}${proceed_code}${NC}]"
                echo -e "To cancel, enter this PIN [${GREEN}${BOLD}${exit_code}${NC}]"
                read -p "Enter PIN > " input_code

                if [[ "$input_code" == "$proceed_code" ]]; then
                    install_intel_top
                elif [[ "$input_code" == "$exit_code" ]]; then
                    continue
                else
                    echo "Incorrect code. Returning to the menu..."
                fi
                read -p "Press Enter to continue..."
                ;;
            u)
                clear
                proceed_code=$(generate_code)
                exit_code=$(generate_code)

                echo -e "To proceed, enter this PIN [${HOTPINK}${BOLD}${proceed_code}${NC}]"
                echo -e "To cancel, enter this PIN [${GREEN}${BOLD}${exit_code}${NC}]"
                read -p "Enter PIN > " input_code

                if [[ "$input_code" == "$proceed_code" ]]; then
                    uninstall_intel_top
                elif [[ "$input_code" == "$exit_code" ]]; then
                    continue
                else
                    echo "Incorrect code. Returning to the menu..."
                fi
                read -p "Press Enter to continue..."
                ;;
            z)
                echo "Returning to the main menu..."
                break
                ;;
            *)
                echo "Invalid option, please try again."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Main menu for NVIDIA driver management
nvidia_drivers_menu() {
    while true; do
        clear
        echo -e "${HOTPINK}PG: NVIDIA Drivers Management${NC}"
        echo -n "Status: "
        
        if check_nvidia_drivers_installed; then
            echo ""
            echo "I) Reinstall/Upgrade NVIDIA Drivers"
            echo "U) Uninstall NVIDIA Drivers"
        else
            echo ""
            echo "I) Install NVIDIA Drivers"
        fi
        
        echo "Z) Exit"
        echo ""  # Space between options and input prompt

        # Prompt the user for input
        read -p "Enter your choice: " choice

        case ${choice,,} in  # Convert input to lowercase for i/I, u/U, z/Z handling
            i)
                echo ""
                proceed_code=$(generate_code)
                exit_code=$(generate_code)

                echo -e "To proceed, enter this PIN [${HOTPINK}${BOLD}${proceed_code}${NC}]"
                echo -e "To cancel, enter this PIN [${GREEN}${BOLD}${exit_code}${NC}]"
                read -p "Enter PIN > " input_code

                if [[ "$input_code" == "$proceed_code" ]]; then
                    install_nvidia_drivers
                elif [[ "$input_code" == "$exit_code" ]]; then
                    continue
                else
                    echo "Incorrect code. Returning to the menu..."
                fi
                read -p "Press Enter to continue..."
                ;;
            u)
                echo ""
                proceed_code=$(generate_code)
                exit_code=$(generate_code)

                echo -e "To proceed, enter this PIN [${HOTPINK}${BOLD}${proceed_code}${NC}]"
                echo -e "To cancel, enter this PIN [${GREEN}${BOLD}${exit_code}${NC}]"
                read -p "Enter PIN > " input_code

                if [[ "$input_code" == "$proceed_code" ]]; then
                    uninstall_nvidia_drivers
                elif [[ "$input_code" == "$exit_code" ]]; then
                    continue
                else
                    echo "Incorrect code. Returning to the menu..."
                fi
                read -p "Press Enter to continue..."
                ;;
            z)
                echo "Returning to the main menu..."
                break
                ;;
            *)
                echo "Invalid option, please try again."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Main menu for GPU Driver Management
main_menu() {
    while true; do
        clear
        echo "GPU Driver Management"
        echo
        echo "I) Intel"
        echo "N) NVIDIA"
        echo "Z) Exit"
        echo

        # Prompt the user for input
        read -p "Select an Option > " user_choice

        case "$user_choice" in
            I|i)
                echo "Redirecting to Intel driver management..."
                intel_top_menu
                ;;
            N|n)
                echo "Redirecting to NVIDIA driver management..."
                nvidia_drivers_menu
                ;;
            Z|z)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo "Invalid choice. Please try again."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Run the main menu
main_menu
