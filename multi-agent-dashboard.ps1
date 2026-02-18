# Multi-Agent Monitoring Dashboard for AxiomCore
# Manages multiple projects with controlled concurrency, logging, and visual monitoring

param(
    [int]$MaxConcurrentAgents = 2,
    [switch]$VisualMode = $true,
    [switch]$AutoRetry = $false,
    [string]$BrainFile = "$env:USERPROFILE\Projects\brain-knowledge.json"
)

# Note: Ensure execution policy allows script execution
# Run this if needed: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# ------------------------------
# Configuration
# ------------------------------
$logFile = "$env:USERPROFILE\Projects\axiomcore\multi-agent-log.txt"
$projectsDir = "$env:USERPROFILE\Projects"

# Ensure directories exist
if (-not (Test-Path $projectsDir)) {
    New-Item -ItemType Directory -Path $projectsDir -Force | Out-Null
}

# Initialize log file
if (-not (Test-Path (Split-Path $logFile -Parent))) {
    New-Item -ItemType Directory -Path (Split-Path $logFile -Parent) -Force | Out-Null
}
"[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Multi-Agent Dashboard Started" | Out-File $logFile -Append

# ------------------------------
# Dashboard State Management
# ------------------------------
$global:DashboardState = @{
    Running = $true
    Paused = $false
    Agents = @()
    ActiveJobs = @{}
    CompletedAgents = @()
    FailedAgents = @()
    LogBuffer = New-Object System.Collections.Generic.List[string]
}

# ------------------------------
# Utility Functions
# ------------------------------
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Level = 'Info',
        [string]$AgentName = 'MASTER'
    )
    
    $timestamp = Get-Date -Format 'HH:mm:ss'
    $logEntry = "$timestamp - [$AgentName] $Message"
    
    # Write to file
    Add-Content $logFile $logEntry
    
    # Add to buffer for visual display
    if ($global:DashboardState.LogBuffer.Count -gt 100) {
        $global:DashboardState.LogBuffer.RemoveAt(0)
    }
    $global:DashboardState.LogBuffer.Add($logEntry)
    
    # Console output with colors
    $color = switch ($Level) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        default { 'Cyan' }
    }
    
    Write-Host $logEntry -ForegroundColor $color
}

