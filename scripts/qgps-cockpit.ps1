# QGPS Autonomous Cockpit
# Orchestrates multiple repositories with automatic dependency installation and dev server launch

param(
    [Parameter(Mandatory=$false)]
    [int]$MaxConcurrency = 2,
    
    [Parameter(Mandatory=$false)]
    [string]$BrainCorePath = "$PSScriptRoot\..\brain-core"
)

$ErrorActionPreference = "Stop"

# Helper function to log errors to cockpit-log.json
function Write-CockpitLog {
    param(
        [string]$LogPath,
        [string]$RepoName,
        [string]$Action,
        [string]$Status,
        [string]$Message = "",
        [object]$ErrorDetails = $null
    )
    
    try {
        $logEntry = @{
            timestamp = Get-Date -Format o
            repository = $RepoName
            action = $Action
            status = $Status
            message = $Message
        }
        
        if ($ErrorDetails) {
            $logEntry.error = @{
                message = $ErrorDetails.Exception.Message
                stackTrace = $ErrorDetails.ScriptStackTrace
                category = $ErrorDetails.CategoryInfo.Category
            }
        }
        
        # Read existing log
        $existingLog = @{
            processedRepos = @()
            launchedServers = @()
            maxConcurrency = $MaxConcurrency
            lastRun = Get-Date -Format o
            detailedLogs = @()
        }
        
        if (Test-Path $LogPath) {
            $existingLog = Get-Content $LogPath | ConvertFrom-Json -AsHashtable
            if (-not $existingLog.detailedLogs) {
                $existingLog.detailedLogs = @()
            }
        }
        
        # Add new log entry
        $existingLog.detailedLogs += $logEntry
        $existingLog.lastRun = Get-Date -Format o
        
        # Save updated log
        $existingLog | ConvertTo-Json -Depth 10 | Set-Content $LogPath
    } catch {
        Write-Warning "Failed to write to cockpit log: $_"
    }
}

# Helper function to clean up completed jobs/processes
function Update-RunningJobs {
    param(
        [array]$JobList,
        [bool]$IsWindowsPlatform
    )
    
    $activeJobs = @()
    
    foreach ($item in $JobList) {
        $isStillRunning = $false
        
        if ($item.Type -eq "Job") {
            # Check PowerShell job
            $job = Get-Job -Id $item.Id -ErrorAction SilentlyContinue
            $isStillRunning = ($job -and $job.State -eq "Running")
        } elseif ($item.Type -eq "Process") {
            # Check Windows process
            $process = Get-Process -Id $item.Id -ErrorAction SilentlyContinue
            $isStillRunning = ($process -ne $null)
        }
        
        if ($isStillRunning) {
            $activeJobs += $item
        }
    }
    
    return $activeJobs
}

# Helper function to check environment versions
function Test-EnvironmentVersions {
    $results = @{
        nodeVersion = $null
        npmVersion = $null
        nodeVersionOk = $false
        npmVersionOk = $false
        warnings = @()
    }
    
    # Check Node.js version
    try {
        $nodeVersionOutput = node -v 2>&1
        if ($?) {
            $results.nodeVersion = $nodeVersionOutput.ToString().Trim()
            # Extract version number (e.g., v18.17.0 -> 18.17.0)
            if ($results.nodeVersion -match 'v?(\d+)\.') {
                $majorVersion = [int]$matches[1]
                if ($majorVersion -ge 18) {
                    $results.nodeVersionOk = $true
                } else {
                    $results.warnings += "Node.js version $($results.nodeVersion) is below recommended 18.x"
                }
            }
        }
    } catch {
        $results.warnings += "Node.js not found. Please install Node.js 18.x or higher"
    }
    
    # Check npm version
    try {
        $npmVersionOutput = npm -v 2>&1
        if ($?) {
            $results.npmVersion = $npmVersionOutput.ToString().Trim()
            $results.npmVersionOk = $true
        }
    } catch {
        $results.warnings += "npm not found. Please install npm"
    }
    
    return $results
}

