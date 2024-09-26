#!/bin/bash

# Source the functions from the separate script
source /pg/scripts/traefik/functions.sh

# Ensure the config file exists, create if missing
ensure_config_file

# Function to display the main menu
setup_dns_provider() {
    while true; do
        clear
        check_traefik_status
        check_email_status
        check_domain_status
        
        echo -e "${CYAN}${BOLD}PG: CloudFlare Traefik Interface ${traefik_status}${NC}"
        echo ""
        echo -e "[${GREEN}${BOLD}A${NC}] Domain Name (${domain_status})"
        echo -e "[${CYAN}${BOLD}C${NC}] CF Information"
        echo -e "[${MAGENTA}${BOLD}E${NC}] Notification E-Mail Address (${email_status})"
        
        # Show the Deploy Traefik option only if email is set
        if [[ "$email_status" == "${GREEN}${BOLD}Set${NC}" ]]; then
            echo -e "[${BLUE}${BOLD}D${NC}] Deploy Traefik"
        fi
        
        echo -e "[${RED}${BOLD}Z${NC}] Exit"
        echo ""
        
        read -p "Select an Option > " choice
        case $choice in
            [Aa])
                set_domain
                ;;
            [Cc])
                if docker ps --filter "name=traefik" --format '{{.Names}}' | grep -q 'traefik'; then
                    warn_traefik_removal
                    if [[ $? -eq 1 ]]; then
                        continue  # Skip changing credentials if the user canceled
                    fi
                fi
                configure_provider
                ;;
            [Ee])
                set_email
                ;;
            [Dd])
                if [[ "$email_status" == "${GREEN}${BOLD}Set${NC}" ]]; then
                    bash /pg/scripts/traefik/deploy.sh
                    echo ""
                    read -p "Press Enter to continue..."
                fi
                ;;
            [Zz])
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Run the menu
setup_dns_provider
