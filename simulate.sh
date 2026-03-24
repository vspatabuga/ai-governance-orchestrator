#!/usr/bin/env bash

# ============================================
# VSP Porto - Simulation Runner
# Package: AI Governance (Private AI Orchestration)
# ============================================

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuration
PACKAGE_NAME="ai-gov"
PACKAGE_TITLE="AI GOVERNANCE"
PACKAGE_DESC="Private AI Orchestration Stack"
N8N_PORT=5678
PHOENIX_PORT=6006
AGENT_PORT=8000
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
AUTO_OPEN=false
FORCE_RECREATE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --open|-o)
      AUTO_OPEN=true
      shift
      ;;
    --force|-f)
      FORCE_RECREATE=true
      shift
      ;;
    --help|-h)
      echo "Usage: ./simulate.sh [--open] [--force] [--help]"
      echo ""
      echo "Options:"
      echo "  --open, -o    Open browser after starting"
      echo "  --force, -f   Recreate containers even if running"
      echo "  --help, -h    Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}"
cat << "BANNER"
   ____  _____     _______ ____  _____ ___ _____ _   _ 
  / ___|/ _ \ \   / / ____|  _ \|_   _|_ _/ ____| \ | |
  \___ \ | | \ \ / /|  _| | |_) | | |  | | |    |  \| |
   ___) | |_| \ V / | |___|  _ <  | |  | | |___ | |\  |
  |____/ \___/ \_/  |_____|_| \_\ |_| |___\____|_| \_|
                                                        
   AI GOVERNANCE ORCHESTRATOR - SIMULATION
BANNER
echo -e "${NC}"

echo -e "${CYAN}${PACKAGE_DESC}${NC}"
echo -e ""

# Check prerequisites
echo -e "${YELLOW}>> Checking prerequisites...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker not found${NC}"
    echo "  Install: https://docs.docker.com/get-docker/"
    exit 1
fi
echo -e "${GREEN}✓\${NC} Docker"

if ! docker info &> /dev/null; then
    echo -e "${RED}✗ Docker is not running${NC}"
    echo "  Please start Docker Desktop or the Docker daemon."
    exit 1
fi
echo -e "${GREEN}✓\${NC} Docker is running"

# Check for existing containers
if docker compose -p vsp-${PACKAGE_NAME} ps &> /dev/null; then
    if [ "$FORCE_RECREATE" = true ]; then
        echo -e "${YELLOW}>> Recreating containers...${NC}"
        docker compose -p vsp-${PACKAGE_NAME} down
    else
        echo -e "${YELLOW}>> Simulation already running. Use --force to restart.${NC}"
        echo -e "${GREEN}✔ Access URLs:${NC}"
        echo -e "   🌐 n8n:       http://localhost:${N8N_PORT}"
        echo -e "   📊 Phoenix:   http://localhost:${PHOENIX_PORT}"
        echo -e "   🔌 Agent API: http://localhost:${AGENT_PORT}"
        exit 0
    fi
fi

echo -e "${YELLOW}>> Starting ${PACKAGE_NAME} simulation...${NC}"

# Check if docker-compose.yml exists
if [ ! -f "$PROJECT_DIR/docker-compose.yml" ]; then
    echo -e "${RED}✗ docker-compose.yml not found${NC}"
    echo "  Make sure you're running this from the project directory."
    exit 1
fi

# Start the simulation
docker compose -p vsp-${PACKAGE_NAME} up -d --build

# Wait for services to be ready
echo -e "${YELLOW}>> Waiting for services to be ready...${NC}"

MAX_WAIT=300
COUNTER=0

wait_for_service() {
    local url=$1
    local name=$2
    
    while [ $COUNTER -lt $MAX_WAIT ]; do
        if curl -sf --max-time 2 "$url" > /dev/null 2>&1; then
            echo -e "${GREEN}✓\${NC} ${name} is ready"
            return 0
        fi
        sleep 2
        COUNTER=$((COUNTER + 2))
        printf "."
    done
    echo ""
    echo -e "${YELLOW}⚠ ${name} may not be ready yet${NC}"
    return 1
}

wait_for_service "http://localhost:${PHOENIX_PORT}" "Phoenix Dashboard" || true
wait_for_service "http://localhost:${N8N_PORT}" "n8n Workflow" || true

# Pull smallest LLM model for AI agent (phi:2.7b is ~1.6GB, efficient for demo)
echo -e "${YELLOW}>> Pulling smallest LLM model (phi:2.7b - ~1.6GB)...${NC}"
echo -e "${YELLOW}>> This is a one-time download for the simulation.${NC}"

if docker exec vsp_ollama ollama pull phi:2.7b 2>/dev/null; then
    echo -e "${GREEN}✓\${NC} LLM model ready"
else
    echo -e "${YELLOW}⚠ LLM model pull skipped (or already exists)${NC}"
fi

# Auto-open browser
if [ "$AUTO_OPEN" = true ]; then
    echo -e "${YELLOW}>> Opening browser...${NC}"
    sleep 2
    if command -v xdg-open &> /dev/null; then
        xdg-open "http://localhost:${PHOENIX_PORT}" &>/dev/null || true
    elif command -v open &> /dev/null; then
        open "http://localhost:${PHOENIX_PORT}" &>/dev/null || true
    elif command -v start &> /dev/null; then
        start "http://localhost:${PHOENIX_PORT}" &>/dev/null || true
    fi
fi

# Display success message
echo -e ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✔ ${PACKAGE_TITLE} Simulation Started Successfully!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e ""
echo -e "  ${PACKAGE_DESC}"
echo -e ""
echo -e "  Access URLs:"
echo -e "    🧱 n8n Workflow:      ${CYAN}http://localhost:${N8N_PORT}${NC}"
echo -e "    📊 Phoenix Dashboard: ${CYAN}http://localhost:${PHOENIX_PORT}${NC}"
echo -e "    🔌 Agent API:         ${CYAN}http://localhost:${AGENT_PORT}${NC}"
echo -e ""
echo -e "  Commands:"
echo -e "    View logs:    ${YELLOW}docker compose -p vsp-${PACKAGE_NAME} logs -f${NC}"
echo -e "    Stop:         ${YELLOW}docker compose -p vsp-${PACKAGE_NAME} down${NC}"
echo -e "    Reset:        ${YELLOW}docker compose -p vsp-${PACKAGE_NAME} down -v && ./simulate.sh${NC}"
echo -e ""
echo -e "  Default Credentials:"
echo -e "    n8n:  ${CYAN}admin@n8n.io${NC} / ${CYAN}admin123${NC}"
echo -e ""
echo -e "  Note: First run will download LLM models (~4GB). Be patient."
echo -e ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e ""
