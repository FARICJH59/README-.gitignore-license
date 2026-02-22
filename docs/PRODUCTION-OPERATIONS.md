# AxiomCore Production Operations Guide

## Overview

This guide provides comprehensive instructions for operating AxiomCore in production environments, including monitoring, troubleshooting, scaling, and maintenance procedures.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Monitoring & Observability](#monitoring--observability)
3. [Incident Response](#incident-response)
4. [Scaling & Performance](#scaling--performance)
5. [Backup & Recovery](#backup--recovery)
6. [Maintenance Windows](#maintenance-windows)
7. [Troubleshooting Guide](#troubleshooting-guide)

## Architecture Overview

### Production Infrastructure

```
┌─────────────────────────────────────────────────┐
│          Application Load Balancer (ALB)        │
│                 (SSL/TLS 1.3)                   │
└───────────────┬─────────────────────────────────┘
                │
        ┌───────┴───────┐
        │               │
┌───────▼──────┐  ┌────▼──────────┐
│  Frontend    │  │  API Service  │
│  (ECS/Docker)│  │  (ECS/Docker) │
│  Port: 3000  │  │  Port: 8080   │
└──────────────┘  └───────────────┘
                        │
                ┌───────┴───────┐
                │               │
        ┌───────▼─────┐  ┌─────▼──────┐
        │  Database   │  │   Redis    │
        │  (RDS)      │  │  (Cache)   │
        └─────────────┘  └────────────┘
```

### Components

- **Frontend**: React/Next.js application served via Express
- **API**: Node.js REST API with Express
- **Database**: PostgreSQL/MySQL (optional, via RDS)
- **Cache**: Redis (optional, via ElastiCache)
- **Monitoring**: Prometheus + Grafana
- **Logging**: CloudWatch Logs

## Monitoring & Observability

### Key Metrics to Monitor

#### API Service
- **Availability**: Target 99.9% uptime
- **Response Time**: P95 < 200ms, P99 < 500ms
- **Error Rate**: < 0.1%
- **Throughput**: Requests per second
- **CPU Usage**: < 70% average
- **Memory Usage**: < 80% of allocated

#### Frontend Service
- **Availability**: Target 99.9% uptime
- **Page Load Time**: < 3 seconds
- **Core Web Vitals**: All green
- **Error Rate**: < 0.5%

### Monitoring Tools

#### Prometheus Queries

```promql
# API Response Time (P95)
histogram_quantile(0.95, 
  rate(http_request_duration_seconds_bucket[5m])
)

# Error Rate
rate(http_requests_total{status=~"5.."}[5m])
/ rate(http_requests_total[5m])

# CPU Usage
rate(container_cpu_usage_seconds_total[5m]) * 100

# Memory Usage
container_memory_usage_bytes / container_spec_memory_limit_bytes * 100
```

#### CloudWatch Dashboards

Access dashboards at: AWS Console → CloudWatch → Dashboards

Key dashboards:
- **AxiomCore-Overview**: High-level system health
- **AxiomCore-API**: API-specific metrics
- **AxiomCore-Frontend**: Frontend performance
- **AxiomCore-Infrastructure**: Infrastructure metrics

### Alerting

#### Critical Alerts (Page immediately)
- Service down > 5 minutes
- Error rate > 5%
- Response time P95 > 1 second
- CPU > 90% for > 5 minutes
- Memory > 95%
- SSL certificate expiring < 7 days

#### Warning Alerts (Notify during business hours)
- Error rate > 1%
- Response time P95 > 500ms
- CPU > 70% for > 15 minutes
- Memory > 80%
- Disk usage > 80%

### Logging

#### Access Logs
```bash
# View API logs
aws logs tail /aws/ecs/axiomcore/api --follow

# View Frontend logs
aws logs tail /aws/ecs/axiomcore/frontend --follow

# Search for errors
aws logs filter-pattern "ERROR" \
  --log-group-name /aws/ecs/axiomcore/api \
  --start-time 1h
```

#### Log Levels
- **ERROR**: Critical issues requiring immediate attention
- **WARN**: Issues that should be investigated
- **INFO**: Normal operational messages
- **DEBUG**: Detailed diagnostic information (not in production)

## Incident Response

### Severity Levels

#### SEV1 - Critical
- Complete service outage
- Data loss or corruption
- Security breach
- **Response Time**: Immediate
- **Resolution Time**: < 1 hour

#### SEV2 - High
- Partial service degradation
- High error rates
- Performance severely impacted
- **Response Time**: < 15 minutes
- **Resolution Time**: < 4 hours

#### SEV3 - Medium
- Minor functionality issues
- Performance slightly degraded
- **Response Time**: < 1 hour
- **Resolution Time**: < 24 hours

#### SEV4 - Low
- Cosmetic issues
- Feature requests
- **Response Time**: Best effort
- **Resolution Time**: As scheduled

### Incident Response Procedure

1. **Detect**: Alert triggered or user report
2. **Acknowledge**: Confirm incident and assign owner
3. **Assess**: Determine severity and impact
4. **Communicate**: Notify stakeholders
5. **Mitigate**: Implement temporary fix if possible
6. **Resolve**: Deploy permanent solution
7. **Document**: Post-mortem and lessons learned

### Common Issues & Solutions

#### API Service Not Responding

```bash
# Check service status
aws ecs describe-services \
  --cluster axiomcore-production \
  --services api

# Check task health
aws ecs describe-tasks \
  --cluster axiomcore-production \
  --tasks $(aws ecs list-tasks \
    --cluster axiomcore-production \
    --service-name api \
    --query 'taskArns[0]' --output text)

# View recent logs
aws logs tail /aws/ecs/axiomcore/api --since 10m

# Restart service (last resort)
aws ecs update-service \
  --cluster axiomcore-production \
  --service api \
  --force-new-deployment
```

#### High Error Rate

```bash
# Check error distribution
aws logs filter-pattern "ERROR" \
  --log-group-name /aws/ecs/axiomcore/api \
  --start-time 30m

# Check for specific error patterns
aws logs filter-pattern "\"status\":500" \
  --log-group-name /aws/ecs/axiomcore/api \
  --start-time 30m
```

#### Performance Degradation

```bash
# Check CPU/Memory usage
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=api \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average

# Scale up if needed (see Scaling section)
```

## Scaling & Performance

### Horizontal Scaling

#### Manual Scaling

```bash
# Scale API service
aws ecs update-service \
  --cluster axiomcore-production \
  --service api \
  --desired-count 5

# Scale Frontend service
aws ecs update-service \
  --cluster axiomcore-production \
  --service frontend \
  --desired-count 3
```

#### Auto Scaling (Recommended)

Configure in Terraform or AWS Console:

```hcl
resource "aws_appautoscaling_target" "api" {
  max_capacity       = 10
  min_capacity       = 2
  resource_id        = "service/axiomcore-production/api"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "api_cpu" {
  name               = "api-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api.resource_id
  scalable_dimension = aws_appautoscaling_target.api.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 70.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
```

### Vertical Scaling

Update task definitions with more CPU/Memory:

```bash
# Update API task definition
aws ecs register-task-definition \
  --family axiomcore-api \
  --cpu 1024 \
  --memory 2048 \
  --container-definitions file://api-container-def.json

# Update service to use new task definition
aws ecs update-service \
  --cluster axiomcore-production \
  --service api \
  --task-definition axiomcore-api:NEW_VERSION
```

## Backup & Recovery

### Database Backups

```bash
# Create manual snapshot
aws rds create-db-snapshot \
  --db-instance-identifier axiomcore-production \
  --db-snapshot-identifier axiomcore-manual-$(date +%Y%m%d-%H%M%S)

# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier axiomcore-restored \
  --db-snapshot-identifier axiomcore-manual-YYYYMMDD-HHMMSS
```

### Configuration Backups

```bash
# Backup Terraform state
aws s3 cp s3://axiomcore-terraform-state/production/terraform.tfstate \
  ./backups/terraform-state-$(date +%Y%m%d).tfstate

# Backup secrets
aws secretsmanager get-secret-value \
  --secret-id axiomcore/production \
  > ./backups/secrets-$(date +%Y%m%d).json
```

## Maintenance Windows

### Scheduled Maintenance

- **Frequency**: Monthly (1st Sunday, 2-6 AM UTC)
- **Duration**: Up to 4 hours
- **Notification**: 7 days advance notice

### Maintenance Tasks

1. Security patches
2. Dependency updates
3. Database maintenance
4. Log rotation
5. Performance optimization

### Maintenance Procedure

```bash
# 1. Enable maintenance mode (if available)
# 2. Scale down to minimum capacity
aws ecs update-service \
  --cluster axiomcore-production \
  --service api \
  --desired-count 1

# 3. Perform maintenance
# - Apply updates
# - Run migrations
# - Optimize database

# 4. Verify health
curl https://api.axiomcore.example.com/health

# 5. Scale back up
aws ecs update-service \
  --cluster axiomcore-production \
  --service api \
  --desired-count 3

# 6. Disable maintenance mode
# 7. Monitor for issues
```

## Troubleshooting Guide

### Service Won't Start

**Symptoms**: Tasks keep restarting, service unavailable

**Diagnosis**:
```bash
# Check task logs
aws logs tail /aws/ecs/axiomcore/api --since 5m

# Check task status
aws ecs describe-tasks --cluster axiomcore-production --tasks TASK_ID
```

**Common Causes**:
- Missing environment variables
- Port conflicts
- Health check failures
- Resource constraints

**Solutions**:
- Verify .env configuration
- Check health check endpoint
- Increase CPU/memory allocation
- Review application logs

### High Memory Usage

**Symptoms**: Memory usage > 80%, potential OOM kills

**Diagnosis**:
```bash
# Check memory metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name MemoryUtilization \
  --dimensions Name=ServiceName,Value=api \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Maximum
```

**Solutions**:
- Investigate memory leaks in application
- Increase memory allocation
- Implement caching
- Optimize queries

### SSL Certificate Issues

**Symptoms**: HTTPS not working, certificate warnings

**Diagnosis**:
```bash
# Check certificate expiration
aws acm describe-certificate \
  --certificate-arn CERT_ARN
```

**Solutions**:
- Renew certificate
- Update ALB listener
- Verify DNS configuration

---

**Document Version**: 1.0  
**Last Updated**: 2026-02-22  
**Owner**: FARICJH59  
**Contact**: farichva@gmail.com
