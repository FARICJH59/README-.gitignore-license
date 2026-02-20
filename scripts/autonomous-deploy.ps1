#!/usr/bin/env pwsh
# Master Deployment Orchestration Script
# Autonomous deployment with monitoring, DNS configuration, and security

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev', 'staging', 'production')]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet('aws', 'gcp', 'azure', 'cloudrun', 'local')]
    [string]$Provider,
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = "axiomcore",
    
    [Parameter(Mandatory=$false)]
    [string]$BaseDomain,
    
    [Parameter(Mandatory=$false)]
    [string]$Version = "latest",
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableMonitoring = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableSSL = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$ConfigureDNS = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$RunSecurityScan = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir

Write-Host "╔═══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   AxiomCore Autonomous Deployment System     ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "Environment:    $Environment" -ForegroundColor Yellow
Write-Host "Provider:       $Provider" -ForegroundColor Yellow
Write-Host "Project:        $ProjectName" -ForegroundColor Yellow
Write-Host "Version:        $Version" -ForegroundColor Yellow
Write-Host "Domain:         $(if ($BaseDomain) { $BaseDomain } else { 'Not configured' })" -ForegroundColor Yellow
Write-Host "Monitoring:     $(if ($EnableMonitoring) { 'Enabled' } else { 'Disabled' })" -ForegroundColor $(if ($EnableMonitoring) { 'Green' } else { 'Gray' })
Write-Host "SSL/TLS:        $(if ($EnableSSL) { 'Enabled' } else { 'Disabled' })" -ForegroundColor $(if ($EnableSSL) { 'Green' } else { 'Gray' })
Write-Host "DNS Config:     $(if ($ConfigureDNS) { 'Enabled' } else { 'Disabled' })" -ForegroundColor $(if ($ConfigureDNS) { 'Green' } else { 'Gray' })
Write-Host "Security Scan:  $(if ($RunSecurityScan) { 'Enabled' } else { 'Disabled' })" -ForegroundColor $(if ($RunSecurityScan) { 'Green' } else { 'Gray' })
Write-Host "Dry Run:        $(if ($DryRun) { 'YES' } else { 'NO' })" -ForegroundColor $(if ($DryRun) { 'Yellow' } else { 'White' })
Write-Host ""

# Deployment stages
$stages = @(
    @{ name = "Pre-flight Checks"; script = "preflight-checks" }
    @{ name = "Generate Deployment Scripts"; script = "deploy-multi-environment" }
    @{ name = "Deploy Infrastructure"; script = "deploy-infrastructure" }
    @{ name = "Configure DNS & URLs"; script = "configure-dns-urls" }
    @{ name = "Security & RBAC Setup"; script = "security-compliance" }
    @{ name = "Monitoring & Alerting"; script = "monitoring-alerting" }
    @{ name = "Post-Deployment Validation"; script = "validate-deployment" }
    @{ name = "Generate Release Notes"; script = "generate-release-notes" }
)

$deploymentLog = @{
    startTime = Get-Date -Format "o"
    environment = $Environment
    provider = $Provider
    version = $Version
    stages = @()
}

