# Digital Ocean Token
variable "do_token" {
  description = "Digital Ocean API Token"
  type        = string
  sensitive   = true
}

# Digital Ocean Spaces credentials
variable "do_spaces_access_id" {
  description = "Digital Ocean Spaces Access ID"
  type        = string
  sensitive   = true
}

variable "do_spaces_secret_key" {
  description = "Digital Ocean Spaces Secret Key"
  type        = string
  sensitive   = true
}

# Cloudflare
variable "cloudflare_api_token" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for the domain"
  type        = string
}

variable "domain" {
  description = "Primary domain name"
  type        = string
  default     = "villagers.live"
}

# Environment
variable "environment" {
  description = "Environment name (staging or production)"
  type        = string
  default     = "production"
  
  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be either staging or production."
  }
}

# Region configuration
variable "region" {
  description = "Digital Ocean region"
  type        = string
  default     = "nyc3"
}

variable "availability_zones" {
  description = "Availability zones for the region"
  type        = list(string)
  default     = ["nyc3"]
}

# Kubernetes cluster configuration
variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = "rescuemesh-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28.2-do.0"
}

# Node pool configuration
variable "node_pool_size" {
  description = "Droplet size for worker nodes"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "node_pool_min_nodes" {
  description = "Minimum number of nodes in the pool"
  type        = number
  default     = 3
}

variable "node_pool_max_nodes" {
  description = "Maximum number of nodes in the pool"
  type        = number
  default     = 10
}

# Database configuration
variable "db_cluster_size" {
  description = "Database cluster node size"
  type        = string
  default     = "db-s-2vcpu-4gb"
}

variable "db_cluster_node_count" {
  description = "Number of database nodes"
  type        = number
  default     = 2
}

# Backup retention
variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = list(string)
  default = [
    "rescuemesh",
    "terraform-managed"
  ]
}

# VPC CIDR
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Container Registry
variable "registry_subscription_tier" {
  description = "Container registry subscription tier"
  type        = string
  default     = "professional"
  
  validation {
    condition     = contains(["starter", "basic", "professional"], var.registry_subscription_tier)
    error_message = "Registry tier must be starter, basic, or professional."
  }
}

# Monitoring
variable "enable_monitoring" {
  description = "Enable Digital Ocean monitoring"
  type        = bool
  default     = true
}

variable "enable_alerting" {
  description = "Enable alerting policies"
  type        = bool
  default     = true
}

# SSL/TLS
variable "letsencrypt_email" {
  description = "Email for Let's Encrypt certificates"
  type        = string
}

# Admin email
variable "admin_email" {
  description = "Administrator email for notifications"
  type        = string
}

# Cost optimization
variable "enable_autoscaling" {
  description = "Enable cluster autoscaling"
  type        = bool
  default     = true
}

variable "auto_upgrade" {
  description = "Enable automatic Kubernetes upgrades"
  type        = bool
  default     = true
}

# Database passwords (should be set via environment variables or secret management)
variable "postgres_password" {
  description = "PostgreSQL admin password"
  type        = string
  sensitive   = true
}

variable "redis_password" {
  description = "Redis password"
  type        = string
  sensitive   = true
}

# JWT secret
variable "jwt_secret" {
  description = "JWT secret for authentication"
  type        = string
  sensitive   = true
}

# External services
variable "sendgrid_api_key" {
  description = "SendGrid API key for email notifications"
  type        = string
  sensitive   = true
  default     = ""
}

variable "twilio_account_sid" {
  description = "Twilio Account SID for SMS"
  type        = string
  sensitive   = true
  default     = ""
}

variable "twilio_auth_token" {
  description = "Twilio Auth Token"
  type        = string
  sensitive   = true
  default     = ""
}

# Feature flags
variable "enable_elk_stack" {
  description = "Enable ELK stack for logging"
  type        = bool
  default     = true
}

variable "enable_jaeger" {
  description = "Enable Jaeger for distributed tracing"
  type        = bool
  default     = true
}

variable "enable_sonarqube" {
  description = "Enable SonarQube for code quality"
  type        = bool
  default     = true
}

# Spaces configuration
variable "backup_space_name" {
  description = "Name of the backup Space"
  type        = string
  default     = "rescuemesh-backups"
}

variable "backup_space_region" {
  description = "Region for backup Space"
  type        = string
  default     = "nyc3"
}
