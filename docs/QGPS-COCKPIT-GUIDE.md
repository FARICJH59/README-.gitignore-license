# QGPS Autonomous Cockpit - User Guide

## Overview

The QGPS Autonomous Cockpit is an orchestration system that automates the management of multiple repositories registered in the Brain core. It handles dependency installation, building, and launching development servers with a single command.

## Features

### 🔧 Automatic Dependency Installation
- Scans all registered repositories for `package.json`
- Runs `npm install` automatically for Node.js/TypeScript projects
- Silent installation to reduce console clutter

### 🏗️ Smart Building
- Detects `build` scripts in package.json
- Automatically executes build commands before launching servers
- Handles build errors gracefully

### 🚀 Dev Server Launch
- Launches development servers in separate PowerShell windows
- Supports both `dev` and `start` scripts
- Each server runs independently in its own terminal

### 📊 Activity Logging
- All cockpit operations are logged to `.brain/cockpit-log.json`
- Tracks processed repositories and launched servers
- Records timestamps for audit trails

## Installation

The QGPS Autonomous Cockpit is included in the repository. No additional installation required.

## Prerequisites

Before using the cockpit, ensure:

1. **Brain Core Initialized**: The `brain-core/repo-registry.json` must exist
2. **Repositories Registered**: Use `generate-autopilot-repo.ps1` to add repositories
3. **Node.js/npm**: Required for JavaScript/TypeScript projects
4. **PowerShell**: Version 7.0 or higher recommended

## Usage

### Basic Usage

```powershell
# Navigate to repository root
cd /path/to/repository

# Run the cockpit
.\scripts\qgps-cockpit.ps1
```

### Advanced Usage

```powershell
# Specify maximum concurrency (default: 2)
.\scripts\qgps-cockpit.ps1 -MaxConcurrency 3

# Use custom Brain core path
.\scripts\qgps-cockpit.ps1 -BrainCorePath "C:\Custom\Path\brain-core"
```

## Output Explanation

### Console Output

```
🚀 Starting QGPS Autonomous Cockpit...
======================================================================
📋 Found 3 registered repository(ies)

📦 Processing repository: axiomcore
   Path: C:\Projects\axiomcore
   📄 Found package.json
   🔧 Installing dependencies...
   ✅ Dependencies installed
   🏗️  Building project...
   ✅ Build completed
   🚀 Starting dev server...
   ✅ Dev server launched in new window

📦 Processing repository: energy-dashboard
   Path: C:\Projects\energy-dashboard
   📄 Found package.json
   🔧 Installing dependencies...
   ✅ Dependencies installed
   🚀 Starting dev server...
   ✅ Dev server launched in new window

======================================================================
✅ QGPS Cockpit run complete!
======================================================================

📊 Summary:
   Processed repositories: 3
   Launched servers: 2

🌐 Active servers:
   - axiomcore
   - energy-dashboard

📁 Log saved to: .brain/cockpit-log.json

💡 Tip: Close the dev server windows to stop the servers
```

### Log File Format

The cockpit log (`.brain/cockpit-log.json`) contains:

```json
{
  "lastRun": "2026-02-19T13:35:07.9243616+00:00",
  "processedRepos": [
    "axiomcore",
    "energy-dashboard",
    "ai-predictor"
  ],
  "launchedServers": [
    "axiomcore",
    "energy-dashboard"
  ],
  "maxConcurrency": 2
}
```

## Workflow

### Step 1: Register Repositories

Before using the cockpit, register your repositories:

```powershell
.\scripts\generate-autopilot-repo.ps1 `
    -RepoName "MyProject" `
    -RepoPath "C:\Projects\MyProject" `
    -Priority 5
```

### Step 2: Run the Cockpit

Launch all registered repositories:

```powershell
.\scripts\qgps-cockpit.ps1
```

### Step 3: Work with Dev Servers

Each repository with a dev server will open in a separate PowerShell window. You can:
- View real-time logs in each window
- Access the running applications (typically on localhost)
- Stop individual servers by closing their windows

### Step 4: Stop All Servers

To stop all dev servers:
1. Close each PowerShell window that was opened by the cockpit
2. Or press Ctrl+C in each window to gracefully stop the server

## Supported Project Types

### Node.js/TypeScript Projects

Projects with `package.json` are fully supported:
- **Dependencies**: Automatic `npm install`
- **Build**: Runs `npm run build` if script exists
- **Dev Server**: Launches `npm run dev` or `npm start`

### Other Project Types

Projects without `package.json` are skipped with an informational message.

## Error Handling

The cockpit handles errors gracefully:

### Missing Repository Path
```
📦 Processing repository: MyProject
   Path: C:\Projects\MyProject
   ⚠️  Repository path not found, skipping
