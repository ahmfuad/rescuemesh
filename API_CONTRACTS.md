# API Contracts - RescueMesh Services

This document defines the API contracts between all services. **Critical for team coordination!**

---

## 🔗 Service Endpoints Overview

| Service | Port | Base URL | Status |
|---------|------|----------|--------|
| User & Identity Service | 3001 | `http://user-service:3001` | ✅ Implemented (Go) |
| Skill & Resource Registry | 3002 | `http://skill-service:3002` | ✅ Implemented (Go) |
| Disaster Event Service | 3003 | `http://disaster-service:3003` | ✅ Implemented (Python) |
| **SOS Service (You)** | 3004 | `http://sos-service:3004` | 🔄 In Development |
| **Matching Service (You)** | 3005 | `http://matching-service:3005` | 🔄 In Development |
| **Notification Service (You)** | 3006 | `http://notification-service:3006` | 🔄 In Development |

---

## 📡 Service 1: User & Identity Service ✅ IMPLEMENTED

**Tech Stack**: Go + Gin Framework
**Database**: PostgreSQL + Redis

### **GET /api/users/:userId**
Get user details by ID.

**Response:**
```json
{
  "userId": "user-123",
  "role": "volunteer" | "victim" | "authority" | "ngo",
  "profile": {
    "name": "John Doe",
    "phone": "+1234567890",
    "email": "john@example.com"
  },
  "location": {
    "latitude": 28.6139,
    "longitude": 77.2090,
    "lastUpdated": "2024-01-15T10:30:00Z"
  },
  "status": "active" | "inactive",
  "trustScore": 8.5
}
```

### **GET /api/users/:userId/location**
Get user's current location.

**Response:**
```json
{
  "userId": "user-123",
  "latitude": 28.6139,
  "longitude": 77.2090,
  "lastUpdated": "2024-01-15T10:30:00Z"
}
```

### **POST /api/users/batch**
Get multiple users by IDs.

**Request:**
```json
{
  "userIds": ["user-123", "user-456"]
}
```

**Response:**
```json
{
  "users": [
    {
      "userId": "user-123",
      "role": "volunteer",
      "profile": { "name": "John Doe", "phone": "+1234567890" },
      "location": { "latitude": 28.6139, "longitude": 77.2090 },
      "status": "active"
    }
  ]
}
```

### **PUT /api/users/:userId/location**
Update user location.

**Request:**
```json
{
  "latitude": 28.6139,
  "longitude": 77.2090
}
```

### **POST /api/users**
Create a new user.

**Request:**
```json
{
  "userId": "user-123",
  "role": "volunteer",
  "profile": {
    "name": "John Doe",
    "phone": "+1234567890",
    "email": "john@example.com"
  },
  "location": {
    "latitude": 28.6139,
    "longitude": 77.2090
  },
  "status": "active",
  "trustScore": 5.0
}
```

---

## 🔧 Service 2: Skill & Resource Registry ✅ IMPLEMENTED

**Tech Stack**: Go + Gin Framework
**Database**: PostgreSQL (with array support) + Redis

### **GET /api/skills?disasterType=flood&location={lat},{lng}&radius=10**
Get available skills matching disaster type and location.

**Query Params:**
- `disasterType`: flood, earthquake, cyclone, fire, tsunami, landslide
- `location`: "latitude,longitude"
- `radius`: km radius (default: 10)

**Response:**
```json
{
  "skills": [
    {
      "skillId": "skill-123",
      "userId": "user-123",
      "skillType": "boat_operator",
      "skillName": "Boat Operator",
      "certificationLevel": "expert" | "intermediate" | "beginner",
      "verified": true,
      "location": {
        "latitude": 28.6139,
        "longitude": 77.2090
      },
      "availability": "available" | "busy" | "unavailable",
      "trustScore": 8.5,
      "disasterTypes": ["flood", "tsunami"]
    }
  ]
}
```

