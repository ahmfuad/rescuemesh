#!/bin/bash

# RescueMesh Monitoring Setup Script
# Installs Prometheus, Grafana, and Loki for observability

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Installing Monitoring Stack${NC}"
echo -e "${GREEN}========================================${NC}"

# Add Helm repositories
echo -e "\n${YELLOW}Adding Helm repositories...${NC}"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
echo -e "${GREEN}✓${NC} Repositories added"

# Create monitoring namespace
echo -e "\n${YELLOW}Creating monitoring namespace...${NC}"
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓${NC} Namespace created"

# Install Prometheus Stack
echo -e "\n${YELLOW}Installing Prometheus + Grafana...${NC}"
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --values k8s/monitoring/prometheus-values.yaml \
    --wait
echo -e "${GREEN}✓${NC} Prometheus + Grafana installed"

# Install Loki Stack
echo -e "\n${YELLOW}Installing Loki for log aggregation...${NC}"
helm upgrade --install loki grafana/loki-stack \
    --namespace monitoring \
    --values k8s/monitoring/loki-values.yaml \
    --wait
echo -e "${GREEN}✓${NC} Loki installed"

# Get Grafana password
echo -e "\n${YELLOW}Grafana Credentials:${NC}"
GRAFANA_PASSWORD=$(kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
echo -e "Username: ${GREEN}admin${NC}"
echo -e "Password: ${GREEN}$GRAFANA_PASSWORD${NC}"

# Get Grafana URL
echo -e "\n${YELLOW}Access Grafana:${NC}"
echo "1. Port forward:"
echo "   kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "2. Open browser: http://localhost:3000"
echo ""
echo "Or wait for ingress to be configured at: https://grafana.villagers.live"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Monitoring Stack Installed!${NC}"
echo -e "${GREEN}========================================${NC}"
