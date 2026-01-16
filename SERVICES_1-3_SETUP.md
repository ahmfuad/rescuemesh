# Complete Setup Guide - RescueMesh Services 1-3

This guide will help you set up and run the first three microservices of the RescueMesh platform.

## 📋 Prerequisites

### Required Software
- **Docker** & **Docker Compose** (v3.8+)
- **Git** (for version control)
- **Go 1.21+** (for local development of Go services)
- **Python 3.11+** (for local development of Python service)
- **Make** (optional, for convenience commands)

### System Requirements
- RAM: 4GB minimum, 8GB recommended
- Disk Space: 10GB free
- OS: Linux, macOS, or Windows (with WSL2)

---

## 🚀 Quick Start (Docker Compose)

### 1. Clone and Navigate
```bash
cd /home/ahmf/Documents/rescuemesh
```

### 2. Start All Services
```bash
# Start all services in detached mode
docker-compose up -d

# View logs
docker-compose logs -f

# Check service status
docker-compose ps
```

### 3. Verify Health
```bash
# Check User Service
curl http://localhost:3001/health

# Check Skill Service
curl http://localhost:3002/health

# Check Disaster Service
curl http://localhost:3003/health
curl http://localhost:3003/docs  # FastAPI interactive docs
```

### 4. Stop Services
```bash
docker-compose down

# With volume cleanup
docker-compose down -v
```

---

## 🔧 Local Development Setup

### Service 1: User & Identity Service (Go)

```bash
cd rescuemesh-user-service

# Install Go dependencies
go mod download

# Run locally (requires PostgreSQL and Redis)
export DB_HOST=localhost
export DB_PORT=5431
export DB_NAME=rescuemesh_users
export REDIS_HOST=localhost
export REDIS_PORT=6371

go run main.go

# Or build and run
go build -o user-service
./user-service
```

**Testing Endpoints:**
```bash
# Get user
curl http://localhost:3001/api/users/user-001

# Update location
curl -X PUT http://localhost:3001/api/users/user-001/location \
  -H "Content-Type: application/json" \
  -d '{"latitude": 28.6139, "longitude": 77.2090}'

# Batch query
curl -X POST http://localhost:3001/api/users/batch \
  -H "Content-Type: application/json" \
  -d '{"userIds": ["user-001", "user-002"]}'
```

---

### Service 2: Skill & Resource Registry (Go)

```bash
cd rescuemesh-skill-service

# Install Go dependencies
go mod download

# Run locally
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=rescuemesh_skills
export REDIS_HOST=localhost
export REDIS_PORT=6372

go run main.go
```

**Testing Endpoints:**
```bash
# Query skills for flood disaster
curl "http://localhost:3002/api/skills?disasterType=flood&location=28.6139,77.2090&radius=10"

# Get disaster template
curl http://localhost:3002/api/disaster-templates/flood

# Query resources
curl "http://localhost:3002/api/resources?disasterType=flood"

# Update skill availability
curl -X PUT http://localhost:3002/api/skills/skill-001/availability \
  -H "Content-Type: application/json" \
  -d '{"availability": "busy"}'
```

---

### Service 3: Disaster Event Service (Python)

```bash
cd rescuemesh-disaster-service

# Create virtual environment
python -m venv venv

# Activate virtual environment
source venv/bin/activate  # Linux/Mac
# or
venv\Scripts\activate     # Windows

# Install dependencies
pip install -r requirements.txt

# Run locally
export DB_HOST=localhost
export DB_PORT=5433
export DB_NAME=rescuemesh_disasters

# Run with uvicorn
uvicorn main:app --reload --port 3003

# Or run directly
python main.py
```

**Testing Endpoints:**
```bash
# Get active disasters
curl http://localhost:3003/api/disasters/active

# Get disaster by ID
curl http://localhost:3003/api/disasters/disaster-001

# Create new disaster
curl -X POST http://localhost:3003/api/disasters \
  -H "Content-Type: application/json" \
  -d '{
    "disasterId": "disaster-004",
    "disasterType": "fire",
    "severity": "high",
    "impactArea": {
      "latitude": 28.5,
      "longitude": 77.1,
      "radius": 15.0
    },
    "affectedPopulation": 10000,
    "description": "Major fire in industrial area"
  }'

# Get disaster statistics
curl http://localhost:3003/api/disasters/types/stats

# Interactive API docs (FastAPI)
# Open in browser: http://localhost:3003/docs
```

---

## 🐳 Docker Commands Reference

### Build Services
```bash
# Build all services
docker-compose build

# Build specific service
docker-compose build user-service
docker-compose build skill-service
docker-compose build disaster-service

# Build without cache
docker-compose build --no-cache
```

### Service Management
```bash
# Start services
docker-compose up user-service skill-service disaster-service

# Start in detached mode
docker-compose up -d

# Restart specific service
docker-compose restart user-service

# Stop specific service
docker-compose stop user-service

# View logs
docker-compose logs -f user-service
docker-compose logs --tail=100 skill-service
```

### Database & Volume Management
```bash
# View volumes
docker volume ls | grep rescuemesh

# Remove volumes (WARNING: deletes data)
docker-compose down -v

# Inspect volume
docker volume inspect rescuemesh_postgres-users-data
```

### Network & Debugging
```bash
# List networks
docker network ls | grep rescuemesh

# Inspect network
docker network inspect rescuemesh-network

# Execute command in container
docker-compose exec user-service /bin/sh
docker-compose exec postgres-users psql -U postgres -d rescuemesh_users

# View container details
docker inspect user-service
```

---

## 🗄️ Database Access

### PostgreSQL Databases

