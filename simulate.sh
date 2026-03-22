#!/usr/bin/env bash

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

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

SIM_DIR="/tmp/vsp-ai-gov"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${YELLOW}>> Initializing AI Governance Stack in ${SIM_DIR}...${NC}"

rm -rf "$SIM_DIR"
mkdir -p "$SIM_DIR"
cp -r "$PROJECT_DIR"/* "$SIM_DIR/"
cd "$SIM_DIR"

echo -e ">> Building Docker images..."
if command -v docker-compose &> /dev/null; then
    docker-compose -p vsp-ai-gov up --build -d
else
    docker compose -p vsp-ai-gov up --build -d
fi

echo -e "\n${GREEN}✔ AI Governance Stack Successfully Simulated!${NC}"
echo -e "================================================================================="
echo -e "🧱 The system is running across 4 isolated virtual networks."
echo -e "🔒 Data stores (Ollama & VectorDB) are completely hidden from the host network."
echo -e ""
echo -e "🌍 ${PURPLE}n8n Automation Engine${NC}:      http://localhost:5678"
echo -e "📊 ${BLUE}Arize Phoenix Dashboard${NC}:    http://localhost:6006"
echo -e "🔌 Agent API${NC}:                        http://localhost:8000"
echo -e ""
echo -e "🛑 To teardown: cd $SIM_DIR && docker compose -p vsp-ai-gov down"
echo -e "================================================================================="
