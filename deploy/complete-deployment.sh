#!/bin/bash

# Complete Deployment Script for RescueMesh
# This script deploys everything from scratch

set -e

echo "======================================"
echo "RescueMesh - Complete Deployment"
echo "======================================"
echo ""

# Configuration
DOCKER_USER="${DOCKER_USER:-kdbazizul}"
NAMESPACE="rescuemesh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
K8S_DIR="$PROJECT_ROOT/k8s"

# Step 1: Check prerequisites
echo "Step 1: Checking prerequisites..."
command -v kubectl >/dev/null 2>&1 || { echo "Error: kubectl not installed"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "Error: docker not installed"; exit 1; }
echo "✓ Prerequisites OK"
echo ""

# Step 2: Check cluster connection
echo "Step 2: Checking Kubernetes cluster connection..."
kubectl cluster-info >/dev/null 2>&1 || { echo "Error: Cannot connect to cluster"; exit 1; }
echo "✓ Connected to cluster"
echo ""

# Step 3: Build and push images (optional - skip if already done)
if [ "$SKIP_BUILD" != "true" ]; then
    echo "Step 3: Building and pushing Docker images..."
    echo "Note: Set SKIP_BUILD=true to skip this step"
    echo ""
    
    read -p "Build and push images? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        "$SCRIPT_DIR/build-and-push-images.sh" "$DOCKER_USER"
    fi
    echo ""
else
    echo "Step 3: Skipping image build (SKIP_BUILD=true)"
    echo ""
fi

# Step 4: Create namespace
echo "Step 4: Creating namespace..."
kubectl apply -f "$K8S_DIR/namespace.yaml"
echo ""

# Step 5: Create secrets
echo "Step 5: Creating secrets..."
kubectl apply -f "$K8S_DIR/secrets/secrets.yaml"
echo ""

# Step 6: Deploy infrastructure
echo "Step 6: Deploying infrastructure (PostgreSQL, Redis, RabbitMQ)..."
kubectl apply -f "$K8S_DIR/infrastructure/"
echo "Waiting for databases to be ready (60s)..."
sleep 60
echo ""

# Step 7: Deploy configmaps
echo "Step 7: Deploying ConfigMaps..."
kubectl apply -f "$K8S_DIR/configmaps/"
echo ""

# Step 8: Deploy services
echo "Step 8: Creating Kubernetes services..."
kubectl apply -f "$K8S_DIR/services/"
echo ""

# Step 9: Deploy applications
echo "Step 9: Deploying microservices..."
kubectl apply -f "$K8S_DIR/deployments/"
echo "Waiting for deployments to stabilize (30s)..."
sleep 30
echo ""

# Step 10: Deploy ingress
echo "Step 10: Deploying Ingress..."
kubectl apply -f "$K8S_DIR/ingress/"
echo ""

# Step 11: Check deployment status
echo "Step 11: Checking deployment status..."
echo ""
kubectl get pods -n "$NAMESPACE"
echo ""
kubectl get svc -n "$NAMESPACE"
echo ""
kubectl get ingress -n "$NAMESPACE"
echo ""

# Step 12: Get LoadBalancer IP
echo "======================================"
echo "Deployment Complete!"
echo "======================================"
echo ""

LB_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Not found")

echo "LoadBalancer IP: $LB_IP"
echo ""
echo "Configure your DNS:"
echo "  villagers.live → $LB_IP"
echo "  www.villagers.live → $LB_IP"
echo "  api.villagers.live → $LB_IP"
echo ""
echo "Access your application:"
echo "  Frontend: http://villagers.live"
echo "  API: http://api.villagers.live/health"
echo ""
echo "Test deployment:"
echo "  ./deploy/test-deployment.sh"
echo ""
