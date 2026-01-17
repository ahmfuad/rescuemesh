# 🚀 Quick Start Guide - RescueMesh DevOps

## One-Command Deployment

```bash
# Deploy everything in order:
cd /home/ahmf/Documents/rescuemesh

# 1. Infrastructure (15-20 min)
./scripts/terraform-deploy.sh

# 2. Monitoring (10-15 min)
./scripts/install-advanced-monitoring.sh

# 3. Application (5-10 min)
kubectl apply -k k8s/

# 4. Verify
./scripts/verify-system.sh
```

## Essential Commands

### Deployment

```bash
# Deploy infrastructure
./scripts/terraform-deploy.sh

# Deploy applications
kubectl apply -k k8s/

# Update single service
kubectl set image deployment/user-service user-service=registry.digitalocean.com/rescuemesh/user-service:v1.2.0 -n rescuemesh

# Rollback deployment
kubectl rollout undo deployment/user-service -n rescuemesh

# Check deployment status
kubectl rollout status deployment/user-service -n rescuemesh
```

### Monitoring

```bash
# Access Grafana
https://grafana.villagers.live

# Access Kibana (logs)
https://kibana.villagers.live

# Access Jaeger (traces)
https://jaeger.villagers.live

# Access SonarQube
https://sonarqube.villagers.live

# View metrics locally
kubectl port-forward -n monitoring svc/prometheus-server 9090:80
```

### Troubleshooting

```bash
# Check pod status
kubectl get pods -n rescuemesh

# View logs
kubectl logs -f deployment/user-service -n rescuemesh

# Describe pod
kubectl describe pod <pod-name> -n rescuemesh

# Execute in container
kubectl exec -it <pod-name> -n rescuemesh -- /bin/sh

# Check events
kubectl get events -n rescuemesh --sort-by='.lastTimestamp'

# View resource usage
kubectl top pods -n rescuemesh
kubectl top nodes
```

### Database

```bash
# Connect to PostgreSQL
kubectl exec -it postgres-users-0 -n rescuemesh -- psql -U postgres -d users

# Check database status
kubectl get statefulset -n rescuemesh
kubectl get pvc -n rescuemesh

# Backup database
kubectl create job --from=cronjob/backup-databases manual-backup -n rescuemesh

# Restore database
velero restore create --from-backup <backup-name>
```

### Scaling

```bash
# Manual scaling
kubectl scale deployment user-service --replicas=5 -n rescuemesh

# Auto-scaling status
kubectl get hpa -n rescuemesh

# Cluster autoscaling (via Terraform)
terraform apply -var="worker_node_count=5"
```

### Security

```bash
# Scan for vulnerabilities
trivy image registry.digitalocean.com/rescuemesh/user-service:latest

# Check network policies
kubectl get networkpolicies -n rescuemesh

# View secrets (base64 encoded)
kubectl get secrets -n rescuemesh
kubectl get secret postgres-users -n rescuemesh -o yaml

# Check RBAC
kubectl get rolebindings -n rescuemesh
kubectl auth can-i create pods --namespace=rescuemesh
```

### Backup & Restore

```bash
# Create backup
velero backup create manual-backup

# List backups
velero backup get

# Restore from backup
velero restore create --from-backup <backup-name>

# Check backup status
velero backup describe <backup-name>
```

## Access URLs

```
Production:
  API: https://api.villagers.live
  Frontend: https://villagers.live
  Grafana: https://grafana.villagers.live
  Kibana: https://kibana.villagers.live
  Jaeger: https://jaeger.villagers.live
  SonarQube: https://sonarqube.villagers.live

Staging:
  API: https://staging-api.villagers.live
  Frontend: https://staging.villagers.live
```

## Credentials

Saved in: `.credentials/monitoring-credentials.txt`

```bash
# View all credentials
cat .credentials/monitoring-credentials.txt

# Terraform outputs
cd terraform && terraform output

# Kubernetes secrets
kubectl get secret -n monitoring elasticsearch-credentials -o jsonpath='{.data.password}' | base64 -d
```

## Common Issues

### Pod won't start
```bash
kubectl describe pod <pod-name> -n rescuemesh
kubectl logs <pod-name> -n rescuemesh
# Check: image pull, resources, config
```

### Service unreachable
```bash
kubectl get svc -n rescuemesh
kubectl get endpoints -n rescuemesh
# Check: service selector, pod labels
```

