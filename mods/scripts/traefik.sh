#!/bin/bash

# ANSI color codes for highlighting
GREEN="\033[0;32m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No color

# Configuration variables
TRAEFIK_VERSION="v3.0"
TRAEFIK_DIR="/pg/traefik"
TRAEFIK_CONFIG="$TRAEFIK_DIR/traefik.yml"
TRAEFIK_DYNAMIC_CONFIG="$TRAEFIK_DIR/dynamic.yml"
TRAEFIK_LOG="$TRAEFIK_DIR/traefik.log"
DOCKER_COMPOSE_FILE="$TRAEFIK_DIR/docker-compose.yml"

# Create Traefik directory
echo -e "${BLUE}Creating Traefik configuration directory...${NC}"
mkdir -p $TRAEFIK_DIR

# Create traefik.yml configuration file
echo -e "${BLUE}Creating Traefik configuration file...${NC}"
cat << EOF > $TRAEFIK_CONFIG
entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"

api:
  dashboard: true
  insecure: true

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false

log:
  level: INFO
  filePath: "$TRAEFIK_LOG"
EOF

# Create dynamic.yml file for additional configuration
echo -e "${BLUE}Creating dynamic configuration file...${NC}"
cat << EOF > $TRAEFIK_DYNAMIC_CONFIG
http:
  middlewares:
    secureHeaders:
      headers:
        sslRedirect: true
        frameDeny: true
        contentTypeNosniff: true
        browserXssFilter: true
        stsIncludeSubdomains: true
        stsPreload: true
EOF

# Create a Docker Compose file for Traefik using version 3.9
echo -e "${BLUE}Creating Docker Compose file for Traefik...${NC}"
cat << EOF > $DOCKER_COMPOSE_FILE
services:
  traefik:
    image: traefik:$TRAEFIK_VERSION
    container_name: traefik
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - $TRAEFIK_CONFIG:/etc/traefik/traefik.yml:ro
      - $TRAEFIK_DYNAMIC_CONFIG:/etc/traefik/dynamic.yml:ro
      - $TRAEFIK_DIR/acme.json:/acme.json
      - $TRAEFIK_LOG:/traefik.log
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.api.rule=Host(\`traefik.localhost\`)"
      - "traefik.http.routers.api.service=api@internal"
EOF

# Set permissions and create an empty acme.json file for SSL certificates
echo -e "${BLUE}Setting up permissions and creating acme.json file...${NC}"
touch $TRAEFIK_DIR/acme.json
chmod 600 $TRAEFIK_DIR/acme.json

# Start Traefik using Docker Compose
echo -e "${GREEN}Starting Traefik...${NC}"
docker-compose -f $DOCKER_COMPOSE_FILE up -d

# Show Traefik logs
echo -e "${GREEN}Traefik has been installed and started successfully. Logs are available at $TRAEFIK_LOG.${NC}"
echo -e "${BLUE}Access the Traefik dashboard at http://traefik.localhost:8080${NC}"