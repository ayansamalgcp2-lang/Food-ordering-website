#!/bin/bash

# Quick Docker Build & Run
# Usage: ./docker-quick-run.sh <image-name> <container-name> <port>

IMAGE_NAME=${1:-my-app}
CONTAINER_NAME=${2:-my-container}
PORT=${3:-8080}

echo "🐳 Building image: $IMAGE_NAME"
docker build -t "$IMAGE_NAME" .

echo "🚀 Running container: $CONTAINER_NAME on port $PORT"
docker run -d -p "$PORT:80" --name "$CONTAINER_NAME" "$IMAGE_NAME"

echo "⏳ Waiting for container..."
sleep 3

echo "🌐 Opening browser..."
powershell.exe -Command "Start-Process msedge -ArgumentList 'http://localhost:$PORT'"

echo "✅ Done! Access at: http://localhost:$PORT"
docker ps --filter "name=$CONTAINER_NAME"
