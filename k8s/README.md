# Kubernetes Manifests for RescueMesh on DigitalOcean

This directory contains all Kubernetes manifests for deploying RescueMesh on DigitalOcean Kubernetes cluster.

## 📋 Structure

```
k8s/
├── namespace.yaml                          # Namespace definition
├── configmaps/                            # ConfigMaps for all services
│   ├── configmap-user-service.yaml
│   ├── configmap-skill-service.yaml
│   ├── configmap-disaster-service.yaml
│   ├── configmap-sos-service.yaml
│   ├── configmap-matching-service.yaml
│   └── configmap-notification-service.yaml
├── secrets/
│   └── secrets.yaml                       # Secrets (UPDATE BEFORE DEPLOYING!)
├── infrastructure/                        # PostgreSQL, Redis, RabbitMQ
│   ├── postgres-*-statefulset.yaml
│   ├── redis-*-deployment.yaml
│   └── rabbitmq-deployment.yaml
├── services/                             # Kubernetes Services
│   └── service-*.yaml
├── deployments/                          # Application Deployments
│   └── deployment-*.yaml
├── hpa/                                  # Horizontal Pod Autoscalers
│   └── hpa-*.yaml
├── ingress/
│   └── ingress.yaml                      # Ingress configuration
├── kustomization.yaml                    # Kustomize config
└── README.md                            # This file
```

## 🚀 Quick Start

### Prerequisites

1. **DigitalOcean Kubernetes Cluster** - Create one via DO console or doctl CLI
2. **kubectl** configured to access your cluster
3. **Docker images** pushed to a registry (update image references in deployments)
4. **Domain names** configured (for ingress)

### Step 1: Update Secrets

**⚠️ CRITICAL: Update secrets before deploying!**

```bash
# Edit secrets.yaml or create secrets manually
kubectl create secret generic rescuemesh-secrets \
  --from-literal=DB_PASSWORD='your-secure-password' \
  --from-literal=RABBITMQ_PASSWORD='your-rabbitmq-password' \
  --from-literal=TWILIO_ACCOUNT_SID='your-twilio-sid' \
  --from-literal=TWILIO_AUTH_TOKEN='your-twilio-token' \
  --from-literal=TWILIO_PHONE_NUMBER='+1234567890' \
  --from-literal=FIREBASE_PROJECT_ID='your-project-id' \
  --from-literal=FIREBASE_PRIVATE_KEY='your-private-key' \
  --from-literal=FIREBASE_CLIENT_EMAIL='your-email' \
  -n rescuemesh
```

### Step 2: Update Image References

Edit all deployment files to point to your container registry:

```bash
# Find and replace in all deployment files
sed -i 's|your-registry/|registry.digitalocean.com/your-registry/|g' deployments/*.yaml
```

### Step 3: Update Ingress Hostnames

Edit `ingress/ingress.yaml` and replace:
- `api.rescuemesh.com` → your actual domain
- `docs.rescuemesh.com` → your actual domain
- `rabbitmq.rescuemesh.com` → your actual domain (optional)

### Step 4: Deploy

#### Option A: Using kubectl

```bash
# Create namespace
kubectl apply -f namespace.yaml

# Apply all resources
kubectl apply -f configmaps/
kubectl apply -f secrets/
kubectl apply -f infrastructure/
kubectl apply -f services/
kubectl apply -f deployments/
kubectl apply -f hpa/
kubectl apply -f ingress/
```

#### Option B: Using Kustomize

```bash
kubectl apply -k .
```

### Step 5: Verify Deployment

```bash
# Check all pods
kubectl get pods -n rescuemesh

# Check services
kubectl get svc -n rescuemesh

# Check ingress
kubectl get ingress -n rescuemesh

# Check HPA
kubectl get hpa -n rescuemesh

# View logs
kubectl logs -f deployment/sos-service -n rescuemesh
```

## 🔧 Configuration

### DigitalOcean Specific Settings

1. **Storage Class**: Uses `do-block-storage` for PersistentVolumes
2. **Load Balancer**: Ingress controller will create a DO Load Balancer
3. **Block Storage**: Persistent volumes use DO Block Storage

### Resource Limits

All services have resource requests and limits:
- **Requests**: CPU 250m, Memory 256Mi
- **Limits**: CPU 500m, Memory 512Mi

