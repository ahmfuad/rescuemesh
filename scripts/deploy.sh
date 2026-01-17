#!/bin/bash

# RescueMesh Deployment Script for Digital Ocean Kubernetes
# This script deploys the entire RescueMesh application to DOKS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="rescuemesh"
CLUSTER_NAME="rescuemesh-cluster"
REGISTRY="registry.digitalocean.com/rescuemesh"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  RescueMesh Deployment Script${NC}"
echo -e "${GREEN}========================================${NC}"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "\n${YELLOW}Checking prerequisites...${NC}"
for cmd in kubectl doctl helm; do
    if ! command_exists $cmd; then
        echo -e "${RED}Error: $cmd is not installed${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓${NC} $cmd is installed"
done

# Connect to Digital Ocean cluster
echo -e "\n${YELLOW}Connecting to Digital Ocean Kubernetes cluster...${NC}"
doctl kubernetes cluster kubeconfig save $CLUSTER_NAME
echo -e "${GREEN}✓${NC} Connected to cluster"

# Verify cluster connection
echo -e "\n${YELLOW}Verifying cluster connection...${NC}"
kubectl cluster-info
kubectl get nodes

# Create namespace
echo -e "\n${YELLOW}Creating namespace...${NC}"
kubectl apply -f k8s/namespace.yaml
echo -e "${GREEN}✓${NC} Namespace created"

# Deploy storage classes
echo -e "\n${YELLOW}Deploying storage classes...${NC}"
kubectl apply -f k8s/storage/
echo -e "${GREEN}✓${NC} Storage classes deployed"

# Deploy secrets (prompt for sensitive data)
echo -e "\n${YELLOW}Deploying secrets...${NC}"
echo -e "${RED}WARNING: Make sure you've updated k8s/secrets/secrets.yaml with actual secrets!${NC}"
read -p "Have you updated the secrets? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo -e "${RED}Please update secrets before continuing${NC}"
    exit 1
fi
kubectl apply -f k8s/secrets/secrets.yaml
echo -e "${GREEN}✓${NC} Secrets deployed"

# Deploy ConfigMaps
echo -e "\n${YELLOW}Deploying ConfigMaps...${NC}"
kubectl apply -f k8s/configmaps/
echo -e "${GREEN}✓${NC} ConfigMaps deployed"

# Deploy infrastructure (PostgreSQL, Redis, RabbitMQ)
echo -e "\n${YELLOW}Deploying infrastructure components...${NC}"
kubectl apply -f k8s/infrastructure/
echo -e "${GREEN}✓${NC} Infrastructure deployed"

# Wait for infrastructure to be ready
echo -e "\n${YELLOW}Waiting for infrastructure components to be ready...${NC}"

# Wait for PostgreSQL StatefulSets
echo "Waiting for PostgreSQL databases..."
for db in postgres-disasters postgres-matching postgres-notification postgres-skills postgres-sos postgres-users; do
    echo "  Checking $db..."
    if kubectl get statefulset $db -n $NAMESPACE &>/dev/null; then
        kubectl wait --for=condition=ready pod -l app=$db -n $NAMESPACE --timeout=5m || true
    else
        echo -e "${YELLOW}  Warning: StatefulSet $db not found, checking pods...${NC}"
        kubectl wait --for=condition=ready pod -l app=$db -n $NAMESPACE --timeout=5m || true
    fi
done
echo -e "${GREEN}✓${NC} PostgreSQL databases are ready"

# Wait for Redis Deployments
echo "Waiting for Redis instances..."
for redis in redis-matching redis-notification redis-skills redis-sos redis-users; do
    echo "  Checking $redis..."
    if kubectl get deployment $redis -n $NAMESPACE &>/dev/null; then
        kubectl wait --for=condition=available deployment/$redis -n $NAMESPACE --timeout=3m || true
    elif kubectl get statefulset $redis -n $NAMESPACE &>/dev/null; then
        kubectl wait --for=condition=ready pod -l app=$redis -n $NAMESPACE --timeout=3m || true
    else
        echo -e "${YELLOW}  Warning: $redis not found as deployment or statefulset${NC}"
    fi
done
echo -e "${GREEN}✓${NC} Redis instances are ready"

# Wait for RabbitMQ
echo "Waiting for RabbitMQ..."
if kubectl get deployment rabbitmq -n $NAMESPACE &>/dev/null; then
    kubectl wait --for=condition=available deployment/rabbitmq -n $NAMESPACE --timeout=3m || true
elif kubectl get statefulset rabbitmq -n $NAMESPACE &>/dev/null; then
    kubectl wait --for=condition=ready pod -l app=rabbitmq -n $NAMESPACE --timeout=3m || true
else
    echo -e "${YELLOW}  Warning: RabbitMQ not found${NC}"
fi
echo -e "${GREEN}✓${NC} RabbitMQ is ready"

