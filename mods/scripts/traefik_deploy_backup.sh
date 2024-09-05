#!/bin/bash

# ANSI color codes for styling output
CYAN="\033[0;36m"
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m" # No color

# Configuration file path for reading the DNS provider details
CONFIG_FILE="/pg/config/dns_provider.cfg"

# Function to stop and remove any running Traefik container
remove_existing_traefik() {
    existing_container=$(docker ps -aq --filter "name=traefik")

    if [[ -n "$existing_container" ]]; then
        echo -e "${CYAN}Stopping and removing existing Traefik container...${NC}"
        docker stop traefik >/dev/null 2>&1
        docker rm traefik >/dev/null 2>&1
        echo -e "${GREEN}Existing Traefik container removed.${NC}"
    else
        echo -e "${GREEN}No existing Traefik container found.${NC}"
    fi
}

# Function to deploy Traefik with the chosen DNS provider
deploy_traefik() {
    # Load the DNS provider configuration
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    else
        echo -e "${RED}Error: DNS provider configuration not found. Please set up a provider first.${NC}"
        read -p "Press Enter to continue..."
        exit 1
    fi

    # Stop and remove any existing Traefik container
    remove_existing_traefik

    # Create a Docker Compose file dynamically based on the provider
    echo -e "${CYAN}Creating Docker Compose file for Traefik...${NC}"

    # Create the Docker Compose directory if it doesn't exist
    mkdir -p /pg/traefik
    DOCKER_COMPOSE_FILE="/pg/traefik/docker-compose.yml"

    # Write the base configuration
    cat <<EOF > $DOCKER_COMPOSE_FILE
version: '3'

services:
  traefik:
    image: traefik:latest
    container_name: traefik
    hostname: traefik
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--entrypoints.web.http.redirections.entrypoint.to=websecure"
      - "--entrypoints.web.http.redirections.entrypoint.scheme=https"
      - "--certificatesresolvers.mytlschallenge.acme.dnschallenge=true"
      - "--certificatesresolvers.mytlschallenge.acme.email=${letsencrypt_email:-example@example.com}"
      - "--certificatesresolvers.mytlschallenge.acme.storage=/letsencrypt/acme.json"
      - "--certificatesresolvers.mytlschallenge.acme.dnschallenge.resolvers=1.1.1.1:53,8.8.8.8:53"
      - "--certificatesresolvers.mytlschallenge.acme.dnschallenge.delaybeforecheck=60"
EOF

    # Add provider-specific configurations
    if [[ "$provider" == "cloudflare" ]]; then
        cat <<EOF >> $DOCKER_COMPOSE_FILE
      - "--certificatesresolvers.mytlschallenge.acme.dnschallenge.provider=cloudflare"
    environment:
      - CLOUDFLARE_DNS_API_TOKEN=$api_key
EOF
    elif [[ "$provider" == "godaddy" ]]; then
        cat <<EOF >> $DOCKER_COMPOSE_FILE
      - "--certificatesresolvers.mytlschallenge.acme.dnschallenge.provider=godaddy"
    environment:
      - GODADDY_API_KEY=$api_key
      - GODADDY_API_SECRET=$api_secret
EOF
    else
        echo -e "${RED}Invalid provider configuration.${NC}"
        exit 1
    fi

    # Finalize Docker Compose file
    cat <<EOF >> $DOCKER_COMPOSE_FILE
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /pg/traefik/letsencrypt:/letsencrypt
    networks:
      - plexguide
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik.rule=Host(\`traefik.${domain_name}\`)"
      - "traefik.http.routers.traefik.entrypoints=websecure"
      - "traefik.http.routers.traefik.tls.certresolver=mytlschallenge"
      - "traefik.http.routers.traefik.service=api@internal"
      - "traefik.http.middlewares.traefik-auth.basicauth.users=${TRAEFIK_AUTH}"
    restart: unless-stopped


networks:
  plexguide:
    external: true
EOF

    echo -e "${GREEN}Docker Compose file for Traefik has been created at $DOCKER_COMPOSE_FILE.${NC}"
    echo -e "${GREEN}Starting Traefik using Docker Compose...${NC}"
    docker-compose -f "$DOCKER_COMPOSE_FILE" up -d
    echo -e "${GREEN}Traefik has been deployed successfully.${NC}"
}

# Deploy Traefik with the chosen DNS provider
deploy_traefik