# ELK Stack, Jaeger & SonarQube Setup Guide

Complete guide for deploying and configuring advanced monitoring and code quality tools.

## 📋 Table of Contents

- [Overview](#overview)
- [ELK Stack Setup](#elk-stack-setup)
- [Jaeger Tracing Setup](#jaeger-tracing-setup)
- [SonarQube Setup](#sonarqube-setup)
- [Service Instrumentation](#service-instrumentation)
- [Dashboard Configuration](#dashboard-configuration)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

### Components

**ELK Stack** (Log Analysis):
- **Elasticsearch**: Search and analytics engine
- **Logstash**: Log processing pipeline
- **Kibana**: Visualization dashboard
- **Filebeat**: Log shipper for container logs
- **Metricbeat**: Metrics shipper for system metrics

**Jaeger** (Distributed Tracing):
- **Jaeger Agent**: Sidecar for trace collection
- **Jaeger Collector**: Receives and processes traces
- **Jaeger Query**: UI for trace visualization
- **Elasticsearch**: Trace storage backend

**SonarQube** (Code Quality):
- **SonarQube Server**: Code analysis platform
- **PostgreSQL**: SonarQube database
- **Scanner**: Integrated in CI/CD pipeline

### Architecture

```
Application Pods
├── Filebeat (logs) ──────────> Logstash ──> Elasticsearch ──> Kibana
├── Metricbeat (metrics) ─────> Elasticsearch ──> Kibana
├── Jaeger Agent (traces) ────> Jaeger Collector ──> Elasticsearch ──> Jaeger UI
└── Application Code ─────────> SonarQube Scanner ──> SonarQube Server
```

## 🔧 ELK Stack Setup

### Quick Installation

```bash
# Install entire stack
cd /home/ahmf/Documents/rescuemesh
./scripts/install-advanced-monitoring.sh
```

### Manual Installation

#### 1. Add Helm Repository

```bash
helm repo add elastic https://helm.elastic.co
helm repo update
```

#### 2. Create Namespace

```bash
kubectl create namespace monitoring
```

#### 3. Install Elasticsearch

```bash
# Create credentials secret
ELASTIC_PASSWORD=$(openssl rand -base64 32)
kubectl create secret generic elasticsearch-credentials \
  --from-literal=password=$ELASTIC_PASSWORD \
  --namespace monitoring

# Install Elasticsearch
helm install elasticsearch elastic/elasticsearch \
  --namespace monitoring \
  --set replicas=3 \
  --set minimumMasterNodes=2 \
  --set persistence.enabled=true \
  --set persistence.size=100Gi \
  --set resources.requests.memory=2Gi \
  --set resources.requests.cpu=1000m \
  --set esJavaOpts="-Xmx1g -Xms1g" \
  --wait --timeout 10m

# Save password
echo "Elasticsearch password: $ELASTIC_PASSWORD"
```

#### 4. Verify Elasticsearch

```bash
# Check pods
kubectl get pods -n monitoring -l app=elasticsearch-master

# Port forward
kubectl port-forward -n monitoring svc/elasticsearch-master 9200:9200

# Test (in another terminal)
curl -u elastic:$ELASTIC_PASSWORD http://localhost:9200/_cluster/health
```

#### 5. Install Logstash

```bash
# Create Logstash pipeline config
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: logstash-pipeline
  namespace: monitoring
data:
  logstash.conf: |
    input {
      beats {
        port => 5044
      }
    }
    
    filter {
      # Parse JSON logs
      if [message] =~ /^\{.*\}$/ {
        json {
          source => "message"
        }
      }
      
      # Add Kubernetes metadata
      mutate {
        add_field => {
          "cluster" => "production"
          "environment" => "production"
        }
      }
      
      # Parse log levels
      grok {
        match => { "message" => "%{LOGLEVEL:log_level}" }
      }
    }
    
    output {
      elasticsearch {
        hosts => ["elasticsearch-master:9200"]
        user => "elastic"
        password => "\${ELASTICSEARCH_PASSWORD}"
        index => "logstash-%{[@metadata][beat]}-%{+YYYY.MM.dd}"
      }
    }
EOF

# Install Logstash
helm install logstash elastic/logstash \
  --namespace monitoring \
  --set replicas=2 \
  --set persistence.enabled=true \
  --set extraEnvs[0].name=ELASTICSEARCH_PASSWORD \
  --set extraEnvs[0].valueFrom.secretKeyRef.name=elasticsearch-credentials \
  --set extraEnvs[0].valueFrom.secretKeyRef.key=password \
  --set logstashPipeline.logstash\.conf="$(cat k8s/monitoring/elk-values.yaml | grep -A 50 'logstash.conf')" \
  --wait
```

#### 6. Install Kibana

```bash
helm install kibana elastic/kibana \
  --namespace monitoring \
  --set elasticsearchHosts="http://elasticsearch-master:9200" \
  --set resources.requests.memory=1Gi \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=kibana.villagers.live \
  --set ingress.hosts[0].paths[0].path=/ \
  --set ingress.tls[0].secretName=kibana-tls \
  --set ingress.tls[0].hosts[0]=kibana.villagers.live \
  --wait
```

#### 7. Install Filebeat

```bash
helm install filebeat elastic/filebeat \
  --namespace monitoring \
  --set daemonset.enabled=true \
  --set deployment.enabled=false \
  --set extraEnvs[0].name=ELASTICSEARCH_PASSWORD \
  --set extraEnvs[0].valueFrom.secretKeyRef.name=elasticsearch-credentials \
  --set extraEnvs[0].valueFrom.secretKeyRef.key=password \
  --wait
```

#### 8. Install Metricbeat

```bash
helm install metricbeat elastic/metricbeat \
  --namespace monitoring \
  --set daemonset.enabled=true \
  --set deployment.enabled=false \
  --set kube-state-metrics.enabled=true \
  --set extraEnvs[0].name=ELASTICSEARCH_PASSWORD \
  --set extraEnvs[0].valueFrom.secretKeyRef.name=elasticsearch-credentials \
  --set extraEnvs[0].valueFrom.secretKeyRef.key=password \
  --wait
```

### Access Kibana

```bash
# Wait for ingress
kubectl wait --for=condition=ready ingress/kibana -n monitoring --timeout=5m

# Get credentials
echo "URL: https://kibana.villagers.live"
echo "Username: elastic"
echo "Password: $ELASTIC_PASSWORD"
```

### Configure Kibana

1. **Login** to https://kibana.villagers.live
2. **Create Index Patterns**:
   - Go to Stack Management > Index Patterns
   - Create pattern: `filebeat-*`
   - Time field: `@timestamp`
   - Create pattern: `metricbeat-*`
   - Time field: `@timestamp`

3. **Import Dashboards**:
   ```bash
   # Filebeat dashboards
   kubectl exec -it -n monitoring $(kubectl get pod -n monitoring -l app=filebeat -o jsonpath='{.items[0].metadata.name}') -- filebeat setup --dashboards
   
   # Metricbeat dashboards
   kubectl exec -it -n monitoring $(kubectl get pod -n monitoring -l app=metricbeat -o jsonpath='{.items[0].metadata.name}') -- metricbeat setup --dashboards
   ```

4. **Create Custom Dashboards**:
   - Go to Dashboard > Create dashboard
   - Add visualizations for:
     - Error rate by service
     - Request latency
     - Resource usage
     - Log volume

## 🔍 Jaeger Tracing Setup

### Installation

```bash
# Add Helm repo
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo update

# Create auth secret
JAEGER_USER=admin
JAEGER_PASSWORD=$(openssl rand -base64 16)
kubectl create secret generic jaeger-auth \
  --from-literal=auth=$(htpasswd -nb $JAEGER_USER $JAEGER_PASSWORD) \
  --namespace monitoring

# Install Jaeger
helm install jaeger jaegertracing/jaeger \
  --namespace monitoring \
  --set provisionDataStore.cassandra=false \
  --set provisionDataStore.elasticsearch=true \
  --set storage.type=elasticsearch \
  --set storage.elasticsearch.host=elasticsearch-master \
  --set storage.elasticsearch.port=9200 \
  --set storage.elasticsearch.user=elastic \
  --set storage.elasticsearch.password=$ELASTIC_PASSWORD \
  --set agent.enabled=true \
  --set collector.enabled=true \
  --set collector.replicaCount=2 \
  --set query.enabled=true \
  --set query.ingress.enabled=true \
  --set query.ingress.hosts[0]=jaeger.villagers.live \
  --set query.ingress.annotations."cert-manager\.io/cluster-issuer"=letsencrypt-prod \
  --set query.ingress.tls[0].secretName=jaeger-tls \
  --set query.ingress.tls[0].hosts[0]=jaeger.villagers.live \
  --wait --timeout 10m

echo "Jaeger URL: https://jaeger.villagers.live"
echo "Username: $JAEGER_USER"
echo "Password: $JAEGER_PASSWORD"
```

### Verify Installation

```bash
# Check pods
kubectl get pods -n monitoring -l app.kubernetes.io/name=jaeger

# Port forward (for local access)
kubectl port-forward -n monitoring svc/jaeger-query 16686:16686

# Open browser: http://localhost:16686
```

### Configure Jaeger

1. **Set Sampling Rate**:
   ```yaml
   # In your service deployment
   env:
     - name: JAEGER_SAMPLER_TYPE
       value: probabilistic
     - name: JAEGER_SAMPLER_PARAM
       value: "0.1"  # Sample 10% of requests
   ```

2. **Configure Storage Retention**:
   ```bash
   # Edit Jaeger deployment
   kubectl edit deployment -n monitoring jaeger-collector
   
   # Add environment variable
   - name: ES_INDEX_PREFIX
     value: jaeger
   - name: ES_TAGS_AS_FIELDS_ALL
     value: "true"
   ```

## 🔬 SonarQube Setup

### Installation

```bash
# Add Helm repo
helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
helm repo update

# Create PostgreSQL secret
SONAR_DB_PASSWORD=$(openssl rand -base64 24)
kubectl create secret generic sonarqube-postgres \
  --from-literal=password=$SONAR_DB_PASSWORD \
  --namespace monitoring

# Install SonarQube
helm install sonarqube sonarqube/sonarqube \
  --namespace monitoring \
  --set postgresql.enabled=true \
  --set postgresql.auth.password=$SONAR_DB_PASSWORD \
  --set persistence.enabled=true \
  --set persistence.size=20Gi \
  --set ingress.enabled=true \
  --set ingress.hosts[0].name=sonarqube.villagers.live \
  --set ingress.annotations."cert-manager\.io/cluster-issuer"=letsencrypt-prod \
  --set ingress.tls[0].secretName=sonarqube-tls \
  --set ingress.tls[0].hosts[0]=sonarqube.villagers.live \
  --wait --timeout 15m

echo "SonarQube URL: https://sonarqube.villagers.live"
echo "Default credentials: admin / admin"
echo "CHANGE PASSWORD ON FIRST LOGIN!"
```

### Initial Configuration

1. **Login** to https://sonarqube.villagers.live
   - Username: `admin`
   - Password: `admin`

2. **Change Admin Password**:
   - Click profile > My Account > Security
   - Change password

3. **Generate Token**:
   - My Account > Security > Generate Tokens
   - Name: `GitHub Actions`
   - Type: `Project Analysis Token`
   - Save token securely

4. **Create Projects**:
   ```bash
   # For each microservice
   # Go to: Projects > Create Project
   # Project key: rescuemesh-user-service
   # Display name: RescueMesh User Service
   # Main branch: main
   ```

5. **Configure Quality Gates**:
   - Quality Gates > Create
   - Set conditions:
     - Coverage < 80% = Failed
     - Duplications > 3% = Failed
     - Code Smells > 50 = Warning
     - Security Hotspots > 0 = Warning

### GitHub Actions Integration

Add to `.github/workflows/staging-production.yml`:

```yaml
- name: SonarQube Scan
  uses: sonarsource/sonarqube-scan-action@master
  env:
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
    SONAR_HOST_URL: https://sonarqube.villagers.live
  with:
    projectBaseDir: .
    args: >
      -Dsonar.projectKey=rescuemesh-${{ matrix.service }}
      -Dsonar.sources=src
      -Dsonar.tests=tests
      -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info
```

## 🔌 Service Instrumentation

### Go Services (User, Skill)

#### 1. Install Dependencies

```bash
cd rescuemesh-user-service
go get github.com/uber/jaeger-client-go
go get github.com/opentracing/opentracing-go
```

#### 2. Initialize Tracer

Create `tracing/tracer.go`:

```go
package tracing

import (
    "io"
    "github.com/uber/jaeger-client-go"
    "github.com/uber/jaeger-client-go/config"
    "github.com/opentracing/opentracing-go"
)

func InitTracer(serviceName string) (opentracing.Tracer, io.Closer, error) {
    cfg := &config.Configuration{
        ServiceName: serviceName,
        Sampler: &config.SamplerConfig{
            Type:  "probabilistic",
            Param: 0.1, // Sample 10% of traces
        },
        Reporter: &config.ReporterConfig{
            LogSpans:           true,
            LocalAgentHostPort: "jaeger-agent:6831",
        },
    }

    tracer, closer, err := cfg.NewTracer()
    if err != nil {
        return nil, nil, err
    }

    opentracing.SetGlobalTracer(tracer)
    return tracer, closer, nil
}
```

#### 3. Instrument HTTP Handlers

Update `main.go`:

```go
import (
    "your-module/tracing"
    "github.com/opentracing/opentracing-go"
    "github.com/opentracing/opentracing-go/ext"
)

func main() {
    // Initialize tracer
    tracer, closer, err := tracing.InitTracer("user-service")
    if err != nil {
        log.Fatal(err)
    }
    defer closer.Close()

    // ... existing code ...
}

// Instrument handler
func handleUser(w http.ResponseWriter, r *http.Request) {
    // Start span
    span := opentracing.StartSpan("handle-user")
    defer span.Finish()

    // Add tags
    ext.HTTPMethod.Set(span, r.Method)
    ext.HTTPUrl.Set(span, r.URL.String())

    // Your handler logic
    // ...

    // Log events
    span.LogKV("event", "user-fetched", "user_id", userID)
}
```

#### 4. Instrument Database Calls

```go
func GetUser(ctx context.Context, userID string) (*User, error) {
    span, ctx := opentracing.StartSpanFromContext(ctx, "db-get-user")
    defer span.Finish()
    
    span.SetTag("db.type", "postgresql")
    span.SetTag("db.statement", "SELECT * FROM users WHERE id = $1")

    var user User
    err := db.QueryRowContext(ctx, "SELECT * FROM users WHERE id = $1", userID).Scan(&user)
    
    if err != nil {
        ext.Error.Set(span, true)
        span.LogKV("error", err.Error())
        return nil, err
    }

    return &user, nil
}
```

### Node.js Services (SOS, Matching, Notification)

#### 1. Install Dependencies

```bash
cd rescuemesh-sos-service
npm install jaeger-client opentracing
```

#### 2. Initialize Tracer

Create `src/tracing.js`:

```javascript
const { initTracer } = require('jaeger-client');

function initJaeger(serviceName) {
  const config = {
    serviceName: serviceName,
    sampler: {
      type: 'probabilistic',
      param: 0.1,
    },
    reporter: {
      logSpans: true,
      agentHost: process.env.JAEGER_AGENT_HOST || 'jaeger-agent',
      agentPort: process.env.JAEGER_AGENT_PORT || 6831,
    },
  };

  const options = {
    logger: {
      info(msg) {
        console.log('INFO', msg);
      },
      error(msg) {
        console.log('ERROR', msg);
      },
    },
  };

  return initTracer(config, options);
}

module.exports = { initJaeger };
```

#### 3. Instrument Express App

Update `src/index.js`:

```javascript
const express = require('express');
const opentracing = require('opentracing');
const { initJaeger } = require('./tracing');

const app = express();
const tracer = initJaeger('sos-service');

// Tracing middleware
app.use((req, res, next) => {
  const span = tracer.startSpan('http-request');
  span.setTag('http.method', req.method);
  span.setTag('http.url', req.url);

  res.on('finish', () => {
    span.setTag('http.status_code', res.statusCode);
    span.finish();
  });

  req.span = span;
  next();
});

// Example route
app.post('/sos', async (req, res) => {
  const span = tracer.startSpan('create-sos', { childOf: req.span });
  
  try {
    // Your logic here
    const sos = await createSOS(req.body);
    
    span.log({ event: 'sos-created', sos_id: sos.id });
    span.finish();
    
    res.json(sos);
  } catch (error) {
    span.setTag('error', true);
    span.log({ event: 'error', message: error.message });
    span.finish();
    
    res.status(500).json({ error: error.message });
  }
});
```

### Python Service (Disaster)

#### 1. Install Dependencies

```bash
cd rescuemesh-disaster-service
pip install opentelemetry-api opentelemetry-sdk opentelemetry-instrumentation-fastapi opentelemetry-exporter-jaeger
```

#### 2. Initialize Tracer

Update `main.py`:

```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.jaeger.thrift import JaegerExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

# Initialize tracer
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)

# Configure Jaeger exporter
jaeger_exporter = JaegerExporter(
    agent_host_name="jaeger-agent",
    agent_port=6831,
)

# Add span processor
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(jaeger_exporter)
)

app = FastAPI()

# Auto-instrument FastAPI
FastAPIInstrumentor.instrument_app(app)

# Manual instrumentation
@app.post("/disasters")
async def create_disaster(disaster: Disaster):
    with tracer.start_as_current_span("create-disaster") as span:
        span.set_attribute("disaster.type", disaster.type)
        span.set_attribute("disaster.severity", disaster.severity)
        
        try:
            result = await save_disaster(disaster)
            span.add_event("disaster-created", {"id": result.id})
            return result
        except Exception as e:
            span.set_attribute("error", True)
            span.add_event("error", {"message": str(e)})
            raise
```

## 📊 Dashboard Configuration

### Kibana Dashboards

#### Application Logs Dashboard

```json
{
  "title": "RescueMesh Application Logs",
  "visualizations": [
    {
      "type": "line",
      "title": "Log Volume Over Time",
      "query": "kubernetes.namespace:rescuemesh"
    },
    {
      "type": "pie",
      "title": "Logs by Service",
      "query": "kubernetes.namespace:rescuemesh",
      "field": "kubernetes.labels.app"
    },
    {
      "type": "table",
      "title": "Recent Errors",
      "query": "kubernetes.namespace:rescuemesh AND log.level:ERROR"
    }
  ]
}
```

#### Performance Metrics Dashboard

```json
{
  "title": "RescueMesh Performance",
  "visualizations": [
    {
      "type": "line",
      "title": "CPU Usage",
      "query": "metricset.name:container",
      "field": "kubernetes.container.cpu.usage.node.pct"
    },
    {
      "type": "line",
      "title": "Memory Usage",
      "query": "metricset.name:container",
      "field": "kubernetes.container.memory.usage.bytes"
    }
  ]
}
```

### Jaeger Query Examples

1. **Find slow requests**:
   - Service: `user-service`
   - Operation: `handle-user`
   - Min Duration: `1s`

2. **Find errors**:
   - Tags: `error=true`
   - Lookback: `1h`

3. **Trace specific user request**:
   - Tags: `user_id=12345`
   - Limit: `10`

## 🔧 Troubleshooting

### ELK Stack Issues

#### Elasticsearch Not Starting

```bash
# Check pod status
kubectl get pods -n monitoring -l app=elasticsearch-master

# Check logs
kubectl logs -n monitoring elasticsearch-master-0

# Common issues:
# 1. Insufficient memory
kubectl edit deployment -n monitoring elasticsearch-master
# Increase memory limits

# 2. PVC not bound
kubectl get pvc -n monitoring
kubectl describe pvc elasticsearch-master-elasticsearch-master-0

# 3. vm.max_map_count too low (node issue)
# SSH to node and run:
sudo sysctl -w vm.max_map_count=262144
```

#### Kibana Connection Failed

```bash
# Check Elasticsearch connectivity
kubectl exec -it -n monitoring kibana-xxx -- curl http://elasticsearch-master:9200

# Check credentials
kubectl get secret -n monitoring elasticsearch-credentials -o jsonpath='{.data.password}' | base64 -d

# Restart Kibana
kubectl rollout restart deployment -n monitoring kibana
```

#### Filebeat Not Collecting Logs

```bash
# Check Filebeat pods
kubectl get pods -n monitoring -l app=filebeat

# Check logs
kubectl logs -n monitoring -l app=filebeat

# Verify configuration
kubectl exec -it -n monitoring filebeat-xxx -- filebeat test config

# Check output
kubectl exec -it -n monitoring filebeat-xxx -- filebeat test output
```

### Jaeger Issues

#### No Traces Appearing

```bash
# 1. Check Jaeger collector logs
kubectl logs -n monitoring -l app.kubernetes.io/component=collector

# 2. Verify agent is running
kubectl get pods -n monitoring -l app.kubernetes.io/component=agent

# 3. Check service instrumentation
# Ensure JAEGER_AGENT_HOST is set correctly
kubectl get deployment -n rescuemesh user-service -o yaml | grep JAEGER

# 4. Test trace submission
kubectl exec -it -n monitoring jaeger-agent-xxx -- \
  curl -X POST http://localhost:14268/api/traces \
  -H "Content-Type: application/json" \
  -d '{"data": [{"traceID": "1", "spans": []}]}'
```

#### Storage Issues

```bash
# Check Elasticsearch indices
kubectl exec -it -n monitoring elasticsearch-master-0 -- \
  curl -u elastic:$ELASTIC_PASSWORD http://localhost:9200/_cat/indices?v

# Delete old Jaeger indices
kubectl exec -it -n monitoring elasticsearch-master-0 -- \
  curl -XDELETE -u elastic:$ELASTIC_PASSWORD \
  'http://localhost:9200/jaeger-span-*-2024.01.01'
```

### SonarQube Issues

#### SonarQube Not Starting

```bash
# Check pod logs
kubectl logs -n monitoring -l app=sonarqube

# Common issues:
# 1. Database connection
kubectl exec -it -n monitoring sonarqube-postgresql-0 -- \
  psql -U postgres -c "SELECT 1"

# 2. Insufficient resources
kubectl edit deployment -n monitoring sonarqube
# Increase CPU/memory

# 3. Volume permissions
kubectl exec -it -n monitoring sonarqube-xxx -- ls -la /opt/sonarqube
```

#### Analysis Failing in CI/CD

```bash
# Check SonarQube logs
kubectl logs -n monitoring -l app=sonarqube | grep ERROR

# Verify token
# GitHub Secrets > SONAR_TOKEN should match token in SonarQube

# Test connection
curl -u $SONAR_TOKEN: https://sonarqube.villagers.live/api/system/health
```

---

**Next Steps**: After installation, proceed to [service instrumentation](#service-instrumentation) to start collecting traces.