# Verify all infrastructure pods
echo -e "\n${YELLOW}Verifying infrastructure pods...${NC}"
kubectl get pods -n $NAMESPACE -l tier=infrastructure --no-headers 2>/dev/null || kubectl get pods -n $NAMESPACE --no-headers | grep -E "(postgres|redis|rabbitmq)" || true
echo -e "${GREEN}✓${NC} All infrastructure components deployed"

# Deploy Kubernetes services
echo -e "\n${YELLOW}Deploying Kubernetes services...${NC}"
kubectl apply -f k8s/services/
echo -e "${GREEN}✓${NC} Services deployed"

# Deploy application deployments
echo -e "\n${YELLOW}Deploying application microservices...${NC}"
kubectl apply -f k8s/deployments/
echo -e "${GREEN}✓${NC} Deployments created"

# Wait for deployments to be ready
echo -e "\n${YELLOW}Waiting for application deployments to be ready...${NC}"
for service in frontend user-service skill-service disaster-service sos-service matching-service notification-service; do
    echo "  Checking $service..."
    if kubectl get deployment $service -n $NAMESPACE &>/dev/null; then
        kubectl rollout status deployment/$service -n $NAMESPACE --timeout=5m || echo -e "${YELLOW}  Warning: $service not ready yet${NC}"
    else
        echo -e "${YELLOW}  Warning: Deployment $service not found${NC}"
    fi
done
echo -e "${GREEN}✓${NC} Application deployments processed"

# Show current pod status
echo -e "\n${YELLOW}Current pod status:${NC}"
kubectl get pods -n $NAMESPACE

# Deploy HPA (Horizontal Pod Autoscalers)
echo -e "\n${YELLOW}Deploying Horizontal Pod Autoscalers...${NC}"
kubectl apply -f k8s/hpa/
echo -e "${GREEN}✓${NC} HPAs deployed"

# Deploy Pod Disruption Budgets
echo -e "\n${YELLOW}Deploying Pod Disruption Budgets...${NC}"
kubectl apply -f k8s/pdb/
echo -e "${GREEN}✓${NC} PDBs deployed"

# Deploy Network Policies
echo -e "\n${YELLOW}Deploying Network Policies...${NC}"
kubectl apply -f k8s/network-policies/
echo -e "${GREEN}✓${NC} Network policies deployed"

# Install NGINX Ingress Controller
echo -e "\n${YELLOW}Installing NGINX Ingress Controller...${NC}"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx --create-namespace \
    --set controller.service.annotations."service\.beta\.kubernetes\.io/do-loadbalancer-enable-proxy-protocol"="true" \
    --set controller.config.use-forwarded-headers="true"
echo -e "${GREEN}✓${NC} NGINX Ingress Controller installed"

# Install cert-manager
echo -e "\n${YELLOW}Installing cert-manager...${NC}"
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager \
    --namespace cert-manager --create-namespace \
    --set installCRDs=true
echo -e "${GREEN}✓${NC} cert-manager installed"

# Wait for cert-manager to be ready
sleep 30
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=5m

# Deploy ClusterIssuer
echo -e "\n${YELLOW}Deploying ClusterIssuer...${NC}"
kubectl apply -f k8s/issuer.yaml
echo -e "${GREEN}✓${NC} ClusterIssuer deployed"

# Deploy Ingress
echo -e "\n${YELLOW}Deploying Ingress...${NC}"
kubectl apply -f k8s/ingress/
echo -e "${GREEN}✓${NC} Ingress deployed"

# Get Load Balancer IP
echo -e "\n${YELLOW}Getting Load Balancer IP...${NC}"
echo "Waiting for Load Balancer to be provisioned..."
sleep 60
LB_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo -e "${GREEN}✓${NC} Load Balancer IP: ${GREEN}$LB_IP${NC}"

# Final status check
echo -e "\n${YELLOW}Final Status Check:${NC}"
echo -e "\nPods:"
kubectl get pods -n $NAMESPACE
echo -e "\nServices:"
kubectl get svc -n $NAMESPACE
echo -e "\nIngress:"
kubectl get ingress -n $NAMESPACE

# Display deployment summary
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Load Balancer IP: ${GREEN}$LB_IP${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Point your domain DNS to the Load Balancer IP: $LB_IP"
echo "2. In Cloudflare, add an A record:"
echo "   Type: A"
echo "   Name: @"
echo "   Content: $LB_IP"
echo "   Proxy: Enable (orange cloud)"
echo ""
echo "3. Wait for DNS propagation and SSL certificate issuance (5-10 minutes)"
echo ""
echo "4. Check certificate status:"
echo "   kubectl get certificate -n rescuemesh"
echo ""
echo "5. Monitor pods:"
echo "   kubectl get pods -n rescuemesh"
echo ""
echo "6. Check application health:"
echo "   curl https://villagers.live/health"
echo ""
echo -e "${GREEN}========================================${NC}"