function Write-StageHeader {
    param($StageName, $StageNumber, $TotalStages)
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Stage $StageNumber/$TotalStages: $StageName" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

function Invoke-DeploymentStage {
    param($Stage, $StageNumber, $TotalStages)
    
    Write-StageHeader -StageName $Stage.name -StageNumber $StageNumber -TotalStages $TotalStages
    
    $stageLog = @{
        name = $Stage.name
        startTime = Get-Date -Format "o"
        status = "in-progress"
        output = @()
    }
    
    try {
        switch ($Stage.script) {
            "preflight-checks" {
                Write-Host "Running pre-flight checks..." -ForegroundColor Yellow
                
                # Check required tools
                $tools = @('kubectl', 'docker', 'git')
                foreach ($tool in $tools) {
                    $available = Get-Command $tool -ErrorAction SilentlyContinue
                    if ($available) {
                        Write-Host "  ✓ $tool is available" -ForegroundColor Green
                    } else {
                        Write-Host "  ⚠️  $tool is not available" -ForegroundColor Yellow
                    }
                }
                
                # Check provider-specific tools
                switch ($Provider) {
                    'aws' { 
                        $awsCli = Get-Command aws -ErrorAction SilentlyContinue
                        if ($awsCli) {
                            Write-Host "  ✓ AWS CLI is available" -ForegroundColor Green
                        } else {
                            Write-Host "  ⚠️  AWS CLI is not available" -ForegroundColor Yellow
                        }
                    }
                    'gcp' { 
                        $gcloud = Get-Command gcloud -ErrorAction SilentlyContinue
                        if ($gcloud) {
                            Write-Host "  ✓ gcloud CLI is available" -ForegroundColor Green
                        } else {
                            Write-Host "  ⚠️  gcloud CLI is not available" -ForegroundColor Yellow
                        }
                    }
                    'azure' { 
                        $az = Get-Command az -ErrorAction SilentlyContinue
                        if ($az) {
                            Write-Host "  ✓ Azure CLI is available" -ForegroundColor Green
                        } else {
                            Write-Host "  ⚠️  Azure CLI is not available" -ForegroundColor Yellow
                        }
                    }
                }
                
                $stageLog.status = "success"
            }
            
            "deploy-multi-environment" {
                Write-Host "Generating deployment scripts..." -ForegroundColor Yellow
                $deployScript = Join-Path $ScriptDir "deploy-multi-environment.ps1"
                
                $params = @{
                    Environment = $Environment
                    Provider = $Provider
                    ProjectName = $ProjectName
                    Version = $Version
                    GenerateOnly = $true
                }
                
                if ($DryRun) { $params.DryRun = $true }
                
                & $deployScript @params
                $stageLog.status = "success"
            }
            
            "deploy-infrastructure" {
                Write-Host "Deploying infrastructure..." -ForegroundColor Yellow
                
                if (-not $DryRun) {
                    # Deploy based on provider
                    if ($Provider -eq 'local') {
                        Write-Host "  Starting local deployment with Docker Compose..." -ForegroundColor White
                        Push-Location (Join-Path $RootDir "infra")
                        docker-compose up -d
                        Pop-Location
                    } else {
                        # Deploy to cloud provider
                        $deployScript = Join-Path $ScriptDir "deploy-multi-environment.ps1"
                        & $deployScript -Environment $Environment -Provider $Provider -ProjectName $ProjectName -Version $Version
                    }
                }
                
                $stageLog.status = "success"
            }
            
            "configure-dns-urls" {
                if ($ConfigureDNS -and $BaseDomain) {
                    Write-Host "Configuring DNS and URLs..." -ForegroundColor Yellow
                    $dnsScript = Join-Path $ScriptDir "configure-dns-urls.ps1"
                    
                    $params = @{
                        ProjectName = $ProjectName
                        BaseDomain = $BaseDomain
                        DnsProvider = $Provider
                        Environment = $Environment
                    }
                    
                    if ($DryRun) { $params.DryRun = $true }
                    if ($EnableSSL) { $params.EnableSSL = $true }
                    
                    & $dnsScript @params
                } else {
                    Write-Host "  DNS configuration skipped" -ForegroundColor Gray
                }
                
                $stageLog.status = "success"
            }
            
            "security-compliance" {
                if ($RunSecurityScan) {
                    Write-Host "Running security scan and configuring RBAC..." -ForegroundColor Yellow
                    $securityScript = Join-Path $ScriptDir "security-compliance.ps1"
                    
                    & $securityScript -Action rbac -Namespace $ProjectName
                    & $securityScript -Action scan -Namespace $ProjectName
                } else {
                    Write-Host "  Security scan skipped" -ForegroundColor Gray
                }
                
                $stageLog.status = "success"
            }
            
            "monitoring-alerting" {
                if ($EnableMonitoring) {
                    Write-Host "Setting up monitoring and alerting..." -ForegroundColor Yellow
                    $monitoringScript = Join-Path $ScriptDir "monitoring-alerting.ps1"
                    
                    & $monitoringScript -Action setup -Namespace $ProjectName
                    
                    Write-Host "  Monitoring dashboard will be available at:" -ForegroundColor Cyan
                    if ($BaseDomain) {
                        Write-Host "  https://grafana.$ProjectName-$Environment.$BaseDomain" -ForegroundColor Cyan
                    } else {
                        Write-Host "  http://localhost:3001 (Grafana)" -ForegroundColor Cyan
                        Write-Host "  http://localhost:9090 (Prometheus)" -ForegroundColor Cyan
                    }
                } else {
                    Write-Host "  Monitoring setup skipped" -ForegroundColor Gray
                }
                
                $stageLog.status = "success"
            }
            
            "validate-deployment" {
                Write-Host "Validating deployment..." -ForegroundColor Yellow
                
                if ($Provider -ne 'local') {
                    # Check Kubernetes pods
                    Write-Host "  Checking pod status..." -ForegroundColor White
                    $pods = kubectl get pods -n $ProjectName -o json 2>$null | ConvertFrom-Json
                    
                    if ($pods) {
                        $runningPods = ($pods.items | Where-Object { $_.status.phase -eq 'Running' }).Count
                        $totalPods = $pods.items.Count
                        Write-Host "  ✓ $runningPods/$totalPods pods are running" -ForegroundColor Green
                    }
                } else {
                    # Check Docker containers
                    Write-Host "  Checking container status..." -ForegroundColor White
                    docker-compose -f (Join-Path $RootDir "infra" "docker-compose.yml") ps
                }
                
                $stageLog.status = "success"
            }
            
            "generate-release-notes" {
                Write-Host "Generating release notes..." -ForegroundColor Yellow
                $releaseScript = Join-Path $ScriptDir "generate-release-notes.ps1"
                
                & $releaseScript -Format markdown
                
                $stageLog.status = "success"
            }
        }
        
        Write-Host "  ✓ Stage completed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "  ✗ Stage failed: $($_.Exception.Message)" -ForegroundColor Red
        $stageLog.status = "failed"
        $stageLog.error = $_.Exception.Message
    }
    
    $stageLog.endTime = Get-Date -Format "o"
    $deploymentLog.stages += $stageLog
}

# Execute deployment stages
$stageNumber = 1
foreach ($stage in $stages) {
    Invoke-DeploymentStage -Stage $stage -StageNumber $stageNumber -TotalStages $stages.Count
    $stageNumber++
}

$deploymentLog.endTime = Get-Date -Format "o"
$deploymentLog.status = if (($deploymentLog.stages | Where-Object { $_.status -eq 'failed' }).Count -eq 0) { "success" } else { "failed" }

# Save deployment log
$logDir = Join-Path $RootDir ".brain"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}
$logFile = Join-Path $logDir "deployment-log-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$deploymentLog | ConvertTo-Json -Depth 10 | Set-Content -Path $logFile -Force

