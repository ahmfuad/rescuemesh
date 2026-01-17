# Complete DevOps Deployment Guide for RescueMesh on Digital Ocean

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Digital Ocean Setup](#digital-ocean-setup)
3. [Cloudflare DNS Configuration](#cloudflare-dns-configuration)
4. [Kubernetes Deployment](#kubernetes-deployment)
5. [CI/CD Pipeline](#cicd-pipeline)
6. [Monitoring & Observability](#monitoring--observability)
7. [Backup & Disaster Recovery](#backup--disaster-recovery)
8. [Security Best Practices](#security-best-practices)
9. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Tools
```bash
# Install doctl (Digital Ocean CLI)
brew install doctl  # macOS
# or
snap install doctl  # Linux

# Install kubectl
brew install kubectl

# Install Helm
brew install helm

# Install Velero (for backups)
brew install velero
```

### Required Accounts
- ✅ Digital Ocean account with billing enabled
- ✅ Cloudflare account with domain added
- ✅ GitHub account (for CI/CD)

---

## Digital Ocean Setup

### 1. Create Digital Ocean Kubernetes Cluster

#### Via Web Console:
1. Log in to Digital Ocean
2. Go to **Kubernetes** → **Create Cluster**
3. Configure:
   - **Region**: Choose closest to your users (e.g., NYC3, SFO3)
   - **Kubernetes Version**: Latest stable (1.28+)
   - **Node Pool**:
     - Size: 3 nodes minimum for HA
     - Plan: Basic ($12/month per node) or higher
     - Node type: 2 vCPU, 4GB RAM minimum
   - **Name**: `rescuemesh-cluster`
4. Click **Create Cluster**

#### Via CLI:
```bash
# Authenticate
doctl auth init

# Create cluster
doctl kubernetes cluster create rescuemesh-cluster   --region nyc3   --version 1.34.1-do.2   --node-pool "name=worker-pool;size=s-2vcpu-4gb;count=3;auto-scale=true;min-nodes=1;max-nodes=3"

# Save kubeconfig
doctl kubernetes cluster kubeconfig save rescuemesh-cluster

# Verify connection
kubectl cluster-info
kubectl get nodes
```

### 2. Create Container Registry

```bash
# Create registry
doctl registry create rescuemesh

# Get login credentials
doctl registry login

# Get registry endpoint
doctl registry get
```

### 3. Create Digital Ocean Spaces (for backups)

```bash
# Via web console: Spaces → Create Space
# Name: rescuemesh-backups
# Region: Same as your cluster
# CDN: Enable

# Create API keys for Spaces
# Spaces → Settings → Spaces access keys → Generate New Key
# Save: Access Key ID and Secret Key
```

### 4. Enable Digital Ocean Monitoring (Optional but Recommended)

```bash
# Enable monitoring on cluster nodes
doctl kubernetes cluster update rescuemesh-cluster \
  --auto-upgrade \
  --surge-upgrade \
  --maintenance-window sunday=02:00
```

---

## Cloudflare DNS Configuration

### 1. Add Domain to Cloudflare
1. Log in to Cloudflare
2. Add site: `villagers.live`
3. Update nameservers at your domain registrar

### 2. Configure DNS Records

After deployment, you'll get a Load Balancer IP. Configure:

```
Type    Name    Content                 Proxy   TTL
A       @       <LB-IP>                ✓       Auto
A       www     <LB-IP>                ✓       Auto
A       api     <LB-IP>                ✓       Auto
A       grafana <LB-IP>                ✓       Auto
CNAME   *       villagers.live         ✓       Auto
```

### 3. SSL/TLS Settings
1. Go to **SSL/TLS** → **Overview**
2. Set mode to: **Full (strict)**
3. Enable: **Always Use HTTPS**
4. Enable: **Automatic HTTPS Rewrites**

### 4. Security Settings
1. **Firewall** → **Security Level**: Medium
2. **WAF** → Enable managed rules
3. **DDoS Protection**: Automatic (enabled by default)
4. **Bot Fight Mode**: Enable

### 5. Performance Settings
1. **Speed** → **Optimization**:
   - Auto Minify: CSS, JS, HTML
   - Brotli: On
2. **Caching**:
   - Caching Level: Standard
   - Browser Cache TTL: 4 hours

---

## Kubernetes Deployment

### Method 1: Automated Deployment (Recommended)

```bash
# Clone repository
cd /home/ahmf/Documents/rescuemesh

# Update secrets
nano k8s/secrets/secrets.yaml  # Update with real values

# Run deployment script
./scripts/deploy.sh
```

The script will:
- ✅ Create namespace and resource quotas
- ✅ Deploy storage classes
- ✅ Deploy secrets and configmaps
- ✅ Deploy PostgreSQL, Redis, RabbitMQ
- ✅ Deploy all 6 microservices
- ✅ Install NGINX Ingress Controller
- ✅ Install cert-manager for SSL
- ✅ Configure ingress with SSL
- ✅ Setup HPA and PDB for high availability

### Method 2: Manual Deployment

```bash
# 1. Create namespace
kubectl apply -f k8s/namespace.yaml

# 2. Deploy storage
kubectl apply -f k8s/storage/

# 3. Deploy secrets (UPDATE FIRST!)
kubectl apply -f k8s/secrets/secrets.yaml

# 4. Deploy ConfigMaps
kubectl apply -f k8s/configmaps/

# 5. Deploy infrastructure
kubectl apply -f k8s/infrastructure/

# Wait for databases
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgresql -n rescuemesh --timeout=5m

# 6. Deploy services
kubectl apply -f k8s/services/

# 7. Deploy applications
kubectl apply -f k8s/deployments/

# 8. Deploy HPA and PDB
kubectl apply -f k8s/hpa/
kubectl apply -f k8s/pdb/

# 9. Deploy network policies
kubectl apply -f k8s/network-policies/

# 10. Install NGINX Ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/do-loadbalancer-enable-proxy-protocol"="true"

# 11. Install cert-manager
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set installCRDs=true

# Wait for cert-manager
sleep 30

# 12. Deploy issuer and ingress
kubectl apply -f k8s/issuer.yaml
kubectl apply -f k8s/ingress/

# 13. Get Load Balancer IP
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

### Build and Push Docker Images

```bash
# Log in to DO Container Registry
doctl registry login

# Build and push each service
cd rescuemesh-user-service
docker build -t registry.digitalocean.com/rescuemesh/user-service:latest .
docker push registry.digitalocean.com/rescuemesh/user-service:latest

cd ../rescuemesh-skill-service
docker build -t registry.digitalocean.com/rescuemesh/skill-service:latest .
docker push registry.digitalocean.com/rescuemesh/skill-service:latest

cd ../rescuemesh-disaster-service
docker build -t registry.digitalocean.com/rescuemesh/disaster-service:latest .
docker push registry.digitalocean.com/rescuemesh/disaster-service:latest

cd ../rescuemesh-sos-service
docker build -t registry.digitalocean.com/rescuemesh/sos-service:latest .
docker push registry.digitalocean.com/rescuemesh/sos-service:latest

cd ../rescuemesh-matching-service
docker build -t registry.digitalocean.com/rescuemesh/matching-service:latest .
docker push registry.digitalocean.com/rescuemesh/matching-service:latest

cd ../rescuemesh-notification-service
docker build -t registry.digitalocean.com/rescuemesh/notification-service:latest .
docker push registry.digitalocean.com/rescuemesh/notification-service:latest

cd ../frontend
docker build -t registry.digitalocean.com/rescuemesh/frontend:latest .
docker push registry.digitalocean.com/rescuemesh/frontend:latest
```

### Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n rescuemesh

# Check services
kubectl get svc -n rescuemesh

# Check ingress
kubectl get ingress -n rescuemesh

# Check certificate (wait 5-10 minutes for issuance)
kubectl get certificate -n rescuemesh
kubectl describe certificate rescuemesh-tls -n rescuemesh

# Run health check
./scripts/health-check.sh

# Test endpoints
curl https://villagers.live/health
curl https://villagers.live/api/users/health
```

---

## CI/CD Pipeline

### 1. Setup GitHub Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**

Add the following secrets:

```
DIGITALOCEAN_ACCESS_TOKEN      # Your DO API token
DO_SPACES_ACCESS_KEY           # DO Spaces access key
DO_SPACES_SECRET_KEY           # DO Spaces secret key
```

### 2. GitHub Actions Workflows

Two workflows are configured:

#### **CI/CD Pipeline** (`.github/workflows/ci-cd.yml`)
- Triggers on push to `main` branch
- Builds Docker images for all services
- Scans for vulnerabilities with Trivy
- Pushes to DO Container Registry
- Deploys to Kubernetes cluster
- Runs smoke tests
- Auto-rollback on failure

#### **Database Backup** (`.github/workflows/backup.yml`)
- Runs every 6 hours
- Backs up all PostgreSQL databases
- Uploads to DO Spaces
- Retains last 30 backups

### 3. Manual Deployment Trigger

```bash
# Trigger deployment via GitHub CLI
gh workflow run ci-cd.yml

# Or push to main branch
git push origin main
```

---

## Monitoring & Observability

### Setup Monitoring Stack

```bash
./scripts/setup-monitoring.sh
```

This installs:
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization dashboards
- **Loki**: Log aggregation
- **Promtail**: Log shipping

### Access Grafana

```bash
# Get admin password
kubectl get secret -n monitoring prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode

# Port forward
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Open browser: http://localhost:3000
# Username: admin
# Password: <from above command>
```

### Pre-configured Dashboards
- Kubernetes Cluster Monitoring
- Node Metrics
- Pod Resources
- Microservices Performance
- Database Performance
- Ingress/Network Metrics

### Custom Metrics
Services should expose `/metrics` endpoint for Prometheus scraping.

Example Go service (user-service, skill-service):
```go
import "github.com/prometheus/client_golang/prometheus/promhttp"

http.Handle("/metrics", promhttp.Handler())
```

---

## Backup & Disaster Recovery

### Setup Velero

```bash
./scripts/setup-backup.sh
```

### Backup Schedules

Configured automatic backups:
- **Full backup**: Daily at 2 AM (30-day retention)
- **Database backup**: Every 6 hours (7-day retention)
- **Config backup**: Daily at 3 AM (90-day retention)
- **Weekly backup**: Sunday 1 AM (180-day retention)

### Manual Backup

```bash
# Backup entire namespace
velero backup create rescuemesh-manual \
  --include-namespaces rescuemesh

# Backup specific service
velero backup create user-service-backup \
  --include-namespaces rescuemesh \
  --selector app=user-service

# Check backup status
velero backup describe rescuemesh-manual
```

### Restore from Backup

```bash
# List available backups
velero backup get

# Restore
velero restore create --from-backup rescuemesh-daily-20260117

# Monitor restore
velero restore describe <restore-name>
```

---

## Security Best Practices

### 1. Secrets Management

```bash
# Use sealed-secrets for GitOps
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Seal a secret
kubeseal --format=yaml < secret.yaml > sealed-secret.yaml
```

### 2. Network Policies

Network policies are configured to:
- Deny all ingress by default
- Allow only necessary service-to-service communication
- Allow ingress controller to reach services
- Allow services to reach databases

### 3. RBAC

```bash
# Create service account for CI/CD
kubectl create serviceaccount github-actions -n rescuemesh

# Create role and binding
kubectl create role deployer \
  --verb=get,list,create,update,patch,delete \
  --resource=deployments,services,configmaps \
  -n rescuemesh

kubectl create rolebinding github-actions-deployer \
  --role=deployer \
  --serviceaccount=rescuemesh:github-actions \
  -n rescuemesh
```

### 4. Pod Security

All deployments include:
- Resource limits and requests
- Security contexts
- Read-only root filesystems (where possible)
- Non-root users

### 5. Image Security

```bash
# Scan images for vulnerabilities
trivy image registry.digitalocean.com/rescuemesh/user-service:latest
```

---

## Troubleshooting

### Common Issues

#### 1. Pods not starting
```bash
# Check pod status
kubectl describe pod <pod-name> -n rescuemesh

# Check logs
kubectl logs <pod-name> -n rescuemesh

# Check events
kubectl get events -n rescuemesh --sort-by='.lastTimestamp'
```

#### 2. Certificate not issuing
```bash
# Check certificate status
kubectl describe certificate rescuemesh-tls -n rescuemesh

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# Check challenge
kubectl get challenges -n rescuemesh
```

#### 3. Services not accessible
```bash
# Check ingress
kubectl describe ingress rescuemesh-ingress -n rescuemesh

# Check load balancer
kubectl get svc -n ingress-nginx

# Test from pod
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://user-service.rescuemesh.svc.cluster.local:3001/health
```

#### 4. Database connection issues
```bash
# Check database pod
kubectl logs <postgres-pod> -n rescuemesh

# Test connection
kubectl exec -it <service-pod> -n rescuemesh -- \
  nc -zv postgres-users 5432
```

#### 5. High memory/CPU usage
```bash
# Check resource usage
kubectl top pods -n rescuemesh

# Check HPA status
kubectl get hpa -n rescuemesh

# Scale manually if needed
kubectl scale deployment user-service --replicas=3 -n rescuemesh
```

### Debug Commands

```bash
# Run health check script
./scripts/health-check.sh

# Get all resources
kubectl get all -n rescuemesh

# Check resource quotas
kubectl describe resourcequota -n rescuemesh

# Check pod disruption budgets
kubectl get pdb -n rescuemesh

# Check network policies
kubectl get networkpolicy -n rescuemesh
```

---

## Maintenance

### Update Deployments

```bash
# Update image
kubectl set image deployment/user-service \
  user-service=registry.digitalocean.com/rescuemesh/user-service:v2.0.0 \
  -n rescuemesh

# Rollout status
kubectl rollout status deployment/user-service -n rescuemesh

# Rollback if needed
kubectl rollout undo deployment/user-service -n rescuemesh
```

### Scale Services

```bash
# Manual scaling
kubectl scale deployment user-service --replicas=5 -n rescuemesh

# Update HPA
kubectl edit hpa user-service-hpa -n rescuemesh
```

### Database Migrations

```bash
# Run migrations as a Job
kubectl create job user-migration --from=cronjob/user-migration -n rescuemesh
```

---

## Cost Optimization

### Current Estimated Costs (Digital Ocean)

- **Kubernetes Cluster**: 3 nodes × $24/month = $72/month
- **Load Balancer**: $12/month
- **Block Storage**: ~20GB × $0.10/GB = $2/month
- **Container Registry**: $5/month (basic)
- **Bandwidth**: $0.01/GB (outbound)
- **Spaces**: $5/month (250GB)

**Total**: ~$96-110/month

### Optimization Tips

1. **Use cluster autoscaling**
2. **Right-size pods** based on actual usage
3. **Use DO managed databases** for production (optional)
4. **Enable image garbage collection**
5. **Set up budget alerts** in DO console

---

## Next Steps

1. ✅ Deploy to Digital Ocean
2. ✅ Configure Cloudflare DNS
3. ✅ Setup monitoring
4. ✅ Configure backups
5. ⬜ Setup alerting (PagerDuty/Slack)
6. ⬜ Configure auto-scaling policies
7. ⬜ Implement Blue-Green deployments
8. ⬜ Add end-to-end tests
9. ⬜ Document runbooks
10. ⬜ Setup status page

---

## Support & Resources

- [Digital Ocean Kubernetes Documentation](https://docs.digitalocean.com/products/kubernetes/)
- [Cloudflare Documentation](https://developers.cloudflare.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [cert-manager Documentation](https://cert-manager.io/docs/)
- [Velero Documentation](https://velero.io/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)

---

**Last Updated**: January 17, 2026  
**Version**: 1.0.0
