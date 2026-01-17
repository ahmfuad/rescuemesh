#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
# Set your DockerHub username here or pass as environment variable
DOCKERHUB_USERNAME="${DOCKERHUB_USERNAME:-kdbazizul}"
REGISTRY="$DOCKERHUB_USERNAME"
TAG="${1:-latest}"

echo -e "${GREEN}RescueMesh - Build and Push All Container Images${NC}"
echo "Registry: DockerHub ($REGISTRY)"
echo "Tag: $TAG"
echo ""

# Check if podman/docker is running
if command -v podman &> /dev/null; then
    CONTAINER_CMD="podman"
elif command -v docker &> /dev/null; then
    CONTAINER_CMD="docker"
else
    echo -e "${RED}Error: Neither podman nor docker found${NC}"
    exit 1
fi

echo "Using: $CONTAINER_CMD"
echo ""

# Ensure logged in to registry
echo -e "${YELLOW}Ensuring authentication to DockerHub...${NC}"
if [ "$CONTAINER_CMD" = "podman" ]; then
    if ! podman login docker.io --get-login &>/dev/null; then
        echo "Please login to DockerHub:"
        podman login docker.io
    else
        echo "Already logged in to DockerHub"
    fi
else
    if ! docker login; then
        echo -e "${RED}Failed to login to DockerHub${NC}"
        exit 1
    fi
fi

# Define services and their directories
declare -A SERVICES=(
    ["user-service"]="rescuemesh-user-service"
    ["skill-service"]="rescuemesh-skill-service"
    ["disaster-service"]="rescuemesh-disaster-service"
    ["sos-service"]="rescuemesh-sos-service"
    ["matching-service"]="rescuemesh-matching-service"
    ["notification-service"]="rescuemesh-notification-service"
    ["frontend"]="frontend"
)

# Build and push each service
FAILED_SERVICES=()
SUCCESSFUL_SERVICES=()

for SERVICE in "${!SERVICES[@]}"; do
    DIR="${SERVICES[$SERVICE]}"
    IMAGE_NAME="$REGISTRY/$DIR:$TAG"
    
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Building $SERVICE${NC}"
    echo "  Directory: $DIR"
    echo "  Image: $IMAGE_NAME"
    
    if [ ! -d "$DIR" ]; then
        echo -e "${RED}  ✗ Error: Directory $DIR not found${NC}"
        FAILED_SERVICES+=("$SERVICE (directory not found)")
        continue
    fi
    
    if [ ! -f "$DIR/Dockerfile" ]; then
        echo -e "${RED}  ✗ Error: Dockerfile not found in $DIR${NC}"
        FAILED_SERVICES+=("$SERVICE (no Dockerfile)")
        continue
    fi
    
    # Build the image
    echo "  Building..."
    if $CONTAINER_CMD build -t "$IMAGE_NAME" "$DIR"; then
        echo -e "${GREEN}  ✓ Build successful${NC}"
        
        # Push the image
        echo "  Pushing to registry..."
        if $CONTAINER_CMD push "$IMAGE_NAME"; then
            echo -e "${GREEN}  ✓ Push successful${NC}"
            SUCCESSFUL_SERVICES+=("$SERVICE")
        else
            echo -e "${RED}  ✗ Push failed${NC}"
            FAILED_SERVICES+=("$SERVICE (push failed)")
        fi
    else
        echo -e "${RED}  ✗ Build failed${NC}"
        FAILED_SERVICES+=("$SERVICE (build failed)")
    fi
    
    echo ""
done

# Summary
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Build Summary${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ ${#SUCCESSFUL_SERVICES[@]} -gt 0 ]; then
    echo -e "${GREEN}Successful (${#SUCCESSFUL_SERVICES[@]}):${NC}"
    for service in "${SUCCESSFUL_SERVICES[@]}"; do
        echo -e "${GREEN}  ✓ $service${NC}"
    done
    echo ""
fi

if [ ${#FAILED_SERVICES[@]} -gt 0 ]; then
    echo -e "${RED}Failed (${#FAILED_SERVICES[@]}):${NC}"
    for service in "${FAILED_SERVICES[@]}"; do
        echo -e "${RED}  ✗ $service${NC}"
    done
    echo ""
    exit 1
fi

echo -e "${GREEN}All images built and pushed successfully!${NC}"
echo ""
echo "Next steps:"
echo "  1. Apply updated deployments: kubectl apply -f k8s/deployments/"
echo "  2. Restart deployments: kubectl rollout restart deployment -n rescuemesh"
echo "  3. Or run: ./scripts/deploy.sh"
