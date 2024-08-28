#!/bin/bash

deploy_container() {

docker run -d \
  --name "${app_name}" \
  --hostname "${app_name}" \
  --env PGID=1000 \
  --env PUID=1000 \
  --env TZ="${time_zone}" \
  --env UMASK=022 \
  --env TERM=xterm \
  --env RUN_TIME="${runtime}"\
  --restart unless-stopped \
  --volume "${appdata_path}":/config:rw \
  --volume "${kometa_path}"/assets:/assets:rw \
  ghcr.io/fscorrupt/docker-posterizarr:"${version_tag}"
  
    # display app deployment information
    appverify "$app_name"
}