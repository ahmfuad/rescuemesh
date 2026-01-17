# Terraform Infrastructure Guide

Complete guide for deploying RescueMesh infrastructure on Digital Ocean using Terraform.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Infrastructure Components](#infrastructure-components)
- [Deployment Steps](#deployment-steps)
- [Environment Management](#environment-management)
- [State Management](#state-management)
- [Disaster Recovery](#disaster-recovery)
- [Cost Management](#cost-management)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

The Terraform infrastructure provides:
- **Complete Infrastructure as Code**: All Digital Ocean and Cloudflare resources
- **Multi-Environment Support**: Separate staging and production configurations
- **Reproducibility**: Destroy and recreate entire infrastructure from code
- **Version Control**: Track infrastructure changes in Git
- **Automation**: One-command deployments with the deployment script

### Infrastructure Architecture

```
Digital Ocean Cloud
├── Production Cluster (DOKS)
│   ├── Worker Node Pool (3-10 nodes)
│   ├── Database Node Pool (2-4 nodes)
│   └── Monitoring Node Pool (2-3 nodes)
├── Staging Cluster (DOKS)
│   └── Worker Node Pool (2-4 nodes)
├── Managed Databases
│   ├── 6x PostgreSQL Clusters
│   └── 3x Redis Clusters
├── Container Registry
├── Spaces (Object Storage)
│   ├── Backups Space
│   ├── Assets Space
│   └── Terraform State Space
└── Load Balancers + Firewalls

Cloudflare
├── DNS Records (A, CNAME)
├── SSL/TLS (Full Strict)
├── WAF Rules
└── Rate Limiting
```

## 🔧 Prerequisites

### Required Tools

```bash
# Terraform
terraform --version  # >= 1.6.0

# kubectl
kubectl version --client

# doctl (Digital Ocean CLI)
doctl version

# git
git --version
```

### Installation

```bash
# Terraform
wget https://releases.hashicorp.com/terraform/1.6.4/terraform_1.6.4_linux_amd64.zip
unzip terraform_1.6.4_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# doctl
cd ~
wget https://github.com/digitalocean/doctl/releases/download/v1.101.0/doctl-1.101.0-linux-amd64.tar.gz
tar xf doctl-1.101.0-linux-amd64.tar.gz
sudo mv doctl /usr/local/bin/
doctl auth init

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### Required Credentials

1. **Digital Ocean API Token**
   - Create at: https://cloud.digitalocean.com/account/api/tokens
   - Permissions: Read and Write
   - Save securely

2. **Cloudflare API Token**
   - Create at: https://dash.cloudflare.com/profile/api-tokens
   - Permissions: Zone:Edit, DNS:Edit
   - Template: "Edit zone DNS"

3. **Spaces Access Keys**
   - Create at: https://cloud.digitalocean.com/account/api/spaces
   - Generate new key pair
   - Save access key and secret key

### Required Accounts

- Digital Ocean account with payment method
- Cloudflare account with domain configured
- GitHub repository for state storage (optional)

## 🚀 Quick Start

### 1. Clone and Setup

```bash
cd /home/ahmf/Documents/rescuemesh
cd terraform

# Copy example variables
cp terraform.tfvars.example terraform.tfvars
```

### 2. Configure Variables

Edit `terraform.tfvars`:

```hcl
# Digital Ocean
do_token = "dop_v1_xxxxxxxxxxxxx"
do_region = "nyc3"

# Cloudflare
cloudflare_api_token = "your-cloudflare-token"
cloudflare_zone_id   = "your-zone-id"
domain_name          = "villagers.live"

# Spaces (for Terraform state)
spaces_access_id  = "your-spaces-access-key"
spaces_secret_key = "your-spaces-secret-key"

# Cluster Configuration
cluster_name = "rescuemesh-prod"
k8s_version  = "1.28.2-do.0"

# Node Pool Sizes
worker_node_count     = 3
database_node_count   = 2
monitoring_node_count = 2

# Enable managed databases
enable_managed_databases = true
```

### 3. Deploy Using Automation Script

```bash
cd /home/ahmf/Documents/rescuemesh
./scripts/terraform-deploy.sh
```

The script will:
1. Prompt for environment selection (production/staging)
2. Request credentials interactively
3. Generate secure random secrets
4. Initialize Terraform
5. Show execution plan
6. Prompt for confirmation
7. Apply infrastructure
8. Configure kubectl
9. Save outputs

### 4. Manual Deployment (Alternative)

```bash
cd terraform

# Initialize
terraform init

# Plan
terraform plan -out=plan.tfplan

# Apply
terraform apply plan.tfplan

# Configure kubectl
doctl kubernetes cluster kubeconfig save $(terraform output -raw cluster_id)
```

## 🏗️ Infrastructure Components

### Kubernetes Clusters

**Production Cluster**
```hcl
resource "digitalocean_kubernetes_cluster" "production"
  - Region: nyc3 (configurable)
  - Version: 1.28.2-do.0
  - Node Pools:
    * Workers: 3-10 nodes (s-4vcpu-8gb)
    * Databases: 2-4 nodes (s-2vcpu-4gb)
    * Monitoring: 2-3 nodes (s-4vcpu-8gb)
  - Auto-upgrade: enabled
  - High Availability: enabled
```

**Staging Cluster**
```hcl
resource "digitalocean_kubernetes_cluster" "staging"
  - Region: nyc3
  - Version: 1.28.2-do.0
  - Node Pools:
    * Workers: 2-4 nodes (s-2vcpu-4gb)
  - Auto-upgrade: enabled
```

### In-Cluster Databases

**PostgreSQL StatefulSets (6 instances)**
- users-db: Running in Kubernetes
- skills-db: Running in Kubernetes
- disasters-db: Running in Kubernetes
- sos-db: Running in Kubernetes
- matching-db: Running in Kubernetes
- notifications-db: Running in Kubernetes

**Redis StatefulSets (3 instances)**
- users-cache: Running in Kubernetes
- matching-cache: Running in Kubernetes
- notifications-cache: Running in Kubernetes

**RabbitMQ StatefulSet**
- messaging-queue: Running in Kubernetes

**Configuration**
- Deployed as StatefulSets with persistent volumes
- Persistent storage using Digital Ocean block storage
- Included in container images
- Backed up via Velero (cluster backups)
- No additional managed database costs

### Storage

**Container Registry**
- Subscription: Professional ($20/month)
- Storage: Unlimited private repositories
- Traffic: 5TB monthly bandwidth

**Spaces Buckets**
1. **rescuemesh-backups**
   - Purpose: Velero backups, database dumps
   - Lifecycle: Delete after 30 days
   - CDN: Disabled
   - CORS: Enabled

2. **rescuemesh-assets**
   - Purpose: User uploads, static assets
   - CDN: Enabled
   - CORS: Enabled
   - Public read access

3. **rescuemesh-terraform-state**
   - Purpose: Terraform state files
   - Versioning: Enabled
   - Encryption: Enabled
   - Private access only

### Networking

**Load Balancer**
- Algorithm: Round robin
- Health checks: Enabled
- Sticky sessions: Enabled
- Protocol: HTTPS with HTTP redirect

**Firewalls**
```hcl
Inbound Rules:
- HTTPS (443): 0.0.0.0/0
- HTTP (80): 0.0.0.0/0 (redirect to HTTPS)
- SSH (22): Your IP only

Outbound Rules:
- All traffic: Allowed
```

**VPC**
- Private networking for clusters and databases
- IP range: 10.0.0.0/16
- Isolated from public internet

### Cloudflare Integration

**DNS Records**
- api.villagers.live → Load Balancer
- grafana.villagers.live → Prometheus
- kibana.villagers.live → ELK Stack
- jaeger.villagers.live → Jaeger
- sonarqube.villagers.live → SonarQube

**Security**
- SSL/TLS: Full (Strict)
- WAF: Enabled with OWASP rules
- DDoS Protection: Automatic
- Rate Limiting: 100 req/min per IP

## 📦 Deployment Steps

### Initial Deployment

```bash
# 1. Clone repository
git clone <your-repo>
cd rescuemesh/terraform

# 2. Configure variables
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # Edit with your values

# 3. Initialize Terraform
terraform init

# 4. Validate configuration
terraform validate

# 5. Plan deployment
terraform plan -out=plan.tfplan

# Review the plan carefully!
# Expected resources: ~50 resources

# 6. Apply
terraform apply plan.tfplan

# This takes 15-20 minutes

# 7. Configure kubectl
export CLUSTER_ID=$(terraform output -raw cluster_id)
doctl kubernetes cluster kubeconfig save $CLUSTER_ID

# 8. Verify cluster
kubectl get nodes
kubectl get namespaces

# 9. Save outputs
terraform output > ../outputs/terraform-outputs.txt
```

### Deploy Application

After infrastructure is ready:

```bash
cd /home/ahmf/Documents/rescuemesh

# 1. Deploy monitoring stack
./scripts/install-advanced-monitoring.sh

# 2. Deploy application services
kubectl apply -k k8s/

# 3. Verify deployments
kubectl get deployments -n rescuemesh
kubectl get pods -n rescuemesh

# 4. Check ingress
kubectl get ingress -n rescuemesh
```

## 🔄 Environment Management

### Staging Environment

```bash
# Deploy staging
terraform workspace new staging
terraform apply -var-file=staging.tfvars

# Or use the script
./scripts/terraform-deploy.sh
# Select: staging
```

**Staging Configuration** (`staging.tfvars`):
- Smaller node pools (2-4 nodes)
- Smaller instance sizes
- Managed databases disabled (uses in-cluster PostgreSQL)
- Reduced costs (~$60/month)

### Production Environment

```bash
# Deploy production
terraform workspace select production
terraform apply -var-file=terraform.tfvars

# Or use the script
./scripts/terraform-deploy.sh
# Select: production
```

**Production Configuration** (`terraform.tfvars`):
- Larger node pools (3-10 nodes with autoscaling)
- Production-grade instances
- Managed databases enabled
- High availability
- Full monitoring stack
- Estimated cost: $180-250/month

### Switching Environments

```bash
# List workspaces
terraform workspace list

# Switch to staging
terraform workspace select staging

# Switch to production
terraform workspace select production

# Show current workspace
terraform workspace show
```

### Environment Variables

```bash
# Production
export TF_WORKSPACE=production
export TF_VAR_do_token="your-token"

# Staging
export TF_WORKSPACE=staging
export TF_VAR_do_token="your-token"
```

## 💾 State Management

### Remote State (Recommended)

State is stored in Digital Ocean Spaces:

```hcl
# terraform/main.tf
terraform {
  backend "s3" {
    endpoint = "nyc3.digitaloceanspaces.com"
    bucket   = "rescuemesh-terraform-state"
    key      = "production/terraform.tfstate"
    region   = "us-east-1"  # Required but unused
    
    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }
}
```

**Setup**:

```bash
# Set credentials
export AWS_ACCESS_KEY_ID="your-spaces-access-key"
export AWS_SECRET_ACCESS_KEY="your-spaces-secret-key"

# Initialize with backend
terraform init

# Migrate local state to remote (if needed)
terraform init -migrate-state
```

### State Commands

```bash
# List resources
terraform state list

# Show resource details
terraform state show digitalocean_kubernetes_cluster.production

# Pull current state
terraform state pull > backup.tfstate

# Import existing resource
terraform import digitalocean_kubernetes_cluster.production <cluster-id>

# Remove resource from state (dangerous!)
terraform state rm digitalocean_kubernetes_cluster.production
```

### State Backup

```bash
# Automatic backups in Spaces
# Manual backup
terraform state pull > "backup-$(date +%Y%m%d-%H%M%S).tfstate"

# Restore from backup
terraform state push backup-20240101-120000.tfstate
```

### State Locking

Digital Ocean Spaces doesn't support state locking. For team environments:

```bash
# Option 1: Use Terraform Cloud (free tier)
terraform {
  cloud {
    organization = "your-org"
    workspaces {
      name = "rescuemesh-production"
    }
  }
}

# Option 2: External locking with DynamoDB
# (requires AWS account)
```

## 🚨 Disaster Recovery

### Backup Strategy

1. **Terraform State**: Versioned in Spaces
2. **Kubernetes Backups**: Velero daily snapshots
3. **Database Backups**: Automatic daily backups
4. **Configuration**: All in Git

### Recovery Scenarios

#### Complete Infrastructure Loss

```bash
# 1. Clone repository
git clone <your-repo>
cd rescuemesh/terraform

# 2. Initialize Terraform (pulls state from Spaces)
terraform init

# 3. Recreate infrastructure
terraform apply -auto-approve

# 4. Restore Kubernetes resources
cd ..
./scripts/setup-backup.sh

# 5. Restore from Velero
velero restore create --from-backup daily-backup-<latest>

# 6. Restore databases
kubectl apply -f k8s/backup/restore-job.yaml
```

#### Database Loss

```bash
# Managed databases have automatic backups
# Restore via Digital Ocean dashboard or API

# From DO Spaces backup
kubectl create job --from=cronjob/backup-databases manual-restore
kubectl logs -f job/manual-restore
```

#### State File Corruption

```bash
# 1. Download backup from Spaces
aws s3 cp s3://rescuemesh-terraform-state/production/terraform.tfstate.backup ./

# 2. Restore
terraform state push terraform.tfstate.backup

# 3. Verify
terraform plan
```

### Testing Disaster Recovery

```bash
# Create test environment
terraform workspace new dr-test
terraform apply -var-file=staging.tfvars

# Simulate disaster
terraform destroy

# Restore
terraform apply -var-file=staging.tfvars

# Clean up
terraform workspace select default
terraform workspace delete dr-test
```

## 💰 Cost Management

### Cost Breakdown

**Production Environment** (~$140-180/month):
```
Kubernetes Clusters:
- Production cluster: $120-180 (3-10 nodes)
- Staging cluster: $40-80 (2-4 nodes)

In-Cluster Databases (included):
- PostgreSQL, Redis, RabbitMQ in StatefulSets
- No additional managed database costs

Storage:
- Container Registry: $20
- Spaces (3 buckets): $15
- Block Storage: $10-20

Load Balancer: $12

Total: $140-180/month (using in-cluster databases)
```

**Staging Environment** (~$60/month):
```
Kubernetes Cluster: $40-80 (2-4 nodes)
Container Registry: $0 (shared)
Spaces: $5
Load Balancer: $12

Total: ~$60/month
```

### Cost Optimization

```hcl
# 1. Use smaller node sizes
variable "worker_node_size" {
  default = "s-2vcpu-4gb"  # Instead of s-4vcpu-8gb
}

# 2. Reduce node counts
variable "worker_node_count" {
  default = 2  # Instead of 3
}

# 3. Databases are in-cluster (already optimized)
# PostgreSQL, Redis, RabbitMQ run as StatefulSets
# No managed database costs

# 4. Use single region
variable "do_region" {
  default = "nyc3"  # Cheapest region
}

# 5. Optimize autoscaling
max_nodes = 5  # Instead of 10
```

### Cost Monitoring

```bash
# Use Digital Ocean cost dashboard
doctl balance get

# Estimate Terraform changes
terraform plan | grep "Plan:"

# Show current resources
terraform state list | wc -l

# Calculate monthly costs
doctl compute size list --format Slug,Memory,VCPUs,Disk,PriceMonthly
```

### Savings Tips

1. **Destroy staging when not in use**:
   ```bash
   terraform destroy -var-file=staging.tfvars
   ```

2. **Use spot instances** (when available):
   ```hcl
   # Not yet supported by Digital Ocean
   ```

3. **Schedule autoscaling**:
   ```bash
   # Scale down at night
   kubectl scale deployment --all --replicas=1
   
   # Scale up in morning
   kubectl scale deployment --all --replicas=3
   ```

4. **Optimize storage**:
   ```hcl
   # Enable lifecycle policies
   lifecycle_rules {
     expiration = 30  # Delete old backups
   }
   ```

## 🔍 Troubleshooting

### Common Issues

#### 1. Terraform Init Fails

```bash
# Error: Failed to configure backend
# Solution: Check Spaces credentials
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
terraform init -reconfigure
```

#### 2. Cluster Creation Timeout

```bash
# Error: timeout while waiting for cluster
# Solution: Increase timeout
terraform apply -var="cluster_timeout=30m"

# Or check Digital Ocean status
doctl kubernetes cluster list
```

#### 3. Database Connection Fails

```bash
# Error: database "xyz" does not exist
# Solution: Check firewall rules
terraform show | grep firewall

# Update firewall
terraform apply -target=digitalocean_database_firewall.users_db
```

#### 4. State Lock Error

```bash
# Error: state locked
# Solution: Force unlock (use carefully!)
terraform force-unlock <lock-id>

# Or wait for lock timeout
```

#### 5. Resource Already Exists

```bash
# Error: resource already exists
# Solution: Import existing resource
terraform import digitalocean_kubernetes_cluster.production <cluster-id>

# Or remove from state
terraform state rm digitalocean_kubernetes_cluster.production
```

### Validation Commands

```bash
# Validate Terraform syntax
terraform validate

# Check formatting
terraform fmt -check

# Show current state
terraform show

# Verify outputs
terraform output

# Refresh state
terraform refresh

# Check for drift
terraform plan -detailed-exitcode
```

### Debug Mode

```bash
# Enable debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform-debug.log
terraform apply

# Disable
unset TF_LOG
unset TF_LOG_PATH
```

### Getting Help

```bash
# Terraform documentation
terraform --help
terraform plan --help

# Digital Ocean CLI
doctl kubernetes --help
doctl database --help

# Provider documentation
# https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs
```

## 📚 Additional Resources

- [Terraform Digital Ocean Provider](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs)
- [Digital Ocean Kubernetes](https://docs.digitalocean.com/products/kubernetes/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Digital Ocean API](https://docs.digitalocean.com/reference/api/)

## 🎓 Next Steps

1. **Review Configuration**: Understand each Terraform file
2. **Customize Variables**: Adjust for your requirements
3. **Deploy Staging**: Test with staging environment first
4. **Deploy Production**: Use automated script
5. **Monitor Costs**: Set up billing alerts in Digital Ocean
6. **Backup State**: Ensure Spaces backup is working
7. **Documentation**: Document any customizations
8. **Team Access**: Share credentials securely (use Vault)

---

**Note**: Always review `terraform plan` output before applying changes to production!
