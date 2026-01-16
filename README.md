# RescueMesh - Unified Disaster Coordination Platform

> **"Right skill. Right place. Right time."**

A microservices-based disaster response platform with unified API Gateway.

## 🎯 Project Status

### ✅ Implemented Services (3/6)
- **Service 1**: User & Identity Service (Go + Gin)
- **Service 2**: Skill & Resource Registry (Go + Gin)
- **Service 3**: Disaster Event Service (Python + FastAPI)
- **API Gateway**: nginx reverse proxy (unified entry point)
- **Infrastructure**: PostgreSQL, Redis, RabbitMQ

### 🔄 In Development (3/6)
- **Service 4**: SOS Emergency Request Service
- **Service 5**: Intelligent Matching Service
- **Service 6**: Notification & Communication Service

---

## 🚀 Quick Start

```bash
# Start all services via Docker Compose
docker-compose up -d

# Access via unified API Gateway
curl http://localhost:8000/health

# View interactive dashboard
open http://localhost:8000

# Run automated tests
./test-gateway.sh
```

**Main Access Points:**
- 🌐 **API Gateway**: http://localhost:8000 (Single unified entry point)
- 📊 **Dashboard**: http://localhost:8000/ (Service status and quick links)
- 📖 **API Docs**: http://localhost:8000/docs (Interactive Swagger UI)
- 🧪 **Tests**: `./test-gateway.sh` (Automated validation)

---

## 📐 Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     API Gateway (nginx)                  │
│                   Port 8000 - Single Entry               │
│  ┌──────────┬──────────┬──────────┬─────┬─────┬────────┐│
│  │  Users   │  Skills  │ Disasters│ SOS │Match│ Notify ││
│  │ :3001    │  :3002   │  :3003   │:3004│:3005│ :3006  ││
│  └──────────┴──────────┴──────────┴─────┴─────┴────────┘│
└─────────────────────────────────────────────────────────┘
           │          │          │          │          │
           ▼          ▼          ▼          ▼          ▼
    ┌──────────┬──────────┬──────────┬──────────┬──────────┐
    │PostgreSQL│PostgreSQL│PostgreSQL│PostgreSQL│PostgreSQL│
    │  :5431   │  :5432   │  :5433   │  :5434   │  :5435   │
    └──────────┴──────────┴──────────┴──────────┴──────────┘
    
    ┌──────────┬──────────┬──────────┬──────────┬──────────┐
    │  Redis   │  Redis   │  Redis   │  Redis   │  Redis   │
    │  :6371   │  :6372   │  :6373   │  :6374   │  :6375   │
    └──────────┴──────────┴──────────┴──────────┴──────────┘
    
    ┌────────────────────────────────────────────────────┐
    │              RabbitMQ Message Queue                │
    │                   Port 5672                        │
    └────────────────────────────────────────────────────┘
