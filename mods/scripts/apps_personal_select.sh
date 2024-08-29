#!/bin/bash

# ANSI color codes for formatting
RED="\033[0;31m"
GREEN="\033[0;32m"
ORANGE="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No color

# Default values for personal apps configuration
DEFAULT_USER="Admin9705"
DEFAULT_REPO="apps"

# Function to load personal apps configuration
load_personal_apps_config() {
    local config_file="/pg/config/personal_apps.cfg"
    if [[ -f "$config_file" ]]; then
        source "$config_file"
    else
        user=$DEFAULT_USER
        repo=$DEFAULT_REPO
    fi
}

# Function to display the current user and repo, and prompt to change them
display_and_prompt_user_repo() {
    clear
    echo -e "${BLUE}Personal App Interface${NC}"
    echo ""  # Blank line for separation

    echo -e "Current User/Repo: [${GREEN}${user}/${repo}${NC}]"
    echo ""  # Space for separation

    read -p "Would you like to change the User/Repo? (y/n, or Z to Exit): " change_choice

    if [[ "${change_choice,,}" == "z" ]]; then
        echo "Exiting..."
        exit 0
    elif [[ "${change_choice,,}" == "n" ]]; then
        echo "No changes made. Exiting..."
        exit 0
    elif [[ "${change_choice,,}" == "y" ]]; then
        read -p "Enter new GitHub User: " new_user
        read -p "Enter new GitHub Repo: " new_repo

        validate_github_repository "$new_user" "$new_repo"
    else
        echo -e "${RED}Invalid option, please try again.${NC}"
        read -p "Press Enter to continue..."
    fi
}

# Function to validate the GitHub repository using GitHub API
validate_github_repository() {
    local user="$1"
    local repo="$2"
    local api_url="https://api.github.com/repos/${user}/${repo}"

    echo "Checking if the GitHub repository is valid: $api_url"
    local response=$(curl -s -o /dev/null -w "%{http_code}" "$api_url")

    if [[ "$response" == "200" ]]; then
        echo -e "${GREEN}The GitHub repository is valid.${NC}"
        save_changes_to_config "$user" "$repo"
        clone_repository "$user" "$repo"
    else
        echo -e "${RED}Invalid GitHub repository. Please try again.${NC}"
        read -p "Press Enter to continue..."
    fi
}

# Function to save the new user and repo to the configuration file
save_changes_to_config() {
    local user="$1"
    local repo="$2"
    local config_file="/pg/config/personal_apps.cfg"

    if [[ ! -f "$config_file" ]]; then
        touch "$config_file"
    fi

    # Update or add user and repo in the configuration file
    sed -i "/^user=/d" "$config_file"
    sed -i "/^repo=/d" "$config_file"
    echo "user=$user" >> "$config_file"
    echo "repo=$repo" >> "$config_file"

    echo -e "${GREEN}Updated configuration successfully!${NC}"
    echo "New User/Repo: ${user}/${repo}"
    read -p "Press Enter to continue..."
}

# Function to clone the GitHub repository
clone_repository() {
    local user="$1"
    local repo="$2"
    local repo_url="https://github.com/${user}/${repo}.git"
    local clone_dir="/pg/p_apps"

    echo "Cloning the repository from $repo_url to $clone_dir..."

    # Remove the directory if it already exists
    if [[ -d "$clone_dir" ]]; then
        echo "Removing existing directory: $clone_dir"
        rm -rf "$clone_dir"
    fi

    # Clone the repository
    git clone "$repo_url" "$clone_dir"

    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}Repository cloned successfully.${NC}"

        # Set permissions and ownership
        echo "Setting permissions and ownership for files in $clone_dir..."
        chown -R 1000:1000 "$clone_dir"
        chmod -R +x "$clone_dir"
        
        echo -e "${GREEN}Permissions and ownership set successfully.${NC}"
    else
        echo -e "${RED}Failed to clone the repository. Please check your GitHub details and try again.${NC}"
    fi
    read -p "Press Enter to continue..."
}

# Main logic
load_personal_apps_config
while true; do
    display_and_prompt_user_repo
done
