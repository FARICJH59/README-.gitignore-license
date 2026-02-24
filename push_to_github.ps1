<# 
    Convenience script to commit and push local changes.
    Assumes git is configured and remote is set.
#>

param(
    [string]$Message = "chore: update agentic fullstack platform"
)

Write-Host "Adding changes..." -ForegroundColor Yellow
git add .

Write-Host "Creating commit..." -ForegroundColor Yellow
git commit -m $Message

Write-Host "Pushing to remote..." -ForegroundColor Yellow
git push

Write-Host "Push complete." -ForegroundColor Green
