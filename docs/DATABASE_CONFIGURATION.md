# Database Configuration - In-Cluster Setup

## Overview

RescueMesh uses **in-cluster databases** running as Kubernetes StatefulSets instead of Digital Ocean managed databases. All database components (PostgreSQL, Redis, RabbitMQ) are included in the container images and deployed within the Kubernetes cluster.

## Benefits

✅ **Cost Savings**: Saves ~$84/month compared to managed databases  
✅ **Simplified Management**: All components in one cluster  
✅ **Version Control**: Database configurations in Git  
✅ **Faster Development**: Easy local testing with same setup  
✅ **Portability**: Works on any Kubernetes cluster  

## Database Architecture

```
Kubernetes Cluster (rescuemesh namespace)
├── PostgreSQL StatefulSets (6 databases)
│   ├── postgres-users (user-service)
│   ├── postgres-skills (skill-service)
│   ├── postgres-disasters (disaster-service)
│   ├── postgres-sos (sos-service)
│   ├── postgres-matching (matching-service)
│   └── postgres-notifications (notification-service)
│
├── Redis StatefulSets (3 caches)
│   ├── redis-users (user caching)
│   ├── redis-matching (matching cache)
│   └── redis-notifications (notification cache)
│
└── RabbitMQ StatefulSet (1 messaging queue)
    └── rabbitmq (inter-service messaging)
```

## Storage

All databases use persistent volumes backed by Digital Ocean block storage:

```yaml
Storage Classes:
- do-block-storage (default, SSD)
- do-block-storage-retain (for production databases)

Persistent Volume Claims:
- PostgreSQL: 20Gi per database (120Gi total)
- Redis: 5Gi per cache (15Gi total)
- RabbitMQ: 10Gi

Total Storage: ~145Gi (~$14.5/month)
```

## High Availability

**PostgreSQL**:
- 3 replicas per StatefulSet (production)
- 1 replica for staging
- PodDisruptionBudget: maxUnavailable=1
- Anti-affinity rules (different nodes)

**Redis**:
- Master-slave replication
- Sentinel for automatic failover
- 3 replicas in production

**RabbitMQ**:
- Clustered mode (3 nodes)
- Quorum queues for durability
- Mirror across availability zones

## Backup Strategy

**Method 1: Velero (Cluster-wide)**
```bash
# Daily full cluster backup includes all databases
velero schedule get daily-backup

# Restore entire cluster
velero restore create --from-backup daily-backup-20260117
```

**Method 2: Database-specific**
```bash
# PostgreSQL backups (automated)
kubectl get cronjob -n rescuemesh backup-databases

# Manual backup
kubectl create job --from=cronjob/backup-databases manual-backup-$(date +%s)

# Backups saved to: rescuemesh-backups Space
# Retention: 30 days
```

## Connection Details

### PostgreSQL

Each service connects to its own PostgreSQL instance:

```yaml
# Example: user-service
DATABASE_URL: postgresql://postgres:${POSTGRES_PASSWORD}@postgres-users:5432/users

# Connection details:
Host: postgres-users.rescuemesh.svc.cluster.local
Port: 5432
Database: users
User: postgres
Password: <from secret>
```

### Redis

```yaml
# Example: user-service cache
REDIS_URL: redis://redis-users:6379

# Connection details:
Host: redis-users.rescuemesh.svc.cluster.local
Port: 6379
Password: <from secret>
```

### RabbitMQ

```yaml
RABBITMQ_URL: amqp://guest:${RABBITMQ_PASSWORD}@rabbitmq:5672/

# Connection details:
Host: rabbitmq.rescuemesh.svc.cluster.local
Port: 5672 (AMQP)
Management UI: 15672
```

## Migration from Managed Databases

If you previously used DO managed databases and want to migrate:

### 1. Export Data from Managed DB

```bash
# Get managed database connection details
doctl databases connection <database-id>

# Export data
pg_dump -h <host> -U <user> -d <database> > backup.sql

# Or use Digital Ocean console backup feature
```

### 2. Import to In-Cluster DB

```bash
# Port forward to in-cluster database
kubectl port-forward -n rescuemesh postgres-users-0 5432:5432

# Import data (in another terminal)
psql -h localhost -U postgres -d users < backup.sql
```

### 3. Update Service Configuration

Services should already be configured for in-cluster databases. Verify:

```bash
# Check environment variables
kubectl get deployment user-service -n rescuemesh -o yaml | grep -A 5 env:

# Should see:
# DATABASE_URL: postgresql://postgres:xxx@postgres-users:5432/users
```

### 4. Remove Managed Databases

Once migration is verified:

```bash
# Via Terraform (already commented out)
cd terraform
terraform plan  # Should show no managed DB resources

# Or manually via doctl
doctl databases list
doctl databases delete <database-id>
```

## Monitoring

### Database Metrics (Prometheus)

