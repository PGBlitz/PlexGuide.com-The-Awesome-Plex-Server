#!/bin/bash

deploy_container() {

    docker run -d \
      --name="${app_name}" \
      -e PUID=1000 \
      -e PGID=1000 \
      -e TZ="${time_zone}" \
      -p "${expose}""${port_number}":5690 \
      -v "${appdata_path}":/data/database \
      --restart unless-stopped \
      ghcr.io/wizarrrr/wizarr:"${version_tag}"
    
    # display app deployment information
    appverify "$app_name"
}