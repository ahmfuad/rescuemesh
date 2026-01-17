# Monitoring and Alerting

# Uptime check for main site
resource "digitalocean_uptime_check" "main_site" {
  name    = "RescueMesh Main Site"
  target  = "https://${var.domain}"
  type    = "https"
  regions = ["us_east", "eu_west"]
  enabled = var.enable_monitoring
}

# Uptime check for API
resource "digitalocean_uptime_check" "api" {
  name    = "RescueMesh API"
  target  = "https://api.${var.domain}/health"
  type    = "https"
  regions = ["us_east", "eu_west"]
  enabled = var.enable_monitoring
}

# Alert policy for uptime checks
resource "digitalocean_uptime_alert" "main_site_down" {
  name  = "Main Site Down Alert"
  type  = "down"
  
  uptime_check_id = digitalocean_uptime_check.main_site.id
  
  notifications {
    email = [var.admin_email]
  }
  
  comparison = "less_than"
  threshold  = 1
  period     = "5m"
}

# Alert policy for database
resource "digitalocean_monitor_alert" "database_high_cpu" {
  alerts {
    email = [var.admin_email]
  }
  
  window      = "5m"
  type        = "v1/insights/droplet/cpu"
  compare     = "greater_than"
  value       = 90
  enabled     = var.enable_alerting
  entities    = [digitalocean_database_cluster.users.id]
  description = "Alert when database CPU > 90%"
}

# Project to organize resources
resource "digitalocean_project" "rescuemesh" {
  name        = "RescueMesh ${var.environment}"
  description = "RescueMesh disaster response platform - ${var.environment}"
  purpose     = "Web Application"
  environment = var.environment
  
  resources = concat(
    [digitalocean_kubernetes_cluster.production.urn],
    [digitalocean_container_registry.main.urn],
    [digitalocean_spaces_bucket.backups.urn],
    [digitalocean_spaces_bucket.assets.urn],
    [digitalocean_database_cluster.users.urn],
    [digitalocean_database_cluster.skills.urn],
    [digitalocean_database_cluster.disasters.urn],
    [digitalocean_database_cluster.sos.urn],
    [digitalocean_database_cluster.matching.urn],
    [digitalocean_database_cluster.notification.urn],
    [digitalocean_database_cluster.redis_users.urn],
    [digitalocean_database_cluster.redis_skills.urn],
    [digitalocean_database_cluster.redis_shared.urn],
  )
}
