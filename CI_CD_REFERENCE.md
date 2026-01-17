# Quick CI/CD Reference

## Quick Commands

### View Workflow Runs
```bash
# Using GitHub CLI
gh run list
gh run watch
gh run view <run-id>
```

### Trigger Workflows Manually
```bash
# Deploy all services
gh workflow run deploy-all.yml

# Deploy specific service
gh workflow run user-service.yml
gh workflow run frontend.yml
```

### Monitor Deployments
```bash
# Watch all pods
kubectl get pods -n rescuemesh -w

# Watch specific deployment
kubectl rollout status deployment/user-service -n rescuemesh

# View logs
kubectl logs -f deployment/user-service -n rescuemesh
```

### Rollback Deployments
```bash
# Rollback to previous version
kubectl rollout undo deployment/user-service -n rescuemesh

# Rollback to specific revision
kubectl rollout history deployment/user-service -n rescuemesh
kubectl rollout undo deployment/user-service -n rescuemesh --to-revision=3
```

### Check Image Tags
```bash
# List all tags for a service
curl -s https://hub.docker.com/v2/repositories/kdbazizul/rescuemesh-user-service/tags | jq '.results[].name'
```

### Force Rebuild All Images
```bash
cd /home/ahmf/Documents/rescuemesh
./deploy/build-and-push-images.sh
```

## Workflow Triggers

### Automatic Triggers
- **Push to main** → Build + Deploy
- **Push to develop** → Build only (no deploy)
- **Pull Request** → Build + Test

### Manual Triggers
- GitHub UI → Actions → Select workflow → Run workflow
- `gh workflow run <workflow-name.yml>`

## Environment Variables

Update in workflow files if needed:
- `NAMESPACE`: rescuemesh (default)
- `DOCKER_IMAGE`: kdbazizul/rescuemesh-*
- `SERVICE_NAME`: Name of the service

## Common Issues

### Build fails
```bash
# Check workflow logs in GitHub Actions
# Fix the code/Dockerfile
# Push again - workflow will re-run
```

### Deployment fails
```bash
# Check pod status
kubectl describe pod <pod-name> -n rescuemesh

# Check events
kubectl get events -n rescuemesh --sort-by='.lastTimestamp' | tail -20

# Rollback
kubectl rollout undo deployment/<service-name> -n rescuemesh
```

### Image pull errors
```bash
# Verify image exists
docker pull kdbazizul/rescuemesh-user-service:latest

# Check if deployment has correct image
kubectl get deployment user-service -n rescuemesh -o yaml | grep image:
```

## Testing Workflows Locally

### Using act (GitHub Actions locally)
```bash
# Install act
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Run workflow locally
act -j build-and-deploy -W .github/workflows/user-service.yml
```

## Health Check After Deployment
```bash
curl -sk https://api.villagers.live/health | jq .
```

Expected response:
```json
{
  "status": "healthy",
  "services": [...],
  "summary": {
    "healthy": 11,
    "total": 11,
    "percentage": 100
  }
}
```

## Secrets Management

### Rotate Docker Hub Password
```bash
# Update in GitHub: Settings → Secrets → Actions → DOCKER_PASSWORD
# Re-run failed jobs if any
```

### Update Kubeconfig
```bash
# Generate new base64 encoded config
cat ~/.kube/config | base64 -w 0

# Update in GitHub: Settings → Secrets → Actions → KUBE_CONFIG
```

## Useful GitHub Actions Commands

```bash
# Install GitHub CLI
sudo apt install gh

# Login
gh auth login

# List workflows
gh workflow list

# Run workflow
gh workflow run deploy-all.yml

# View recent runs
gh run list --limit 10

# View specific run
gh run view <run-id> --log

# Re-run failed jobs
gh run rerun <run-id>
```
