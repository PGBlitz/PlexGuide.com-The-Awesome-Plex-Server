#!/bin/bash

# Define color codes
dark_red="\033[0;31m"
yellow="\033[1;33m"
green="\033[0;32m"
blue="\033[0;34m"
purple="\033[0;35m"
reset="\033[0m"

# Function to check and create default backup folder
create_backup_folder() {
    if [ ! -d /pgbackups/ ]; then
        mkdir -p /pgbackups/
        chown 1000:1000 /pgbackups/
        chmod +x /pgbackups/
        echo "Backup folder created at /pgbackups/"
    fi
}

# Backup and Restore Menu Interface
menu() {
    while true; do
        # Get the current backup location
        backup_location=$(./location.sh read)

        clear
        echo -e "${dark_red}PG: Backup & Restore Menu${reset}"
        echo -e "Backup Location: ${yellow}$backup_location${reset}"
        echo
        echo -e "[${yellow}B${reset}] Backup Data"
        echo -e "[${green}R${reset}] Restore Data"
        echo -e "[${blue}S${reset}] Set Backup Location"
        echo -e "[${purple}Z${reset}] Exit"
        echo
        read -p "Select an Option > " choice

        case $choice in
            B|b)
                echo "Backup process initiated..."
                # Backup process logic (to be implemented)
                read -p "Press Enter to continue..."
                ;;
            R|r)
                echo "Restore process initiated..."
                # Restore process logic (to be implemented)
                read -p "Press Enter to continue..."
                ;;
            S|s)
                bash /pg/scripts/mods/data/location.sh set
                result=$?
                if [ $result -eq 0 ]; then
                    echo "Backup location updated successfully."
                elif [ $result -eq 2 ]; then
                    echo "Operation canceled. Returning to main menu."
                else
                    echo "Failed to set new backup location."
                fi
                read -p "Press Enter to continue..."
                ;;
            Z|z)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo "Invalid option. Please try again."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Initialize
create_backup_folder
menu