```

### Missing package.json
```
📦 Processing repository: MyProject
   Path: C:\Projects\MyProject
   ℹ️  No package.json found
```

### npm Install Issues
```
   🔧 Installing dependencies...
   ⚠️  Warning: npm install had issues: <error details>
```

### Build Failures
```
   🏗️  Building project...
   ⚠️  Warning: Build had issues
```

## Integration with Other QGPS Scripts

The cockpit works seamlessly with other QGPS components:

### Brain Sync
Ensure repositories are synced before launching:
```powershell
.\scripts\axiom-orchestrator.ps1 -Action sync-all
.\scripts\qgps-cockpit.ps1
```

### Compliance Check
Validate compliance before launching:
```powershell
.\scripts\axiom-orchestrator.ps1 -Action check-all
.\scripts\qgps-cockpit.ps1
```

### Orchestrator Status
View repository status:
```powershell
.\scripts\axiom-orchestrator.ps1 -Action status
```

## Troubleshooting

### Issue: "Brain registry not found"

**Solution**: Initialize the Brain core:
```powershell
# Ensure brain-core directory exists
.\create-qgps-starter.ps1 -RootPath "."
```

### Issue: "No repositories registered"

**Solution**: Register at least one repository:
```powershell
.\scripts\generate-autopilot-repo.ps1 -RepoName "MyProject" -RepoPath "C:\Path"
```

### Issue: Dev servers not launching

**Possible causes**:
1. No `dev` or `start` script in package.json
2. Port already in use
3. Missing dependencies

**Solution**: Check package.json scripts and resolve port conflicts

### Issue: PowerShell windows close immediately

**Solution**: Check for syntax errors in package.json or missing node_modules

## Best Practices

1. **Register Repositories First**: Always register repositories before running the cockpit
2. **Review Logs**: Check `.brain/cockpit-log.json` after each run
3. **Clean Builds**: Run builds separately first if encountering issues
4. **Port Management**: Ensure no port conflicts exist
5. **Sequential Testing**: Test one repository at a time initially
6. **Keep Windows Open**: Don't close dev server windows until you're done working

## Performance Considerations

### Max Concurrency

The `-MaxConcurrency` parameter is reserved for future use. Currently, all repositories are processed sequentially to ensure stability.

### Memory Usage

Each dev server runs in a separate PowerShell window, consuming:
- ~100-200 MB per PowerShell instance
- Variable memory for Node.js processes (depends on project)

**Recommendation**: On systems with limited RAM, register fewer repositories or close unnecessary servers.

## Example Session

```powershell
# Step 1: View registered repositories
PS> .\scripts\axiom-orchestrator.ps1 -Action status

📊 Repository Status Report

  📦 axiomcore
     Path: C:\Projects\axiomcore
     Priority: 1
     Status: ✅ Exists
     Brain: ✅ Synced

  📦 energy-dashboard
     Path: C:\Projects\energy-dashboard
     Priority: 2
     Status: ✅ Exists
     Brain: ✅ Synced

Total Repositories: 2

# Step 2: Launch all repositories
PS> .\scripts\qgps-cockpit.ps1

🚀 Starting QGPS Autonomous Cockpit...
======================================================================
📋 Found 2 registered repository(ies)

📦 Processing repository: axiomcore
   Path: C:\Projects\axiomcore
   📄 Found package.json
   🔧 Installing dependencies...
   ✅ Dependencies installed
   🚀 Starting dev server...
   ✅ Dev server launched in new window

📦 Processing repository: energy-dashboard
   Path: C:\Projects\energy-dashboard
   📄 Found package.json
   🔧 Installing dependencies...
   ✅ Dependencies installed
   🚀 Starting dev server...
   ✅ Dev server launched in new window

======================================================================
✅ QGPS Cockpit run complete!
======================================================================

📊 Summary:
   Processed repositories: 2
   Launched servers: 2

🌐 Active servers:
   - axiomcore
   - energy-dashboard

# Two PowerShell windows open automatically with dev servers running
```

## Future Enhancements

Planned features for future versions:
- Parallel repository processing (true concurrent execution)
- Health monitoring for running servers
- Automatic port allocation
- Container-based server launch
- Hot reload detection
- Centralized log aggregation

## Support

For issues or questions:
1. Check this documentation
2. Review `.brain/cockpit-log.json` for details
3. Examine individual dev server windows for errors
4. Consult `docs/QGPS-COMPLETE-GUIDE.md` for Brain core documentation

---

**QGPS Autonomous Cockpit** - Orchestrating industrial-grade development workflows  
Version 1.0.0 | MIT License
