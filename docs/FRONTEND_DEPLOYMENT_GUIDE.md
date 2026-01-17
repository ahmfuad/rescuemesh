# Frontend Deployment Guide

## Overview

The RescueMesh frontend is a **React + Vite** application served by **nginx** in production. It's containerized and deployed to Kubernetes alongside the backend microservices.

## Current Status

✅ **Frontend deployment configuration created!**

### What Was Missing

The frontend existed in the repository but had **no Kubernetes deployment**. It was only configured for local development via docker-compose.

### What I Created

1. **Kubernetes Deployment** - `k8s/deployments/deployment-frontend.yaml`
2. **Horizontal Pod Autoscaler** - `k8s/hpa/hpa-frontend.yaml`
3. **CI/CD Pipeline** - `.github/workflows/frontend-ci-cd.yaml`
4. **Updated deploy script** to include frontend

## Architecture

```
Frontend Deployment Flow:

User Browser
    ↓
Cloudflare CDN (villagers.live)
    ↓
Digital Ocean Load Balancer
    ↓
NGINX Ingress Controller
    ↓
Frontend Service (ClusterIP)
    ↓
Frontend Pods (2-10 replicas, nginx)
    ↓ (API calls to /api/*)
Backend API Gateway
```

## Deployment Configuration

### 1. Container Image

**Dockerfile**: Multi-stage build
```dockerfile
Stage 1: Builder (Node.js 18)
  - npm ci (install dependencies)
  - npm run build (Vite build)
  - Output: /app/dist

Stage 2: Production (nginx:alpine)
  - Copy built static files
  - Copy nginx.conf
  - Serve on port 80
```

**Registry**: `registry.digitalocean.com/rescuemesh/frontend:latest`

### 2. Kubernetes Resources

**Deployment** (`k8s/deployments/deployment-frontend.yaml`):
```yaml
Replicas: 2 (min)
Container: nginx:alpine with built React app
Port: 80
Resources:
  Requests: 128Mi RAM, 100m CPU
  Limits: 256Mi RAM, 200m CPU
Environment:
  VITE_API_URL: https://api.villagers.live
  NODE_ENV: production
Health Checks:
  Liveness: HTTP GET / (10s delay)
  Readiness: HTTP GET / (5s delay)
```

**Service**:
```yaml
Type: ClusterIP
Port: 80
Selector: app=frontend
```

**Ingress**:
```yaml
Hosts:
  - villagers.live
  - www.villagers.live
TLS:
  - Certificate: frontend-tls (Let's Encrypt)
  - Issuer: letsencrypt-prod
Path: / (all paths)
Backend: frontend:80
```

**HPA** (`k8s/hpa/hpa-frontend.yaml`):
```yaml
Min Replicas: 2
Max Replicas: 10
Metrics:
  - CPU: 70% utilization
  - Memory: 80% utilization
Scale Up: Fast (100% or 2 pods per 30s)
Scale Down: Gradual (50% per 60s, 5min stabilization)
```

### 3. CI/CD Pipeline

**Workflow**: `.github/workflows/frontend-ci-cd.yaml`

**Trigger**:
- Push to `main` or `develop` branches
- Changes in `frontend/` directory

**Jobs**:

1. **Build & Test**
   - Setup Node.js 18
   - Install dependencies (npm ci)
   - Lint code
   - Run tests
   - Build with Vite
   - Upload build artifacts

2. **Docker Build & Push** (main branch only)
   - Login to DO Container Registry
   - Build Docker image
   - Tag: `latest` and `${{ github.sha }}`
   - Push to registry

3. **Deploy** (main branch only)
   - Connect to Kubernetes cluster
   - Update deployment with new image
   - Wait for rollout completion
   - Verify deployment

## Deployment Steps

### Option 1: Using CI/CD (Automated)

```bash
# 1. Make changes to frontend
cd frontend
# ... edit files ...

# 2. Commit and push
git add .
git commit -m "feat: update frontend"
git push origin main

# 3. GitHub Actions will:
#    - Build the app
#    - Create Docker image
#    - Push to registry
#    - Deploy to Kubernetes
#    - Takes ~5-7 minutes
```

### Option 2: Manual Deployment

```bash
# 1. Build Docker image
cd /home/ahmf/Documents/rescuemesh
docker build -t registry.digitalocean.com/rescuemesh/frontend:latest ./frontend

# 2. Push to registry
doctl registry login
docker push registry.digitalocean.com/rescuemesh/frontend:latest

# 3. Deploy to Kubernetes
kubectl apply -f k8s/deployments/deployment-frontend.yaml
kubectl apply -f k8s/hpa/hpa-frontend.yaml

# 4. Wait for rollout
kubectl rollout status deployment/frontend -n rescuemesh

# 5. Verify
kubectl get pods -n rescuemesh -l app=frontend
kubectl get ingress -n rescuemesh frontend-ingress
```

### Option 3: Using Deploy Script

The deploy script now includes frontend:

```bash
# Deploy everything including frontend
./scripts/deploy.sh

# The script will:
# - Deploy all infrastructure
# - Deploy all services (including frontend)
# - Configure ingress
# - Wait for everything to be ready
```

## Access URLs

After deployment:

```
Production:
  https://villagers.live          → Frontend (React app)
  https://www.villagers.live      → Frontend (www subdomain)
  https://api.villagers.live      → Backend API

Staging:
  https://staging.villagers.live  → Staging frontend
```

## Frontend Configuration

### Environment Variables

Set in `k8s/deployments/deployment-frontend.yaml`:

```yaml
VITE_API_URL: https://api.villagers.live
NODE_ENV: production
```

For local development (`.env.local`):
```bash
VITE_API_URL=http://localhost:8000
NODE_ENV=development
```

