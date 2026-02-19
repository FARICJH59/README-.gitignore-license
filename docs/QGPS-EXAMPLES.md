# QGPS Quick Start Examples

## Example 1: Creating a New Project from Scratch

### Step 1: Generate the Autopilot Repository
```powershell
cd /home/runner/work/README-.gitignore-license/README-.gitignore-license
.\scripts\generate-autopilot-repo.ps1 `
    -RepoName "EnergyDashboard" `
    -RepoPath "/tmp/test-repos/EnergyDashboard" `
    -Priority 3
```

Expected output:
```
🚀 Generating Autopilot-Ready Repository
============================================================
Repository: EnergyDashboard
Path: /tmp/test-repos/EnergyDashboard
Priority: 3
============================================================

📁 Creating repository directory...
✅ Repository directory created
✅ Created .brain folder
✅ Repository registered in Brain core
💾 Registry saved

🔄 Running Brain sync...
🔍 Running compliance check...
🎯 Updating orchestrator status...

============================================================
✅ Repository 'EnergyDashboard' is now fully autopilot-ready and MCP-compliant!
============================================================
```

### Step 2: Verify the Structure
```bash
ls -la /tmp/test-repos/EnergyDashboard
```

You should see:
```
drwxr-xr-x  2 runner runner 4096 .brain/
drwxr-xr-x  2 runner runner 4096 src/
drwxr-xr-x  2 runner runner 4096 config/
drwxr-xr-x  2 runner runner 4096 docs/
-rw-r--r--  1 runner runner    0 README.md
-rw-r--r--  1 runner runner    0 LICENSE
-rw-r--r--  1 runner runner    0 .gitignore
```

### Step 3: Check Brain Sync Data
```bash
ls -la /tmp/test-repos/EnergyDashboard/.brain/
```

You should see:
```
-rw-r--r--  1 runner runner  470 brain-version.json
-rw-r--r--  1 runner runner  363 mandatory-modules.json
-rw-r--r--  1 runner runner  648 infra-policy.json
-rw-r--r--  1 runner runner  200 sync-metadata.json
-rw-r--r--  1 runner runner  350 compliance-log.json
```

## Example 2: Managing Multiple Repositories

### Create Multiple Projects
```powershell
# Create first project
.\scripts\generate-autopilot-repo.ps1 `
    -RepoName "MLPipeline" `
    -RepoPath "/tmp/test-repos/MLPipeline" `
    -Priority 1

# Create second project
.\scripts\generate-autopilot-repo.ps1 `
    -RepoName "IoTGateway" `
    -RepoPath "/tmp/test-repos/IoTGateway" `
    -Priority 2

# Create third project
.\scripts\generate-autopilot-repo.ps1 `
    -RepoName "WebPortal" `
    -RepoPath "/tmp/test-repos/WebPortal" `
    -Priority 5
```

### Check Status of All Repositories
```powershell
.\scripts\axiom-orchestrator.ps1 -Action status
```

Expected output:
```
🎯 QGPS Orchestrator - status
============================================================

📊 Repository Status Report

  📦 MLPipeline
     Path: /tmp/test-repos/MLPipeline
     Priority: 1
     Status: ✅ Exists
     Brain: ✅ Synced

  📦 IoTGateway
     Path: /tmp/test-repos/IoTGateway
     Priority: 2
     Status: ✅ Exists
     Brain: ✅ Synced

  📦 WebPortal
     Path: /tmp/test-repos/WebPortal
     Priority: 5
     Status: ✅ Exists
     Brain: ✅ Synced

Total Repositories: 3

============================================================
✅ Orchestrator completed
```

## Example 3: Compliance Checking

### Check Compliance for Single Repository
```powershell
.\scripts\axiom-compliance.ps1 -RepoPath "/tmp/test-repos/EnergyDashboard"
```

Expected output:
```
🔍 Starting Compliance Check for: /tmp/test-repos/EnergyDashboard

📋 Checking mandatory folders...
  ✅ Found: src
  ✅ Found: config
  ✅ Found: docs
  ✅ Found: .brain

📋 Checking mandatory files...
  ✅ Found: README.md
  ✅ Found: LICENSE
  ✅ Found: .gitignore

📋 Checking recommended files...
  ⚠️  Recommended: package.json
  ⚠️  Recommended: Dockerfile
  ⚠️  Recommended: .env.example

✅ Compliance check PASSED
```

### Check Compliance for All Repositories
```powershell
.\scripts\axiom-orchestrator.ps1 -Action check-all
```

## Example 4: Brain Synchronization

### Sync Single Repository
```powershell
.\scripts\axiom-sync.ps1 -RepoPath "/tmp/test-repos/EnergyDashboard"
```

Expected output:
```
🔄 Starting Brain Sync for: /tmp/test-repos/EnergyDashboard
✅ Created .brain folder in repository
📦 Brain Version: 1.0.0.0
✅ Synced mandatory modules policy
✅ Synced infrastructure policy
✅ Brain sync completed successfully
📁 Brain data stored in: /tmp/test-repos/EnergyDashboard/.brain
```

### Sync All Repositories
```powershell
.\scripts\axiom-orchestrator.ps1 -Action sync-all
```

## Example 5: Using the Complete Starter

