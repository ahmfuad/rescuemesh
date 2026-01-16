# 🎯 QUICK START GUIDE - RescueMesh Services 1-3

## ✅ What You Have Now

Three fully functional microservices:

1. **User & Identity Service** (Go + Gin) - Port 3001
2. **Skill & Resource Registry** (Go + Gin) - Port 3002  
3. **Disaster Event Service** (Python + FastAPI) - Port 3003

## 🚀 Starting the Services

### Recommended: Docker Compose (All Services)

```bash
cd /home/ahmf/Documents/rescuemesh

# Start all services + databases + gateway
docker-compose up -d

# View logs
docker-compose logs -f

# Check status
docker-compose ps

# Test via API Gateway
./test-gateway.sh
```

**Access Points:**
- **API Gateway**: http://localhost:8000 (Unified entry point) ⭐
- **Gateway Dashboard**: http://localhost:8000/ (Web interface)
- **API Docs**: http://localhost:8000/docs (Interactive Swagger)
- **Individual Services**: 3001-3006 (Direct access for development)

### Option 2: Individual Services (Development)

**Terminal 1 - User Service:**
```bash
cd /home/ahmf/Documents/rescuemesh/rescuemesh-user-service
go run main.go
```

**Terminal 2 - Skill Service:**
```bash
cd /home/ahmf/Documents/rescuemesh/rescuemesh-skill-service
go run main.go
```

**Terminal 3 - Disaster Service:**
```bash
cd /home/ahmf/Documents/rescuemesh/rescuemesh-disaster-service
pip install -r requirements.txt
python main.py
```

## 🧪 Testing the Services

### Quick Health Check (via Gateway)
```bash
# Gateway health
curl http://localhost:8000/health

# Individual service health
curl http://localhost:8000/health/user
curl http://localhost:8000/health/skill
curl http://localhost:8000/health/disaster
```

### Run Automated Gateway Tests
```bash
cd /home/ahmf/Documents/rescuemesh
./test-gateway.sh
```

### Interactive Dashboard
Open in browser: **http://localhost:8000/** (Gateway landing page with all services)

### Interactive API Documentation
Open in browser: **http://localhost:8000/docs** (FastAPI Swagger UI via Gateway)

## 📋 Sample API Calls

### ⭐ Through API Gateway (Recommended for Production)

**Get Active Disasters:**
```bash
curl http://localhost:8000/api/disasters/active | jq
```

**Find Flood Skills:**
```bash
curl "http://localhost:8000/api/skills?disasterType=flood&location=28.6,77.2&radius=50" | jq
```

**Get User Details:**
```bash
curl http://localhost:8000/api/users/user-001 | jq
```

**Get Disaster Template:**
```bash
curl http://localhost:8000/api/disaster-templates/flood | jq
```

**Batch User Query:**
```bash
curl -X POST http://localhost:8000/api/users/batch \
  -H "Content-Type: application/json" \
  -d '{"userIds": ["user-001", "user-002"]}' | jq
```

### Direct Service Access (Development Only)

**User Service:**
```bash
curl http://localhost:3001/api/users/user-001 | jq
```

**Skill Service:**
```bash
curl "http://localhost:3002/api/skills?disasterType=flood" | jq
```

**Disaster Service:**
```bash
curl http://localhost:3003/api/disasters/active | jq
```

## 📊 Service Ports

| Service | Direct Port | Gateway URL | Status |
|---------|-------------|-------------|--------|
| **API Gateway** | **8000** | **http://localhost:8000** | **⭐ Main Entry** |
| User Service | 3001 | /api/users/ | ✅ Active |
| Skill Service | 3002 | /api/skills/, /api/resources/ | ✅ Active |
| Disaster Service | 3003 | /api/disasters/ | ✅ Active |
| SOS Service | 3004 | /api/sos/ | 🔄 In Dev |
| Matching Service | 3005 | /api/matching/ | 🔄 In Dev |
| Notification Service | 3006 | /api/notifications/ | 🔄 In Dev |
| RabbitMQ UI | 15672 | http://localhost:15672 | ✅ Active |

