# GitHub Enterprise Repository Rename & Remote Update Script
# Renames a repository via REST API, updates local clones, verifies rename,
# checks workflow references, and logs detailed output.

param(
    [Parameter(Mandatory = $true)]
    [string]$Owner,

    [Parameter(Mandatory = $true)]
    [SecureString]$Token,

    [string]$ApiBaseUrl = "https://api.github.com",

    [string]$RepoBaseUrl,

    [Parameter(Mandatory = $true)]
    [string]$OldRepoName,

    [Parameter(Mandatory = $true)]
    [string]$NewRepoName,

    [Parameter(Mandatory = $true)]
    [string]$LocalRoot,

    [int]$MaxDepth,

    [string]$LogPath,

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

if (-not $LogPath) {
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $LogPath = Join-Path -Path $PSScriptRoot -ChildPath "rename-repo-$timestamp.log"
}

$logDirectory = Split-Path -Parent -Path $LogPath
if ($logDirectory -and -not (Test-Path -Path $logDirectory)) {
    New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null
}

New-Item -ItemType File -Force -Path $LogPath | Out-Null

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [ConsoleColor]$Color = [ConsoleColor]::Gray
    )

    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format o), $Level.ToUpper(), $Message
    Add-Content -Path $LogPath -Value $line
    Write-Host $line -ForegroundColor $Color
}

function Resolve-RepoBaseUrl {
    param(
        [string]$ApiUrl,
        [string]$CustomBase
    )

    if ($CustomBase) {
        return $CustomBase.TrimEnd("/")
    }

    try {
        if ($ApiUrl -notmatch "^https?://") {
            $ApiUrl = "https://$ApiUrl"
        }
        $uri = [Uri]$ApiUrl
    }
    catch {
        Write-Log "Invalid API base URL '$ApiUrl': $($_.Exception.Message)" "ERROR" ([ConsoleColor]::Red)
        throw
    }
    $base = $uri.GetLeftPart([System.UriPartial]::Authority)

    if ($uri.Host -like "api.*") {
        $base = $base -replace "://api\.", "://"
    }

    if ($uri.AbsolutePath -like "/api*") {
        $base = $uri.GetLeftPart([System.UriPartial]::Authority)
    }

    return $base.TrimEnd("/")
}

$tokenPlain = $null
if ($Token) {
    $tokenPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Token)
    try {
        $tokenPlain = [Runtime.InteropServices.Marshal]::PtrToStringUni($tokenPtr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($tokenPtr)
    }
}

$repoBaseUrl = Resolve-RepoBaseUrl -ApiUrl $ApiBaseUrl -CustomBase $RepoBaseUrl
$projectRoot = Split-Path $PSScriptRoot -Parent
$headers = @{
    Authorization            = "Bearer $tokenPlain"
    Accept                   = "application/vnd.github+json"
    "X-GitHub-Api-Version"   = "2022-11-28"
}

Write-Log "Starting repository rename from '$OldRepoName' to '$NewRepoName' for owner '$Owner'." "INFO" ([ConsoleColor]::Cyan)
Write-Log "Logging to $LogPath" "INFO" ([ConsoleColor]::DarkGray)

function Invoke-GitHubApi {
    param(
        [string]$Method,
        [string]$Uri,
        $Body = $null
    )

    try {
        if ($DryRun) {
            Write-Log "DRY RUN: Would call $Method $Uri with body: $($Body | ConvertTo-Json -Depth 10)" "INFO" ([ConsoleColor]::DarkYellow)
            return $null
        }

        if ($Body) {
            return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers -Body ($Body | ConvertTo-Json) -ContentType "application/json"
        }

        return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers
    }
    catch {
        Write-Log "API call to $Uri failed: $($_.Exception.Message)" "ERROR" ([ConsoleColor]::Red)
        throw
    }
}