# Helper function to validate repo-registry.json
function Test-RepositoryRegistry {
    param(
        [string]$RegistryPath
    )
    
    $result = @{
        isValid = $false
        registry = $null
        errors = @()
        warnings = @()
    }
    
    # Check if file exists
    if (-not (Test-Path $RegistryPath)) {
        $result.errors += "Registry file not found at: $RegistryPath"
        return $result
    }
    
    # Try to parse JSON
    try {
        $content = Get-Content $RegistryPath -Raw
        $registry = $content | ConvertFrom-Json
        $result.registry = $registry
    } catch {
        $result.errors += "Failed to parse JSON: $($_.Exception.Message)"
        return $result
    }
    
    # Validate structure
    if (-not $registry.PSObject.Properties.Name -contains "repositories") {
        $result.warnings += "Registry missing 'repositories' field, using empty object"
        $registry | Add-Member -NotePropertyName "repositories" -NotePropertyValue @{} -Force
    }
    
    if (-not $registry.PSObject.Properties.Name -contains "metadata") {
        $result.warnings += "Registry missing 'metadata' field, adding default metadata"
        $registry | Add-Member -NotePropertyName "metadata" -NotePropertyValue @{
            totalRepos = 0
            lastSync = $null
            registryVersion = "1.0.0"
        } -Force
    }
    
    # Validate each repository entry
    if ($registry.repositories.PSObject.Properties.Count -gt 0) {
        foreach ($repo in $registry.repositories.PSObject.Properties) {
            $repoName = $repo.Name
            $repoData = $repo.Value
            
            if (-not $repoData.PSObject.Properties.Name -contains "path") {
                $result.warnings += "Repository '$repoName' missing 'path' field"
            }
        }
    }
    
    $result.isValid = $true
    $result.registry = $registry
    return $result
}

Write-Host "🚀 Starting QGPS Autonomous Cockpit..." -ForegroundColor Cyan
Write-Host ("=" * 70) -ForegroundColor Gray

# Verify Brain registry exists and validate
$registryPath = Join-Path $BrainCorePath "repo-registry.json"
$validationResult = Test-RepositoryRegistry -RegistryPath $registryPath

if (-not $validationResult.isValid) {
    Write-Host "❌ Brain registry validation failed:" -ForegroundColor Red
    foreach ($errorMsg in $validationResult.errors) {
        Write-Host "   - $errorMsg" -ForegroundColor Red
    }
    Write-Host "Run generate-autopilot-repo.ps1 to register repositories first" -ForegroundColor Yellow
    exit 1
}

# Display warnings if any
if ($validationResult.warnings.Count -gt 0) {
    Write-Host "⚠️  Registry validation warnings:" -ForegroundColor Yellow
    foreach ($warningMsg in $validationResult.warnings) {
        Write-Host "   - $warningMsg" -ForegroundColor Yellow
    }
}

# Load validated registry
$registry = $validationResult.registry

if ($registry.repositories.PSObject.Properties.Count -eq 0) {
    Write-Host "⚠️  No repositories registered in Brain" -ForegroundColor Yellow
    Write-Host "Use generate-autopilot-repo.ps1 to add repositories" -ForegroundColor Cyan
    exit 0
}

# Check environment versions
Write-Host ""
Write-Host "🔍 Checking environment..." -ForegroundColor Cyan
$envCheck = Test-EnvironmentVersions

if ($envCheck.nodeVersionOk) {
    Write-Host "   ✅ Node.js: $($envCheck.nodeVersion)" -ForegroundColor Green
} elseif ($envCheck.nodeVersion) {
    Write-Host "   ⚠️  Node.js: $($envCheck.nodeVersion)" -ForegroundColor Yellow
} else {
    Write-Host "   ❌ Node.js: Not found" -ForegroundColor Red
}

if ($envCheck.npmVersionOk) {
    Write-Host "   ✅ npm: $($envCheck.npmVersion)" -ForegroundColor Green
} else {
    Write-Host "   ❌ npm: Not found" -ForegroundColor Red
}

# Display environment warnings
if ($envCheck.warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "⚠️  Environment warnings:" -ForegroundColor Yellow
    foreach ($warningMsg in $envCheck.warnings) {
        Write-Host "   - $warningMsg" -ForegroundColor Yellow
    }
}

