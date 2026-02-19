# QGPS Brain Sync Script
# Synchronizes repository with Brain core policies and configurations

param(
    [Parameter(Mandatory=$true)]
    [string]$RepoPath,
    
    [Parameter(Mandatory=$false)]
    [string]$BrainCorePath = "$PSScriptRoot\..\brain-core"
)

$ErrorActionPreference = "Stop"

Write-Host "🔄 Starting Brain Sync for: $RepoPath" -ForegroundColor Cyan

# Ensure Brain folder exists in repository
$brainFolder = Join-Path $RepoPath ".brain"
if (-not (Test-Path $brainFolder)) {
    New-Item -ItemType Directory -Path $brainFolder -Force | Out-Null
    Write-Host "✅ Created .brain folder in repository" -ForegroundColor Green
}

# Load Brain core version
$versionFile = Join-Path $BrainCorePath "version.json"
if (Test-Path $versionFile) {
    $brainVersion = Get-Content $versionFile | ConvertFrom-Json
    Write-Host "📦 Brain Version: $($brainVersion.brainVersion)" -ForegroundColor Yellow
    
    # Copy version info to repo brain folder
    $brainVersion | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $brainFolder "brain-version.json")
}

# Load compliance policies
$mandatoryModules = Join-Path $BrainCorePath "compliance\mandatory-modules.json"
$infraPolicy = Join-Path $BrainCorePath "compliance\infra-policy.json"

if (Test-Path $mandatoryModules) {
    Copy-Item $mandatoryModules -Destination (Join-Path $brainFolder "mandatory-modules.json") -Force
    Write-Host "✅ Synced mandatory modules policy" -ForegroundColor Green
}

if (Test-Path $infraPolicy) {
    Copy-Item $infraPolicy -Destination (Join-Path $brainFolder "infra-policy.json") -Force
    Write-Host "✅ Synced infrastructure policy" -ForegroundColor Green
}

# Create sync metadata
$syncMetadata = @{
    lastSync = Get-Date -Format o
    brainVersion = $brainVersion.brainVersion
    syncedBy = $env:USERNAME
    repoPath = $RepoPath
}

$syncMetadata | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $brainFolder "sync-metadata.json")

Write-Host "✅ Brain sync completed successfully" -ForegroundColor Green
Write-Host "📁 Brain data stored in: $brainFolder" -ForegroundColor Gray
