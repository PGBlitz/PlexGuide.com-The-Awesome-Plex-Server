#!/bin/bash

# ANSI color codes for styling output
CYAN="\033[0;36m"
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m" # No color

# Configuration file path for reading the DNS provider details
CONFIG_FILE="/pg/config/dns_provider.cfg"

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

    # Create a Docker Compose file dynamically based on the provider
    echo -e "${CYAN}Creating Docker Compose file for Traefik...${NC}"

    # Create the Docker Compose directory if it doesn't exist
    mkdir -p /pg/traefik
    DOCKER_COMPOSE_FILE="/pg/traefik/docker-compose.yml"

    # Write the base configuration
    cat <<EOF > $DOCKER_COMPOSE_FILE
version: '3.9'

services:
  traefik:
    image: traefik:latest
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
EOF

    # Add provider-specific configurations
    if [[ "$provider" == "cloudflare" ]]; then
        cat <<EOF >> $DOCKER_COMPOSE_FILE
      - "--certificatesresolvers.mytlschallenge.acme.dnschallenge.provider=cloudflare"
      - "--certificatesresolvers.mytlschallenge.acme.email=$cf_email"
      - "--certificatesresolvers.mytlschallenge.acme.storage=/letsencrypt/acme.json"
    environment:
      - CLOUDFLARE_API_TOKEN=$cf_api_key
EOF
    elif [[ "$provider" == "godaddy" ]]; then
        cat <<EOF >> $DOCKER_COMPOSE_FILE
      - "--certificatesresolvers.mytlschallenge.acme.dnschallenge.provider=godaddy"
      - "--certificatesresolvers.mytlschallenge.acme.email=example@example.com"  # Replace with your email if needed
      - "--certificatesresolvers.mytlschallenge.acme.storage=/letsencrypt/acme.json"
    environment:
      - GODADDY_API_KEY=$gd_api_key
      - GODADDY_API_SECRET=$gd_api_secret
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