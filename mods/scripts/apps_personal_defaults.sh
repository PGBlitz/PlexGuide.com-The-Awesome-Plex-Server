#!/bin/bash

# Function: parse_and_store_defaults
parse_and_store_defaults() {
    local app_name="$1"
    local app_defaults_path="/pg/p_apps/${app_name}/${app_name}.defaults"
    local config_path="/pg/personal_configs/${app_name}.cfg"

    # Debugging: Show the paths being used
    echo "Using app name: $app_name"
    echo "App defaults path: $app_defaults_path"
    echo "Config path: $config_path"
    read -p "Press Enter to continue..."

    # Check if the config file exists, create it if not
    [[ ! -f "$config_path" ]] && touch "$config_path"

    # Read through the app defaults file for lines starting with "#####"
    while IFS= read -r line; do
        if [[ "$line" =~ ^##### ]]; then
            # Remove leading "##### " and extract the key and value
            local trimmed_line=$(echo "$line" | sed 's/^##### //')
            local key=$(echo "$trimmed_line" | cut -d':' -f1 | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
            local value=$(echo "$trimmed_line" | cut -d':' -f2 | xargs)

            # Check if the key already exists in the config file, add it if not
            if ! grep -q "^$key=" "$config_path"; then
                echo "$key=$value" >> "$config_path"
            fi
        fi
    done < "$app_defaults_path"

    # Debugging: Confirm parsing and storing is complete
    echo "Completed parsing defaults and storing in config for $app_name"
    read -p "Press Enter to continue..."
}
