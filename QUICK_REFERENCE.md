# RescueMesh DevOps Quick Reference

## 🚀 Quick Start Commands

### Initial Setup
```bash
# 1. Connect to DO cluster
doctl kubernetes cluster kubeconfig save rescuemesh-cluster

# 2. Deploy everything
./scripts/deploy.sh

# 3. Setup monitoring
./scripts/setup-monitoring.sh

# 4. Setup backups
./scripts/setup-backup.sh
```

### Build & Deploy Services
```bash
# Build all images
for service in user skill disaster sos matching notification; do
  cd rescuemesh-${service}-service
  docker build -t registry.digitalocean.com/rescuemesh/${service}-service:latest .
  docker push registry.digitalocean.com/rescuemesh/${service}-service:latest
  cd ..
done

# Deploy via kustomize
kubectl apply -k k8s/

# Or deploy individually
kubectl apply -f k8s/deployments/
```

### Common Operations

#### Check Status
```bash
# Quick health check
./scripts/health-check.sh

# Check pods
kubectl get pods -n rescuemesh

# Check services
kubectl get svc -n rescuemesh

# Check ingress
kubectl get ingress -n rescuemesh

# Check certificates
kubectl get certificate -n rescuemesh
```

#### View Logs
```bash
# Service logs
kubectl logs -f deployment/user-service -n rescuemesh

# All pods for a service
kubectl logs -f -l app=user-service -n rescuemesh

# Previous pod logs
kubectl logs --previous deployment/user-service -n rescuemesh

# Tail logs
stern user-service -n rescuemesh  # requires stern
```

#### Scale Services
```bash
# Manual scale
kubectl scale deployment user-service --replicas=5 -n rescuemesh

# Check HPA
kubectl get hpa -n rescuemesh

# Edit HPA
kubectl edit hpa user-service-hpa -n rescuemesh
```

#### Update Deployments
```bash
# Update image
kubectl set image deployment/user-service \
  user-service=registry.digitalocean.com/rescuemesh/user-service:v2.0 \
  -n rescuemesh

# Check rollout status
kubectl rollout status deployment/user-service -n rescuemesh

# Rollback
kubectl rollout undo deployment/user-service -n rescuemesh

# Rollback to specific revision
kubectl rollout undo deployment/user-service --to-revision=2 -n rescuemesh
```

#### Database Operations
```bash
# Connect to PostgreSQL
kubectl exec -it <postgres-pod> -n rescuemesh -- psql -U postgres -d rescuemesh_users

# Backup database
kubectl exec <postgres-pod> -n rescuemesh -- \
  pg_dump -U postgres rescuemesh_users > backup.sql

# Restore database
cat backup.sql | kubectl exec -i <postgres-pod> -n rescuemesh -- \
  psql -U postgres rescuemesh_users
```

#### Redis Operations
```bash
# Connect to Redis
kubectl exec -it <redis-pod> -n rescuemesh -- redis-cli

# Check keys
kubectl exec <redis-pod> -n rescuemesh -- redis-cli KEYS '*'

# Flush cache (careful!)
kubectl exec <redis-pod> -n rescuemesh -- redis-cli FLUSHALL
```

### Monitoring

#### Prometheus/Grafana
```bash
# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Open: http://localhost:3000

# Get admin password
kubectl get secret -n monitoring prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode

# Access Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Open: http://localhost:9090
```

#### Logs (Loki)
```bash
# Query logs via logcli
logcli query '{namespace="rescuemesh", app="user-service"}'

# Tail logs
logcli query --follow '{namespace="rescuemesh"}'
```

### Backup & Restore

#### Velero
```bash
# List backups
velero backup get

# Create manual backup
velero backup create rescuemesh-manual --include-namespaces rescuemesh

# Check backup status
velero backup describe rescuemesh-manual

# Restore from backup
velero restore create --from-backup rescuemesh-daily-20260117

# Check restore status
velero restore describe <restore-name>
```

### Debugging

