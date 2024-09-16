#!/bin/bash

# ANSI color codes for formatting
RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[0;33m"
NC="\033[0m"  # No color

# Config file to store drive information
config_file="/pg/config/hd.cfg"

# Ensure the config directory exists
mkdir -p /pg/config

# Function to list drives and partitions
list_drives() {
    clear
    echo -e "${BLUE}========================="
    echo -e "   Top-Level Drives List   "
    echo -e "=========================${NC}"
    echo -e "${GREEN}Top-Level View of Drives, Partitions, Sizes, and Filesystems:${NC}"
    echo ""
    lsblk -o NAME,SIZE,FSTYPE | grep -E '^[a-z]'
    echo ""
}

# Function to clean old mount points and swaps associated with the selected drive
clean_old_mounts() {
    local drive="$1"
    
    echo -e "${YELLOW}Searching for and cleaning old mount points for /dev/${drive}...${NC}"
    
    mount | grep "/dev/${drive}" | awk '{print $3}' | while read mp; do
        echo -e "${YELLOW}Unmounting $mp...${NC}"
        umount "$mp" &>/dev/null
    done

    swapon --show | grep "/dev/${drive}" | awk '{print $1}' | while read swap_partition; do
        echo -e "${YELLOW}Disabling swap on $swap_partition...${NC}"
        swapoff "$swap_partition"
    done
}

# Function to update the config file with drive information
update_config() {
    local drive="$1"
    local fs_type="$2"

    # Remove old entry for the drive if it exists
    sed -i "/^$drive:/d" "$config_file"

    # Add the new entry for the drive
    echo "$drive:$fs_type" >> "$config_file"
}

# Function to prompt for drive selection and format options
format_drive() {
    echo -e "${BLUE}Select a drive to format (e.g., sda, sdb):${NC}"
    read -p "> " drive

    if [ ! -b "/dev/$drive" ]; then
        echo -e "${RED}Invalid drive. Please ensure the drive exists.${NC}"
        return
    fi

    clean_old_mounts "$drive"

    echo -e "${BLUE}Select the filesystem format type:${NC}"
    echo "1) XFS"
    echo "2) ZFS"
    read -p "> " fs_choice

    if [[ "$fs_choice" == "1" ]]; then
        fs_type="xfs"
    elif [[ "$fs_choice" == "2" ]]; then
        fs_type="zfs"
    else
        echo -e "${RED}Invalid choice. Exiting.${NC}"
        return
    fi

    echo -e "${YELLOW}Wiping existing filesystem signatures on /dev/$drive...${NC}"
    wipefs -a "/dev/$drive"

    echo -e "${YELLOW}Overwriting beginning of /dev/$drive with zeros...${NC}"
    dd if=/dev/zero of="/dev/$drive" bs=1M count=1000 status=progress

    echo -e "${YELLOW}Creating new partition table and partition on /dev/$drive...${NC}"
    (echo g; echo n; echo 1; echo ""; echo ""; echo w) | fdisk "/dev/$drive"

    echo -e "${YELLOW}Formatting the partition with $fs_type...${NC}"
    if [[ "$fs_type" == "xfs" ]]; then
        mkfs.xfs "/dev/${drive}1" -f
    elif [[ "$fs_type" == "zfs" ]]; then
        apt-get install -y zfsutils-linux
        zpool_name="pg_$(tr -dc 'a-z0-9' < /dev/urandom | head -c 8)"
        zpool create -f "$zpool_name" "/dev/${drive}1"
    fi

    update_config "$drive" "$fs_type"

    echo -e "${GREEN}Drive /dev/$drive formatted with $fs_type.${NC}"
    echo -e "${GREEN}Drive information updated in $config_file.${NC}"
}

# Main menu function
main_menu() {
    while true; do
        list_drives
        format_drive
        read -p "[Press ENTER to continue or type 'exit' to quit] " user_input
        if [[ "$user_input" == "exit" ]]; then
            exit 0
        fi
    done
}

# Start the script
main_menu