function Get-ProgressChar {
    param([int]$Step)
    $chars = @('|', '/', '-', '\')
    return $chars[$Step % 4]
}

# ------------------------------
# Agent Management Functions
# ------------------------------
function Initialize-Agent {
    param($Project)
    
    return @{
        Name = $Project.name
        Project = $Project
        Status = 'Queued'
        Progress = 0
        CurrentStep = ''
        StartTime = $null
        EndTime = $null
        Error = $null
        RetryCount = 0
    }
}

function Run-AgentTask {
    param($Agent)
    
    $proj = $Agent.Project
    $Agent.Status = 'Running'
    $Agent.StartTime = Get-Date
    
    try {
        # Step 1: Clone/Update Repository
        $Agent.CurrentStep = 'Cloning repository'
        $Agent.Progress = 10
        Write-Log "Starting $($proj.name)" -Level Info -AgentName $proj.name
        
        $localPath = Join-Path $projectsDir $proj.name
        if (-not (Test-Path $localPath)) {
            Write-Log "Cloning repository from $($proj.repo)" -Level Info -AgentName $proj.name
            $gitOutput = git clone $proj.repo $localPath 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Log "Git clone failed: $gitOutput" -Level Error -AgentName $proj.name
                throw "Git clone failed"
            }
        } else {
            Write-Log "Updating existing repository" -Level Info -AgentName $proj.name
            Push-Location $localPath
            $gitOutput = git pull 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Log "Git pull failed: $gitOutput" -Level Warning -AgentName $proj.name
            }
            Pop-Location
        }
        $Agent.Progress = 25
        
        # Step 2: Scaffold Frontend
        $Agent.CurrentStep = 'Scaffolding frontend'
        $Agent.Progress = 30
        
        $frontendPath = Join-Path $localPath $proj.frontend.path
        if (-not (Test-Path $frontendPath)) {
            Write-Log "Creating frontend structure" -Level Info -AgentName $proj.name
            New-Item -ItemType Directory -Path $frontendPath -Force | Out-Null
            Push-Location $frontendPath
            
            # Initialize npm project
            $npmOutput = npm init -y 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Log "npm init failed: $npmOutput" -Level Warning -AgentName $proj.name
            }
            Write-Log "Installing React dependencies..." -Level Info -AgentName $proj.name
            $npmOutput = npm install react react-dom next 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Log "npm install failed: $npmOutput" -Level Error -AgentName $proj.name
                throw "npm install failed"
            }
            
            # Create basic structure
            New-Item -ItemType Directory -Path "src/app" -Force | Out-Null
            Pop-Location
        }
        $Agent.Progress = 45
        
        # Step 3: Scaffold Backend
        $Agent.CurrentStep = 'Scaffolding backend'
        $Agent.Progress = 50
        
        $apiPath = Join-Path $localPath $proj.backend.path
        if (-not (Test-Path $apiPath)) {
            Write-Log "Creating backend structure" -Level Info -AgentName $proj.name
            New-Item -ItemType Directory -Path $apiPath -Force | Out-Null
            Push-Location $apiPath
            
            $npmOutput = npm init -y 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Log "npm init failed: $npmOutput" -Level Warning -AgentName $proj.name
            }
            Write-Log "Installing Express..." -Level Info -AgentName $proj.name
            $npmOutput = npm install express 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Log "npm install failed: $npmOutput" -Level Error -AgentName $proj.name
                throw "npm install failed"
            }
            Pop-Location
        }
        $Agent.Progress = 65
        
        # Step 4: Dockerize Services
        $Agent.CurrentStep = 'Building Docker images'
        $Agent.Progress = 70
        
        $services = @{
            'frontend' = @{
                Path = $frontendPath
                Port = $proj.frontend.port
                Command = 'dev'
            }
            'api' = @{
                Path = $apiPath
                Port = $proj.backend.port
                Command = 'start'
            }
        }
        
        foreach ($serviceName in $services.Keys) {
            $service = $services[$serviceName]
            $dockerfilePath = Join-Path $service.Path "Dockerfile"
            
            if (-not (Test-Path $dockerfilePath)) {
                Write-Log "Creating Dockerfile for $serviceName" -Level Info -AgentName $proj.name
                
                $dockerContent = @"
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE $($service.Port)
CMD ["npm", "run", "$($service.Command)"]
"@
                $dockerContent | Set-Content $dockerfilePath
            }
            
            # Build Docker image
            Write-Log "Building Docker image for $serviceName" -Level Info -AgentName $proj.name
            $dockerOutput = docker build -t "$($proj.name)-$serviceName" $service.Path 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Log "Docker build failed: $dockerOutput" -Level Error -AgentName $proj.name
                throw "Docker build failed"
            }
            
            # Run Docker container
            Write-Log "Starting Docker container for $serviceName" -Level Info -AgentName $proj.name
            docker rm -f "$($proj.name)-$serviceName" 2>&1 | Out-Null
            $dockerOutput = docker run -d -p "$($service.Port):$($service.Port)" --name "$($proj.name)-$serviceName" "$($proj.name)-$serviceName" 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Log "Docker run failed: $dockerOutput" -Level Error -AgentName $proj.name
                throw "Docker run failed"
            }
        }
        
        $Agent.Progress = 90
        
        # Step 5: Open Frontend in Browser
        $Agent.CurrentStep = 'Launching browser'
        $Agent.Progress = 95
        
        if ($proj.frontend.port) {
            Start-Sleep -Seconds 2
            Start-Process "http://localhost:$($proj.frontend.port)"
            Write-Log "Frontend launched at http://localhost:$($proj.frontend.port)" -Level Success -AgentName $proj.name
        }
        
        $Agent.Status = 'Completed'
        $Agent.Progress = 100
        $Agent.EndTime = Get-Date
        Write-Log "$($proj.name) launched successfully" -Level Success -AgentName $proj.name
        
    } catch {
        $Agent.Status = 'Failed'
        $Agent.Error = $_.Exception.Message
        $Agent.EndTime = Get-Date
        Write-Log "Error in $($proj.name): $_" -Level Error -AgentName $proj.name
        
        if ($AutoRetry -and $Agent.RetryCount -lt 3) {
            $Agent.RetryCount++
            Write-Log "Scheduling retry #$($Agent.RetryCount) for $($proj.name)" -Level Warning -AgentName $proj.name
            return $false  # Signal retry needed
        }
    }
    
    return $true  # Completed (success or failed permanently)
}

