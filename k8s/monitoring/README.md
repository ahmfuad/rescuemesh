# Monitoring Stack for RescueMesh

This directory contains configurations for the observability stack:
- Prometheus for metrics collection
- Grafana for visualization
- Loki for log aggregation
- Promtail for log shipping

## Quick Deploy

```bash
# Add Prometheus Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Prometheus Stack (includes Grafana)
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --values prometheus-values.yaml

# Install Loki Stack
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --values loki-values.yaml
```

## Access Grafana

```bash
# Get Grafana admin password
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode

# Port forward to access locally
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

## Pre-configured Dashboards

- Kubernetes Cluster Monitoring
- Node Exporter
- Pod Metrics
- Microservices Overview
- Database Performance
- Ingress Metrics
