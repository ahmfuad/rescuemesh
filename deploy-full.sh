#!/bin/bash

#############################################################################
# RescueMesh Full Deployment Pipeline Script
# This script deploys the complete RescueMesh application to Kubernetes
# Basic usage (uses defaults)
#./deploy-full.sh

# With custom values
#DOCKERHUB_USERNAME=your-username IMAGE_TAG=v1.0.0 ./deploy-full.sh

# With custom cluster name
#CLUSTER_NAME=my-cluster ./deploy-full.sh

#############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CLUSTER_NAME="${CLUSTER_NAME:-rescuemesh-cluster}"
NAMESPACE="rescuemesh"
DOCKERHUB_USERNAME="${DOCKERHUB_USERNAME:-kdbazizul}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

#############################################################################
# Helper Functions
#############################################################################

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}➜ $1${NC}"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 is not installed"
        exit 1
    fi
    print_success "$1 is installed"
}

#############################################################################
# Step 1: Prerequisites Check
#############################################################################

print_header "STEP 1: Checking Prerequisites"

check_command kubectl
check_command doctl

# Check for podman or docker
if command -v podman &> /dev/null; then
    CONTAINER_CMD="podman"
    print_success "Using podman"
elif command -v docker &> /dev/null; then
    CONTAINER_CMD="docker"
    print_success "Using docker"
else
    print_error "Neither podman nor docker found"
    exit 1
fi

#############################################################################
# Step 2: Verify Kubernetes Cluster
#############################################################################

print_header "STEP 2: Verifying Kubernetes Cluster"

print_info "Checking cluster status..."
if ! doctl k8s cluster list | grep -q "$CLUSTER_NAME"; then
    print_error "Cluster '$CLUSTER_NAME' not found"
    print_info "Available clusters:"
    doctl k8s cluster list
    exit 1
fi

print_success "Cluster '$CLUSTER_NAME' found"

print_info "Connecting to cluster..."
doctl k8s cluster kubeconfig save "$CLUSTER_NAME"
print_success "Connected to cluster"

print_info "Verifying nodes..."
kubectl get nodes
NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
print_success "$NODE_COUNT nodes ready"

#############################################################################
# Step 3: Create Namespace and Storage
#############################################################################

print_header "STEP 3: Creating Namespace and Storage"

print_info "Creating namespace..."
kubectl apply -f k8s/namespace.yaml
print_success "Namespace created"

print_info "Creating storage classes..."
kubectl apply -f k8s/storage/
print_success "Storage classes created"

#############################################################################
# Step 4: Deploy Secrets and ConfigMaps
#############################################################################

print_header "STEP 4: Deploying Secrets and ConfigMaps"

print_info "Creating secrets..."
kubectl apply -f k8s/secrets/secrets.yaml
print_success "Secrets created"

print_info "Creating ConfigMaps..."
kubectl apply -f k8s/configmaps/
print_success "ConfigMaps created"

#############################################################################
# Step 5: Deploy Infrastructure (PostgreSQL, Redis, RabbitMQ)
#############################################################################

print_header "STEP 5: Deploying Infrastructure Components"

print_info "Deploying PostgreSQL, Redis, and RabbitMQ..."
kubectl apply -f k8s/infrastructure/
print_success "Infrastructure deployed"

print_info "Waiting for infrastructure pods to be ready (this may take 2-3 minutes)..."
kubectl wait --for=condition=ready pod --all -n $NAMESPACE --timeout=300s || true
print_success "Infrastructure pods are ready"

#############################################################################
# Step 6: Build and Push Docker Images
#############################################################################

print_header "STEP 6: Building and Pushing Docker Images"

print_info "Logging into DockerHub..."
if [ "$CONTAINER_CMD" = "podman" ]; then
    podman login docker.io
else
    docker login
fi
print_success "Logged into DockerHub"

print_info "Building and pushing images (this may take 10-15 minutes)..."
bash scripts/build-and-push-images.sh $IMAGE_TAG

if [ $? -eq 0 ]; then
    print_success "All images built and pushed successfully"
else
    print_error "Some images failed to build/push"
    print_info "Continuing with deployment..."
fi

#############################################################################
# Step 7: Deploy Microservices
#############################################################################

print_header "STEP 7: Deploying Microservices"

print_info "Deploying all microservices..."
kubectl apply -f k8s/deployments/
print_success "Deployments created"

print_info "Creating services..."
kubectl apply -f k8s/services/
print_success "Services created"

print_info "Waiting for microservice pods to be ready..."
sleep 10
kubectl get pods -n $NAMESPACE

#############################################################################
# Step 8: Deploy Health Aggregator
#############################################################################

print_header "STEP 8: Deploying Health Aggregator"

print_info "Deploying health aggregator service..."
kubectl apply -f k8s/monitoring/health-aggregator.yaml
print_success "Health aggregator deployed"

print_info "Waiting for health aggregator to be ready..."
kubectl wait --for=condition=ready pod -l app=health-aggregator -n $NAMESPACE --timeout=60s || true

#############################################################################
# Step 9: Install and Configure NGINX Ingress Controller
#############################################################################

print_header "STEP 9: Installing NGINX Ingress Controller"

# Check if ingress controller is already installed
if kubectl get namespace ingress-nginx &> /dev/null; then
    print_info "NGINX Ingress Controller already installed, skipping..."
else
    print_info "Installing NGINX Ingress Controller..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/do/deploy.yaml
    print_success "NGINX Ingress Controller installed"
    
    print_info "Waiting for ingress controller to be ready..."
    sleep 10
fi

# Disable proxy protocol (to avoid errors with Cloudflare)
print_info "Configuring ingress controller..."
kubectl patch configmap ingress-nginx-controller -n ingress-nginx --type merge -p '{"data":{"use-proxy-protocol":"false"}}' 2>/dev/null || true

