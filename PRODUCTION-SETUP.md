# Production Setup Guide

Quick start guide for deploying AxiomCore to production.

## Prerequisites

- Docker 24.x or higher
- Node.js 18.x or higher
- AWS CLI configured (for cloud deployment)
- Terraform 1.0+ (for infrastructure deployment)

## Local Development

### 1. Setup Environment Variables

```bash
# API
cp api/.env.example api/.env
# Edit api/.env with your configuration

# Frontend
cp frontend/.env.example frontend/.env
# Edit frontend/.env with your configuration
```

### 2. Build and Run with Docker Compose

```bash
# Build images
docker compose build

# Start services
docker compose up -d

# View logs
docker compose logs -f

# Check health
curl http://localhost:8080/health
curl http://localhost:3000/health

# Stop services
docker compose down
```

### 3. Run with Monitoring (Optional)

```bash
# Start with monitoring stack
docker compose --profile monitoring up -d

# Access Grafana: http://localhost:3001 (admin/admin)
# Access Prometheus: http://localhost:9090
```

## Production Deployment

### Option 1: AWS with Terraform

```bash
cd infra/terraform

# Initialize Terraform
terraform init

# Create terraform.tfvars from example
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings

# Plan deployment
terraform plan -out=tfplan

# Apply infrastructure
terraform apply tfplan
```

### Option 2: Manual Docker Deployment

```bash
# Build production images
docker build -t axiomcore/api:latest ./api
docker build -t axiomcore/frontend:latest ./frontend

# Push to registry
docker push axiomcore/api:latest
docker push axiomcore/frontend:latest

# Deploy on server
docker compose -f docker-compose.yml up -d
```

### Option 3: CI/CD via GitHub Actions

Push to main branch to trigger automated deployment:

```bash
git checkout main
git merge develop
git push origin main
```

The `.github/workflows/production-ci-cd.yml` workflow will:
1. Run security scans
2. Execute tests
3. Build Docker images
4. Deploy to production (if on main branch)

## Monitoring

### Prometheus Metrics

Access at: `http://localhost:9090` (local) or your production URL

Key metrics:
- API response times
- Error rates
- CPU/Memory usage
- Request throughput

### Grafana Dashboards

Access at: `http://localhost:3001` (local) or your production URL

Default credentials: `admin/admin` (change on first login)

### CloudWatch Logs (AWS)

```bash
# View API logs
aws logs tail /aws/ecs/axiomcore/api --follow

# View Frontend logs
aws logs tail /aws/ecs/axiomcore/frontend --follow
```

## Health Checks

### API Health Check
```bash
curl http://localhost:8080/health
# Response: {"uptime":123,"message":"OK","timestamp":1234567890}
```

### Frontend Health Check
```bash
curl http://localhost:3000/health
# Response: HTTP 200 OK
```

## Troubleshooting

### Services Won't Start

1. Check logs: `docker compose logs`
2. Verify environment variables are set
3. Ensure ports 3000 and 8080 are available
4. Check Docker daemon is running

### High Memory Usage

1. Check container stats: `docker stats`
2. Increase memory limits in docker-compose.yml
3. Review application logs for memory leaks

### Connection Issues

1. Verify network configuration: `docker network ls`
2. Check firewall rules
3. Verify security group settings (AWS)

## Documentation

For comprehensive documentation, see:

- [Production Deployment Checklist](docs/PRODUCTION-DEPLOYMENT-CHECKLIST.md)
- [Production Operations Guide](docs/PRODUCTION-OPERATIONS.md)
- [Production Readiness Report](docs/PRODUCTION-READINESS.md)

## Support

- Primary Maintainer: FARICJH59
- Email: farichva@gmail.com
- Repository: https://github.com/FARICJH59/README-.gitignore-license

## Quick Commands Reference

```bash
# Start services
docker compose up -d

# View logs
docker compose logs -f api
docker compose logs -f frontend

# Restart a service
docker compose restart api

# Scale services
docker compose up -d --scale api=3

# Stop all services
docker compose down

# Remove volumes
docker compose down -v

# Pull latest images
docker compose pull

# Rebuild and restart
docker compose up -d --build

# Check service status
docker compose ps

# Execute command in container
docker compose exec api sh
```
