# RescueMesh API Gateway Documentation

## Overview

The API Gateway serves as the single entry point for all RescueMesh microservices, providing:
- **Unified routing** to all 6 services
- **Rate limiting** per service
- **CORS handling** for cross-origin requests
- **Health monitoring** for each service
- **Load balancing** (future)
- **SSL/TLS termination** (future)

## Gateway URL

**Production**: `http://localhost:8000`

## Service Routes

### Service 1: User & Identity Service (Port 3001)
```
GET    /api/users/:userId
GET    /api/users/:userId/location
POST   /api/users/batch
PUT    /api/users/:userId/location
POST   /api/users
PUT    /api/users/:userId
```

**Rate Limit**: 20 requests/second (burst: 30)

### Service 2: Skill & Resource Registry (Port 3002)
```
GET    /api/skills?disasterType=&location=&radius=
GET    /api/skills/:skillId
POST   /api/skills
PUT    /api/skills/:skillId/availability

GET    /api/resources?disasterType=&location=&radius=
GET    /api/resources/:resourceId
POST   /api/resources
PUT    /api/resources/:resourceId/availability

GET    /api/disaster-templates/:disasterType
```

**Rate Limit**: 20 requests/second (burst: 30)

### Service 3: Disaster Event Service (Port 3003)
```
GET    /api/disasters/active
GET    /api/disasters/:disasterId
GET    /api/disasters/nearby?latitude=&longitude=&radius=
POST   /api/disasters
PUT    /api/disasters/:disasterId
GET    /api/disasters/types/stats
```

**Rate Limit**: 15 requests/second (burst: 25)

**Documentation**:
- `/docs` - Interactive Swagger UI
- `/redoc` - ReDoc documentation
- `/openapi.json` - OpenAPI schema

### Service 4: SOS Service (Port 3004)
```
POST   /api/sos/requests
GET    /api/sos/requests
GET    /api/sos/requests/:requestId
PUT    /api/sos/requests/:requestId
```

**Rate Limit**: 10 requests/second (burst: 20)

### Service 5: Matching Service (Port 3005)
```
POST   /api/matching/match
GET    /api/matching/results
GET    /api/matching/results/:matchId
```

**Rate Limit**: 10 requests/second (burst: 20)

### Service 6: Notification Service (Port 3006)
```
POST   /api/notifications/send
GET    /api/notifications/history
GET    /api/notifications/:notificationId
```

**Rate Limit**: 5 requests/second (burst: 10)

## Health Checks

### Gateway Health
```bash
curl http://localhost:8000/health
```

### Individual Service Health
```bash
curl http://localhost:8000/health/user
curl http://localhost:8000/health/skill
curl http://localhost:8000/health/disaster
curl http://localhost:8000/health/sos
curl http://localhost:8000/health/matching
curl http://localhost:8000/health/notification
```

### All Services Health Check Script
```bash
#!/bin/bash
for service in user skill disaster sos matching notification; do
  echo -n "$service: "
  curl -s http://localhost:8000/health/$service | jq -r '.status // "ERROR"'
done
```

## Usage Examples

### Through API Gateway (Recommended)

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

**Create SOS Request:**
```bash
curl -X POST http://localhost:8000/api/sos/requests \
  -H "Content-Type: application/json" \
  -d '{
    "disasterId": "disaster-001",
    "urgency": "critical",
    "location": {"latitude": 28.6, "longitude": 77.2}
  }' | jq
```

### Direct Service Access (Development)

You can also access services directly:
```bash
# Direct to User Service
curl http://localhost:3001/api/users/user-001

# Direct to Skill Service
curl http://localhost:3002/api/skills

# Direct to Disaster Service
curl http://localhost:3003/api/disasters/active
```

## Rate Limiting

The gateway implements rate limiting to prevent abuse:

| Service | Rate Limit | Burst |
|---------|------------|-------|
| User | 20 req/s | 30 |
| Skill | 20 req/s | 30 |
| Disaster | 15 req/s | 25 |
| SOS | 10 req/s | 20 |
| Matching | 10 req/s | 20 |
| Notification | 5 req/s | 10 |

**Rate Limit Response:**
```
HTTP/1.1 503 Service Temporarily Unavailable
```

## CORS Configuration

The gateway handles CORS for all services:

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
```

**Preflight Requests:**
```bash
curl -X OPTIONS http://localhost:8000/api/users/user-001 \
  -H "Origin: http://example.com" \
  -H "Access-Control-Request-Method: GET"
```

## Proxy Headers

The gateway forwards these headers to backend services:
- `Host`: Original host header
- `X-Real-IP`: Client's real IP address
- `X-Forwarded-For`: Client IP and any proxies
- `X-Forwarded-Proto`: Original protocol (http/https)

## Timeouts

| Timeout Type | Duration |
|--------------|----------|
| Connection | 5 seconds |
| Send | 10 seconds |
| Read | 10 seconds |

## Landing Page

Visit the gateway root for an interactive dashboard:
```
http://localhost:8000/
```

Features:
- Service status overview
- Quick links to API endpoints
- Health check links
- API documentation links

## Monitoring Endpoints

### Gateway Status
```bash
# Gateway health
curl http://localhost:8000/health

