#!/bin/bash

# Function to create symbolic links for command scripts
create_command_symlinks() {
    echo "Creating command symlinks..."

    # Define a static associative array with command names as keys and script paths as values
    declare -A commands=(
        ["plexguide"]="/pg/scripts/menu.sh"
        ["pg"]="/pg/scripts/menu.sh"
        ["pgalpha"]="/pg/installer/install_alpha.sh"
        ["pgbeta"]="/pg/installer/install_beta.sh"
        ["pgfork"]="/pg/installer/install_fork.sh"
    )

    # Loop over the associative array to create symbolic links for predefined commands
    for cmd in "${!commands[@]}"; do
        sudo ln -sf "${commands[$cmd]}" "/usr/local/bin/$cmd"
        sudo chown 1000:1000 "/usr/local/bin/$cmd"
        sudo chmod 755 "/usr/local/bin/$cmd"
    done

    # Now dynamically create wrapper scripts and symbolic links for each app in /pg/apps/
    for app_dir in /pg/apps/*; do
        if [[ -d "$app_dir" ]]; then
            app_name=$(basename "$app_dir")  # Get the app name from the directory name
            cmd_name="pg-$app_name"  # Define the command name with the pg- prefix
            wrapper_script="/usr/local/bin/$cmd_name"

            # Create the wrapper script that calls apps_interface.sh with the app_name
            echo "#!/bin/bash" > "$wrapper_script"
            echo "/pg/scripts/apps_interface.sh \"$app_name\"" >> "$wrapper_script"

            # Set ownership and permissions for the wrapper script
            sudo chown 1000:1000 "$wrapper_script"
            sudo chmod 755 "$wrapper_script"  # Ensure the script is executable
        fi
    done

    echo "Command symlinks created successfully."
}

# Call the function to create the symlinks
create_command_symlinks
