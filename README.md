# axiomcore

AxiomCore MVP — backend, frontend, AI orchestration

## Description

This repository serves as the foundation for the AxiomCore MVP platform, providing backend services, frontend interfaces, and AI orchestration capabilities. The project is a comprehensive full-stack solution supporting both PowerShell and Python development environments.

## Features

- Full-stack platform architecture
- PowerShell scripting support
- Python application development
- Cross-platform compatibility

## Getting Started

### Prerequisites

- PowerShell 7.0 or higher
- Python 3.8 or higher

### Installation

#### Option 1: Clone the Repository

Clone the repository:

```bash
git clone https://github.com/TechFusion-Quantum-Global-Platform/axiomcore.git
cd axiomcore
```

#### Option 2: Create a New Repository

If you need to create a new axiomcore repository, you can use the provided scripts:

**Using Bash (Linux/macOS):**
```bash
./create-repo.sh
```

**Using PowerShell (Windows/Cross-platform):**
```powershell
./create-repo.ps1
```

**Or manually with GitHub CLI:**
```bash
gh repo create TechFusion-Quantum-Global-Platform/axiomcore \
  --private \
  --description "AxiomCore MVP — backend, frontend, AI orchestration" \
  --confirm
```

After creating the repository, you can initialize it with your project files:

```bash
# Clone the empty repository
git clone https://github.com/TechFusion-Quantum-Global-Platform/axiomcore.git
cd axiomcore

# Copy your project files into the directory
# Then commit and push them
git add .
git commit -m "Initial commit"
git push -u origin main
```

> **Note**: Option 2 requires GitHub CLI (`gh`) to be installed and authenticated. The repository will be created as private under the TechFusion-Quantum-Global-Platform organization.

## Enterprise Branch Protection Setup

The repository includes an automated setup script to configure enterprise-level branch protection and automation system for your axiomcore repository.

### Quick Start

Run the setup script from the repository root:

```powershell
# Basic setup
.\setup-enterprise-protection.ps1

# Specify repository details
.\setup-enterprise-protection.ps1 -RepoOwner "YourOrg" -RepoName "axiomcore"

# Dry run (preview changes without applying)
.\setup-enterprise-protection.ps1 -DryRun

# With GitHub token for API access
.\setup-enterprise-protection.ps1 -GitHubToken $env:GITHUB_TOKEN
```

### What the Script Does

The `setup-enterprise-protection.ps1` script automates the following:

1. **✅ Prerequisites Validation**
   - Checks for GitHub CLI, Git, and GitHub token
   - Validates required tools are available

2. **✅ Repository Structure Verification**
   - Ensures required folders exist (`.github/workflows`, `scripts`, `.brain`)
   - Creates missing folders automatically

3. **✅ Script Verification**
   - Validates all required PowerShell scripts are present:
     - `axiom-sync.ps1` - Brain sync operations
     - `axiom-compliance.ps1` - Compliance checking
     - `axiom-orchestrator.ps1` - Multi-repo orchestration
     - `qgps-cockpit.ps1` - Autonomous cockpit operations

4. **✅ GitHub Actions Workflow Validation**
   - Verifies `ci-cd-autopilot.yml` workflow exists
   - Checks that all required script steps are included

5. **✅ Branch Protection Configuration**
   - Provides guidance for manual configuration via GitHub UI
   - Documents required ruleset settings
   - Lists bypass actors (roles, teams, apps)

6. **✅ Comprehensive Logging**
   - Logs all operations to `.brain/cockpit-log.json`
   - Provides colored console output for easy monitoring
   - Includes timestamps and detailed status information

### Branch Protection Requirements

The script helps you configure the following branch protection rules for the `main` branch:

**Protection Rules:**
- ✅ Require linear history (no merge commits)
- ✅ Require pull requests before merging
- ✅ Require status checks to pass (including `ci-cd-autopilot`)
- ✅ Require code scanning results (CodeQL)
- ✅ Prevent force pushes
- ✅ Prevent deletions
- ✅ Require signed commits

**Bypass List:**
The following roles, teams, and apps should be added to the bypass list:
- Repository admin role
- Maintain role
- Write role
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

### Manual Configuration Steps

After running the setup script, complete the branch protection configuration manually:

