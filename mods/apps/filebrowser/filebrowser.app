#!/bin/bash

deploy_container() {
    
    # Create required files if they don't exist
    #touch "${appdata_path}"/.filebrowser.json
    #touch "${appdata_path}"/filebrowser.db
    
    #-v "${appdata_path}"/.filebrowser.json:/.filebrowser.json \


    # Deploy the container
    docker run -d \
      --name="${app_name}" \
      -e PUID=1000 \
      -e PGID=1000 \
      -e TZ="${time_zone}" \
      -p "${expose}${port_number}":80 \
      -v "${file_browser}"/filebrowser.db \
      -v "${file_browser}"/config/settings.json \
      -v "${root_path}":/srv \
      --restart unless-stopped \
      filebrowser/filebrowser:"${version_tag}"
    
    # Display app deployment information
    appverify "$app_name"
}