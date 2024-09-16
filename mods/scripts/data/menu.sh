validate_and_create_location() {
    while true; do
        new_location=$1

        # Check if the path starts with a single slash (absolute path) and is not just slashes
        if [[ "$new_location" != /* || "$new_location" == */* ]]; then
            echo -e "${dark_red}Error: Please enter a valid absolute path (starting with '/').${reset}"
            read -p "Enter new backup location: " new_location
            continue
        fi

        # Generate two random 4-digit PINs
        pin_confirm=$(( RANDOM % 9000 + 1000 ))
        pin_cancel=$(( RANDOM % 9000 + 1000 ))

        # Ensure the two PINs are different
        while [ "$pin_confirm" -eq "$pin_cancel" ]; do
            pin_cancel=$(( RANDOM % 9000 + 1000 ))
        done
        
        echo -e "You are about to change the backup location to '$new_location'.\n"
        echo -e "Type the 4-digit code to confirm the change: ${hot_pink}$pin_confirm${reset}"
        echo -e "Or cancel with this code: ${bright_green}$pin_cancel${reset}"
        
        read -p "Enter code: " user_pin
        
        if [ "$user_pin" -eq "$pin_confirm" ]; then
            if [ ! -d "$new_location" ]; then
                echo "The directory '$new_location' does not exist."
                echo "Would you like to create it?"

                # Confirm creation of the new directory
                read -p "Enter 'yes' to create or 'no' to cancel: " create_choice
                if [[ "$create_choice" == "yes" ]]; then
                    echo "Creating location at $new_location..."
                    mkdir -p "$new_location"
                    chown 1000:1000 "$new_location"
                    chmod +x "$new_location"
                else
                    echo "Operation canceled."
                    return
                fi
            fi
            
            # Test the location by creating a temporary file
            temp_file="$new_location/.testfile"
            touch "$temp_file"
            if [ -f "$temp_file" ]; then
                echo "Location is valid and writable."
                rm "$temp_file"
                echo "$new_location" > "$config_dir/location.cfg"
                echo "Backup location updated to: $new_location"
                break
            else
                echo "Failed to write to $new_location. Please check permissions."
                return
            fi
        elif [ "$user_pin" -eq "$pin_cancel" ]; then
            echo "Operation canceled."
            return
        else
            echo -e "${dark_red}Invalid PIN entered. Returning to menu.${reset}"
            return
        fi
    done
}
