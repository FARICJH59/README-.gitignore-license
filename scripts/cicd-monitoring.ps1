#!/usr/bin/env pwsh
# CI/CD Deployment Tracking and Monitoring
# Monitors workflow runs, tracks deployments, and reports status

param(
    [Parameter(Mandatory=$false)]
    [string]$RepoOwner = "FARICJH59",
    
    [Parameter(Mandatory=$false)]
    [string]$RepoName = "README-.gitignore-license",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('list', 'status', 'logs', 'trigger')]
    [string]$Action = "status",
    
    [Parameter(Mandatory=$false)]
    [string]$WorkflowId,
    
    [Parameter(Mandatory=$false)]
    [string]$RunId,
    
    [Parameter(Mandatory=$false)]
    [switch]$Watch
)

$ErrorActionPreference = "Stop"

# Deployment tracking database
$trackingDir = Join-Path $PSScriptRoot ".." ".brain"
$deploymentTrackingFile = Join-Path $trackingDir "deployment-tracking.json"

if (-not (Test-Path $trackingDir)) {
    New-Item -ItemType Directory -Path $trackingDir -Force | Out-Null
}

# Initialize tracking database
if (-not (Test-Path $deploymentTrackingFile)) {
    $initialData = @{
        lastUpdated = Get-Date -Format "o"
        deployments = @()
        statistics = @{
            total = 0
            successful = 0
            failed = 0
            inProgress = 0
        }
    }
    $initialData | ConvertTo-Json -Depth 10 | Set-Content -Path $deploymentTrackingFile -Force
}

function Get-WorkflowRuns {
    param($Owner, $Repo)
    
    Write-Host "Fetching workflow runs from GitHub..." -ForegroundColor Cyan
    
    try {
        # Use gh CLI to get workflow runs
        $runsJson = gh api "/repos/$Owner/$Repo/actions/runs" --jq '.workflow_runs[] | {id: .id, name: .name, status: .status, conclusion: .conclusion, created_at: .created_at, updated_at: .updated_at, head_branch: .head_branch, event: .event}'
        
        if ($runsJson) {
            $runs = $runsJson | ConvertFrom-Json
            return $runs
        }
    } catch {
        Write-Host "⚠️  Could not fetch workflow runs: $($_.Exception.Message)" -ForegroundColor Yellow
        return @()
    }
    
    return @()
}

function Get-WorkflowStatus {
    param($Owner, $Repo, $RunId)
    
    try {
        $runJson = gh api "/repos/$Owner/$Repo/actions/runs/$RunId"
        $run = $runJson | ConvertFrom-Json
        
        $statusObj = @{
            id = $run.id
            name = $run.name
            status = $run.status
            conclusion = $run.conclusion
            createdAt = $run.created_at
            updatedAt = $run.updated_at
            branch = $run.head_branch
            event = $run.event
            url = $run.html_url
            jobs = @()
        }
        
        # Get jobs for this run
        $jobsJson = gh api "/repos/$Owner/$Repo/actions/runs/$RunId/jobs"
        $jobs = $jobsJson | ConvertFrom-Json
        
        foreach ($job in $jobs.jobs) {
            $statusObj.jobs += @{
                id = $job.id
                name = $job.name
                status = $job.status
                conclusion = $job.conclusion
                startedAt = $job.started_at
                completedAt = $job.completed_at
            }
        }
        
        return $statusObj
    } catch {
        Write-Host "⚠️  Could not fetch workflow status: $($_.Exception.Message)" -ForegroundColor Yellow
        return $null
    }
}

function Get-WorkflowLogs {
    param($Owner, $Repo, $RunId)
    
    Write-Host "Fetching workflow logs..." -ForegroundColor Cyan
    
    try {
        # Download logs
        $logFile = Join-Path $env:TEMP "workflow-logs-$RunId.zip"
        gh api "/repos/$Owner/$Repo/actions/runs/$RunId/logs" > $logFile
        
        Write-Host "✓ Logs downloaded to: $logFile" -ForegroundColor Green
        return $logFile
    } catch {
        Write-Host "⚠️  Could not fetch logs: $($_.Exception.Message)" -ForegroundColor Yellow
        return $null
    }
}

