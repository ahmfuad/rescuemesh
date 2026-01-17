# Terraform configuration for RescueMesh infrastructure on Digital Ocean
# Version: 1.0.0

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.34"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.20"
    }
  }
  
  # Remote state storage
  backend "s3" {
    endpoint                    = "nyc3.digitaloceanspaces.com"
    key                         = "terraform/rescuemesh/terraform.tfstate"
    bucket                      = "rescuemesh-terraform-state"
    region                      = "us-east-1"  # Dummy region for DO Spaces
    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }
}

# Provider configurations
provider "digitalocean" {
  token             = var.do_token
  spaces_access_id  = var.do_spaces_access_id
  spaces_secret_key = var.do_spaces_secret_key
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "kubernetes" {
  host  = digitalocean_kubernetes_cluster.production.endpoint
  token = digitalocean_kubernetes_cluster.production.kube_config[0].token
  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.production.kube_config[0].cluster_ca_certificate
  )
}

provider "helm" {
  kubernetes {
    host  = digitalocean_kubernetes_cluster.production.endpoint
    token = digitalocean_kubernetes_cluster.production.kube_config[0].token
    cluster_ca_certificate = base64decode(
      digitalocean_kubernetes_cluster.production.kube_config[0].cluster_ca_certificate
    )
  }
}
