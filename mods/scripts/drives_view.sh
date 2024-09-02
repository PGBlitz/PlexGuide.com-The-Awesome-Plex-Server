#!/bin/bash

# ANSI color codes for formatting
GREEN="\033[0;32m"
BLUE="\033[0;34m"
NC="\033[0m"  # No color

# Clear the screen when the script starts
clear

# Display a header
echo -e "${BLUE}========================="
echo -e "   Top-Level Drives List   "
echo -e "=========================${NC}"

# Use lsblk to list only top-level block devices with just the name and size
# Then, pipe the output through column to ensure alignment
echo -e "${GREEN}Top Level View of Drives:${NC}"
echo ""
lsblk -d -o NAME,SIZE | column -t

# Prompt the user to press [ENTER] to exit
read -p "Press [ENTER] to Exit"