### **GET /api/resources?disasterType=flood&location={lat},{lng}&radius=10**
Get available resources.

**Response:**
```json
{
  "resources": [
    {
      "resourceId": "res-123",
      "userId": "user-123",
      "resourceType": "boat",
      "resourceName": "Rescue Boat",
      "quantity": 2,
      "location": {
        "latitude": 28.6139,
        "longitude": 77.2090
      },
      "availability": "available" | "in-use" | "unavailable",
      "disasterTypes": ["flood", "tsunami"]
    }
  ]
}
```

### **PUT /api/skills/:skillId/availability**
Update skill availability.

**Request:**
```json
{
  "availability": "busy"
}
```

### **GET /api/disaster-templates/:disasterType**
Get disaster-specific skill/resource templates.

**Response:**
```json
{
  "disasterType": "flood",
  "requiredSkills": ["boat_operator", "swimmer", "medical", "rescue"],
  "requiredResources": ["boat", "medical_kit", "life_jacket"]
}
```

---

## 🌋 Service 3: Disaster Event Service ✅ IMPLEMENTED

**Tech Stack**: Python + FastAPI
**Database**: PostgreSQL

### **GET /api/disasters/active**
Get all active disasters.

**Response:**
```json
{
  "disasters": [
    {
      "disasterId": "disaster-123",
      "disasterType": "flood" | "earthquake" | "cyclone" | "fire" | "tsunami" | "landslide",
      "severity": "low" | "medium" | "high" | "critical",
      "status": "active" | "resolved" | "monitoring",
      "impactArea": {
        "latitude": 28.6139,
        "longitude": 77.2090,
        "radius": 25.0
      },
      "affectedPopulation": 50000,
      "startTime": "2024-01-15T10:00:00Z",
      "endTime": null,
      "description": "Severe flooding in Delhi NCR",
      "createdAt": "2024-01-15T10:00:00Z"
    }
  ]
}
```

### **GET /api/disasters/:disasterId**
Get specific disaster details.

**Response:**
```json
{
  "disasterId": "disaster-123",
  "disasterType": "flood",
  "severity": "high",
  "status": "active",
  "impactArea": {
    "latitude": 28.6139,
    "longitude": 77.2090,
    "radius": 25.0
  },
  "affectedPopulation": 50000,
  "startTime": "2024-01-15T10:00:00Z",
  "description": "Severe flooding in Delhi NCR"
}
```

### **GET /api/disasters/nearby?latitude=28.6&longitude=77.2&radius=50**
Get disasters near a location.

### **POST /api/disasters**
Create a new disaster event.

**Request:**
```json
{
  "disasterId": "disaster-123",
  "disasterType": "flood",
  "severity": "high",
  "status": "active",
  "impactArea": {
    "latitude": 28.6139,
    "longitude": 77.2090,
    "radius": 25.0
  },
  "affectedPopulation": 50000,
  "startTime": "2024-01-15T10:00:00Z",
  "description": "Severe flooding"
}
```

### **PUT /api/disasters/:disasterId**
Update disaster status.

**Request:**
```json
{
  "status": "resolved",
  "severity": "medium",
  "affectedPopulation": 60000,
  "endTime": "2024-01-15T20:00:00Z"
}
```

### **GET /api/disasters/types/stats**
Get statistics by disaster type.

**Response:**
```json
{
  "statistics": [
    {
      "disasterType": "flood",
      "totalCount": 5,
      "activeCount": 2,
      "totalAffectedPopulation": 100000
    }
  ]
}
```

---

## 🆘 Service 4: Emergency Request (SOS) Service (YOUR SERVICE)

### **POST /api/sos/requests**
Create a new SOS request.