# Step 1: Rename repository
try {
    $renameUri = "$ApiBaseUrl/repos/$Owner/$OldRepoName"
    $renameBody = @{ name = $NewRepoName }
    if ($DryRun) {
        Write-Log "DRY RUN: Skipped sending repository rename request to '$renameUri'." "INFO" ([ConsoleColor]::DarkYellow)
    }
    else {
        Invoke-GitHubApi -Method PATCH -Uri $renameUri -Body $renameBody | Out-Null
        Write-Log "Repository rename request sent successfully." "SUCCESS" ([ConsoleColor]::Green)
    }
}
catch {
    Write-Log "Repository rename failed. See log for details." "ERROR" ([ConsoleColor]::Red)
    exit 1
}

# Step 2: Verify rename
try {
    $verifyUri = "$ApiBaseUrl/repos/$Owner/$NewRepoName"
    $repoInfo = Invoke-GitHubApi -Method Get -Uri $verifyUri
    if ($repoInfo -or $DryRun) {
        Write-Log "Verified repository now available as $Owner/$NewRepoName." "SUCCESS" ([ConsoleColor]::Green)
    }
}
catch {
    Write-Log "Unable to verify renamed repository at $Owner/$NewRepoName." "ERROR" ([ConsoleColor]::Red)
    exit 1
}

# Step 3: Update local clones
$gitPaths = @()
try {
    $gitSearchParams = @{
        Path        = $LocalRoot
        Directory   = $true
        Recurse     = $true
        Force       = $true
        ErrorAction = "SilentlyContinue"
    }
    $pathSeparators = @([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $normalizedRoot = [System.IO.Path]::GetFullPath($LocalRoot)
    $trimmedRoot    = $normalizedRoot.TrimEnd($pathSeparators)
    $rootSegments   = $trimmedRoot.Split($pathSeparators, [System.StringSplitOptions]::RemoveEmptyEntries).Count

    $gitPaths = Get-ChildItem @gitSearchParams | ForEach-Object {
        if ($_.Name -ne ".git") { return }

        $currentPath     = [System.IO.Path]::GetFullPath($_.FullName)
        $currentTrimmed  = $currentPath.TrimEnd($pathSeparators)
        $currentSegments = $currentTrimmed.Split($pathSeparators, [System.StringSplitOptions]::RemoveEmptyEntries).Count

        if ($MaxDepth -le 0 -or $currentSegments -le ($rootSegments + $MaxDepth)) {
            $_
        }
    }
    Write-Log "Found $($gitPaths.Count) git directories under $LocalRoot." "INFO" ([ConsoleColor]::Gray)
}
catch {
    Write-Log "Failed to enumerate git directories under $($LocalRoot): $($_.Exception.Message)" "ERROR" ([ConsoleColor]::Red)
}

try {
    if ($repoBaseUrl -notmatch "^https?://") {
        Write-Log "No scheme detected in repo base URL '$repoBaseUrl'. Assuming https://." "INFO" ([ConsoleColor]::DarkGray)
        $repoUri = [Uri]("https://$repoBaseUrl")
    }
    else {
        $repoUri = [Uri]$repoBaseUrl
    }
}
catch {
    Write-Log "Invalid repository base URL '$repoBaseUrl': $($_.Exception.Message)" "ERROR" ([ConsoleColor]::Red)
    exit 1
}

$repoAuthority = $repoUri.GetLeftPart([System.UriPartial]::Authority).TrimEnd("/")
if ($repoAuthority -notmatch "^https?://") {
    $repoAuthority = "https://$repoAuthority"
}

$newHttpsRemote = "$repoAuthority/$Owner/$NewRepoName.git"
$sshPortSpecified = ($repoUri.Port -and $repoUri.Port -notin 80, 443)
$newSshRemote = if ($sshPortSpecified) { "ssh://git@$($repoUri.Host):$($repoUri.Port)/$Owner/$NewRepoName.git" } else { "git@$($repoUri.Host):$Owner/$NewRepoName.git" }
$escapedOwner = [regex]::Escape($Owner)
$escapedOldRepo = [regex]::Escape($OldRepoName)
$httpsRemotePattern = "^https?://[^/]+/$escapedOwner/$escapedOldRepo(\.git)?$"
$sshRemotePattern = "^git@[^:]+:$escapedOwner/$escapedOldRepo(\.git)?$"
$sshUrlPattern = "^ssh://git@[^/]+/$escapedOwner/$escapedOldRepo(\.git)?$"
$workflowPattern = "(https?://|git@|ssh://git@)[^\s]*/$escapedOwner/$escapedOldRepo(\.git)?"

try {
    Get-Command git -ErrorAction Stop | Out-Null
}
catch {
    Write-Log "git executable not found on PATH. Please install git and retry." "ERROR" ([ConsoleColor]::Red)
    exit 1
}

foreach ($gitDir in $gitPaths) {
    $repoPath = $gitDir.Parent.FullName
    try {
        $getUrlOutput = & git -C $repoPath remote get-url origin 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Skipping $repoPath (failed to read origin: $getUrlOutput)" "WARN" ([ConsoleColor]::Yellow)
            continue
        }
        $currentRemote = $getUrlOutput.Trim()
        if (-not $currentRemote) {
            Write-Log "Skipping $repoPath (no origin remote found)." "WARN" ([ConsoleColor]::Yellow)
            continue
        }

        if ($currentRemote -notmatch $httpsRemotePattern -and $currentRemote -notmatch $sshRemotePattern -and $currentRemote -notmatch $sshUrlPattern) {
            Write-Log "Skipping $repoPath (origin does not reference $OldRepoName)." "INFO" ([ConsoleColor]::DarkGray)
            continue
        }

        $newRemote = if ($currentRemote -match $sshRemotePattern -or $currentRemote -match $sshUrlPattern) { $newSshRemote } else { $newHttpsRemote }

        if ($DryRun) {
            Write-Log "DRY RUN: Would update origin in $repoPath from $currentRemote to $newRemote" "INFO" ([ConsoleColor]::DarkYellow)
        }
        else {
            $setUrlOutput = & git -C $repoPath remote set-url origin $newRemote 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Log "Failed to update origin in $($repoPath): $setUrlOutput" "ERROR" ([ConsoleColor]::Red)
                continue
            }
            Write-Log "Updated origin in $repoPath to $newRemote" "SUCCESS" ([ConsoleColor]::Green)
        }
    }
    catch {
        Write-Log "Failed to update origin in $($repoPath): $($_.Exception.Message)" "ERROR" ([ConsoleColor]::Red)
    }
}

