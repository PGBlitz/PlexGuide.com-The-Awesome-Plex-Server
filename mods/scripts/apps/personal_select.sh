#!/bin/bash

# ANSI color codes for formatting
RED="\033[0;31m"
GREEN="\033[0;32m"
ORANGE="\033[0;33m"
BLUE="\033[0;34m"
YELLOW="\033[0;33m"
NC="\033[0m" # No color

# Default values for personal apps configuration
DEFAULT_USER="None"
DEFAULT_REPO="None"

# Function to load personal apps configuration
load_personal_apps_config() {
    local config_file="/pg/personal_configs/personal_apps.cfg"  # Updated config path
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
    echo -e "Current User/Repo: [${YELLOW}${user}/${repo}${NC}]"
    echo ""  # Space for separation

    local random_pin=$(printf "%04d" $((RANDOM % 10000)))
    read -p "$(echo -e "Enter [${RED}$random_pin${NC}] to proceed or [${GREEN}Z${NC}] to Exit: ")" change_choice

    if [[ "${change_choice,,}" == "z" ]]; then
        echo "Exiting..."
        exit 0
    elif [[ "$change_choice" == "$random_pin" ]]; then
        # Show testing hint
        echo -e "\nTesting? Use [${YELLOW}plexguide${NC}] for user and [${YELLOW}appsfork${NC}] for repo."
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

    echo ""
    echo "Checking if the GitHub repository is valid:"
    echo "$api_url"
    local response=$(curl -s -o /dev/null -w "%{http_code}" "$api_url")

    if [[ "$response" == "200" ]]; then
        echo -e "\n${GREEN}The GitHub repository is valid.${NC} ${GREEN}Updated configuration successfully!${NC}"
        save_changes_to_config "$user" "$repo"
        clone_repository "$user" "$repo"
        echo -e "${RED}NOTE: Adding new apps later? Redeploy this to See Your Updates!${NC}"
        echo -e "\n${YELLOW}[Press ENTER] to continue...${NC}"
        read -r
        exit 0
    else
        echo -e "${RED}Invalid GitHub repository. Please try again.${NC}"
        read -p "Press Enter to continue..."
    fi
}

# Function to save the new user and repo to the configuration file
save_changes_to_config() {
    local user="$1"
    local repo="$2"
    local config_file="/pg/personal_configs/personal_apps.cfg"  # Updated config path

    if [[ ! -f "$config_file" ]]; then
        touch "$config_file"
    fi

    # Update or add user and repo in the configuration file
    sed -i "/^user=/d" "$config_file"
    sed -i "/^repo=/d" "$config_file"
    echo "user=$user" >> "$config_file"
    echo "repo=$repo" >> "$config_file"

    echo -e "${ORANGE}NOTE:${NC} New User/Repo: ${user}/${repo}"
}

# Function to clone the GitHub repository
clone_repository() {
    local user="$1"
    local repo="$2"
    local repo_url="https://github.com/${user}/${repo}.git"
    local clone_dir="/pg/p_apps"

    echo ""
    echo "Cloning the repository from $repo_url to $clone_dir..."

    # Remove the directory if it already exists
    if [[ -d "$clone_dir" ]]; then
        echo "Removing existing directory: $clone_dir"
        rm -rf "$clone_dir"
    fi

    # Clone the repository
    git clone "$repo_url" "$clone_dir"

    if [[ $? -eq 0 ]]; then
        echo -e "\n${GREEN}Repository cloned successfully.${NC}\n"

        # Set permissions and ownership
        echo "Setting permissions and ownership for files in $clone_dir..."
        echo -e "${GREEN}Permissions and ownership set successfully.${NC}\n"
    else
        echo -e "${RED}Failed to clone the repository. Please check your GitHub details and try again.${NC}"
    fi
}

# Main logic
load_personal_apps_config
while true; do
    display_and_prompt_user_repo
done
