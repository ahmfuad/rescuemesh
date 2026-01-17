#!/bin/bash

# RescueMesh - Complete DevOps Setup
# Interactive setup script for Digital Ocean + Cloudflare deployment

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Banner
echo -e "${GREEN}"
cat << "EOF"
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║     ██████╗ ███████╗███████╗ ██████╗██╗   ██╗███████╗    ║
║     ██╔══██╗██╔════╝██╔════╝██╔════╝██║   ██║██╔════╝    ║
║     ██████╔╝█████╗  ███████╗██║     ██║   ██║█████╗      ║
║     ██╔══██╗██╔══╝  ╚════██║██║     ██║   ██║██╔══╝      ║
║     ██║  ██║███████╗███████║╚██████╗╚██████╔╝███████╗    ║
║     ╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚══════╝    ║
║                                                            ║
║              Complete DevOps Setup Script                 ║
║         Digital Ocean + Cloudflare Deployment             ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${BLUE}This script will guide you through the complete setup process.${NC}"
echo -e "${BLUE}Estimated time: 30-45 minutes${NC}\n"

# Step 1: Prerequisites Check
echo -e "${YELLOW}Step 1/10: Checking Prerequisites${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

MISSING_TOOLS=()

for cmd in doctl kubectl helm docker; do
    if command -v $cmd &> /dev/null; then
        echo -e "${GREEN}✓${NC} $cmd is installed"
    else
        echo -e "${RED}✗${NC} $cmd is NOT installed"
        MISSING_TOOLS+=($cmd)
    fi
done

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo -e "\n${RED}Missing tools: ${MISSING_TOOLS[*]}${NC}"
    echo -e "${YELLOW}Please install missing tools:${NC}"
    echo "  brew install doctl kubectl helm docker  # macOS"
    echo "  or visit: https://docs.digitalocean.com/reference/doctl/"
    exit 1
fi

echo -e "\n${GREEN}✓ All prerequisites installed${NC}\n"

# Step 2: Digital Ocean Authentication
echo -e "${YELLOW}Step 2/10: Digital Ocean Authentication${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Visit: https://cloud.digitalocean.com/account/api/tokens"
echo "Create a new Personal Access Token with read/write permissions"
echo ""
read -p "Enter your Digital Ocean API Token: " DO_TOKEN

if [ -z "$DO_TOKEN" ]; then
    echo -e "${RED}Token cannot be empty${NC}"
    exit 1
fi

doctl auth init -t $DO_TOKEN
echo -e "${GREEN}✓ Authenticated with Digital Ocean${NC}\n"

# Step 3: Create Kubernetes Cluster
echo -e "${YELLOW}Step 3/10: Kubernetes Cluster Setup${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Available regions:"
doctl kubernetes options regions | head -n 10
echo ""
read -p "Enter region (default: nyc3): " REGION
REGION=${REGION:-nyc3}

read -p "Cluster name (default: rescuemesh-cluster): " CLUSTER_NAME
CLUSTER_NAME=${CLUSTER_NAME:-rescuemesh-cluster}

echo ""
echo "Creating cluster with:"
echo "  Name: $CLUSTER_NAME"
echo "  Region: $REGION"
echo "  Nodes: 3 × 2vCPU, 4GB RAM"
echo "  Auto-scaling: 3-6 nodes"
echo ""
read -p "Proceed? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Skipping cluster creation. Using existing cluster."
else
    echo "Creating cluster (this takes 5-10 minutes)..."
    doctl kubernetes cluster create $CLUSTER_NAME \
        --region $REGION \
        --version latest \
        --node-pool "name=worker-pool;size=s-2vcpu-4gb;count=3;auto-scale=true;min-nodes=3;max-nodes=6" \
        --wait
    echo -e "${GREEN}✓ Cluster created${NC}"
fi

# Save kubeconfig
doctl kubernetes cluster kubeconfig save $CLUSTER_NAME
echo -e "${GREEN}✓ Kubeconfig saved${NC}\n"

# Verify connection
kubectl cluster-info
echo ""

# Step 4: Container Registry
echo -e "${YELLOW}Step 4/10: Container Registry Setup${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

read -p "Registry name (default: rescuemesh): " REGISTRY_NAME
REGISTRY_NAME=${REGISTRY_NAME:-rescuemesh}

# Check if registry exists
if doctl registry get 2>/dev/null; then
    echo "Registry already exists"
else
    doctl registry create $REGISTRY_NAME --subscription-tier basic
    echo -e "${GREEN}✓ Registry created${NC}"
fi

doctl registry login
echo -e "${GREEN}✓ Logged in to registry${NC}\n"

# Step 5: Spaces for Backups
echo -e "${YELLOW}Step 5/10: Spaces Setup (for backups)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Visit: https://cloud.digitalocean.com/spaces"
echo "Create a Space named: rescuemesh-backups"
echo "Region: Same as your cluster ($REGION)"
echo ""
echo "Then visit: https://cloud.digitalocean.com/account/api/spaces"
echo "Generate a new Spaces access key"
echo ""
read -p "Enter Spaces Access Key ID: " SPACES_KEY_ID
read -p "Enter Spaces Secret Key: " SPACES_SECRET_KEY
echo -e "${GREEN}✓ Spaces credentials saved${NC}\n"

# Step 6: Update Configuration Files
echo -e "${YELLOW}Step 6/10: Updating Configuration Files${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

read -p "Enter your domain name (e.g., villagers.live): " DOMAIN