### Create Full QGPS System
```powershell
# Run the main creation script
.\create-qgps-starter.ps1 -RootPath "C:\Projects\QGPS-Industrial"
```

Expected output:
```
🚀 Starting QGPS Starter Repo Creation...
Target Path: C:\Projects\QGPS-Industrial

📁 Step 1: Creating folder structure...
  ✅ Created folder: C:\Projects\QGPS-Industrial\brain-core
  ✅ Created folder: C:\Projects\QGPS-Industrial\brain-core\compliance
  ✅ Created folder: C:\Projects\QGPS-Industrial\scripts
  ✅ Created folder: C:\Projects\QGPS-Industrial\docs
  ✅ Created folder: C:\Projects\QGPS-Industrial\.github\workflows

🧠 Step 2: Creating Brain core files...
  ✅ Created version.json
  ✅ Created repo-registry.json
  ✅ Created mandatory-modules.json
  ✅ Created infra-policy.json

📜 Step 3: Creating QGPS scripts...
  ✅ Created script: axiom-sync.ps1
  ✅ Created script: axiom-compliance.ps1
  ✅ Created script: axiom-orchestrator.ps1
  ✅ Created script: generate-autopilot-repo.ps1
  ✅ Created script: mega-bootstrap-qgps.ps1

📄 Step 4: Creating README.md...
  ✅ README.md created

⚙️  Step 5: Creating GitHub Actions workflow...
  ✅ GitHub Actions workflow created

======================================================================
🎉 QGPS Starter Repo Bundle fully created at:
   C:\Projects\QGPS-Industrial
======================================================================

Next steps:
  1. cd C:\Projects\QGPS-Industrial
  2. .\scripts\mega-bootstrap-qgps.ps1
  3. .\scripts\generate-autopilot-repo.ps1 -RepoName 'MyProject' -RepoPath 'C:\Projects\MyProject'

🚀 Ready to build industrial-grade autopilot systems!
```

### Bootstrap the System
```powershell
cd C:\Projects\QGPS-Industrial
.\scripts\mega-bootstrap-qgps.ps1
```

## Example 6: CI/CD Integration

### Local Testing Before CI/CD
```powershell
# Sync
.\scripts\axiom-sync.ps1 -RepoPath "/path/to/your/repo"

# Check compliance
.\scripts\axiom-compliance.ps1 -RepoPath "/path/to/your/repo"

# Fix any issues
.\scripts\axiom-compliance.ps1 -RepoPath "/path/to/your/repo" -FixIssues

# Verify orchestrator
.\scripts\axiom-orchestrator.ps1 -Action status
```

### GitHub Actions Configuration
The workflow in `.github/workflows/ci-cd-autopilot.yml` will automatically:
1. Check out your repositories
2. Run Brain sync
3. Validate compliance
4. Upload logs as artifacts

## Example 7: Working with Priorities

### High Priority Projects (1-3)
```powershell
.\scripts\generate-autopilot-repo.ps1 `
    -RepoName "CriticalSystem" `
    -RepoPath "/tmp/critical-system" `
    -Priority 1
```

### Medium Priority Projects (4-6)
```powershell
.\scripts\generate-autopilot-repo.ps1 `
    -RepoName "StandardApp" `
    -RepoPath "/tmp/standard-app" `
    -Priority 5
```

### Low Priority Projects (7-10)
```powershell
.\scripts\generate-autopilot-repo.ps1 `
    -RepoName "ExperimentalFeature" `
    -RepoPath "/tmp/experimental" `
    -Priority 9
```

## Troubleshooting Examples

### Example: Missing .brain folder
```powershell
# Problem: Compliance check fails with ".brain folder not found"
# Solution: Run sync first
.\scripts\axiom-sync.ps1 -RepoPath "/path/to/repo"
```

### Example: Compliance failures
```powershell
# Problem: Missing mandatory folders
# Solution: Run compliance with auto-fix
.\scripts\axiom-compliance.ps1 -RepoPath "/path/to/repo" -FixIssues
```

### Example: Repository not registered
```powershell
# Problem: Orchestrator doesn't show your repository
# Solution: Register it
.\scripts\generate-autopilot-repo.ps1 `
    -RepoName "YourRepo" `
    -RepoPath "/path/to/repo"
```

## Common Workflows

### Daily Development Workflow
```powershell
# 1. Check status
.\scripts\axiom-orchestrator.ps1 -Action status

# 2. Sync if needed
.\scripts\axiom-sync.ps1 -RepoPath "/your/repo"

# 3. Develop features
# ... your development work ...

# 4. Before commit, check compliance
.\scripts\axiom-compliance.ps1 -RepoPath "/your/repo"
```

### Weekly Maintenance Workflow
```powershell
# 1. Sync all repositories with latest Brain policies
.\scripts\axiom-orchestrator.ps1 -Action sync-all

# 2. Check compliance across all projects
.\scripts\axiom-orchestrator.ps1 -Action check-all

# 3. Review and fix any issues
# ... fix identified problems ...

# 4. Re-check
.\scripts\axiom-orchestrator.ps1 -Action check-all
```

---

These examples demonstrate the core functionality of the QGPS Industrial Autopilot system. For complete documentation, see `docs/QGPS-COMPLETE-GUIDE.md`.
