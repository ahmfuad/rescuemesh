#!/bin/bash

# RescueMesh Services 1-3 Test Script
# This script tests all implemented services and their integrations

set -e

echo "🚀 RescueMesh Services 1-3 Test Suite"
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Base URLs
USER_SERVICE="http://localhost:3001"
SKILL_SERVICE="http://localhost:3002"
DISASTER_SERVICE="http://localhost:3003"

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to test endpoint
test_endpoint() {
    local name=$1
    local url=$2
    local expected_code=${3:-200}
    
    echo -n "Testing: $name ... "
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    
    if [ "$response" -eq "$expected_code" ]; then
        echo -e "${GREEN}✓ PASSED${NC} (HTTP $response)"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAILED${NC} (Expected HTTP $expected_code, got $response)"
        ((TESTS_FAILED++))
    fi
}

# Function to test POST endpoint
test_post() {
    local name=$1
    local url=$2
    local data=$3
    local expected_code=${4:-200}
    
    echo -n "Testing: $name ... "
    
    response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$url" \
        -H "Content-Type: application/json" \
        -d "$data")
    
    if [ "$response" -eq "$expected_code" ]; then
        echo -e "${GREEN}✓ PASSED${NC} (HTTP $response)"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAILED${NC} (Expected HTTP $expected_code, got $response)"
        ((TESTS_FAILED++))
    fi
}

echo "📡 Service 1: User & Identity Service"
echo "--------------------------------------"
test_endpoint "Health Check" "$USER_SERVICE/health"
test_endpoint "Get User by ID" "$USER_SERVICE/api/users/user-001"
test_endpoint "Get User Location" "$USER_SERVICE/api/users/user-001/location"
test_post "Batch User Query" "$USER_SERVICE/api/users/batch" '{"userIds":["user-001","user-002"]}'
echo ""

echo "🔧 Service 2: Skill & Resource Registry"
echo "--------------------------------------"
test_endpoint "Health Check" "$SKILL_SERVICE/health"
test_endpoint "Get All Skills" "$SKILL_SERVICE/api/skills"
test_endpoint "Get Skills by Disaster Type" "$SKILL_SERVICE/api/skills?disasterType=flood"
test_endpoint "Get Skills with Location" "$SKILL_SERVICE/api/skills?disasterType=flood&location=28.6139,77.2090&radius=50"
test_endpoint "Get Skill by ID" "$SKILL_SERVICE/api/skills/skill-001"
test_endpoint "Get All Resources" "$SKILL_SERVICE/api/resources"
test_endpoint "Get Resources by Disaster" "$SKILL_SERVICE/api/resources?disasterType=flood"
test_endpoint "Get Disaster Template (Flood)" "$SKILL_SERVICE/api/disaster-templates/flood"
test_endpoint "Get Disaster Template (Earthquake)" "$SKILL_SERVICE/api/disaster-templates/earthquake"
echo ""

echo "🌋 Service 3: Disaster Event Service"
echo "--------------------------------------"
test_endpoint "Health Check" "$DISASTER_SERVICE/health"
test_endpoint "Get Active Disasters" "$DISASTER_SERVICE/api/disasters/active"
test_endpoint "Get Disaster by ID" "$DISASTER_SERVICE/api/disasters/disaster-001"
test_endpoint "Get Nearby Disasters" "$DISASTER_SERVICE/api/disasters/nearby?latitude=28.6&longitude=77.2&radius=100"
test_endpoint "Get Disaster Statistics" "$DISASTER_SERVICE/api/disasters/types/stats"
test_endpoint "API Documentation (Swagger)" "$DISASTER_SERVICE/docs"
echo ""

echo "🔗 Integration Tests"
echo "--------------------------------------"

# Test 1: Get disaster, then get required skills
echo -n "Integration Test 1: Disaster → Skills ... "
DISASTER_TYPE=$(curl -s "$DISASTER_SERVICE/api/disasters/disaster-001" | grep -o '"disasterType":"[^"]*"' | cut -d'"' -f4)
if [ -n "$DISASTER_TYPE" ]; then
    TEMPLATE=$(curl -s "$SKILL_SERVICE/api/disaster-templates/$DISASTER_TYPE")
    if [ -n "$TEMPLATE" ]; then
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

# Test 2: Get skill, then get user details
echo -n "Integration Test 2: Skill → User ... "
USER_ID=$(curl -s "$SKILL_SERVICE/api/skills/skill-001" | grep -o '"userId":"[^"]*"' | cut -d'"' -f4)
if [ -n "$USER_ID" ]; then
    USER=$(curl -s "$USER_SERVICE/api/users/$USER_ID")
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

# Test 3: Geographic query (location-based skills near disaster)
echo -n "Integration Test 3: Disaster Location → Nearby Skills ... "
DISASTER_LAT=$(curl -s "$DISASTER_SERVICE/api/disasters/disaster-001" | grep -o '"latitude":[0-9.]*' | head -1 | cut -d':' -f2)
DISASTER_LNG=$(curl -s "$DISASTER_SERVICE/api/disasters/disaster-001" | grep -o '"longitude":[0-9.]*' | head -1 | cut -d':' -f2)
if [ -n "$DISASTER_LAT" ] && [ -n "$DISASTER_LNG" ]; then
    SKILLS=$(curl -s "$SKILL_SERVICE/api/skills?location=$DISASTER_LAT,$DISASTER_LNG&radius=50")
    if [ -n "$SKILLS" ]; then
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
echo "========================================"
echo "📊 Test Summary"
echo "========================================"
echo -e "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! Services are working correctly.${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Some tests failed. Please check the services.${NC}"
    exit 1
fi
