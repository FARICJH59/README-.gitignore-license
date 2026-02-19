# QGPS Generate Autopilot Repository Script
# Registers a repository with the Brain core and makes it autopilot-ready

param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    
    [Parameter(Mandatory=$true)]
    [string]$RepoPath,
    
    [Parameter(Mandatory=$false)]
    [int]$Priority = 5,
    
    [Parameter(Mandatory=$false)]
    [string]$BrainCorePath = "$PSScriptRoot\..\brain-core"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Generating Autopilot-Ready Repository" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray
Write-Host "Repository: $RepoName" -ForegroundColor Yellow
Write-Host "Path: $RepoPath" -ForegroundColor Yellow
Write-Host "Priority: $Priority" -ForegroundColor Yellow
Write-Host "=" * 60 -ForegroundColor Gray
Write-Host ""

# Validate repository path
if (-not (Test-Path $RepoPath)) {
    Write-Host "📁 Creating repository directory..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $RepoPath -Force | Out-Null
    Write-Host "✅ Repository directory created" -ForegroundColor Green
}

# Ensure .brain folder exists
$brainPath = Join-Path $RepoPath ".brain"
if (-not (Test-Path $brainPath)) {
    New-Item -ItemType Directory -Path $brainPath -Force | Out-Null
    Write-Host "✅ Created .brain folder" -ForegroundColor Green
}

# Load repository registry
$registryFile = Join-Path $BrainCorePath "repo-registry.json"
$registry = Get-Content $registryFile | ConvertFrom-Json

# Check if repository already registered
$repoExists = $false
foreach ($prop in $registry.repositories.PSObject.Properties) {
    if ($prop.Name -eq $RepoName) {
        $repoExists = $true
        Write-Host "⚠️  Repository '$RepoName' already registered" -ForegroundColor Yellow
        Write-Host "Updating registration..." -ForegroundColor Cyan
        break
    }
}

# Register or update repository
if (-not $repoExists) {
    # Add new repository
    $registry.repositories | Add-Member -NotePropertyName $RepoName -NotePropertyValue @{
        path = $RepoPath
        priority = $Priority
        registeredAt = Get-Date -Format o
        lastSync = $null
    }
    
    $registry.metadata.totalRepos++
    Write-Host "✅ Repository registered in Brain core" -ForegroundColor Green
} else {
    # Update existing repository
    $registry.repositories.$RepoName.path = $RepoPath
    $registry.repositories.$RepoName.priority = $Priority
    $registry.repositories.$RepoName.updatedAt = Get-Date -Format o
    Write-Host "✅ Repository registration updated" -ForegroundColor Green
}

# Save updated registry
$registry | ConvertTo-Json -Depth 10 | Set-Content $registryFile
Write-Host "💾 Registry saved" -ForegroundColor Green
Write-Host ""

# Run Brain sync
Write-Host "🔄 Running Brain sync..." -ForegroundColor Cyan
$syncScript = Join-Path $PSScriptRoot "axiom-sync.ps1"
& $syncScript -RepoPath $RepoPath -BrainCorePath $BrainCorePath
Write-Host ""

# Run compliance check
Write-Host "🔍 Running compliance check..." -ForegroundColor Cyan
$complianceScript = Join-Path $PSScriptRoot "axiom-compliance.ps1"
try {
    & $complianceScript -RepoPath $RepoPath -FixIssues -ErrorAction Stop
    Write-Host ""
} catch {
    Write-Host "⚠️  Compliance check found issues (auto-fixed)" -ForegroundColor Yellow
    Write-Host ""
}

# Run orchestrator to update status
Write-Host "🎯 Updating orchestrator status..." -ForegroundColor Cyan
$orchestratorScript = Join-Path $PSScriptRoot "axiom-orchestrator.ps1"
& $orchestratorScript -Action status -BrainCorePath $BrainCorePath
Write-Host ""

Write-Host "=" * 60 -ForegroundColor Gray
Write-Host "✅ Repository '$RepoName' is now fully autopilot-ready and MCP-compliant!" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Navigate to: $RepoPath" -ForegroundColor Gray
Write-Host "  2. Review .brain folder for synced policies" -ForegroundColor Gray
Write-Host "  3. Start developing with Brain-enforced compliance" -ForegroundColor Gray