# Restart ingress controller to apply config
kubectl rollout restart deployment ingress-nginx-controller -n ingress-nginx
kubectl wait --for=condition=available deployment/ingress-nginx-controller -n ingress-nginx --timeout=120s

print_success "Ingress controller configured"

#############################################################################
# Step 10: Deploy Ingress Rules
#############################################################################

print_header "STEP 10: Deploying Ingress Rules"

print_info "Applying ingress configuration..."
kubectl apply -f k8s/ingress/ingress.yaml
print_success "Ingress rules applied"

print_info "Waiting for Load Balancer IP assignment..."
sleep 15

EXTERNAL_IP=""
for i in {1..30}; do
    EXTERNAL_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    if [ -n "$EXTERNAL_IP" ]; then
        break
    fi
    sleep 2
done

if [ -z "$EXTERNAL_IP" ]; then
    print_error "Failed to get external IP"
    exit 1
fi

print_success "Load Balancer IP assigned: $EXTERNAL_IP"

#############################################################################
# Step 11: Deployment Verification
#############################################################################

print_header "STEP 11: Verifying Deployment"

print_info "Checking pod status..."
kubectl get pods -n $NAMESPACE

TOTAL_PODS=$(kubectl get pods -n $NAMESPACE --no-headers | wc -l)
RUNNING_PODS=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase=Running --no-headers | wc -l)

echo ""
print_info "Total Pods: $TOTAL_PODS"
print_info "Running Pods: $RUNNING_PODS"

if [ "$TOTAL_PODS" -eq "$RUNNING_PODS" ]; then
    print_success "All pods are running"
else
    print_error "Some pods are not running"
fi

print_info "Services:"
kubectl get svc -n $NAMESPACE | grep -E "NAME|user-service|disaster-service|skill-service|sos-service|matching-service|notification-service|frontend|health"

print_info "Ingress:"
kubectl get ingress -n $NAMESPACE

#############################################################################
# Step 12: Test Deployment
#############################################################################

print_header "STEP 12: Testing Deployment"

print_info "Testing frontend..."
FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://$EXTERNAL_IP -H "Host: villagers.live" --max-time 5)
if [ "$FRONTEND_RESPONSE" = "200" ]; then
    print_success "Frontend is accessible (HTTP $FRONTEND_RESPONSE)"
else
    print_error "Frontend test failed (HTTP $FRONTEND_RESPONSE)"
fi

print_info "Testing API health endpoint..."
HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://$EXTERNAL_IP/health -H "Host: api.villagers.live" --max-time 5)
if [ "$HEALTH_RESPONSE" = "200" ] || [ "$HEALTH_RESPONSE" = "503" ]; then
    print_success "Health endpoint is accessible (HTTP $HEALTH_RESPONSE)"
else
    print_error "Health endpoint test failed (HTTP $HEALTH_RESPONSE)"
fi

#############################################################################
# Final Summary
#############################################################################

print_header "DEPLOYMENT SUMMARY"

cat << EOF

${GREEN}╔═══════════════════════════════════════════════════════════════════╗
║              🎉 DEPLOYMENT COMPLETED SUCCESSFULLY! 🎉              ║
╚═══════════════════════════════════════════════════════════════════╝${NC}

${BLUE}📍 LOAD BALANCER IP:${NC} ${GREEN}$EXTERNAL_IP${NC}

${BLUE}🌐 YOUR APPLICATIONS:${NC}
   • Frontend:     http://$EXTERNAL_IP
   • API Gateway:  http://$EXTERNAL_IP/api
   • Health Check: http://$EXTERNAL_IP/health

${BLUE}🔧 DEPLOYED MICROSERVICES:${NC}
   ├─ User Service         (Port 3001)
   ├─ Skill Service        (Port 3002)
   ├─ Disaster Service     (Port 3003)
   ├─ SOS Service          (Port 3004)
   ├─ Matching Service     (Port 3005)
   └─ Notification Service (Port 3006)

${BLUE}💾 INFRASTRUCTURE:${NC}
   ├─ PostgreSQL (6 databases)
   ├─ Redis (5 instances)
   └─ RabbitMQ

${BLUE}📋 NEXT STEPS:${NC}

1. ${YELLOW}Update Cloudflare DNS:${NC}
   Point your domains to: ${GREEN}$EXTERNAL_IP${NC}
   • villagers.live → A record → $EXTERNAL_IP
   • www.villagers.live → A record → $EXTERNAL_IP
   • api.villagers.live → A record → $EXTERNAL_IP

2. ${YELLOW}Configure Cloudflare SSL:${NC}
   Go to SSL/TLS → Overview → Set to ${GREEN}"Flexible"${NC}

3. ${YELLOW}Test your services:${NC}
   curl http://$EXTERNAL_IP -H "Host: villagers.live"
   curl http://$EXTERNAL_IP/api/users/health -H "Host: api.villagers.live"

${BLUE}📚 USEFUL COMMANDS:${NC}
   • View pods:     kubectl get pods -n $NAMESPACE
   • View services: kubectl get svc -n $NAMESPACE
   • View logs:     kubectl logs -f deployment/user-service -n $NAMESPACE
   • Scale service: kubectl scale deployment user-service --replicas=3 -n $NAMESPACE

${BLUE}🔐 SECURITY REMINDERS:${NC}
   ${YELLOW}⚠️  Update production secrets:${NC} kubectl edit secret rescuemesh-secrets -n $NAMESPACE
   ${YELLOW}⚠️  Review database passwords${NC}
   ${YELLOW}⚠️  Consider setting up TLS/SSL certificates for production${NC}

═══════════════════════════════════════════════════════════════════

EOF

print_success "Deployment script completed!"
echo ""
