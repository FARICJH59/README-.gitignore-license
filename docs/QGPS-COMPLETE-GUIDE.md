# QGPS Industrial Autopilot System - Complete Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Installation](#installation)
4. [Core Components](#core-components)
5. [Usage Guide](#usage-guide)
6. [CI/CD Integration](#cicd-integration)
7. [Troubleshooting](#troubleshooting)

## Overview

QGPS (Quantum Global Platform System) is a Brain-driven, MCP-managed multi-repository autopilot system designed for industrial-grade projects. It provides:

- **Centralized Policy Management**: Brain core enforces consistent standards across all repositories
- **Automated Compliance**: Validates project structure and dependencies automatically
- **Multi-Repo Orchestration**: Manage multiple projects from a single control plane
- **Self-Healing**: Automatic detection and fixing of compliance issues
- **CI/CD Ready**: Integrated GitHub Actions workflows for continuous validation

## Architecture

### Brain Core
The Brain core is the central nervous system of QGPS:

```
brain-core/
├── version.json              # Brain version and compatibility
├── repo-registry.json        # Registry of all managed repositories
└── compliance/
    ├── mandatory-modules.json # Required folder/file structure
    └── infra-policy.json      # Technology stack requirements
```

### Repository Structure
Each managed repository contains a `.brain/` folder with synced policies:

```
my-project/
├── .brain/                    # Brain sync data
│   ├── brain-version.json    # Current Brain version
│   ├── mandatory-modules.json # Synced structure requirements
│   ├── infra-policy.json     # Synced infrastructure policy
│   ├── sync-metadata.json    # Last sync information
│   └── compliance-log.json   # Compliance check results
├── src/                      # Source code (mandatory)
├── config/                   # Configuration (mandatory)
├── docs/                     # Documentation (mandatory)
├── README.md                 # Project docs (mandatory)
├── LICENSE                   # License file (mandatory)
└── .gitignore               # Git ignore (mandatory)
```

## Installation

### Option 1: Quick Start (Recommended)

```powershell
# Download and run the starter script
powershell -NoProfile -ExecutionPolicy Bypass -File .\create-qgps-starter.ps1 -RootPath "C:\Projects\QGPS-Starter"
```

### Option 2: Manual Setup

1. Clone this repository
2. Navigate to the cloned directory
3. Run the bootstrap script:

```powershell
cd path\to\repository
.\scripts\mega-bootstrap-qgps.ps1
```

### Option 3: Custom Installation Path

```powershell
.\create-qgps-starter.ps1 -RootPath "D:\MyCustomPath\QGPS"
```

## Core Components

### 1. axiom-sync.ps1
Synchronizes a repository with Brain core policies.

**Usage:**
```powershell
.\scripts\axiom-sync.ps1 -RepoPath "C:\Projects\MyProject"
```

**What it does:**
- Creates `.brain/` folder in the repository
- Copies Brain version information
- Syncs compliance policies
- Creates sync metadata

### 2. axiom-compliance.ps1
Validates repository compliance with Brain policies.

**Usage:**
```powershell
# Check compliance
.\scripts\axiom-compliance.ps1 -RepoPath "C:\Projects\MyProject"

# Check and auto-fix issues
.\scripts\axiom-compliance.ps1 -RepoPath "C:\Projects\MyProject" -FixIssues
```

**What it checks:**
- Mandatory folders exist
- Mandatory files exist
- Recommended files (warnings only)
- Generates compliance report

### 3. axiom-orchestrator.ps1
Orchestrates multi-repository operations.

**Usage:**
```powershell
# View status of all repositories
.\scripts\axiom-orchestrator.ps1 -Action status

# Sync all registered repositories
.\scripts\axiom-orchestrator.ps1 -Action sync-all

# Check compliance for all repositories
.\scripts\axiom-orchestrator.ps1 -Action check-all
```

**Actions:**
- `status`: Shows current state of all repositories
- `sync-all`: Syncs all repositories with Brain
- `check-all`: Runs compliance checks on all repositories

### 4. generate-autopilot-repo.ps1
Creates and registers a new autopilot-ready repository.

**Usage:**
```powershell
.\scripts\generate-autopilot-repo.ps1 `
    -RepoName "MyProject" `
    -RepoPath "C:\Projects\MyProject" `
    -Priority 5
```

**What it does:**
- Creates repository directory (if needed)
- Registers repository in Brain core
- Runs Brain sync
- Runs compliance check with auto-fix
- Updates orchestrator status

**Priority Levels:**
- 1-3: High priority (critical systems)
- 4-6: Medium priority (standard projects)
- 7-10: Low priority (experimental/dev projects)

### 5. mega-bootstrap-qgps.ps1
One-shot setup for the entire QGPS system.

**Usage:**
```powershell
# Basic bootstrap
.\scripts\mega-bootstrap-qgps.ps1

# Include example repositories
.\scripts\mega-bootstrap-qgps.ps1 -IncludeExamples
```

**What it does:**
- Verifies Brain core exists
- Validates all scripts
- Shows current system status
- Optionally creates example repositories
- Displays available commands

## Usage Guide

### Creating Your First Autopilot Repository

1. **Generate the repository:**
```powershell
.\scripts\generate-autopilot-repo.ps1 `
    -RepoName "MyAwesomeProject" `
    -RepoPath "C:\Projects\MyAwesomeProject" `
    -Priority 5
```

2. **Navigate to your repository:**
```powershell
cd C:\Projects\MyAwesomeProject
```

3. **Verify structure:**
```powershell
# Check .brain folder
ls .brain

# Should show:
# - brain-version.json
# - mandatory-modules.json
# - infra-policy.json
# - sync-metadata.json
# - compliance-log.json
```

4. **Start developing:**
Your project is now autopilot-ready! All mandatory folders (src, config, docs) have been created.

### Syncing an Existing Repository

If you have an existing project:

1. **Register it:**
```powershell
.\scripts\generate-autopilot-repo.ps1 `
    -RepoName "ExistingProject" `
    -RepoPath "C:\Projects\ExistingProject"
```

2. **Check compliance:**
```powershell
.\scripts\axiom-compliance.ps1 -RepoPath "C:\Projects\ExistingProject"
```

3. **Fix any issues:**
```powershell
.\scripts\axiom-compliance.ps1 -RepoPath "C:\Projects\ExistingProject" -FixIssues
```

### Managing Multiple Repositories

1. **View all repositories:**
```powershell
.\scripts\axiom-orchestrator.ps1 -Action status
```

2. **Sync all repositories:**
```powershell
.\scripts\axiom-orchestrator.ps1 -Action sync-all
```

3. **Check compliance for all:**
```powershell
.\scripts\axiom-orchestrator.ps1 -Action check-all
```

### Updating Brain Policies

When you update policies in `brain-core/compliance/`:

1. **Sync all repositories:**
```powershell
.\scripts\axiom-orchestrator.ps1 -Action sync-all
```

2. **Verify compliance:**
```powershell
.\scripts\axiom-orchestrator.ps1 -Action check-all
```

## CI/CD Integration

### GitHub Actions

The included workflow (`ci-cd-autopilot.yml`) automatically:

1. Checks out each repository
2. Syncs with Brain core
3. Validates compliance
4. Runs orchestrator
5. Uploads compliance logs as artifacts

**Customizing the workflow:**

Edit `.github/workflows/ci-cd-autopilot.yml` and update the matrix:

```yaml
strategy:
  matrix:
    repo: [your-repo-1, your-repo-2, your-repo-3]
```

### Local Testing

Before pushing to CI/CD, test locally:

```powershell
# Sync your repository
.\scripts\axiom-sync.ps1 -RepoPath "C:\Projects\YourRepo"

# Check compliance
.\scripts\axiom-compliance.ps1 -RepoPath "C:\Projects\YourRepo"

# If issues found, fix them
.\scripts\axiom-compliance.ps1 -RepoPath "C:\Projects\YourRepo" -FixIssues
```

## Troubleshooting

### Issue: "Brain core not found"

**Solution:**
Ensure you've run the starter script:
```powershell
.\create-qgps-starter.ps1 -RootPath "C:\Projects\QGPS-Starter"
```

### Issue: "Missing mandatory folder: src"

**Solution:**
Run compliance check with auto-fix:
```powershell
.\scripts\axiom-compliance.ps1 -RepoPath "YourPath" -FixIssues
```

### Issue: "Repository not registered"

**Solution:**
Register the repository:
```powershell
.\scripts\generate-autopilot-repo.ps1 -RepoName "YourRepo" -RepoPath "YourPath"
```

### Issue: ".brain folder not found"

**Solution:**
Run Brain sync:
```powershell
.\scripts\axiom-sync.ps1 -RepoPath "YourPath"
```

### Issue: "Compliance check failed in CI/CD"

**Solution:**
1. Check the uploaded compliance-log.json artifact
2. Fix issues locally
3. Re-run compliance check
4. Commit and push

### Debugging Scripts

Add `-ErrorAction Stop` to see detailed errors:
```powershell
.\scripts\axiom-sync.ps1 -RepoPath "YourPath" -ErrorAction Stop
```

## Best Practices

1. **Regular Syncs**: Sync repositories weekly or after Brain policy updates
2. **Priority Management**: Use priorities to focus on critical projects
3. **Compliance First**: Fix compliance issues before feature development
4. **Version Control**: Keep Brain core in version control
5. **Documentation**: Document custom policies in `docs/` folder
6. **Testing**: Test policy changes on low-priority repos first
7. **Backup**: Keep backups of `repo-registry.json`

## Advanced Configuration

### Custom Brain Path

All scripts support custom Brain path:
```powershell
.\scripts\axiom-sync.ps1 `
    -RepoPath "YourPath" `
    -BrainCorePath "D:\Custom\brain-core"
```

### Modifying Policies

Edit policies in `brain-core/compliance/`:

**mandatory-modules.json**: Add/remove required folders and files
**infra-policy.json**: Update version requirements

After modifications, sync all repositories:
```powershell
.\scripts\axiom-orchestrator.ps1 -Action sync-all
```

## Support

For issues, questions, or contributions:
1. Review this documentation
2. Check the troubleshooting section
3. Examine compliance logs in `.brain/` folders
4. Create an issue in the repository

---

**QGPS Industrial Autopilot** - Built for enterprise-grade automation
Version 1.0.0 | MIT License
