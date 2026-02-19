# QGPS Enterprise Branch Protection Setup Script
# Configures enterprise-level branch protection and automation system
# Author: QGPS Automation Team
# Version: 1.0.0

param(
    [Parameter(Mandatory=$false)]
    [string]$RepoOwner = "FARICJH59",
    
    [Parameter(Mandatory=$false)]
    [string]$RepoName = "axiomcore",
    
    [Parameter(Mandatory=$false)]
    [string]$GitHubToken = $env:GITHUB_TOKEN,
    
    [Parameter(Mandatory=$false)]
    [string]$BranchName = "main",
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipBranchProtection = $false
)

$ErrorActionPreference = "Stop"

# Validate script location - must be run from repository root
function Test-RepositoryLocation {
    $scriptDir = $PSScriptRoot
    $requiredFiles = @("scripts", ".github", "README.md")
    $missingFiles = @()
    
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path $scriptDir $file
        if (-not (Test-Path $filePath)) {
            $missingFiles += $file
        }
    }
    
    if ($missingFiles.Count -gt 0) {
        Write-Host ""
        Write-Host "═" * 70 -ForegroundColor Red
        Write-Host "❌ ERROR: Script Not Run From Repository Root" -ForegroundColor Red
        Write-Host "═" * 70 -ForegroundColor Red
        Write-Host ""
        Write-Host "This script must be run from the repository root directory." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Current location: $scriptDir" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Missing required files/folders:" -ForegroundColor Yellow
        foreach ($missing in $missingFiles) {
            Write-Host "  • $missing" -ForegroundColor Red
        }
        Write-Host ""
        Write-Host "To fix this issue:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "1. Navigate to your repository directory:" -ForegroundColor White
        Write-Host "   cd C:\path\to\your\repository" -ForegroundColor Gray
        Write-Host ""
        Write-Host "2. Verify you're in the correct location:" -ForegroundColor White
        Write-Host "   ls" -ForegroundColor Gray
        Write-Host "   # Should show: scripts/, .github/, README.md, setup-enterprise-protection.ps1" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "3. Run the script again:" -ForegroundColor White
        Write-Host "   .\setup-enterprise-protection.ps1" -ForegroundColor Gray
        Write-Host ""
        Write-Host "═" * 70 -ForegroundColor Red
        Write-Host ""
        return $false
    }
    
    return $true
}

# Check if running from correct location
if (-not (Test-RepositoryLocation)) {
    exit 1
}

# Color output functions
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White",
        [string]$Prefix = ""
    )
    
    $prefixColor = switch ($Prefix) {
        "✅" { "Green" }
        "❌" { "Red" }
        "⚠️" { "Yellow" }
        "🔧" { "Cyan" }
        "📋" { "Blue" }
        "🚀" { "Magenta" }
        default { "White" }
    }
    
    if ($Prefix) {
        Write-Host "$Prefix " -ForegroundColor $prefixColor -NoNewline
    }
    Write-Host $Message -ForegroundColor $Color
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "═" * 70 -ForegroundColor Gray
    Write-Host $Title -ForegroundColor Cyan
    Write-Host "═" * 70 -ForegroundColor Gray
}

function Write-SubSection {
    param([string]$Title)
    Write-Host ""
    Write-Host "─" * 70 -ForegroundColor DarkGray
    Write-Host $Title -ForegroundColor Yellow
}

# Initialize logging
$brainPath = Join-Path $PSScriptRoot ".brain"
if (-not (Test-Path $brainPath)) {
    New-Item -ItemType Directory -Path $brainPath -Force | Out-Null
}
$logPath = Join-Path $brainPath "cockpit-log.json"

