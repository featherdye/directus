#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "================================================"
echo "Directus Deployment Script"
echo "================================================"
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    echo "Please create .env file from .env.example:"
    echo "  cp .env.example .env"
    echo "  nano .env"
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running!${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not installed!${NC}"
    exit 1
fi

echo -e "${GREEN}[1/5] Pulling latest changes from Git...${NC}"
git pull

echo -e "${GREEN}[2/5] Pulling latest Docker images...${NC}"
docker-compose -f docker-compose.prod.yml pull

echo -e "${GREEN}[3/5] Building Docker images...${NC}"
docker-compose -f docker-compose.prod.yml build

echo -e "${GREEN}[4/5] Starting services...${NC}"
docker-compose -f docker-compose.prod.yml up -d

echo -e "${GREEN}[5/5] Cleaning up old images...${NC}"
docker system prune -f

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Deployment complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "View logs with:"
echo "  docker-compose -f docker-compose.prod.yml logs -f"
echo ""
echo "Check service status:"
echo "  docker-compose -f docker-compose.prod.yml ps"
echo ""
