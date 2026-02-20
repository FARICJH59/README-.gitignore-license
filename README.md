# axiomcore

AxiomCore MVP — backend, frontend, AI orchestration

## Description

This repository serves as the foundation for the AxiomCore MVP platform, providing backend services, frontend interfaces, and AI orchestration capabilities. The project is a comprehensive full-stack solution supporting both PowerShell and Python development environments.

## Features

### Core Platform
- Full-stack platform architecture
- PowerShell scripting support
- Python application development
- Cross-platform compatibility

### 🚀 Autonomous Deployment
- **Multi-Environment Support**: Deploy to AWS, GCP, Azure, Cloud Run, or local environments
- **Auto-Generated Build Scripts**: Environment-specific deployment scripts generated automatically
- **Container Orchestration**: Kubernetes manifests and Docker Compose configurations
- **Infrastructure as Code**: Terraform modules for AWS, GCP, and Azure
- **One-Command Deployment**: Single script orchestrates entire deployment pipeline

### 🌐 DNS & URL Configuration
- **Auto-Subdomain Generation**: Automatically creates subdomains per project and environment
- **Dynamic Route Mapping**: Connects frontend/backend services with dynamic routing
- **SSL/TLS Automation**: Automatic certificate provisioning via Let's Encrypt
- **Multi-Provider DNS**: Support for Route53, Cloud DNS, and Azure DNS
- **Ingress Controllers**: Nginx-based reverse proxy with load balancing

### 🔄 CI/CD Integration
- **Workflow Monitoring**: Parse and track GitHub Actions workflows
- **Automated Triggers**: Trigger builds and deployments programmatically
- **Deployment Tracking**: Track success/failure of ML and IoT pipeline deployments
- **Real-time Status**: Monitor workflow runs with live status updates
- **Deployment History**: Complete audit trail of all deployments

### 📊 Monitoring & Observability
- **Metrics Collection**: Prometheus-based metrics for all services
- **Log Aggregation**: Centralized logging with Grafana Loki
- **Dashboards**: Pre-configured Grafana dashboards
- **ML Metrics**: Track model accuracy, inference latency, and predictions
- **IoT Telemetry**: Capture and analyze device events and telemetry
- **Auto-Redeploy**: Automatic redeployment on service failures
- **Alert System**: Configurable alerts with multi-channel notifications

### 🔒 Security & Compliance
- **RBAC**: Role-Based Access Control with predefined roles (admin, developer, readonly)
- **Network Policies**: Pod-to-pod communication restrictions
- **Pod Security Policies**: Enforce security standards at pod level
- **Audit Logging**: Comprehensive audit trail of all security events
- **Secrets Management**: Encrypted secrets with best practices
- **Container Scanning**: Integration points for Trivy/Clair vulnerability scanning
- **Compliance Reports**: Automated security and compliance reporting

## Getting Started

### Prerequisites

#### Required
- PowerShell 7.0 or higher
- Docker 24.x or higher
- Git
- kubectl (for Kubernetes deployments)

#### Optional (Provider-Specific)
- **AWS**: AWS CLI configured with credentials
- **GCP**: gcloud CLI configured with credentials
- **Azure**: Azure CLI configured with credentials
- **Terraform**: For infrastructure provisioning

### Quick Start

#### Local Development with Docker Compose

```bash
# Clone the repository
git clone https://github.com/FARICJH59/README-.gitignore-license.git
cd README-.gitignore-license

# Start all services locally
docker-compose -f infra/docker-compose.yml up -d

# Access the application
# Frontend: http://localhost:3000
# API Gateway: http://localhost:8081-8084
# Grafana: http://localhost:3001
# Prometheus: http://localhost:9090
```

#### Autonomous Deployment to Cloud

```powershell
# Deploy to GCP production environment
.\scripts\autonomous-deploy.ps1 `
    -Environment production `
    -Provider gcp `
    -BaseDomain "example.com" `
    -EnableMonitoring `
    -EnableSSL `
    -ConfigureDNS

# Deploy to AWS staging environment
.\scripts\autonomous-deploy.ps1 `
    -Environment staging `
    -Provider aws `
    -BaseDomain "example.com"

# Deploy to Azure development environment
.\scripts\autonomous-deploy.ps1 `
    -Environment dev `
    -Provider azure
```

#### Manual Kubernetes Deployment

```bash
# Apply Kubernetes manifests
kubectl apply -f infra/kubernetes/namespace.yaml
kubectl apply -f infra/kubernetes/configmap.yaml
kubectl apply -f infra/kubernetes/rbac.yaml
kubectl apply -f infra/kubernetes/

# Configure DNS and SSL
.\scripts\configure-dns-urls.ps1 `
    -ProjectName "axiomcore" `
    -BaseDomain "example.com" `
    -DnsProvider gcp `
    -EnableSSL

# Setup monitoring
.\scripts\monitoring-alerting.ps1 -Action setup -Namespace axiomcore

