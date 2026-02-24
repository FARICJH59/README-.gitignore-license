<# 
    Opinionated setup for the AxiomCore/Agentic platform.
    - Validates core tooling versions
    - Installs backend + frontend dependencies
    - Prints next-step guidance
#>

function Test-Command {
    param([string]$Name)
    try { Get-Command $Name -ErrorAction Stop | Out-Null; return $true }
    catch { return $false }
}

Write-Host "Running AxiomCore fullstack setup..." -ForegroundColor Cyan

if (-not (Test-Command "python")) {
    Write-Error "Python is required. Please install Python 3.8+."
    exit 1
}

if (-not (Test-Command "npm")) {
    Write-Error "npm is required. Please install Node.js 18+."
    exit 1
}

Write-Host "Installing Python dependencies..." -ForegroundColor Yellow
python -m pip install --upgrade pip
python -m pip install -r requirements.txt

Write-Host "Installing frontend dependencies..." -ForegroundColor Yellow
Push-Location frontend
npm install
Pop-Location

Write-Host "Setup complete. Start the stack with start-all.ps1 or run components manually." -ForegroundColor Green
