#!/bin/bash

# RescueMesh - Complete System Test via API Gateway
# Tests all 6 services through the unified gateway

set -e

echo "🌐 RescueMesh API Gateway - Complete System Test"
echo "=================================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

GATEWAY="http://localhost:8000"
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
test_endpoint() {
    local name=$1
    local url=$2
    local expected_code=${3:-200}
    
    echo -n "Testing: $name ... "
    response=$(curl -s -o /dev/null -w "%{http_code}" "$GATEWAY$url")
    
    if [ "$response" -eq "$expected_code" ]; then
        echo -e "${GREEN}✓ PASSED${NC} (HTTP $response)"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAILED${NC} (Expected $expected_code, got $response)"
        ((TESTS_FAILED++))
    fi
}

test_post() {
    local name=$1
    local url=$2
    local data=$3
    local expected_code=${4:-200}
    
    echo -n "Testing: $name ... "
    response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$GATEWAY$url" \
        -H "Content-Type: application/json" -d "$data")
    
    if [ "$response" -eq "$expected_code" ]; then
        echo -e "${GREEN}✓ PASSED${NC} (HTTP $response)"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAILED${NC} (Expected $expected_code, got $response)"
        ((TESTS_FAILED++))
    fi
}

echo -e "${BLUE}🚪 Gateway Health Checks${NC}"
echo "----------------------------------------"
test_endpoint "Gateway Main Health" "/health"
test_endpoint "User Service Health" "/health/user"
test_endpoint "Skill Service Health" "/health/skill"
test_endpoint "Disaster Service Health" "/health/disaster"
echo ""

echo -e "${BLUE}👤 Service 1: User & Identity Service${NC}"
echo "----------------------------------------"
test_endpoint "Get User by ID" "/api/users/user-001"
test_endpoint "Get User Location" "/api/users/user-001/location"
test_post "Batch User Query" "/api/users/batch" '{"userIds":["user-001","user-002"]}'
echo ""

echo -e "${BLUE}🔧 Service 2: Skill & Resource Registry${NC}"
echo "----------------------------------------"
test_endpoint "Get All Skills" "/api/skills"
test_endpoint "Get Flood Skills" "/api/skills?disasterType=flood"
test_endpoint "Get Skills by Location" "/api/skills?disasterType=flood&location=28.6,77.2&radius=50"
test_endpoint "Get Skill by ID" "/api/skills/skill-001"
test_endpoint "Get All Resources" "/api/resources"
test_endpoint "Get Flood Resources" "/api/resources?disasterType=flood"
test_endpoint "Get Flood Template" "/api/disaster-templates/flood"
test_endpoint "Get Earthquake Template" "/api/disaster-templates/earthquake"
echo ""

echo -e "${BLUE}🌋 Service 3: Disaster Event Service${NC}"
echo "----------------------------------------"
test_endpoint "Get Active Disasters" "/api/disasters/active"
test_endpoint "Get Disaster by ID" "/api/disasters/disaster-001"
test_endpoint "Get Nearby Disasters" "/api/disasters/nearby?latitude=28.6&longitude=77.2&radius=100"
test_endpoint "Get Disaster Stats" "/api/disasters/types/stats"
test_endpoint "API Docs (Swagger)" "/docs"
test_endpoint "API Docs (ReDoc)" "/redoc"
echo ""

echo -e "${BLUE}🔗 Cross-Service Integration Tests${NC}"
echo "----------------------------------------"

# Test 1: Complete disaster response flow
echo -n "Integration 1: Disaster → Template → Skills ... "
DISASTER=$(curl -s "$GATEWAY/api/disasters/disaster-001")
if [ -n "$DISASTER" ]; then
    DISASTER_TYPE=$(echo "$DISASTER" | grep -o '"disasterType":"[^"]*"' | cut -d'"' -f4)
    TEMPLATE=$(curl -s "$GATEWAY/api/disaster-templates/$DISASTER_TYPE")
    SKILLS=$(curl -s "$GATEWAY/api/skills?disasterType=$DISASTER_TYPE")
    if [ -n "$TEMPLATE" ] && [ -n "$SKILLS" ]; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAILED${NC}"
        ((TESTS_FAILED++))
    fi
else
    echo -e "${RED}✗ FAILED${NC}"
    ((TESTS_FAILED++))
fi

# Test 2: User → Skill lookup
echo -n "Integration 2: Skill → User Details ... "
SKILL=$(curl -s "$GATEWAY/api/skills/skill-001")
if [ -n "$SKILL" ]; then
    USER_ID=$(echo "$SKILL" | grep -o '"userId":"[^"]*"' | cut -d'"' -f4)
    USER=$(curl -s "$GATEWAY/api/users/$USER_ID")
    if [ -n "$USER" ]; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAILED${NC}"
        ((TESTS_FAILED++))
    fi
else
    echo -e "${RED}✗ FAILED${NC}"
    ((TESTS_FAILED++))
fi

# Test 3: Geospatial query
echo -n "Integration 3: Disaster Location → Skills Nearby ... "
LOCATION=$(curl -s "$GATEWAY/api/disasters/disaster-001" | grep -o '"latitude":[0-9.]*' | head -1 | cut -d':' -f2)
if [ -n "$LOCATION" ]; then
    NEARBY_SKILLS=$(curl -s "$GATEWAY/api/skills?location=$LOCATION,77.2&radius=50")
    if [ -n "$NEARBY_SKILLS" ]; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAILED${NC}"
        ((TESTS_FAILED++))
    fi
else
    echo -e "${RED}✗ FAILED${NC}"
    ((TESTS_FAILED++))
fi

echo ""
echo -e "${BLUE}📊 CORS & Headers Test${NC}"
echo "----------------------------------------"
echo -n "Testing CORS Headers ... "
CORS=$(curl -s -I -X OPTIONS "$GATEWAY/api/users/user-001" \
    -H "Origin: http://example.com" \
    -H "Access-Control-Request-Method: GET" | grep -i "Access-Control-Allow")
if [ -n "$CORS" ]; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ FAILED${NC}"
    ((TESTS_FAILED++))
fi

echo ""
echo "=================================================="
echo -e "${BLUE}📈 Test Summary${NC}"
echo "=================================================="
echo "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All gateway tests passed!${NC}"
    echo ""
    echo "✅ API Gateway is properly routing all services"
    echo "✅ All 3 implemented services are accessible"
    echo "✅ Cross-service integration working"
    echo "✅ CORS headers configured correctly"
    echo ""
    echo "🌐 You can now access all services through:"
    echo "   http://localhost:8000"
    echo ""
    echo "📚 Visit http://localhost:8000 for the interactive dashboard"
    echo "📖 API Docs: http://localhost:8000/docs"
    exit 0
else
    echo -e "${RED}⚠️  Some tests failed. Please check the services.${NC}"
    echo ""
    echo "🔍 Troubleshooting:"
    echo "  1. Ensure all services are running: docker-compose ps"
    echo "  2. Check service logs: docker-compose logs <service-name>"
    echo "  3. Verify health: curl http://localhost:8000/health/<service>"
    exit 1
fi
