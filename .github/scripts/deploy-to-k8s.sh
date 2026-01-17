#!/bin/bash

# Deploy services to Kubernetes

set -e

SERVICES_JSON="$1"
GIT_SHA=$(echo $GITHUB_SHA | cut -c1-7)
NAMESPACE="rescuemesh"

echo "Deploying services to Kubernetes..."
echo "Git SHA: $GIT_SHA"

# Parse services JSON and deploy each
echo "$SERVICES_JSON" | jq -c '.[]' | while read -r service; do
    SERVICE_NAME=$(echo $service | jq -r '.name')
    DEPLOYMENT_NAME=$(echo $service | jq -r '.deployment')
    IMAGE_NAME=$(echo $service | jq -r '.image')
    
    IMAGE="kdbazizul/$IMAGE_NAME:prod-$GIT_SHA"
    
    echo "Deploying $SERVICE_NAME..."
    echo "  Deployment: $DEPLOYMENT_NAME"
    echo "  Image: $IMAGE"
    
    # Update deployment with new image
    kubectl set image deployment/$DEPLOYMENT_NAME \
        $DEPLOYMENT_NAME=$IMAGE \
        -n $NAMESPACE \
        --record
    
    # Add annotation for tracking
    kubectl annotate deployment/$DEPLOYMENT_NAME \
        kubernetes.io/change-cause="Deployed $IMAGE by GitHub Actions (SHA: $GIT_SHA)" \
        -n $NAMESPACE \
        --overwrite
    
    echo "✓ Updated deployment for $SERVICE_NAME"
done

echo "All deployments updated successfully"