```

**Key Features:**
- ✅ Unified API Gateway with rate limiting
- ✅ Service isolation with independent databases
- ✅ Redis caching per service
- ✅ RabbitMQ for async communication
- ✅ Health monitoring and CORS support
- ✅ Docker Compose orchestration

---

## 🛠 Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Services 1-2** | Go 1.21 + Gin | High performance, simple APIs |
| **Service 3** | Python 3.11 + FastAPI | Auto-docs, async support |
| **API Gateway** | nginx | Rate limiting, CORS, routing |
| **Databases** | PostgreSQL 15 | Structured data, geospatial |
| **Cache** | Redis 7 | Performance, sessions |
| **Message Queue** | RabbitMQ 3 | Async communication |
| **Container** | Docker + Compose | Orchestration |

---

## 📦 Services Overview

### Service 1: User & Identity Service ✅
**Status**: Implemented (Go + Gin)  
**Port**: 3001 | **Gateway**: `/api/users/*`  
**Features**:
- User profile management with Redis caching
- Real-time location tracking
- Trust score system
- Batch operations for performance
- Role-based access (volunteer, victim, authority)

### Service 2: Skill & Resource Registry ✅
**Status**: Implemented (Go + Gin)  
**Port**: 3002 | **Gateway**: `/api/skills/*`, `/api/resources/*`, `/api/disaster-templates/*`  
**Features**:
- Skills database with disaster-type filtering
- Resource inventory with availability tracking
- Disaster templates (6 types: flood, earthquake, cyclone, fire, tsunami, landslide)
- Geographic search with Haversine distance calculation
- Dynamic skill availability updates

### Service 3: Disaster Event Service ✅
**Status**: Implemented (Python + FastAPI)  
**Port**: 3003 | **Gateway**: `/api/disasters/*`  
**Features**:
- Active disaster tracking
- Geospatial impact area management
- Severity monitoring (critical/high/medium/low)
- Statistics by disaster type
- Auto-generated API documentation (Swagger/ReDoc)

### Service 4: SOS Service 🔄
**Status**: Pending Implementation  
**Port**: 3004 | **Gateway**: `/api/sos/*`  
**Planned**: Emergency request handling, priority queue, multi-channel alerts

### Service 5: Matching Service 🔄
**Status**: Pending Implementation  
**Port**: 3005 | **Gateway**: `/api/matching/*`  
**Planned**: Algorithm-based volunteer-victim matching, skill-resource optimization

### Service 6: Notification Service 🔄
**Status**: Pending Implementation  
**Port**: 3006 | **Gateway**: `/api/notifications/*`  
**Planned**: Multi-channel notifications (SMS, Push, Email), message queue integration

---

## 📁 Project Structure

```
rescuemesh/
├── rescuemesh-user-service/         # Service 1 ✅ (Go + Gin)
│   ├── main.go
│   ├── config/
│   ├── database/
│   ├── handlers/
│   ├── models/
│   ├── routes/
│   ├── Dockerfile
│   └── README.md
├── rescuemesh-skill-service/        # Service 2 ✅ (Go + Gin)
│   ├── main.go
│   ├── config/
│   ├── database/
│   ├── handlers/
│   ├── models/
│   ├── routes/
│   ├── Dockerfile
│   └── README.md
├── rescuemesh-disaster-service/     # Service 3 ✅ (Python + FastAPI)
│   ├── main.py
│   ├── config.py
│   ├── database.py
│   ├── models.py
│   ├── requirements.txt
│   ├── Dockerfile
│   └── README.md
├── rescuemesh-sos-service/          # Service 4 🔄 (Placeholder)
├── rescuemesh-matching-service/     # Service 5 🔄 (Placeholder)
├── rescuemesh-notification-service/ # Service 6 🔄 (Placeholder)
├── api-gateway/
│   └── nginx.conf                   # Unified API Gateway ✅
├── docker-compose.yml               # Full orchestration ✅
├── test-gateway.sh                  # Gateway tests ✅
├── test-services.sh                 # Service tests ✅
├── API_CONTRACTS.md                 # API specifications ✅
├── API_GATEWAY.md                   # Gateway documentation ✅
├── QUICKSTART.md                    # Quick reference ✅
├── IMPLEMENTATION_SUMMARY.md        # Feature details ✅
├── GIT_SUBMODULES_GUIDE.md         # Git workflow ✅
├── SETUP_GUIDE.md                   # Comprehensive setup ✅
├── TECH_STACK_EXPLANATION.md        # Tech decisions ✅
└── README.md                        # This file
```

---

## 🔌 API Gateway Routes

All services are accessible through the unified gateway at port 8000:

| Service | Direct Port | Gateway Route | Rate Limit |
|---------|-------------|---------------|------------|
| User Service | 3001 | `/api/users/*` | 20 req/s |
| Skill Service | 3002 | `/api/skills/*`, `/api/resources/*`, `/api/disaster-templates/*` | 20 req/s |
| Disaster Service | 3003 | `/api/disasters/*` | 15 req/s |
| SOS Service | 3004 | `/api/sos/*` | 10 req/s |
| Matching Service | 3005 | `/api/matching/*` | 10 req/s |
| Notification Service | 3006 | `/api/notifications/*` | 5 req/s |

**Special Routes:**
- `/` - Interactive dashboard
- `/health` - Gateway health
- `/health/{service}` - Individual service health
- `/docs` - FastAPI Swagger UI
- `/redoc` - FastAPI ReDoc

---

## 🧪 Testing

### Automated Gateway Tests
```bash
./test-gateway.sh
# Tests: Gateway health, service routing, integration, CORS
```

### Manual API Testing
```bash
# Via Gateway (Recommended)
curl http://localhost:8000/api/disasters/active | jq
curl http://localhost:8000/api/users/user-001 | jq
curl "http://localhost:8000/api/skills?disasterType=flood" | jq

# Direct Service Access (Development)
curl http://localhost:3001/health
curl http://localhost:3002/health
curl http://localhost:3003/health
```

### Interactive Documentation
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **Dashboard**: http://localhost:8000/

---

## 📊 Database Ports

| Service | PostgreSQL | Redis |
|---------|------------|-------|
| User Service | 5431 | 6371 |
| Skill Service | 5432 | 6372 |
| Disaster Service | 5433 | 6373 |
| SOS Service | 5434 | 6374 |
| Matching Service | 5435 | 6375 |
| Notification Service | 5436 | 6376 |

**RabbitMQ**:
- AMQP: 5672
- Management UI: http://localhost:15672 (guest/guest)

---

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [QUICKSTART.md](QUICKSTART.md) | ⚡ Quick reference to start services and test via gateway |
| [API_GATEWAY.md](API_GATEWAY.md) | 🌐 Complete API Gateway documentation and routing |
| [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) | 📋 Detailed feature list and schemas |
| [API_CONTRACTS.md](API_CONTRACTS.md) | 📖 Complete API specifications for all services |
| [SETUP_GUIDE.md](SETUP_GUIDE.md) | 🔧 Comprehensive setup instructions |
| [GIT_SUBMODULES_GUIDE.md](GIT_SUBMODULES_GUIDE.md) | 🔀 Git workflow and submodule management |
| [TECH_STACK_EXPLANATION.md](TECH_STACK_EXPLANATION.md) | 💡 Technology choices explained |

---

## 🔄 Git Structure

Each service is an independent Git repository:

```bash
# Initialize submodules (for new clones)
git submodule init
git submodule update

# Or clone with submodules
git clone --recurse-submodules <repo-url>
```

See [GIT_SUBMODULES_GUIDE.md](GIT_SUBMODULES_GUIDE.md) for detailed workflow.

---

## 🚦 Development Workflow

### 1. Start Infrastructure
```bash
docker-compose up -d postgres-user postgres-skill postgres-disaster redis-user redis-skill redis-disaster rabbitmq
```

### 2. Start Services
```bash
# Via Docker
docker-compose up -d user-service skill-service disaster-service

# Or locally for development
cd rescuemesh-user-service && go run main.go
cd rescuemesh-skill-service && go run main.go
cd rescuemesh-disaster-service && uvicorn main:app --reload --port 3003
```

### 3. Start API Gateway
```bash
docker-compose up -d api-gateway
```

### 4. Test
```bash
./test-gateway.sh
open http://localhost:8000
```

---

## 🎯 Next Steps for Services 4-6

### SOS Service (Service 4)
**Recommended**: Node.js + Express or Go + Gin
- Emergency request handling
- Priority queue implementation
- Real-time location updates
- Integration with User Service (location) and Disaster Service (context)

### Matching Service (Service 5)
**Recommended**: Python + FastAPI (for ML capabilities) or Go + Gin
- Algorithm-based matching (skills + distance + availability)
- Integration with Skill Service and SOS Service
- Real-time match updates via RabbitMQ

### Notification Service (Service 6)
**Recommended**: Node.js + Express (for async I/O)
- Multi-channel notifications (SMS, Push, Email)
- RabbitMQ consumer for events
- Integration with Twilio/Firebase

---

## 🏆 Deployment Checklist

### Completed ✅
- [x] Docker containers for services 1-3
- [x] Docker Compose orchestration
- [x] API Gateway with nginx
- [x] Environment variable management
- [x] Health check endpoints
- [x] Database schemas and initialization
- [x] Sample data for testing
- [x] Service documentation
- [x] API contracts
- [x] Git repository structure
- [x] Automated test scripts
- [x] Interactive API documentation
- [x] Rate limiting and CORS

### Pending 🔄
- [ ] Services 4-6 implementation
- [ ] CI/CD pipeline (GitHub Actions)
- [ ] Monitoring dashboard (Prometheus + Grafana)
- [ ] Load testing
- [ ] Production SSL/TLS
- [ ] Authentication middleware
- [ ] Distributed tracing (Jaeger)

---

## 🤝 Integration Points

### Services 1-3 Provide:
- **User Service**: User profiles, locations, batch queries
- **Skill Service**: Available skills/resources, disaster templates
- **Disaster Service**: Active disasters, geospatial data, statistics

### Services 4-6 Will Consume:
- **SOS Service**: User locations, disaster context, available resources
- **Matching Service**: Skills, user details, disaster requirements
- **Notification Service**: Match results, SOS updates, disaster alerts

---

## 💡 Demo Scenario

```bash
# 1. View all active disasters
curl http://localhost:8000/api/disasters/active | jq

# 2. Get flood disaster requirements
curl http://localhost:8000/api/disaster-templates/flood | jq

# 3. Find boat operators near disaster location
curl "http://localhost:8000/api/skills?disasterType=flood&location=28.6,77.2&radius=50" | jq

# 4. Get volunteer details
curl http://localhost:8000/api/users/user-001 | jq

# 5. (Future) Create SOS request via gateway
# curl -X POST http://localhost:8000/api/sos/requests ...
```

---

## 📞 Support

For detailed setup and troubleshooting:
- Check service-specific READMEs in each service directory
- Review [QUICKSTART.md](QUICKSTART.md) for common issues
- See [API_GATEWAY.md](API_GATEWAY.md) for routing problems

---

## 📄 License

MIT License - See individual service directories for details.

---

**Built for disaster response coordination | Made with ❤️ for saving lives**
