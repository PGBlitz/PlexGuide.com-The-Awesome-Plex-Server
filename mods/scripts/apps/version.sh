#!/bin/bash

# ANSI color codes for bold formatting
RED="\033[1;31m"
GREEN="\033[1;32m"
ORANGE="\033[1;33m"  # Gold/Yellow
WHITE="\033[1;37m"
HOT_PINK="\033[1;35m"  # Bold hot pink
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

# Function to get the current version from the config file
get_current_version() {
    local config_file="/pg/config/appstore_version.cfg"
    if [[ -f "$config_file" ]]; then
        source "$config_file"
        echo "$appstore_version"
    else
        echo "Unknown"
    fi
}

# Function to display releases with Alpha in red, the first release in gold/yellow, and the rest in white
display_releases() {
    local current_version="$1"
    releases="$2"
    echo -e "Apps Version Selector - [${GREEN}${current_version}${NC}]"
    echo "NOTE: Visit https://github.com/plexguide/Apps/releases for Information"
    echo ""

    # Display Alpha option in bold red
    echo -n -e "${RED}Alpha${NC} "

    # Print the first release in gold/yellow and the rest in white
    first_release=true
    for release in $releases; do
        if $first_release; then
            echo -n -e "${ORANGE}$release${NC} "
            first_release=false
        else
            echo -n -e "${WHITE}$release${NC} "
        fi
    done
    echo "" # New line after displaying all releases
}

# Function to handle Alpha version download
handle_alpha_version() {
    local alpha_dir="/pg/tmp/alpha_apps"
    
    # Delete the directory outright if it exists
    if [[ -d "$alpha_dir" ]]; then
        echo "Deleting existing /pg/tmp/alpha_apps directory..."
        rm -rf "$alpha_dir"
    fi

    # Clone the Alpha version
    echo "Cloning Alpha version from GitHub..."
    git clone https://github.com/plexguide/Apps.git "$alpha_dir"

    # Clear the /pg/apps directory before moving files
    echo "Clearing /pg/apps/ directory..."
    rm -rf /pg/apps/*

    # Move all contents from the alpha directory to /pg/apps
    echo "Moving Alpha version files to /pg/apps"
    mv "$alpha_dir/"* /pg/apps/

    # Remove the LICENSE file from /pg/apps if it exists
    if [[ -f "/pg/apps/LICENSE" ]]; then
        rm "/pg/apps/LICENSE"
        echo "Removed LICENSE file from /pg/apps"
    fi

    # Set permissions and ownership
    echo "Setting permissions and ownership for files in /pg/apps..."
    chmod -R +x /pg/apps/
    chown -R 1000:1000 /pg/apps/

    # Remove the alpha directory to clean up
    rm -rf "$alpha_dir"
    echo "Removed temporary directory: $alpha_dir"

    # Update the version in the config file
    update_config_version "Alpha"
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

        # Move all contents from the extracted folder directly to /pg/apps
        echo "Moving apps to /pg/apps"
        mv "$extracted_folder/"* /pg/apps/
        chown -R 1000:1000 /pg/apps/
        chmod -R +x /pg/apps/

        # Remove the LICENSE file from /pg/apps if it exists
        if [[ -f "/pg/apps/LICENSE" ]]; then
            rm "/pg/apps/LICENSE"
            echo "Removed LICENSE file from /pg/apps"
        fi

        # Remove the extracted folder to clean up
        rm -rf "$extracted_folder"
        echo "Removed extracted folder: $extracted_folder"

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

# Function to generate a random 4-digit PIN with no repeating digits
generate_random_pin() {
    local pin=""
    while [[ ${#pin} -lt 4 ]]; do
        local digit=$((RANDOM % 10))
        if [[ ! "$pin" =~ $digit ]]; then
            pin+="$digit"
        fi
    done
    echo "$pin"
}

# Main logic
while true; do
    clear
    current_version=$(get_current_version)
    releases=$(fetch_releases)
    
    if [[ -z "$releases" ]]; then
        echo "No releases found."
        exit 1
    fi

    display_releases "$current_version" "$releases"
    echo ""

    # Prompt user with the updated question, using echo for colors
    echo "════════════════════════════════════════════════════════════════════════════════"
    read -p "$(echo -e "Type [${RED}${BOLD}Version${NC}] to download or [${GREEN}${BOLD}Z${NC}] to exit > ")" selected_version
    echo ""

    # Handle the user's input, including the exit option
    if [[ "${selected_version,,}" == "z" ]]; then
        echo "Installation canceled."
        exit 0
    elif [[ "${selected_version,,}" == "alpha" ]]; then
        # Same PIN process for Alpha
        echo "Alpha version selected."
        random_proceed_pin=$(generate_random_pin)
        random_cancel_pin=$(generate_random_pin)
        
        while true; do
            echo ""
            echo -e "To proceed, enter this PIN [${HOT_PINK}${random_proceed_pin}${NC}]"
            echo -e "To cancel, enter this PIN [${GREEN}${random_cancel_pin}${NC}]"
            read -p "Enter PIN > " response
            if [[ "$response" == "$random_proceed_pin" ]]; then
                handle_alpha_version  # Proceed with Alpha version setup
                echo -e "\nAlpha version setup complete. [Press ENTER] to continue..."
                read -r
                exit 0
            elif [[ "$response" == "$random_cancel_pin" ]]; then
                echo "Installation canceled."
                exit 0
            else
                echo "Invalid input. Please try again."
            fi
        done
    elif echo "$releases" | grep -q "^${selected_version}$"; then
        echo "Valid version selected: $selected_version"
    else
        echo "Invalid version. Please select a valid version from the list."
        continue
    fi

    random_proceed_pin=$(generate_random_pin)
    random_cancel_pin=$(generate_random_pin)
    
    while true; do
        echo ""
        echo -e "To proceed, enter this PIN [${HOT_PINK}${random_proceed_pin}${NC}]"
        echo -e "To cancel, enter this PIN [${GREEN}${random_cancel_pin}${NC}]"
        read -p "Enter PIN > " response
        if [[ "$response" == "$random_proceed_pin" ]]; then
            check_and_install_unzip
            if download_and_extract "$selected_version"; then
                update_config_version "$selected_version"
                echo -e "\nApp Store Version ${ORANGE}${selected_version}${NC} was installed. [Press ENTER] to continue..."
                read -r
                exit 0
            else
                echo "Error during download or extraction."
            fi
        elif [[ "$response" == "$random_cancel_pin" ]]; then
            echo "Installation canceled."
            exit 0
        else
            echo "Invalid input. Please try again."
        fi
    done
done
