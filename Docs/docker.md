# 🐳 Docker & Nginx Documentation

This document provides comprehensive information about Docker containerization and Nginx configuration for the RedBus DevOps project.

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Docker Architecture](#-docker-architecture)
- [Docker Images](#-docker-images)
- [Frontend Dockerfile](#-frontend-dockerfile)
- [Backend Dockerfile](#-backend-dockerfile)
- [Nginx Configuration](#-nginx-configuration)
- [Docker Installation](#-docker-installation)
- [Building Images](#-building-images)
- [Running Containers](#-running-containers)
- [Docker Compose](#-docker-compose)
- [Pushing to ECR](#-pushing-to-ecr)
- [Best Practices](#-best-practices)
- [Troubleshooting](#-troubleshooting)

---

## 📌 Overview

The project uses Docker for containerizing both frontend and backend applications with optimized, production-ready configurations.

### Container Summary

| Container | Base Image | Size | Port | Purpose |
|-----------|------------|------|------|---------|
| redbus-frontend | nginx:alpine | ~25MB | 80 | React SPA + Nginx |
| redbus-backend | node:18-alpine | ~150MB | 5000 | Express API |

### File Structure

```
docker/
├── frontend.Dockerfile    # Multi-stage React build with Nginx
├── backend.Dockerfile     # Node.js Express API container
└── nginx.conf             # Nginx production configuration
```

---

## 🏗️ Docker Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        DOCKER CONTAINER ARCHITECTURE                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      FRONTEND CONTAINER                              │   │
│  │                                                                      │   │
│  │   ┌──────────────────────┐    ┌────────────────────────────────┐   │   │
│  │   │    Stage 1: Build    │    │     Stage 2: Production        │   │   │
│  │   │   node:18-alpine     │───▶│        nginx:alpine            │   │   │
│  │   │                      │    │                                │   │   │
│  │   │   - npm install      │    │   - Static files only          │   │   │
│  │   │   - npm run build    │    │   - Gzip compression           │   │   │
│  │   │   - ~500MB           │    │   - Security headers           │   │   │
│  │   │                      │    │   - ~25MB final size           │   │   │
│  │   └──────────────────────┘    └────────────────────────────────┘   │   │
│  │                                           │                         │   │
│  │                                           ▼                         │   │
│  │                                      Port 80                        │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      BACKEND CONTAINER                               │   │
│  │                                                                      │   │
│  │   ┌────────────────────────────────────────────────────────────┐   │   │
│  │   │                    node:18-alpine                           │   │   │
│  │   │                                                             │   │   │
│  │   │   - Security patches (libcrypto3, libssl3)                  │   │   │
│  │   │   - Non-root user (nodeuser:1001)                          │   │   │
│  │   │   - Production dependencies only                            │   │   │
│  │   │   - Health check endpoint                                   │   │   │
│  │   │   - ~150MB final size                                       │   │   │
│  │   │                                                             │   │   │
│  │   └────────────────────────────────────────────────────────────┘   │   │
│  │                                           │                         │   │
│  │                                           ▼                         │   │
│  │                                      Port 5000                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📦 Docker Images

### Image Specifications

| Attribute | Frontend | Backend |
|-----------|----------|---------|
| **Base Image** | nginx:alpine | node:18-alpine |
| **Build Type** | Multi-stage | Single-stage |
| **Final Size** | ~25MB | ~150MB |
| **Port** | 80 | 5000 |
| **User** | nginx (default) | nodeuser (1001) |
| **Health Check** | wget localhost | wget localhost:5000/health |

### Why Alpine?

| Benefit | Description |
|---------|-------------|
| **Small Size** | Alpine is ~5MB vs ~100MB+ for full images |
| **Security** | Minimal attack surface |
| **Fast Pulls** | Quick deployments |
| **Production Ready** | Used by many enterprises |

---

## 🎨 Frontend Dockerfile

### Complete Dockerfile

```dockerfile
# Frontend Dockerfile - Multi-stage build for React application
# Stage 1: Build
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY front-end-redbus/package*.json ./

# Install dependencies (using npm install for better compatibility)
RUN npm install --legacy-peer-deps

# Copy source code
COPY front-end-redbus/ .

# Build the application
RUN npm run build

# Stage 2: Production
FROM nginx:alpine

# Copy custom nginx config
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# Copy built assets from builder stage
COPY --from=builder /app/build /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
```

### Stage Breakdown

#### Stage 1: Builder

| Step | Purpose |
|------|---------|
| `FROM node:18-alpine AS builder` | Use Node.js for building React app |
| `WORKDIR /app` | Set working directory |
| `COPY package*.json ./` | Copy only package files first (layer caching) |
| `npm install --legacy-peer-deps` | Install dependencies with compatibility flag |
| `COPY front-end-redbus/ .` | Copy source code |
| `npm run build` | Build production bundle |

#### Stage 2: Production

| Step | Purpose |
|------|---------|
| `FROM nginx:alpine` | Fresh minimal image |
| `COPY nginx.conf` | Custom Nginx configuration |
| `COPY --from=builder` | Copy only built files (~5MB) |
| `EXPOSE 80` | Document exposed port |
| `HEALTHCHECK` | Container health monitoring |
| `CMD` | Start Nginx in foreground |

### Multi-stage Benefits

| Benefit | Before | After |
|---------|--------|-------|
| **Image Size** | ~500MB | ~25MB |
| **Build Tools** | Included | Excluded |
| **node_modules** | Included | Excluded |
| **Security** | More surface | Minimal |

---

## 🖥️ Backend Dockerfile

### Complete Dockerfile

```dockerfile
# Backend Dockerfile - Node.js Express API
FROM node:18-alpine

# Update Alpine packages to fix security vulnerabilities (CVE-2025-15467)
RUN apk update && apk upgrade --no-cache libcrypto3 libssl3

# Create app directory
WORKDIR /app

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodeuser -u 1001

# Copy package files
COPY back-end-redbus/package*.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy source code
COPY back-end-redbus/ .

# Change ownership to non-root user
RUN chown -R nodeuser:nodejs /app

# Switch to non-root user
USER nodeuser

# Expose port 5000
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:5000/health || exit 1

# Start the application
CMD ["node", "app.js"]
```

### Security Features

| Feature | Implementation | Purpose |
|---------|----------------|---------|
| **Security Patches** | `apk upgrade libcrypto3 libssl3` | Fix CVE vulnerabilities |
| **Non-root User** | `USER nodeuser` | Prevent privilege escalation |
| **Production Deps** | `npm ci --only=production` | Exclude dev dependencies |
| **Clean Cache** | `npm cache clean --force` | Reduce image size |
| **Health Check** | `HEALTHCHECK` | Container health monitoring |

### Step-by-Step Explanation

| Step | Command | Purpose |
|------|---------|---------|
| 1 | `FROM node:18-alpine` | Minimal Node.js image |
| 2 | `apk update && apk upgrade` | Patch security vulnerabilities |
| 3 | `WORKDIR /app` | Set working directory |
| 4 | `addgroup && adduser` | Create non-root user |
| 5 | `COPY package*.json` | Layer caching for dependencies |
| 6 | `npm ci --only=production` | Install production deps only |
| 7 | `COPY back-end-redbus/` | Copy source code |
| 8 | `chown -R nodeuser:nodejs` | Transfer ownership |
| 9 | `USER nodeuser` | Switch to non-root |
| 10 | `EXPOSE 5000` | Document port |
| 11 | `HEALTHCHECK` | Health monitoring |
| 12 | `CMD ["node", "app.js"]` | Start application |

---

## 🌐 Nginx Configuration

### Complete nginx.conf

```nginx
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml text/javascript;
    gzip_min_length 1000;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Handle React Router
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API proxy to backend
    location /api {
        proxy_pass http://backend-service:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
```

### Configuration Breakdown

#### Basic Server Settings

```nginx
server {
    listen 80;                          # Listen on port 80
    server_name localhost;              # Server name
    root /usr/share/nginx/html;         # Document root
    index index.html;                   # Default file
}
```

#### Gzip Compression

| Setting | Value | Purpose |
|---------|-------|---------|
| `gzip on` | Enabled | Compress responses |
| `gzip_types` | Multiple MIME types | Which content to compress |
| `gzip_min_length` | 1000 bytes | Minimum size to compress |

**Compression Benefits:**
- Reduces bandwidth by 60-80%
- Faster page loads
- Lower data transfer costs

#### Security Headers

| Header | Value | Protection |
|--------|-------|------------|
| `X-Frame-Options` | SAMEORIGIN | Prevents clickjacking |
| `X-Content-Type-Options` | nosniff | Prevents MIME sniffing |
| `X-XSS-Protection` | 1; mode=block | XSS filter |

#### React Router Support

```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

| Purpose | Description |
|---------|-------------|
| SPA Routing | Redirects all routes to index.html |
| Client-side Routing | React Router handles navigation |
| 404 Prevention | Prevents 404 on direct URL access |

#### API Proxy

```nginx
location /api {
    proxy_pass http://backend-service:5000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_cache_bypass $http_upgrade;
}
```

| Header | Purpose |
|--------|---------|
| `proxy_pass` | Forward to backend service |
| `Upgrade` | Support WebSocket connections |
| `X-Real-IP` | Pass client's real IP |
| `X-Forwarded-For` | Proxy chain information |
| `X-Forwarded-Proto` | Original protocol (http/https) |

#### Static Asset Caching

```nginx
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

| Setting | Value | Purpose |
|---------|-------|---------|
| `expires` | 1 year | Browser cache duration |
| `Cache-Control` | public, immutable | CDN & browser caching |

**Cached File Types:**
- JavaScript (`.js`)
- CSS (`.css`)
- Images (`.png`, `.jpg`, `.gif`, `.ico`, `.svg`)
- Fonts (`.woff`, `.woff2`, `.ttf`, `.eot`)

#### Health Check Endpoint

```nginx
location /health {
    access_log off;                     # Don't log health checks
    return 200 "healthy\n";             # Return 200 OK
    add_header Content-Type text/plain; # Plain text response
}
```

**Used by:**
- Kubernetes liveness probes
- Kubernetes readiness probes
- Load balancer health checks

---

## 🔧 Docker Installation

### Amazon Linux / EC2

```bash
#!/bin/bash
# Script location: scripts/devops/docker.sh

# Update the package list
sudo yum update -y

# Install Docker
sudo yum install docker -y

# Start Docker service
sudo systemctl start docker

# Enable Docker to start on boot
sudo systemctl enable docker

# Add users to docker group
sudo usermod -aG docker ec2-user
sudo usermod -aG docker jenkins

# Set correct permissions for Docker socket
sudo chmod 660 /var/run/docker.sock
sudo chown root:docker /var/run/docker.sock

# Restart Docker service
sudo systemctl restart docker

# Apply new group settings
newgrp docker

# Verify installation
docker --version
```

### Ubuntu/Debian

```bash
# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER
```

### macOS

```bash
# Using Homebrew
brew install --cask docker

# Or download Docker Desktop from:
# https://www.docker.com/products/docker-desktop
```

### Verify Installation

```bash
# Check Docker version
docker --version

# Check Docker is running
docker info

# Run test container
docker run hello-world
```

---

## 🏗️ Building Images

### Build Frontend Image

```bash
# From project root directory
docker build -f docker/frontend.Dockerfile -t redbus-frontend:latest .

# With build arguments
docker build -f docker/frontend.Dockerfile \
  --build-arg REACT_APP_BACKEND_URL=http://api.example.com \
  -t redbus-frontend:latest .

# Build with no cache
docker build -f docker/frontend.Dockerfile \
  --no-cache \
  -t redbus-frontend:latest .
```

### Build Backend Image

```bash
# From project root directory
docker build -f docker/backend.Dockerfile -t redbus-backend:latest .

# With specific tag
docker build -f docker/backend.Dockerfile -t redbus-backend:v1.0.0 .
```

### Build Both Images

```bash
# Build script
#!/bin/bash
VERSION=${1:-latest}

echo "Building frontend..."
docker build -f docker/frontend.Dockerfile -t redbus-frontend:$VERSION .

echo "Building backend..."
docker build -f docker/backend.Dockerfile -t redbus-backend:$VERSION .

echo "Build complete!"
docker images | grep redbus
```

### View Built Images

```bash
# List all images
docker images

# Filter redbus images
docker images | grep redbus

# Inspect image
docker inspect redbus-frontend:latest

# Check image size
docker images redbus-frontend --format "{{.Size}}"
```

---

## 🚀 Running Containers

### Run Frontend Container

```bash
# Basic run
docker run -d -p 3000:80 --name frontend redbus-frontend:latest

# With environment variables
docker run -d -p 3000:80 \
  -e BACKEND_URL=http://localhost:5000 \
  --name frontend \
  redbus-frontend:latest

# Check logs
docker logs frontend

# Access shell
docker exec -it frontend sh
```

### Run Backend Container

```bash
# Basic run
docker run -d -p 5000:5000 --name backend redbus-backend:latest

# With environment variables
docker run -d -p 5000:5000 \
  -e MONGODB_URI="<YOUR_MONGODB_URI>" \
  -e STRIPE_SECRET_KEY="<YOUR_STRIPE_SECRET_KEY>" \
  -e PORT=5000 \
  --name backend \
  redbus-backend:latest

# Check logs
docker logs -f backend

# Access shell
docker exec -it backend sh
```

### Container Management

```bash
# List running containers
docker ps

# List all containers
docker ps -a

# Stop container
docker stop frontend backend

# Start container
docker start frontend backend

# Restart container
docker restart frontend

# Remove container
docker rm frontend backend

# Remove all stopped containers
docker container prune
```

---

## 🐙 Docker Compose

### docker-compose.yml

```yaml
version: '3.8'

services:
  frontend:
    build:
      context: .
      dockerfile: docker/frontend.Dockerfile
    ports:
      - "3000:80"
    depends_on:
      - backend
    networks:
      - redbus-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

  backend:
    build:
      context: .
      dockerfile: docker/backend.Dockerfile
    ports:
      - "5000:5000"
    environment:
      - MONGODB_URI=mongodb://mongo:27017/redbus
      - PORT=5000
      - NODE_ENV=production
    depends_on:
      - mongo
    networks:
      - redbus-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 15s

  mongo:
    image: mongo:5.0
    ports:
      - "27017:27017"
    volumes:
      - mongo-data:/data/db
    networks:
      - redbus-network
    restart: unless-stopped

networks:
  redbus-network:
    driver: bridge

volumes:
  mongo-data:
    driver: local
```

### Docker Compose Commands

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f backend

# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# Rebuild images
docker-compose build

# Rebuild and start
docker-compose up -d --build

# Scale services
docker-compose up -d --scale backend=3

# Check status
docker-compose ps
```

---

## 📤 Pushing to ECR

### Prerequisites

```bash
# Configure AWS CLI
aws configure

# Verify credentials
aws sts get-caller-identity
```

### Push to Amazon ECR

```bash
# Set variables
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_REGISTRY

# Create repositories (if not exists)
aws ecr create-repository --repository-name redbus-frontend --region $AWS_REGION
aws ecr create-repository --repository-name redbus-backend --region $AWS_REGION

# Tag images
docker tag redbus-frontend:latest ${ECR_REGISTRY}/redbus-frontend:latest
docker tag redbus-backend:latest ${ECR_REGISTRY}/redbus-backend:latest

# Push images
docker push ${ECR_REGISTRY}/redbus-frontend:latest
docker push ${ECR_REGISTRY}/redbus-backend:latest
```

### Push Script

```bash
#!/bin/bash
# push-to-ecr.sh

VERSION=${1:-latest}
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_REGISTRY

echo "🏷️ Tagging images..."
docker tag redbus-frontend:$VERSION ${ECR_REGISTRY}/redbus-frontend:$VERSION
docker tag redbus-backend:$VERSION ${ECR_REGISTRY}/redbus-backend:$VERSION

echo "📤 Pushing frontend..."
docker push ${ECR_REGISTRY}/redbus-frontend:$VERSION

echo "📤 Pushing backend..."
docker push ${ECR_REGISTRY}/redbus-backend:$VERSION

echo "✅ Push complete!"
```

---

## ✅ Best Practices

### Dockerfile Best Practices

| Practice | Implementation | Benefit |
|----------|----------------|---------|
| Use specific base image tags | `node:18-alpine` not `node:latest` | Reproducible builds |
| Multi-stage builds | Frontend Dockerfile | Smaller images |
| Non-root user | `USER nodeuser` | Security |
| Layer caching | Copy package.json first | Faster builds |
| .dockerignore | Exclude unnecessary files | Smaller context |
| Health checks | `HEALTHCHECK` instruction | Container monitoring |
| Clean up | `npm cache clean --force` | Smaller images |

### Recommended .dockerignore

```
# .dockerignore
node_modules
npm-debug.log
.git
.gitignore
.env
.env.*
Dockerfile*
docker-compose*
README.md
.vscode
.idea
coverage
.nyc_output
*.log
```

### Security Best Practices

| Practice | How |
|----------|-----|
| Scan images | Use Trivy: `trivy image redbus-backend:latest` |
| Update base images | Regularly rebuild with latest patches |
| Use non-root users | Create and switch to unprivileged user |
| Minimize image size | Use Alpine, multi-stage builds |
| Don't store secrets | Use environment variables or secrets management |
| Use read-only filesystem | `--read-only` flag when possible |

---

## 🔧 Troubleshooting

### Common Issues

#### 1. Build Fails - npm install

```bash
# Error: npm ERR! peer dep missing

# Solution: Use legacy-peer-deps
npm install --legacy-peer-deps
```

#### 2. Container Won't Start

```bash
# Check logs
docker logs <container_id>

# Run interactively
docker run -it redbus-backend:latest sh

# Check health
docker inspect --format='{{.State.Health.Status}}' <container_id>
```

#### 3. Permission Denied

```bash
# Error: permission denied while trying to connect to Docker daemon

# Solution: Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

#### 4. Port Already in Use

```bash
# Error: port is already allocated

# Find process using port
lsof -i :5000
# or on Linux
netstat -tulpn | grep 5000

# Kill the process or use different port
docker run -p 5001:5000 redbus-backend:latest
```

#### 5. Image Too Large

```bash
# Check layer sizes
docker history redbus-backend:latest

# Solutions:
# 1. Use Alpine base images
# 2. Multi-stage builds
# 3. Clean up in same layer
# 4. Use .dockerignore
```

#### 6. Container Can't Connect to MongoDB

```bash
# In Docker Compose, use service name
MONGODB_URI=mongodb://mongo:27017/redbus

# Not localhost
# WRONG: MONGODB_URI=mongodb://localhost:27017/redbus
```

### Debugging Commands

```bash
# View container logs
docker logs -f <container>

# Execute command in container
docker exec -it <container> sh

# Inspect container
docker inspect <container>

# Check network
docker network ls
docker network inspect <network>

# Check container processes
docker top <container>

# Monitor resource usage
docker stats
```

---

## 📊 Quick Reference

### Dockerfile Commands

| Command | Purpose |
|---------|---------|
| `FROM` | Set base image |
| `WORKDIR` | Set working directory |
| `COPY` | Copy files |
| `RUN` | Execute command |
| `ENV` | Set environment variable |
| `EXPOSE` | Document port |
| `USER` | Set user |
| `HEALTHCHECK` | Health check config |
| `CMD` | Default command |
| `ENTRYPOINT` | Main executable |

### Docker CLI Commands

| Command | Purpose |
|---------|---------|
| `docker build` | Build image |
| `docker run` | Run container |
| `docker ps` | List containers |
| `docker images` | List images |
| `docker logs` | View logs |
| `docker exec` | Execute in container |
| `docker stop` | Stop container |
| `docker rm` | Remove container |
| `docker rmi` | Remove image |
| `docker prune` | Clean up |

---

<p align="center">
  <b>🐳 Docker & Nginx Configuration for RedBus DevOps Project</b>
</p>
