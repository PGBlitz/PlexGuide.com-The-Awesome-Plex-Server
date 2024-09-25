#!/bin/bash

# ANSI color codes for styling output
CYAN="\033[0;36m"
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m"  # No color
BOLD="\033[1m"
UNDERLINE="\033[4m"

# Function to check if the repository is cloned
check_repo_status() {
    if [ -d "/pg/zurg" ]; then
        repo_status="${GREEN}[Cloned]${NC}"
    else
        repo_status="${RED}[Not Cloned]${NC}"
    fi
}

# Function to check if token is set in config.yml
check_token_status() {
    if [ -f "/pg/zurg/config.yml" ]; then
        token_line=$(grep '^token:' /pg/zurg/config.yml)
        if [ -n "$token_line" ]; then
            token_value=$(echo $token_line | cut -d' ' -f2-)
            if [ -n "$token_value" ] && [ "$token_value" != "YOUR_TOKEN_HERE" ]; then
                token_status="${GREEN}[Set]${NC}"
            else
                token_status="${RED}[Not Set]${NC}"
            fi
        else
            token_status="${RED}[Not Set]${NC}"
        fi
    else
        token_status="${RED}[Not Set]${NC}"
    fi
}

# Function to check if docker containers are running
check_docker_status() {
    if docker ps --filter "name=zurg" --format '{{.Names}}' | grep -q 'zurg'; then
        docker_status="${GREEN}[Running]${NC}"
    else
        docker_status="${RED}[Not Running]${NC}"
    fi
}

# Automated setup: Create /mnt/zurg, set ownership and permissions
automate_setup() {
    echo -e "${YELLOW}Setting up directories, ownership, and permissions...${NC}"

    # Create /mnt/zurg directory if it doesn't exist
    if [ ! -d "/mnt/zurg" ]; then
        sudo mkdir -p /mnt/zurg
        echo -e "${GREEN}/mnt/zurg created.${NC}"
    fi

    # Set ownership to 1000:1000 and chmod +x for /pg/zurg and /mnt/zurg
    sudo chown -R 1000:1000 /pg/zurg
    sudo chown -R 1000:1000 /mnt/zurg
    sudo chmod -R +x /pg/zurg
    echo -e "${GREEN}Ownership and permissions set for /pg/zurg and /mnt/zurg.${NC}"
}

# Main function to display menu and handle user choices
main_menu() {
    while true; do
        clear
        check_repo_status
        check_token_status
        check_docker_status

        echo -e "${CYAN}${BOLD}Zurg Setup Menu${NC}"
        echo -e "${BLUE}-------------------------------${NC}"
        echo -e "1) Clone repository to /pg/zurg         ${repo_status}"
        echo -e "2) Enter token and update config.yml    ${token_status}"
        echo -e "3) Run docker compose up -d             ${docker_status}"
        echo -e "4) All steps"
        echo -e "Q) Quit"
        echo -e "${BLUE}-------------------------------${NC}"
        read -p "Enter your choice: " choice
        case $choice in
            1)
                clone_repository
                ;;
            2)
                enter_token
                ;;
            3)
                run_docker_compose
                ;;
            4)
                all_steps
                ;;
            [Qq])
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Function to clone repository to /pg/zurg
clone_repository() {
    echo -e "${YELLOW}Cloning repository to /pg/zurg...${NC}"
    sudo mkdir -p /pg
    if [ -d "/pg/zurg" ]; then
        echo -e "${GREEN}Repository already cloned.${NC}"
    else
        git clone https://github.com/debridmediamanager/zurg-testing.git /pg/zurg
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Repository cloned successfully.${NC}"
            automate_setup  # Call to automate the setup after cloning
        else
            echo -e "${RED}Failed to clone repository.${NC}"
        fi
    fi
    read -p "Press Enter to continue..."
}

# Function to enter token and update config.yml
enter_token() {
    echo -e "${YELLOW}Updating config.yml with your token...${NC}"
    if [ ! -f "/pg/zurg/config.yml" ]; then
        echo -e "${RED}config.yml not found in /pg/zurg.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    read -p "Please enter your token: " USER_TOKEN
    sed -i "s/^token:.*/token: $USER_TOKEN/" /pg/zurg/config.yml
    echo -e "${GREEN}Token updated in config.yml.${NC}"
    read -p "Press Enter to continue..."
}

# Function to run docker compose up -d
run_docker_compose() {
    echo -e "${YELLOW}Running docker compose up -d...${NC}"
    if [ -f "/pg/zurg/docker-compose.yml" ]; then
        cd /pg/zurg
        docker compose up -d
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Docker containers started successfully.${NC}"
        else
            echo -e "${RED}Failed to start docker containers.${NC}"
        fi
    else
        echo -e "${RED}docker-compose.yml not found in /pg/zurg.${NC}"
    fi
    read -p "Press Enter to continue..."
}

# Function to perform all steps
all_steps() {
    clone_repository
    enter_token
    run_docker_compose
    echo -e "${GREEN}All steps completed!${NC}"
    read -p "Press Enter to continue..."
}

# Start the script
main_menu