### Auto-Scaling (HPA)

All services have HorizontalPodAutoscalers configured:
- **Min Replicas**: 2
- **Max Replicas**: 10 (Notification: 15)
- **CPU Threshold**: 70%
- **Memory Threshold**: 80%

## 📊 Services Overview

### Your Services (4-6)
- **SOS Service**: Port 3004
- **Matching Service**: Port 3005
- **Notification Service**: Port 3006

### Friend's Services (1-3)
- **User Service**: Port 3001
- **Skill Service**: Port 3002
- **Disaster Service**: Port 3003

### Infrastructure
- **PostgreSQL**: 6 databases (one per service)
- **Redis**: 5 instances (User, Skill, SOS, Matching, Notification)
- **RabbitMQ**: 1 instance (shared message queue)

## 🌐 Ingress Routes

After deploying, access services via:

- **API**: `https://api.rescuemesh.com`
  - `/api/users` → User Service
  - `/api/skills` → Skill Service
  - `/api/resources` → Skill Service
  - `/api/disasters` → Disaster Service
  - `/api/sos` → SOS Service
  - `/api/matching` → Matching Service
  - `/api/notifications` → Notification Service

- **Swagger Docs**: `https://docs.rescuemesh.com`
  - `/user/docs` → User Service Docs
  - `/skill/docs` → Skill Service Docs
  - `/disaster/docs` → Disaster Service Docs
  - `/sos/docs` → SOS Service Docs
  - `/matching/docs` → Matching Service Docs
  - `/notification/docs` → Notification Service Docs

- **RabbitMQ Management**: `https://rabbitmq.rescuemesh.com` (if enabled)

## 🔐 Security Considerations

1. **Secrets Management**:
   - Use `kubectl create secret` or sealed-secrets
   - Never commit secrets to Git
   - Rotate secrets regularly

2. **TLS/SSL**:
   - Configure cert-manager for automatic SSL certificates
   - Update ingress annotations with your cluster-issuer

3. **Network Policies**:
   - Consider adding NetworkPolicies for pod-to-pod communication
   - Restrict ingress access as needed

4. **RBAC**:
   - Configure ServiceAccounts with minimal required permissions
   - Use Role-Based Access Control for pod permissions

## 🔄 Updates and Rollouts

### Update a Service

```bash
# Update image tag
kubectl set image deployment/sos-service \
  sos-service=your-registry/rescuemesh-sos-service:v1.1.0 \
  -n rescuemesh

# Rollout status
kubectl rollout status deployment/sos-service -n rescuemesh

# Rollback if needed
kubectl rollout undo deployment/sos-service -n rescuemesh
```

### Scale Manually

```bash
# Scale a service
kubectl scale deployment sos-service --replicas=5 -n rescuemesh
```

## 📝 Monitoring

### View Logs

```bash
# All services
kubectl logs -f deployment/sos-service -n rescuemesh
kubectl logs -f deployment/matching-service -n rescuemesh
kubectl logs -f deployment/notification-service -n rescuemesh
```

### Check Resource Usage

```bash
# Pod resources
kubectl top pods -n rescuemesh

# Node resources
kubectl top nodes
```

### Health Checks

All services expose `/health` endpoints:
```bash
curl https://api.rescuemesh.com/health
```

## 🐛 Troubleshooting

### Pods Not Starting

```bash
# Describe pod
kubectl describe pod <pod-name> -n rescuemesh

# Check events
kubectl get events -n rescuemesh --sort-by='.lastTimestamp'
```

### Database Connection Issues

```bash
# Check PostgreSQL pods
kubectl get pods -l app=postgres-sos -n rescuemesh

# Check database logs
kubectl logs <postgres-pod> -n rescuemesh
```

### Ingress Not Working

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress status
kubectl describe ingress rescuemesh-ingress -n rescuemesh
```

## 🔗 External Resources

- [DigitalOcean Kubernetes Docs](https://docs.digitalocean.com/products/kubernetes/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Kustomize Documentation](https://kustomize.io/)

## 📞 Support

For issues or questions, check:
1. Service logs
2. Kubernetes events
3. Resource utilization
4. Network connectivity

---

**Note**: Remember to update all `your-registry` references and secrets before deploying!