**Request:**
```json
{
  "disasterId": "disaster-123",
  "requestedBy": "user-456",
  "requiredSkills": ["boat_operator", "medic"],
  "requiredResources": ["boat"],
  "urgency": "critical" | "high" | "medium" | "low",
  "numberOfPeople": 10,
  "location": {
    "latitude": 28.6139,
    "longitude": 77.2090
  },
  "description": "Family trapped in flooded building",
  "contactPhone": "+1234567890"
}
```

**Response:**
```json
{
  "requestId": "sos-123",
  "disasterId": "disaster-123",
  "requestedBy": "user-456",
  "status": "pending" | "matched" | "in_progress" | "resolved" | "cancelled",
  "requiredSkills": ["boat_operator", "medic"],
  "requiredResources": ["boat"],
  "urgency": "critical",
  "numberOfPeople": 10,
  "location": {
    "latitude": 28.6139,
    "longitude": 77.2090
  },
  "createdAt": "2024-01-15T10:30:00Z",
  "matchedAt": null,
  "resolvedAt": null
}
```

### **GET /api/sos/requests**
Get all SOS requests (with filters).

**Query Params:**
- `disasterId`: Filter by disaster
- `status`: Filter by status
- `urgency`: Filter by urgency
- `location`: "lat,lng" with radius

**Response:**
```json
{
  "requests": [
    {
      "requestId": "sos-123",
      "disasterId": "disaster-123",
      "requestedBy": "user-456",
        "center": {
          "latitude": 28.6139,
          "longitude": 77.2090
        },
        "radius": 5.0
      },
      "startedAt": "2024-01-15T10:00:00Z",
      "updatedAt": "2024-01-15T10:30:00Z"
    }
  ]
}
```

### **GET /api/disasters/:disasterId**
Get specific disaster details.

**Response:**
```json
{
  "disasterId": "disaster-123",
  "disasterType": "flood",
  "severity": "high",
  "status": "active",
  "impactArea": {
    "center": {
      "latitude": 28.6139,
      "longitude": 77.2090
    },
    "radius": 5.0
  },
  "metadata": {
    "affectedPopulation": 1000,
    "casualties": 5
  }
}
```

---

## 🆘 Service 4: Emergency Request (SOS) Service (YOUR SERVICE)

### **POST /api/sos/requests**
Create a new SOS request.

**Request:**
```json
{
  "disasterId": "disaster-123",
  "requestedBy": "user-456",
  "requiredSkills": ["boat_operator", "medic"],
  "requiredResources": ["boat"],
  "urgency": "critical" | "high" | "medium" | "low",
  "numberOfPeople": 10,
  "location": {
    "latitude": 28.6139,
    "longitude": 77.2090
  },
  "description": "Family trapped in flooded building",
  "contactPhone": "+1234567890"
}
```

**Response:**
```json
{
  "requestId": "sos-123",
  "disasterId": "disaster-123",
  "requestedBy": "user-456",
  "status": "pending" | "matched" | "in_progress" | "resolved" | "cancelled",
  "requiredSkills": ["boat_operator", "medic"],
  "requiredResources": ["boat"],
  "urgency": "critical",
  "numberOfPeople": 10,
  "location": {
    "latitude": 28.6139,
    "longitude": 77.2090
  },
  "createdAt": "2024-01-15T10:30:00Z",
  "matchedAt": null,
  "resolvedAt": null
}
```

### **GET /api/sos/requests**
Get all SOS requests (with filters).

**Query Params:**
- `disasterId`: Filter by disaster
- `status`: Filter by status
- `urgency`: Filter by urgency
- `location`: "lat,lng" with radius

**Response:**
```json
{
  "requests": [
    {
      "requestId": "sos-123",
      "disasterId": "disaster-123",
      "requestedBy": "user-456",
      "status": "pending",
      "urgency": "critical",
      "location": {
        "latitude": 28.6139,
        "longitude": 77.2090
      },
      "createdAt": "2024-01-15T10:30:00Z"
    }
  ],
  "total": 1
}
```

### **GET /api/sos/requests/:requestId**
Get specific SOS request.

