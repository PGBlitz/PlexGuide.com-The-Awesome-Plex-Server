#!/bin/bash

# ANSI color codes for styling output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No color
BOLD='\033[1m'
UNDERLINE='\033[4m'

# Function to check if the repository is cloned
check_repo_status() {
    if [ -d "/pg/zurg" ]; then
        repo_status="${GREEN}[Cloned]${NC}"
        return 0  # Repository is cloned
    else
        repo_status="${RED}[Not Cloned]${NC}"
        return 1  # Repository is not cloned
    fi
}

# Function to check if token is set in /pg/config/debrid.cfg
check_token_status() {
    if [ -f "/pg/config/debrid.cfg" ]; then
        token_line=$(grep '^token:' /pg/config/debrid.cfg)
        if [ -n "$token_line" ]; then
            token_value=$(echo $token_line | cut -d' ' -f2-)
            if [ -n "$token_value" ] && [ ${#token_value} -ge 10 ]; then
                token_status="${GREEN}[Set]${NC}"
                return 0  # Token is set
            fi
        fi
    fi
    token_status="${RED}[Not Set]${NC}"
    return 1  # Token is not set
}

# Function to check if docker containers are running
check_docker_status() {
    if docker ps --filter "name=zurg" --format '{{.Names}}' | grep -q 'zurg'; then
        docker_status="${GREEN}[Running]${NC}"
    else
        docker_status="${RED}[Not Running]${NC}"
    fi
}

# Main function to display menu and handle user choices
main_menu() {
    while true; do
        clear
        check_repo_status
        check_token_status
        check_docker_status

        echo -e "${CYAN}${BOLD}PG Zurg Interface${NC}"
        echo -e "${BLUE}-------------------------------${NC}"
        echo -e "[C] Clone repository to /pg/zurg         ${repo_status}"
        if check_repo_status; then
            echo -e "[T] Real Debrid API Token                ${token_status}"
        fi
        if check_token_status; then
            echo -e "[R] Run docker compose up -d             ${docker_status}"
        fi
        echo -e "[D] Destroy & Remove All Data"
        echo -e "[Z] Exit"
        echo -e "${BLUE}-------------------------------${NC}"
        read -p "Select an Option > " choice
        case $choice in
            [Cc])
                clone_repository
                ;;
            [Tt])
                if check_repo_status; then
                    enter_token
                else
                    echo -e "${RED}Please clone the repository first.${NC}"
                    read -p "Press [ENTER] to continue..."
                fi
                ;;
            [Rr])
                if check_token_status; then
                    run_docker_compose
                else
                    echo -e "${RED}Please set a valid token first.${NC}"
                    read -p "Press [ENTER] to continue..."
                fi
                ;;
            [Dd])
                destroy_and_remove
                ;;
            [Zz])
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                read -p "Press [ENTER] to continue..."
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
    read -p "Press [ENTER] to continue..."
}

# Function to enter token and update config files
enter_token() {
    echo -e "${YELLOW}Updating config files with your Real Debrid API Token...${NC}"
    
    # Ensure both config files exist
    sudo mkdir -p /pg/config
    touch /pg/config/debrid.cfg
    
    if [ ! -f "/pg/zurg/config.yml" ]; then
        echo -e "${RED}config.yml not found in /pg/zurg. Please clone the repository first.${NC}"
        read -p "Press [ENTER] to continue..."
        return
    fi

    read -p "Please enter your Real Debrid API Token (at least 10 characters): " USER_TOKEN

    if [ ${#USER_TOKEN} -ge 10 ]; then
        # Update both files
        sed -i "s/^token:.*/token: $USER_TOKEN/" /pg/zurg/config.yml
        echo "token: $USER_TOKEN" | sudo tee /pg/config/debrid.cfg > /dev/null
        echo -e "${GREEN}Token updated in config.yml and debrid.cfg.${NC}"
    else
        echo -e "${RED}Token must be at least 10 characters long. Please try again.${NC}"
    fi
    read -p "Press [ENTER] to continue..."
}

# Function to run docker compose up -d
run_docker_compose() {
    echo -e "${YELLOW}Running docker compose up -d...${NC}"
    if [ -f "/pg/zurg/docker-compose.yml" ]; then
        cd /pg/zurg
        docker-compose up -d
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Docker containers started successfully.${NC}"
            echo ""
            echo -e "${YELLOW}Access Debrid Drive via /mnt/zurg${NC}"
        else
            echo -e "${RED}Failed to start docker containers.${NC}"
        fi
    else
        echo -e "${RED}docker-compose.yml not found in /pg/zurg.${NC}"
    fi
    echo -e "Press [ENTER] to continue..."
    read
}

# Function to destroy and remove all data
destroy_and_remove() {
    echo -e "${RED}${BOLD}WARNING: This will destroy and remove all Zurg data.${NC}"
    read -p "Are you sure you want to continue? (y/N) " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Stopping and removing Docker containers...${NC}"
        docker stop zurg rclone
        docker rm zurg rclone
        echo -e "${YELLOW}Removing all data from /pg/zurg/...${NC}"
        sudo rm -rf /pg/zurg/
        echo -e "${YELLOW}Removing token from /pg/config/debrid.cfg...${NC}"
        sudo rm -f /pg/config/debrid.cfg
        echo -e "${GREEN}All Zurg data has been destroyed and removed.${NC}"
    else
        echo -e "${YELLOW}Operation cancelled.${NC}"
    fi
    read -p "Press [ENTER] to continue..."
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

# Start the script
main_menu