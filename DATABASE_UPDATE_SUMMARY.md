# Configuration Update: In-Cluster Databases

## Changes Made

Updated the entire DevOps stack to use **in-cluster databases** instead of Digital Ocean managed databases, as PostgreSQL, Redis, and RabbitMQ are included in your container images.

## Files Updated

### 1. Terraform Configuration
- **terraform/databases.tf**: Commented out all managed database resources
  - Added clear note explaining in-cluster approach
  - Resources can be uncommented if needed later

### 2. Documentation Updates
- **COMPLETE_DEVOPS_IMPLEMENTATION.md**: Updated cost breakdowns and architecture diagrams
- **docs/TERRAFORM_INFRASTRUCTURE_GUIDE.md**: Changed managed DB section to in-cluster DB section
- **QUICKSTART_DEVOPS.md**: Updated cost estimates
- **README_DEVOPS_SECTION.md**: Updated infrastructure lists and costs
- **DEVOPS_FILES_SUMMARY.md**: Updated component descriptions

### 3. New Documentation
- **docs/DATABASE_CONFIGURATION.md**: Complete guide for in-cluster database management
  - Architecture overview
  - Connection details
  - Backup & recovery procedures
  - Migration guide (if coming from managed DBs)
  - Troubleshooting
  - Performance tuning
  - Security best practices

## Cost Impact

### Before (with managed databases):
```
Production: $313-407/month
- Managed PostgreSQL (6 clusters): $60/month
- Managed Redis (3 clusters): $24/month
```

### After (in-cluster databases):
```
Production: $313-323/month
- Block storage for PVCs: ~$15/month
- Savings: ~$69/month
```

## Architecture

```
Before:
├── Kubernetes Cluster
└── Digital Ocean Managed Databases (external)
    ├── 6x PostgreSQL clusters
    └── 3x Redis clusters

After:
└── Kubernetes Cluster
    ├── Application Pods
    └── Database StatefulSets (in-cluster)
        ├── 6x PostgreSQL StatefulSets
        ├── 3x Redis StatefulSets
        └── 1x RabbitMQ StatefulSet
```

## Benefits

✅ **Cost Savings**: $69/month saved  
✅ **Simplified Management**: Everything in one cluster  
✅ **Version Control**: Database configs in Git  
✅ **Portability**: Works on any Kubernetes cluster  
✅ **Faster Development**: Same setup locally and in production  

## Deployment

No changes needed to your deployment workflow:

```bash
# Still the same commands:
./scripts/terraform-deploy.sh      # Provisions infrastructure
./scripts/install-advanced-monitoring.sh  # Sets up monitoring
kubectl apply -k k8s/             # Deploys app + databases
```

The databases are deployed as StatefulSets with persistent volumes, automatically created by the Kubernetes manifests in `k8s/infrastructure/`.

## Database Locations

All databases now run in the `rescuemesh` namespace:

```bash
# PostgreSQL instances
kubectl get statefulsets -n rescuemesh | grep postgres
# postgres-users, postgres-skills, postgres-disasters, 
# postgres-sos, postgres-matching, postgres-notifications

# Redis instances  
kubectl get statefulsets -n rescuemesh | grep redis
# redis-users, redis-matching, redis-notifications

# RabbitMQ
kubectl get statefulsets -n rescuemesh | grep rabbitmq
# rabbitmq
```

## Backup Strategy

**Velero** backs up the entire cluster including databases:
- Daily full cluster backups
- 6-hourly database-specific backups
- 30-day retention in Digital Ocean Spaces

```bash
# Verify backups
velero backup get
velero schedule get

# Restore if needed
velero restore create --from-backup daily-backup-<date>
```

## Connection Details

Services connect to databases via Kubernetes service names:

```yaml
# PostgreSQL
DATABASE_URL: postgresql://postgres:${POSTGRES_PASSWORD}@postgres-users:5432/users

# Redis
REDIS_URL: redis://redis-users:6379

# RabbitMQ
RABBITMQ_URL: amqp://guest:${RABBITMQ_PASSWORD}@rabbitmq:5672/
```

## Monitoring

All databases are monitored:
- **Metrics**: Prometheus + Grafana dashboards
- **Logs**: ELK Stack (Kibana)
- **Health Checks**: Kubernetes liveness/readiness probes

Access at:
- Grafana: https://grafana.villagers.live (database dashboards)
- Kibana: https://kibana.villagers.live (database logs)

## High Availability

Production configuration (already in k8s/infrastructure/):
- **PostgreSQL**: 3 replicas with anti-affinity
- **Redis**: Master-slave with Sentinel
- **RabbitMQ**: 3-node cluster with quorum queues
- **Storage**: Persistent volumes with retain policy
- **Backups**: Automated daily backups

## Next Steps

Your deployment is ready to go with in-cluster databases:

1. ✅ Terraform configured (managed DBs disabled)
2. ✅ Documentation updated
3. ✅ Cost estimates corrected
4. ✅ Database guide created

Simply proceed with deployment:

```bash
cd /home/ahmf/Documents/rescuemesh
./scripts/terraform-deploy.sh
```

The in-cluster databases will be automatically deployed as StatefulSets when you run `kubectl apply -k k8s/`.

## Support

For database management, see:
- **[docs/DATABASE_CONFIGURATION.md](docs/DATABASE_CONFIGURATION.md)** - Complete database guide
- **k8s/infrastructure/** - StatefulSet configurations
- **Monitoring dashboards** - Real-time database metrics

---

**Status**: ✅ Configuration updated for in-cluster databases  
**Savings**: $69/month  
**Ready**: Yes, proceed with deployment
