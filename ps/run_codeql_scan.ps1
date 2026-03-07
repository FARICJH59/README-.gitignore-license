Write-Host "Starting CodeQL scan placeholder..."

$root = Split-Path -Parent $PSScriptRoot
$sarifPath = Join-Path $root "codeql-results/placeholder.sarif"

$changes = @()
try {
    $diffOutput = git diff --name-only HEAD~1 HEAD 2>$null
    if ($diffOutput) {
        $changes = $diffOutput -split "`n" | Where-Object { $_ -ne "" }
    }
}
catch {
    Write-Warning "git diff unavailable; proceeding with placeholder scan."
}

if ($changes.Count -eq 0) {
    Write-Host "No changed files detected; running full placeholder scan."
}
else {
    Write-Host "Scanning changed files: $($changes -join ', ')"
}

$sarif = @{
    version = "2.1.0"
    runs    = @(
        @{
            tool    = @{
                driver = @{
                    name           = "CodeQL-Placeholder"
                    semanticVersion = "0.0.0"
                }
            }
            artifacts = $changes
            results = @()
        }
    )
}

$json = $sarif | ConvertTo-Json -Depth 6
Set-Content -Path $sarifPath -Value $json -Encoding UTF8

Write-Host "SARIF placeholder written to $sarifPath"
