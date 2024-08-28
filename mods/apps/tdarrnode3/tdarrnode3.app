#!/bin/bash

deploy_container() {
        
    docker run -ti \
        --name="${app_name}" \
        -v "${appdata_path}/server":/app/server \
        -v "${appdata_path}/configs":/app/configs \
        -v "${appdata_path}/logs":/app/logs \
        -v "${media_path}":/media \
        -v "${transcode_cache_path}":/temp \
        -e "serverIP=${server_ip}" \
        -e "serverPort=${port_number}" \
        -e "webUIPort=${expose}${port_number}" \
        -e "internalNode=${internal_node}" \
        -e "inContainer=true" \
        -e "ffmpegVersion=${ffmpeg_version}" \
        -e "nodeName=${node_name}" \
        --network bridge \
        -p "${expose}""${port_number}":8268 \
        -e "TZ=${time_zone}" \
        -e PUID=1000 \
        -e PGID=1000 \
        --device=/dev/dri:/dev/dri \
        --log-opt max-size=10m \
        --log-opt max-file=5 \
        --restart unless-stopped \
        ghcr.io/haveagitgat/tdarr:"${version_tag}"

    # display app deployment information
    appverify "$app_name"
}
