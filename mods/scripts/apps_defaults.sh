parse_and_store_defaults() {
    local app_name="$1"
    local app_type="$2"  # 'personal' for personal apps, 'official' for official apps

    # Determine paths based on config type
    if [[ "$app_type" == "personal" ]]; then
        local app_file_path="/pg/p_apps/${app_name}.app"
        local config_path="/pg/personal_configs/${app_name}.cfg"
    else
        local app_file_path="/pg/apps/${app_name}.app"
        local config_path="/pg/config/${app_name}.cfg"
    fi

    # Check if the config file exists, create it if not
    [[ ! -f "$config_path" ]] && touch "$config_path"

    # Check if the app file exists
    if [[ ! -f "$app_file_path" ]]; then
        echo "Error: App file $app_file_path does not exist."
        return 1
    fi

    # Read through the app file for lines starting with "##### "
    while IFS= read -r line; do
        if [[ "$line" =~ ^#####[[:space:]]+(.*?):[[:space:]]*(.*) ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"

            # Convert key to lowercase and replace spaces with underscores
            key=$(echo "$key" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')

            # Trim leading and trailing whitespace from value
            value=$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

            # If value is "null", set it to an empty string
            if [[ "$value" == "null" ]]; then
                value=""
            fi

            # Check if the key already exists in the config file, update if it does, add if it doesn't
            if grep -q "^$key=" "$config_path"; then
                sed -i "s|^$key=.*|$key=$value|" "$config_path"
            else
                echo "$key=$value" >> "$config_path"
            fi
        fi
    done < "$app_file_path"

    echo "Configuration updated in $config_path"
}