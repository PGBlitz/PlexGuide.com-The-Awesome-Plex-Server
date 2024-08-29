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
    echo -e "Current User/Repo: [${GREEN}${user}/${repo}${NC}]"
    echo ""  # Space for separation

    local random_pin=$(printf "%04d" $((RANDOM % 10000)))
    read -p "$(echo -e "Enter [${RED}$random_pin${NC}] to proceed or [${GREEN}Z${NC}] to Exit: ")" change_choice

    if [[ "${change_choice,,}" == "z" ]]; then
        echo "Exiting..."
        exit 0
    elif [[ "$change_choice" == "$random_pin" ]]; then
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
    else
        echo -e "${RED}Invalid GitHub repository. Please try again.${NC}"
        read -p "Press Enter to continue..."
    fi
}

# Function to save the