### nginx Configuration

The nginx.conf includes:

1. **Gzip Compression**: Compress static assets
2. **Security Headers**: X-Frame-Options, X-Content-Type-Options, X-XSS-Protection
3. **API Proxy**: `/api/*` → proxied to backend (for local dev)
4. **SPA Routing**: All routes → index.html (React Router)
5. **Caching**: Static assets cached with proper headers

In Kubernetes, API requests go directly through the ingress to the backend (no nginx proxy needed).

## Monitoring

### Metrics (Prometheus/Grafana)

Frontend pods expose metrics:
- Request count
- Response times
- Error rates
- Resource usage (CPU/RAM)

Access: https://grafana.villagers.live

### Logs (Kibana)

Frontend nginx access logs:
```bash
# View in Kibana
https://kibana.villagers.live

# Or kubectl
kubectl logs -f -n rescuemesh -l app=frontend
```

### Health Checks

```bash
# Liveness probe
curl http://villagers.live/

# Check pod health
kubectl get pods -n rescuemesh -l app=frontend

# Describe pod
kubectl describe pod -n rescuemesh <frontend-pod-name>
```

## Troubleshooting

### Frontend pods not starting

```bash
# Check pod status
kubectl get pods -n rescuemesh -l app=frontend

# View logs
kubectl logs -n rescuemesh -l app=frontend

# Describe deployment
kubectl describe deployment frontend -n rescuemesh

# Common issues:
# 1. Image pull error → Check registry credentials
# 2. CrashLoopBackOff → Check nginx.conf syntax
# 3. ImagePullBackOff → Build and push image first
```

### Build the image manually

```bash
cd /home/ahmf/Documents/rescuemesh/frontend

# Build locally
npm ci
npm run build

# Test nginx config
docker build -t frontend-test .
docker run -p 8080:80 frontend-test

# Access: http://localhost:8080
```

### 404 errors on routes

This happens if nginx SPA routing is not configured. Check `nginx.conf`:

```nginx
# This should be present:
location / {
    try_files $uri $uri/ /index.html;
}
```

### API calls failing

Check VITE_API_URL environment variable:

```bash
kubectl get deployment frontend -n rescuemesh -o yaml | grep VITE_API_URL

# Should show:
# - name: VITE_API_URL
#   value: https://api.villagers.live
```

### SSL certificate issues

```bash
# Check certificate
kubectl get certificate -n rescuemesh frontend-tls

# Should show: Ready=True

# If not ready, check cert-manager
kubectl describe certificate frontend-tls -n rescuemesh
kubectl get challenges -n rescuemesh
```

## Scaling

### Manual Scaling

```bash
# Scale to specific number
kubectl scale deployment frontend --replicas=5 -n rescuemesh

# Check current replicas
kubectl get deployment frontend -n rescuemesh
```

### Auto-scaling (HPA)

```bash
# Check HPA status
kubectl get hpa -n rescuemesh frontend-hpa

# View HPA details
kubectl describe hpa frontend-hpa -n rescuemesh

# HPA will automatically scale:
# - Min: 2 replicas
# - Max: 10 replicas
# - Trigger: CPU > 70% or Memory > 80%
```

## Performance Optimization

### Build Optimization

Already configured in Vite:

```javascript
// vite.config.js
build: {
  minify: 'terser',
  rollupOptions: {
    output: {
      manualChunks: {
        vendor: ['react', 'react-dom']
      }
    }
  }
}
```

### nginx Optimization

Already in nginx.conf:

- Gzip compression
- Static asset caching
- HTTP/2 support (via ingress)

### CDN (Cloudflare)

Already configured:
- Cloudflare CDN for static assets
- Edge caching
- DDoS protection
- SSL/TLS

## Deployment Checklist

Before deploying frontend:

- [ ] Build Docker image
- [ ] Push to DO Container Registry
- [ ] Apply Kubernetes manifests
- [ ] Verify ingress configuration
- [ ] Check DNS (villagers.live → Load Balancer IP)
- [ ] Wait for SSL certificate (5-10 min)
- [ ] Test frontend: https://villagers.live
- [ ] Test API calls work
- [ ] Check responsive design
- [ ] Verify all routes work

## Quick Commands

```bash
# Deploy frontend
kubectl apply -f k8s/deployments/deployment-frontend.yaml
kubectl apply -f k8s/hpa/hpa-frontend.yaml

# Check status
kubectl get pods -n rescuemesh -l app=frontend
kubectl get svc -n rescuemesh frontend
kubectl get ingress -n rescuemesh frontend-ingress

# View logs
kubectl logs -f -n rescuemesh -l app=frontend

# Restart frontend
kubectl rollout restart deployment/frontend -n rescuemesh

# Update image
kubectl set image deployment/frontend \
  frontend=registry.digitalocean.com/rescuemesh/frontend:latest \
  -n rescuemesh

# Port forward (local testing)
kubectl port-forward -n rescuemesh svc/frontend 8080:80
# Access: http://localhost:8080

# Delete frontend
kubectl delete -f k8s/deployments/deployment-frontend.yaml
```

## Summary

✅ **Frontend is now production-ready!**

**Stack**:
- React 18 + Vite
- nginx (production server)
- Kubernetes deployment
- Auto-scaling (2-10 pods)
- CI/CD automation
- SSL/TLS (Let's Encrypt)
- CDN (Cloudflare)

**URLs**:
- https://villagers.live (production)
- https://www.villagers.live (www subdomain)

**Deployment**:
```bash
# Quick deploy
./scripts/deploy.sh

# Or via GitHub Actions (automatic on push to main)
git push origin main
```

Frontend is ready to serve users! 🚀