# Returns: "API Gateway healthy"
```

### Service-Specific Health
```bash
# Individual service health checks
curl http://localhost:8000/health/user
curl http://localhost:8000/health/skill
curl http://localhost:8000/health/disaster
```

### RabbitMQ Management
```
http://localhost:15672
Username: admin
Password: admin
```

## Development vs Production

### Development (Current Setup)
- Direct service ports exposed (3001-3006)
- Gateway on port 8000
- All traffic logged
- CORS allows all origins

### Production Recommendations
1. **Close direct service ports** - Only expose gateway
2. **Enable HTTPS** - Add SSL/TLS certificates
3. **Restrict CORS** - Whitelist specific domains
4. **Add authentication** - JWT tokens, API keys
5. **Enable monitoring** - Prometheus metrics
6. **Add caching** - Redis for frequently accessed data

## Testing the Gateway

### Complete Integration Test
```bash
#!/bin/bash

echo "Testing RescueMesh API Gateway"

# 1. Gateway health
echo "1. Gateway Health:"
curl -s http://localhost:8000/health

# 2. Get disaster
echo -e "\n2. Get Active Disasters:"
curl -s http://localhost:8000/api/disasters/active | jq -r '.disasters[0].disasterId'

# 3. Get required skills for disaster
echo -e "\n3. Get Disaster Template:"
curl -s http://localhost:8000/api/disaster-templates/flood | jq

# 4. Find available skills
echo -e "\n4. Find Available Skills:"
curl -s "http://localhost:8000/api/skills?disasterType=flood" | jq '.skills | length'

# 5. Get user details
echo -e "\n5. Get User Details:"
curl -s http://localhost:8000/api/users/user-001 | jq '.profile.name'

echo -e "\n✅ Gateway test complete!"
```

## Error Handling

### Service Unavailable
```json
{
  "error": "Service temporarily unavailable",
  "code": 503
}
```

### Gateway Timeout
```json
{
  "error": "Gateway timeout",
  "code": 504
}
```

### Rate Limit Exceeded
```
HTTP/1.1 503 Service Temporarily Unavailable
```

## Performance Tuning

### Worker Connections
Currently set to 1024. Adjust based on load:
```nginx
events {
    worker_connections 1024;  # Increase for high traffic
}
```

### Rate Limit Zones
Memory allocated per service:
```nginx
limit_req_zone $binary_remote_addr zone=user_limit:10m rate=20r/s;
```

## Security Considerations

### Current Setup (Development)
- ⚠️ CORS allows all origins
- ⚠️ No authentication required
- ⚠️ All traffic is HTTP (not HTTPS)
- ⚠️ Services directly accessible

### Production Recommendations
1. **Add authentication middleware**
2. **Implement JWT validation**
3. **Enable HTTPS only**
4. **Restrict CORS to known domains**
5. **Add request logging and audit trails**
6. **Implement API key management**

## Troubleshooting

### Gateway not responding
```bash
# Check nginx container
docker-compose ps api-gateway

# Check logs
docker-compose logs api-gateway

# Restart gateway
docker-compose restart api-gateway
```

### Service returns 502 Bad Gateway
```bash
# Check if backend service is running
curl http://localhost:3001/health  # or 3002, 3003, etc.

# Check service logs
docker-compose logs user-service
```

### Rate limit issues
```bash
# Check nginx error logs
docker-compose logs api-gateway | grep limit_req

# Temporarily disable for testing (edit nginx.conf)
# Comment out: limit_req zone=user_limit burst=30 nodelay;
```

## Configuration Files

### Main Config
`/home/ahmf/Documents/rescuemesh/api-gateway/nginx.conf`

### Reload Config Without Restart
```bash
docker-compose exec api-gateway nginx -s reload
```

### Test Config Syntax
```bash
docker-compose exec api-gateway nginx -t
```

## Migration Path

### From Direct Access → Gateway
```bash
# Old way (direct to service)
curl http://localhost:3001/api/users/user-001

# New way (through gateway)
curl http://localhost:8000/api/users/user-001
```

### Update Service URLs in Code
```javascript
// Before
const USER_SERVICE_URL = 'http://localhost:3001';

// After (production)
const API_GATEWAY_URL = 'http://api.rescuemesh.com';
```

## Future Enhancements

- [ ] SSL/TLS termination
- [ ] JWT authentication
- [ ] API key management
- [ ] Request/response logging to ELK
- [ ] Prometheus metrics endpoint
- [ ] WebSocket support for real-time updates
- [ ] GraphQL gateway layer
- [ ] Circuit breaker pattern
- [ ] Caching layer (Redis)
- [ ] Load balancing across multiple instances

---

**Gateway Version**: 1.0.0  
**Last Updated**: 2026-01-16  
**Port**: 8000  
**Protocol**: HTTP (HTTPS in production)