## 🗄️ Database Access

```bash
# User database
docker-compose exec postgres-users psql -U postgres -d rescuemesh_users

# Skill database
docker-compose exec postgres-skills psql -U postgres -d rescuemesh_skills

# Disaster database
docker-compose exec postgres-disasters psql -U postgres -d rescuemesh_disasters
```

## 🔧 Troubleshooting

### Services not starting?
```bash
# Check Docker status
docker-compose ps

# View logs
docker-compose logs <service-name>

# Restart a service
docker-compose restart <service-name>
```

### Port conflicts?
```bash
# Check what's using a port
sudo lsof -i :3001
sudo netstat -tulpn | grep 3001

# Kill process
kill -9 <PID>
```

### Database issues?
```bash
# Recreate databases
docker-compose down -v
docker-compose up -d
```

## 📚 Documentation Files

- **IMPLEMENTATION_SUMMARY.md** - What was built
- **SERVICES_1-3_SETUP.md** - Detailed setup guide
- **API_CONTRACTS.md** - API documentation
- **GIT_SUBMODULES_GUIDE.md** - Git workflow
- **README.md** - Project overview

## 🎯 Next Steps

### For Your Team (Services 4-6):
1. **SOS Service** - Emergency requests
2. **Matching Service** - Match volunteers to requests
3. **Notification Service** - Send alerts

### Integration Points:
Your services can call these endpoints:
- `GET http://user-service:3001/api/users/{userId}`
- `GET http://skill-service:3002/api/skills?disasterType=flood`
- `GET http://disaster-service:3003/api/disasters/active`

## 💡 Demo Scenario

### Complete End-to-End Flow via Gateway

```bash
# 1. Check gateway health
curl http://localhost:8000/health

# 2. View active disasters
curl http://localhost:8000/api/disasters/active | jq

# 3. Get flood disaster requirements
curl http://localhost:8000/api/disaster-templates/flood | jq

# 4. Find available boat operators near disaster
DISASTER_LAT=28.6139
DISASTER_LNG=77.2090
curl "http://localhost:8000/api/skills?disasterType=flood&location=$DISASTER_LAT,$DISASTER_LNG&radius=50" | jq

# 5. Get volunteer details
curl http://localhost:8000/api/users/user-001 | jq

# 6. Create SOS request (Service 4 - when implemented)
# curl -X POST http://localhost:8000/api/sos/requests ...
```

### Interactive Web Dashboard

1. Open http://localhost:8000 in your browser
2. View all services and their status
3. Click on API documentation links
4. Test endpoints interactively via Swagger UI

## 🐛 Common Issues

**"connection refused"** → Services not running
```bash
docker-compose up -d
```

**"database does not exist"** → Databases need initialization
```bash
docker-compose down -v
docker-compose up -d
# Wait 30 seconds for initialization
```

**Go modules error** → Dependencies not downloaded
```bash
cd rescuemesh-user-service
go mod download
```

**Python packages missing** → Install requirements
```bash
cd rescuemesh-disaster-service
pip install -r requirements.txt
```

## ✅ Success Indicators

When everything is working:
- ✅ Gateway returns HTTP 200 at http://localhost:8000/health
- ✅ All service health checks pass via /health/* endpoints
- ✅ Dashboard loads at http://localhost:8000/
- ✅ API docs accessible at http://localhost:8000/docs
- ✅ Sample data is visible via gateway API calls
- ✅ No errors in `docker-compose logs`
- ✅ Cross-service integration tests pass

### Quick Validation
```bash
# Run complete gateway test suite
./test-gateway.sh

# Should show: "🎉 All gateway tests passed!"
```

## 🎉 You're Ready!

Your three services are fully implemented and ready to integrate with services 4-6!

---

**Need Help?** Check the detailed documentation:
- `API_GATEWAY.md` for gateway configuration and usage
- `SERVICES_1-3_SETUP.md` for comprehensive setup
- `IMPLEMENTATION_SUMMARY.md` for what's been built
- `API_CONTRACTS.md` for API specifications
