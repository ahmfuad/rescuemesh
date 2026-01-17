#!/bin/bash

# Deploy RescueMesh to Kubernetes
# Usage: ./deploy-to-k8s.sh

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
K8S_DIR="$PROJECT_ROOT/k8s"

echo "======================================"
echo "RescueMesh - Kubernetes Deployment"
echo "======================================"

# Check kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed"
    exit 1
fi

# Check cluster connectivity
echo ""
echo "Checking cluster connectivity..."
kubectl cluster-info || { echo "Error: Cannot connect to cluster"; exit 1; }

echo ""
echo "======================================"
echo "Step 1: Create Namespace"
echo "======================================"
kubectl apply -f "$K8S_DIR/namespace.yaml"

echo ""
echo "======================================"
echo "Step 2: Create Secrets"
echo "======================================"
kubectl apply -f "$K8S_DIR/secrets/secrets.yaml"

echo ""
echo "======================================"
echo "Step 3: Deploy Infrastructure"
echo "======================================"
echo "Deploying PostgreSQL databases..."
kubectl apply -f "$K8S_DIR/infrastructure/postgres-users-statefulset.yaml"
kubectl apply -f "$K8S_DIR/infrastructure/postgres-skills-statefulset.yaml"
kubectl apply -f "$K8S_DIR/infrastructure/postgres-disasters-statefulset.yaml"
kubectl apply -f "$K8S_DIR/infrastructure/postgres-sos-statefulset.yaml"
kubectl apply -f "$K8S_DIR/infrastructure/postgres-matching-statefulset.yaml"
kubectl apply -f "$K8S_DIR/infrastructure/postgres-notification-statefulset.yaml"

echo ""
echo "Deploying Redis instances..."
kubectl apply -f "$K8S_DIR/infrastructure/redis-users-deployment.yaml"
kubectl apply -f "$K8S_DIR/infrastructure/redis-skills-deployment.yaml"
kubectl apply -f "$K8S_DIR/infrastructure/redis-deployment.yaml"

echo ""
echo "Deploying RabbitMQ..."
kubectl apply -f "$K8S_DIR/infrastructure/rabbitmq-deployment.yaml"

echo ""
echo "Waiting for infrastructure to be ready (60s)..."
sleep 60

echo ""
echo "======================================"
echo "Step 4: Deploy ConfigMaps"
echo "======================================"
kubectl apply -f "$K8S_DIR/configmaps/"

echo ""
echo "======================================"
echo "Step 5: Deploy Services"
echo "======================================"
kubectl apply -f "$K8S_DIR/services/"

echo ""
echo "======================================"
echo "Step 6: Deploy Applications"
echo "======================================"
echo "Deploying microservices..."
kubectl apply -f "$K8S_DIR/deployments/deployment-user-service.yaml"
kubectl apply -f "$K8S_DIR/deployments/deployment-skill-service.yaml"
kubectl apply -f "$K8S_DIR/deployments/deployment-disaster-service.yaml"
kubectl apply -f "$K8S_DIR/deployments/deployment-sos-service.yaml"
kubectl apply -f "$K8S_DIR/deployments/deployment-matching-service.yaml"
kubectl apply -f "$K8S_DIR/deployments/deployment-notification-service.yaml"

echo ""
echo "Deploying frontend..."
kubectl apply -f "$K8S_DIR/deployments/deployment-frontend.yaml"

echo ""
echo "======================================"
echo "Step 7: Deploy Ingress"
echo "======================================"
kubectl apply -f "$K8S_DIR/ingress/ingress.yaml"

echo ""
echo "Waiting for deployments to roll out (30s)..."
sleep 30

echo ""
echo "======================================"
echo "Deployment Status"
echo "======================================"
kubectl get pods -n rescuemesh
echo ""
kubectl get svc -n rescuemesh
echo ""
kubectl get ingress -n rescuemesh

echo ""
echo "======================================"
echo "✓ Deployment Complete!"
echo "======================================"
echo ""
echo "Check deployment status:"
echo "  kubectl get pods -n rescuemesh"
echo "  kubectl get svc -n rescuemesh"
echo "  kubectl get ingress -n rescuemesh"
echo ""
echo "View logs:"
echo "  kubectl logs -n rescuemesh -l app=user-service"
echo "  kubectl logs -n rescuemesh -l app=frontend"
echo ""
