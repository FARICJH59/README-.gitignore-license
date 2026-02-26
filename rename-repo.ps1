# Fail fast on any errors in the rename workflow.
$ErrorActionPreference = "Stop"

param(
    # Defaults are specific to this repository; change these when renaming other repositories.
    [string]$Owner = "FARIJCH59",
    [string]$Repo = "README-.gitignore-license",
    [string]$NewRepoName = "Axiomcore-SYSTEM",
    [string]$Token
)

if (-not $Token) {
    $Token = $env:GITHUB_TOKEN
}

if (-not $Token) {
    throw "A GitHub token is required. Provide it with -Token or set the GITHUB_TOKEN environment variable."
}

$uri = "https://api.github.com/repos/$Owner/$Repo"
$headers = @{
    "Authorization"        = "Bearer $Token"
    "Accept"               = "application/vnd.github+json"
    # Pinned to the stable REST API version used across our scripts.
    "X-GitHub-Api-Version" = "2022-11-28"
}

Write-Host "Renaming repository '$Owner/$Repo' to '$NewRepoName'..." -ForegroundColor Cyan

$body = @{ name = $NewRepoName } | ConvertTo-Json
try {
    $response = Invoke-RestMethod -Method Patch -Uri $uri -Headers $headers -Body $body -ContentType "application/json"
} catch {
    $statusCode = $null
    $reason = $null
    $responseBody = $null

    if ($_.Exception.Response) {
        $statusCode = try { [int]$_.Exception.Response.StatusCode } catch { $null }
        $reason = try { $_.Exception.Response.ReasonPhrase } catch { $null }
    }

    if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
        $responseBody = $_.ErrorDetails.Message
    }

    $details = @()
    if ($statusCode) { $details += "StatusCode=$statusCode" }
    if ($reason) { $details += "Reason='$reason'" }
    if ($responseBody) { $details += "Response=$responseBody" }
    $detailText = if ($details.Count -gt 0) { " (" + ($details -join "; ") + ")" } else { "" }

    throw "Failed to rename repository$detailText: $($_.Exception.Message)"
}
Write-Host "✅ Repository renamed successfully." -ForegroundColor Green
Write-Host "🔗 New repository URL: $($response.html_url)" -ForegroundColor Yellow