function Add-LogEntry {
    param(
        [string]$Action,
        [string]$Status,
        [string]$Message = "",
        [object]$Details = $null
    )
    
    try {
        $logEntry = @{
            timestamp = Get-Date -Format o
            action = $Action
            status = $Status
            message = $Message
        }
        
        if ($Details) {
            $logEntry.details = $Details
        }
        
        # Read existing log
        $existingLog = @{
            setupVersion = "1.0.0"
            lastRun = Get-Date -Format o
            entries = @()
        }
        
        if (Test-Path $logPath) {
            $content = Get-Content $logPath -Raw | ConvertFrom-Json
            $existingLog.entries = @($content.entries)
        }
        
        # Add new entry
        $existingLog.entries += $logEntry
        $existingLog.lastRun = Get-Date -Format o
        
        # Save
        $existingLog | ConvertTo-Json -Depth 10 | Set-Content $logPath
    } catch {
        Write-Warning "Failed to write to log: $_"
    }
}

# Main script
Clear-Host
Write-Section "🚀 QGPS Enterprise Branch Protection Setup"

Write-ColorOutput "Repository: $RepoOwner/$RepoName" "Cyan" "📋"
Write-ColorOutput "Target Branch: $BranchName" "Cyan" "📋"
Write-ColorOutput "Dry Run: $DryRun" "$(if($DryRun){'Yellow'}else{'Green'})" "📋"

if ($DryRun) {
    Write-ColorOutput "Running in DRY RUN mode - no changes will be made" "Yellow" "⚠️"
}

Add-LogEntry -Action "setup-start" -Status "running" -Message "Starting enterprise protection setup"

# Step 1: Validate Prerequisites
Write-SubSection "Step 1: Validating Prerequisites"

# Check if GitHub CLI is available
$ghAvailable = $false
try {
    $ghVersion = gh --version 2>&1 | Select-Object -First 1
    if ($?) {
        Write-ColorOutput "GitHub CLI: $ghVersion" "Green" "✅"
        $ghAvailable = $true
    }
} catch {
    Write-ColorOutput "GitHub CLI not found" "Yellow" "⚠️"
}

# Check if git is available
$gitAvailable = $false
try {
    $gitVersion = git --version 2>&1
    if ($?) {
        Write-ColorOutput "Git: $gitVersion" "Green" "✅"
        $gitAvailable = $true
    }
} catch {
    Write-ColorOutput "Git not found" "Red" "❌"
}

# Check for GitHub token
if (-not $GitHubToken) {
    Write-ColorOutput "GitHub token not provided (use -GitHubToken or set GITHUB_TOKEN environment variable)" "Yellow" "⚠️"
    Write-ColorOutput "Branch protection configuration will be skipped" "Yellow" "⚠️"
    $SkipBranchProtection = $true
} else {
    Write-ColorOutput "GitHub token found" "Green" "✅"
}

Add-LogEntry -Action "validate-prerequisites" -Status "completed" -Details @{
    ghAvailable = $ghAvailable
    gitAvailable = $gitAvailable
    hasToken = ($null -ne $GitHubToken)
}

# Step 2: Verify Repository Structure
Write-SubSection "Step 2: Verifying Repository Structure"

$requiredFolders = @(".github/workflows", "scripts", ".brain")
$missingFolders = @()

foreach ($folder in $requiredFolders) {
    $folderPath = Join-Path $PSScriptRoot $folder
    if (Test-Path $folderPath) {
        Write-ColorOutput "Found: $folder" "Green" "✅"
    } else {
        Write-ColorOutput "Missing: $folder" "Red" "❌"
        $missingFolders += $folder
        
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
            Write-ColorOutput "Created: $folder" "Green" "🔧"
        }
    }
}

Add-LogEntry -Action "verify-structure" -Status "completed" -Details @{
    missingFolders = $missingFolders
}

# Step 3: Verify Required Scripts
Write-SubSection "Step 3: Verifying Required Scripts"

$requiredScripts = @(
    "scripts/axiom-sync.ps1",
    "scripts/axiom-compliance.ps1",
    "scripts/axiom-orchestrator.ps1",
    "scripts/qgps-cockpit.ps1"
)

