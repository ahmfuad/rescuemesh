#!/bin/bash
# Quick Setup Script for CI/CD

set -e

echo "=================================================="
echo "RescueMesh CI/CD Setup Script"
echo "=================================================="
echo ""

# Check if we're in a git repository
if [ ! -d .git ]; then
    echo "❌ Error: Not in a git repository"
    echo "Run: git init"
    exit 1
fi

# Check if GitHub remote exists
if ! git remote -v | grep -q "github.com"; then
    echo "⚠️  Warning: No GitHub remote found"
    echo "Add GitHub remote: git remote add origin https://github.com/YOUR_USERNAME/rescuemesh.git"
fi

# Get kubeconfig
echo "📋 Step 1: Preparing kubeconfig..."
if [ -f ~/.kube/config ]; then
    KUBE_CONFIG_BASE64=$(cat ~/.kube/config | base64 -w 0)
    echo "✅ Kubeconfig encoded"
else
    echo "❌ Error: ~/.kube/config not found"
    exit 1
fi

# Display secrets to set in GitHub
echo ""
echo "=================================================="
echo "📝 Step 2: Set these secrets in GitHub"
echo "=================================================="
echo ""
echo "Go to: https://github.com/YOUR_USERNAME/YOUR_REPO/settings/secrets/actions"
echo ""
echo "Add these repository secrets:"
echo ""
echo "1. DOCKER_USERNAME"
echo "   Value: kdbazizul"
echo ""
echo "2. DOCKER_PASSWORD"
echo "   Value: <your-docker-hub-password>"
echo ""
echo "3. KUBE_CONFIG"
echo "   Value: (copy from below)"
echo ""
echo "======== KUBE_CONFIG VALUE (copy this) ========"
echo "$KUBE_CONFIG_BASE64"
echo "================================================"
echo ""

# Check if workflows directory exists
if [ -d .github/workflows ]; then
    echo "✅ Step 3: Workflows already exist in .github/workflows/"
    ls -la .github/workflows/
else
    echo "❌ Error: .github/workflows/ directory not found"
    exit 1
fi

# Commit and push
echo ""
read -p "Do you want to commit and push the workflows to GitHub? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📤 Committing workflows..."
    git add .github/
    git commit -m "Add CI/CD workflows for all services"
    
    echo "📤 Pushing to GitHub..."
    git push origin main || git push origin master
    
    echo "✅ Workflows pushed to GitHub!"
fi

echo ""
echo "=================================================="
echo "✅ CI/CD Setup Complete!"
echo "=================================================="
echo ""
echo "Next steps:"
echo "1. ✅ Set the secrets in GitHub (see above)"
echo "2. Go to your GitHub repo → Actions tab"
echo "3. Enable workflows if needed"
echo "4. Make a change to any service and push to test"
echo ""
echo "Test deployment:"
echo "  - Push code: git push origin main"
echo "  - Or trigger manually: GitHub → Actions → Pick a workflow → Run workflow"
echo ""
echo "Monitor deployments:"
echo "  kubectl get pods -n rescuemesh -w"
echo ""
echo "Check health:"
echo "  curl -sk https://api.villagers.live/health"
echo ""
