#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "================================================"
echo "Nginx Configuration Script for Directus"
echo "================================================"
echo ""

# Prompt for domain name
read -p "Enter your domain name (e.g., directus.example.com): " DOMAIN

if [ -z "$DOMAIN" ]; then
    echo -e "${RED}Error: Domain name is required!${NC}"
    exit 1
fi

read -p "Enter your email for SSL certificate: " EMAIL

if [ -z "$EMAIL" ]; then
    echo -e "${RED}Error: Email is required!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}[1/4] Creating Nginx configuration...${NC}"

# Create Nginx config
cat > /etc/nginx/sites-available/directus << EOF
server {
    listen 80;
    server_name ${DOMAIN};

    client_max_body_size 100M;

    location / {
        proxy_pass http://localhost:8055;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;

        # Timeouts
        proxy_connect_timeout 600;
        proxy_send_timeout 600;
        proxy_read_timeout 600;
        send_timeout 600;
    }
}
EOF

echo -e "${GREEN}[2/4] Enabling site...${NC}"
ln -sf /etc/nginx/sites-available/directus /etc/nginx/sites-enabled/

echo -e "${GREEN}[3/4] Testing Nginx configuration...${NC}"
nginx -t

echo -e "${GREEN}[4/4] Restarting Nginx...${NC}"
systemctl restart nginx

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Nginx configured successfully!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo -e "${YELLOW}To set up SSL, run:${NC}"
echo "  certbot --nginx -d ${DOMAIN} --email ${EMAIL} --agree-tos --non-interactive"
echo ""
echo -e "${YELLOW}Or run this command now?${NC}"
read -p "Set up SSL now? (y/n): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Setting up SSL with Let's Encrypt...${NC}"
    certbot --nginx -d ${DOMAIN} --email ${EMAIL} --agree-tos --non-interactive
    echo ""
    echo -e "${GREEN}SSL configured successfully!${NC}"
    echo "Your Directus instance is now available at: https://${DOMAIN}"
else
    echo "You can set up SSL later with the command above."
    echo "Your Directus instance is available at: http://${DOMAIN}"
fi

echo ""
