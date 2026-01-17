# PostgreSQL Database Clusters
# NOTE: Managed databases are DISABLED by default
# The application uses in-cluster PostgreSQL, Redis, and RabbitMQ
# running as StatefulSets in Kubernetes (see k8s/infrastructure/)
# 
# To enable managed databases, uncomment the resources below and:
# 1. Set enable_managed_databases = true in terraform.tfvars
# 2. Update service deployments to use managed database endpoints
# 3. This will add ~$84/month to infrastructure costs

# Managed databases disabled - using in-cluster databases instead
/*
# Users Database
resource "digitalocean_database_cluster" "users" {
  name       = "rescuemesh-users-${var.environment}"
  engine     = "pg"
  version    = "15"
  size       = var.db_cluster_size
  region     = var.region
  node_count = var.db_cluster_node_count
  
  private_network_uuid = digitalocean_vpc.main.id
  
  tags = concat(var.tags, ["database:users"])
  
  maintenance_window {
    day  = "sunday"
    hour = "02:00:00"
  }
  
  backup_restore {
    database_name = "rescuemesh_users"
  }
}

resource "digitalocean_database_db" "users" {
  cluster_id = digitalocean_database_cluster.users.id
  name       = "rescuemesh_users"
}

# Skills Database
resource "digitalocean_database_cluster" "skills" {
  name       = "rescuemesh-skills-${var.environment}"
  engine     = "pg"
  version    = "15"
  size       = var.db_cluster_size
  region     = var.region
  node_count = var.db_cluster_node_count
  
  private_network_uuid = digitalocean_vpc.main.id
  
  tags = concat(var.tags, ["database:skills"])
  
  maintenance_window {
    day  = "sunday"
    hour = "02:30:00"
  }
}

resource "digitalocean_database_db" "skills" {
  cluster_id = digitalocean_database_cluster.skills.id
  name       = "rescuemesh_skills"
}

# Disasters Database
resource "digitalocean_database_cluster" "disasters" {
  name       = "rescuemesh-disasters-${var.environment}"
  engine     = "pg"
  version    = "15"
  size       = var.db_cluster_size
  region     = var.region
  node_count = var.db_cluster_node_count
  
  private_network_uuid = digitalocean_vpc.main.id
  
  tags = concat(var.tags, ["database:disasters"])
  
  maintenance_window {
    day  = "sunday"
    hour = "03:00:00"
  }
}

resource "digitalocean_database_db" "disasters" {
  cluster_id = digitalocean_database_cluster.disasters.id
  name       = "rescuemesh_disasters"
}

# SOS Database
resource "digitalocean_database_cluster" "sos" {
  name       = "rescuemesh-sos-${var.environment}"
  engine     = "pg"
  version    = "15"
  size       = var.db_cluster_size
  region     = var.region
  node_count = var.db_cluster_node_count
  
  private_network_uuid = digitalocean_vpc.main.id
  
  tags = concat(var.tags, ["database:sos"])
  
  maintenance_window {
    day  = "sunday"
    hour = "03:30:00"
  }
}

resource "digitalocean_database_db" "sos" {
  cluster_id = digitalocean_database_cluster.sos.id
  name       = "rescuemesh_sos"
}

# Matching Database
resource "digitalocean_database_cluster" "matching" {
  name       = "rescuemesh-matching-${var.environment}"
  engine     = "pg"
  version    = "15"
  size       = var.db_cluster_size
  region     = var.region
  node_count = var.db_cluster_node_count
  
  private_network_uuid = digitalocean_vpc.main.id
  
  tags = concat(var.tags, ["database:matching"])
  
  maintenance_window {
    day  = "sunday"
    hour = "04:00:00"
  }
}

resource "digitalocean_database_db" "matching" {
  cluster_id = digitalocean_database_cluster.matching.id
  name       = "rescuemesh_matching"
}

# Notification Database
resource "digitalocean_database_cluster" "notification" {
  name       = "rescuemesh-notification-${var.environment}"
  engine     = "pg"
  version    = "15"
  size       = var.db_cluster_size
  region     = var.region
  node_count = var.db_cluster_node_count
  
  private_network_uuid = digitalocean_vpc.main.id
  
  tags = concat(var.tags, ["database:notification"])
  
  maintenance_window {
    day  = "sunday"
    hour = "04:30:00"
  }
}

resource "digitalocean_database_db" "notification" {
  cluster_id = digitalocean_database_cluster.notification.id
  name       = "rescuemesh_notification"
}

# Redis Clusters
resource "digitalocean_database_cluster" "redis_users" {
  name       = "rescuemesh-redis-users-${var.environment}"
  engine     = "redis"
  version    = "7"
  size       = "db-s-1vcpu-1gb"
  region     = var.region
  node_count = 1
  
  private_network_uuid = digitalocean_vpc.main.id
  
  tags = concat(var.tags, ["cache:users"])
  
  eviction_policy = "allkeys_lru"
}

resource "digitalocean_database_cluster" "redis_skills" {
  name       = "rescuemesh-redis-skills-${var.environment}"
  engine     = "redis"
  version    = "7"
  size       = "db-s-1vcpu-1gb"
  region     = var.region
  node_count = 1
  
  private_network_uuid = digitalocean_vpc.main.id
  
  tags = concat(var.tags, ["cache:skills"])
  
  eviction_policy = "allkeys_lru"
}

resource "digitalocean_database_cluster" "redis_shared" {
  name       = "rescuemesh-redis-shared-${var.environment}"
  engine     = "redis"
  version    = "7"
  size       = "db-s-2vcpu-2gb"
  region     = var.region
  node_count = 1
  
  private_network_uuid = digitalocean_vpc.main.id
  
  tags = concat(var.tags, ["cache:shared"])
  
  eviction_policy = "allkeys_lru"
}

# Database firewall rules
resource "digitalocean_database_firewall" "users" {
  cluster_id = digitalocean_database_cluster.users.id
  
  rule {
    type  = "k8s"
    value = digitalocean_kubernetes_cluster.production.id
  }
}

resource "digitalocean_database_firewall" "skills" {
  cluster_id = digitalocean_database_cluster.skills.id
  
  rule {
    type  = "k8s"
    value = digitalocean_kubernetes_cluster.production.id
  }
}

# Connection pools for better performance
resource "digitalocean_database_connection_pool" "users_pool" {
  cluster_id = digitalocean_database_cluster.users.id
  name       = "users-pool"
  mode       = "transaction"
  size       = 25
  db_name    = digitalocean_database_db.users.name
  user       = digitalocean_database_cluster.users.user
}
