# Load Balancer for production
resource "digitalocean_loadbalancer" "production" {
  name   = "${var.cluster_name}-lb"
  region = var.region
  
  vpc_uuid = digitalocean_vpc.main.id
  
  forwarding_rule {
    entry_port      = 443
    entry_protocol  = "https"
    target_port     = 80
    target_protocol = "http"
    
    certificate_name = digitalocean_certificate.main.name
    tls_passthrough  = false
  }
  
  forwarding_rule {
    entry_port      = 80
    entry_protocol  = "http"
    target_port     = 80
    target_protocol = "http"
  }
  
  healthcheck {
    port     = 80
    protocol = "http"
    path     = "/health"
    check_interval_seconds   = 10
    response_timeout_seconds = 5
    unhealthy_threshold      = 3
    healthy_threshold        = 2
  }
  
  droplet_tag = "k8s:${digitalocean_kubernetes_cluster.production.id}"
  
  algorithm = "least_connections"
  
  enable_proxy_protocol = true
  enable_backend_keepalive = true
  
  sticky_sessions {
    type               = "cookies"
    cookie_name        = "lb-session"
    cookie_ttl_seconds = 300
  }
}

# SSL Certificate
resource "digitalocean_certificate" "main" {
  name    = "${var.domain}-cert"
  type    = "lets_encrypt"
  domains = [var.domain, "www.${var.domain}", "*.${var.domain}"]
  
  lifecycle {
    create_before_destroy = true
  }
}

# Firewall for Kubernetes nodes
resource "digitalocean_firewall" "k8s_nodes" {
  name = "${var.cluster_name}-firewall"
  
  tags = ["k8s:${digitalocean_kubernetes_cluster.production.id}"]
  
  # Allow SSH from admin IPs (add your IPs here)
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]  # Restrict this in production!
  }
  
  # Allow Kubernetes API
  inbound_rule {
    protocol         = "tcp"
    port_range       = "6443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  
  # Allow HTTP/HTTPS from load balancer
  inbound_rule {
    protocol                  = "tcp"
    port_range               = "80"
    source_load_balancer_uids = [digitalocean_loadbalancer.production.id]
  }
  
  inbound_rule {
    protocol                  = "tcp"
    port_range               = "443"
    source_load_balancer_uids = [digitalocean_loadbalancer.production.id]
  }
  
  # Allow inter-node communication
  inbound_rule {
    protocol         = "tcp"
    port_range       = "1-65535"
    source_tags      = ["k8s:${digitalocean_kubernetes_cluster.production.id}"]
  }
  
  inbound_rule {
    protocol         = "udp"
    port_range       = "1-65535"
    source_tags      = ["k8s:${digitalocean_kubernetes_cluster.production.id}"]
  }
  
  # Allow all outbound
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  
  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  
  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# Reserved IP for Load Balancer
resource "digitalocean_reserved_ip" "lb" {
  region = var.region
}

resource "digitalocean_reserved_ip_assignment" "lb" {
  ip_address = digitalocean_reserved_ip.lb.ip_address
  droplet_id = digitalocean_loadbalancer.production.id
}