# Start continuous monitoring
.\scripts\monitoring-alerting.ps1 `
    -Action monitor `
    -Namespace axiomcore `
    -CheckInterval 60 `
    -AutoRedeploy `
    -Continuous
```

## QGPS Autonomous Cockpit

The QGPS Autonomous Cockpit provides automated orchestration for multiple repositories with dependency management and dev server launch capabilities.

### Usage

```powershell
# Start all registered repositories
.\scripts\qgps-cockpit.ps1

# Specify max concurrency (default: 2)
.\scripts\qgps-cockpit.ps1 -MaxConcurrency 3

# Use custom brain core path
.\scripts\qgps-cockpit.ps1 -BrainCorePath "C:\custom\brain-core"
```

### Features

- **Automatic Dependency Installation**: Runs `npm install` for all registered repositories with package.json
- **Smart Building**: Executes build scripts if they exist in package.json
- **Dev Server Launch**: Automatically starts dev servers in separate PowerShell windows (Windows) or background jobs (Linux/macOS)
- **Comprehensive Logging**: All cockpit runs are logged to `.brain/cockpit-log.json` with detailed error tracking
- **Environment Validation**: Checks Node.js and npm versions before processing
- **Concurrency Control**: Respects MaxConcurrency parameter to limit simultaneous server launches
- **Cross-Platform Support**: Works on Windows (PowerShell 5.1+), Linux, and macOS (PowerShell Core 7+)
- **Registry Validation**: Validates repo-registry.json structure with helpful error messages

### Error Handling & Logging

The cockpit now includes comprehensive error handling:
- Try/catch blocks around all npm operations
- Detailed error logs with timestamps, stack traces, and error categories
- Fallback behavior for missing or malformed configuration files
- Warning messages for non-critical issues

Error logs are stored in `.brain/cockpit-log.json` with the following structure:
```json
{
  "lastRun": "2026-02-19T14:21:28.2940131+00:00",
  "processedRepos": ["repo1", "repo2"],
  "launchedServers": ["repo1"],
  "maxConcurrency": 2,
  "runningJobs": 1,
  "platform": {
    "edition": "Core",
    "version": "7.4.13",
    "os": "Ubuntu 24.04.3 LTS",
    "isWindows": false
  },
  "environment": {
    "nodeVersion": "v24.13.0",
    "npmVersion": "11.6.2"
  },
  "detailedLogs": [
    {
      "timestamp": "2026-02-19T14:21:28.5Z",
      "repository": "repo1",
      "action": "npm-install",
      "status": "success",
      "message": "Dependencies installed successfully"
    }
  ]
}
```

### Prerequisites

Before using the cockpit, ensure:
1. Repositories are registered using `.\scripts\generate-autopilot-repo.ps1`
2. Node.js 18.x or higher is installed for JavaScript/TypeScript projects
3. npm is installed and available in PATH
4. Brain core is initialized with `brain-core/repo-registry.json`
5. For cross-platform usage, PowerShell Core 7+ is recommended

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Documentation

### Deployment Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `autonomous-deploy.ps1` | Master orchestration script for autonomous deployment | `.\scripts\autonomous-deploy.ps1 -Environment production -Provider gcp -BaseDomain example.com` |
| `deploy-multi-environment.ps1` | Generate and execute environment-specific deployment scripts | `.\scripts\deploy-multi-environment.ps1 -Environment staging -Provider aws` |
| `configure-dns-urls.ps1` | Auto-configure DNS records and SSL certificates | `.\scripts\configure-dns-urls.ps1 -ProjectName axiomcore -BaseDomain example.com -DnsProvider gcp` |
| `monitoring-alerting.ps1` | Setup and run monitoring with auto-redeploy capabilities | `.\scripts\monitoring-alerting.ps1 -Action monitor -AutoRedeploy -Continuous` |
| `cicd-monitoring.ps1` | Track GitHub Actions workflows and deployment status | `.\scripts\cicd-monitoring.ps1 -Action status -RunId 123456` |
| `security-compliance.ps1` | Run security scans and manage RBAC | `.\scripts\security-compliance.ps1 -Action scan -Namespace axiomcore` |
| `generate-release-notes.ps1` | Auto-generate release notes from commits | `.\scripts\generate-release-notes.ps1 -AutoPublish` |

### Infrastructure Components

#### Kubernetes Manifests (`infra/kubernetes/`)
- `namespace.yaml` - Namespace configuration
- `configmap.yaml` - Environment variables and configuration
- `rbac.yaml` - Role-Based Access Control
- `ingress.yaml` - Ingress controller with SSL/TLS
- `api-ingestion.yaml` - Ingestion service deployment
- `frontend.yaml` - Frontend application deployment

#### Docker Compose (`infra/docker-compose.yml`)
Complete local development environment including:
- API services (ingestion, dashboard, optimization, billing)
- Frontend application
- Monitoring stack (Prometheus, Grafana, Loki)
- Reverse proxy (Nginx)

