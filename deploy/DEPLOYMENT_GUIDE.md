# SE-QPT Deployment Guide - DigitalOcean

This guide walks you through deploying SE-QPT on a DigitalOcean Droplet using Docker.

## Prerequisites

- DigitalOcean account with $200 student credit
- Domain name (optional, can use droplet IP)
- OpenAI API key

---

## Architecture Overview

```
+------------------+     +------------------+     +------------------+
|    Frontend      |     |     Backend      |     |    Database      |
|    (Nginx)       |---->|    (Flask +      |---->|   (PostgreSQL)   |
|    Port 80       |     |    Gunicorn)     |     |    Port 5432     |
|                  |     |    Port 5000     |     |                  |
+------------------+     +------------------+     +------------------+
        |                        |
        |                        +-- src/backend/config/
        |                        +-- src/backend/data/templates/
        +-- Static Vue.js build
```

**Data Dependencies (co-located with backend):**
- `src/backend/config/learning_objectives_config.json` - LO configuration
- `src/backend/data/templates/se_qpt_learning_objectives_template_v2.json` - LO templates
- `src/backend/data/pmt_examples/` - PMT reference example files

---

## Step 1: Create Droplet

1. Log into DigitalOcean
2. Create Droplet:
   - **Image**: Ubuntu 22.04 LTS
   - **Plan**: Basic $12/mo (2GB RAM, 1 CPU, 50GB SSD)
   - **Datacenter**: Choose closest to users (Frankfurt for EU)
   - **Authentication**: SSH Key (recommended) or Password
   - **Hostname**: `seqpt-production`

3. Note your Droplet's IP address

---

## Step 2: Initial Server Setup

SSH into your droplet:
```bash
ssh root@YOUR_DROPLET_IP
```

Update system and install Docker:
```bash
# Update packages
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
apt install docker-compose-plugin -y

# Verify installation
docker --version
docker compose version

# Add swap for 2GB droplet (recommended)
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

---

## Step 3: Clone Repository

```bash
# Install git
apt install git -y

# Clone your repo
cd /opt
git clone https://github.com/jmngeo/SEQPT.git seqpt
cd seqpt
```

---

## Step 4: Configure Environment

```bash
# Copy example env file
cp .env.example .env

# Edit with your values
nano .env
```

Set these values in `.env`:
```
POSTGRES_USER=seqpt_admin
POSTGRES_PASSWORD=YOUR_SECURE_PASSWORD_HERE
POSTGRES_DB=seqpt_database

FLASK_ENV=production
SECRET_KEY=YOUR_SECRET_KEY_HERE

OPENAI_API_KEY=sk-your-openai-key-here
```

Generate a secure secret key:
```bash
python3 -c "import secrets; print(secrets.token_hex(32))"
```

---

## Step 5: Build and Start Services

```bash
# Build and start all services
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build

# Check status
docker compose ps

# View logs
docker compose logs -f
```

---

## Step 6: Initialize Database

After containers are running, initialize the database:

```bash
# Enter backend container
docker compose exec backend bash

# Inside container, run setup scripts (working dir is /app/src/backend)
python setup/populate/populate_competencies.py
python setup/database_objects/create_stored_procedures.py
python setup/database_objects/create_role_competency_matrix.py

# Exit container
exit
```

---

## Step 7: Verify Deployment

1. **Check health endpoint**:
   ```bash
   curl http://YOUR_DROPLET_IP/api/health
   ```

2. **Access the app**:
   Open `http://YOUR_DROPLET_IP` in browser

---

## Step 8: Setup Domain (Optional)

If you have a domain:

1. Add A record pointing to your Droplet IP
2. Install Certbot for SSL:
   ```bash
   apt install certbot python3-certbot-nginx -y
   ```

3. Update nginx config for your domain and get SSL certificate

---

## Maintenance Commands

```bash
# View logs
docker compose logs -f backend
docker compose logs -f frontend
docker compose logs -f db

# Restart services
docker compose restart

# Stop all services
docker compose down

# Update deployment
cd /opt/seqpt
git pull
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build

# Database backup
docker compose exec db pg_dump -U seqpt_admin seqpt_database > backup_$(date +%Y%m%d).sql

# Check resource usage
docker stats
```

---

## Troubleshooting

### Container won't start
```bash
docker compose logs backend
docker compose logs db
```

### Database connection error
```bash
# Check if DB is healthy
docker compose ps
docker compose exec db pg_isready -U seqpt_admin
```

### Out of memory
```bash
# Check memory
free -h

# If swap not enabled, add it (see Step 2)
```

### Port already in use
```bash
# Find what's using port 80
lsof -i :80
```

---

## Cost Summary

| Service | Monthly Cost |
|---------|--------------|
| Droplet (2GB) | $12 |
| **Total** | **$12/mo** |

With $200 credit = **16+ months free**

---

## Security Checklist

- [ ] Changed default PostgreSQL password
- [ ] Generated secure SECRET_KEY
- [ ] OpenAI API key not committed to git
- [ ] Firewall configured (UFW)
- [ ] SSH key authentication enabled
- [ ] Regular backups scheduled

---

## Quick Reference

| URL | Purpose |
|-----|---------|
| `http://YOUR_IP` | Frontend |
| `http://YOUR_IP/api/health` | Backend health check |
| `http://YOUR_IP/api/*` | All API endpoints |

| Container | Port |
|-----------|------|
| frontend | 80 |
| backend | 5000 (internal) |
| db | 5432 (internal) |
