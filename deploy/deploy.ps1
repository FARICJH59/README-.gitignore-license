$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-Stage {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Get-ChangedArea {
    $status = git status --porcelain
    return @{
        Backend  = ($status | Select-String "backend" | ForEach-Object { $_ }).Count -gt 0
        Frontend = ($status | Select-String "frontend" | ForEach-Object { $_ }).Count -gt 0
        Infra    = ($status | Select-String "wrangler.toml" | ForEach-Object { $_ }).Count -gt 0
    }
}

function Ensure-Prereqs {
    Write-Stage "Installing dependencies"
    npm install
    Push-Location frontend
    npm install
    Pop-Location
}

function Patch-CloudflareResources {
    param($envFile = ".dev.vars")
    Write-Stage "Patching KV, Vectorize index, and Durable Objects"
    if (Test-Path $envFile) {
        Write-Host "Loading $envFile for secrets and bindings..."
    }
    wrangler kv namespace create KV_STATE -q | Out-Null
    wrangler r2 bucket create axiomcore-content -q | Out-Null
    wrangler vectorize create axiomcore-index -q | Out-Null
    wrangler deploy backend/workers/mainWorker.ts --dry-run | Out-Null
}

function Build-Frontend {
    Write-Stage "Building frontend"
    Push-Location frontend
    npm run build
    Pop-Location
}

function Deploy-WorkerAndPages {
    param([switch]$RetryOnFail)
    Write-Stage "Deploying Worker + Pages"
    $attempt = 0
    do {
        try {
            wrangler deploy backend/workers/mainWorker.ts --minify
            wrangler pages deploy frontend/dist --project-name axiomcore-ai-playground
            return
        } catch {
            $attempt++
            Write-Warning "Deploy failed (attempt $attempt): $_"
            if (-not $RetryOnFail -or $attempt -ge 3) { throw }
            Start-Sleep -Seconds 10
        }
    } while ($true)
}

function Notify {
    param([string]$Message)
    Write-Stage "Sending alerts"
    Write-Host "Slack/Email would receive: $Message"
}

function Save-State {
    param($Data)
    $statePath = "deploy/deploy_state.json"
    $Data | ConvertTo-Json -Depth 6 | Out-File $statePath -Encoding utf8
    Write-Host "Persisted state to $statePath"
}

Write-Stage "Predictive deploy start"
$changes = Get-ChangedArea
Ensure-Prereqs
Patch-CloudflareResources

if ($changes.Frontend) { Build-Frontend }
if ($changes.Backend -or $changes.Infra) { wrangler deploy backend/workers/mainWorker.ts --dry-run | Out-Null }

Deploy-WorkerAndPages -RetryOnFail
Save-State @{
    timestamp = (Get-Date).ToString("o")
    changes   = $changes
}
Notify "AxiomCore + Cloudflare AI Playground deployed successfully."
