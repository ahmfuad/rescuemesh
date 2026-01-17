#!/bin/bash

# RescueMesh Health Check Script
# Monitors the health of all services

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

NAMESPACE="rescuemesh"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  RescueMesh Health Check${NC}"
echo -e "${GREEN}========================================${NC}"

# Check cluster connection
echo -e "\n${YELLOW}Cluster Info:${NC}"
kubectl cluster-info | head -n 1

# Check nodes
echo -e "\n${YELLOW}Node Status:${NC}"
kubectl get nodes

# Check namespace
echo -e "\n${YELLOW}Namespace Status:${NC}"
kubectl get namespace $NAMESPACE

# Check all pods
echo -e "\n${YELLOW}Pod Status:${NC}"
kubectl get pods -n $NAMESPACE -o wide

# Check deployments
echo -e "\n${YELLOW}Deployment Status:${NC}"
kubectl get deployments -n $NAMESPACE

# Check services
echo -e "\n${YELLOW}Service Status:${NC}"
kubectl get svc -n $NAMESPACE

# Check ingress
echo -e "\n${YELLOW}Ingress Status:${NC}"
kubectl get ingress -n $NAMESPACE

# Check certificates
echo -e "\n${YELLOW}Certificate Status:${NC}"
kubectl get certificate -n $NAMESPACE

# Check HPA
echo -e "\n${YELLOW}HPA Status:${NC}"
kubectl get hpa -n $NAMESPACE

# Check PVC
echo -e "\n${YELLOW}PersistentVolumeClaim Status:${NC}"
kubectl get pvc -n $NAMESPACE

# Check recent events
echo -e "\n${YELLOW}Recent Events:${NC}"
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -n 20

# Check pod health
echo -e "\n${YELLOW}Pod Health Details:${NC}"
for pod in $(kubectl get pods -n $NAMESPACE -o name); do
    STATUS=$(kubectl get $pod -n $NAMESPACE -o jsonpath='{.status.phase}')
    if [ "$STATUS" != "Running" ]; then
        echo -e "${RED}✗${NC} $pod: $STATUS"
    else
        READY=$(kubectl get $pod -n $NAMESPACE -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
        if [ "$READY" == "True" ]; then
            echo -e "${GREEN}✓${NC} $pod: Running"
        else
            echo -e "${YELLOW}⚠${NC} $pod: Running but not ready"
        fi
    fi
done

# Test service endpoints
echo -e "\n${YELLOW}Testing Service Endpoints:${NC}"
LB_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
if [ -n "$LB_IP" ]; then
    echo "Load Balancer IP: $LB_IP"
    echo "Testing /health endpoint..."
    curl -f -s -o /dev/null http://$LB_IP/health && echo -e "${GREEN}✓${NC} Health endpoint OK" || echo -e "${RED}✗${NC} Health endpoint failed"
else
    echo -e "${YELLOW}⚠${NC} Load Balancer IP not yet assigned"
fi

# Resource usage
echo -e "\n${YELLOW}Resource Usage:${NC}"
kubectl top nodes 2>/dev/null || echo "Metrics server not installed"
kubectl top pods -n $NAMESPACE 2>/dev/null || echo "Metrics server not installed"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Health Check Complete${NC}"
echo -e "${GREEN}========================================${NC}"
