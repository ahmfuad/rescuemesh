#!/bin/bash

# Detect which services have changed based on git diff or submodule changes

set -e

# Service mapping
declare -A SERVICE_MAP=(
    ["rescuemesh-user-service"]="user-service:rescuemesh-user-service:user-service"
    ["rescuemesh-skill-service"]="skill-service:rescuemesh-skill-service:skill-service"
    ["rescuemesh-disaster-service"]="disaster-service:rescuemesh-disaster-service:disaster-service"
    ["rescuemesh-sos-service"]="sos-service:rescuemesh-sos-service:sos-service"
    ["rescuemesh-matching-service"]="matching-service:rescuemesh-matching-service:matching-service"
    ["rescuemesh-notification-service"]="notification-service:rescuemesh-notification-service:notification-service"
    ["frontend"]="frontend:frontend:frontend"
)

CHANGED_SERVICES=()
CHANGED_SERVICES_LIST=""

# Check if this is a PR or push
if [ "$GITHUB_EVENT_NAME" = "pull_request" ]; then
    BASE_SHA="${{ github.event.pull_request.base.sha }}"
    HEAD_SHA="${{ github.event.pull_request.head.sha }}"
elif [ "$GITHUB_EVENT_NAME" = "push" ]; then
    # Get the previous commit
    BASE_SHA=$(git rev-parse HEAD^)
    HEAD_SHA=$(git rev-parse HEAD)
else
    # Manual trigger - deploy all
    echo "Manual trigger detected, checking all services"
    BASE_SHA=$(git rev-parse HEAD^)
    HEAD_SHA=$(git rev-parse HEAD)
fi

echo "Comparing $BASE_SHA...$HEAD_SHA"

# Check for changed files
CHANGED_FILES=$(git diff --name-only $BASE_SHA $HEAD_SHA 2>/dev/null || echo "")

# Check each service directory for changes
for SERVICE_PATH in "${!SERVICE_MAP[@]}"; do
    IFS=':' read -r SERVICE_NAME SERVICE_DIR DEPLOYMENT_NAME <<< "${SERVICE_MAP[$SERVICE_PATH]}"
    
    # Check if files in this service directory changed
    if echo "$CHANGED_FILES" | grep -q "^$SERVICE_PATH/"; then
        echo "✓ Detected changes in $SERVICE_NAME"
        CHANGED_SERVICES+=("{\"name\":\"$SERVICE_NAME\",\"dir\":\"$SERVICE_DIR\",\"image\":\"rescuemesh-$SERVICE_NAME\",\"deployment\":\"$DEPLOYMENT_NAME\"}")
        CHANGED_SERVICES_LIST="$CHANGED_SERVICES_LIST $SERVICE_NAME"
    fi
done

# Check for submodule changes
SUBMODULE_DIFF=$(git diff $BASE_SHA $HEAD_SHA 2>/dev/null || echo "")

if [ -n "$SUBMODULE_DIFF" ]; then
    echo "Checking for submodule changes..."
    
    for SERVICE_PATH in "${!SERVICE_MAP[@]}"; do
        # Check if this service path appears in the diff
        if echo "$SUBMODULE_DIFF" | grep -q "^diff --git a/$SERVICE_PATH b/$SERVICE_PATH"; then
            IFS=':' read -r SERVICE_NAME SERVICE_DIR DEPLOYMENT_NAME <<< "${SERVICE_MAP[$SERVICE_PATH]}"
            
            # Check if not already added
            if [[ ! " ${CHANGED_SERVICES_LIST} " =~ " ${SERVICE_NAME} " ]]; then
                echo "✓ Detected submodule change in $SERVICE_NAME"
                CHANGED_SERVICES+=("{\"name\":\"$SERVICE_NAME\",\"dir\":\"$SERVICE_DIR\",\"image\":\"rescuemesh-$SERVICE_NAME\",\"deployment\":\"$DEPLOYMENT_NAME\"}")
                CHANGED_SERVICES_LIST="$CHANGED_SERVICES_LIST $SERVICE_NAME"
            fi
        fi
    done
fi

# Check if k8s configs changed (deploy all services)
if echo "$CHANGED_FILES" | grep -q "^k8s/"; then
    echo "Kubernetes config changes detected, marking all services for deployment"
    CHANGED_SERVICES=()
    CHANGED_SERVICES_LIST=""
    
    for SERVICE_PATH in "${!SERVICE_MAP[@]}"; do
        IFS=':' read -r SERVICE_NAME SERVICE_DIR DEPLOYMENT_NAME <<< "${SERVICE_MAP[$SERVICE_PATH]}"
        CHANGED_SERVICES+=("{\"name\":\"$SERVICE_NAME\",\"dir\":\"$SERVICE_DIR\",\"image\":\"rescuemesh-$SERVICE_NAME\",\"deployment\":\"$DEPLOYMENT_NAME\"}")
        CHANGED_SERVICES_LIST="$CHANGED_SERVICES_LIST $SERVICE_NAME"
    done
fi

# Output results
if [ ${#CHANGED_SERVICES[@]} -eq 0 ]; then
    echo "No service changes detected"
    echo "has_changes=false" >> $GITHUB_OUTPUT
    echo "services=[]" >> $GITHUB_OUTPUT
    echo "services_list=none" >> $GITHUB_OUTPUT
else
    echo "Changed services: $CHANGED_SERVICES_LIST"
    echo "has_changes=true" >> $GITHUB_OUTPUT
    
    # Format as JSON array
    SERVICES_JSON="[$(IFS=,; echo "${CHANGED_SERVICES[*]}")]"
    echo "services=$SERVICES_JSON" >> $GITHUB_OUTPUT
    echo "services_list=$CHANGED_SERVICES_LIST" >> $GITHUB_OUTPUT
fi
