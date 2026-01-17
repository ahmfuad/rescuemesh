#!/bin/bash

# Infrastructure Health Check Script
# Quick diagnostic for database and infrastructure components

set -e

NAMESPACE="rescuemesh"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Infrastructure Health Check${NC}"
echo -e "${GREEN}========================================${NC}"

# Check PostgreSQL
echo -e "\n${YELLOW}PostgreSQL Databases:${NC}"
for db in postgres-disasters postgres-matching postgres-notification postgres-skills postgres-sos postgres-users; do
    POD=$(kubectl get pods -n $NAMESPACE -l app=$db -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    if [ -n "$POD" ]; then
        STATUS=$(kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.status.phase}')
        READY=$(kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.status.containerStatuses[0].ready}')
        if [ "$STATUS" == "Running" ] && [ "$READY" == "true" ]; then
            echo -e "  ${GREEN}✓${NC} $db: $POD (Ready)"
        else
            echo -e "  ${YELLOW}⚠${NC} $db: $POD (Status: $STATUS, Ready: $READY)"
        fi
    else
        echo -e "  ${RED}✗${NC} $db: Not found"
    fi
done

# Check Redis
echo -e "\n${YELLOW}Redis Instances:${NC}"
for redis in redis-matching redis-notification redis-skills redis-sos redis-users; do
    POD=$(kubectl get pods -n $NAMESPACE -l app=$redis -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    if [ -n "$POD" ]; then
        STATUS=$(kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.status.phase}')
        READY=$(kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.status.containerStatuses[0].ready}')
        if [ "$STATUS" == "Running" ] && [ "$READY" == "true" ]; then
            echo -e "  ${GREEN}✓${NC} $redis: $POD (Ready)"
        else
            echo -e "  ${YELLOW}⚠${NC} $redis: $POD (Status: $STATUS, Ready: $READY)"
        fi
    else
        echo -e "  ${RED}✗${NC} $redis: Not found"
    fi
done

# Check RabbitMQ
echo -e "\n${YELLOW}RabbitMQ:${NC}"
POD=$(kubectl get pods -n $NAMESPACE -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$POD" ]; then
    STATUS=$(kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.status.phase}')
    READY=$(kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.status.containerStatuses[0].ready}')
    RESTARTS=$(kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.status.containerStatuses[0].restartCount}')
    if [ "$STATUS" == "Running" ] && [ "$READY" == "true" ]; then
        echo -e "  ${GREEN}✓${NC} rabbitmq: $POD (Ready, Restarts: $RESTARTS)"
    else
        echo -e "  ${YELLOW}⚠${NC} rabbitmq: $POD (Status: $STATUS, Ready: $READY, Restarts: $RESTARTS)"
        echo -e "\n  ${YELLOW}RabbitMQ Logs (last 20 lines):${NC}"
        kubectl logs -n $NAMESPACE $POD --tail=20 2>&1 | sed 's/^/    /'
    fi
else
    echo -e "  ${RED}✗${NC} RabbitMQ: Not found"
fi

# Check Persistent Volumes
echo -e "\n${YELLOW}Persistent Volume Claims:${NC}"
kubectl get pvc -n $NAMESPACE 2>/dev/null | tail -n +2 | while read line; do
    NAME=$(echo $line | awk '{print $1}')
    STATUS=$(echo $line | awk '{print $2}')
    if [ "$STATUS" == "Bound" ]; then
        echo -e "  ${GREEN}✓${NC} $NAME: $STATUS"
    else
        echo -e "  ${RED}✗${NC} $NAME: $STATUS"
    fi
done

# Summary
echo -e "\n${YELLOW}Pod Summary:${NC}"
TOTAL=$(kubectl get pods -n $NAMESPACE --no-headers 2>/dev/null | wc -l)
RUNNING=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
READY=$(kubectl get pods -n $NAMESPACE -o jsonpath='{range .items[*]}{.status.containerStatuses[0].ready}{"\n"}{end}' 2>/dev/null | grep -c "true" || echo "0")

echo -e "  Total Pods: $TOTAL"
echo -e "  Running: $RUNNING"
echo -e "  Ready: $READY"

if [ "$RUNNING" -eq "$TOTAL" ] && [ "$READY" -eq "$TOTAL" ]; then
    echo -e "\n${GREEN}✓ All infrastructure components are healthy!${NC}"
else
    echo -e "\n${YELLOW}⚠ Some components may need attention${NC}"
    echo -e "\nPods not ready:"
    kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running 2>/dev/null || echo "  (checking...)"
    kubectl get pods -n $NAMESPACE -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.containerStatuses[0].ready}{"\n"}{end}' 2>/dev/null | grep "false" | awk '{print "  - "$1}' || true
fi

echo -e "\n${GREEN}========================================${NC}"