#### Pod Issues
```bash
# Describe pod
kubectl describe pod <pod-name> -n rescuemesh

# Get pod events
kubectl get events -n rescuemesh --field-selector involvedObject.name=<pod-name>

# Check resource usage
kubectl top pod <pod-name> -n rescuemesh

# Execute into pod
kubectl exec -it <pod-name> -n rescuemesh -- /bin/sh

# Debug with temporary pod
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
```

#### Network Issues
```bash
# Test service connectivity
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://user-service.rescuemesh.svc.cluster.local:3001/health

# Check DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  nslookup user-service.rescuemesh.svc.cluster.local

# Check network policies
kubectl get networkpolicy -n rescuemesh
kubectl describe networkpolicy <policy-name> -n rescuemesh
```

#### Certificate Issues
```bash
# Check certificate
kubectl describe certificate rescuemesh-tls -n rescuemesh

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager -f

# Check challenges
kubectl get challenges -n rescuemesh
kubectl describe challenge <challenge-name> -n rescuemesh

# Check orders
kubectl get orders -n rescuemesh
```

### Security

#### Secrets
```bash
# View secret
kubectl get secret rescuemesh-secrets -n rescuemesh -o yaml

# Edit secret
kubectl edit secret rescuemesh-secrets -n rescuemesh

# Create secret from file
kubectl create secret generic my-secret \
  --from-file=./credentials.json \
  -n rescuemesh
```

#### RBAC
```bash
# Check permissions
kubectl auth can-i create deployments -n rescuemesh

# View service account
kubectl get serviceaccount -n rescuemesh

# View roles
kubectl get role,rolebinding -n rescuemesh
```

### Performance Tuning

#### Resource Usage
```bash
# Node resources
kubectl top nodes

# Pod resources
kubectl top pods -n rescuemesh

# Check resource quotas
kubectl describe resourcequota -n rescuemesh

# Check limit ranges
kubectl describe limitrange -n rescuemesh
```

### Cloudflare

#### Update DNS
```bash
# Get Load Balancer IP
kubectl get svc -n ingress-nginx ingress-nginx-controller \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Update A record in Cloudflare dashboard to point to this IP
```

#### Purge Cache
```bash
# Via Cloudflare Dashboard:
# Caching → Configuration → Purge Everything

# Or use CF API
curl -X POST "https://api.cloudflare.com/client/v4/zones/<zone-id>/purge_cache" \
  -H "Authorization: Bearer <api-token>" \
  -H "Content-Type: application/json" \
  --data '{"purge_everything":true}'
```

## 📊 Monitoring URLs (after setup)

- **Application**: https://villagers.live
- **Grafana**: https://grafana.villagers.live (or port-forward)
- **Prometheus**: http://localhost:9090 (port-forward)

## 🔥 Emergency Procedures

### Service Down
```bash
# 1. Check pod status
kubectl get pods -n rescuemesh

# 2. Restart deployment
kubectl rollout restart deployment/<service-name> -n rescuemesh

# 3. Check logs
kubectl logs -f deployment/<service-name> -n rescuemesh
```

### Database Issues
```bash
# 1. Check database pod
kubectl get pod -l app=postgres-<db-name> -n rescuemesh

# 2. Check logs
kubectl logs <postgres-pod> -n rescuemesh

# 3. Restart if needed
kubectl delete pod <postgres-pod> -n rescuemesh
```

### Complete System Failure
```bash
# Restore from latest backup
velero restore create emergency-restore \
  --from-backup $(velero backup get | grep Completed | head -n1 | awk '{print $1}')
```

### SSL Certificate Issues
```bash
# Delete and recreate certificate
kubectl delete certificate rescuemesh-tls -n rescuemesh
kubectl apply -f k8s/ingress/ingress.yaml
```

## 📞 Support Contacts

- **Digital Ocean Support**: https://cloud.digitalocean.com/support
- **Cloudflare Support**: https://dash.cloudflare.com/
- **GitHub Issues**: https://github.com/yourusername/rescuemesh/issues

## 🔗 Useful Links

- DO Dashboard: https://cloud.digitalocean.com/
- Cloudflare Dashboard: https://dash.cloudflare.com/
- GitHub Actions: https://github.com/yourusername/rescuemesh/actions
- K8s Dashboard: Deploy with `kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml`
