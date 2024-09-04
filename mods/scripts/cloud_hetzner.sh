#!/bin/bash

# Title: PG Cloud Hetzner Manager Script
# Description: Script to manage Hetzner Cloud servers using the new hcloud CLI

# Configuration file path for storing the token
TOKEN_FILE="/pg/hcloud/.token"

# ANSI color codes
CYAN="\033[0;36m"
RED="\033[0;31m"
ORANGE="\033[0;33m"
WHITE="\033[1;37m"
BOLD="\033[1m"
NC="\033[0m"  # No color

# Function to install hcloud CLI if missing
install_hcloud() {
  if ! command -v hcloud &> /dev/null; then
    echo "Installing Hetzner CLI..."
    curl -o /tmp/hcloud.tar.gz -L https://github.com/hetznercloud/cli/releases/latest/download/hcloud-linux-amd64.tar.gz
    tar -xzf /tmp/hcloud.tar.gz -C /tmp
    mv /tmp/hcloud /usr/local/bin/hcloud
    chmod +x /usr/local/bin/hcloud
    rm -rf /tmp/hcloud.tar.gz
  fi
}

# Function to validate the Hetzner API token
validate_hcloud_token() {
  if [[ -f "$TOKEN_FILE" ]]; then
    export HCLOUD_TOKEN=$(cat "$TOKEN_FILE")
    if ! hcloud server list &> /dev/null; then
      echo -e "\n${RED}WARNING! The existing token is invalid.${NC}"
      change_token
    fi
  else
    change_token
  fi
}

# Function to change or set the hcloud API token
change_token() {
  echo -e "\nPlease provide a valid Hetzner API token."
  echo -e "\nFollow these steps:"
  echo -e "1. Activate a Hetzner Cloud Account"
  echo -e "2. Create a Project"
  echo -e "3. Go to Security (left-hand side)"
  echo -e "4. Select and Click API Tokens"
  echo -e "5. Create a Token and Save It\n"
  echo -e "Type 'exit' to cancel and return to the main menu.\n"
  read -p 'Paste your API token here (or type exit): ' api_token </dev/tty

  # Check if the user typed exit
  if [[ "${api_token,,}" == "exit" ]]; then
    echo -e "\nToken generation canceled. Exiting interface...\n"
    exit 0
  fi

  # Validate the token format (64 alphanumeric characters)
  if [[ ! "$api_token" =~ ^[a-zA-Z0-9]{64}$ ]]; then
    echo -e "\n${RED}Invalid token format. Please try again.${NC}"
    change_token
  fi

  # Save the token to the TOKEN_FILE
  echo "$api_token" > "$TOKEN_FILE"
  export HCLOUD_TOKEN="$api_token"

  # Verify the token
  if ! hcloud server list &> /dev/null; then
    echo -e "\n${RED}Invalid token provided. Please try again.${NC}\n"
    rm -f "$TOKEN_FILE"
    change_token
  else
    echo -e "\n${WHITE}Token successfully configured.${NC}"
  fi
}

# Function to ensure necessary directories exist
setup_directories() {
  mkdir -p /pg/hcloud
}

# Main menu function
main_menu() {
  clear
  echo -e "${CYAN}${BOLD}PG: Hetzner Cloud Manager${NC}\n"
  echo -e "[1] Deploy a New Server"
  echo -e "[2] Destroy a Server"
  echo -e "[A] List Servers"
  echo -e "[B] Show Initial Passwords"
  echo -e "[T] Change API Token"
  echo -e "[Z] Exit\n"
  read -p 'Select an option: ' option </dev/tty

  case ${option,,} in
    1) deploy_server ;;
    2) destroy_server ;;
    a) list_servers ;;
    b) show_initial_passwords ;;
    t) change_token ;;
    z) exit 0 ;;
    *) main_menu ;;
  esac
}

