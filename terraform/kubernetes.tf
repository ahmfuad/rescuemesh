# VPC for Private Networking
resource "digitalocean_vpc" "main" {
  name     = "${var.cluster_name}-vpc"
  region   = var.region
  ip_range = var.vpc_cidr
  
  description = "VPC for RescueMesh ${var.environment} environment"
}

# Production Kubernetes Cluster
resource "digitalocean_kubernetes_cluster" "production" {
  name    = var.cluster_name
  region  = var.region
  version = var.kubernetes_version
  
  vpc_uuid = digitalocean_vpc.main.id
  
  tags = concat(var.tags, ["environment:${var.environment}"])
  
  # Cluster configuration
  auto_upgrade = var.auto_upgrade
  surge_upgrade = true
  ha           = true
  
  maintenance_policy {
    start_time = "04:00"
    day        = "sunday"
  }
  
  # Primary node pool
  node_pool {
    name       = "worker-pool"
    size       = var.node_pool_size
    auto_scale = var.enable_autoscaling
    min_nodes  = var.node_pool_min_nodes
    max_nodes  = var.node_pool_max_nodes
    tags       = concat(var.tags, ["node-pool:primary"])
    
    labels = {
      environment = var.environment
      node-type   = "worker"
    }
    
    taint {
      key    = "workload"
      value  = "general"
      effect = "NoSchedule"
    }
  }
}

# Staging Kubernetes Cluster (smaller)
resource "digitalocean_kubernetes_cluster" "staging" {
  count   = var.environment == "staging" ? 1 : 0
  
  name    = "${var.cluster_name}-staging"
  region  = var.region
  version = var.kubernetes_version
  
  vpc_uuid = digitalocean_vpc.main.id
  
  tags = concat(var.tags, ["environment:staging"])
  
  auto_upgrade = true
  surge_upgrade = true
  ha           = false  # Single control plane for staging
  
  node_pool {
    name       = "staging-pool"
    size       = "s-2vcpu-2gb"  # Smaller for staging
    auto_scale = true
    min_nodes  = 2
    max_nodes  = 4
    tags       = concat(var.tags, ["node-pool:staging"])
  }
}

# Additional node pool for database workloads
resource "digitalocean_kubernetes_node_pool" "database" {
  cluster_id = digitalocean_kubernetes_cluster.production.id
  
  name       = "database-pool"
  size       = "s-4vcpu-8gb"
  auto_scale = true
  min_nodes  = 3
  max_nodes  = 6
  tags       = concat(var.tags, ["node-pool:database"])
  
  labels = {
    workload = "database"
  }
  
  taint {
    key    = "workload"
    value  = "database"
    effect = "NoSchedule"
  }
}

# Node pool for monitoring workloads
resource "digitalocean_kubernetes_node_pool" "monitoring" {
  cluster_id = digitalocean_kubernetes_cluster.production.id
  
  name       = "monitoring-pool"
  size       = "s-2vcpu-4gb"
  auto_scale = true
  min_nodes  = 2
  max_nodes  = 4
  tags       = concat(var.tags, ["node-pool:monitoring"])
  
  labels = {
    workload = "monitoring"
  }
  
  taint {
    key    = "workload"
    value  = "monitoring"
    effect = "NoSchedule"
  }
}

# Save kubeconfig locally
resource "local_file" "kubeconfig_production" {
  content  = digitalocean_kubernetes_cluster.production.kube_config[0].raw_config
  filename = "${path.module}/kubeconfig-production.yaml"
  
  file_permission = "0600"
}

resource "local_file" "kubeconfig_staging" {
  count    = var.environment == "staging" ? 1 : 0
  content  = digitalocean_kubernetes_cluster.staging[0].kube_config[0].raw_config
  filename = "${path.module}/kubeconfig-staging.yaml"
  
  file_permission = "0600"
}
