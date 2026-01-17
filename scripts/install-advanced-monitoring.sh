#!/bin/bash

# Install ELK Stack, Jaeger, and SonarQube
# Complete observability and code quality setup

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Installing Advanced Monitoring Stack${NC}"
echo -e "${GREEN}========================================${NC}"

# Add Helm repositories
echo -e "\n${YELLOW}Adding Helm repositories...${NC}"
helm repo add elastic https://helm.elastic.co
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
helm repo update
echo -e "${GREEN}✓${NC} Repositories added"

# Create monitoring namespace if not exists
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Create Elasticsearch credentials secret
echo -e "\n${YELLOW}Creating Elasticsearch credentials...${NC}"
ELASTIC_PASSWORD=$(openssl rand -base64 32)
kubectl create secret generic elasticsearch-credentials \
  --from-literal=password=$ELASTIC_PASSWORD \
  --namespace monitoring \
  --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓${NC} Elasticsearch credentials created"
echo -e "${YELLOW}Elasticsearch password: ${ELASTIC_PASSWORD}${NC}"

# Install Elasticsearch
echo -e "\n${YELLOW}Installing Elasticsearch...${NC}"
helm upgrade --install elasticsearch elastic/elasticsearch \
  --namespace monitoring \
  --values k8s/monitoring/elk-values.yaml \
  --set elasticsearch.enabled=true \
  --wait \
  --timeout 10m
echo -e "${GREEN}✓${NC} Elasticsearch installed"

# Wait for Elasticsearch to be ready
echo -e "\n${YELLOW}Waiting for Elasticsearch to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=elasticsearch-master -n monitoring --timeout=10m
echo -e "${GREEN}✓${NC} Elasticsearch is ready"

# Install Logstash
echo -e "\n${YELLOW}Installing Logstash...${NC}"
helm upgrade --install logstash elastic/logstash \
  --namespace monitoring \
  --values k8s/monitoring/elk-values.yaml \
  --set logstash.enabled=true \
  --wait
echo -e "${GREEN}✓${NC} Logstash installed"

# Install Kibana
echo -e "\n${YELLOW}Installing Kibana...${NC}"
helm upgrade --install kibana elastic/kibana \
  --namespace monitoring \
  --values k8s/monitoring/elk-values.yaml \
  --set kibana.enabled=true \
  --wait
echo -e "${GREEN}✓${NC} Kibana installed"

# Install Filebeat
echo -e "\n${YELLOW}Installing Filebeat...${NC}"
helm upgrade --install filebeat elastic/filebeat \
  --namespace monitoring \
  --values k8s/monitoring/elk-values.yaml \
  --set filebeat.enabled=true \
  --wait
echo -e "${GREEN}✓${NC} Filebeat installed"

# Install Metricbeat
echo -e "\n${YELLOW}Installing Metricbeat...${NC}"
helm upgrade --install metricbeat elastic/metricbeat \
  --namespace monitoring \
  --values k8s/monitoring/elk-values.yaml \
  --set metricbeat.enabled=true \
  --wait
echo -e "${GREEN}✓${NC} Metricbeat installed"

# Install Jaeger
echo -e "\n${YELLOW}Installing Jaeger...${NC}"

# Create Jaeger auth secret
JAEGER_USER=admin
JAEGER_PASSWORD=$(openssl rand -base64 16)
kubectl create secret generic jaeger-auth \
  --from-literal=auth=$(htpasswd -nb $JAEGER_USER $JAEGER_PASSWORD) \
  --namespace monitoring \
  --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install jaeger jaegertracing/jaeger \
  --namespace monitoring \
  --values k8s/monitoring/jaeger-values.yaml \
  --wait \
  --timeout 10m
echo -e "${GREEN}✓${NC} Jaeger installed"
echo -e "${YELLOW}Jaeger credentials: ${JAEGER_USER} / ${JAEGER_PASSWORD}${NC}"

# Install SonarQube
echo -e "\n${YELLOW}Installing SonarQube...${NC}"

# Create SonarQube PostgreSQL secret
SONAR_DB_PASSWORD=$(openssl rand -base64 24)
kubectl create secret generic sonarqube-postgres \
  --from-literal=password=$SONAR_DB_PASSWORD \
  --namespace monitoring \
  --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install sonarqube sonarqube/sonarqube \
  --namespace monitoring \
  --values k8s/monitoring/sonarqube-values.yaml \
  --set postgresql.auth.password=$SONAR_DB_PASSWORD \
  --wait \
  --timeout 15m
echo -e "${GREEN}✓${NC} SonarQube installed"

# Save credentials
mkdir -p .credentials
cat > .credentials/monitoring-credentials.txt << EOF
========================================
Monitoring Stack Credentials
========================================

Elasticsearch:
  URL: http://elasticsearch-master:9200
  Username: elastic
  Password: ${ELASTIC_PASSWORD}

Kibana:
  URL: https://kibana.villagers.live
  Username: elastic
  Password: ${ELASTIC_PASSWORD}

Jaeger:
  URL: https://jaeger.villagers.live
  Username: ${JAEGER_USER}
  Password: ${JAEGER_PASSWORD}

SonarQube:
  URL: https://sonarqube.villagers.live
  Username: admin
  Password: admin (CHANGE ON FIRST LOGIN!)
  Database Password: ${SONAR_DB_PASSWORD}

========================================
EOF
chmod 600 .credentials/monitoring-credentials.txt

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}Access URLs:${NC}"
echo "  Kibana: https://kibana.villagers.live"
echo "  Jaeger: https://jaeger.villagers.live"
echo "  SonarQube: https://sonarqube.villagers.live"

echo -e "\n${YELLOW}Credentials saved to:${NC}"
echo "  .credentials/monitoring-credentials.txt"

echo -e "\n${YELLOW}Port forwarding (for local access):${NC}"
echo "  Kibana: kubectl port-forward -n monitoring svc/kibana-kibana 5601:5601"
echo "  Jaeger: kubectl port-forward -n monitoring svc/jaeger-query 16686:16686"
echo "  SonarQube: kubectl port-forward -n monitoring svc/sonarqube-sonarqube 9000:9000"

echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Wait 5-10 minutes for SSL certificates"
echo "2. Access Kibana and create index patterns"
echo "3. Login to SonarQube and change admin password"
echo "4. Configure SonarQube projects"
echo "5. Instrument services with Jaeger clients"
