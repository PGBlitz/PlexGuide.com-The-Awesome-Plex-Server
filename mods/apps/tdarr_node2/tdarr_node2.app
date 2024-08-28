#!/bin/bash

deploy_container() {

if lspci | grep -i 'nvidia' &> /dev/null; then
    nvidia_options="-e NVIDIA_DRIVER_CAPABILITIES=\"${nvidia_driver}\" -e NVIDIA_VISIBLE_DEVICES=\"${nvidia_visible}\" --gpus=\"${nvidia_graphics}\""; else
    nvidia_options=""; fi

docker run -d \
    --name="${app_name}" \
    -v "${appdata_path}/server":/app/server \
    -v "${appdata_path}/configs":/app/configs \
    -v "${appdata_path}/logs":/app/logs \
    -v "${media_path}":/media \
    -v "${transcode_cache_path}":/temp \
    -e "inContainer=true" \
    -e "ffmpegVersion=${ffmpeg_version}" \
    -p "${expose}${port_number}":8268 \
    -e "TZ=${time_zone}" \
    -e PUID=1000 \
    -e PGID=1000 \
    --network bridge \
    --device=/dev/dri:/dev/dri \
    --log-opt max-size=10m \
    --log-opt max-file=5 \
    --restart unless-stopped \
    $nvidia_options \
    ghcr.io/haveagitgat/tdarr:"${version_tag}"

    # display app deployment information
    appverify "$app_name"
}
