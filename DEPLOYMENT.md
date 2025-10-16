# Directus Deployment Guide for DigitalOcean

This guide walks you through deploying Directus on DigitalOcean using Docker.

## Prerequisites

- DigitalOcean account
- Domain name (optional but recommended)
- SSH access to your server

## Option 1: Deploy with DigitalOcean App Platform (Easiest)

### Step 1: Push to GitHub
Your code is already on GitHub at `git@github.com:featherdye/directus.git`

### Step 2: Create App in DigitalOcean
1. Go to [DigitalOcean App Platform](https://cloud.digitalocean.com/apps)
2. Click "Create App"
3. Connect your GitHub repository
4. Select the `featherdye/directus` repository
5. Configure the app:
   - **Resource Type**: Docker
   - **Dockerfile Path**: `/Dockerfile`
   - **HTTP Port**: 8055

### Step 3: Add Database
1. In App Settings, add a managed PostgreSQL database
2. DigitalOcean will automatically inject database credentials

### Step 4: Configure Environment Variables
Add these in the App Platform environment variables section:

```
KEY=<generate-32-char-random-string>
SECRET=<generate-64-char-random-string>
ADMIN_EMAIL=admin@yourdomain.com
ADMIN_PASSWORD=<strong-password>
PUBLIC_URL=${APP_URL}
DB_CLIENT=pg
DB_HOST=${db.HOSTNAME}
DB_PORT=${db.PORT}
DB_DATABASE=${db.DATABASE}
DB_USER=${db.USERNAME}
DB_PASSWORD=${db.PASSWORD}
DB_SSL=true
CORS_ENABLED=true
CORS_ORIGIN=https://yourdomain.com
```

### Step 5: Deploy
Click "Deploy" and wait for the build to complete.

---

## Option 2: Deploy on DigitalOcean Droplet (More Control)

### Step 1: Create a Droplet
1. Go to [DigitalOcean Droplets](https://cloud.digitalocean.com/droplets)
2. Create a new Droplet:
   - **Image**: Ubuntu 22.04 LTS
   - **Size**: Basic plan, $12/month (2GB RAM minimum)
   - **Datacenter**: Choose closest to your users
   - **Authentication**: SSH keys recommended

### Step 2: Connect to Your Droplet
```bash
ssh root@your_droplet_ip
```

### Step 3: Install Docker and Docker Compose
```bash
# Update packages
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
apt install docker-compose -y

# Start Docker
systemctl start docker
systemctl enable docker
```

### Step 4: Clone Your Repository
```bash
# Install git if needed
apt install git -y

# Clone your repo
git clone git@github.com:featherdye/directus.git
cd directus
```

### Step 5: Configure Environment Variables
```bash
# Copy example environment file
cp .env.example .env

# Edit environment variables
nano .env
```

Update the following values:
- `KEY`: Generate with `openssl rand -hex 32`
- `SECRET`: Generate with `openssl rand -hex 64`
- `ADMIN_EMAIL`: Your admin email
- `ADMIN_PASSWORD`: Strong password
- `DB_PASSWORD`: Strong database password
- `PUBLIC_URL`: Your domain or droplet IP

### Step 6: Deploy with Docker Compose
```bash
# Build and start services
docker-compose -f docker-compose.prod.yml up -d

# View logs
docker-compose -f docker-compose.prod.yml logs -f directus
```

### Step 7: Configure Firewall
```bash
# Allow SSH
ufw allow OpenSSH

# Allow HTTP and HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Allow Directus port (or use nginx reverse proxy)
ufw allow 8055/tcp

# Enable firewall
ufw enable
```

### Step 8: Set Up Nginx Reverse Proxy (Recommended)
```bash
# Install Nginx
apt install nginx -y

# Create Nginx configuration
nano /etc/nginx/sites-available/directus
```

Add this configuration:
```nginx
server {
    listen 80;
    server_name yourdomain.com;

    location / {
        proxy_pass http://localhost:8055;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Enable the site:
```bash
ln -s /etc/nginx/sites-available/directus /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
```

### Step 9: Set Up SSL with Let's Encrypt
```bash
# Install Certbot
apt install certbot python3-certbot-nginx -y

# Get SSL certificate
certbot --nginx -d yourdomain.com

# Auto-renewal is set up automatically
```

### Step 10: Set Up Automatic Updates
```bash
# Create update script
nano /root/update-directus.sh
```

Add:
```bash
#!/bin/bash
cd /root/directus
git pull
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d
docker system prune -f
```

Make executable:
```bash
chmod +x /root/update-directus.sh
```

---

## Post-Deployment

### Access Your Directus Instance
- Visit `https://yourdomain.com` or `http://your_droplet_ip:8055`
- Login with your admin credentials
- Import your schema from the `schemas` directory if needed

### Backup Strategy
```bash
# Backup database
docker-compose -f docker-compose.prod.yml exec database pg_dump -U directus directus > backup.sql

# Backup uploads
tar -czf uploads-backup.tar.gz uploads/
```

### Monitoring
```bash
# View logs
docker-compose -f docker-compose.prod.yml logs -f

# Check resource usage
docker stats

# Restart services
docker-compose -f docker-compose.prod.yml restart
```

### Scaling Considerations
- **Storage**: Use DigitalOcean Spaces for file uploads
- **Database**: Use managed PostgreSQL database
- **Caching**: Redis is already configured
- **CDN**: Use DigitalOcean CDN or Cloudflare

---

## Troubleshooting

### Check Service Status
```bash
docker-compose -f docker-compose.prod.yml ps
```

### View Logs
```bash
docker-compose -f docker-compose.prod.yml logs directus
docker-compose -f docker-compose.prod.yml logs database
```

### Restart Services
```bash
docker-compose -f docker-compose.prod.yml restart
```

### Update Directus
```bash
cd /root/directus
git pull
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d
```

---

## Security Best Practices

1. **Change default passwords** - Use strong, unique passwords
2. **Enable SSL/TLS** - Always use HTTPS in production
3. **Restrict database access** - Only allow localhost connections
4. **Regular backups** - Automate daily backups
5. **Update regularly** - Keep Directus and dependencies updated
6. **Use secrets management** - Don't commit `.env` files
7. **Enable rate limiting** - Already configured in docker-compose
8. **Monitor logs** - Set up log monitoring and alerts

---

## Cost Estimate

### App Platform (Easiest)
- Basic plan: ~$12/month
- Managed PostgreSQL: ~$15/month
- **Total**: ~$27/month

### Droplet (More control)
- Droplet (2GB): $12/month
- Managed PostgreSQL (optional): $15/month
- Managed Redis (optional): $15/month
- Spaces (optional): $5/month + transfer
- **Total**: $12-47/month depending on options

---

## Support

For issues related to:
- **Directus**: [Directus Documentation](https://docs.directus.io)
- **DigitalOcean**: [DigitalOcean Support](https://www.digitalocean.com/support)
- **This setup**: Check logs and GitHub issues