$repoCount = $registry.repositories.PSObject.Properties.Count
Write-Host ""
Write-Host "📋 Found $repoCount registered repository(ies)" -ForegroundColor Yellow
Write-Host ""

# Prepare brain log path
$brainPath = Join-Path (Split-Path $BrainCorePath -Parent) ".brain"
if (-not (Test-Path $brainPath)) {
    New-Item -ItemType Directory -Path $brainPath -Force | Out-Null
}
$logPath = Join-Path $brainPath "cockpit-log.json"

$processedRepos = @()
$launchedServers = @()
$runningJobs = @()

# Detect if we're running on PowerShell Core (cross-platform)
$isPSCore = $PSVersionTable.PSEdition -eq "Core"
if ($isPSCore) {
    $isWindowsPlatform = $IsWindows
} else {
    # Windows PowerShell (version 5.x and below) always runs on Windows
    $isWindowsPlatform = $true
}

foreach ($repo in $registry.repositories.PSObject.Properties) {
    $repoName = $repo.Name
    $repoData = $repo.Value
    $repoPath = $repoData.path
    
    Write-Host "📦 Processing repository: $repoName" -ForegroundColor Cyan
    Write-Host "   Path: $repoPath" -ForegroundColor Gray
    
    if (-not (Test-Path $repoPath)) {
        Write-Host "   ⚠️  Repository path not found, skipping" -ForegroundColor Yellow
        Write-CockpitLog -LogPath $logPath -RepoName $repoName -Action "validate" -Status "skipped" -Message "Repository path not found"
        Write-Host ""
        continue
    }
    
    # Check for package.json
    $packageJsonPath = Join-Path $repoPath "package.json"
    if (Test-Path $packageJsonPath) {
        Write-Host "   📄 Found package.json" -ForegroundColor Green
        
        # Install dependencies with error handling
        Write-Host "   🔧 Installing dependencies..." -ForegroundColor Yellow
        Push-Location $repoPath
        try {
            $installOutput = npm install --silent 2>&1 | Out-String
            
            if ($?) {
                Write-Host "   ✅ Dependencies installed" -ForegroundColor Green
                Write-CockpitLog -LogPath $logPath -RepoName $repoName -Action "npm-install" -Status "success" -Message "Dependencies installed successfully"
            } else {
                $errorMsg = "npm install failed"
                if ($installOutput) {
                    $errorMsg += " - $installOutput"
                }
                throw $errorMsg
            }
        } catch {
            Write-Host "   ❌ Error during npm install: $($_.Exception.Message)" -ForegroundColor Red
            Write-CockpitLog -LogPath $logPath -RepoName $repoName -Action "npm-install" -Status "failed" -Message "npm install failed" -ErrorDetails $_
        } finally {
            Pop-Location
        }
        
        # Check for build script and build with error handling
        try {
            $pkg = Get-Content $packageJsonPath | ConvertFrom-Json
            
            # Check for Next.js dependency
            if ($pkg.dependencies.PSObject.Properties.Name -contains "next") {
                $nextVersion = $pkg.dependencies.next
                Write-Host "   📦 Next.js project detected: $nextVersion" -ForegroundColor Cyan
            }
            
            if ($pkg.scripts.PSObject.Properties.Name -contains "build") {
                Write-Host "   🏗️  Building project..." -ForegroundColor Yellow
                Push-Location $repoPath
                try {
                    $buildOutput = npm run build 2>&1 | Out-String
                    
                    if ($?) {
                        Write-Host "   ✅ Build completed" -ForegroundColor Green
                        Write-CockpitLog -LogPath $logPath -RepoName $repoName -Action "npm-build" -Status "success" -Message "Build completed successfully"
                    } else {
                        throw "npm run build failed"
                    }
                } catch {
                    Write-Host "   ❌ Error during build: $($_.Exception.Message)" -ForegroundColor Red
                    Write-CockpitLog -LogPath $logPath -RepoName $repoName -Action "npm-build" -Status "failed" -Message "Build failed" -ErrorDetails $_
                } finally {
                    Pop-Location
                }
            }
            
            # Launch dev server with concurrency control
            if ($pkg.scripts.PSObject.Properties.Name -contains "dev") {
                # Implement concurrency control
                while ($runningJobs.Count -ge $MaxConcurrency) {
                    Write-Host "   ⏳ Waiting for available slot (current: $($runningJobs.Count)/$MaxConcurrency)..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                    
                    # Clean up completed jobs/processes
                    $runningJobs = Update-RunningJobs -JobList $runningJobs -IsWindowsPlatform $isWindowsPlatform
                }
                
                Write-Host "   🚀 Starting dev server..." -ForegroundColor Green
                
                try {
                    if ($isWindowsPlatform) {
                        # Windows: Use Start-Process with PowerShell window
                        $devCommand = "cd `"$repoPath`"; Write-Host '🚀 Dev server for $repoName' -ForegroundColor Cyan; npm run dev"
                        $process = Start-Process powershell -ArgumentList "-NoExit", "-Command", $devCommand -PassThru
                        
                        # Track as job-like object for concurrency
                        $runningJobs += @{
                            Id = $process.Id
                            RepoName = $repoName
                            Type = "Process"
                        }
                    } else {
                        # Linux/macOS: Use Start-Job for background execution
                        $job = Start-Job -ScriptBlock {
                            param($path, $name)
                            Set-Location $path
                            Write-Host "🚀 Dev server for $name" -ForegroundColor Cyan
                            npm run dev
                        } -ArgumentList $repoPath, $repoName
                        
                        $runningJobs += @{
                            Id = $job.Id
                            RepoName = $repoName
                            Type = "Job"
                        }
                        
                        Write-Host "   ℹ️  Dev server started as background job (ID: $($job.Id))" -ForegroundColor Gray
                        Write-Host "   💡 Use 'Get-Job' and 'Receive-Job $($job.Id)' to check output" -ForegroundColor Cyan
                    }
                    
                    $launchedServers += $repoName
                    Write-Host "   ✅ Dev server launched" -ForegroundColor Green
                    Write-CockpitLog -LogPath $logPath -RepoName $repoName -Action "start-dev" -Status "success" -Message "Dev server launched successfully"
                } catch {
                    Write-Host "   ❌ Error launching dev server: $($_.Exception.Message)" -ForegroundColor Red
                    Write-CockpitLog -LogPath $logPath -RepoName $repoName -Action "start-dev" -Status "failed" -Message "Failed to launch dev server" -ErrorDetails $_
                }
            } elseif ($pkg.scripts.PSObject.Properties.Name -contains "start") {
                # Similar concurrency control for start script
                while ($runningJobs.Count -ge $MaxConcurrency) {
                    Write-Host "   ⏳ Waiting for available slot (current: $($runningJobs.Count)/$MaxConcurrency)..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                    
                    # Clean up completed jobs/processes
                    $runningJobs = Update-RunningJobs -JobList $runningJobs -IsWindowsPlatform $isWindowsPlatform
                }
                
                Write-Host "   🚀 Starting server..." -ForegroundColor Green
                
                try {
                    if ($isWindowsPlatform) {
                        # Windows: Use Start-Process with PowerShell window
                        $startCommand = "cd `"$repoPath`"; Write-Host '🚀 Server for $repoName' -ForegroundColor Cyan; npm start"
                        $process = Start-Process powershell -ArgumentList "-NoExit", "-Command", $startCommand -PassThru
                        
                        # Track as job-like object for concurrency
                        $runningJobs += @{
                            Id = $process.Id
                            RepoName = $repoName
                            Type = "Process"
                        }
                    } else {
                        # Linux/macOS: Use Start-Job for background execution
                        $job = Start-Job -ScriptBlock {
                            param($path, $name)
                            Set-Location $path
                            Write-Host "🚀 Server for $name" -ForegroundColor Cyan
                            npm start
                        } -ArgumentList $repoPath, $repoName
                        
                        $runningJobs += @{
                            Id = $job.Id
                            RepoName = $repoName
                            Type = "Job"
                        }
                        
                        Write-Host "   ℹ️  Server started as background job (ID: $($job.Id))" -ForegroundColor Gray
                        Write-Host "   💡 Use 'Get-Job' and 'Receive-Job $($job.Id)' to check output" -ForegroundColor Cyan
                    }
                    
                    $launchedServers += $repoName
                    Write-Host "   ✅ Server launched" -ForegroundColor Green
                    Write-CockpitLog -LogPath $logPath -RepoName $repoName -Action "start-server" -Status "success" -Message "Server launched successfully"
                } catch {
                    Write-Host "   ❌ Error launching server: $($_.Exception.Message)" -ForegroundColor Red
                    Write-CockpitLog -LogPath $logPath -RepoName $repoName -Action "start-server" -Status "failed" -Message "Failed to launch server" -ErrorDetails $_
                }
            } else {
                Write-Host "   ℹ️  No dev/start script found" -ForegroundColor Gray
            }
        } catch {
            Write-Host "   ⚠️  Error processing package.json: $_" -ForegroundColor Yellow
            Write-CockpitLog -LogPath $logPath -RepoName $repoName -Action "process-package" -Status "failed" -Message "Error processing package.json" -ErrorDetails $_
        }
    } else {
        Write-Host "   ℹ️  No package.json found" -ForegroundColor Gray
        Write-CockpitLog -LogPath $logPath -RepoName $repoName -Action "validate" -Status "skipped" -Message "No package.json found"
    }
    
    $processedRepos += $repoName
    Write-Host ""
}

