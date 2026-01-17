# DNS Configuration for RescueMesh

## Get Your Ingress IP

```bash
kubectl get ingress -n rescuemesh
```

You should see output like:
```
NAME               CLASS    HOSTS                               ADDRESS          PORTS     AGE
api-ingress        nginx    api.villagers.live                  129.212.147.11   80, 443   10m
frontend-ingress   nginx    villagers.live,www.villagers.live   129.212.147.11   80, 443   10m
```

**Your Ingress IP**: `129.212.147.11` (use your actual IP)

---

## DNS Records to Add

Add these A records to your DNS provider (Cloudflare, Route53, Namecheap, etc.):

### Required Records

| Type | Name | Value | TTL | Description |
|------|------|-------|-----|-------------|
| A | @ (villagers.live) | 129.212.147.11 | 300 | Main website |
| A | www | 129.212.147.11 | 300 | WWW redirect |
| A | api | 129.212.147.11 | 300 | API endpoint |

### Optional (if using RabbitMQ management)

| Type | Name | Value | TTL | Description |
|------|------|-------|-----|-------------|
| A | rabbitmq.rescuemesh | 129.212.147.11 | 300 | RabbitMQ UI (use subdomain) |

---

## Cloudflare Setup (Recommended)

### 1. Add DNS Records

Go to your Cloudflare dashboard → DNS → Records

Add the three A records above with "Proxied" status (orange cloud icon).

### 2. SSL/TLS Configuration

**Dashboard → SSL/TLS → Overview**
- **SSL/TLS encryption mode**: Full (strict)
- This allows Cloudflare to verify your Let's Encrypt certificate

**Dashboard → SSL/TLS → Edge Certificates**
- ✅ Always Use HTTPS: ON
- ✅ HTTP Strict Transport Security (HSTS): Enable
- ✅ Minimum TLS Version: 1.2
- ✅ Automatic HTTPS Rewrites: ON
- ✅ Certificate Transparency Monitoring: ON

### 3. Speed Optimizations

**Dashboard → Speed → Optimization**
- ✅ Auto Minify: Check HTML, CSS, JS
- ✅ Brotli: ON
- ✅ Early Hints: ON

**Dashboard → Caching → Configuration**
- Browser Cache TTL: 4 hours

### 4. Security Settings

**Dashboard → Security → Settings**
- Security Level: Medium
- Challenge Passage: 30 minutes

**Dashboard → Security → WAF**
- Enable for additional protection

### 5. Network Settings

**Dashboard → Network**
- ✅ HTTP/2: ON
- ✅ HTTP/3 (with QUIC): ON
- ✅ WebSockets: ON
- ✅ gRPC: ON

---

## Alternative: Direct DNS (Without Cloudflare)

If not using Cloudflare, add these records to your DNS provider:

### For DigitalOcean Domains

```bash
# Using doctl CLI
doctl compute domain records create villagers.live --record-type A --record-name @ --record-data 129.212.147.11 --record-ttl 300
doctl compute domain records create villagers.live --record-type A --record-name www --record-data 129.212.147.11 --record-ttl 300
doctl compute domain records create villagers.live --record-type A --record-name api --record-data 129.212.147.11 --record-ttl 300
```

### For Route53 (AWS)

Create a Route53 hosted zone and add the records via AWS Console or CLI.

### For Namecheap/GoDaddy

Go to Advanced DNS settings and add A records manually.

---

## Verification

### 1. Wait for DNS Propagation

DNS changes can take 5 minutes to 48 hours. Usually it's quick (< 30 minutes).

Check propagation:
```bash
# Check if DNS is resolving
dig villagers.live
dig www.villagers.live
dig api.villagers.live

# Or use online tools
# https://dnschecker.org/
# https://www.whatsmydns.net/
```

### 2. Test Connectivity

```bash
# Test frontend
curl -I https://villagers.live

# Test API
curl https://api.villagers.live/health

# Test specific service
curl https://api.villagers.live/users/health
```

### 3. Browser Test

Open in browser:
- https://villagers.live (Frontend)
- https://api.villagers.live/health (API Health Check)

You should see valid SSL certificates (green lock icon).

---

## SSL Certificate Status

### Check Certificates

```bash
# Check certificate resources
kubectl get certificate -n rescuemesh

# Check certificate details
kubectl describe certificate frontend-tls -n rescuemesh
kubectl describe certificate api-tls -n rescuemesh
```

### Certificate Renewal

Certificates are automatically renewed by cert-manager before expiration.

To force renewal:
```bash
kubectl delete certificate frontend-tls api-tls -n rescuemesh
kubectl apply -f k8s/ingress/ingress.yaml
```

---

## Troubleshooting DNS Issues

### DNS Not Resolving

```bash
# Clear local DNS cache (Linux)
sudo systemd-resolve --flush-caches

# Clear local DNS cache (Mac)
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder

# Check if A record exists
nslookup villagers.live
nslookup api.villagers.live
```

### SSL Certificate Not Working

```bash
# Check cert-manager is running
kubectl get pods -n cert-manager

# If not installed, install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create cluster issuer
kubectl apply -f k8s/issuer.yaml

# Check certificate challenge
kubectl describe challenge -n rescuemesh
```

### 502 Bad Gateway

```bash
# Check if backend services are running
kubectl get pods -n rescuemesh

# Check ingress controller
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Check service endpoints
kubectl get endpoints -n rescuemesh
```

---

## Load Balancer IP Changed?

If your ingress IP changes (rare, but possible):

```bash
# Get new IP
NEW_IP=$(kubectl get ingress frontend-ingress -n rescuemesh -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "New Ingress IP: $NEW_IP"

# Update DNS records with new IP
# Then wait for propagation
```

---

## Advanced: Custom Domain Mapping

If you want to use different domains for different services:

### Update Ingress

Edit `k8s/ingress/ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: custom-ingress
  namespace: rescuemesh
spec:
  rules:
  - host: app.villagers.live    # Frontend
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
  - host: api.villagers.live    # All APIs
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: user-service  # Or use a gateway service
            port:
              number: 3001
  - host: docs.villagers.live   # Documentation
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: disaster-service
            port:
              number: 3003
```

Then add DNS records for each subdomain.

---

## Quick Reference

### DNS Records (Replace IP with yours)

```
villagers.live        A    129.212.147.11
www.villagers.live    A    129.212.147.11
api.villagers.live    A    129.212.147.11
```

### Access Points

```
Frontend:  https://villagers.live
API:       https://api.villagers.live
Health:    https://api.villagers.live/health
```

### Common Commands

```bash
# Get ingress IP
kubectl get ingress -n rescuemesh -o wide

# Check DNS
dig villagers.live +short

# Test SSL
curl -I https://villagers.live

# Check certificates
kubectl get certificate -n rescuemesh
```