**Response:**
```json
{
  "requestId": "sos-123",
  "disasterId": "disaster-123",
  "requestedBy": "user-456",
  "status": "matched",
  "requiredSkills": ["boat_operator", "medic"],
  "requiredResources": ["boat"],
  "urgency": "critical",
  "numberOfPeople": 10,
  "location": {
    "latitude": 28.6139,
    "longitude": 77.2090
  },
  "matches": [
    {
      "matchId": "match-123",
      "volunteerId": "user-789",
      "skillId": "skill-456",
      "status": "accepted"
    }
  ],
  "createdAt": "2024-01-15T10:30:00Z",
  "matchedAt": "2024-01-15T10:35:00Z"
}
```

### **PUT /api/sos/requests/:requestId/status**
Update SOS request status.

**Request:**
```json
{
  "status": "resolved"
}
```

### **POST /api/sos/requests/:requestId/trigger-matching**
Trigger matching service for this request.

**Response:**
```json
{
  "requestId": "sos-123",
  "matchingTriggered": true,
  "message": "Matching service notified"
}
```

---

## 🧠 Service 5: Intelligent Matching Service (YOUR SERVICE)

### **POST /api/matching/match**
Match volunteers/resources to an SOS request.

**Request:**
```json
{
  "requestId": "sos-123",
  "disasterId": "disaster-123",
  "disasterType": "flood",
  "requiredSkills": ["boat_operator", "medic"],
  "requiredResources": ["boat"],
  "location": {
    "latitude": 28.6139,
    "longitude": 77.2090
  },
  "urgency": "critical",
  "radius": 10
}
```

**Response:**
```json
{
  "requestId": "sos-123",
  "matches": [
    {
      "matchId": "match-123",
      "volunteerId": "user-789",
      "skillId": "skill-456",
      "skillType": "boat_operator",
      "matchScore": 9.2,
      "distance": 2.5,
      "trustScore": 8.5,
      "availability": "available",
      "status": "pending"
    },
    {
      "matchId": "match-124",
      "volunteerId": "user-790",
      "skillId": "skill-457",
      "skillType": "medic",
      "matchScore": 8.8,
      "distance": 3.1,
      "trustScore": 9.0,
      "availability": "available",
      "status": "pending"
    }
  ],
  "resourceMatches": [
    {
      "matchId": "match-125",
      "resourceId": "res-123",
      "resourceType": "boat",
      "ownerId": "user-791",
      "distance": 1.8,
      "status": "pending"
    }
  ],
  "matchedAt": "2024-01-15T10:35:00Z"
}
```

### **POST /api/matching/matches/:matchId/accept**
Accept a match (volunteer accepts request).

**Request:**
```json
{
  "volunteerId": "user-789"
}
```

**Response:**
```json
{
  "matchId": "match-123",
  "status": "accepted",
  "updatedAt": "2024-01-15T10:36:00Z"
}
```

### **POST /api/matching/matches/:matchId/reject**
Reject a match.

**Request:**
```json
{
  "volunteerId": "user-789",
  "reason": "Already committed to another request"
}
```

### **GET /api/matching/matches?requestId=sos-123**
Get all matches for a request.

**Response:**
```json
{
  "matches": [
    {
      "matchId": "match-123",
      "requestId": "sos-123",
      "volunteerId": "user-789",
      "status": "accepted",
      "matchScore": 9.2
    }
  ]
}
```

### **GET /api/matching/stats**
Get matching statistics.

**Response:**
```json
{
  "totalMatches": 150,
  "acceptedMatches": 120,
  "rejectedMatches": 20,
  "pendingMatches": 10,
  "averageMatchTime": "00:02:30"
}
```

---

## 📡 Service 6: Notification & Communication Service (YOUR SERVICE)

### **POST /api/notifications/send**
Send a notification.

