#!/bin/bash

deploy_container() {

    docker run -d \
      --name="${app_name}" \
      -e PUID=1000 \
      -e PGID=1000 \
      -e TZ="${time_zone}" \
      -p "${expose}""${port_number}":8181 \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v "${data_path}":/data \
      -v "${icons_path}":/app/public/icons \     
      -v "${configs_path}":/app/data/configs \
      --restart unless-stopped \
      lscr.io/linuxserver/tautulli:"${version_tag}"
    
    # display app deployment information
    appverify "$app_name"
}
