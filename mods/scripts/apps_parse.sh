parse_and_store_defaults() {
    local app_name="$1"
    local app_type="$2"  # 'personal' for personal apps, 'official' for official apps

    # Determine paths based on app type
    if [[ "$app_type" == "personal" ]]; then
        local config_path="/pg/personal_configs/${app_name}.cfg"
        local app_path="/pg/p_apps/${app_name}.app"
    else
        local config_path="/pg/config/${app_name}.cfg"
        local app_path="/pg/apps/${app_name}.app"
    fi

    # Check if the config file exists, create it if not
    [[ ! -f "$config_path" ]] && touch "$config_path"

    # Check if the app file exists
    if [[ ! -f "$app_path" ]]; then
        echo "Error: App file $app_path does not exist."
        return 1
    fi

    # Load the domain_name from /pg/config/dns_provider.cfg
    local dns_config_path="/pg/config/dns_provider.cfg"
    if [[ -f "$dns_config_path" ]]; then
        source "$dns_config_path"
        traefik_domain="${domain_name:-nodomain}"
    else
        traefik_domain="nodomain"
    fi

    # Update or add traefik_domain to the config file
    if grep -q "^traefik_domain=" "$config_path"; then
        # Update existing variable
        sed -i "s|^traefik_domain=.*|traefik_domain=\"$traefik_domain\"|" "$config_path"
    else
        # Add variable if it doesn't exist
        echo "traefik_domain=\"$traefik_domain\"" >> "$config_path"
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
}