**User Service Database:**
```bash
# Connect to database
docker-compose exec postgres-users psql -U postgres -d rescuemesh_users

# Query users
SELECT * FROM users;

# Check indexes
\di
```

**Skill Service Database:**
```bash
docker-compose exec postgres-skills psql -U postgres -d rescuemesh_skills

# Query skills
SELECT * FROM skills;
SELECT * FROM resources;
```

**Disaster Service Database:**
```bash
docker-compose exec postgres-disasters psql -U postgres -d rescuemesh_disasters

# Query disasters
SELECT * FROM disasters WHERE status = 'active';
```

### Redis Access

```bash
# Connect to User Redis
docker-compose exec redis-users redis-cli

# Check cached data
KEYS user:*
GET user:user-001

# Monitor Redis commands
MONITOR
```

---

## 📊 Service Ports & URLs

| Service | Port | Health Check | API Docs |
|---------|------|--------------|----------|
| User Service | 3001 | http://localhost:3001/health | - |
| Skill Service | 3002 | http://localhost:3002/health | - |
| Disaster Service | 3003 | http://localhost:3003/health | http://localhost:3003/docs |
| PostgreSQL (Users) | 5431 | - | - |
| PostgreSQL (Skills) | 5432 | - | - |
| PostgreSQL (Disasters) | 5433 | - | - |
| Redis (Users) | 6371 | - | - |
| Redis (Skills) | 6372 | - | - |
| Redis (Disasters) | 6373 | - | - |
| RabbitMQ | 5672 | - | http://localhost:15672 |
| API Gateway | 8000 | - | - |

---

## 🧪 Testing the Integration

### End-to-End Scenario: Flood Disaster

```bash
# 1. Check active disasters
curl http://localhost:3003/api/disasters/active | jq

# 2. Find available skills for flood
curl "http://localhost:3002/api/skills?disasterType=flood&location=28.6139,77.2090&radius=50" | jq

# 3. Get user details for a volunteer
curl http://localhost:3001/api/users/user-001 | jq

# 4. Get disaster-specific requirements
curl http://localhost:3002/api/disaster-templates/flood | jq
```

---

## 🔍 Troubleshooting

### Common Issues

**1. Port Already in Use**
```bash
# Find process using port
lsof -i :3001
sudo netstat -tulpn | grep 3001

# Kill process
kill -9 <PID>
```

**2. Database Connection Failed**
```bash
# Check if database is healthy
docker-compose ps

# Restart database
docker-compose restart postgres-users

# View database logs
docker-compose logs postgres-users
```

**3. Go Dependencies Issues**
```bash
cd rescuemesh-user-service
go mod tidy
go mod download
```

**4. Python Package Issues**
```bash
cd rescuemesh-disaster-service
pip install --upgrade pip
pip install -r requirements.txt --force-reinstall
```

**5. Docker Build Fails**
```bash
# Clean build
docker-compose down
docker system prune -a
docker-compose build --no-cache
```

---

## 🔐 Environment Variables

Create `.env` file in root directory:

```env
# Database
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres

# RabbitMQ
RABBITMQ_DEFAULT_USER=admin
RABBITMQ_DEFAULT_PASS=admin

# Service URLs (for local development)
USER_SERVICE_URL=http://localhost:3001
SKILL_SERVICE_URL=http://localhost:3002
DISASTER_SERVICE_URL=http://localhost:3003
```

---

## 📚 API Documentation

### User Service (Go + Gin)
- Health: `GET /health`
- Get User: `GET /api/users/:userId`
- Get Location: `GET /api/users/:userId/location`
- Batch Users: `POST /api/users/batch`
- Update Location: `PUT /api/users/:userId/location`
- Create User: `POST /api/users`

### Skill Service (Go + Gin)
- Health: `GET /health`
- Query Skills: `GET /api/skills?disasterType=&location=&radius=`
- Query Resources: `GET /api/resources?disasterType=&location=&radius=`
- Get Template: `GET /api/disaster-templates/:disasterType`
- Update Availability: `PUT /api/skills/:skillId/availability`

### Disaster Service (Python + FastAPI)
- Health: `GET /health`
- Active Disasters: `GET /api/disasters/active`
- Get Disaster: `GET /api/disasters/:disasterId`
- Nearby Disasters: `GET /api/disasters/nearby?latitude=&longitude=&radius=`
- Create Disaster: `POST /api/disasters`
- Update Disaster: `PUT /api/disasters/:disasterId`
- Statistics: `GET /api/disasters/types/stats`
- **Interactive Docs**: http://localhost:3003/docs

---

## 🚀 Production Deployment Checklist

- [ ] Change default passwords
- [ ] Enable HTTPS/TLS
- [ ] Set up proper logging
- [ ] Configure monitoring (Prometheus/Grafana)
- [ ] Set resource limits in docker-compose
- [ ] Enable Redis persistence
- [ ] Set up database backups
- [ ] Configure firewall rules
- [ ] Enable RabbitMQ authentication
- [ ] Set up CI/CD pipeline
- [ ] Load testing
- [ ] Security scanning

---

## 📞 Support & Resources

- **API Contracts**: See `API_CONTRACTS.md`
- **Git Submodules**: See `GIT_SUBMODULES_GUIDE.md`
- **Architecture**: See `PROJECT_SUMMARY.md`
- **Tech Stack**: See `TECH_STACK_EXPLANATION.md`

---

## 🎯 Next Steps

After setting up services 1-3:
1. Test all endpoints thoroughly
2. Integrate with services 4-6 (SOS, Matching, Notification)
3. Set up monitoring and logging
4. Prepare demo scenarios for hackathon
5. Create Postman/Newman test collections

---

**Happy Coding! 🚀**
