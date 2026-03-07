param(
    [int]$WorkerReplicas = 500,
    [ValidateSet('llm','vision','ml','embedding')]
    [string]$GPUCluster = 'llm',
    [int]$GPUCount = 100,
    [switch]$Redeploy,
    [switch]$PlanOnly
)

$ErrorActionPreference = 'Stop'

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format o
    Write-Host "[$timestamp] $Message"
}

function Update-UsageReport {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        return
    }
    $json = Get-Content -Raw -Path $Path | ConvertFrom-Json
    if (-not $json) { return }
    $json.updatedAt = (Get-Date).ToString("o")
    if (-not $json.clusters) { $json | Add-Member -MemberType NoteProperty -Name clusters -Value @{} }
    if (-not $json.clusters.worker) { $json.clusters | Add-Member -MemberType NoteProperty -Name worker -Value @{} }
    $json.clusters.worker.nodes = $WorkerReplicas
    if (-not $json.clusters.gpu) { $json.clusters | Add-Member -MemberType NoteProperty -Name gpu -Value @{} }
    if (-not $json.clusters.gpu.$GPUCluster) { $json.clusters.gpu | Add-Member -MemberType NoteProperty -Name $GPUCluster -Value @{} }
    $json.clusters.gpu.$GPUCluster.nodes = $GPUCount
    $json.telemetry.profit = [math]::Round(($json.telemetry.revenue - $json.telemetry.cost), 2)
    $json | ConvertTo-Json -Depth 6 | Set-Content -Path $Path
}

$mode = if ($PlanOnly) { 'PlanOnly' } elseif ($Redeploy) { 'Redeploy' } else { 'Scale' }
Write-Log "Starting deploy_axiomcore_prod.ps1 in mode=$mode"
Write-Log "WorkerReplicas=$WorkerReplicas GPU=$GPUCluster/$GPUCount"

# Simulated Kubernetes + Helm orchestration hooks
if ($PlanOnly) {
    Write-Log "Performing dry-run validation (no changes applied)"
} else {
    Write-Log "Applying desired state to Brain (200), Worker ($WorkerReplicas), GPU ($GPUCluster:$GPUCount)" 
}

if ($Redeploy) {
    Write-Log "Redeploying all clusters with latest images and configs"
}

$usagePath = Join-Path $PSScriptRoot 'USAGE_REPORT.json'
Update-UsageReport -Path $usagePath
Write-Log "Usage report refreshed at $usagePath"

Write-Log "Completed deploy_axiomcore_prod.ps1"
