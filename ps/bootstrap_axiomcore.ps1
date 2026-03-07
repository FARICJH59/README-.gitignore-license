Write-Host "Bootstrapping AxiomCore..."

$root = Split-Path -Parent $PSScriptRoot
$deployScript = Join-Path $PSScriptRoot "deploy_axiomcore_prod.ps1"
$driftScript = Join-Path $PSScriptRoot "axiocore_hyperscale_drift_suite.ps1"

Write-Host "Validating script locations..."
@($deployScript, $driftScript) | ForEach-Object {
    if (-not (Test-Path $_)) {
        Write-Warning "Expected script missing: $_"
    }
}

Write-Host "Running initial deploy in PlanOnly mode..."
& $deployScript -PlanOnly

Write-Host "Running initial drift suite..."
& $driftScript

Write-Host "Bootstrap completed."
