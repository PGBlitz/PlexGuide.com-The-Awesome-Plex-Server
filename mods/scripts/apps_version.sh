#!/bin/bash

# ANSI color codes for formatting
RED="\033[0;31m"
GREEN="\033[0;32m"
ORANGE="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No color

# Function to check and install unzip if not present
check_and_install_unzip() {
    if ! command -v unzip &> /dev/null; then
        echo -e "\n${RED}unzip is missing. Installing unzip...${NC}\n"
        sudo apt-get update
        sudo apt-get install -y unzip
        echo -e "\nProceeding...\n"
    fi
}

# Function to fetch releases from GitHub
fetch_releases() {
    curl -s https://api.github.com/repos/plexguide/Apps/releases | jq -r '.[].tag_name' | grep -E '^11\.[0-9]{4}$' | sort -r
}

# Function to display releases
display_releases() {
    releases="$1"
    echo -e "${BLUE}PG Application Store Selector${NC}"
    echo ""  # Blank line for separation
    line_length=0
    echo -n -e "${RED}Alpha${NC} "
    for release in $releases; do
        if (( line_length + ${#release} + 1 > 80 )); then
            echo ""
            line_length=0
        fi
        echo -n -e "${ORANGE}$release${NC} "
        line_length=$((line_length + ${#release} + 1))
    done
    echo "" # New line after displaying all releases
}

# Function to download and extract the selected version
download_and_extract() {
    local selected_version="$1"
    local url="https://github.com/plexguide/Apps/archive/refs/tags/${selected_version}.zip"

    echo "Downloading and extracting ${selected_version}..."
    curl -L -o /pg/tmp/release.zip "$url"

    unzip -o /pg/tmp/release.zip -d /pg/tmp/
    local extracted_folder="/pg/tmp/Apps-${selected_version}"

    if [[ -d "$extracted_folder" ]]; then
        echo "Found extracted folder: $extracted_folder"

        # Clear the /pg/apps/ directory before moving files
        echo "Clearing /pg/apps/ directory..."
        rm -rf /pg/apps/*

        # Move apps to /pg/apps
        if [[ -d "$extracted_folder/mods/apps" ]]; then
            echo "Moving apps to /pg/apps"
            mv "$extracted_folder/mods/apps/"* /pg/apps/
            chown -R 1000:1000 /pg/apps/
            chmod -R +x /pg/apps/
        else
            echo "No apps directory found in $extracted_folder"
        fi

        # Clear the /pg/tmp directory after moving the files
        rm -rf /pg/tmp/*
        echo "Cleared /pg/tmp directory after moving files."

        return 0
    else
        echo "Extracted folder $extracted_folder not found!"
        return 1
    fi
}

# Function to update the version in the config file
update_config_version() {
    local selected_version="$1"
    local config_file="/pg/config/appstore_version.cfg"

    if [[ ! -f "$config_file" ]]; then
        echo "Creating config file at $config_file"
        touch "$config_file"
    fi

    if grep -q "^appstore_version=" "$config_file"; then
        sed -i "s/^appstore_version=.*/appstore_version=\"$selected_version\"/" "$config_file"
    else
        echo "appstore_version=\"$selected_version\"" >> "$config_file"
    fi

    echo "App Store version has been set to $selected_version in $config_file"
}

# Main logic
while true; do
    clear
    releases=$(fetch_releases)
    
    if [[ -z "$releases" ]]; then
        echo "No releases found."
        exit 1
    fi

    display_releases "$releases"
    echo ""
    read -p "Which version do you want to install? " selected_version

    if [[ "$selected_version" == "Alpha" ]]; then
        selected_version="Alpha"  # Handling the special case for Alpha
    elif echo "$releases" | grep -q "^${selected_version}$"; then
        echo ""
        echo "Valid version selected: $selected_version"
    else
        echo "Invalid version. Please select a valid version from the list."
        continue
    fi

    random_pin=$(printf "%04d" $((RANDOM % 10000)))
    while true; do
        echo ""
        read -p "$(echo -e "Type [${RED}${random_pin}${NC}] to proceed or [${GREEN}Z${NC}] to cancel: ")" response
        if [[ "$response" == "$random_pin" ]]; then
            check_and_install_unzip
            if download_and_extract "$selected_version"; then
                update_config_version "$selected_version"
                echo "Version update successful!"
                exit 0
            else
                echo "Error during download or extraction."
            fi
        elif [[ "${response,,}" == "z" ]]; then
            echo "Installation canceled."
            exit 0
        else
            echo "Invalid input. Please try again."
        fi
    done
done
