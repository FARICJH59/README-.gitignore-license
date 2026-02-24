<# 
    Helper launcher that chains setup + start.
    - Ensures dependencies exist
    - Boots backend and frontend
#>

Write-Host "Launching fullstack (setup + start)..." -ForegroundColor Cyan

.\setup-fullstack.ps1
.\start-all.ps1
