parse_and_store_defaults() {
    local app_name="$1"
    local app_type="$2"  # 'personal' for personal apps, 'official' for official apps
    local port_default="$3"  # The default port to expose

    # Determine paths based on app type
    if [[ "$app_type" == "personal" ]]; then
        local config_path="/pg/personal_configs/${app_name}.cfg"
        local app_path="/pg/p_apps/${app_name}.app"
    else
        local config_path="/pg/config/${app_name}.cfg"
        local app_path="/pg/apps/${app_name}.app"
    fi

    # Check if the config file exists, create it if not
    if [[ ! -f "$config_path" ]]; then
        touch "$config_path"
        add_expose_variable "$config_path" "$port_default"  # Add expose variable
    fi

    # Check if the app file exists
    if [[ ! -f "$app_path" ]]; then
        echo "Error: App file $app_path does not exist."
        return 1
    fi

    # Source the app's default_variables function
    source "$app_path"

    # Call the default_variables function for the specific app
    default_variables

    # Parse the default_variables function and write to config if not exist
    declare -f default_variables | while read line; do
        if [[ $line =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)=(.*)$ ]]; then
            var="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
            
            # Remove any existing quotes and semicolons from the value
            value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//" -e 's/;$//')
            
            # Check if the variable exists in the config file
            if ! grep -q "^${var}=" "$config_path"; then
                # Add quotes around the value (without semicolon) and write to config
                echo "${var}=\"${value}\"" >> "$config_path"
            fi
        fi
    done

    # Add or update traefik_domain
    update_traefik_domain "$config_path"
}

# Function to add the 'expose' variable based on default ports status
add_expose_variable() {
    local config_path="$1"
    local port_default="$2"

    # Check the status of the ports from /pg/config/default_ports.cfg
    local default_ports_cfg="/pg/config/default_ports.cfg"
    if [[ -f "$default_ports_cfg" ]]; then
        source "$default_ports_cfg"

        # If ports=closed, use 127.0.0.1 for $port_default
        if [[ "$ports" == "closed" ]]; then
            echo "expose=\"127.0.0.1:$port_default\"" >> "$config_path"
        else
            # If ports=open, just write expose=
            echo "expose=" >> "$config_path"
        fi
    else
        # Default to open if the config file doesn't exist
        echo "expose=" >> "$config_path"
    fi
}