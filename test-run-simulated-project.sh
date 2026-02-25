#!/bin/bash

# Test Run Simulated Project Script
# This script runs a complete test of the AxiomCore simulated project

set -e

echo "========================================="
echo "AxiomCore Simulated Project Test Run"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check prerequisites
echo "Checking prerequisites..."

# Check Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}✗ Python3 not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Python3 found: $(python3 --version)${NC}"

# Check Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}✗ Node.js not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Node.js found: $(node --version)${NC}"

# Check npm
if ! command -v npm &> /dev/null; then
    echo -e "${RED}✗ npm not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ npm found: $(npm --version)${NC}"

echo ""
echo "========================================="
echo "Step 1: Installing Backend Dependencies"
echo "========================================="
echo ""

pip install -q -r requirements.txt
echo -e "${GREEN}✓ Backend dependencies installed${NC}"

echo ""
echo "========================================="
echo "Step 2: Installing Frontend Dependencies"
echo "========================================="
echo ""

cd frontend
npm install --silent
echo -e "${GREEN}✓ Frontend dependencies installed${NC}"
cd ..

echo ""
echo "========================================="
echo "Step 3: Starting Backend Server"
echo "========================================="
echo ""

python3 server.py &
BACKEND_PID=$!
echo -e "${YELLOW}Backend server starting (PID: $BACKEND_PID)${NC}"

# Wait for backend to start
sleep 3

# Test backend
if curl -s http://127.0.0.1:8000/health > /dev/null; then
    echo -e "${GREEN}✓ Backend server is running and healthy${NC}"
else
    echo -e "${RED}✗ Backend server failed to start${NC}"
    kill $BACKEND_PID 2>/dev/null || true
    exit 1
fi

echo ""
echo "========================================="
echo "Step 4: Starting Frontend Dev Server"
echo "========================================="
echo ""

cd frontend
npm run dev &
FRONTEND_PID=$!
echo -e "${YELLOW}Frontend server starting (PID: $FRONTEND_PID)${NC}"
cd ..

# Wait for frontend to start
sleep 5

# Test frontend
if curl -s http://localhost:5173 > /dev/null; then
    echo -e "${GREEN}✓ Frontend server is running${NC}"
else
    echo -e "${RED}✗ Frontend server failed to start${NC}"
    kill $BACKEND_PID $FRONTEND_PID 2>/dev/null || true
    exit 1
fi

echo ""
echo "========================================="
echo "Step 5: Testing API Integration"
echo "========================================="
echo ""

# Test backend endpoint directly
BACKEND_RESPONSE=$(curl -s http://127.0.0.1:8000/api/hello)
if echo "$BACKEND_RESPONSE" | grep -q "Hello from FastAPI backend"; then
    echo -e "${GREEN}✓ Backend API endpoint working${NC}"
    echo "  Response: $BACKEND_RESPONSE"
else
    echo -e "${RED}✗ Backend API endpoint not responding correctly${NC}"
fi

# Test frontend proxy to backend
PROXY_RESPONSE=$(curl -s http://localhost:5173/api/hello)
if echo "$PROXY_RESPONSE" | grep -q "Hello from FastAPI backend"; then
    echo -e "${GREEN}✓ Frontend proxy to backend working${NC}"
    echo "  Response: $PROXY_RESPONSE"
else
    echo -e "${RED}✗ Frontend proxy not working correctly${NC}"
fi

echo ""
echo "========================================="
echo "Test Run Complete!"
echo "========================================="
echo ""
echo -e "${GREEN}✓ All tests passed successfully!${NC}"
echo ""
echo "Servers are running:"
echo "  - Backend:  http://127.0.0.1:8000"
echo "  - Frontend: http://localhost:5173"
echo ""
echo "Press Ctrl+C to stop both servers..."
echo ""

# Wait for user to stop
trap "echo ''; echo 'Stopping servers...'; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null || true; echo 'Servers stopped.'; exit 0" INT TERM

# Keep script running
wait