# Function to deploy a new server
deploy_server() {
  clear
  read -p 'Enter Server Name: ' server_name </dev/tty

  # Select OS
  echo -e "\n${CYAN}${BOLD}Select OS:${NC}\n"
  echo -e "[1] Ubuntu 20.04"
  echo -e "[2] Ubuntu 22.04"
  echo -e "[3] Ubuntu 24.04"
  echo -e "[4] Debian 11"
  echo -e "[5] Fedora 40"
  echo -e "[6] CentOS 9"
  echo -e "[7] Rocky Linux 9"
  echo -e "[8] AlmaLinux 9"
  echo -e "[Z] Exit\n"
  read -p 'Select an option: ' os_option </dev/tty

  case $os_option in
    1) os="ubuntu-20.04" ;;
    2) os="ubuntu-22.04" ;;
    3) os="ubuntu-24.04" ;;
    4) os="debian-11" ;;
    5) os="fedora-40" ;;
    6) os="centos-9" ;;
    7) os="rockylinux-9" ;;
    8) os="almalinux-9" ;;
    [Zz]) main_menu ;;
    *) deploy_server ;;
  esac

  # Select CPU Type: Shared or Dedicated
  echo -e "\n${CYAN}${BOLD}Select CPU Type:${NC}\n"
  echo -e "[1] Shared vCPU (Lower Cost)"
  echo -e "[2] Dedicated vCPU (Higher Performance)\n"
  read -p 'Select an option: ' cpu_type_option </dev/tty

  case $cpu_type_option in
    1) cpu_type="shared" ;;
    2) cpu_type="dedicated" ;;
    *) deploy_server ;;
  esac

  # Select Server Type
  if [[ "$cpu_type" == "shared" ]]; then
    echo -e "\n${CYAN}${BOLD}Select Shared Server Type:${NC}\n"
    echo -e "[1]  CX22  -  2vCPU |  4GB RAM  | Intel"
    echo -e "[2]  CPX11 -  2vCPU |  2GB RAM  | AMD  "
    echo -e "[3]  CX32  -  4vCPU |  8GB RAM  | Intel"
    echo -e "[4]  CPX21 -  3vCPU |  4GB RAM  | AMD  "
    echo -e "[5]  CPX31 -  4vCPU |  8GB RAM  | AMD  "
    echo -e "[6]  CX42  -  8vCPU | 16GB RAM  | Intel"
    echo -e "[7]  CPX41 -  8vCPU | 16GB RAM  | AMD  "
    echo -e "[8]  CX52  - 16vCPU | 32GB RAM  | Intel"
    echo -e "[9]  CPX51 - 16vCPU | 32GB RAM  | AMD  "
    echo -e "[Z] Exit\n"
    read -p 'Select an option: ' server_type_option </dev/tty

    case $server_type_option in
      1) server_type="cx22" ;;
      2) server_type="cpx11" ;;
      3) server_type="cx32" ;;
      4) server_type="cpx21" ;;
      5) server_type="cpx31" ;;
      6) server_type="cx42" ;;
      7) server_type="cpx41" ;;
      8) server_type="cx52" ;;
      9) server_type="cpx51" ;;
      [Zz]) main_menu ;;
      *) deploy_server ;;
    esac
  else
    echo -e "\n${CYAN}${BOLD}Select Dedicated Server Type:${NC}\n"
    echo -e "[1]  CCX13 -  2vCPU |   8GB RAM  | AMD"
    echo -e "[2]  CCX23 -  4vCPU |  16GB RAM  | AMD"
    echo -e "[3]  CCX33 -  8vCPU |  32GB RAM  | AMD"
    echo -e "[4]  CCX43 - 16vCPU |  64GB RAM  | AMD"
    echo -e "[5]  CCX53 - 32vCPU | 128GB RAM  | AMD"
    echo -e "[6]  CCX63 - 48vCPU | 192GB RAM  | AMD"
    echo -e "[Z] Exit\n"
    read -p 'Select an option: ' server_type_option </dev/tty

    case $server_type_option in
      1) server_type="ccx13" ;;
      2) server_type="ccx23" ;;
      3) server_type="ccx33" ;;
      4) server_type="ccx43" ;;
      5) server_type="ccx53" ;;
      6) server_type="ccx63" ;;
      [Zz]) main_menu ;;
      *) deploy_server ;;
    esac
  fi

  # Create the server
  echo -e "\nDeploying server..."
  hcloud server create --name "$server_name" --type "$server_type" --image "$os" > "/pg/hcloud/$server_name.info"
  echo -e "\nServer information:"
  cat "/pg/hcloud/$server_name.info"
  read -p 'Press [ENTER] to continue...' </dev/tty
  main_menu
}

# Function to list servers
list_servers() {
  clear
  echo -e "${CYAN}${BOLD}Hetzner Cloud Servers:${NC}\n"
  hcloud server list | awk 'NR>1 {print $2}'
  echo ""
  read -p 'Press [ENTER] to continue...' </dev/tty
  main_menu
}

# Function to destroy a server
destroy_server() {
  clear
  echo -e "${CYAN}${BOLD}Available Servers to Destroy:${NC}\n"
  hcloud server list | awk 'NR>1 {print $2}'
  echo ""
  read -p 'Enter server name to destroy or [Z] to exit: ' server_name </dev/tty

  if [[ "$server_name" =~ ^[Zz]$ ]]; then
    main_menu
  elif hcloud server list | grep -q "$server_name"; then
    hcloud server delete "$server_name"
    echo "Server $server_name destroyed."
  else
    echo "Server $server_name does not exist."
  fi

  read -p 'Press [ENTER] to continue...' </dev/tty
  main_menu
}

# Function to show initial passwords
show_initial_passwords() {
  clear
  echo -e "${CYAN}${BOLD}Initial Server Passwords:${NC}\n"
  grep -i 'password' /pg/hcloud/*.info
  echo ""
  read -p 'Press [ENTER] to continue...' </dev/tty
  main_menu
}

# Execute script
install_hcloud
setup_directories
validate_hcloud_token
main_menu
