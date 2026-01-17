# Container Registry
resource "digitalocean_container_registry" "main" {
  name                   = "rescuemesh"
  subscription_tier_slug = var.registry_subscription_tier
  region                 = var.region
}

# Grant Kubernetes cluster access to registry
resource "digitalocean_container_registry_docker_credentials" "production" {
  registry_name = digitalocean_container_registry.main.name
  write         = true
}

# Spaces for backups
resource "digitalocean_spaces_bucket" "backups" {
  name   = var.backup_space_name
  region = var.backup_space_region
  
  acl = "private"
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    id      = "delete-old-backups"
    enabled = true
    
    expiration {
      days = var.backup_retention_days
    }
    
    noncurrent_version_expiration {
      days = 7
    }
  }
  
  lifecycle_rule {
    id      = "transition-old-backups"
    enabled = true
    
    transition {
      days          = 30
      storage_class = "GLACIER"
    }
  }
}

# Spaces for Terraform state
resource "digitalocean_spaces_bucket" "terraform_state" {
  name   = "rescuemesh-terraform-state"
  region = var.backup_space_region
  
  acl = "private"
  
  versioning {
    enabled = true
  }
}

# Spaces for application assets
resource "digitalocean_spaces_bucket" "assets" {
  name   = "rescuemesh-assets"
  region = var.backup_space_region
  
  acl = "public-read"
  
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["https://${var.domain}", "https://www.${var.domain}"]
    max_age_seconds = 3600
  }
}

# CDN endpoint for assets
resource "digitalocean_cdn" "assets" {
  origin = digitalocean_spaces_bucket.assets.bucket_domain_name
  
  custom_domain = "cdn.${var.domain}"
  
  ttl = 3600
}