# Create final cockpit log
$logData = @{
    lastRun = Get-Date -Format o
    processedRepos = $processedRepos
    launchedServers = $launchedServers
    maxConcurrency = $MaxConcurrency
    runningJobs = $runningJobs.Count
    platform = @{
        edition = $PSVersionTable.PSEdition
        version = $PSVersionTable.PSVersion.ToString()
        os = $PSVersionTable.OS
        isWindows = $isWindowsPlatform
    }
    environment = @{
        nodeVersion = $envCheck.nodeVersion
        npmVersion = $envCheck.npmVersion
    }
}

$logData | ConvertTo-Json -Depth 10 | Set-Content $logPath

Write-Host ("=" * 70) -ForegroundColor Gray
Write-Host "✅ QGPS Cockpit run complete!" -ForegroundColor Green
Write-Host ("=" * 70) -ForegroundColor Gray
Write-Host ""
Write-Host "📊 Summary:" -ForegroundColor Yellow
Write-Host "   Platform: PowerShell $($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion)" -ForegroundColor Cyan
Write-Host "   Processed repositories: $($processedRepos.Count)" -ForegroundColor Cyan
Write-Host "   Launched servers: $($launchedServers.Count)" -ForegroundColor Green
Write-Host "   Running jobs: $($runningJobs.Count)" -ForegroundColor Cyan
Write-Host "   Max concurrency: $MaxConcurrency" -ForegroundColor Gray

if ($launchedServers.Count -gt 0) {
    Write-Host ""
    Write-Host "🌐 Active servers:" -ForegroundColor Yellow
    foreach ($server in $launchedServers) {
        Write-Host "   - $server" -ForegroundColor Green
    }
}

if ($runningJobs.Count -gt 0 -and -not $isWindowsPlatform) {
    Write-Host ""
    Write-Host "💼 Background jobs:" -ForegroundColor Yellow
    foreach ($job in $runningJobs) {
        if ($job.Type -eq "Job") {
            Write-Host "   - $($job.RepoName) (Job ID: $($job.Id))" -ForegroundColor Cyan
        }
    }
    Write-Host ""
    Write-Host "💡 Tip: Use 'Get-Job' to see job status, 'Receive-Job <ID>' to see output" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "📁 Log saved to: $logPath" -ForegroundColor Gray
Write-Host ""

if ($isWindowsPlatform) {
    Write-Host "💡 Tip: Close the PowerShell windows to stop the servers" -ForegroundColor Cyan
} else {
    Write-Host "💡 Tip: Use 'Stop-Job <ID>' to stop background jobs" -ForegroundColor Cyan
}
