<# 
    Installs dependencies for both backend (Python) and frontend (Node).
    Run this once per environment or after pulling new dependencies.
#>

Write-Host "Setting up project environment..." -ForegroundColor Cyan

Write-Host "Upgrading pip..." -ForegroundColor Yellow
python -m pip install --upgrade pip

Write-Host "Installing backend dependencies from requirements.txt..." -ForegroundColor Yellow
python -m pip install -r requirements.txt

Write-Host "Installing frontend dependencies..." -ForegroundColor Yellow
Push-Location frontend
npm install
Pop-Location

Write-Host "Setup complete!" -ForegroundColor Green
