# QGPS Orchestrator Script
# Orchestrates multi-repo operations and Brain core management

param(
    [Parameter(Mandatory=$false)]
    [string]$Action = "status",
    
    [Parameter(Mandatory=$false)]
    [string]$BrainCorePath = "$PSScriptRoot\..\brain-core"
)

$ErrorActionPreference = "Stop"

Write-Host "🎯 QGPS Orchestrator - $Action" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray

# Load repository registry
$registryFile = Join-Path $BrainCorePath "repo-registry.json"
if (-not (Test-Path $registryFile)) {
    Write-Host "❌ ERROR: Repository registry not found at: $registryFile" -ForegroundColor Red
    exit 1
}

$registry = Get-Content $registryFile | ConvertFrom-Json

switch ($Action.ToLower()) {
    "status" {
        Write-Host "📊 Repository Status Report" -ForegroundColor Yellow
        Write-Host ""
        
        if ($registry.repositories.PSObject.Properties.Count -eq 0) {
            Write-Host "  No repositories registered yet" -ForegroundColor Gray
            Write-Host "  Use generate-autopilot-repo.ps1 to add repositories" -ForegroundColor Cyan
        } else {
            foreach ($repo in $registry.repositories.PSObject.Properties) {
                $repoName = $repo.Name
                $repoData = $repo.Value
                
                Write-Host "  📦 $repoName" -ForegroundColor Green
                Write-Host "     Path: $($repoData.path)" -ForegroundColor Gray
                Write-Host "     Priority: $($repoData.priority)" -ForegroundColor Gray
                
                # Check if repo exists
                if (Test-Path $repoData.path) {
                    Write-Host "     Status: ✅ Exists" -ForegroundColor Green
                    
                    # Check for .brain folder
                    $brainPath = Join-Path $repoData.path ".brain"
                    if (Test-Path $brainPath) {
                        Write-Host "     Brain: ✅ Synced" -ForegroundColor Green
                    } else {
                        Write-Host "     Brain: ⚠️  Not synced" -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "     Status: ❌ Not found" -ForegroundColor Red
                }
                Write-Host ""
            }
        }
        
        Write-Host "Total Repositories: $($registry.metadata.totalRepos)" -ForegroundColor Cyan
    }
    
    "sync-all" {
        Write-Host "🔄 Syncing all repositories with Brain..." -ForegroundColor Yellow
        Write-Host ""
        
        $syncScript = Join-Path $PSScriptRoot "axiom-sync.ps1"
        
        foreach ($repo in $registry.repositories.PSObject.Properties) {
            $repoName = $repo.Name
            $repoPath = $repo.Value.path
            
            if (Test-Path $repoPath) {
                Write-Host "📦 Syncing $repoName..." -ForegroundColor Cyan
                & $syncScript -RepoPath $repoPath
                Write-Host ""
            } else {
                Write-Host "⚠️  Skipping $repoName (path not found)" -ForegroundColor Yellow
                Write-Host ""
            }
        }
        
        Write-Host "✅ All repositories synced" -ForegroundColor Green
    }
    
    "check-all" {
        Write-Host "🔍 Checking compliance for all repositories..." -ForegroundColor Yellow
        Write-Host ""
        
        $complianceScript = Join-Path $PSScriptRoot "axiom-compliance.ps1"
        $results = @{
            passed = @()
            failed = @()
        }
        
        foreach ($repo in $registry.repositories.PSObject.Properties) {
            $repoName = $repo.Name
            $repoPath = $repo.Value.path
            
            if (Test-Path $repoPath) {
                Write-Host "📦 Checking $repoName..." -ForegroundColor Cyan
                
                try {
                    & $complianceScript -RepoPath $repoPath -ErrorAction Stop
                    $results.passed += $repoName
                } catch {
                    $results.failed += $repoName
                }
                
                Write-Host ""
            } else {
                Write-Host "⚠️  Skipping $repoName (path not found)" -ForegroundColor Yellow
                Write-Host ""
            }
        }
        
        Write-Host "=" * 60 -ForegroundColor Gray
        Write-Host "📊 Compliance Summary" -ForegroundColor Yellow
        Write-Host "  ✅ Passed: $($results.passed.Count)" -ForegroundColor Green
        Write-Host "  ❌ Failed: $($results.failed.Count)" -ForegroundColor Red
        
        if ($results.failed.Count -gt 0) {
            Write-Host ""
            Write-Host "Failed repositories:" -ForegroundColor Red
            foreach ($failed in $results.failed) {
                Write-Host "  - $failed" -ForegroundColor Red
            }
        }
    }
    
    default {
        Write-Host "❌ Unknown action: $Action" -ForegroundColor Red
        Write-Host ""
        Write-Host "Available actions:" -ForegroundColor Yellow
        Write-Host "  status      - Show status of all registered repositories" -ForegroundColor Gray
        Write-Host "  sync-all    - Sync all repositories with Brain core" -ForegroundColor Gray
        Write-Host "  check-all   - Check compliance for all repositories" -ForegroundColor Gray
        exit 1
    }
}

Write-Host "=" * 60 -ForegroundColor Gray
Write-Host "✅ Orchestrator completed" -ForegroundColor Green