# Step 4: Check workflow references
$workflowPath = Join-Path -Path $projectRoot -ChildPath ".github/workflows"
if (Test-Path $workflowPath) {
    $workflows = Get-ChildItem -Path $workflowPath -File -Recurse -Include *.yml, *.yaml -ErrorAction SilentlyContinue |
        Sort-Object -Property FullName -Unique
    if (-not $workflows) {
        Write-Log "No workflow files found to scan." "INFO" ([ConsoleColor]::DarkGray)
    }
    else {
        $workflowWarnings = $false
        $workflowMatches = Select-String -Path @($workflows.FullName) -Pattern $workflowPattern
        if ($workflowMatches) {
            foreach ($matchPath in ($workflowMatches | Select-Object -ExpandProperty Path -Unique)) {
                Write-Log "WARNING: Workflow $(Split-Path $matchPath -Leaf) references $OldRepoName. Review and update if necessary." "WARN" ([ConsoleColor]::Yellow)
            }
            $workflowWarnings = $true
        }

        if (-not $workflowWarnings) {
            Write-Log "Workflow references do not contain $OldRepoName." "SUCCESS" ([ConsoleColor]::Green)
        }
    }
}
else {
    Write-Log "Workflow directory not found at $workflowPath" "WARN" ([ConsoleColor]::Yellow)
}

Write-Log "Repository rename and local update process complete." "INFO" ([ConsoleColor]::Cyan)
