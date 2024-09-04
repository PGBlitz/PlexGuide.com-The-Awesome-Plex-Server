#!/bin/bash

# Title: PGBlitz (Simplified)
# Description: Script to manage Hetzner Cloud servers using the new hcloud CLI

# Check if hcloud CLI is installed and install if missing
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

# Validate hcloud API token
validate_hcloud_token() {
  if ! hcloud server list &> /dev/null; then
    echo -e "\nWARNING! Please configure Hetzner API token first!"
    echo -e "\nFollow these steps:\n1. Activate a Hetzner Cloud Account\n2. Create a Project\n3. Go to Access (left-hand side)\n4. Click API Tokens\n5. Create a Token and Save It\n"
    echo -e "Type 'exit' to cancel and return to the main menu.\n"
    read -p 'Paste your API token here (or type exit): ' api_token </dev/tty

    # Check if the user typed exit
    if [[ "${api_token,,}" == "exit" ]]; then
      echo -e "\nToken generation canceled. Returning to the main menu...\n"
      main_menu
    fi

    # Create a new context with the provided API token
    hcloud context create plexguide --token "$api_token"

    # Verify the token again
    if ! hcloud server list &> /dev/null; then
      hcloud context delete plexguide
      echo -e "\nInvalid token provided. Please try again.\n"
      exit 1
    fi
  fi
}

# Ensure necessary directories exist
setup_directories() {
  mkdir -p /pg/hcloud
}

# Main menu
main_menu() {
  clear
  echo -e "\e[1;36mPG: Hetzner Cloud Manager\e[0m\n"
  echo -e "[1] Deploy a New Server"
  echo -e "[2] Destroy a Server"
  echo -e "[A] List Servers"
  echo -e "[B] Show Initial Passwords"
  echo -e "[Z] Exit\n"
  read -p 'Select an option: ' option </dev/tty

  case $option in
    1) deploy_server ;;
    2) destroy_server ;;
    [Aa]) list_servers ;;
    [Bb]) show_initial_passwords ;;
    [Zz]) exit ;;
    *) main_menu ;;
  esac
}

# Deploy a new server
deploy_server() {
  clear
  read -p 'Enter Server Name: ' server_name </dev/tty

  # Select OS
  echo -e "\n\e[1;36mSelect OS:\e[0m\n"
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
  echo -e "\n\e[1;36mSelect CPU Type:\e[0m\n"
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
    echo -e "\n\e[1;36mSelect Shared Server Type:\e[0m\n"
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
    echo -e "\n\e[1;36mSelect Dedicated Server Type:\e[0m\n"
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

  # Create server
  echo -e "\nDeploying server..."
  hcloud server create --name "$server_name" --type "$server_type" --image "$os" > "/pg/hcloud/$server_name.info"
  echo -e "\nServer information:"
  cat "/pg/hcloud/$server_name.info"
  read -p 'Press [ENTER] to continue...' </dev/tty
  main_menu
}

# List servers
list_servers() {
  clear
  echo -e "\e[1;36mHetzner Cloud Servers:\e[0m\n"
  hcloud server list | awk 'NR>1 {print $2}'
  echo ""
  read -p 'Press [ENTER] to continue...' </dev/tty
  main_menu
}

# Destroy a server
destroy_server() {
  clear
  echo -e "\e[1;36mAvailable Servers to Destroy:\e[0m\n"
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

# Show initial passwords
show_initial_passwords() {
  clear
  echo -e "\e[1;36mInitial Server Passwords:\e[0m\n"
  grep -i 'password' /pg/hcloud/*.info
  echo ""
  read -p 'Press [ENTER] to continue...' </dev/tty
  main_menu
}

# Execute script
install_hcloud
validate_hcloud_token
setup_directories
main_menu
