# Enterprise Protection Setup - Usage Guide

This guide provides detailed instructions for configuring enterprise-level branch protection and automation for your axiomcore repository.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [Detailed Setup Steps](#detailed-setup-steps)
5. [Branch Protection Configuration](#branch-protection-configuration)
6. [Workflow Validation](#workflow-validation)
7. [Troubleshooting](#troubleshooting)

## Overview

The `setup-enterprise-protection.ps1` script automates the configuration of enterprise-level branch protection and automation system for your repository. It includes:

- ✅ Repository structure validation
- ✅ Script verification
- ✅ GitHub Actions workflow validation
- ✅ Branch protection guidance
- ✅ Comprehensive logging

## Prerequisites

Before running the setup script, ensure you have:

1. **PowerShell 7.0 or higher**
   ```powershell
   $PSVersionTable.PSVersion
   ```

2. **GitHub CLI (gh)** - Optional but recommended
   ```bash
   gh --version
   ```
   Install from: https://cli.github.com/

3. **Git**
   ```bash
   git --version
   ```

4. **GitHub Personal Access Token** - Optional for API access
   - Create at: https://github.com/settings/tokens
   - Required scopes: `repo`, `workflow`

## Quick Start

### Basic Usage

Run the script from the repository root:

```powershell
# Navigate to repository root
cd /path/to/your/repository

# Run setup script
.\setup-enterprise-protection.ps1
```

### With Custom Parameters

```powershell
# Specify repository details
.\setup-enterprise-protection.ps1 `
    -RepoOwner "YourOrganization" `
    -RepoName "your-repo-name" `
    -BranchName "main"

# Dry run (preview without making changes)
.\setup-enterprise-protection.ps1 -DryRun

# With GitHub token
.\setup-enterprise-protection.ps1 -GitHubToken $env:GITHUB_TOKEN

# Skip branch protection configuration
.\setup-enterprise-protection.ps1 -SkipBranchProtection
```

## Detailed Setup Steps

### Step 1: Run the Setup Script

```powershell
# Basic setup
.\setup-enterprise-protection.ps1
```

The script will:
1. Validate prerequisites (GitHub CLI, Git, GitHub token)
2. Verify repository structure
3. Check for required scripts
4. Validate GitHub Actions workflow
5. Provide branch protection configuration guidance

### Step 2: Review the Output

The script provides colored output with status indicators:

- ✅ **Green checkmarks** - Success
- ❌ **Red X marks** - Errors
- ⚠️ **Yellow warnings** - Warnings/Info
- 🔧 **Blue wrenches** - Configuration actions
- 📋 **Blue clipboards** - Information

### Step 3: Configure Branch Protection

After running the script, manually configure branch protection:

1. Navigate to your repository settings:
   ```
   https://github.com/YourOrg/your-repo/settings/rules
   ```

2. Click **"New branch ruleset"**

3. Configure the ruleset:
   - **Name**: `QGPS-Enterprise-Main-Protection`
   - **Target**: `main` branch
   - **Enforcement**: Active

4. Enable the following rules:
   - ✅ Restrict deletions
   - ✅ Block force pushes
   - ✅ Require linear history
   - ✅ Require signed commits
   - ✅ Require pull request before merging
   - ✅ Require status checks (add `ci-cd-autopilot`)
   - ✅ Require code scanning results (add `CodeQL`)

5. Add bypass actors (see [Bypass List](#bypass-list) below)

6. Save the ruleset

### Step 4: Verify the Configuration

```powershell
# Run the script again to verify
.\setup-enterprise-protection.ps1

# Check the log file
Get-Content .brain/cockpit-log.json | ConvertFrom-Json | Format-List
```

## Branch Protection Configuration

### Protection Rules

The following rules should be enabled for the `main` branch:

| Rule | Description | Required |
|------|-------------|----------|
| **Require linear history** | Prevent merge commits | ✅ Yes |
| **Require pull requests** | All changes via PR | ✅ Yes |
| **Require status checks** | Include `ci-cd-autopilot` | ✅ Yes |
| **Require code scanning** | CodeQL analysis | ✅ Yes |
| **Block force pushes** | Prevent force push | ✅ Yes |
| **Prevent deletions** | Prevent branch deletion | ✅ Yes |
| **Require signed commits** | GPG/SSH signatures | ✅ Yes |

### Bypass List

Add the following to the bypass list:

**Roles:**
- Repository admin role
- Maintain role
- Write role

**Apps & Services:**
- Deploy keys
- ChatGPT Codex connector
- Copilot code review app (.github)
- Copilot coding agent app (.github)
- Dependabot
- Firebase App Hosting app
- Google Cloud Build app
- Render
- SourceryAI
- Supabase
- Vercel
- Docker
- Monday.com GitHub integration

## Workflow Validation

The setup script validates the GitHub Actions workflow includes all required steps:

### Required Steps in ci-cd-autopilot.yml

1. **Checkout repository** - Uses `actions/checkout@v3`
2. **Setup PowerShell** - Uses `actions/setup-powershell@v2`
3. **Brain Sync** - Runs `axiom-sync.ps1`
4. **Compliance Check** - Runs `axiom-compliance.ps1`
5. **Run Orchestrator** - Runs `axiom-orchestrator.ps1`
6. **Run QGPS Cockpit** - Runs `qgps-cockpit.ps1`
7. **Upload Compliance Logs** - Uploads `.brain/compliance-log.json`
8. **Upload Sync Metadata** - Uploads `.brain/sync-metadata.json`

### Verify Workflow Locally

```powershell
# Check workflow file
Get-Content .github/workflows/ci-cd-autopilot.yml

# Validate syntax (requires yamllint)
yamllint .github/workflows/ci-cd-autopilot.yml
```

## Troubleshooting

### Common Issues

#### 1. Script Not Recognized / File Not Found

**Error:**
```
.\setup-enterprise-protection.ps1: The term '.\setup-enterprise-protection.ps1' is not recognized as a name of a cmdlet, function, script file, or executable program.
```

**Cause:** You are not in the repository directory where the script is located.

**Solution:**
```powershell
# Navigate to your repository directory
cd C:\path\to\your\repository
# Example: cd C:\Users\YourName\Documents\axiomcore

# Verify you're in the correct location
ls setup-enterprise-protection.ps1
# Should show: -rw-r--r-- setup-enterprise-protection.ps1

# Now run the script
.\setup-enterprise-protection.ps1
```

**Alternative Solution (if you cloned the repository):**
```powershell
# Find your repository
cd ~
Get-ChildItem -Recurse -Filter "setup-enterprise-protection.ps1" -ErrorAction SilentlyContinue | Select-Object Directory -First 1

# Or search in common locations
cd ~\Documents
cd ~\GitHub
cd ~\projects
```

#### 2. GitHub CLI Not Found

**Error:**
```
⚠️ GitHub CLI not found
```

**Solution:**
```powershell
# Windows
winget install GitHub.cli

# macOS
brew install gh

# Linux
sudo apt install gh
```

#### 3. No GitHub Token

**Error:**
```
⚠️ GitHub token not provided
```

**Solution:**
```powershell
# Set environment variable
$env:GITHUB_TOKEN = "ghp_your_token_here"

# Run script with token
.\setup-enterprise-protection.ps1 -GitHubToken "ghp_your_token_here"
```

Create a token at: https://github.com/settings/tokens

Required scopes:
- `repo` - Full repository access
- `workflow` - Update workflows

#### 4. Missing Scripts

**Error:**
```
❌ Missing: scripts/axiom-sync.ps1
```

**Solution:**
Ensure all required scripts are present in the `scripts` directory:
- `axiom-sync.ps1`
- `axiom-compliance.ps1`
- `axiom-orchestrator.ps1`
- `qgps-cockpit.ps1`

#### 5. Permission Denied

**Error:**
```
Permission denied when accessing repository
```

**Solution:**
- Ensure you have admin access to the repository
- Verify your GitHub token has the correct scopes
- Check if you're authenticated with GitHub CLI: `gh auth status`

#### 6. Workflow Not Found

**Error:**
```
❌ Workflow missing: ci-cd-autopilot.yml
```

**Solution:**
The workflow file must exist at `.github/workflows/ci-cd-autopilot.yml`

### Dry Run Mode

Test the script without making changes:

```powershell
.\setup-enterprise-protection.ps1 -DryRun
```

This will:
- Show what would be created/updated
- Display configuration that would be applied
- Not make any actual changes
- Still create log entries

### Viewing Logs

```powershell
# View the complete log
Get-Content .brain/cockpit-log.json | ConvertFrom-Json | Format-List

# View only recent entries
$log = Get-Content .brain/cockpit-log.json | ConvertFrom-Json
$log.entries | Select-Object -Last 5 | Format-Table

# View specific action logs
$log = Get-Content .brain/cockpit-log.json | ConvertFrom-Json
$log.entries | Where-Object { $_.action -eq "setup-complete" } | Format-List
```

## Advanced Usage

### Using with CI/CD

You can run the setup script as part of your CI/CD pipeline:

```yaml
- name: Configure Enterprise Protection
  shell: pwsh
  run: |
    .\setup-enterprise-protection.ps1 `
      -RepoOwner "${{ github.repository_owner }}" `
      -RepoName "${{ github.event.repository.name }}" `
      -GitHubToken "${{ secrets.GITHUB_TOKEN }}"
```

### Custom Brain Path

If you have a custom brain core path:

```powershell
.\setup-enterprise-protection.ps1 -BrainCorePath "C:\custom\brain-core"
```

### Multiple Repositories

Run the script for multiple repositories:

```powershell
$repos = @("axiomcore", "rugged-silo", "veo3")

foreach ($repo in $repos) {
    Write-Host "Configuring $repo..." -ForegroundColor Cyan
    .\setup-enterprise-protection.ps1 `
        -RepoName $repo `
        -RepoOwner "YourOrg"
}
```

## Additional Resources

- [GitHub Branch Protection Rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/defining-the-mergeability-of-pull-requests/about-protected-branches)
- [GitHub Rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [CodeQL Documentation](https://codeql.github.com/docs/)

## Support

If you encounter issues or have questions:

1. Check the troubleshooting section above
2. Review the log file at `.brain/cockpit-log.json`
3. Run the script with `-DryRun` to see what would happen
4. Consult the repository documentation

---

**Last Updated:** 2026-02-19
**Version:** 1.0.0
