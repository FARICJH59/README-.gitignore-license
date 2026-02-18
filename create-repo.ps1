# Script to create the axiomcore repository using GitHub CLI

$ErrorActionPreference = "Stop"

Write-Host "Creating axiomcore repository..." -ForegroundColor Cyan
Write-Host "Organization: TechFusion-Quantum-Global-Platform"
Write-Host "Repository: axiomcore"
Write-Host "Visibility: private"
Write-Host ""

# Check if gh CLI is installed
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "Error: GitHub CLI (gh) is not installed." -ForegroundColor Red
    Write-Host "Please install it from: https://cli.github.com/"
    exit 1
}

# Check if gh is authenticated
try {
    gh auth status 2>&1 | Out-Null
} catch {
    Write-Host "Error: GitHub CLI is not authenticated." -ForegroundColor Red
    Write-Host "Please run: gh auth login"
    exit 1
}

# Create the repository
gh repo create TechFusion-Quantum-Global-Platform/axiomcore `
  --private `
  --description "AxiomCore MVP — backend, frontend, AI orchestration" `
  --confirm

Write-Host ""
Write-Host "Repository created successfully!" -ForegroundColor Green
Write-Host "Clone it with:"
Write-Host "  git clone https://github.com/TechFusion-Quantum-Global-Platform/axiomcore.git" -ForegroundColor Yellow