# ------------------------------
# Visual Dashboard Functions
# ------------------------------
function Show-VisualDashboard {
    Clear-Host
    
    $width = [Console]::WindowWidth
    $height = [Console]::WindowHeight
    
    # Header
    Write-Host ("=" * $width) -ForegroundColor Cyan
    $headerText = " Multi-Agent Monitoring Dashboard - AxiomCore "
    $padding = [int](($width - $headerText.Length) / 2)
    Write-Host ($headerText.PadLeft($padding + $headerText.Length).PadRight($width)) -ForegroundColor Cyan -BackgroundColor DarkBlue
    Write-Host ("=" * $width) -ForegroundColor Cyan
    Write-Host ""
    
    # Control Status
    $statusColor = if ($global:DashboardState.Paused) { 'Yellow' } else { 'Green' }
    $statusText = if ($global:DashboardState.Paused) { 'PAUSED' } else { 'RUNNING' }
    Write-Host " Status: " -NoNewline
    Write-Host $statusText -ForegroundColor $statusColor
    Write-Host " Press [P] to Pause/Resume | [Q] to Quit | [R] to Refresh" -ForegroundColor Gray
    Write-Host ""
    
    # Agent Progress Section
    Write-Host " AGENT STATUS:" -ForegroundColor Yellow
    Write-Host ("-" * $width) -ForegroundColor DarkGray
    
    foreach ($agent in $global:DashboardState.Agents) {
        $statusColor = switch ($agent.Status) {
            'Completed' { 'Green' }
            'Failed' { 'Red' }
            'Running' { 'Cyan' }
            default { 'Gray' }
        }
        
        # Agent name and status
        Write-Host " [$($agent.Status.PadRight(10))]" -ForegroundColor $statusColor -NoNewline
        Write-Host " $($agent.Name.PadRight(30))" -NoNewline
        
        # Progress bar
        if ($agent.Progress -gt 0) {
            $barWidth = 30
            $filled = [Math]::Floor($agent.Progress / 100 * $barWidth)
            $empty = $barWidth - $filled
            
            Write-Host " [" -NoNewline -ForegroundColor Gray
            Write-Host ("█" * $filled) -NoNewline -ForegroundColor Green
            Write-Host ("░" * $empty) -NoNewline -ForegroundColor DarkGray
            Write-Host "]" -NoNewline -ForegroundColor Gray
            Write-Host " $($agent.Progress)%" -ForegroundColor White
            
            # Current step
            if ($agent.CurrentStep) {
                Write-Host "    └─ $($agent.CurrentStep)" -ForegroundColor DarkGray
            }
        } else {
            Write-Host ""
        }
        
        # Error message if failed
        if ($agent.Status -eq 'Failed' -and $agent.Error) {
            Write-Host "    └─ Error: $($agent.Error)" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    
    # Statistics
    $completed = ($global:DashboardState.Agents | Where-Object { $_.Status -eq 'Completed' }).Count
    $failed = ($global:DashboardState.Agents | Where-Object { $_.Status -eq 'Failed' }).Count
    $running = ($global:DashboardState.Agents | Where-Object { $_.Status -eq 'Running' }).Count
    $queued = ($global:DashboardState.Agents | Where-Object { $_.Status -eq 'Queued' }).Count
    
    Write-Host " STATISTICS:" -ForegroundColor Yellow
    Write-Host ("-" * $width) -ForegroundColor DarkGray
    Write-Host "  Completed: " -NoNewline
    Write-Host $completed -ForegroundColor Green
    Write-Host "  Failed: " -NoNewline
    Write-Host $failed -ForegroundColor Red
    Write-Host "  Running: " -NoNewline
    Write-Host $running -ForegroundColor Cyan
    Write-Host "  Queued: " -NoNewline
    Write-Host $queued -ForegroundColor Gray
    Write-Host ""
    
    # Recent Logs
    Write-Host " RECENT LOGS:" -ForegroundColor Yellow
    Write-Host ("-" * $width) -ForegroundColor DarkGray
    
    $logsToShow = [Math]::Min(10, $global:DashboardState.LogBuffer.Count)
    if ($logsToShow -gt 0) {
        $startIndex = [Math]::Max(0, $global:DashboardState.LogBuffer.Count - $logsToShow)
        for ($i = $startIndex; $i -lt $global:DashboardState.LogBuffer.Count; $i++) {
            $logEntry = $global:DashboardState.LogBuffer[$i]
            $color = if ($logEntry -match 'Error') { 'Red' } 
                    elseif ($logEntry -match 'successfully|Success') { 'Green' }
                    elseif ($logEntry -match 'Warning') { 'Yellow' }
                    else { 'Gray' }
            
            Write-Host "  $logEntry" -ForegroundColor $color
        }
    }
    
    Write-Host ""
    Write-Host ("=" * $width) -ForegroundColor Cyan
}

function Start-VisualDashboard {
    # Start dashboard refresh loop in background
    $global:DashboardRefreshJob = Start-Job -ScriptBlock {
        param($StateRef)
        while ($true) {
            Start-Sleep -Milliseconds 500
            # Signal refresh needed
        }
    } -ArgumentList $global:DashboardState
}

function Stop-VisualDashboard {
    if ($global:DashboardRefreshJob) {
        Stop-Job $global:DashboardRefreshJob
        Remove-Job $global:DashboardRefreshJob
    }
}

# ------------------------------
# Main Dashboard Loop
# ------------------------------
function Start-Dashboard {
    Write-Log "Initializing Multi-Agent Dashboard" -Level Info
    
    # Check if brain file exists
    if (-not (Test-Path $BrainFile)) {
        Write-Log "Brain Knowledge file not found at $BrainFile" -Level Error
        Write-Log "Creating sample brain-knowledge.json..." -Level Info
        
        # Create sample brain file
        $sampleBrain = @(
            @{
                name = "axiomcore"
                repo = "https://github.com/TechFusion-Quantum-Global-Platform/axiomcore.git"
                frontend = @{
                    path = "frontend"
                    port = 3000
                }
                backend = @{
                    path = "api"
                    port = 8080
                }
            }
        )
        
        $brainDir = Split-Path $BrainFile -Parent
        if (-not (Test-Path $brainDir)) {
            New-Item -ItemType Directory -Path $brainDir -Force | Out-Null
        }
        
        $sampleBrain | ConvertTo-Json -Depth 10 | Set-Content $BrainFile
        Write-Log "Sample brain-knowledge.json created. Please update it with your projects." -Level Warning
    }
    
    # Load projects
    try {
        $projects = Get-Content $BrainFile | ConvertFrom-Json
        Write-Log "Loaded $($projects.Count) project(s) from brain knowledge" -Level Success
    } catch {
        Write-Log "Failed to parse brain-knowledge.json: $_" -Level Error
        return
    }
    
    # Initialize agents
    foreach ($proj in $projects) {
        $agent = Initialize-Agent -Project $proj
        $global:DashboardState.Agents += $agent
    }
    
    # Start visual dashboard if enabled
    if ($VisualMode) {
        Write-Log "Starting visual dashboard mode" -Level Info
    }
    
    # Agent execution queue
    $agentQueue = New-Object System.Collections.Queue
    foreach ($agent in $global:DashboardState.Agents) {
        $agentQueue.Enqueue($agent)
    }
    
    $activeJobs = @()
    $refreshCounter = 0
    
    # Main loop
    while ($agentQueue.Count -gt 0 -or $activeJobs.Count -gt 0) {
        
        # Check for pause
        if ($global:DashboardState.Paused) {
            if ($VisualMode) {
                Show-VisualDashboard
            }
            Start-Sleep -Milliseconds 500
            
            # Check for keyboard input
            if ([Console]::KeyAvailable) {
                $key = [Console]::ReadKey($true)
                if ($key.Key -eq 'P') {
                    $global:DashboardState.Paused = $false
                    Write-Log "Dashboard resumed" -Level Info
                } elseif ($key.Key -eq 'Q') {
                    $global:DashboardState.Running = $false
                    break
                }
            }
            continue
        }
        
        # Start new agents if slots available
        while ($activeJobs.Count -lt $MaxConcurrentAgents -and $agentQueue.Count -gt 0) {
            $agent = $agentQueue.Dequeue()
            
            Write-Log "Starting agent for $($agent.Name)" -Level Info
            
            # Execute agent task synchronously (not in job for better error handling)
            $completed = Run-AgentTask -Agent $agent
        }
        
        # Update display
        if ($VisualMode -and ($refreshCounter % 2 -eq 0)) {
            Show-VisualDashboard
        }
        $refreshCounter++
        
        # Check if agents need retry
        $agentsToRetry = $global:DashboardState.Agents | Where-Object { 
            $_.Status -eq 'Failed' -and $AutoRetry -and $_.RetryCount -lt 3 
        }
        
        foreach ($agent in $agentsToRetry) {
            $agent.Status = 'Queued'
            $agent.Progress = 0
            $agent.Error = $null
            $agentQueue.Enqueue($agent)
            Write-Log "Retrying agent $($agent.Name) (attempt #$($agent.RetryCount + 1))" -Level Warning
        }
        
        # Check for keyboard input
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.Key -eq 'P') {
                $global:DashboardState.Paused = -not $global:DashboardState.Paused
                $status = if ($global:DashboardState.Paused) { "paused" } else { "resumed" }
                Write-Log "Dashboard $status" -Level Warning
            } elseif ($key.Key -eq 'Q') {
                $global:DashboardState.Running = $false
                Write-Log "Dashboard shutdown requested" -Level Warning
                break
            } elseif ($key.Key -eq 'R') {
                # Force refresh
                if ($VisualMode) {
                    Show-VisualDashboard
                }
            }
        }
        
        Start-Sleep -Milliseconds 500
    }
    
    # Final display
    if ($VisualMode) {
        Show-VisualDashboard
    }
    
    Write-Log "All agents completed" -Level Success
    Write-Log "Dashboard session ended" -Level Info
    
    # Summary
    $completed = ($global:DashboardState.Agents | Where-Object { $_.Status -eq 'Completed' }).Count
    $failed = ($global:DashboardState.Agents | Where-Object { $_.Status -eq 'Failed' }).Count
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " FINAL SUMMARY" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " Total Projects: $($global:DashboardState.Agents.Count)" -ForegroundColor White
    Write-Host " Completed: $completed" -ForegroundColor Green
    Write-Host " Failed: $failed" -ForegroundColor Red
    Write-Host " Log File: $logFile" -ForegroundColor Gray
    Write-Host "========================================" -ForegroundColor Cyan
}

# ------------------------------
# Entry Point
# ------------------------------
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Multi-Agent Monitoring Dashboard - AxiomCore           ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host " Configuration:" -ForegroundColor Yellow
Write-Host "  - Max Concurrent Agents: $MaxConcurrentAgents" -ForegroundColor Gray
Write-Host "  - Visual Mode: $VisualMode" -ForegroundColor Gray
Write-Host "  - Auto Retry: $AutoRetry" -ForegroundColor Gray
Write-Host "  - Brain File: $BrainFile" -ForegroundColor Gray
Write-Host "  - Log File: $logFile" -ForegroundColor Gray
Write-Host ""
Write-Host " Controls:" -ForegroundColor Yellow
Write-Host "  - Press [P] to Pause/Resume" -ForegroundColor Gray
Write-Host "  - Press [R] to Refresh display" -ForegroundColor Gray
Write-Host "  - Press [Q] to Quit" -ForegroundColor Gray
Write-Host ""

Start-Sleep -Seconds 2

# Start the dashboard
Start-Dashboard

Write-Host ""
Write-Host "Thank you for using Multi-Agent Dashboard!" -ForegroundColor Green