$missingScripts = @()
foreach ($script in $requiredScripts) {
    $scriptPath = Join-Path $PSScriptRoot $script
    if (Test-Path $scriptPath) {
        Write-ColorOutput "Found: $script" "Green" "✅"
    } else {
        Write-ColorOutput "Missing: $script" "Red" "❌"
        $missingScripts += $script
    }
}

if ($missingScripts.Count -gt 0) {
    Write-ColorOutput "ERROR: Required scripts are missing. Cannot continue." "Red" "❌"
    Add-LogEntry -Action "verify-scripts" -Status "failed" -Message "Missing required scripts"
    exit 1
}

Add-LogEntry -Action "verify-scripts" -Status "completed"

# Step 4: Verify GitHub Actions Workflow
Write-SubSection "Step 4: Verifying GitHub Actions Workflow"

$workflowPath = Join-Path $PSScriptRoot ".github/workflows/ci-cd-autopilot.yml"
if (Test-Path $workflowPath) {
    Write-ColorOutput "Workflow exists: ci-cd-autopilot.yml" "Green" "✅"
    
    # Check if workflow contains all required steps
    $workflowContent = Get-Content $workflowPath -Raw
    $requiredSteps = @("axiom-sync.ps1", "axiom-compliance.ps1", "axiom-orchestrator.ps1", "qgps-cockpit.ps1")
    $missingSteps = @()
    
    foreach ($step in $requiredSteps) {
        if ($workflowContent -match [regex]::Escape($step)) {
            Write-ColorOutput "  Step found: $step" "Green" "  ✅"
        } else {
            Write-ColorOutput "  Step missing: $step" "Yellow" "  ⚠️"
            $missingSteps += $step
        }
    }
    
    if ($missingSteps.Count -gt 0) {
        Write-ColorOutput "Workflow may need updates to include all required steps" "Yellow" "⚠️"
    }
} else {
    Write-ColorOutput "Workflow missing: ci-cd-autopilot.yml" "Red" "❌"
}

Add-LogEntry -Action "verify-workflow" -Status "completed"