function Start-WorkflowRun {
    param($Owner, $Repo, $WorkflowId, $Branch = "main")
    
    Write-Host "Triggering workflow: $WorkflowId on branch $Branch..." -ForegroundColor Cyan
    
    try {
        gh workflow run $WorkflowId --repo "$Owner/$Repo" --ref $Branch
        Write-Host "✓ Workflow triggered successfully" -ForegroundColor Green
        
        # Wait a moment for the run to appear
        Start-Sleep -Seconds 3
        
        # Get the latest run
        $runs = Get-WorkflowRuns -Owner $Owner -Repo $Repo
        $latestRun = $runs | Where-Object { $_.name -like "*$WorkflowId*" } | Select-Object -First 1
        
        if ($latestRun) {
            Write-Host "Run ID: $($latestRun.id)" -ForegroundColor Yellow
            Write-Host "Status: $($latestRun.status)" -ForegroundColor Yellow
            return $latestRun.id
        }
    } catch {
        Write-Host "❌ Failed to trigger workflow: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Update-DeploymentTracking {
    param($DeploymentData)
    
    $tracking = Get-Content $deploymentTrackingFile | ConvertFrom-Json
    
    # Add new deployment
    $tracking.deployments += $DeploymentData
    $tracking.lastUpdated = Get-Date -Format "o"
    
    # Update statistics
    $tracking.statistics.total = $tracking.deployments.Count
    $tracking.statistics.successful = ($tracking.deployments | Where-Object { $_.conclusion -eq 'success' }).Count
    $tracking.statistics.failed = ($tracking.deployments | Where-Object { $_.conclusion -eq 'failure' }).Count
    $tracking.statistics.inProgress = ($tracking.deployments | Where-Object { $_.status -eq 'in_progress' -or $_.status -eq 'queued' }).Count
    
    $tracking | ConvertTo-Json -Depth 10 | Set-Content -Path $deploymentTrackingFile -Force
}

function Show-DeploymentStatistics {
    $tracking = Get-Content $deploymentTrackingFile | ConvertFrom-Json
    
    Write-Host ""
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host "Deployment Statistics" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host "Total Deployments: $($tracking.statistics.total)" -ForegroundColor White
    Write-Host "Successful: $($tracking.statistics.successful)" -ForegroundColor Green
    Write-Host "Failed: $($tracking.statistics.failed)" -ForegroundColor Red
    Write-Host "In Progress: $($tracking.statistics.inProgress)" -ForegroundColor Yellow
    Write-Host ""
    
    if ($tracking.statistics.total -gt 0) {
        $successRate = [math]::Round(($tracking.statistics.successful / $tracking.statistics.total) * 100, 2)
        Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -gt 90) { 'Green' } elseif ($successRate -gt 70) { 'Yellow' } else { 'Red' })
    }
    
    Write-Host ""
    Write-Host "Recent Deployments:" -ForegroundColor Yellow
    $recentDeployments = $tracking.deployments | Select-Object -Last 5
    foreach ($deployment in $recentDeployments) {
        $statusColor = switch ($deployment.conclusion) {
            'success' { 'Green' }
            'failure' { 'Red' }
            default { 'Yellow' }
        }
        Write-Host "  [$($deployment.createdAt)] $($deployment.name) - $($deployment.conclusion)" -ForegroundColor $statusColor
    }
}

# Main execution
switch ($Action) {
    'list' {
        Write-Host "================================" -ForegroundColor Cyan
        Write-Host "Workflow Runs" -ForegroundColor Cyan
        Write-Host "================================" -ForegroundColor Cyan
        
        $runs = Get-WorkflowRuns -Owner $RepoOwner -Repo $RepoName
        
        if ($runs.Count -eq 0) {
            Write-Host "No workflow runs found" -ForegroundColor Yellow
        } else {
            foreach ($run in $runs) {
                $statusColor = switch ($run.status) {
                    'completed' { if ($run.conclusion -eq 'success') { 'Green' } else { 'Red' } }
                    'in_progress' { 'Yellow' }
                    default { 'Gray' }
                }
                
                Write-Host "[$($run.id)] $($run.name)" -ForegroundColor $statusColor
                Write-Host "  Status: $($run.status) | Conclusion: $($run.conclusion)" -ForegroundColor Gray
                Write-Host "  Branch: $($run.head_branch) | Event: $($run.event)" -ForegroundColor Gray
                Write-Host "  Created: $($run.created_at)" -ForegroundColor Gray
                Write-Host ""
            }
        }
        
        Show-DeploymentStatistics
    }
    
    'status' {
        if ($RunId) {
            Write-Host "Fetching status for run: $RunId" -ForegroundColor Cyan
            $status = Get-WorkflowStatus -Owner $RepoOwner -Repo $RepoName -RunId $RunId
            
            if ($status) {
                Write-Host ""
                Write-Host "Workflow: $($status.name)" -ForegroundColor Cyan
                Write-Host "Status: $($status.status)" -ForegroundColor $(if ($status.status -eq 'completed') { 'Green' } else { 'Yellow' })
                Write-Host "Conclusion: $($status.conclusion)" -ForegroundColor $(if ($status.conclusion -eq 'success') { 'Green' } else { 'Red' })
                Write-Host "Branch: $($status.branch)" -ForegroundColor White
                Write-Host "URL: $($status.url)" -ForegroundColor Cyan
                Write-Host ""
                Write-Host "Jobs:" -ForegroundColor Yellow
                foreach ($job in $status.jobs) {
                    $jobStatus = if ($job.conclusion -eq 'success') { '✓' } elseif ($job.conclusion -eq 'failure') { '✗' } else { '⋯' }
                    Write-Host "  $jobStatus $($job.name) - $($job.status)" -ForegroundColor $(if ($job.conclusion -eq 'success') { 'Green' } else { 'Yellow' })
                }
                
                # Update tracking
                Update-DeploymentTracking -DeploymentData $status
            }
        } else {
            Show-DeploymentStatistics
        }
        
        if ($Watch) {
            Write-Host ""
            Write-Host "Watching for updates (Ctrl+C to stop)..." -ForegroundColor Yellow
            while ($true) {
                Start-Sleep -Seconds 30
                $status = Get-WorkflowStatus -Owner $RepoOwner -Repo $RepoName -RunId $RunId
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Status: $($status.status) | Conclusion: $($status.conclusion)" -ForegroundColor Cyan
                
                if ($status.status -eq 'completed') {
                    Write-Host "Workflow completed!" -ForegroundColor Green
                    break
                }
            }
        }
    }
    
    'logs' {
        if (-not $RunId) {
            Write-Host "❌ RunId is required for logs action" -ForegroundColor Red
            exit 1
        }
        
        Get-WorkflowLogs -Owner $RepoOwner -Repo $RepoName -RunId $RunId
    }
    
    'trigger' {
        if (-not $WorkflowId) {
            Write-Host "❌ WorkflowId is required for trigger action" -ForegroundColor Red
            exit 1
        }
        
        $runId = Start-WorkflowRun -Owner $RepoOwner -Repo $RepoName -WorkflowId $WorkflowId
        
        if ($runId -and $Watch) {
            Start-Sleep -Seconds 5
            & $MyInvocation.MyCommand.Path -Action status -RunId $runId -Watch
        }
    }
}
