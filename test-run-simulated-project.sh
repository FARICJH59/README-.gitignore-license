#!/bin/bash

# Test Run Simulated Project Script
# This script runs a complete test of the AxiomCore simulated project

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

AUTO_EXIT=false

usage() {
    cat <<'EOF'
Usage: test-run-simulated-project.sh [--ci]

Options:
  --ci, --non-interactive, --auto-exit
              Run in non-interactive mode, shutting down servers after checks.
  -h, --help  Show this help message.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --ci|--non-interactive|--auto-exit)
            AUTO_EXIT=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

echo "========================================="
echo "AxiomCore Simulated Project Test Run"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
FRONTEND_LOG="${ROOT_DIR}/frontend-dev.log"

# Truncate/create log file for the frontend dev server
: > "$FRONTEND_LOG"

BACKEND_PID=0
FRONTEND_PID=0

cleanup() {
    if [[ $BACKEND_PID -gt 0 ]] && kill -0 "${BACKEND_PID}" 2>/dev/null; then
        kill "${BACKEND_PID}" 2>/dev/null || true
        wait "${BACKEND_PID}" 2>/dev/null || true
    fi
    if [[ $FRONTEND_PID -gt 0 ]] && kill -0 "${FRONTEND_PID}" 2>/dev/null; then
        kill "${FRONTEND_PID}" 2>/dev/null || true
        wait "${FRONTEND_PID}" 2>/dev/null || true
    fi
}
trap 'rc=$?; cleanup; exit "$rc"' EXIT

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
cd "$ROOT_DIR"

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
    exit 1
fi

echo ""
echo "========================================="
echo "Step 4: Starting Frontend Dev Server"
echo "========================================="
echo ""

cd frontend
npm run dev >"$FRONTEND_LOG" 2>&1 &
FRONTEND_PID=$!
echo -e "${YELLOW}Frontend server starting (PID: $FRONTEND_PID) — logs: $FRONTEND_LOG${NC}"
cd "$ROOT_DIR"

# Wait for frontend to start
sleep 5

# Test frontend
if curl -s http://localhost:5173 > /dev/null; then
    echo -e "${GREEN}✓ Frontend server is running${NC}"
else
    echo -e "${RED}✗ Frontend server failed to start${NC}"
    echo "Recent frontend logs:"
    tail -n 50 "$FRONTEND_LOG" || true
    exit 1
fi

echo ""
echo "========================================="
echo "Step 5: Testing API Integration"
echo "========================================="
echo ""

TEST_FAILURES=0

# Test backend endpoint directly
BACKEND_RESPONSE=$(curl -s http://127.0.0.1:8000/api/hello)
BACKEND_STATUS=$?
if [[ $BACKEND_STATUS -ne 0 ]]; then
    echo -e "${RED}✗ Backend API endpoint unreachable (curl exit $BACKEND_STATUS)${NC}"
    TEST_FAILURES=$((TEST_FAILURES + 1))
elif echo "$BACKEND_RESPONSE" | grep -q "Hello from FastAPI backend"; then
    echo -e "${GREEN}✓ Backend API endpoint working${NC}"
    echo "  Response: $BACKEND_RESPONSE"
else
    echo -e "${RED}✗ Backend API endpoint not responding correctly${NC}"
    TEST_FAILURES=$((TEST_FAILURES + 1))
fi

if [[ $TEST_FAILURES -ne 0 ]]; then
    echo -e "${YELLOW}⚠ Skipping frontend proxy test because backend check failed${NC}"
else
    # Test frontend proxy to backend
    PROXY_RESPONSE=$(curl -s http://localhost:5173/api/hello)
    PROXY_STATUS=$?
    if [[ $PROXY_STATUS -ne 0 ]]; then
        echo -e "${RED}✗ Frontend proxy unreachable (curl exit $PROXY_STATUS)${NC}"
        TEST_FAILURES=$((TEST_FAILURES + 1))
    elif echo "$PROXY_RESPONSE" | grep -q "Hello from FastAPI backend"; then
        echo -e "${GREEN}✓ Frontend proxy to backend working${NC}"
        echo "  Response: $PROXY_RESPONSE"
    else
        echo -e "${RED}✗ Frontend proxy not working correctly${NC}"
        TEST_FAILURES=$((TEST_FAILURES + 1))
    fi
fi

echo ""
echo "========================================="
echo "Test Run Complete!"
echo "========================================="
echo ""

if [[ $TEST_FAILURES -eq 0 ]]; then
    echo -e "${GREEN}✓ All tests passed successfully!${NC}"
else
    echo -e "${RED}✗ Test run completed with ${TEST_FAILURES} failure(s)${NC}"
fi
echo ""

if [[ $TEST_FAILURES -ne 0 ]]; then
    echo "Shutting down servers..."
    exit 1
fi

if $AUTO_EXIT; then
    echo "Shutting down servers..."
    exit 0
fi

echo "Servers are running:"
echo "  - Backend:  http://127.0.0.1:8000"
echo "  - Frontend: http://localhost:5173"
echo ""
echo "Press Ctrl+C to stop both servers..."
echo ""

# Wait for user to stop; cleanup trap will handle shutdown
wait
