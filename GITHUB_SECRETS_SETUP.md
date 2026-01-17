# GitHub Secrets Setup Guide

## Required Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

### 1. DOCKERHUB_USERNAME
```
your-dockerhub-username
```

### 2. DOCKERHUB_TOKEN
```
your-dockerhub-token-here
```

**Get token from:** https://hub.docker.com/settings/security

### 3. DIGITALOCEAN_TOKEN
```
your-digitalocean-token-here
```

**Get token from:** https://cloud.digitalocean.com/account/api/tokens

Run this command to get your kube config:
```bash
doctl kubernetes cluster kubeconfig show rescuemesh-cluster | base64 -w 0
```

Copy the entire output and paste it as the value for KUBE_CONFIG secret.

---

## How to Add Secrets

1. Go to: https://github.com/YOUR_USERNAME/YOUR_REPO/settings/secrets/actions

2. Click "New repository secret"

3. Add these 4 secrets with the exact name and value:
   - DOCKERHUB_USERNAME
   - DOCKERHUB_TOKEN
   - DIGITALOCEAN_TOKEN
   - KUBE_CONFIG

---

## Verify Setup

After adding secrets, go to:
- Actions tab → Click on any workflow → You should see them listed (values hidden)

---

## ⚠️ IMPORTANT SECURITY NOTICE

The DockerHub and DigitalOcean tokens in this file are now exposed. 
After setting up the GitHub secrets, you should:

1. Rotate DockerHub token:
   - Go to https://hub.docker.com/settings/security
   - Revoke current token
   - Create new token
   - Update GitHub secret

2. Rotate DigitalOcean token:
   - Go to https://cloud.digitalocean.com/account/api/tokens
   - Revoke current token
   - Create new token
   - Update GitHub secret

3. Delete this file after setup!