1. Navigate to: `https://github.com/YourOrg/axiomcore/settings/rules`
2. Click "New branch ruleset"
3. Set ruleset name: `QGPS-Enterprise-Main-Protection`
4. Target the `main` branch
5. Enable all protection rules as listed above
6. Add bypass actors from the list above
7. Save the ruleset

### Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-RepoOwner` | GitHub repository owner/organization | `FARICJH59` |
| `-RepoName` | Repository name | `axiomcore` |
| `-GitHubToken` | GitHub personal access token (or use `$env:GITHUB_TOKEN`) | `$env:GITHUB_TOKEN` |
| `-BranchName` | Target branch for protection | `main` |
| `-DryRun` | Preview changes without applying them | `$false` |
| `-SkipBranchProtection` | Skip branch protection configuration | `$false` |

### Safety Features

The setup script includes multiple safety features:

- **Idempotent Operations**: Can be run multiple times safely
- **No Overwriting**: Existing files are never overwritten
- **Dry Run Mode**: Test the script without making changes
- **Comprehensive Logging**: All operations are logged for audit trail
- **Colored Output**: Easy-to-read console messages with status indicators
- **Error Handling**: Graceful handling of missing dependencies

### Troubleshooting

**GitHub CLI not found:**
```powershell
# Install GitHub CLI
winget install GitHub.cli
# Or visit: https://cli.github.com/
```

**No GitHub token:**
```powershell
# Set GitHub token environment variable
$env:GITHUB_TOKEN = "your_token_here"
# Or create a token at: https://github.com/settings/tokens
```

**Permission denied:**
- Ensure you have admin access to the repository
- Verify your GitHub token has the required scopes: `repo`, `workflow`

## QGPS Autonomous Cockpit

The QGPS Autonomous Cockpit provides automated orchestration for multiple repositories with dependency management and dev server launch capabilities.

### Usage

```powershell
# Start all registered repositories
.\scripts\qgps-cockpit.ps1

# Specify max concurrency (default: 2)
.\scripts\qgps-cockpit.ps1 -MaxConcurrency 3

# Use custom brain core path
.\scripts\qgps-cockpit.ps1 -BrainCorePath "C:\custom\brain-core"
```

### Features

- **Automatic Dependency Installation**: Runs `npm install` for all registered repositories with package.json
- **Smart Building**: Executes build scripts if they exist in package.json
- **Dev Server Launch**: Automatically starts dev servers in separate PowerShell windows (Windows) or background jobs (Linux/macOS)
- **Comprehensive Logging**: All cockpit runs are logged to `.brain/cockpit-log.json` with detailed error tracking
- **Environment Validation**: Checks Node.js and npm versions before processing
- **Concurrency Control**: Respects MaxConcurrency parameter to limit simultaneous server launches
- **Cross-Platform Support**: Works on Windows (PowerShell 5.1+), Linux, and macOS (PowerShell Core 7+)
- **Registry Validation**: Validates repo-registry.json structure with helpful error messages

### Error Handling & Logging

The cockpit now includes comprehensive error handling:
- Try/catch blocks around all npm operations
- Detailed error logs with timestamps, stack traces, and error categories
- Fallback behavior for missing or malformed configuration files
- Warning messages for non-critical issues

Error logs are stored in `.brain/cockpit-log.json` with the following structure:
```json
{
  "lastRun": "2026-02-19T14:21:28.2940131+00:00",
  "processedRepos": ["repo1", "repo2"],
  "launchedServers": ["repo1"],
  "maxConcurrency": 2,
  "runningJobs": 1,
  "platform": {
    "edition": "Core",
    "version": "7.4.13",
    "os": "Ubuntu 24.04.3 LTS",
    "isWindows": false
  },
  "environment": {
    "nodeVersion": "v24.13.0",
    "npmVersion": "11.6.2"
  },
  "detailedLogs": [
    {
      "timestamp": "2026-02-19T14:21:28.5Z",
      "repository": "repo1",
      "action": "npm-install",
      "status": "success",
      "message": "Dependencies installed successfully"
    }
  ]
}
```

### Prerequisites

Before using the cockpit, ensure:
1. Repositories are registered using `.\scripts\generate-autopilot-repo.ps1`
2. Node.js 18.x or higher is installed for JavaScript/TypeScript projects
3. npm is installed and available in PATH
4. Brain core is initialized with `brain-core/repo-registry.json`
5. For cross-platform usage, PowerShell Core 7+ is recommended

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
