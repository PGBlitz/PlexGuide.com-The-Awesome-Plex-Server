#!/bin/bash

# Define the name of the app and Docker container
APP_NAME="plexguide-ui"

# Stop and remove any existing container with the same name
echo "Stopping and removing any existing container..."
docker stop $APP_NAME > /dev/null 2>&1
docker rm $APP_NAME > /dev/null 2>&1

# Build the Docker image
echo "Building the Docker image..."
docker build -t $APP_NAME .

# Run the Docker container with a volume mount for /pg/ymals
echo "Running the Docker container..."
docker run -d -p 5000:5000 \
  --name $APP_NAME \
  -v /pg/ymals:/pg/ymals:ro \  # Mount /pg/ymals from host to container (read-only)
  $APP_NAME  # Use the correct image name (plexguide-ui)

# Confirm the container is running
if [ "$(docker ps -q -f name=$APP_NAME)" ]; then
    echo "The Flask app is running on port 5000."
    echo "Access it at http://<your-server-ip>:5000"
else
    echo "There was an issue running the Flask app. Check the Docker logs for more information."
fi
