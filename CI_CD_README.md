# RescueMesh CI/CD Pipeline

## 🚀 Overview

Automated CI/CD pipeline using GitHub Actions that:
- ✅ Detects changed services (including git submodules)
- ✅ Builds only changed Docker images
- ✅ Deploys automatically to production
- ✅ Sends email notifications
- ✅ Supports rollback

---

## 📋 Workflows

### 1. CI Test (`1-ci-test.yml`)
**Trigger:** Pull Request to main

**What it does:**
- Detects which services changed
- Validates Docker builds (doesn't push)
- Comments on PR with results

### 2. Build and Deploy (`2-build-and-deploy.yml`)
**Trigger:** Push to main (auto) or Manual

**What it does:**
1. Detects changed services/submodules
2. Builds and pushes Docker images to DockerHub
3. Tags images: `prod-{SHA}`, `prod-latest`, `latest`
4. Deploys to Kubernetes cluster
5. Verifies deployment


### 3. Rollback (`3-rollback.yml`)
**Trigger:** Manual

**What it does:**
- Rolls back specific service to previous version
- Verifies rollback

---

## 🎯 How It Works

### Change Detection

The pipeline automatically detects changes in:

| Changed Path | Action |
|--------------|--------|
| `rescuemesh-user-service/` | Build & deploy user-service |
| `rescuemesh-skill-service/` | Build & deploy skill-service |
| `rescuemesh-disaster-service/` | Build & deploy disaster-service |
| `rescuemesh-sos-service/` | Build & deploy sos-service |
| `rescuemesh-matching-service/` | Build & deploy matching-service |
| `rescuemesh-notification-service/` | Build & deploy notification-service |
| `frontend/` | Build & deploy frontend |
| `k8s/` | Deploy all services |

### Git Submodules

The pipeline handles submodule changes automatically:
```bash
# When a submodule updates
git submodule update --remote rescuemesh-user-service

# The pipeline detects and deploys only user-service
```

---

## 📦 Image Tagging Strategy

Each build creates 3 tags:

```
kdbazizul/rescuemesh-user-service:prod-abc1234  # Git SHA (rollback reference)
kdbazizul/rescuemesh-user-service:prod-latest   # Latest production
kdbazizul/rescuemesh-user-service:latest        # DockerHub default
```

---

## 🔧 Setup Instructions

### 1. Get Kube Config

```bash
doctl kubernetes cluster kubeconfig show rescuemesh-cluster | base64 -w 0
```

Copy the output.

### 2. Add GitHub Secrets

Go to: `Settings → Secrets and variables → Actions`

Add these secrets:

| Secret Name | Value |
|-------------|-------|
| `DOCKERHUB_USERNAME` | `kdbazizul` |
| `DOCKERHUB_TOKEN` | Your DockerHub token |
| `DIGITALOCEAN_TOKEN` | Your DO token |

### 3. Enable GitHub Actions

1. Go to `Actions` tab
2. Enable workflows if prompted

### 4. Test the Pipeline

Create a test PR:
```bash
# Make a small change
echo "# Test" >> rescuemesh-user-service/README.md

git add .
git commit -m "test: CI/CD pipeline"
git push
```

---

## 🔄 Usage

### Normal Development Flow

```bash
# 1. Create feature branch
git checkout -b feature/new-feature

# 2. Make changes in a service (or update submodule)
cd rescuemesh-user-service
# make changes
cd ..

# 3. Commit and push
git add .
git commit -m "feat: add new feature"
git push origin feature/new-feature

# 4. Create Pull Request
# → CI tests run automatically

# 5. Merge PR
# → Builds and deploys automatically to production
```

### Rollback a Service

1. Go to `Actions` tab
2. Select "Rollback Deployment"
3. Click "Run workflow"
4. Select:
   - Service to rollback
   - Version/tag (e.g., `prod-abc1234`)
5. Click "Run workflow"

### Manual Deployment

1. Go to `Actions` tab
2. Select "CD - Build and Deploy to Production"
3. Click "Run workflow"
4. Select branch (usually `main`)
5. Click "Run workflow"

---

## 🔍 Monitoring

### View Deployment Status

```bash
# Check running pods
kubectl get pods -n rescuemesh

# Check deployment status
kubectl get deployments -n rescuemesh

# View logs
kubectl logs -f deployment/user-service -n rescuemesh

# Check rollout history
kubectl rollout history deployment/user-service -n rescuemesh
```

### GitHub Actions Dashboard

- Go to `Actions` tab to see all runs
- Click on a run to see detailed logs
- Green ✅ = Success
- Red ❌ = Failed

---

## 🐛 Troubleshooting

### Pipeline fails at "Detect changes"

```bash
# Ensure scripts are executable
chmod +x .github/scripts/*.sh
git add .github/scripts/
git commit -m "fix: make scripts executable"
git push
```

### Docker build fails

```bash
# Test build locally
cd rescuemesh-user-service
docker build -t test .
```

### Deployment fails

```bash
# Check if cluster is accessible
doctl k8s cluster list

# Reconnect to cluster
doctl k8s cluster kubeconfig save rescuemesh-cluster

# Check deployment
kubectl get deployments -n rescuemesh
kubectl describe deployment user-service -n rescuemesh
```



---

## 📝 Best Practices

### Commit Messages

Use conventional commits:
```
feat: add new feature
fix: resolve bug
docs: update documentation
chore: update dependencies
```

### Service Updates

```bash
# Update a submodule
cd rescuemesh-user-service
git pull origin main
cd ..
git add rescuemesh-user-service
git commit -m "chore: update user-service"
git push
```

### Review Before Merge

- Always create PR
- Review CI test results
- Ensure builds pass
- Then merge to trigger deployment

---

## 🔐 Security

### Rotate Tokens Regularly

The tokens in `GITHUB_SECRETS_SETUP.md` are now exposed. Rotate them:

**DockerHub:**
```
1. https://hub.docker.com/settings/security
2. Revoke old token
3. Create new token
4. Update GitHub secret
```

**DigitalOcean:**
```
1. https://cloud.digitalocean.com/account/api/tokens
2. Revoke old token
3. Create new token  
4. Update GitHub secret
```

---

## 📊 Workflow Files

| File | Purpose |
|------|---------|
| `.github/workflows/1-ci-test.yml` | PR validation |
| `.github/workflows/2-build-and-deploy.yml` | Build & deploy |
| `.github/workflows/3-rollback.yml` | Emergency rollback |
| `.github/scripts/detect-changes.sh` | Change detection logic |
| `.github/scripts/deploy-to-k8s.sh` | K8s deployment logic |

---

## 🎓 Additional Resources

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Docker Build Docs](https://docs.docker.com/engine/reference/commandline/build/)
- [Kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)
- [DigitalOcean K8s Docs](https://docs.digitalocean.com/products/kubernetes/)

---

## 💡 Tips

- Monitor first few deployments closely
- Test rollback procedure in advance
- Keep deployment history for reference
- Document any custom changes
- Update this README as pipeline evolves
