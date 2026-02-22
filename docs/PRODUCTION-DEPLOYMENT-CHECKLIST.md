# Production Deployment Checklist

## Pre-Deployment Checklist

### Code Quality & Security
- [ ] All tests pass (unit, integration, e2e)
- [ ] Code review completed and approved
- [ ] Security scan passed (Trivy, CodeQL)
- [ ] No critical or high vulnerabilities
- [ ] Dependencies up to date
- [ ] Secrets not committed to repository
- [ ] Environment variables properly configured

### Infrastructure
- [ ] Terraform state backend configured
- [ ] AWS resources provisioned
- [ ] VPC and subnets configured
- [ ] Security groups configured
- [ ] Load balancer configured
- [ ] SSL certificates installed and valid
- [ ] DNS records configured
- [ ] Backup strategy in place

### Application Configuration
- [ ] Environment variables set for production
- [ ] Database migrations tested
- [ ] API endpoints tested
- [ ] Health check endpoints working
- [ ] Monitoring configured
- [ ] Logging configured
- [ ] Error tracking configured (e.g., Sentry)

### Docker & Container Registry
- [ ] Docker images built successfully
- [ ] Images scanned for vulnerabilities
- [ ] Images pushed to ECR/registry
- [ ] Image tags follow semantic versioning
- [ ] Container resource limits configured

### CI/CD Pipeline
- [ ] GitHub Actions workflows passing
- [ ] Automated tests enabled
- [ ] Deployment automation tested
- [ ] Rollback procedure tested
- [ ] Branch protection rules enabled

## Deployment Steps

### 1. Pre-Deployment
```bash
# Verify current state
git status
git log -1

# Run local tests
npm test --prefix api
npm test --prefix frontend

# Build Docker images locally
docker-compose build

# Test locally
docker-compose up -d
curl http://localhost:8080/health
curl http://localhost:3000/health
docker-compose down
```

### 2. Infrastructure Deployment
```bash
cd infra/terraform

# Initialize Terraform
terraform init

# Review changes
terraform plan -out=tfplan

# Apply infrastructure changes
terraform apply tfplan

# Save outputs
terraform output > ../terraform-outputs.txt
```

### 3. Application Deployment
```bash
# Tag release
git tag -a v1.0.0 -m "Production release v1.0.0"
git push origin v1.0.0

# Push to main (triggers CI/CD)
git checkout main
git merge develop
git push origin main

# Monitor deployment
watch -n 5 'aws ecs describe-services \
  --cluster axiomcore-production \
  --services api frontend'
```

### 4. Verification
```bash
# Check health endpoints
curl https://api.axiomcore.example.com/health
curl https://axiomcore.example.com/health

# Verify monitoring
open https://grafana.axiomcore.example.com

# Check logs
aws logs tail /aws/ecs/axiomcore/api --follow
aws logs tail /aws/ecs/axiomcore/frontend --follow
```

## Post-Deployment Checklist

### Immediate Verification (0-5 minutes)
- [ ] All services healthy
- [ ] Health checks passing
- [ ] Load balancer routing traffic
- [ ] SSL certificates working
- [ ] No 5xx errors
- [ ] Response times acceptable

### Short-term Monitoring (5-30 minutes)
- [ ] CPU and memory usage normal
- [ ] Error rate < 1%
- [ ] P95 response time < 500ms
- [ ] Database connections stable
- [ ] No memory leaks detected

### Extended Monitoring (30 minutes - 4 hours)
- [ ] No anomalies in metrics
- [ ] User feedback positive
- [ ] No support tickets related to deployment
- [ ] Logs show no unexpected errors
- [ ] Monitoring alerts not triggered

### Documentation
- [ ] Deployment documented in changelog
- [ ] Known issues documented
- [ ] Rollback procedure documented
- [ ] Team notified of deployment
- [ ] Stakeholders informed

## Rollback Procedure

### Quick Rollback (< 5 minutes)
```bash
# Revert to previous Docker images
aws ecs update-service \
  --cluster axiomcore-production \
  --service api \
  --task-definition axiomcore-api:PREVIOUS_VERSION

aws ecs update-service \
  --cluster axiomcore-production \
  --service frontend \
  --task-definition axiomcore-frontend:PREVIOUS_VERSION
```

### Full Rollback (5-15 minutes)
```bash
# Revert Git changes
git revert HEAD
git push origin main

# Or reset to previous tag
git checkout v0.9.0
git tag -f v1.0.0
git push -f origin v1.0.0

# Revert infrastructure if needed
cd infra/terraform
terraform apply -var-file=previous-config.tfvars
```

## Emergency Contacts

- **Primary Maintainer**: FARICJH59 (farichva@gmail.com)
- **AWS Support**: [AWS Support Portal]
- **On-Call Engineer**: [PagerDuty/On-call schedule]

## Disaster Recovery

### Backup Verification
- [ ] Database backups tested
- [ ] Configuration backups available
- [ ] Secrets backup secured
- [ ] Recovery time objective (RTO): 1 hour
- [ ] Recovery point objective (RPO): 15 minutes

### Recovery Procedure
1. Identify failure point
2. Execute rollback procedure
3. Verify services restored
4. Investigate root cause
5. Document incident
6. Implement preventive measures

## Compliance & Audit

- [ ] Deployment logged in audit trail
- [ ] Changes documented in CHANGELOG
- [ ] Security review completed
- [ ] Compliance requirements met
- [ ] Access logs enabled
- [ ] Data retention policies applied

## Performance Benchmarks

### API Performance
- Response time: < 200ms (p95)
- Throughput: > 1000 req/s
- Error rate: < 0.1%
- Availability: 99.9%

### Frontend Performance
- Time to Interactive: < 3s
- First Contentful Paint: < 1.5s
- Lighthouse Score: > 90
- Core Web Vitals: All green

## Post-Mortem Template

```markdown
# Deployment Post-Mortem: [DATE]

## Summary
Brief description of the deployment

## What Went Well
- Item 1
- Item 2

## What Went Wrong
- Issue 1
- Issue 2

## Action Items
- [ ] Fix issue 1
- [ ] Improve process for issue 2

## Metrics
- Deployment duration: X minutes
- Downtime: X minutes
- Error rate during deployment: X%
```

---

**Document Version**: 1.0  
**Last Updated**: 2026-02-22  
**Owner**: FARICJH59
