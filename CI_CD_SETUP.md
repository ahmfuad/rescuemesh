# CI/CD Setup for RescueMesh - Complete Procedure

## Overview
This guide provides a complete CI/CD pipeline for all RescueMesh microservices and frontend using GitHub Actions.

## Prerequisites
1. GitHub repository with all services
2. Docker Hub account (or any container registry)
3. Kubernetes cluster with kubectl access
4. GitHub Secrets configured

## Required GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

Add the following secrets:

```
DOCKER_USERNAME=kdbazizul
DOCKER_PASSWORD=<your-docker-hub-password>
KUBE_CONFIG=<base64-encoded-kubeconfig>
```

### Get Base64 Encoded Kubeconfig
```bash
cat ~/.kube/config | base64 -w 0
```

## Architecture

```
┌─────────────────┐
│  Code Push      │
│  (main branch)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ GitHub Actions  │
│ Triggered       │
└────────┬────────┘
         │
         ├──────────────────┬──────────────────┬──────────────────┐
         ▼                  ▼                  ▼                  ▼
    ┌─────────┐        ┌─────────┐        ┌─────────┐      ┌──────────┐
    │ Build   │        │ Build   │        │ Build   │      │ Build    │
    │ Service │        │ Service │        │ Service │      │ Frontend │
    └────┬────┘        └────┬────┘        └────┬────┘      └────┬─────┘
         │                  │                  │                │
         ▼                  ▼                  ▼                ▼
    ┌─────────┐        ┌─────────┐        ┌─────────┐      ┌──────────┐
    │ Push to │        │ Push to │        │ Push to │      │ Push to  │
    │ Docker  │        │ Docker  │        │ Docker  │      │ Docker   │
    └────┬────┘        └────┬────┘        └────┬────┘      └────┬─────┘
         │                  │                  │                │
         └──────────────────┴──────────────────┴────────────────┘
                            │
                            ▼
                    ┌───────────────┐
                    │ Deploy to K8s │
                    │ (kubectl)     │
                    └───────────────┘
```

## CI/CD Pipeline Structure

### 1. Monorepo Structure (All services in one repo)
```
.github/workflows/
├── user-service.yml
├── skill-service.yml
├── disaster-service.yml
├── sos-service.yml
├── matching-service.yml
├── notification-service.yml
├── frontend.yml
└── deploy-all.yml (manual trigger to deploy all)
```

### 2. Multi-Repo Structure (Each service in separate repo)
Each repository gets its own `.github/workflows/ci-cd.yml`

## Workflow Files

See `.github/workflows/` directory for all workflow files.

## Manual Deployment Procedure

### Option 1: Deploy All Services at Once
```bash
# Trigger the deploy-all workflow from GitHub Actions UI
# Or use GitHub CLI:
gh workflow run deploy-all.yml
```

### Option 2: Deploy Individual Services
```bash
# Build and push
cd rescuemesh-user-service
docker build -t kdbazizul/rescuemesh-user-service:latest .
docker push kdbazizul/rescuemesh-user-service:latest

# Deploy to Kubernetes
kubectl rollout restart deployment/user-service -n rescuemesh
```

### Option 3: Automated on Push
```bash
# Simply push to main branch
git add .
git commit -m "Update user service"
git push origin main

# GitHub Actions will automatically:
# 1. Build the Docker image
# 2. Push to Docker Hub
# 3. Deploy to Kubernetes
```

## Rollback Procedure

### Method 1: Rollback to Previous Deployment
```bash
kubectl rollout undo deployment/user-service -n rescuemesh
```

### Method 2: Rollback to Specific Revision
```bash
# Check rollout history
kubectl rollout history deployment/user-service -n rescuemesh

# Rollback to specific revision
kubectl rollout undo deployment/user-service -n rescuemesh --to-revision=2
```

### Method 3: Deploy Specific Image Tag
```bash
kubectl set image deployment/user-service \
  user-service=kdbazizul/rescuemesh-user-service:v1.2.3 \
  -n rescuemesh
```

## Image Tagging Strategy

### Semantic Versioning (Recommended)
```
kdbazizul/rescuemesh-user-service:v1.2.3
kdbazizul/rescuemesh-user-service:latest
```

### Git Commit SHA
```
kdbazizul/rescuemesh-user-service:abc1234
kdbazizul/rescuemesh-user-service:latest
```

### Date-based
```
kdbazizul/rescuemesh-user-service:2026-01-17
kdbazizul/rescuemesh-user-service:latest
```

## Monitoring Deployment

