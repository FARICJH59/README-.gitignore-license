<#
.SYNOPSIS
Renames a GitHub repository and optionally updates local clones.

.EXAMPLE
./scripts/rename-github-repo.ps1 `
  -Owner FARICJH59 `
  -Token (ConvertTo-SecureString 'YOUR_PAT' -AsPlainText -Force) `
  -OldRepoName README-.gitignore-license `
  -NewRepoName Axiomcore-SYSTEM `
  -LocalRoot C:\Users\User\Projects `
  -MaxDepth 3 `
  -DryRun
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Owner,

    [Parameter(Mandatory = $true)]
    [SecureString]$Token,

    [Parameter(Mandatory = $true)]
    [string]$OldRepoName,

    [Parameter(Mandatory = $true)]
    [string]$NewRepoName,

    [Parameter()]
    [string]$LocalRoot = (Get-Location).Path,

    [Parameter()]
    [int]$MaxDepth = 3,

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message, [ConsoleColor]$Color = [ConsoleColor]::Cyan)
    Write-Host $Message -ForegroundColor $Color
}

function Convert-TokenToPlainText {
    param([SecureString]$SecureToken)
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureToken)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    } finally {
        if ($ptr -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
        }
    }
}

if ($OldRepoName -eq $NewRepoName) {
    Write-Step "Old and new repository names are identical. Nothing to do." ([ConsoleColor]::Yellow)
    return
}

$plainToken = Convert-TokenToPlainText -SecureToken $Token
$remoteUri = "https://api.github.com/repos/$Owner/$OldRepoName"
$headers = @{
    Authorization = "Bearer $plainToken"
    "User-Agent"  = "repo-rename-script"
    Accept        = "application/vnd.github+json"
}

Write-Step "Preparing to rename GitHub repository '$Owner/$OldRepoName' to '$NewRepoName'..."
if ($DryRun) {
    Write-Step "DRY RUN: Skipping GitHub API call. No remote changes will be made." ([ConsoleColor]::Yellow)
} else {
    $body = @{ name = $NewRepoName } | ConvertTo-Json
    Write-Step "Calling GitHub API to rename repository..."
    try {
        $response = Invoke-RestMethod -Method Patch -Uri $remoteUri -Headers $headers -Body $body
        Write-Step "✅ Repository renamed remotely to '$($response.name)'." ([ConsoleColor]::Green)
    } catch {
        Write-Step "❌ Failed to rename repository: $($_.Exception.Message)" ([ConsoleColor]::Red)
        throw
    }
}

if (-not (Test-Path $LocalRoot)) {
    Write-Step "Local root '$LocalRoot' not found. Skipping local updates." ([ConsoleColor]::Yellow)
    return
}

$resolvedRoot = (Resolve-Path $LocalRoot).Path
Write-Step "Scanning '$resolvedRoot' for local clones named '$OldRepoName' (max depth: $MaxDepth)..."

$targets = New-Object System.Collections.Generic.List[System.IO.DirectoryInfo]
$rootItem = Get-Item $resolvedRoot
if ($rootItem.PSIsContainer -and $rootItem.Name -eq $OldRepoName) {
    $targets.Add($rootItem)
}

$gciParams = @{
    Path      = $resolvedRoot
    Directory = $true
    Recurse   = $true
}

$useDepthParam = (Get-Command Get-ChildItem).Parameters.ContainsKey("Depth")
if ($useDepthParam) {
    $gciParams["Depth"] = $MaxDepth
}

$directories = Get-ChildItem @gciParams

if ($useDepthParam) {
    $directories | Where-Object { $_.Name -eq $OldRepoName } | ForEach-Object { $targets.Add($_) }
} else {
    $directories | ForEach-Object {
        $relative = $_.FullName.Substring($resolvedRoot.Length).TrimStart('\','/')
        $depth = if ($relative) { ($relative -split '[\\/]').Length } else { 0 }
        if ($depth -le $MaxDepth -and $_.Name -eq $OldRepoName) {
            $targets.Add($_)
        }
    }
}

if ($targets.Count -eq 0) {
    Write-Step "No matching local directories found." ([ConsoleColor]::Yellow)
    return
}

foreach ($dir in $targets) {
    $newPath = Join-Path (Split-Path $dir.FullName -Parent) $NewRepoName

    if (Test-Path $newPath) {
        Write-Step "⚠️  Target already exists: $newPath. Skipping '$($dir.FullName)'." ([ConsoleColor]::Yellow)
        continue
    }

    if ($DryRun) {
        Write-Step "DRY RUN: Would rename '$($dir.FullName)' to '$newPath'." 
    } else {
        Move-Item -LiteralPath $dir.FullName -Destination $newPath
        Write-Step "✅ Renamed local directory to '$newPath'." ([ConsoleColor]::Green)
    }

    $gitBasePath = if ($DryRun) { $dir.FullName } else { $newPath }
    $gitPath = Join-Path $gitBasePath ".git"
    if (Test-Path $gitPath) {
        $newRemoteUrl = "https://github.com/$Owner/$NewRepoName.git"
        if (Get-Command git -ErrorAction SilentlyContinue) {
            $currentRemote = git -C $gitBasePath remote get-url origin 2>&1
            if ($LASTEXITCODE -eq 0) {
                $currentRemote = $currentRemote.Trim()
                if ($currentRemote -match "^git@github.com:") {
                    $newRemoteUrl = "git@github.com:$Owner/$NewRepoName.git"
                } elseif ($currentRemote -match "^ssh://git@github.com/") {
                    $newRemoteUrl = "ssh://git@github.com/$Owner/$NewRepoName.git"
                }
            }

            if ($DryRun) {
                Write-Step "DRY RUN: Would update git remote origin to $newRemoteUrl." 
            } else {
                try {
                    $gitOutput = git -C $gitBasePath remote set-url origin $newRemoteUrl 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        Write-Step "⚠️  Failed to update git remote: $gitOutput" ([ConsoleColor]::Yellow)
                    } else {
                        Write-Step "🔗 Updated git remote origin." ([ConsoleColor]::Green)
                    }
                } catch {
                    Write-Step "⚠️  Failed to update git remote: $($_.Exception.Message)" ([ConsoleColor]::Yellow)
                }
            }
        } else {
            Write-Step "⚠️  git not found; skipped remote update for '$gitBasePath'." ([ConsoleColor]::Yellow)
        }
    }
}
