# Cloudflare DNS Configuration for RescueMesh

## Current Load Balancer IP
```
129.212.147.11
```

## Required DNS Records in Cloudflare

### Option 1: Direct Connection (Recommended for API)
Set these DNS records to **DNS Only** (gray cloud):

| Type | Name | Content | Proxy Status |
|------|------|---------|--------------|
| A | villagers.live | 129.212.147.11 | DNS Only (gray cloud) |
| A | www | 129.212.147.11 | DNS Only (gray cloud) |
| A | api | 129.212.147.11 | DNS Only (gray cloud) |

### Option 2: With Cloudflare Proxy (Orange Cloud)
If you want to use Cloudflare's CDN and DDoS protection:

| Type | Name | Content | Proxy Status |
|------|------|---------|--------------|
| A | villagers.live | 129.212.147.11 | Proxied (orange cloud) |
| A | www | 129.212.147.11 | Proxied (orange cloud) |
| A | api | 129.212.147.11 | DNS Only (gray cloud) |

**Important:** Keep `api` subdomain as DNS Only to avoid SSL/TLS issues with backend services.

## SSL/TLS Configuration

### If Using Cloudflare Proxy (Orange Cloud):
1. Go to Cloudflare Dashboard → SSL/TLS
2. Set SSL/TLS encryption mode to: **Full** or **Full (strict)**
3. Enable "Always Use HTTPS"

### If Using DNS Only (Gray Cloud):
SSL certificates will be issued by cert-manager (Let's Encrypt) automatically.

## Verification Commands

```bash
# Check DNS resolution
nslookup villagers.live
nslookup api.villagers.live

# Test HTTP/HTTPS
curl -I http://villagers.live
curl -I https://villagers.live
curl -I https://api.villagers.live/health

# Check ingress status
kubectl get ingress -n rescuemesh
```

## Current Status
- Load Balancer IP: 129.212.147.11
- Ingress Controller: Running ✓
- Frontend Ingress: Configured ✓
- API Ingress: Configured ✓
- SSL Certificates: Pending (cert-manager not installed)
