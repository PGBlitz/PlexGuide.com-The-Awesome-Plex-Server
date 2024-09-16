#!/bin/bash

# Define color codes for rainbow effect
dark_red="\033[0;31m"
orange="\033[0;33m"
yellow="\033[1;33m"
green="\033[0;32m"
light_blue="\033[0;36m"
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
    echo "Current backup location: $backup_location"
}

# Function to validate and create new location
validate_and_create_location() {
    new_location=$1
    if [ ! -d "$new_location" ]; then
        echo "The location '$new_location' does not exist."
        
        # Generate two random 4-digit PINs
        pin_confirm=$(( RANDOM % 9000 + 1000 ))
        pin_cancel=$(( RANDOM % 9000 + 1000 ))

        # Ensure the two PINs are different
        while [ "$pin_confirm" -eq "$pin_cancel" ]; do
            pin_cancel=$(( RANDOM % 9000 + 1000 ))
        done
        
        echo -e "Would you like to create this location?\n"
        echo -e "Type the 4-digit code to confirm creation: $pin_confirm"
        echo -e "Or cancel with this code: $pin_cancel"
        
        read -p "Enter code: " user_pin
        
        if [ "$user_pin" -eq "$pin_confirm" ]; then
            echo "Creating location at $new_location..."
            mkdir -p "$new_location"
            chown 1000:1000 "$new_location"
            chmod +x "$new_location"
            
            # Test the location by creating a temporary file
            temp_file="$new_location/.testfile"
            touch "$temp_file"
            if [ -f "$temp_file" ]; then
                echo "Location is valid and writable."
                rm "$temp_file"
                echo "$new_location" > "$config_dir/location.cfg"
                echo "Backup location updated to: $new_location"
            else
                echo "Failed to write to $new_location. Please check permissions."
            fi
        elif [ "$user_pin" -eq "$pin_cancel" ]; then
            echo "Operation canceled."
        else
            echo "Invalid PIN entered. Returning to menu."
        fi
    else
        echo "The location '$new_location' is valid."
        echo "$new_location" > "$config_dir/location.cfg"
        echo "Backup location updated to: $new_location"
    fi
}

# Backup and Restore Menu Interface
menu() {
    while true; do
        clear
        echo
        echo -e "${dark_red}PG: Backup & Restore Menu${reset}"
        echo
        echo -e "${orange}[B]${reset} Backup Data"
        echo
        echo -e "${yellow}[R]${reset} Restore Data"
        echo
        echo -e "${green}[S]${reset} Set Backup Location"
        echo
        echo -e "${blue}[Z]${reset} Exit"
        echo
        echo
        read -p "Select an Option > " choice

        case $choice in
            B|b)
                echo "Backup process initiated..."
                # Backup process logic
                ;;
            R|r)
                echo "Restore process initiated..."
                # Restore process logic
                ;;
            S|s)
                read -p "Enter new backup location: " new_location
                validate_and_create_location "$new_location"
                ;;
            Z|z)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo "Invalid option. Please try again."
                ;;
        esac
    done
}

# Initialize
create_backup_folder
read_backup_location
menu
