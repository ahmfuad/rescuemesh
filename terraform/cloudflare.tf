# Cloudflare DNS Records
resource "cloudflare_record" "root" {
  zone_id = var.cloudflare_zone_id
  name    = "@"
  value   = digitalocean_reserved_ip.lb.ip_address
  type    = "A"
  proxied = true
  ttl     = 1  # Auto
  
  comment = "Managed by Terraform - Production Load Balancer"
}

resource "cloudflare_record" "www" {
  zone_id = var.cloudflare_zone_id
  name    = "www"
  value   = digitalocean_reserved_ip.lb.ip_address
  type    = "A"
  proxied = true
  ttl     = 1
  
  comment = "Managed by Terraform - WWW subdomain"
}

resource "cloudflare_record" "api" {
  zone_id = var.cloudflare_zone_id
  name    = "api"
  value   = digitalocean_reserved_ip.lb.ip_address
  type    = "A"
  proxied = true
  ttl     = 1
  
  comment = "Managed by Terraform - API endpoint"
}

resource "cloudflare_record" "grafana" {
  zone_id = var.cloudflare_zone_id
  name    = "grafana"
  value   = digitalocean_reserved_ip.lb.ip_address
  type    = "A"
  proxied = true
  ttl     = 1
  
  comment = "Managed by Terraform - Grafana monitoring"
}

resource "cloudflare_record" "kibana" {
  zone_id = var.cloudflare_zone_id
  name    = "kibana"
  value   = digitalocean_reserved_ip.lb.ip_address
  type    = "A"
  proxied = true
  ttl     = 1
  
  comment = "Managed by Terraform - Kibana logs"
}

resource "cloudflare_record" "jaeger" {
  zone_id = var.cloudflare_zone_id
  name    = "jaeger"
  value   = digitalocean_reserved_ip.lb.ip_address
  type    = "A"
  proxied = true
  ttl     = 1
  
  comment = "Managed by Terraform - Jaeger tracing"
}

resource "cloudflare_record" "sonarqube" {
  zone_id = var.cloudflare_zone_id
  name    = "sonarqube"
  value   = digitalocean_reserved_ip.lb.ip_address
  type    = "A"
  proxied = true
  ttl     = 1
  
  comment = "Managed by Terraform - SonarQube code quality"
}

resource "cloudflare_record" "staging" {
  count   = var.environment == "staging" ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = "staging"
  value   = digitalocean_kubernetes_cluster.staging[0].ipv4_address
  type    = "A"
  proxied = true
  ttl     = 1
  
  comment = "Managed by Terraform - Staging environment"
}

# Cloudflare Page Rules
resource "cloudflare_page_rule" "api_cache_bypass" {
  zone_id = var.cloudflare_zone_id
  target  = "api.${var.domain}/*"
  
  priority = 1
  
  actions {
    cache_level = "bypass"
  }
}

resource "cloudflare_page_rule" "assets_cache" {
  zone_id = var.cloudflare_zone_id
  target  = "${var.domain}/static/*"
  
  priority = 2
  
  actions {
    cache_level         = "cache_everything"
    edge_cache_ttl      = 86400
    browser_cache_ttl   = 14400
  }
}

# Cloudflare WAF Rules
resource "cloudflare_ruleset" "waf" {
  zone_id     = var.cloudflare_zone_id
  name        = "RescueMesh WAF Rules"
  description = "Custom WAF rules for RescueMesh"
  kind        = "zone"
  phase       = "http_request_firewall_custom"
  
  rules {
    action      = "block"
    expression  = "(http.request.uri.path contains \"/admin\" and not ip.src in {1.2.3.4})"  # Replace with actual admin IP
    description = "Block admin access from unauthorized IPs"
    enabled     = true
  }
  
  rules {
    action      = "challenge"
    expression  = "(cf.threat_score > 10)"
    description = "Challenge high threat score requests"
    enabled     = true
  }
}

# Cloudflare Rate Limiting
resource "cloudflare_rate_limit" "api_rate_limit" {
  zone_id = var.cloudflare_zone_id
  
  threshold = 100
  period    = 60
  
  match {
    request {
      url_pattern = "${var.domain}/api/*"
    }
  }
  
  action {
    mode    = "challenge"
    timeout = 300
  }
  
  disabled    = false
  description = "Rate limit API endpoints"
}

# Cloudflare SSL/TLS Settings
resource "cloudflare_zone_settings_override" "main" {
  zone_id = var.cloudflare_zone_id
  
  settings {
    ssl                      = "strict"
    always_use_https         = "on"
    automatic_https_rewrites = "on"
    opportunistic_encryption = "on"
    tls_1_3                  = "on"
    min_tls_version          = "1.2"
    
    brotli              = "on"
    minify {
      css  = "on"
      js   = "on"
      html = "on"
    }
    
    security_level    = "medium"
    challenge_ttl     = 1800
    browser_check     = "on"
    
    http2             = "on"
    http3             = "on"
    zero_rtt          = "on"
    ipv6              = "on"
    
    websockets        = "on"
    
    cache_level       = "aggressive"
    browser_cache_ttl = 14400
  }
}
