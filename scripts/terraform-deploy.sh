#!/bin/bash

# Terraform Deployment Script for RescueMesh
# Automates infrastructure provisioning

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}"
cat << "EOF"
╔════════════════════════════════════════════════════════════╗
║     Terraform Infrastructure Deployment                    ║
║     RescueMesh on Digital Ocean                            ║
╚════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Get environment
echo -e "${YELLOW}Select environment:${NC}"
echo "1) Production"
echo "2) Staging"
read -p "Choice (1 or 2): " ENV_CHOICE

if [ "$ENV_CHOICE" == "1" ]; then
    ENVIRONMENT="production"
    TFVARS_FILE="terraform.tfvars"
elif [ "$ENV_CHOICE" == "2" ]; then
    ENVIRONMENT="staging"
    TFVARS_FILE="staging.tfvars"
else
    echo -e "${RED}Invalid choice${NC}"
    exit 1
fi

echo -e "\n${BLUE}Deploying to: $ENVIRONMENT${NC}\n"

# Check if required tools are installed
command -v terraform >/dev/null 2>&1 || { echo -e "${RED}Terraform is not installed${NC}"; exit 1; }
command -v doctl >/dev/null 2>&1 || { echo -e "${RED}doctl is not installed${NC}"; exit 1; }

# Check for required environment variables
if [ -z "$TF_VAR_do_token" ]; then
    read -sp "Enter Digital Ocean API Token: " TF_VAR_do_token
    export TF_VAR_do_token
    echo ""
fi

if [ -z "$TF_VAR_cloudflare_api_token" ]; then
    read -sp "Enter Cloudflare API Token: " TF_VAR_cloudflare_api_token
    export TF_VAR_cloudflare_api_token
    echo ""
fi

if [ -z "$TF_VAR_cloudflare_zone_id" ]; then
    read -p "Enter Cloudflare Zone ID: " TF_VAR_cloudflare_zone_id
    export TF_VAR_cloudflare_zone_id
fi

# Generate secure passwords if not set
if [ -z "$TF_VAR_postgres_password" ]; then
    TF_VAR_postgres_password=$(openssl rand -base64 32)
    export TF_VAR_postgres_password
    echo -e "${YELLOW}Generated PostgreSQL password${NC}"
fi

if [ -z "$TF_VAR_redis_password" ]; then
    TF_VAR_redis_password=$(openssl rand -base64 32)
    export TF_VAR_redis_password
    echo -e "${YELLOW}Generated Redis password${NC}"
fi

if [ -z "$TF_VAR_jwt_secret" ]; then
    TF_VAR_jwt_secret=$(openssl rand -base64 64)
    export TF_VAR_jwt_secret
    echo -e "${YELLOW}Generated JWT secret${NC}"
fi

# Save generated secrets
mkdir -p .secrets
cat > .secrets/${ENVIRONMENT}-secrets.env << EOF
export TF_VAR_postgres_password="${TF_VAR_postgres_password}"
export TF_VAR_redis_password="${TF_VAR_redis_password}"
export TF_VAR_jwt_secret="${TF_VAR_jwt_secret}"
EOF
chmod 600 .secrets/${ENVIRONMENT}-secrets.env
echo -e "${GREEN}✓ Secrets saved to .secrets/${ENVIRONMENT}-secrets.env${NC}"

cd terraform

# Initialize Terraform
echo -e "\n${YELLOW}Step 1: Initializing Terraform...${NC}"
terraform init -upgrade
echo -e "${GREEN}✓ Terraform initialized${NC}"

# Validate configuration
echo -e "\n${YELLOW}Step 2: Validating configuration...${NC}"
terraform validate
echo -e "${GREEN}✓ Configuration valid${NC}"

# Format code
terraform fmt -recursive

# Create plan
echo -e "\n${YELLOW}Step 3: Creating execution plan...${NC}"
terraform plan -var-file="$TFVARS_FILE" -out=tfplan
echo -e "${GREEN}✓ Plan created${NC}"

# Review plan
echo -e "\n${YELLOW}Review the plan above${NC}"
read -p "Do you want to apply this plan? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${RED}Deployment cancelled${NC}"
    exit 0
fi

# Apply changes
echo -e "\n${YELLOW}Step 4: Applying changes...${NC}"
terraform apply tfplan
echo -e "${GREEN}✓ Infrastructure deployed${NC}"

# Save outputs
echo -e "\n${YELLOW}Step 5: Saving outputs...${NC}"
terraform output -json > ../outputs/${ENVIRONMENT}-outputs.json
terraform output > ../outputs/${ENVIRONMENT}-outputs.txt

# Get important values
KUBECONFIG_PATH=$(terraform output -raw kubeconfig_path)
LB_IP=$(terraform output -raw load_balancer_ip)
REGISTRY_ENDPOINT=$(terraform output -raw container_registry_endpoint)

echo -e "${GREEN}✓ Outputs saved${NC}"

# Configure kubectl
echo -e "\n${YELLOW}Step 6: Configuring kubectl...${NC}"
export KUBECONFIG=$KUBECONFIG_PATH
kubectl get nodes
echo -e "${GREEN}✓ kubectl configured${NC}"

# Final summary
echo -e "\n${GREEN}"
cat << EOF
╔════════════════════════════════════════════════════════════╗
║              Deployment Successful!                        ║
╚════════════════════════════════════════════════════════════╝

Environment: $ENVIRONMENT
Load Balancer IP: $LB_IP
Container Registry: $REGISTRY_ENDPOINT

Outputs saved to:
  - outputs/${ENVIRONMENT}-outputs.json
  - outputs/${ENVIRONMENT}-outputs.txt

Secrets saved to:
  - .secrets/${ENVIRONMENT}-secrets.env

Kubeconfig:
  export KUBECONFIG=$KUBECONFIG_PATH

Next steps:
1. Build and push Docker images
2. Deploy Kubernetes applications
3. Setup monitoring
4. Configure backups

See terraform/outputs.tf for detailed next steps.
EOF
echo -e "${NC}"

# Ask about next steps
read -p "Do you want to deploy applications now? (yes/no): " DEPLOY_APPS

if [ "$DEPLOY_APPS" == "yes" ]; then
    cd ..
    ./scripts/deploy.sh
fi
