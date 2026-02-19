# QGPS Mega Bootstrap Script
# One-shot setup for Brain core, scripts, and initial repositories

param(
    [Parameter(Mandatory=$false)]
    [string]$RootPath = "$PSScriptRoot\..",
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeExamples = $false
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 QGPS Mega Bootstrap - Industrial Autopilot Setup" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Gray
Write-Host ""

# Verify Brain core exists
$brainCorePath = Join-Path $RootPath "brain-core"
if (-not (Test-Path $brainCorePath)) {
    Write-Host "❌ ERROR: Brain core not found at: $brainCorePath" -ForegroundColor Red
    Write-Host "Please run create-qgps-starter.ps1 first" -ForegroundColor Yellow
    exit 1
}

# Verify scripts exist
$scriptsPath = Join-Path $RootPath "scripts"
$requiredScripts = @(
    "axiom-sync.ps1",
    "axiom-compliance.ps1",
    "axiom-orchestrator.ps1",
    "generate-autopilot-repo.ps1"
)

$missingScripts = @()
foreach ($script in $requiredScripts) {
    $scriptPath = Join-Path $scriptsPath $script
    if (-not (Test-Path $scriptPath)) {
        $missingScripts += $script
    }
}

if ($missingScripts.Count -gt 0) {
    Write-Host "❌ ERROR: Missing required scripts:" -ForegroundColor Red
    foreach ($script in $missingScripts) {
        Write-Host "  - $script" -ForegroundColor Red
    }
    exit 1
}

Write-Host "✅ Brain core verified" -ForegroundColor Green
Write-Host "✅ All required scripts found" -ForegroundColor Green
Write-Host ""

# Display Brain version
$versionFile = Join-Path $brainCorePath "version.json"
if (Test-Path $versionFile) {
    $version = Get-Content $versionFile | ConvertFrom-Json
    Write-Host "📦 Brain Version: $($version.brainVersion)" -ForegroundColor Yellow
    Write-Host "📅 Last Updated: $($version.lastUpdated)" -ForegroundColor Gray
    Write-Host ""
}

# Check current repository registry
$registryFile = Join-Path $brainCorePath "repo-registry.json"
$registry = Get-Content $registryFile | ConvertFrom-Json

Write-Host "📊 Current Status:" -ForegroundColor Yellow
Write-Host "  Registered Repositories: $($registry.metadata.totalRepos)" -ForegroundColor Gray
Write-Host ""

# Create example repositories if requested
if ($IncludeExamples) {
    Write-Host "🎯 Creating example repositories..." -ForegroundColor Cyan
    Write-Host ""
    
    $exampleRepos = @(
        @{Name = "axiomcore"; Path = Join-Path $RootPath "..\axiomcore"; Priority = 1}
        @{Name = "rugged-silo"; Path = Join-Path $RootPath "..\rugged-silo"; Priority = 2}
        @{Name = "veo3"; Path = Join-Path $RootPath "..\veo3"; Priority = 3}
    )
    
    $generateScript = Join-Path $scriptsPath "generate-autopilot-repo.ps1"
    
    foreach ($repo in $exampleRepos) {
        Write-Host "📦 Creating $($repo.Name)..." -ForegroundColor Cyan
        & $generateScript -RepoName $repo.Name -RepoPath $repo.Path -Priority $repo.Priority -BrainCorePath $brainCorePath
        Write-Host ""
    }
}

# Display available commands
Write-Host "=" * 70 -ForegroundColor Gray
Write-Host "✅ QGPS System Ready!" -ForegroundColor Green
Write-Host "=" * 70 -ForegroundColor Gray
Write-Host ""
Write-Host "Available Commands:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Create new autopilot repository:" -ForegroundColor Cyan
Write-Host "    .\scripts\generate-autopilot-repo.ps1 -RepoName 'MyProject' -RepoPath 'C:\Projects\MyProject'" -ForegroundColor Gray
Write-Host ""
Write-Host "  Sync repository with Brain:" -ForegroundColor Cyan
Write-Host "    .\scripts\axiom-sync.ps1 -RepoPath 'C:\Projects\MyProject'" -ForegroundColor Gray
Write-Host ""
Write-Host "  Check compliance:" -ForegroundColor Cyan
Write-Host "    .\scripts\axiom-compliance.ps1 -RepoPath 'C:\Projects\MyProject'" -ForegroundColor Gray
Write-Host ""
Write-Host "  View repository status:" -ForegroundColor Cyan
Write-Host "    .\scripts\axiom-orchestrator.ps1 -Action status" -ForegroundColor Gray
Write-Host ""
Write-Host "  Sync all repositories:" -ForegroundColor Cyan
Write-Host "    .\scripts\axiom-orchestrator.ps1 -Action sync-all" -ForegroundColor Gray
Write-Host ""
Write-Host "  Check all repositories:" -ForegroundColor Cyan
Write-Host "    .\scripts\axiom-orchestrator.ps1 -Action check-all" -ForegroundColor Gray
Write-Host ""
Write-Host "=" * 70 -ForegroundColor Gray
Write-Host "🎉 Ready to build industrial-grade autopilot systems!" -ForegroundColor Green
Write-Host "=" * 70 -ForegroundColor Gray