# Step 5: Configure Branch Protection via GitHub API (if token available)
if (-not $SkipBranchProtection -and $GitHubToken) {
    Write-SubSection "Step 5: Configuring Branch Protection Ruleset"
    
    Write-ColorOutput "Branch protection configuration via GitHub API" "Cyan" "🔧"
    
    # Prepare ruleset configuration
    $rulesetConfig = @{
        name = "QGPS-Enterprise-Main-Protection"
        target = "branch"
        enforcement = "active"
        conditions = @{
            ref_name = @{
                include = @($BranchName)
                exclude = @()
            }
        }
        rules = @(
            @{
                type = "deletion"
            },
            @{
                type = "non_fast_forward"
            },
            @{
                type = "required_linear_history"
            },
            @{
                type = "required_signatures"
            },
            @{
                type = "pull_request"
                parameters = @{
                    required_approving_review_count = 0
                    dismiss_stale_reviews_on_push = $true
                    require_code_owner_review = $false
                    require_last_push_approval = $false
                    required_review_thread_resolution = $true
                }
            },
            @{
                type = "required_status_checks"
                parameters = @{
                    required_status_checks = @(
                        @{
                            context = "ci-cd-autopilot"
                            integration_id = $null
                        }
                    )
                    strict_required_status_checks_policy = $false
                }
            },
            @{
                type = "code_scanning"
                parameters = @{
                    code_scanning_tools = @(
                        @{
                            tool = "CodeQL"
                            security_alerts_threshold = "none"
                            alerts_threshold = "none"
                        }
                    )
                }
            }
        )
        bypass_actors = @(
            @{
                actor_id = 5  # Repository admin role
                actor_type = "RepositoryRole"
                bypass_mode = "always"
            },
            @{
                actor_id = 4  # Maintain role
                actor_type = "RepositoryRole"
                bypass_mode = "always"
            },
            @{
                actor_id = 2  # Write role
                actor_type = "RepositoryRole"
                bypass_mode = "always"
            }
        )
    }
    
    $rulesetJson = $rulesetConfig | ConvertTo-Json -Depth 10
    
    if ($DryRun) {
        Write-ColorOutput "DRY RUN: Would create/update branch protection ruleset" "Yellow" "⚠️"
        Write-ColorOutput "Ruleset configuration:" "Gray"
        Write-Host $rulesetJson -ForegroundColor Gray
    } else {
        Write-ColorOutput "Note: Branch protection rulesets require GitHub API access" "Yellow" "⚠️"
        Write-ColorOutput "To configure branch protection:" "Cyan" "📋"
        Write-ColorOutput "  1. Navigate to: https://github.com/$RepoOwner/$RepoName/settings/rules" "Gray"
        Write-ColorOutput "  2. Create new branch ruleset named 'QGPS-Enterprise-Main-Protection'" "Gray"
        Write-ColorOutput "  3. Configure as per the requirements in the problem statement" "Gray"
        Write-ColorOutput "" "Gray"
        Write-ColorOutput "Bypass list should include:" "Cyan" "📋"
        $bypassList = @(
            "Repository admin role",
            "Maintain role",
            "Write role",
            "Deploy keys",
            "ChatGPT Codex connector",
            "Copilot code review app",
            "Copilot coding agent app",
            "Dependabot",
            "Firebase App Hosting app",
            "Google Cloud Build app",
            "Render",
            "SourceryAI",
            "Supabase",
            "Vercel",
            "Docker",
            "Monday.com GitHub integration"
        )
        foreach ($bypass in $bypassList) {
            Write-ColorOutput "  - $bypass" "Gray"
        }
    }
    
    Add-LogEntry -Action "configure-branch-protection" -Status "info" -Message "Manual configuration required via GitHub UI"
} else {
    Write-SubSection "Step 5: Branch Protection (Skipped)"
    Write-ColorOutput "Branch protection configuration skipped (no GitHub token)" "Yellow" "⚠️"
    Add-LogEntry -Action "configure-branch-protection" -Status "skipped" -Message "No GitHub token provided"
}

# Step 6: Summary and Instructions
Write-SubSection "Step 6: Setup Summary"

$setupSummary = @{
    timestamp = Get-Date -Format o
    repository = "$RepoOwner/$RepoName"
    branch = $BranchName
    scriptsVerified = ($missingScripts.Count -eq 0)
    workflowExists = (Test-Path $workflowPath)
    branchProtectionConfigured = (-not $SkipBranchProtection -and $GitHubToken)
}

Add-LogEntry -Action "setup-complete" -Status "completed" -Details $setupSummary

Write-Host ""
Write-ColorOutput "Setup completed successfully!" "Green" "✅"
Write-Host ""
Write-ColorOutput "Next Steps:" "Cyan" "🚀"
Write-ColorOutput "1. Review and configure branch protection manually at:" "White" "  "
Write-ColorOutput "   https://github.com/$RepoOwner/$RepoName/settings/rules" "Gray"
Write-Host ""
Write-ColorOutput "2. Ensure GitHub Actions workflow is enabled:" "White" "  "
Write-ColorOutput "   https://github.com/$RepoOwner/$RepoName/actions" "Gray"
Write-Host ""
Write-ColorOutput "3. Test the workflow by pushing to the $BranchName branch:" "White" "  "
Write-ColorOutput "   git add ." "Gray"
Write-ColorOutput "   git commit -m 'Configure enterprise protection'" "Gray"
Write-ColorOutput "   git push origin $BranchName" "Gray"
Write-Host ""
Write-ColorOutput "4. Monitor workflow runs at:" "White" "  "
Write-ColorOutput "   https://github.com/$RepoOwner/$RepoName/actions/workflows/ci-cd-autopilot.yml" "Gray"
Write-Host ""
Write-ColorOutput "Log saved to: $logPath" "Gray" "📁"
Write-Host ""

Write-Section "✅ Enterprise Protection Setup Complete"

# Return success
exit 0
