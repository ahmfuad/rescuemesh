#!/bin/bash

# RescueMesh Velero Backup Setup Script
# Installs and configures Velero for disaster recovery

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Installing Velero Backup System${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if Velero CLI is installed
if ! command -v velero &> /dev/null; then
    echo -e "${RED}Error: Velero CLI is not installed${NC}"
    echo "Install it with:"
    echo "  brew install velero  # macOS"
    echo "  or download from: https://velero.io/docs/main/basic-install/"
    exit 1
fi

# Prompt for DO Spaces credentials
echo -e "\n${YELLOW}Enter Digital Ocean Spaces credentials:${NC}"
read -p "Access Key ID: " DO_ACCESS_KEY
read -sp "Secret Access Key: " DO_SECRET_KEY
echo ""
read -p "Spaces Region (default: nyc3): " DO_REGION
DO_REGION=${DO_REGION:-nyc3}
read -p "Bucket Name (default: rescuemesh-backups): " BUCKET_NAME
BUCKET_NAME=${BUCKET_NAME:-rescuemesh-backups}

# Create credentials file
echo -e "\n${YELLOW}Creating credentials file...${NC}"
cat > /tmp/credentials-velero <<EOF
[default]
aws_access_key_id=${DO_ACCESS_KEY}
aws_secret_access_key=${DO_SECRET_KEY}
EOF
echo -e "${GREEN}✓${NC} Credentials file created"

# Install Velero
echo -e "\n${YELLOW}Installing Velero...${NC}"
velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.8.0 \
    --bucket ${BUCKET_NAME} \
    --secret-file /tmp/credentials-velero \
    --backup-location-config region=${DO_REGION},s3ForcePathStyle="true",s3Url=https://${DO_REGION}.digitaloceanspaces.com \
    --snapshot-location-config region=${DO_REGION} \
    --use-volume-snapshots=true \
    --use-node-agent \
    --wait

echo -e "${GREEN}✓${NC} Velero installed"

# Clean up credentials file
rm /tmp/credentials-velero

# Apply backup schedules
echo -e "\n${YELLOW}Applying backup schedules...${NC}"
kubectl apply -f k8s/backup/backup-schedules.yaml
echo -e "${GREEN}✓${NC} Backup schedules applied"

# Verify installation
echo -e "\n${YELLOW}Verifying installation...${NC}"
velero version
kubectl get pods -n velero

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Velero Backup System Installed!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Backup Schedules:${NC}"
echo "- Full backup: Daily at 2 AM (30 day retention)"
echo "- Database backup: Every 6 hours (7 day retention)"
echo "- Config backup: Daily at 3 AM (90 day retention)"
echo "- Weekly backup: Sunday at 1 AM (180 day retention)"
echo ""
echo -e "${YELLOW}Useful Commands:${NC}"
echo "  velero backup get"
echo "  velero backup describe <backup-name>"
echo "  velero backup logs <backup-name>"
echo "  velero restore create --from-backup <backup-name>"
