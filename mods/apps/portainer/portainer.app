#!/bin/bash

deploy_container() {

docker run -d \
    --name="${app_name}" \
    -e PUID=1000 \
    -e PGID=1000 \
    -e TZ="${time_zone}" \
    -p "${expose}""${port_number}":9000 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    --restart unless-stopped \
    portainer/portainer-ce:"${version_tag}"
  
    # display app deployment information
    appverify "$app_name"
}