### Database connection fails
```bash
kubectl get pods -l app=postgres -n rescuemesh
kubectl logs <app-pod> -n rescuemesh | grep -i database
# Check: connection string, credentials
```

### Monitoring not showing data
```bash
# Prometheus
kubectl port-forward -n monitoring svc/prometheus-server 9090:80
# Check targets at: http://localhost:9090/targets

# Elasticsearch
kubectl exec -it -n monitoring elasticsearch-master-0 -- curl localhost:9200/_cluster/health
```

## Quick Reference

### Namespaces
- `rescuemesh` - Application services
- `monitoring` - Monitoring stack
- `ingress-nginx` - Ingress controller
- `cert-manager` - SSL certificates
- `velero` - Backup system

### Services
1. user-service (Go) - Port 8080
2. skill-service (Go) - Port 8081  
3. disaster-service (Python) - Port 8000
4. sos-service (Node.js) - Port 3001
5. matching-service (Node.js) - Port 3002
6. notification-service (Node.js) - Port 3003

### Resource Sizes
```
Production:
  Workers: 3-10 nodes (s-4vcpu-8gb)
  Databases: 2-4 nodes (s-2vcpu-4gb)
  Monitoring: 2-3 nodes (s-4vcpu-8gb)

Staging:
  Workers: 2-4 nodes (s-2vcpu-4gb)
```

### Cost Estimate
```
Production: $140-180/month (full stack with in-cluster databases)
Staging: $60/month
Total: $200-240/month
```

## Emergency Procedures

### Rollback Deployment
```bash
# Quick rollback
kubectl rollout undo deployment/<service> -n rescuemesh

# Rollback to specific revision
kubectl rollout history deployment/<service> -n rescuemesh
kubectl rollout undo deployment/<service> --to-revision=<N> -n rescuemesh
```

### Complete System Restore
```bash
# From Velero backup
velero restore create full-restore --from-backup daily-backup-<date>

# From Terraform
cd terraform
terraform apply -auto-approve

# Reapply Kubernetes
kubectl apply -k k8s/
```

### Scale Down (Cost Saving)
```bash
# Scale application to minimum
kubectl scale deployment --all --replicas=1 -n rescuemesh

# Destroy staging
cd terraform
terraform destroy -target=digitalocean_kubernetes_cluster.staging
```

## CI/CD

### Trigger Deployment
```bash
# Push to main = deploy to staging
git push origin main

# Create release = deploy to production (with approval)
git tag -a v1.0.0 -m "Release v1.0.0"
git push --tags
```

### View Pipeline
```bash
# GitHub Actions
https://github.com/<your-repo>/actions

# Check workflow status
gh workflow list
gh run list
gh run view <run-id>
```

## Health Checks

```bash
# Application health
curl https://api.villagers.live/health

# Service health
kubectl get pods -n rescuemesh
kubectl get deployments -n rescuemesh

# Infrastructure health
kubectl get nodes
kubectl top nodes

# Complete verification
./scripts/verify-system.sh
```

## Documentation

📚 **Full Guides:**
- [COMPLETE_DEVOPS_IMPLEMENTATION.md](COMPLETE_DEVOPS_IMPLEMENTATION.md) - Complete overview
- [DEVOPS_DEPLOYMENT_GUIDE.md](DEVOPS_DEPLOYMENT_GUIDE.md) - Detailed deployment guide
- [docs/TERRAFORM_INFRASTRUCTURE_GUIDE.md](docs/TERRAFORM_INFRASTRUCTURE_GUIDE.md) - Infrastructure guide
- [docs/ELK_JAEGER_SETUP_GUIDE.md](docs/ELK_JAEGER_SETUP_GUIDE.md) - Monitoring setup
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture

🔧 **Scripts:**
- `scripts/terraform-deploy.sh` - Infrastructure deployment
- `scripts/install-advanced-monitoring.sh` - Monitoring setup
- `scripts/deploy.sh` - Application deployment
- `scripts/verify-system.sh` - System verification

---

**Need Help?**
1. Check logs: `kubectl logs -f <pod> -n rescuemesh`
2. Check monitoring: Grafana/Kibana/Jaeger
3. Review documentation
4. Check GitHub issues

**Pro Tips:**
- Always run `terraform plan` before `apply`
- Use `kubectl describe` for detailed pod info
- Monitor costs in Digital Ocean dashboard
- Set up alerts in Grafana
- Regular backup testing with Velero
