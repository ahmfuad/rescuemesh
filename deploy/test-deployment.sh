#!/bin/bash

# Quick Test Script for RescueMesh Deployment
# Tests all endpoints via LoadBalancer IP

set -e

LOAD_BALANCER_IP="129.212.147.11"

echo "======================================"
echo "RescueMesh - Deployment Test"
echo "======================================"
echo ""

echo "Testing Frontend..."
FRONTEND_STATUS=$(curl -s -H "Host: villagers.live" -o /dev/null -w "%{http_code}" http://$LOAD_BALANCER_IP/)
if [ "$FRONTEND_STATUS" = "200" ]; then
    echo "✓ Frontend is accessible (HTTP $FRONTEND_STATUS)"
else
    echo "✗ Frontend returned HTTP $FRONTEND_STATUS"
fi

echo ""
echo "Testing API Health..."
API_HEALTH=$(curl -s -H "Host: api.villagers.live" http://$LOAD_BALANCER_IP/health)
if echo "$API_HEALTH" | grep -q "healthy"; then
    echo "✓ API Health Check: $API_HEALTH"
else
    echo "✗ API Health Check failed: $API_HEALTH"
fi

echo ""
echo "Testing Individual Services..."

# Test User Service
echo -n "  User Service: "
USER_RESPONSE=$(curl -s -H "Host: api.villagers.live" http://$LOAD_BALANCER_IP/users/health 2>/dev/null || echo "failed")
if echo "$USER_RESPONSE" | grep -q "healthy\|ok"; then
    echo "✓ Running"
else
    echo "⚠ Check logs"
fi

# Test Skill Service
echo -n "  Skill Service: "
SKILL_RESPONSE=$(curl -s -H "Host: api.villagers.live" http://$LOAD_BALANCER_IP/skills/health 2>/dev/null || echo "failed")
if echo "$SKILL_RESPONSE" | grep -q "healthy\|ok"; then
    echo "✓ Running"
else
    echo "⚠ Check logs"
fi

# Test Disaster Service
echo -n "  Disaster Service: "
DISASTER_RESPONSE=$(curl -s -H "Host: api.villagers.live" http://$LOAD_BALANCER_IP/disasters/health 2>/dev/null || echo "failed")
if echo "$DISASTER_RESPONSE" | grep -q "healthy\|ok"; then
    echo "✓ Running"
else
    echo "⚠ Check logs"
fi

echo ""
echo "======================================"
echo "DNS Configuration Check"
echo "======================================"
echo ""

echo "Current DNS Resolution:"
echo -n "  villagers.live → "
nslookup villagers.live 2>/dev/null | grep "Address:" | tail -1 | awk '{print $2}'

echo -n "  api.villagers.live → "
nslookup api.villagers.live 2>/dev/null | grep "Address:" | tail -1 | awk '{print $2}'

echo ""
echo "Expected IP: $LOAD_BALANCER_IP"
echo ""

echo "======================================"
echo "Kubernetes Status"
echo "======================================"
echo ""

echo "Running Pods:"
kubectl get pods -n rescuemesh --no-headers | grep "Running" | wc -l
echo ""

echo "Services:"
kubectl get svc -n rescuemesh --no-headers | wc -l
echo ""

echo "Ingress:"
kubectl get ingress -n rescuemesh

echo ""
echo "======================================"
echo "Access Information"
echo "======================================"
echo ""
echo "If DNS is configured correctly:"
echo "  Frontend: http://villagers.live"
echo "  API: http://api.villagers.live/health"
echo ""
echo "Direct access (bypassing DNS):"
echo "  curl -H 'Host: villagers.live' http://$LOAD_BALANCER_IP/"
echo "  curl -H 'Host: api.villagers.live' http://$LOAD_BALANCER_IP/health"
echo ""
