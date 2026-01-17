#!/bin/bash

# ==========================================
# DOKS Observability Stack Installer
# Includes: ELK (Elastic, Kibana, Beats), Jaeger, SonarQube
# ==========================================

set -e # Exit immediately if a command exits with a non-zero status

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting DOKS Observability Installation...${NC}"

# 1. PRE-FLIGHT CHECKS
echo -e "${GREEN}[1/8] Checking prerequisites...${NC}"
if ! command -v helm &> /dev/null; then
    echo -e "${RED}Helm is not installed. Please install Helm first.${NC}"
    exit 1
fi

# 2. ADD HELM REPOS
echo -e "${GREEN}[2/8] Updating Helm Repositories...${NC}"
helm repo add elastic https://helm.elastic.co
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
helm repo update

# 3. CREATE NAMESPACE
echo -e "${GREEN}[3/8] Creating 'monitoring' namespace...${NC}"
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# 4. GENERATE CONFIGURATION (VALUES.YAML)
# We create a single values file to share credentials and settings
echo -e "${GREEN}[4/8] Generating DOKS-specific configuration...${NC}"

cat <<EOF > doks-monitoring-values.yaml
# --- Elasticsearch Config ---
elasticsearch:
  replicas: 1
  minimumMasterNodes: 1
  volumeClaimTemplate:
    accessModes: [ "ReadWriteOnce" ]
    storageClassName: "do-block-storage" 
    resources:
      requests:
        storage: 10Gi
  resources:
    requests:
      memory: "1Gi"
      cpu: "500m"
    limits:
      memory: "2Gi"
      cpu: "1000m"

# --- Kibana Config ---
kibana:
  resources:
    requests:
      memory: "512Mi"
      cpu: "500m"
    limits:
      memory: "1Gi"
      cpu: "1000m"

# --- Filebeat Config (Logs) ---
filebeat:
  daemonset:
    enabled: true
  filebeatConfig:
    filebeat.yml: |
      filebeat.inputs:
      - type: container
        paths:
          - /var/log/containers/*.log
        processors:
        - add_kubernetes_metadata:
            host: \${NODE_NAME}
            matchers:
            - logs_path:
                logs_path: "/var/log/containers/"
      output.elasticsearch:
        host: '\${NODE_NAME}'
        hosts: '[\${ELASTICSEARCH_HOSTS:elasticsearch-master:9200}]'
        username: "elastic" 
        password: "\${ELASTICSEARCH_PASSWORD}"

# --- Metricbeat Config (Metrics) ---
metricbeat:
  daemonset:
    enabled: true
  deployment:
    enabled: true
  metricbeatConfig:
    metricbeat.yml: |
      metricbeat.modules:
      - module: kubernetes
        metricsets:
          - container
          - node
          - pod
          - system
          - volume
        period: 10s
        host: "\${NODE_NAME}"
        hosts: ["https://\${NODE_NAME}:10250"]
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        ssl.verification_mode: "none"
      output.elasticsearch:
        hosts: '[\${ELASTICSEARCH_HOSTS:elasticsearch-master:9200}]'
        username: "elastic"
        password: "\${ELASTICSEARCH_PASSWORD}"
EOF

# 5. INSTALL ELASTICSEARCH
echo -e "${GREEN}[5/8] Installing Elasticsearch (This takes time)...${NC}"
# We set a password explicitly so we can pass it to other components easily
ELASTIC_PASSWORD="StrongPassword123!"

helm upgrade --install elasticsearch elastic/elasticsearch \
  --namespace monitoring \
  --values doks-monitoring-values.yaml \
  --set security.elasticPassword=$ELASTIC_PASSWORD \
  --wait --timeout 10m

# 6. INSTALL LOGGING & METRICS (Kibana, Filebeat, Metricbeat)
echo -e "${GREEN}[6/8] Installing Kibana and Beats...${NC}"

# Install Kibana
helm upgrade --install kibana elastic/kibana \
  --namespace monitoring \
  --values doks-monitoring-values.yaml \
  --set elasticsearch.hosts=http://elasticsearch-master:9200 \
  --set elasticsearch.password=$ELASTIC_PASSWORD

# Install Filebeat (Logs)
helm upgrade --install filebeat elastic/filebeat \
  --namespace monitoring \
  --values doks-monitoring-values.yaml \
  --set elasticsearch.hosts=http://elasticsearch-master:9200 \
  --set elasticsearch.password=$ELASTIC_PASSWORD

# Install Metricbeat (Metrics)
helm upgrade --install metricbeat elastic/metricbeat \
  --namespace monitoring \
  --values doks-monitoring-values.yaml \
  --set elasticsearch.hosts=http://elasticsearch-master:9200 \
  --set elasticsearch.password=$ELASTIC_PASSWORD

# 7. INSTALL JAEGER (Tracing)
echo -e "${GREEN}[7/8] Installing Jaeger...${NC}"
# Using "allInOne" for simplicity. For high scale, swap to "production" strategy
helm upgrade --install jaeger jaegertracing/jaeger \
  --namespace monitoring \
  --set provisionDataStore.cassandra=false \
  --set allInOne.enabled=true \
  --set storage.type=memory

# 8. INSTALL SONARQUBE (Code Quality)
echo -e "${GREEN}[8/8] Installing SonarQube...${NC}"
helm upgrade --install sonarqube sonarqube/sonarqube \
  --namespace monitoring \
  --set persistence.enabled=true \
  --set persistence.storageClass="do-block-storage" \
  --set persistence.size=5Gi \
  --timeout 10m

# ==========================================
# COMPLETION
# ==========================================
echo -e "\n${BLUE}=========================================${NC}"
echo -e "${GREEN}      INSTALLATION COMPLETE!      ${NC}"
echo -e "${BLUE}=========================================${NC}"
echo -e "Use the commands below to access your dashboards:\n"

echo -e "1. ${GREEN}Kibana (Logs & Metrics)${NC}"
echo -e "   Run: kubectl port-forward svc/kibana-kibana 5601:5601 -n monitoring"
echo -e "   URL: http://localhost:5601"
echo -e "   User: elastic"
echo -e "   Pass: $ELASTIC_PASSWORD"
echo ""

echo -e "2. ${GREEN}Jaeger (Tracing)${NC}"
echo -e "   Run: kubectl port-forward svc/jaeger-query 16686:16686 -n monitoring"
echo -e "   URL: http://localhost:16686"
echo ""

echo -e "3. ${GREEN}SonarQube (Code Quality)${NC}"
echo -e "   Run: kubectl port-forward svc/sonarqube-sonarqube 9000:9000 -n monitoring"
echo -e "   URL: http://localhost:9000"
echo -e "   User: admin"
echo -e "   Pass: admin (You will be asked to change this)"
echo ""