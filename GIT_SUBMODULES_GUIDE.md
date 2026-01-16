# Git Submodules Setup for RescueMesh

This workspace uses Git submodules to manage independent service repositories.

## Services as Submodules

The following services are maintained as independent repositories:

1. **rescuemesh-user-service** - User & Identity Service (Go)
2. **rescuemesh-skill-service** - Skill & Resource Registry (Go)
3. **rescuemesh-disaster-service** - Disaster Event Service (Python)
4. **rescuemesh-sos-service** - Emergency Request Service (Managed by another team)
5. **rescuemesh-matching-service** - Matching Service (Managed by another team)
6. **rescuemesh-notification-service** - Notification Service (Managed by another team)

## Setting Up Submodules

### For New Team Members

If you're cloning the main repository for the first time:

```bash
# Clone with submodules
git clone --recurse-submodules <repository-url>

# Or if already cloned
git submodule update --init --recursive
```

### Adding a Service as Submodule (For Team Leads)

When a service repository is ready to be added:

```bash
# Add the submodule
git submodule add <repository-url> <service-directory>

# Example (when services are pushed to remote repos):
# git submodule add https://github.com/your-org/rescuemesh-user-service.git rescuemesh-user-service
# git submodule add https://github.com/your-org/rescuemesh-skill-service.git rescuemesh-skill-service
# git submodule add https://github.com/your-org/rescuemesh-disaster-service.git rescuemesh-disaster-service

# Commit the changes
git add .gitmodules
git commit -m "Add service submodules"
```

## Working with Submodules

### Update All Submodules to Latest
```bash
git submodule update --remote
```

### Update Specific Submodule
```bash
git submodule update --remote rescuemesh-user-service
```

### Making Changes in a Submodule
```bash
# Navigate to the submodule
cd rescuemesh-user-service

# Make your changes
# ... edit files ...

# Commit changes in the submodule
git add .
git commit -m "Update user service"
git push origin master

# Go back to main repo and commit the submodule reference update
cd ..
git add rescuemesh-user-service
git commit -m "Update user service reference"
git push
```

### Pulling Latest Changes (With Submodules)
```bash
# Pull main repo and all submodules
git pull --recurse-submodules
```

## Current Setup (Local Development)

Currently, each service is initialized as a local Git repository. To enable collaboration:

1. **Create Remote Repositories**: Each team should create a remote repository (GitHub, GitLab, etc.)
2. **Push Service Code**: Push each service to its remote repository
3. **Add as Submodules**: Use `git submodule add` to link them to the main repository

### Example: Publishing User Service

```bash
# In the user service directory
cd rescuemesh-user-service

# Add remote repository
git remote add origin https://github.com/your-team/rescuemesh-user-service.git

# Push to remote
git push -u origin master

# Back in main repo, add as submodule (after removing the directory)
cd ..
rm -rf rescuemesh-user-service
git submodule add https://github.com/your-team/rescuemesh-user-service.git rescuemesh-user-service
```

## Benefits of Submodules

✅ **Independent Development**: Each team works on their own repository
✅ **Version Control**: Lock specific versions of each service
✅ **Atomic Updates**: Update services independently
✅ **CI/CD Integration**: Each service can have its own pipeline
✅ **Access Control**: Set different permissions per service

## Alternative: Monorepo

If your team prefers a simpler setup, you can use a monorepo approach:
- Remove submodule structure
- Keep all services in a single repository
- Simpler for small teams but less flexible

## Docker Compose Integration

Regardless of Git structure, Docker Compose works the same:

```bash
# All services defined in docker-compose.yml
docker-compose up
```

## Troubleshooting

### Submodule appears as modified but no changes
```bash
git submodule update --init --recursive
```

### Submodule conflicts
```bash
cd <submodule-dir>
git checkout master
git pull
cd ..
git add <submodule-dir>
```

### Remove a submodule
```bash
git submodule deinit -f <submodule-path>
git rm -f <submodule-path>
rm -rf .git/modules/<submodule-path>
```

## Team Workflow

1. **Service Teams**: Work in their service repositories
2. **Integration Team**: Updates main repo with submodule references
3. **QA Team**: Clones main repo with all submodules for testing
4. **DevOps**: Deploys using docker-compose (services are just directories)

---

For more information, see: https://git-scm.com/book/en/v2/Git-Tools-Submodules
