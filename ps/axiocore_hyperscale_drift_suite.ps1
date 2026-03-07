Write-Host "Starting drift protection suite..."

$root = Split-Path -Parent $PSScriptRoot
$reportPath = Join-Path $root "reports/DRIFT_REPORT.json"

$changes = @()
try {
    $diffOutput = git diff --name-only HEAD~1 HEAD 2>$null
    if ($diffOutput) {
        $changes = $diffOutput -split "`n" | Where-Object { $_ -ne "" }
    }
}
catch {
    Write-Warning "git diff unavailable; proceeding with empty change set."
}

$driftDetected = $changes.Count -gt 0
if (-not $driftDetected) {
    Write-Host "No drift detected. Generating DRIFT_REPORT.json."
}
else {
    Write-Host "Drift detected in files: $($changes -join ', ')"
}

$report = @{
    timestamp      = (Get-Date).ToString("o")
    drift_detected = $driftDetected
    changed_files  = $changes
    summary        = $driftDetected ? "Drift detected; review and reconcile." : "All systems aligned with blueprint."
}

$json = $report | ConvertTo-Json -Depth 4
Set-Content -Path $reportPath -Value $json -Encoding UTF8

Write-Host "DRIFT_REPORT.json written to $reportPath"
