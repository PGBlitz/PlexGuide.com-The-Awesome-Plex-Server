#!/bin/bash

# Stop Docker service
echo "Stopping Docker service..."
sudo systemctl stop docker

# Uninstall Docker packages
echo "Uninstalling Docker packages..."
sudo apt-get purge -y docker-engine docker docker.io docker-ce docker-ce-cli docker-compose-plugin

# Remove Docker data directories
echo "Removing Docker data directories..."
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

# Remove additional Docker configurations
echo "Removing additional Docker configurations..."
sudo rm -rf /etc/docker
sudo rm -rf /var/run/docker.sock

# Remove Docker group
echo "Removing Docker group..."
sudo groupdel docker

# Clean up unused packages and dependencies
echo "Cleaning up unused packages and dependencies..."
sudo apt-get autoremove -y
sudo apt-get autoclean

# Verify Docker removal
if ! command -v docker &> /dev/null; then
    echo "Docker has been successfully uninstalled."
else
    echo "Docker removal failed. Please check the above output for errors."
fi
