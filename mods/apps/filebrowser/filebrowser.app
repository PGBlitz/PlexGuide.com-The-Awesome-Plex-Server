#!/bin/bash

deploy_container() {

    docker run -d \
      --name="${app_name}" \
      -e PUID=1000 \
      -e PGID=1000 \
      -e TZ="${time_zone}" \
      -p "${expose}""${port_number}":80 \
      -v "${appdata_path}"/filebrowser.db:/database.db \
      -v "${appdata_path}"/.filebrowser.json:/.filebrowser.json \
      -v "${root_path}":/srv \
      --restart unless-stopped \
      filebrowser/filebrowser":${version_tag}"
    
    # display app deployment information
    appverify "$app_name"
}