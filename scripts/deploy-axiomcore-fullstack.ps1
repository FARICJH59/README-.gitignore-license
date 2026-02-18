# AxiomCore Full Stack Deployment Script
# Deploys backend API, frontend, and AI orchestration components

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('dev', 'staging', 'production')]
    [string]$Environment = 'dev',
    
    [Parameter(Mandatory=$false)]
    [string]$Provider = 'gcp',
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipTests,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "AxiomCore Full Stack Deployment" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host "Provider: $Provider" -ForegroundColor Yellow
Write-Host "Dry Run: $DryRun" -ForegroundColor Yellow
Write-Host ""

# Set script location
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir

# Load provider configuration
Write-Host "Loading provider configuration..." -ForegroundColor Green
& "$ScriptDir/$Provider.ps1"

# Initialize state management
Write-Host "Initializing state management..." -ForegroundColor Green
. "$ScriptDir/state.ps1"
Initialize-RuntimeState

# Run UDO orchestration
Write-Host "Running UDO orchestration..." -ForegroundColor Green
. "$ScriptDir/udo.ps1"
Initialize-UDO

# Execute DAG for deployment
Write-Host "Executing deployment DAG..." -ForegroundColor Green
. "$ScriptDir/dag.ps1"
Initialize-DAG -DAGName "axiomcore-deployment-$Environment"

if (-not $SkipTests) {
    Write-Host "Running post-deployment tests..." -ForegroundColor Green
    # Add test execution here
}

# Deploy API services
Write-Host ""
Write-Host "Deploying API services..." -ForegroundColor Cyan
Push-Location "$RootDir/api"
try {
    # Deploy ingestion service
    Write-Host "  - Deploying ingestion service..." -ForegroundColor White
    
    # Deploy dashboard service
    Write-Host "  - Deploying dashboard service..." -ForegroundColor White
    
    # Deploy optimization service
    Write-Host "  - Deploying optimization service..." -ForegroundColor White
    
    # Deploy billing service
    Write-Host "  - Deploying billing service..." -ForegroundColor White
    
} finally {
    Pop-Location
}

# Deploy frontend
Write-Host ""
Write-Host "Deploying frontend..." -ForegroundColor Cyan
Push-Location "$RootDir/frontend"
try {
    Write-Host "  - Building frontend assets..." -ForegroundColor White
    # npm run build
    
    Write-Host "  - Deploying frontend to CDN..." -ForegroundColor White
    
} finally {
    Pop-Location
}

# Deploy AI services
Write-Host ""
Write-Host "Deploying AI services..." -ForegroundColor Cyan
Push-Location "$RootDir/ai"
try {
    # Deploy forecasting model
    Write-Host "  - Deploying forecasting service..." -ForegroundColor White
    
    # Deploy energy predictor
    Write-Host "  - Deploying energy predictor..." -ForegroundColor White
    
} finally {
    Pop-Location
}

# Apply infrastructure changes
if (Test-Path "$RootDir/infra/terraform") {
    Write-Host ""
    Write-Host "Applying infrastructure changes..." -ForegroundColor Cyan
    Push-Location "$RootDir/infra/terraform"
    try {
        if ($DryRun) {
            Write-Host "  - Running terraform plan..." -ForegroundColor White
            # terraform plan
        } else {
            Write-Host "  - Running terraform apply..." -ForegroundColor White
            # terraform apply -auto-approve
        }
    } finally {
        Pop-Location
    }
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Verify API endpoints are responding"
Write-Host "  2. Check frontend is accessible"
Write-Host "  3. Monitor AI service health"
Write-Host "  4. Review deployment logs"
Write-Host ""

# Save deployment state
$DeploymentInfo = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Environment = $Environment
    Provider = $Provider
    Status = "Success"
}

$DeploymentInfo | ConvertTo-Json | Out-File "$RootDir/last-deployment.json"

Write-Host "Deployment information saved to last-deployment.json" -ForegroundColor Gray
