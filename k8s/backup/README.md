# Velero Backup Configuration for Digital Ocean

This directory contains Velero backup configurations for disaster recovery.

## Prerequisites

1. **Digital Ocean Spaces** - Create a Space for backups
2. **Velero CLI** - Install on your local machine
3. **Access Keys** - Create DO Spaces access keys

## Installation

```bash
# Create credentials file
cat > credentials-velero <<EOF
[default]
aws_access_key_id=<YOUR_DO_SPACES_ACCESS_KEY>
aws_secret_access_key=<YOUR_DO_SPACES_SECRET_KEY>
EOF

# Install Velero
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.8.0 \
  --bucket rescuemesh-backups \
  --secret-file ./credentials-velero \
  --backup-location-config region=nyc3,s3ForcePathStyle="true",s3Url=https://nyc3.digitaloceanspaces.com \
  --snapshot-location-config region=nyc3 \
  --use-volume-snapshots=true \
  --use-node-agent
```

## Backup Schedules

The following schedules are configured:

- **Full backup**: Daily at 2 AM (30 day retention)
- **Database backup**: Every 6 hours (7 day retention)
- **Config backup**: Daily at 3 AM (90 day retention)

## Manual Backup

```bash
# Backup entire rescuemesh namespace
velero backup create rescuemesh-manual --include-namespaces rescuemesh

# Backup specific resources
velero backup create db-backup --include-namespaces rescuemesh \
  --selector app.kubernetes.io/name=postgresql
```

## Restore

```bash
# List backups
velero backup get

# Restore from backup
velero restore create --from-backup rescuemesh-daily-20240117

# Monitor restore
velero restore describe <restore-name>
```

## Verify Backups

```bash
# Check last backup
velero backup describe rescuemesh-daily --details

# Check backup logs
velero backup logs rescuemesh-daily
```