```bash
# View in Grafana
https://grafana.villagers.live

# Dashboards available:
- PostgreSQL Overview
- Redis Performance
- RabbitMQ Queues
```

### Database Logs (Kibana)

```bash
# View in Kibana
https://kibana.villagers.live

# Filter by:
- kubernetes.labels.app:postgres*
- kubernetes.labels.app:redis*
- kubernetes.labels.app:rabbitmq
```

## Troubleshooting

### PostgreSQL Pod Won't Start

```bash
# Check pod status
kubectl get pods -n rescuemesh -l app=postgres-users

# View logs
kubectl logs -n rescuemesh postgres-users-0

# Check PVC
kubectl get pvc -n rescuemesh -l app=postgres-users

# Common issues:
# 1. PVC not bound -> Check storage class
# 2. Permission issues -> Check security context
# 3. Out of storage -> Resize PVC
```

### Redis Connection Issues

```bash
# Test connection
kubectl exec -it -n rescuemesh redis-users-0 -- redis-cli ping
# Should return: PONG

# Check password
kubectl get secret redis-users -n rescuemesh -o jsonpath='{.data.password}' | base64 -d

# Test with password
kubectl exec -it -n rescuemesh redis-users-0 -- redis-cli -a <password> ping
```

### RabbitMQ Queue Backup

```bash
# Check queue status
kubectl exec -it -n rescuemesh rabbitmq-0 -- rabbitmqctl list_queues

# Access management UI
kubectl port-forward -n rescuemesh svc/rabbitmq 15672:15672
# Open: http://localhost:15672
# Default: guest/guest (change in production!)
```

### Database Recovery

```bash
# If database is corrupted, restore from Velero
velero restore create db-restore --from-backup daily-backup-<date>

# Or restore specific database from backup job
kubectl get job -n rescuemesh | grep backup
kubectl logs -n rescuemesh job/backup-databases-xxx

# Download backup from Space and restore manually
```

## Performance Tuning

### PostgreSQL

```yaml
# In StatefulSet configuration:
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "1000m"

# Postgres config (in ConfigMap):
shared_buffers: "256MB"
effective_cache_size: "1GB"
max_connections: 100
```

### Redis

```yaml
# In StatefulSet configuration:
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "500m"

# Redis config:
maxmemory: "768mb"
maxmemory-policy: "allkeys-lru"
```

### RabbitMQ

```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "500m"

# RabbitMQ config:
vm_memory_high_watermark: 0.6
disk_free_limit: "1GB"
```

## Security

### Secrets Management

```bash
# All database passwords stored in Kubernetes secrets
kubectl get secrets -n rescuemesh | grep postgres
kubectl get secrets -n rescuemesh | grep redis
kubectl get secrets -n rescuemesh | grep rabbitmq

# Rotate passwords
kubectl delete secret postgres-users -n rescuemesh
kubectl create secret generic postgres-users \
  --from-literal=password=$(openssl rand -base64 32) \
  -n rescuemesh

# Restart pods to pick up new password
kubectl rollout restart statefulset postgres-users -n rescuemesh
```

### Network Isolation

```yaml
# Network policies restrict access
# Only application pods can connect to databases
# No external access allowed

# Example policy:
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: postgres-users-policy
spec:
  podSelector:
    matchLabels:
      app: postgres-users
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: user-service  # Only user-service can connect
```

## Cost Comparison

### In-Cluster Databases (Current)
```
Infrastructure:
- Block storage (145Gi): ~$14.50/month
- No managed database fees
- Included in cluster node costs

Total Additional Cost: ~$15/month
```

### Digital Ocean Managed Databases (Alternative)
```
- 6x PostgreSQL (db-s-2vcpu-4gb @ $10): $60/month
- 3x Redis (db-s-1vcpu-2gb @ $8): $24/month

Total: $84/month
```

**Savings: $69/month** ✅

## Deployment

Databases are deployed automatically with the application:

```bash
# Deploy all infrastructure including databases
kubectl apply -k k8s/

# Or specifically:
kubectl apply -f k8s/infrastructure/

# Verify:
kubectl get statefulsets -n rescuemesh
kubectl get pvc -n rescuemesh
kubectl get pods -n rescuemesh -l tier=database
```

## Maintenance

### Regular Tasks

**Daily** (automated):
- Backups via Velero
- Database backup jobs

**Weekly**:
- Review disk usage
- Check slow queries
- Verify replication status

**Monthly**:
- Test backup restoration
- Review and optimize queries
- Update database versions if needed

### Scaling

```bash
# Scale PostgreSQL replicas
kubectl scale statefulset postgres-users --replicas=3 -n rescuemesh

# Expand storage (PVC resize)
kubectl patch pvc postgres-users-data-postgres-users-0 \
  -n rescuemesh \
  -p '{"spec":{"resources":{"requests":{"storage":"30Gi"}}}}'
```

---

**Summary**: Using in-cluster databases saves money, simplifies management, and provides the same reliability as managed databases when properly configured with backups and monitoring.