**Request:**
```json
{
  "recipientId": "user-789",
  "recipientPhone": "+1234567890",
  "channels": ["sms", "push"],
  "type": "sos_match" | "sos_request" | "disaster_alert" | "match_accepted",
  "priority": "high" | "medium" | "low",
  "data": {
    "requestId": "sos-123",
    "message": "You have been matched to an emergency request",
    "location": {
      "latitude": 28.6139,
      "longitude": 77.2090
    },
    "actionUrl": "https://app.rescuemesh.com/requests/sos-123"
  }
}
```

**Response:**
```json
{
  "notificationId": "notif-123",
  "status": "sent" | "failed" | "pending",
  "channels": {
    "sms": "sent",
    "push": "sent"
  },
  "sentAt": "2024-01-15T10:36:00Z"
}
```

### **POST /api/notifications/batch**
Send notifications to multiple recipients.

**Request:**
```json
{
  "recipients": [
    {
      "recipientId": "user-789",
      "recipientPhone": "+1234567890"
    },
    {
      "recipientId": "user-790",
      "recipientPhone": "+1234567891"
    }
  ],
  "channels": ["sms", "push"],
  "type": "disaster_alert",
  "data": {
    "disasterId": "disaster-123",
    "message": "New disaster alert in your area"
  }
}
```

### **GET /api/notifications/:notificationId/status**
Get notification delivery status.

**Response:**
```json
{
  "notificationId": "notif-123",
  "status": "sent",
  "channels": {
    "sms": {
      "status": "delivered",
      "deliveredAt": "2024-01-15T10:36:05Z"
    },
    "push": {
      "status": "sent",
      "sentAt": "2024-01-15T10:36:00Z"
    }
  }
}
```

### **GET /api/notifications/user/:userId**
Get notification history for a user.

**Query Params:**
- `limit`: Number of records (default: 20)
- `offset`: Pagination offset

**Response:**
```json
{
  "notifications": [
    {
      "notificationId": "notif-123",
      "type": "sos_match",
      "message": "You have been matched to an emergency request",
      "status": "sent",
      "createdAt": "2024-01-15T10:36:00Z"
    }
  ],
  "total": 1
}
```

---

## 🔄 Message Queue Events

### **Events Published by Your Services:**

#### **SOS Service → Matching Service**
```json
{
  "event": "sos.request.created",
  "data": {
    "requestId": "sos-123",
    "disasterId": "disaster-123",
    "urgency": "critical"
  }
}
```

#### **Matching Service → Notification Service**
```json
{
  "event": "match.created",
  "data": {
    "matchId": "match-123",
    "requestId": "sos-123",
    "volunteerId": "user-789"
  }
}
```

#### **Matching Service → SOS Service**
```json
{
  "event": "match.accepted",
  "data": {
    "matchId": "match-123",
    "requestId": "sos-123",
    "volunteerId": "user-789"
  }
}
```

---

## 🛡️ Error Responses

All services should return errors in this format:

```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "SOS request not found",
    "details": {}
  }
}
```

**Common HTTP Status Codes:**
- `200`: Success
- `201`: Created
- `400`: Bad Request
- `404`: Not Found
- `500`: Internal Server Error
- `503`: Service Unavailable

---

## 📝 Notes for Integration

1. **Service Discovery**: Use service names in Docker network (e.g., `http://sos-service:3004`)
2. **Timeout**: Set HTTP timeouts to 5 seconds for inter-service calls
3. **Retry Logic**: Implement exponential backoff for failed requests
4. **Health Checks**: All services must have `/health` endpoint
5. **CORS**: Configure CORS for API Gateway access
6. **Authentication**: Add JWT tokens later (optional for MVP)

---

## ✅ Integration Checklist

- [ ] All services expose `/health` endpoint
- [ ] All services have proper error handling
- [ ] Message queue events are defined
- [ ] API contracts are agreed upon
- [ ] Shared data models are documented
- [ ] Test endpoints are ready
