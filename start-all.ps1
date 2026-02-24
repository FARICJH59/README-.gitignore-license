<# 
    Bootstraps the local fullstack experience.
    - Launches FastAPI backend (server.py)
    - Launches Vite frontend (npm run dev) in frontend/
#>

Write-Host "Starting Agentic Fullstack Platform..." -ForegroundColor Cyan

Write-Host "Launching Python backend on http://localhost:8000..." -ForegroundColor Yellow
Start-Process python "server.py"

Write-Host "Launching React frontend (default http://localhost:5173, Vite may pick another open port)..." -ForegroundColor Yellow
Start-Process "npm" "run dev" -WorkingDirectory "./frontend"

Write-Host "Backend and frontend launched. Press Ctrl+C in opened terminals to stop." -ForegroundColor Green