### Watch Deployment Progress
```bash
kubectl rollout status deployment/user-service -n rescuemesh
```

### View Pod Logs
```bash
kubectl logs -f deployment/user-service -n rescuemesh
```

### Check Pod Status
```bash
kubectl get pods -n rescuemesh -l app=user-service
```

## Testing Strategy

### 1. Unit Tests (in CI)
```yaml
- name: Run Tests
  run: |
    npm test
    # or
    go test ./...
    # or
    pytest
```

### 2. Integration Tests (in CI)
```yaml
- name: Integration Tests
  run: |
    docker-compose up -d
    npm run test:integration
    docker-compose down
```

### 3. Smoke Tests (after deployment)
```bash
curl https://api.villagers.live/health
```

## Environment-Specific Deployments

### Development Environment
```bash
# Use dev namespace
kubectl apply -f k8s/ -n rescuemesh-dev
```

### Staging Environment
```bash
# Use staging namespace
kubectl apply -f k8s/ -n rescuemesh-staging
```

### Production Environment
```bash
# Use production namespace (current: rescuemesh)
kubectl apply -f k8s/ -n rescuemesh
```

## Blue-Green Deployment (Advanced)

### Create Blue Deployment (current)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service-blue
spec:
  replicas: 2
  template:
    metadata:
      labels:
        app: user-service
        version: blue
```

### Create Green Deployment (new version)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service-green
spec:
  replicas: 2
  template:
    metadata:
      labels:
        app: user-service
        version: green
```

### Switch Traffic
```bash
# Update service selector
kubectl patch service user-service -n rescuemesh -p '{"spec":{"selector":{"version":"green"}}}'
```

## Canary Deployment (Advanced)

```yaml
# 90% traffic to stable, 10% to canary
apiVersion: v1
kind: Service
metadata:
  name: user-service
spec:
  selector:
    app: user-service
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service-stable
spec:
  replicas: 9
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service-canary
spec:
  replicas: 1
```

## Automated Health Checks

All workflows include health checks after deployment:

```bash
# Wait for rollout to complete
kubectl rollout status deployment/user-service -n rescuemesh

# Check health endpoint
curl -f https://api.villagers.live/health || exit 1
```

## Slack/Discord Notifications (Optional)

Add to GitHub workflow:

```yaml
- name: Notify Deployment
  if: success()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: 'User Service deployed successfully!'
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

## Complete Setup Script

```bash
#!/bin/bash
# Run this once to set up CI/CD

# 1. Create GitHub workflows
mkdir -p .github/workflows

# 2. Copy workflow files (already created in .github/workflows/)

# 3. Set up GitHub secrets
echo "Go to GitHub repo → Settings → Secrets → Actions"
echo "Add: DOCKER_USERNAME, DOCKER_PASSWORD, KUBE_CONFIG"

# 4. Enable GitHub Actions
echo "Go to GitHub repo → Actions → Enable workflows"

# 5. Done! Push to trigger
git add .github/
git commit -m "Add CI/CD workflows"
git push origin main
```

## Troubleshooting

### Build Fails
```bash
# Check GitHub Actions logs
# Fix code/Dockerfile
# Push again
```

### Deployment Fails
```bash
# Check pod status
kubectl describe pod <pod-name> -n rescuemesh

# Check deployment events
kubectl get events -n rescuemesh --sort-by='.lastTimestamp'

# Rollback
kubectl rollout undo deployment/user-service -n rescuemesh
```

### Image Pull Errors
```bash
# Verify image exists
docker pull kdbazizul/rescuemesh-user-service:latest

# Check imagePullSecrets (if private registry)
kubectl get secrets -n rescuemesh
```

## Security Best Practices

1. **Never commit secrets** - Use GitHub Secrets
2. **Scan images** - Add Trivy/Snyk to workflows
3. **Sign images** - Use Cosign for image signing
4. **Use specific tags** - Avoid `:latest` in production
5. **Limit permissions** - Use minimal RBAC for service accounts

## Cost Optimization

1. **Cache Docker layers** - Use GitHub Actions cache
2. **Parallel builds** - Build services in parallel
3. **Conditional triggers** - Only build changed services
4. **Self-hosted runners** - For high-frequency builds

## Next Steps

1. ✅ Set up GitHub Secrets
2. ✅ Copy workflow files to `.github/workflows/`
3. ✅ Test with a single service first
4. ✅ Enable notifications
5. ✅ Add automated tests
6. ✅ Set up staging environment
7. ✅ Implement blue-green deployment
