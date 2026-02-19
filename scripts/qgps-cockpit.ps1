# QGPS Autonomous Cockpit
# Orchestrates multiple repositories with automatic dependency installation and dev server launch

param(
    [Parameter(Mandatory=$false)]
    [int]$MaxConcurrency = 2,
    
    [Parameter(Mandatory=$false)]
    [string]$BrainCorePath = "$PSScriptRoot\..\brain-core"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting QGPS Autonomous Cockpit..." -ForegroundColor Cyan
Write-Host ("=" * 70) -ForegroundColor Gray

# Verify Brain registry exists
$registryPath = Join-Path $BrainCorePath "repo-registry.json"
if (-not (Test-Path $registryPath)) {
    Write-Host "❌ Brain registry not found at: $registryPath" -ForegroundColor Red
    Write-Host "Run generate-autopilot-repo.ps1 to register repositories first" -ForegroundColor Yellow
    exit 1
}

# Load registry
$registry = Get-Content $registryPath | ConvertFrom-Json

if ($registry.repositories.PSObject.Properties.Count -eq 0) {
    Write-Host "⚠️  No repositories registered in Brain" -ForegroundColor Yellow
    Write-Host "Use generate-autopilot-repo.ps1 to add repositories" -ForegroundColor Cyan
    exit 0
}

$repoCount = $registry.repositories.PSObject.Properties.Count
Write-Host "📋 Found $repoCount registered repository(ies)" -ForegroundColor Yellow
Write-Host ""

$processedRepos = @()
$launchedServers = @()

foreach ($repo in $registry.repositories.PSObject.Properties) {
    $repoName = $repo.Name
    $repoData = $repo.Value
    $repoPath = $repoData.path
    
    Write-Host "📦 Processing repository: $repoName" -ForegroundColor Cyan
    Write-Host "   Path: $repoPath" -ForegroundColor Gray
    
    if (-not (Test-Path $repoPath)) {
        Write-Host "   ⚠️  Repository path not found, skipping" -ForegroundColor Yellow
        Write-Host ""
        continue
    }
    
    # Check for package.json
    $packageJsonPath = Join-Path $repoPath "package.json"
    if (Test-Path $packageJsonPath) {
        Write-Host "   📄 Found package.json" -ForegroundColor Green
        
        # Install dependencies
        Write-Host "   🔧 Installing dependencies..." -ForegroundColor Yellow
        Push-Location $repoPath
        try {
            npm install --silent 2>&1 | Out-Null
            Write-Host "   ✅ Dependencies installed" -ForegroundColor Green
        } catch {
            Write-Host "   ⚠️  Warning: npm install had issues: $_" -ForegroundColor Yellow
        }
        Pop-Location
        
        # Check for build script
        try {
            $pkg = Get-Content $packageJsonPath | ConvertFrom-Json
            if ($pkg.scripts.PSObject.Properties.Name -contains "build") {
                Write-Host "   🏗️  Building project..." -ForegroundColor Yellow
                Push-Location $repoPath
                try {
                    npm run build 2>&1 | Out-Null
                    Write-Host "   ✅ Build completed" -ForegroundColor Green
                } catch {
                    Write-Host "   ⚠️  Warning: Build had issues" -ForegroundColor Yellow
                }
                Pop-Location
            }
            
            # Launch dev server
            if ($pkg.scripts.PSObject.Properties.Name -contains "dev") {
                Write-Host "   🚀 Starting dev server..." -ForegroundColor Green
                
                # Start dev server in new PowerShell window
                $devCommand = "cd `"$repoPath`"; Write-Host '🚀 Dev server for $repoName' -ForegroundColor Cyan; npm run dev"
                Start-Process powershell -ArgumentList "-NoExit", "-Command", $devCommand
                
                $launchedServers += $repoName
                Write-Host "   ✅ Dev server launched in new window" -ForegroundColor Green
            } elseif ($pkg.scripts.PSObject.Properties.Name -contains "start") {
                Write-Host "   🚀 Starting server..." -ForegroundColor Green
                
                # Start server in new PowerShell window
                $startCommand = "cd `"$repoPath`"; Write-Host '🚀 Server for $repoName' -ForegroundColor Cyan; npm start"
                Start-Process powershell -ArgumentList "-NoExit", "-Command", $startCommand
                
                $launchedServers += $repoName
                Write-Host "   ✅ Server launched in new window" -ForegroundColor Green
            } else {
                Write-Host "   ℹ️  No dev/start script found" -ForegroundColor Gray
            }
        } catch {
            Write-Host "   ⚠️  Error processing package.json: $_" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   ℹ️  No package.json found" -ForegroundColor Gray
    }
    
    $processedRepos += $repoName
    Write-Host ""
}

# Create cockpit log
$brainPath = Join-Path (Split-Path $BrainCorePath -Parent) ".brain"
if (-not (Test-Path $brainPath)) {
    New-Item -ItemType Directory -Path $brainPath -Force | Out-Null
}

$logData = @{
    lastRun = Get-Date -Format o
    processedRepos = $processedRepos
    launchedServers = $launchedServers
    maxConcurrency = $MaxConcurrency
}

$logPath = Join-Path $brainPath "cockpit-log.json"
$logData | ConvertTo-Json -Depth 10 | Set-Content $logPath

Write-Host ("=" * 70) -ForegroundColor Gray
Write-Host "✅ QGPS Cockpit run complete!" -ForegroundColor Green
Write-Host ("=" * 70) -ForegroundColor Gray
Write-Host ""
Write-Host "📊 Summary:" -ForegroundColor Yellow
Write-Host "   Processed repositories: $($processedRepos.Count)" -ForegroundColor Cyan
Write-Host "   Launched servers: $($launchedServers.Count)" -ForegroundColor Green

if ($launchedServers.Count -gt 0) {
    Write-Host ""
    Write-Host "🌐 Active servers:" -ForegroundColor Yellow
    foreach ($server in $launchedServers) {
        Write-Host "   - $server" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "📁 Log saved to: $logPath" -ForegroundColor Gray
Write-Host ""
Write-Host "💡 Tip: Close the dev server windows to stop the servers" -ForegroundColor Cyan
