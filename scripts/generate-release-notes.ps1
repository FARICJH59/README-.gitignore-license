#!/usr/bin/env pwsh
# Automated Release Notes Generator
# Generates release notes from git commits and deployment history

param(
    [Parameter(Mandatory=$false)]
    [string]$FromTag,
    
    [Parameter(Mandatory=$false)]
    [string]$ToTag = "HEAD",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('markdown', 'json', 'html')]
    [string]$Format = "markdown",
    
    [Parameter(Mandatory=$false)]
    [switch]$AutoPublish
)

$ErrorActionPreference = "Stop"

$releaseNotesDir = Join-Path $PSScriptRoot ".." "docs" "releases"
if (-not (Test-Path $releaseNotesDir)) {
    New-Item -ItemType Directory -Path $releaseNotesDir -Force | Out-Null
}

# Get version from git tags or commits
function Get-VersionInfo {
    param($FromTag, $ToTag)
    
    if (-not $FromTag) {
        # Get the latest tag
        $latestTag = git describe --tags --abbrev=0 2>$null
        if (-not $latestTag) {
            # No tags exist, use first commit
            $FromTag = git rev-list --max-parents=0 HEAD
        } else {
            $FromTag = $latestTag
        }
    }
    
    return @{
        from = $FromTag
        to = $ToTag
        fromDate = git log -1 --format=%ai $FromTag 2>$null
        toDate = git log -1 --format=%ai $ToTag 2>$null
    }
}

# Parse commit messages
function Get-CommitHistory {
    param($FromRef, $ToRef)
    
    Write-Host "Analyzing commit history from $FromRef to $ToRef..." -ForegroundColor Cyan
    
    $commits = @{
        features = @()
        fixes = @()
        breaking = @()
        other = @()
        authors = @()
    }
    
    # Get commit log
    $gitLog = git log "$FromRef..$ToRef" --pretty=format:"%H|%an|%ae|%ai|%s|%b" 2>$null
    
    if ($gitLog) {
        $commitLines = $gitLog -split "`n"
        
        foreach ($line in $commitLines) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            
            $parts = $line -split '\|'
            if ($parts.Count -lt 5) { continue }
            
            $commit = @{
                hash = $parts[0].Substring(0, 7)
                author = $parts[1]
                email = $parts[2]
                date = $parts[3]
                subject = $parts[4]
                body = if ($parts.Count -gt 5) { $parts[5] } else { "" }
            }
            
            # Track authors
            if ($commits.authors -notcontains $commit.author) {
                $commits.authors += $commit.author
            }
            
            # Categorize commit
            $subject = $commit.subject.ToLower()
            
            if ($subject -match '^feat(\(.*?\))?:' -or $subject -match '^feature:') {
                $commits.features += $commit
            }
            elseif ($subject -match '^fix(\(.*?\))?:' -or $subject -match '^bugfix:') {
                $commits.fixes += $commit
            }
            elseif ($subject -match '^breaking(\(.*?\))?:' -or $subject -match 'breaking change') {
                $commits.breaking += $commit
            }
            else {
                $commits.other += $commit
            }
        }
    }
    
    return $commits
}

# Generate release notes in markdown format
function New-MarkdownReleaseNotes {
    param($VersionInfo, $Commits, $Version)
    
    $markdown = @"
# Release Notes - Version $Version

**Release Date:** $(Get-Date -Format "MMMM dd, yyyy")

**Changes from $($VersionInfo.from) to $($VersionInfo.to)**

---

## Summary

This release includes **$($Commits.features.Count)** new features, **$($Commits.fixes.Count)** bug fixes, and **$($Commits.other.Count)** other improvements.

**Contributors:** $($Commits.authors.Count) contributors
$($Commits.authors | ForEach-Object { "- $_" } | Out-String)

---

"@

    if ($Commits.breaking.Count -gt 0) {
        $markdown += @"
## ⚠️ Breaking Changes

"@
        foreach ($commit in $Commits.breaking) {
            $markdown += "- **[$($commit.hash)]** $($commit.subject)`n"
            if ($commit.body) {
                $markdown += "  $($commit.body)`n"
            }
        }
        $markdown += "`n---`n`n"
    }

    if ($Commits.features.Count -gt 0) {
        $markdown += @"
## ✨ New Features

"@
        foreach ($commit in $Commits.features) {
            $cleanSubject = $commit.subject -replace '^feat(\(.*?\))?:\s*', ''
            $markdown += "- **[$($commit.hash)]** $cleanSubject by @$($commit.author)`n"
        }
        $markdown += "`n"
    }

    if ($Commits.fixes.Count -gt 0) {
        $markdown += @"
## 🐛 Bug Fixes

"@
        foreach ($commit in $Commits.fixes) {
            $cleanSubject = $commit.subject -replace '^fix(\(.*?\))?:\s*', ''
            $markdown += "- **[$($commit.hash)]** $cleanSubject by @$($commit.author)`n"
        }
        $markdown += "`n"
    }

    if ($Commits.other.Count -gt 0) {
        $markdown += @"
## 🔧 Other Changes

"@
        foreach ($commit in $Commits.other) {
            $markdown += "- **[$($commit.hash)]** $($commit.subject) by @$($commit.author)`n"
        }
        $markdown += "`n"
    }

    $markdown += @"

---

## Deployment Information

### Kubernetes Manifests
- Updated deployment configurations for multi-environment support
- Enhanced ingress configurations with automatic SSL/TLS
- Improved resource allocation and autoscaling

### Infrastructure
- Added Terraform modules for AWS, GCP, and Azure
- Implemented automated DNS and URL configuration
- Enhanced monitoring with Prometheus and Grafana integration

### Security
- Implemented RBAC with role-based access control
- Added network policies for pod-to-pod communication
- Enhanced secrets management and encryption

### CI/CD
- Improved GitHub Actions workflows with deployment tracking
- Added automated monitoring and alerting
- Implemented auto-redeploy on failures

---

## Installation

### Using kubectl
``````bash
kubectl apply -f infra/kubernetes/namespace.yaml
kubectl apply -f infra/kubernetes/configmap.yaml
kubectl apply -f infra/kubernetes/
``````

### Using Docker Compose
``````bash
docker-compose -f infra/docker-compose.yml up -d
``````

### Using Terraform
``````bash
cd infra/terraform/gcp  # or aws, azure
terraform init
terraform plan
terraform apply
``````

---

## Documentation

For detailed documentation, see:
- [Deployment Guide](../DEPLOYMENT.md)
- [Configuration Guide](../CONFIGURATION.md)
- [Security Guide](../SECURITY.md)

---

**Full Changelog:** https://github.com/FARICJH59/README-.gitignore-license/compare/$($VersionInfo.from)...$($VersionInfo.to)

"@

    return $markdown
}

