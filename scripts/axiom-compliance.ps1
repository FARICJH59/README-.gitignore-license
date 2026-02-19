# QGPS Compliance Check Script
# Validates repository compliance with Brain core policies

param(
    [Parameter(Mandatory=$true)]
    [string]$RepoPath,
    
    [Parameter(Mandatory=$false)]
    [switch]$FixIssues = $false
)

$ErrorActionPreference = "Stop"

Write-Host "🔍 Starting Compliance Check for: $RepoPath" -ForegroundColor Cyan

# Load compliance policies from .brain folder
$brainFolder = Join-Path $RepoPath ".brain"
if (-not (Test-Path $brainFolder)) {
    Write-Host "❌ ERROR: .brain folder not found. Run axiom-sync.ps1 first." -ForegroundColor Red
    exit 1
}

$mandatoryModulesFile = Join-Path $brainFolder "mandatory-modules.json"
$infraPolicyFile = Join-Path $brainFolder "infra-policy.json"

if (-not (Test-Path $mandatoryModulesFile) -or -not (Test-Path $infraPolicyFile)) {
    Write-Host "❌ ERROR: Compliance policies not found. Run axiom-sync.ps1 first." -ForegroundColor Red
    exit 1
}

$mandatoryModules = Get-Content $mandatoryModulesFile | ConvertFrom-Json
$infraPolicy = Get-Content $infraPolicyFile | ConvertFrom-Json

$complianceReport = @{
    timestamp = Get-Date -Format o
    repoPath = $RepoPath
    overallCompliance = $true
    issues = @()
    warnings = @()
}

Write-Host "📋 Checking mandatory folders..." -ForegroundColor Yellow

# Check mandatory folders
foreach ($folder in $mandatoryModules.mandatoryFolders) {
    $folderPath = Join-Path $RepoPath $folder
    if (-not (Test-Path $folderPath)) {
        $complianceReport.issues += "Missing mandatory folder: $folder"
        $complianceReport.overallCompliance = $false
        Write-Host "  ❌ Missing: $folder" -ForegroundColor Red
        
        if ($FixIssues) {
            New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
            Write-Host "  ✅ Created: $folder" -ForegroundColor Green
        }
    } else {
        Write-Host "  ✅ Found: $folder" -ForegroundColor Green
    }
}

Write-Host "📋 Checking mandatory files..." -ForegroundColor Yellow

# Check mandatory files
foreach ($file in $mandatoryModules.mandatoryFiles) {
    $filePath = Join-Path $RepoPath $file
    if (-not (Test-Path $filePath)) {
        $complianceReport.issues += "Missing mandatory file: $file"
        $complianceReport.overallCompliance = $false
        Write-Host "  ❌ Missing: $file" -ForegroundColor Red
        
        if ($FixIssues) {
            # Create placeholder file
            "" | Set-Content $filePath
            Write-Host "  ✅ Created placeholder: $file" -ForegroundColor Green
        }
    } else {
        Write-Host "  ✅ Found: $file" -ForegroundColor Green
    }
}

Write-Host "📋 Checking recommended files..." -ForegroundColor Yellow

# Check recommended files (warnings only)
foreach ($file in $mandatoryModules.recommendedFiles) {
    $filePath = Join-Path $RepoPath $file
    if (-not (Test-Path $filePath)) {
        $complianceReport.warnings += "Missing recommended file: $file"
        Write-Host "  ⚠️  Recommended: $file" -ForegroundColor Yellow
    } else {
        Write-Host "  ✅ Found: $file" -ForegroundColor Green
    }
}

# Save compliance report
$reportPath = Join-Path $brainFolder "compliance-log.json"
$complianceReport | ConvertTo-Json -Depth 10 | Set-Content $reportPath

if ($complianceReport.overallCompliance) {
    Write-Host "✅ Compliance check PASSED" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ Compliance check FAILED" -ForegroundColor Red
    Write-Host "📄 Issues found: $($complianceReport.issues.Count)" -ForegroundColor Red
    Write-Host "⚠️  Warnings: $($complianceReport.warnings.Count)" -ForegroundColor Yellow
    Write-Host "📁 Full report: $reportPath" -ForegroundColor Gray
    
    if (-not $FixIssues) {
        Write-Host "💡 Run with -FixIssues to auto-fix structure issues" -ForegroundColor Cyan
    }
    
    exit 1
}
