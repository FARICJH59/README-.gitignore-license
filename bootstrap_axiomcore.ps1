param(
    [switch]$PlanOnly
)

$ErrorActionPreference = 'Stop'

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format o
    Write-Host "[$timestamp] $Message"
}

Write-Log "Bootstrap starting (PlanOnly=$PlanOnly)"

$deployArgs = @()
if ($PlanOnly) { $deployArgs += '-PlanOnly' }

& (Join-Path $PSScriptRoot 'deploy_axiomcore_prod.ps1') @deployArgs
& (Join-Path $PSScriptRoot 'axiocore_hyperscale_drift_suite.ps1')

Write-Log "Bootstrap complete"
