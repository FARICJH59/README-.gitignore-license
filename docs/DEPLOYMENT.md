# Deployment Guide

This guide covers deployment of AxiomCore to various cloud providers and local environments.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Local Development](#local-development)
3. [Cloud Deployment](#cloud-deployment)
   - [Google Cloud Platform (GCP)](#google-cloud-platform-gcp)
   - [Amazon Web Services (AWS)](#amazon-web-services-aws)
   - [Microsoft Azure](#microsoft-azure)
   - [Google Cloud Run](#google-cloud-run)
4. [Post-Deployment Configuration](#post-deployment-configuration)
5. [Monitoring Setup](#monitoring-setup)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools
- **PowerShell 7.0+**: Cross-platform automation
- **Docker 24.x+**: Container runtime
- **kubectl**: Kubernetes CLI
- **Git**: Version control

### Cloud Provider CLIs (as needed)
- **AWS**: `aws` CLI configured with credentials
- **GCP**: `gcloud` CLI configured with credentials  
- **Azure**: `az` CLI configured with credentials

### Optional Tools
- **Terraform**: Infrastructure as Code
- **Helm**: Kubernetes package manager
- **gh**: GitHub CLI for CI/CD integration

## Local Development

### Quick Start with Docker Compose

```bash
# Clone the repository
git clone https://github.com/FARICJH59/README-.gitignore-license.git
cd README-.gitignore-license

# Start all services
docker-compose -f infra/docker-compose.yml up -d

# Check service status
docker-compose -f infra/docker-compose.yml ps

# View logs
docker-compose -f infra/docker-compose.yml logs -f

# Access the application
# Frontend: http://localhost:3000
# API Gateway: http://localhost:8081-8084
# Grafana: http://localhost:3001
# Prometheus: http://localhost:9090
```

### Configuration

Create a `.env` file for local environment variables:

```bash
# .env
NODE_ENV=development
LOG_LEVEL=debug
GRAFANA_PASSWORD=secure_password
```

### Stopping Services

```bash
# Stop all services
docker-compose -f infra/docker-compose.yml down

# Stop and remove volumes
docker-compose -f infra/docker-compose.yml down -v
```

## Cloud Deployment

### Google Cloud Platform (GCP)

#### One-Command Deployment

```powershell
.\scripts\autonomous-deploy.ps1 `
    -Environment production `
    -Provider gcp `
    -ProjectName "axiomcore" `
    -BaseDomain "example.com" `
    -EnableMonitoring `
    -EnableSSL `
    -ConfigureDNS
```

#### Manual Step-by-Step

1. **Setup GCP Project**
```bash
# Set project
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable container.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable dns.googleapis.com
```

2. **Create GKE Cluster**
```bash
# Using gcloud
gcloud container clusters create axiomcore-production \
    --region us-central1 \
    --num-nodes 3 \
    --machine-type n1-standard-2

# Or using Terraform
cd infra/terraform/gcp
terraform init
terraform apply -var="gcp_project_id=YOUR_PROJECT_ID"
```

3. **Deploy Application**
```bash
# Get cluster credentials
gcloud container clusters get-credentials axiomcore-production --region us-central1

# Apply Kubernetes manifests
kubectl apply -f infra/kubernetes/namespace.yaml
kubectl apply -f infra/kubernetes/configmap.yaml
kubectl apply -f infra/kubernetes/rbac.yaml
kubectl apply -f infra/kubernetes/
```

4. **Configure DNS**
```powershell
.\scripts\configure-dns-urls.ps1 `
    -ProjectName "axiomcore" `
    -BaseDomain "example.com" `
    -DnsProvider gcp `
    -LoadBalancerIP "LOAD_BALANCER_IP" `
    -EnableSSL
```

### Amazon Web Services (AWS)

#### One-Command Deployment

```powershell
.\scripts\autonomous-deploy.ps1 `
    -Environment production `
    -Provider aws `
    -ProjectName "axiomcore" `
    -BaseDomain "example.com" `
    -EnableMonitoring `
    -EnableSSL `
    -ConfigureDNS
```

#### Manual Step-by-Step

1. **Create EKS Cluster**
```bash
# Using Terraform
cd infra/terraform/aws
terraform init
terraform apply -var="aws_region=us-east-1"

# Or using eksctl
eksctl create cluster \
    --name axiomcore-production \
    --region us-east-1 \
    --nodegroup-name standard-workers \
    --node-type t3.medium \
    --nodes 3
```

2. **Update kubectl context**
```bash
aws eks update-kubeconfig --region us-east-1 --name axiomcore-production
```

3. **Deploy Application**
```bash
kubectl apply -f infra/kubernetes/namespace.yaml
kubectl apply -f infra/kubernetes/configmap.yaml
kubectl apply -f infra/kubernetes/rbac.yaml
kubectl apply -f infra/kubernetes/
```

4. **Configure Route53 DNS**
```powershell
.\scripts\configure-dns-urls.ps1 `
    -ProjectName "axiomcore" `
    -BaseDomain "example.com" `
    -DnsProvider aws `
    -EnableSSL
```

### Microsoft Azure

#### One-Command Deployment

```powershell
.\scripts\autonomous-deploy.ps1 `
    -Environment production `
    -Provider azure `
    -ProjectName "axiomcore" `
    -BaseDomain "example.com" `
    -EnableMonitoring `
    -EnableSSL `
    -ConfigureDNS
```

#### Manual Step-by-Step

1. **Create Resource Group**
```bash
az group create --name axiomcore-rg --location eastus
```

2. **Create AKS Cluster**
```bash
# Using Terraform
cd infra/terraform/azure
terraform init
terraform apply

# Or using az CLI
az aks create \
    --resource-group axiomcore-rg \
    --name axiomcore-production \
    --node-count 3 \
    --node-vm-size Standard_D2_v2 \
    --enable-managed-identity
```

3. **Get AKS credentials**
```bash
az aks get-credentials --resource-group axiomcore-rg --name axiomcore-production
```

4. **Deploy Application**
```bash
kubectl apply -f infra/kubernetes/
```

### Google Cloud Run

Cloud Run provides a serverless container platform.

```bash
# Build and deploy
gcloud builds submit --config infra/cloudbuild.yaml

# Deploy frontend
gcloud run deploy axiomcore-frontend \
    --image gcr.io/PROJECT_ID/axiomcore-frontend:latest \
    --region us-central1 \
    --platform managed \
    --allow-unauthenticated

# Deploy API services
gcloud run deploy axiomcore-api \
    --image gcr.io/PROJECT_ID/axiomcore-api:latest \
    --region us-central1 \
    --platform managed
```

## Post-Deployment Configuration

### Verify Deployment

```bash
# Check pod status
kubectl get pods -n axiomcore

# Check services
kubectl get services -n axiomcore

# Check ingress
kubectl get ingress -n axiomcore
```

### Setup Monitoring

```powershell
# Initialize monitoring
.\scripts\monitoring-alerting.ps1 -Action setup -Namespace axiomcore

# Start continuous monitoring with auto-redeploy
.\scripts\monitoring-alerting.ps1 `
    -Action monitor `
    -Namespace axiomcore `
    -CheckInterval 60 `
    -AutoRedeploy `
    -Continuous
```

### Configure Security

```powershell
# Apply RBAC policies
.\scripts\security-compliance.ps1 -Action rbac -Namespace axiomcore

# Run security scan
.\scripts\security-compliance.ps1 -Action scan -Namespace axiomcore

# Generate security report
.\scripts\security-compliance.ps1 -Action report -Namespace axiomcore
```

### Access Application

Your application will be available at:
- **Frontend**: `https://axiomcore-{environment}.{domain}`
- **API Gateway**: `https://api.axiomcore-{environment}.{domain}`
- **Grafana**: `https://grafana.axiomcore-{environment}.{domain}`
- **Prometheus**: `https://monitoring.axiomcore-{environment}.{domain}`

## Monitoring Setup

### Grafana Configuration

1. **Access Grafana**
   - URL: `https://grafana.axiomcore-{env}.{domain}` or `http://localhost:3001`
   - Default credentials: admin / admin (change on first login)

2. **Import Dashboards**
   - Pre-configured dashboards are automatically provisioned
   - Available dashboards:
     - Service Overview
     - API Performance
     - ML Model Metrics
     - IoT Telemetry

3. **Configure Alerts**
   ```powershell
   # View active alerts
   .\scripts\monitoring-alerting.ps1 -Action alert -Namespace axiomcore
   ```

### Prometheus Configuration

- Metrics endpoint: `/metrics`
- Scrape interval: 15 seconds
- Retention: 15 days (configurable)

## Troubleshooting

### Common Issues

#### Pods Not Starting

```bash
# Check pod events
kubectl describe pod <pod-name> -n axiomcore

# Check logs
kubectl logs <pod-name> -n axiomcore

# Auto-redeploy failed pods
.\scripts\monitoring-alerting.ps1 -Action monitor -AutoRedeploy -Namespace axiomcore
```

#### DNS Resolution Issues

```bash
# Check ingress configuration
kubectl describe ingress axiomcore-ingress -n axiomcore

# Verify DNS records
nslookup axiomcore-production.example.com

# Re-configure DNS
.\scripts\configure-dns-urls.ps1 -ProjectName axiomcore -BaseDomain example.com -DnsProvider gcp
```

#### SSL Certificate Not Issued

```bash
# Check certificate status
kubectl get certificate -n axiomcore
kubectl describe certificate axiomcore-tls -n axiomcore

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# Force renewal
kubectl delete certificate axiomcore-tls -n axiomcore
kubectl apply -f infra/kubernetes/ingress.yaml
```

#### High Resource Usage

```bash
# Check resource usage
kubectl top pods -n axiomcore
kubectl top nodes

# View detailed metrics in Grafana
# URL: https://grafana.axiomcore-{env}.{domain}

# Scale deployment
kubectl scale deployment <deployment-name> --replicas=5 -n axiomcore
```

### Getting Help

1. Check deployment logs: `.brain/deployment-log-*.json`
2. Check audit logs: `.brain/security/audit-log.json`
3. Check monitoring metrics in Grafana
4. Review CI/CD status: `.\scripts\cicd-monitoring.ps1 -Action list`

### Cleanup

```bash
# Delete Kubernetes resources
kubectl delete namespace axiomcore

# Delete cloud resources (if using Terraform)
cd infra/terraform/{provider}
terraform destroy

# Local cleanup
docker-compose -f infra/docker-compose.yml down -v
```

## Next Steps

1. **Configure Custom Domain**: Update DNS records to point to your load balancer
2. **Setup CI/CD**: Configure GitHub Actions for automated deployments
3. **Enable Backups**: Configure automated backups for databases
4. **Scale Resources**: Adjust replica counts and resource limits based on load
5. **Monitor Performance**: Review Grafana dashboards and set up alerts

For more information, see:
- [Configuration Guide](CONFIGURATION.md)
- [Security Guide](../SECURITY.md)
- [Monitoring Guide](MONITORING.md)