# Final summary
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          Deployment Summary                   ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "Status: $($deploymentLog.status.ToUpper())" -ForegroundColor $(if ($deploymentLog.status -eq 'success') { 'Green' } else { 'Red' })
Write-Host "Duration: $([math]::Round(((Get-Date) - [DateTime]$deploymentLog.startTime).TotalMinutes, 2)) minutes" -ForegroundColor White
Write-Host ""
Write-Host "Stages:" -ForegroundColor Yellow
foreach ($stage in $deploymentLog.stages) {
    $statusIcon = if ($stage.status -eq 'success') { '✓' } else { '✗' }
    $statusColor = if ($stage.status -eq 'success') { 'Green' } else { 'Red' }
    Write-Host "  $statusIcon $($stage.name)" -ForegroundColor $statusColor
}
Write-Host ""
Write-Host "Deployment log saved: $logFile" -ForegroundColor Cyan
Write-Host ""

if ($deploymentLog.status -eq 'success') {
    Write-Host "🎉 Deployment completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Access your deployment:" -ForegroundColor Yellow
    if ($BaseDomain) {
        Write-Host "  Application: https://$ProjectName-$Environment.$BaseDomain" -ForegroundColor Cyan
        Write-Host "  API: https://api.$ProjectName-$Environment.$BaseDomain" -ForegroundColor Cyan
        if ($EnableMonitoring) {
            Write-Host "  Monitoring: https://grafana.$ProjectName-$Environment.$BaseDomain" -ForegroundColor Cyan
        }
    } else {
        Write-Host "  Application: http://localhost:3000" -ForegroundColor Cyan
        Write-Host "  API: http://localhost:8081-8084" -ForegroundColor Cyan
        if ($EnableMonitoring) {
            Write-Host "  Grafana: http://localhost:3001" -ForegroundColor Cyan
            Write-Host "  Prometheus: http://localhost:9090" -ForegroundColor Cyan
        }
    }
} else {
    Write-Host "❌ Deployment failed. Check the log for details: $logFile" -ForegroundColor Red
    exit 1
}
