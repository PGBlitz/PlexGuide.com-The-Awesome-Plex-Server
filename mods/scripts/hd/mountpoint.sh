#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[0;33m"
NC="\033[0m"  # No color

# Config file to track mount points
config_file="/pg/config/hd.cfg"

# Ensure the config directory exists
mkdir -p /pg/config

# Function to check if 'bc' is installed and install it if missing
check_bc() {
    if ! command -v bc &> /dev/null; then
        echo -e "${YELLOW}The 'bc' command is required but not installed.${NC}"
        echo -e "${YELLOW}Installing 'bc'...${NC}"
        
        # Check if the system uses apt or yum and install 'bc'
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y bc
        elif command -v yum &> /dev/null; then
            sudo yum install -y bc
        else
            echo -e "${RED}Unsupported package manager. Please install 'bc' manually.${NC}"
            exit 1
        fi

        echo -e "${GREEN}'bc' has been installed.${NC}"
    fi
}

# Function to convert bytes to TB and format to 2 decimal places
convert_to_tb() {
    local size_in_bytes="$1"

    # Ensure size is numeric before passing it to bc
    if [[ "$size_in_bytes" =~ ^[0-9]+$ ]]; then
        printf "%.2f" $(echo "scale=2; $size_in_bytes / 1000000000000" | bc -l)
    else
        echo "0.00"  # Return 0.00 if size is not valid
    fi
}

# Function to list available drives in TB format
list_drives() {
    echo -e "${BLUE}Available Drives (Sizes in TB):${NC}"

    # Get drive information with sizes in bytes and format size in TB
    lsblk -b -n -o NAME,SIZE,MOUNTPOINT | grep -E '^[a-z]' | while read -r drive_info; do
        drive_name=$(echo "$drive_info" | awk '{print $1}')
        size_in_bytes=$(echo "$drive_info" | awk '{print $2}')
        size_in_tb=$(convert_to_tb "$size_in_bytes")
        current_mount=$(echo "$drive_info" | awk '{print $3}')

        if [ -z "$current_mount" ]; then
            current_mount=$(get_existing_mount_point "$drive_name")
        fi

        printf "%-4s %-8s %s\n" "$drive_name" "${size_in_tb}TB" "${current_mount:-Not mounted}"
    done
    echo ""
}

# Function to load existing mount point from config file
get_existing_mount_point() {
    local drive="$1"
    if [ -f "$config_file" ]; then
        grep "^$drive:" "$config_file" | cut -d':' -f2
    fi
}

# Function to update mount point in the config file
update_mount_point() {
    local drive="$1"
    local new_mount_point="$2"

    # Remove old entry for the drive if it exists
    sed -i "/^$drive:/d" "$config_file"

    # Add the new mount point for the drive
    echo "$drive:$new_mount_point" >> "$config_file"
}

# Function to remove old mount point if it exists
remove_old_mount_point() {
    local old_mount_point="$1"

    if [ -n "$old_mount_point" ] && [ -d "$old_mount_point" ]; then
        echo -e "${YELLOW}Removing old mount point $old_mount_point...${NC}"
        sudo umount "$old_mount_point" &> /dev/null
        sudo rm -rf "$old_mount_point"
    fi
}

# Function to change the mount point
change_mount_point() {
    list_drives
    echo -e "${BLUE}Select a drive to remount (e.g., sda, sdb):${NC}"
    read -p "> " drive

    if [ ! -b "/dev/$drive" ]; then
        echo -e "${RED}Invalid drive. Please ensure the drive exists.${NC}"
        return
    fi

    # Get existing mount point from config file
    old_mount_point=$(get_existing_mount_point "$drive")

    # Ask for new mount point name
    echo -e "${BLUE}Enter the new mount point name (will mount under /mnt/pg/):${NC}"
    read -p "> " mount_name
    new_mount_point="/mnt/pg/${mount_name}"

    # Remove old mount point if it exists
    remove_old_mount_point "$old_mount_point"

    echo -e "${YELLOW}Creating directory $new_mount_point if it doesn't exist...${NC}"
    sudo mkdir -p "$new_mount_point"  # Create the full directory path if it doesn't exist

    # Unmount if already mounted and remount to the new mount point
    if mount | grep "/dev/${drive}1" &> /dev/null; then
        echo -e "${YELLOW}Unmounting /dev/$drive...${NC}"
        sudo umount "/dev/${drive}1"
    fi

    echo -e "${YELLOW}Mounting /dev/$drive to $new_mount_point...${NC}"
    sudo mount "/dev/${drive}1" "$new_mount_point"

    # Update the config file with the new mount point
    update_mount_point "$drive" "$new_mount_point"

    echo -e "${GREEN}Drive /dev/$drive is now mounted at $new_mount_point.${NC}"
}

# Main menu
main_menu() {
    while true; do
        clear
        echo -e "${BLUE}PG: Drive Management${NC}"
        echo "1) Change Mount Point"
        echo "2) Exit"
        echo ""

        read -p "Select an option > " choice
        case $choice in
            1) change_mount_point ;;
            2) exit 0 ;;
            *) echo -e "${RED}Invalid option, please try again.${NC}" ;;
        esac
        read -p "Press Enter to return to the menu..."
    done
}

# Check for 'bc' and install if necessary
check_bc

# Start the menu
main_menu