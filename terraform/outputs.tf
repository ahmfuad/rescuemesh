# Outputs

# Kubernetes
output "kubernetes_cluster_id" {
  description = "ID of the Kubernetes cluster"
  value       = digitalocean_kubernetes_cluster.production.id
}

output "kubernetes_cluster_endpoint" {
  description = "Endpoint for Kubernetes cluster"
  value       = digitalocean_kubernetes_cluster.production.endpoint
  sensitive   = true
}

output "kubernetes_cluster_name" {
  description = "Name of the Kubernetes cluster"
  value       = digitalocean_kubernetes_cluster.production.name
}

output "kubeconfig_path" {
  description = "Path to kubeconfig file"
  value       = local_file.kubeconfig_production.filename
}

# Load Balancer
output "load_balancer_ip" {
  description = "IP address of the load balancer"
  value       = digitalocean_reserved_ip.lb.ip_address
}

output "load_balancer_id" {
  description = "ID of the load balancer"
  value       = digitalocean_loadbalancer.production.id
}

# Container Registry
output "container_registry_endpoint" {
  description = "Container registry endpoint"
  value       = digitalocean_container_registry.main.endpoint
}

output "container_registry_name" {
  description = "Container registry name"
  value       = digitalocean_container_registry.main.name
}

# Databases
output "database_users_host" {
  description = "Users database host"
  value       = digitalocean_database_cluster.users.host
  sensitive   = true
}

output "database_users_port" {
  description = "Users database port"
  value       = digitalocean_database_cluster.users.port
}

output "database_users_connection_pool" {
  description = "Users database connection pool URI"
  value       = digitalocean_database_connection_pool.users_pool.private_uri
  sensitive   = true
}

output "redis_users_host" {
  description = "Users Redis host"
  value       = digitalocean_database_cluster.redis_users.host
  sensitive   = true
}

output "redis_shared_host" {
  description = "Shared Redis host"
  value       = digitalocean_database_cluster.redis_shared.host
  sensitive   = true
}

# Spaces
output "backup_space_name" {
  description = "Name of the backup Space"
  value       = digitalocean_spaces_bucket.backups.name
}

output "backup_space_endpoint" {
  description = "Endpoint for backup Space"
  value       = digitalocean_spaces_bucket.backups.bucket_domain_name
}

output "assets_cdn_endpoint" {
  description = "CDN endpoint for assets"
  value       = digitalocean_cdn.assets.endpoint
}

# VPC
output "vpc_id" {
  description = "ID of the VPC"
  value       = digitalocean_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = digitalocean_vpc.main.ip_range
}

# DNS
output "domain_nameservers" {
  description = "Domain nameservers (from Cloudflare)"
  value       = "Configure your domain registrar to use Cloudflare nameservers"
}

output "cloudflare_dns_records" {
  description = "Cloudflare DNS records created"
  value = {
    root      = cloudflare_record.root.hostname
    www       = cloudflare_record.www.hostname
    api       = cloudflare_record.api.hostname
    grafana   = cloudflare_record.grafana.hostname
    kibana    = cloudflare_record.kibana.hostname
    jaeger    = cloudflare_record.jaeger.hostname
    sonarqube = cloudflare_record.sonarqube.hostname
  }
}

# Project
output "project_id" {
  description = "Digital Ocean project ID"
  value       = digitalocean_project.rescuemesh.id
}

# Next steps
output "next_steps" {
  description = "Next steps for deployment"
  value = <<-EOT
    
    ========================================
    Infrastructure Provisioned Successfully!
    ========================================
    
    Next Steps:
    
    1. Configure kubectl:
       export KUBECONFIG=${local_file.kubeconfig_production.filename}
       kubectl get nodes
    
    2. Push Docker images to registry:
       doctl registry login
       docker tag your-image ${digitalocean_container_registry.main.endpoint}/your-image:tag
       docker push ${digitalocean_container_registry.main.endpoint}/your-image:tag
    
    3. Deploy applications:
       kubectl apply -k ../k8s/
    
    4. Access services:
       Main site: https://${var.domain}
       API: https://api.${var.domain}
       Grafana: https://grafana.${var.domain}
       Kibana: https://kibana.${var.domain}
       Jaeger: https://jaeger.${var.domain}
       SonarQube: https://sonarqube.${var.domain}
    
    5. Configure monitoring:
       ./scripts/setup-monitoring.sh
    
    6. Setup backups:
       ./scripts/setup-backup.sh
    
    Load Balancer IP: ${digitalocean_reserved_ip.lb.ip_address}
    (DNS records already configured in Cloudflare)
    
    ========================================
  EOT
}
