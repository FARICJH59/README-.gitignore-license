# Script to create the axiomcore repository using GitHub CLI

$ErrorActionPreference = "Stop"

Write-Host "Creating Axiomcore-SYSTEM repository..." -ForegroundColor Cyan
Write-Host "Owner: FARIJCH59"
Write-Host "Repository: Axiomcore-SYSTEM"
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
gh repo create FARIJCH59/Axiomcore-SYSTEM `
  --private `
  --description "AxiomCore MVP — backend, frontend, AI orchestration" `
  --confirm

Write-Host ""
Write-Host "Repository created successfully!" -ForegroundColor Green
Write-Host "Clone it with:"
Write-Host "  git clone https://github.com/FARIJCH59/Axiomcore-SYSTEM.git" -ForegroundColor Yellow
