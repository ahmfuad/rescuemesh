#!/bin/bash

# Build and Push RescueMesh Images to Docker Hub
# Usage: ./build-and-push-images.sh [dockerhub-username]

set -e

# Configuration
DOCKER_USER="${1:-kdbazizul}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "======================================"
echo "RescueMesh - Build & Push Images"
echo "Docker Hub User: $DOCKER_USER"
echo "======================================"

# Services to build
declare -A SERVICES=(
    ["user-service"]="rescuemesh-user-service"
    ["skill-service"]="rescuemesh-skill-service"
    ["disaster-service"]="rescuemesh-disaster-service"
    ["sos-service"]="rescuemesh-sos-service"
    ["matching-service"]="rescuemesh-matching-service"
    ["notification-service"]="rescuemesh-notification-service"
    ["frontend"]="frontend"
)

# Build images
echo ""
echo "Building Docker images..."
for service_dir in "${!SERVICES[@]}"; do
    image_name="${SERVICES[$service_dir]}"
    echo ""
    echo "Building $image_name..."
    
    cd "$PROJECT_ROOT/$service_dir"
    docker build -t "$DOCKER_USER/rescuemesh-$image_name:latest" .
    
    if [ $? -eq 0 ]; then
        echo "✓ Built $image_name successfully"
    else
        echo "✗ Failed to build $image_name"
        exit 1
    fi
done

echo ""
echo "======================================"
echo "Logging into Docker Hub..."
echo "======================================"
docker login

echo ""
echo "======================================"
echo "Pushing images to Docker Hub..."
echo "======================================"

for service_dir in "${!SERVICES[@]}"; do
    image_name="${SERVICES[$service_dir]}"
    echo ""
    echo "Pushing $DOCKER_USER/rescuemesh-$image_name:latest..."
    
    docker push "$DOCKER_USER/rescuemesh-$image_name:latest"
    
    if [ $? -eq 0 ]; then
        echo "✓ Pushed $image_name successfully"
    else
        echo "✗ Failed to push $image_name"
        exit 1
    fi
done

echo ""
echo "======================================"
echo "✓ All images built and pushed!"
echo "======================================"
echo ""
echo "Images available:"
for service_dir in "${!SERVICES[@]}"; do
    image_name="${SERVICES[$service_dir]}"
    echo "  - $DOCKER_USER/rescuemesh-$image_name:latest"
done
echo ""