# Generate release notes in JSON format
function New-JsonReleaseNotes {
    param($VersionInfo, $Commits, $Version)
    
    $json = @{
        version = $Version
        releaseDate = Get-Date -Format "o"
        range = @{
            from = $VersionInfo.from
            to = $VersionInfo.to
            fromDate = $VersionInfo.fromDate
            toDate = $VersionInfo.toDate
        }
        summary = @{
            features = $Commits.features.Count
            fixes = $Commits.fixes.Count
            breaking = $Commits.breaking.Count
            other = $Commits.other.Count
            contributors = $Commits.authors.Count
        }
        contributors = $Commits.authors
        changes = @{
            features = $Commits.features | ForEach-Object { @{ hash = $_.hash; subject = $_.subject; author = $_.author } }
            fixes = $Commits.fixes | ForEach-Object { @{ hash = $_.hash; subject = $_.subject; author = $_.author } }
            breaking = $Commits.breaking | ForEach-Object { @{ hash = $_.hash; subject = $_.subject; author = $_.author } }
            other = $Commits.other | ForEach-Object { @{ hash = $_.hash; subject = $_.subject; author = $_.author } }
        }
    }
    
    return $json | ConvertTo-Json -Depth 10
}

# Main execution
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Release Notes Generator" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

$versionInfo = Get-VersionInfo -FromTag $FromTag -ToTag $ToTag
$commits = Get-CommitHistory -FromRef $versionInfo.from -ToRef $versionInfo.to

# Determine version number
$newVersion = if ($ToTag -eq "HEAD") {
    # Generate version from date or increment
    $latestTag = git describe --tags --abbrev=0 2>$null
    if ($latestTag -match 'v?(\d+)\.(\d+)\.(\d+)') {
        $major = [int]$Matches[1]
        $minor = [int]$Matches[2]
        $patch = [int]$Matches[3]
        
        # Increment based on commit types
        if ($commits.breaking.Count -gt 0) {
            $major++
            $minor = 0
            $patch = 0
        } elseif ($commits.features.Count -gt 0) {
            $minor++
            $patch = 0
        } else {
            $patch++
        }
        
        "v$major.$minor.$patch"
    } else {
        "v1.0.0"
    }
} else {
    $ToTag
}

Write-Host "Generating release notes for version: $newVersion" -ForegroundColor Yellow
Write-Host ""

# Generate release notes
$releaseNotes = switch ($Format) {
    'markdown' { New-MarkdownReleaseNotes -VersionInfo $versionInfo -Commits $commits -Version $newVersion }
    'json' { New-JsonReleaseNotes -VersionInfo $versionInfo -Commits $commits -Version $newVersion }
    'html' { 
        $md = New-MarkdownReleaseNotes -VersionInfo $versionInfo -Commits $commits -Version $newVersion
        # In a real implementation, convert markdown to HTML
        $md
    }
}

# Save release notes
if (-not $OutputFile) {
    $OutputFile = Join-Path $releaseNotesDir "RELEASE-$newVersion.md"
}

$releaseNotes | Set-Content -Path $OutputFile -Force

Write-Host "✓ Release notes generated: $OutputFile" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Features: $($commits.features.Count)" -ForegroundColor White
Write-Host "  Bug Fixes: $($commits.fixes.Count)" -ForegroundColor White
Write-Host "  Breaking Changes: $($commits.breaking.Count)" -ForegroundColor $(if ($commits.breaking.Count -gt 0) { 'Red' } else { 'White' })
Write-Host "  Other: $($commits.other.Count)" -ForegroundColor White
Write-Host "  Contributors: $($commits.authors.Count)" -ForegroundColor White
Write-Host ""

if ($AutoPublish) {
    Write-Host "Publishing release to GitHub..." -ForegroundColor Cyan
    
    try {
        # Create git tag
        git tag -a $newVersion -m "Release $newVersion"
        git push origin $newVersion
        
        # Create GitHub release
        gh release create $newVersion --title "Release $newVersion" --notes-file $OutputFile
        
        Write-Host "✓ Release published successfully" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to publish release: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review the release notes at: $OutputFile" -ForegroundColor White
Write-Host "  2. Create a git tag: git tag -a $newVersion -m 'Release $newVersion'" -ForegroundColor White
Write-Host "  3. Push the tag: git push origin $newVersion" -ForegroundColor White
Write-Host "  4. Create a GitHub release: gh release create $newVersion --notes-file `"$OutputFile`"" -ForegroundColor White
