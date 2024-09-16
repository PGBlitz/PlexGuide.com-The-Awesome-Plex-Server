#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m" # No color

# Clear the screen at the start
clear

# Check if lsblk is installed
if ! command -v lsblk &> /dev/null; then
    echo "lsblk is not installed. Installing now..."
    sudo apt-get update
    sudo apt-get install -y util-linux
    echo "lsblk has been installed."
fi

# Detect the disk the OS is running on
OS_DISK=$(lsblk -no NAME,MOUNTPOINT | grep -w / | awk '{print $1}' | sed 's/[0-9]*$//')

# Detect all hard drives and highlight the OS disk
echo "PG: HardDrive Detector"
echo ""

# Loop through each disk and highlight the one with the OS
while IFS= read -r line; do
    if [[ "$line" == "$OS_DISK"* ]]; then
        echo -e "${RED}${line}${NC}"  # Highlight the OS disk in red
    else
        echo "$line"
    fi
done < <(lsblk -d -o NAME,SIZE,TYPE,MODEL | grep -w 'disk')

# Notify the user
echo ""
echo -e "${RED}The operating system is installed on disk: $OS_DISK${NC}"
echo -e "Press [${GREEN}Enter${NC}] to exit."
read
