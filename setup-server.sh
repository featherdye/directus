#!/bin/bash
set -e

echo "================================================"
echo "Directus Server Setup Script for Ubuntu 22.04"
echo "================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Update system
echo -e "${GREEN}[1/6] Updating system packages...${NC}"
apt update && apt upgrade -y

# Install Docker
echo -e "${GREEN}[2/6] Installing Docker...${NC}"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    systemctl start docker
    systemctl enable docker
    echo -e "${YELLOW}✓ Docker installed successfully${NC}"
else
    echo -e "${YELLOW}✓ Docker already installed${NC}"
fi

# Install Docker Compose
echo -e "${GREEN}[3/6] Installing Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    apt install docker-compose -y
    echo -e "${YELLOW}✓ Docker Compose installed successfully${NC}"
else
    echo -e "${YELLOW}✓ Docker Compose already installed${NC}"
fi

# Install Git
echo -e "${GREEN}[4/6] Installing Git...${NC}"
if ! command -v git &> /dev/null; then
    apt install git -y
    echo -e "${YELLOW}✓ Git installed successfully${NC}"
else
    echo -e "${YELLOW}✓ Git already installed${NC}"
fi

# Install Nginx
echo -e "${GREEN}[5/6] Installing Nginx...${NC}"
if ! command -v nginx &> /dev/null; then
    apt install nginx -y
    systemctl start nginx
    systemctl enable nginx
    echo -e "${YELLOW}✓ Nginx installed successfully${NC}"
else
    echo -e "${YELLOW}✓ Nginx already installed${NC}"
fi

# Install Certbot for SSL
echo -e "${GREEN}[6/6] Installing Certbot for SSL...${NC}"
if ! command -v certbot &> /dev/null; then
    apt install certbot python3-certbot-nginx -y
    echo -e "${YELLOW}✓ Certbot installed successfully${NC}"
else
    echo -e "${YELLOW}✓ Certbot already installed${NC}"
fi

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Setup complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Next steps:"
echo "1. Clone your repository: git clone git@github.com:featherdye/directus.git"
echo "2. Navigate to directory: cd directus"
echo "3. Configure environment: cp .env.example .env && nano .env"
echo "4. Deploy: docker-compose -f docker-compose.prod.yml up -d"
echo ""
