# Artifact Registry Setup Script for AxiomCore MVP
# Creates and configures Google Cloud Artifact Registry for container images

param(
    [string]$ProjectId = $env:GCP_PROJECT_ID,
    [string]$Region = "us-central1",
    [string]$RepositoryName = "axiomcore-mvp"
)

Write-Host "Setting up Artifact Registry for AxiomCore MVP" -ForegroundColor Cyan
Write-Host "Project: $ProjectId" -ForegroundColor Yellow
Write-Host "Region: $Region" -ForegroundColor Yellow
Write-Host "Repository: $RepositoryName" -ForegroundColor Yellow

# Enable Artifact Registry API
Write-Host "`nEnabling Artifact Registry API..." -ForegroundColor Green
gcloud services enable artifactregistry.googleapis.com --project=$ProjectId

# Create Docker repository
Write-Host "`nCreating Docker repository..." -ForegroundColor Green
gcloud artifacts repositories create $RepositoryName `
    --repository-format=docker `
    --location=$Region `
    --description="AxiomCore MVP container images" `
    --project=$ProjectId

# Configure Docker authentication
Write-Host "`nConfiguring Docker authentication..." -ForegroundColor Green
gcloud auth configure-docker "$Region-docker.pkg.dev" --quiet

Write-Host "`nArtifact Registry setup complete!" -ForegroundColor Cyan
Write-Host "Repository URL: $Region-docker.pkg.dev/$ProjectId/$RepositoryName" -ForegroundColor Yellow
