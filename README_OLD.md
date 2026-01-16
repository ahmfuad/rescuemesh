# RescueMesh - Unified Disaster Skill Coordination Platform

> **"Right skill. Right place. Right time."**

## 🎯 Project Overview

RescueMesh is a microservices-based platform that coordinates skills and resources during disasters. This project is built for a **Microservices & DevOps Hackathon**.

### Team Division
- **Services 1-3 (Implemented ✅):**
  - User & Identity Service (Go + Gin)
  - Skill & Resource Registry Service (Go + Gin)
  - Disaster Event Service (Python + FastAPI)

- **Services 4-6 (In Development 🔄):**
  - Emergency Request (SOS) Service
  - Intelligent Matching Service
  - Notification & Communication Service

---

## 🛠 Tech Stack Recommendations

### **Recommended Stack (Fast Development for Hackathon)**

#### **Backend Services**
- **Language**: **Node.js + Express** or **Python + FastAPI**
  - ✅ Fast development
  - ✅ Great ecosystem
  - ✅ Easy containerization
  - **Recommendation**: Node.js for services 4-6 (better async handling)

#### **Database**
- **PostgreSQL** (for structured data: SOS requests, matches)
- **Redis** (for caching, pub/sub, real-time features)
- **MongoDB** (optional, if you prefer NoSQL for flexible schemas)

#### **Message Queue & Communication**
- **RabbitMQ** or **Redis Pub/Sub** (for async service communication)
- **WebSocket** (for real-time updates)

#### **API Gateway**
- **Kong** or **nginx** (for routing, rate limiting)
- **Simple Express gateway** (for MVP/hackathon speed)

#### **Containerization & DevOps**
- **Docker** + **Docker Compose** (mandatory for hackathon)
- **Kubernetes** (optional, if time permits)

#### **Monitoring & Logging**
- **Prometheus** + **Grafana** (metrics)
- **ELK Stack** or **Loki** (logs)
- **Jaeger** or **Zipkin** (distributed tracing)

#### **Service Discovery**
- **Consul** or **Eureka** (or simple config-based for MVP)

#### **External APIs**
- **Twilio** (SMS)
- **Firebase Cloud Messaging** (Push notifications)
- **WhatsApp Business API** (optional)

---

## 📐 Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    API Gateway (Kong/nginx)              │
└─────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
┌───────▼──────┐  ┌───────▼──────┐  ┌───────▼──────┐
│ Service 1-3 │  │ Service 4-6  │  │   Service 7  │
│ (Friend)    │  │   (You)      │  │  (Optional)  │
└───────┬──────┘  └───────┬──────┘  └──────────────┘
        │                 │
        └────────┬────────┘
                 │
        ┌────────▼────────┐
        │  Message Queue │
        │  (RabbitMQ)    │
        └────────────────┘
```

---

## 🔌 Service Communication

### **Synchronous (REST)**
- Direct HTTP calls between services
- Use for: immediate data fetching, simple operations

### **Asynchronous (Message Queue)**
- RabbitMQ/Redis for: notifications, matching triggers, event propagation
- Use for: decoupled operations, scalability

---

## 📁 Project Structure

```
rescuemesh/
├── rescuemesh-user-service/         # Service 1 ✅ (Go + Gin)
├── rescuemesh-skill-service/        # Service 2 ✅ (Go + Gin)
├── rescuemesh-disaster-service/     # Service 3 ✅ (Python + FastAPI)
├── rescuemesh-sos-service/          # Service 4 🔄 (In Development)
├── rescuemesh-matching-service/     # Service 5 🔄 (In Development)
├── rescuemesh-notification-service/ # Service 6 🔄 (In Development)
├── api-gateway/                     # API Gateway (nginx)
├── docker-compose.yml               # All services orchestration
├── API_CONTRACTS.md                 # Service API specifications
├── SERVICES_1-3_SETUP.md           # Setup guide for services 1-3
├── GIT_SUBMODULES_GUIDE.md         # Git submodules documentation
└── README.md
```

---

## 🚀 Quick Start

### Option 1: Docker Compose (Recommended)

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Check health
curl http://localhost:3001/health  # User Service
curl http://localhost:3002/health  # Skill Service
curl http://localhost:3003/health  # Disaster Service
curl http://localhost:3003/docs    # FastAPI Interactive Docs

# Stop services
docker-compose down
```

### Option 2: Local Development

**Services 1-2 (Go):**
```bash
cd rescuemesh-user-service  # or rescuemesh-skill-service
go mod download
go run main.go
```

**Service 3 (Python):**
```bash
cd rescuemesh-disaster-service
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --port 3003
```

**See [SERVICES_1-3_SETUP.md](SERVICES_1-3_SETUP.md) for detailed setup instructions.**

---

## 📋 API Contracts

See `API_CONTRACTS.md` for detailed API specifications between all services.

---

## 🧪 Testing Strategy

- **Unit Tests**: Jest (Node.js) or pytest (Python)
- **Integration Tests**: Supertest (Node.js)
- **E2E Tests**: Postman/Newman collections

---

## 📊 DevOps Checklist for Hackathon

- [x] Docker containers for each service (Services 1-3)
- [x] Docker Compose for local development
- [x] API Gateway setup
- [x] Environment variable management
- [x] Health check endpoints
- [x] Database schemas and migrations
- [x] Sample data initialization
- [x] Service documentation (READMEs)
- [x] API contracts documentation
- [x] Git repository structure
- [ ] Services 4-6 implementation
- [ ] CI/CD pipeline (GitHub Actions)
- [ ] Monitoring dashboard
- [ ] Load testing

---

## 🤝 Integration Points

### **Your Services Depend On:**
- **User Service** (Service 1): Get user details, location
- **Skill Registry** (Service 2): Get available skills/resources
- **Disaster Event** (Service 3): Get active disasters, severity, location

### **Your Services Provide To:**
- **Authority Dashboard**: Real-time SOS requests, match status
- **Other Services**: Event notifications, match results

---

## 📝 Next Steps

1. Review API contracts with your friend
2. Set up shared database schemas
3. Implement health checks
4. Create Docker images
5. Test service integration
6. Prepare demo scenarios

---

## 🏆 Hackathon Presentation Tips

- **Demo Flow**: Show a complete disaster scenario end-to-end
- **Highlight**: Microservices communication, Docker setup, API Gateway
- **Mention**: Scalability, resilience, disaster-agnostic design