#### Terraform Modules (`infra/terraform/`)
- **AWS**: EKS, RDS, ElastiCache, S3, Route53, ALB
- **GCP**: GKE, Cloud SQL, Memorystore, Cloud Storage, Cloud DNS
- **Azure**: AKS, Azure SQL, Azure Cache, Blob Storage, Azure DNS

### Monitoring & Observability

#### Metrics Collection
The platform automatically collects:
- **Service Metrics**: CPU, memory, pod restarts, health status
- **ML Metrics**: Model accuracy, inference latency, prediction counts
- **IoT Telemetry**: Device events, connection status, data throughput
- **API Metrics**: Request rates, error rates, response times

#### Alert Rules
Pre-configured alerts for:
- High CPU usage (>80%)
- High memory usage (>85%)
- Pod restarts (>5 times)
- API error rate (>5%)
- ML accuracy drop (<85%)

#### Dashboards
Access monitoring dashboards:
- **Grafana**: `https://grafana.{project}-{env}.{domain}` or `http://localhost:3001`
- **Prometheus**: `https://monitoring.{project}-{env}.{domain}` or `http://localhost:9090`

### Security Best Practices

#### RBAC Roles
- **Admin**: Full access to all resources
- **Developer**: Read/write access to pods, services, configmaps
- **Readonly**: Read-only access to all resources

#### Network Security
- Pod-to-pod communication restricted by network policies
- Ingress controller with rate limiting (100 req/min)
- SSL/TLS enforced for all external traffic

#### Secrets Management
- Secrets encrypted at rest
- Access controlled via RBAC
- Audit logging for all secret access
- Recommendation: Use external secrets manager (Vault, AWS Secrets Manager)

### CI/CD Pipeline

#### GitHub Actions Workflows
- **main.yml**: Full-stack deployment on push to main
- **ci-cd-autopilot.yml**: Multi-repo orchestration and compliance checks

#### Deployment Tracking
Track all deployments with:
```powershell
# List recent workflow runs
.\scripts\cicd-monitoring.ps1 -Action list

# Monitor specific workflow run
.\scripts\cicd-monitoring.ps1 -Action status -RunId 123456 -Watch

# Trigger new deployment
.\scripts\cicd-monitoring.ps1 -Action trigger -WorkflowId main.yml -Watch
```

### Troubleshooting

#### Common Issues

**Q: Pods are in CrashLoopBackOff**
```bash
# Check pod logs
kubectl logs <pod-name> -n axiomcore

# Auto-redeploy failed pods
.\scripts\monitoring-alerting.ps1 -Action monitor -AutoRedeploy
```

**Q: DNS not resolving**
```powershell
# Verify DNS configuration
.\scripts\configure-dns-urls.ps1 -ProjectName axiomcore -BaseDomain example.com -DryRun

# Check ingress status
kubectl get ingress -n axiomcore
```

**Q: SSL certificate not issued**
```bash
# Check cert-manager status
kubectl get certificate -n axiomcore
kubectl describe certificate axiomcore-tls -n axiomcore

# Check ClusterIssuer
kubectl get clusterissuer
```

### Environment Variables

Key environment variables used across services:

| Variable | Description | Default |
|----------|-------------|---------|
| `NODE_ENV` | Environment mode | `production` |
| `LOG_LEVEL` | Logging verbosity | `info` |
| `API_INGESTION_URL` | Ingestion service URL | `http://api-ingestion:8081` |
| `API_DASHBOARD_URL` | Dashboard service URL | `http://api-dashboard:8082` |
| `METRICS_ENABLED` | Enable metrics collection | `true` |
| `TELEMETRY_ENDPOINT` | Prometheus endpoint | `http://prometheus:9090` |

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Load Balancer / Ingress                  │
│                    (Nginx + SSL/TLS)                         │
└────────────────────┬────────────────────────────────────────┘
                     │
          ┌──────────┴──────────┐
          │                     │
    ┌─────▼─────┐        ┌─────▼─────┐
    │  Frontend │        │ API Gateway│
    │  (React)  │        │  (Node.js) │
    └───────────┘        └─────┬─────┘
                               │
          ┌────────────────────┼────────────────────┐
          │                    │                    │
    ┌─────▼─────┐      ┌──────▼──────┐     ┌──────▼──────┐
    │ Ingestion │      │  Dashboard  │     │Optimization │
    │  Service  │      │   Service   │     │   Service   │
    └───────────┘      └─────────────┘     └─────────────┘
          │                    │                    │
    ┌─────▼────────────────────▼────────────────────▼─────┐
    │              Database / Cache Layer                  │
    │          (PostgreSQL, Redis, S3/GCS)                 │
    └──────────────────────────────────────────────────────┘
          │
    ┌─────▼────────────────────────────────────────────────┐
    │         Monitoring & Observability Stack             │
    │     (Prometheus, Grafana, Loki, Alertmanager)       │
    └──────────────────────────────────────────────────────┘
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
