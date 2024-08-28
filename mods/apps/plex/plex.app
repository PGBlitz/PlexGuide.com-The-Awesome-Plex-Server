#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m" # No color

# Function to deploy the Docker container for the app
deploy_container() {

if lspci | grep -i 'nvidia' &> /dev/null; then
    nvidia_options="-e NVIDIA_DRIVER_CAPABILITIES=\"${nvidia_driver}\" -e NVIDIA_VISIBLE_DEVICES=\"${nvidia_visible}\" --gpus=\"${nvidia_graphics}\""; else
    nvidia_options=""; fi

    # If no token exists, prompts user to create one for the claim
    check_plex_token_default

    # Run the Plex Docker container with the specified settings
    docker run -d \
      --name="${app_name}" \
      --net=host \
      -e PUID=1000 \
      -e PGID=1000 \
      -e TZ="${time_zone}" \
      -e VERSION=docker \
      -e PLEX_CLAIM="${plex_token}" \
      -v "${appdata_path}":/config \
      -v "${media_path}":/media \
      -v realdebrid:/torrents \
      --restart unless-stopped \
      --device=/dev/dri:/dev/dri \
      --restart unless-stopped \
      $nvidia_options \
      lscr.io/linuxserver/plex:"${version_tag}"

    # display app deployment information
    appverify "$app_name"
}