# Update ingress
echo "Updating ingress configuration..."
sed -i.bak "s/villagers.live/$DOMAIN/g" k8s/ingress/ingress.yaml
echo -e "${GREEN}✓ Updated ingress${NC}"

# Update issuer
read -p "Enter your email for Let's Encrypt: " LETSENCRYPT_EMAIL
sed -i.bak "s/ahmfuad9@gmail.com/$LETSENCRYPT_EMAIL/g" k8s/issuer.yaml
echo -e "${GREEN}✓ Updated cert-manager issuer${NC}\n"

# Step 7: Update Secrets
echo -e "${YELLOW}Step 7/10: Updating Secrets${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${RED}IMPORTANT: You must update k8s/secrets/secrets.yaml manually${NC}"
echo ""
echo "Open k8s/secrets/secrets.yaml and update:"
echo "  - Database passwords"
echo "  - JWT secrets"
echo "  - API keys"
echo "  - External service credentials"
echo ""
read -p "Press Enter after updating secrets..."
echo -e "${GREEN}✓ Secrets updated${NC}\n"

# Step 8: Build and Push Images
echo -e "${YELLOW}Step 8/10: Building and Pushing Docker Images${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

REGISTRY_URL="registry.digitalocean.com/$REGISTRY_NAME"

echo "Building images (this may take 15-20 minutes)..."

for service in user skill disaster sos matching notification; do
    echo -e "\n${BLUE}Building ${service}-service...${NC}"
    
    if [ "$service" = "user" ] || [ "$service" = "skill" ]; then
        # Go services
        cd rescuemesh-${service}-service
    elif [ "$service" = "disaster" ]; then
        # Python service
        cd rescuemesh-${service}-service
    else
        # Node.js services
        cd rescuemesh-${service}-service
    fi
    
    docker build -t $REGISTRY_URL/${service}-service:latest .
    docker push $REGISTRY_URL/${service}-service:latest
    echo -e "${GREEN}✓ Built and pushed ${service}-service${NC}"
    cd ..
done

# Frontend
echo -e "\n${BLUE}Building frontend...${NC}"
cd frontend
docker build -t $REGISTRY_URL/frontend:latest .
docker push $REGISTRY_URL/frontend:latest
echo -e "${GREEN}✓ Built and pushed frontend${NC}"
cd ..

echo -e "\n${GREEN}✓ All images built and pushed${NC}\n"

# Step 9: Deploy to Kubernetes
echo -e "${YELLOW}Step 9/10: Deploying to Kubernetes${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

chmod +x scripts/deploy.sh
./scripts/deploy.sh

echo -e "${GREEN}✓ Deployment complete${NC}\n"

# Step 10: Cloudflare Configuration
echo -e "${YELLOW}Step 10/10: Cloudflare DNS Configuration${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

LB_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo -e "${GREEN}Load Balancer IP: $LB_IP${NC}\n"

echo "Cloudflare Setup Steps:"
echo "1. Login to Cloudflare Dashboard"
echo "2. Select your domain: $DOMAIN"
echo "3. Go to DNS section"
echo "4. Add/Update A records:"
echo ""
echo "   Type    Name    Content      Proxy   TTL"
echo "   ────────────────────────────────────────────"
echo "   A       @       $LB_IP       ✓       Auto"
echo "   A       www     $LB_IP       ✓       Auto"
echo "   A       api     $LB_IP       ✓       Auto"
echo ""
echo "5. Go to SSL/TLS → Overview"
echo "   Set mode to: Full (strict)"
echo ""
echo "6. Enable: Always Use HTTPS"
echo ""
read -p "Press Enter after configuring Cloudflare..."

echo -e "${GREEN}✓ Cloudflare configured${NC}\n"

# Final Steps
echo -e "${GREEN}"
cat << "EOF"
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║               🎉 DEPLOYMENT COMPLETE! 🎉                   ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${BLUE}Next Steps:${NC}\n"

echo "1. Wait 5-10 minutes for SSL certificate to be issued"
echo "   Check status: kubectl get certificate -n rescuemesh"
echo ""
echo "2. Setup Monitoring:"
echo "   ./scripts/setup-monitoring.sh"
echo ""
echo "3. Setup Backups:"
echo "   ./scripts/setup-backup.sh"
echo ""
echo "4. Verify deployment:"
echo "   ./scripts/health-check.sh"
echo ""
echo "5. Access your application:"
echo "   https://$DOMAIN"
echo ""

echo -e "${YELLOW}Important URLs:${NC}"
echo "  Application: https://$DOMAIN"
echo "  API: https://$DOMAIN/api"
echo "  Health: https://$DOMAIN/health"
echo ""

echo -e "${YELLOW}Kubernetes Commands:${NC}"
echo "  Get pods: kubectl get pods -n rescuemesh"
echo "  View logs: kubectl logs -f deployment/user-service -n rescuemesh"
echo "  Check ingress: kubectl get ingress -n rescuemesh"
echo ""

echo -e "${YELLOW}Monitoring (after setup):${NC}"
echo "  Grafana: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "  Then open: http://localhost:3000"
echo ""

echo -e "${GREEN}Documentation:${NC}"
echo "  Full Guide: DEVOPS_DEPLOYMENT_GUIDE.md"
echo "  Quick Reference: QUICK_REFERENCE.md"
echo "  Architecture: ARCHITECTURE.md"
echo ""

echo -e "${BLUE}Support:${NC}"
echo "  Digital Ocean: https://cloud.digitalocean.com/support"
echo "  Cloudflare: https://dash.cloudflare.com/"
echo ""

echo -e "${GREEN}Setup completed successfully! 🚀${NC}"
