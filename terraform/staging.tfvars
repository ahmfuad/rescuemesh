# Staging environment variables
environment = "staging"
cluster_name = "rescuemesh-staging-cluster"

# Digital Ocean
region = "nyc3"

# Kubernetes - smaller for staging
kubernetes_version = "1.28.2-do.0"
node_pool_size = "s-2vcpu-2gb"
node_pool_min_nodes = 2
node_pool_max_nodes = 4

# Databases - smaller for staging
db_cluster_size = "db-s-1vcpu-2gb"
db_cluster_node_count = 1

# Domain
domain = "staging.villagers.live"

# Features
enable_autoscaling = true
enable_monitoring = true
enable_alerting = false  # Disable alerts for staging
enable_elk_stack = false  # Use simpler logging for staging
enable_jaeger = true
enable_sonarqube = false  # Only in production

# Backups
backup_retention_days = 7
backup_space_name = "rescuemesh-staging-backups"

# Registry
registry_subscription_tier = "basic"

# Tags
tags = [
  "rescuemesh",
  "staging",
  "terraform-managed"
]

# Admin
admin_email = "dev@villagers.live"
letsencrypt_email = "dev@villagers.live"
