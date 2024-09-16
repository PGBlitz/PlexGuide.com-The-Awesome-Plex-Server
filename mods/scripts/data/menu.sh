#!/bin/bash

# Define color codes
dark_red="\033[0;31m"
yellow="\033[1;33m"
green="\033[0;32m"
blue="\033[0;34m"
purple="\033[0;35m"
hot_pink="\033[1;35m"
bright_green="\033[1;32m"
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

# Function to read or create the config for backup location
read_backup_location() {
    config_dir="/pg/config/backup"
    location_file="$config_dir/location.cfg"
    
    # Check if config directory exists, if not create it
    if [ ! -d "$config_dir" ]; then
        mkdir -p "$config_dir"
        echo "Configuration directory created at $config_dir"
    fi

    # If location file doesn't exist, create it with default path
    if [ ! -f "$location_file" ]; then
        echo "/pgbackups/" > "$location_file"
        echo "Backup location config created with default path at /pgbackups/"
    fi

    # Read the current backup location
    backup_location=$(cat "$location_file")
}

# Function to validate and create new location
validate_and_create_location() {
    new_location="$1"

    # Basic check for absolute path
    if [[ "$new_location" != /* ]]; then
        echo "" && echo -e "${dark_red}Error: Please enter a valid absolute path (starting with '/').${reset}"
        return 1
    fi

    # Remove trailing slash if present
    new_location=${new_location%/}

    # Generate two different random 4-digit PINs
    pin_confirm=$(( RANDOM % 9000 + 1000 ))
    pin_cancel=$(( RANDOM % 9000 + 1000 ))
    while [ "$pin_confirm" -eq "$pin_cancel" ]; do
        pin_cancel=$(( RANDOM % 9000 + 1000 ))
    done

    if [ ! -d "$new_location" ]; then
        echo "" && echo "The directory '$new_location' does not exist."
        echo -e "Enter ${hot_pink}$pin_confirm${reset} to create the directory and set as new backup location."
    else
        echo "" && echo "The directory '$new_location' exists."
        echo -e "Enter ${hot_pink}$pin_confirm${reset} to set as new backup location."
    fi
    echo "" && echo -e "Enter ${bright_green}$pin_cancel${reset} to cancel."
    read -p "Enter PIN: " user_pin

    if [ "$user_pin" -eq "$pin_confirm" ]; then
        if [ ! -d "$new_location" ]; then
            echo "Creating location at $new_location..."
            if ! mkdir -p "$new_location"; then
                echo "Failed to create directory. Please check permissions."
                return 1
            fi
        fi
        
        # Test writability
        if touch "$new_location/.test_write" 2>/dev/null; then
            rm "$new_location/.test_write"
            echo "$new_location" > "$config_dir/location.cfg"
            echo "Backup location updated to: $new_location"
            return 0
        else
            echo "Failed to write to $new_location. Please check permissions."
            return 1
        fi
    elif [ "$user_pin" -eq "$pin_cancel" ]; then
        echo "Operation canceled."
        return 2  # Special return code for cancellation
    else
        echo "Invalid PIN. Operation canceled."
        return 2  # Special return code for cancellation
    fi
}

# Backup and Restore Menu Interface
menu() {
    while true; do
        # Refresh the backup location variable after every action
        read_backup_location

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
                read -p "Enter new backup location: " new_location
                validate_and_create_location "$new_location"
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
read_backup_location
menu