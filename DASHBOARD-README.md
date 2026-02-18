# Multi-Agent Monitoring Dashboard

A comprehensive PowerShell-based monitoring and orchestration system for managing multiple AxiomCore projects with controlled concurrency, live status updates, and automatic recovery.

## Features

### Core Capabilities
- ✅ **Controlled Concurrency**: Limit simultaneous agent execution to prevent system overload
- ✅ **Live Status Updates**: Real-time progress tracking for each agent
- ✅ **Automatic Recovery**: Optional retry logic for failed agents
- ✅ **Browser Integration**: Automatic frontend launch in browser
- ✅ **Comprehensive Logging**: Timestamped logs saved to file for review

### Visual Dashboard Features
- 📊 **Live Progress Bars**: Visual representation of each agent's progress
- 📝 **Real-time Log Display**: Recent logs displayed with color coding
- 🎨 **Color-Coded Status**: Green for success, red for errors, yellow for warnings
- ⏸️ **Pause/Resume Control**: Interactive dashboard control via keyboard
- 📈 **Statistics Panel**: Live counters for completed, failed, running, and queued agents

## Prerequisites

- PowerShell 5.1 or later (PowerShell Core 7+ recommended)
- Git
- Docker Desktop (for containerization)
- Node.js and npm (for frontend/backend scaffolding)

## Installation

1. Clone the repository:
```powershell
git clone https://github.com/FARICJH59/README-.gitignore-license.git
cd README-.gitignore-license
```

2. Set execution policy (if needed):
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

3. Create your brain-knowledge.json file in `$env:USERPROFILE\Projects\`:
```powershell
# Use the sample file as a template
Copy-Item brain-knowledge.sample.json "$env:USERPROFILE\Projects\brain-knowledge.json"
# Then edit it with your projects
```

## Configuration

### Brain Knowledge File Format

The `brain-knowledge.json` file defines your projects:

```json
[
  {
    "name": "project-name",
    "repo": "https://github.com/org/repo.git",
    "frontend": {
      "path": "frontend",
      "port": 3000
    },
    "backend": {
      "path": "api",
      "port": 8080
    }
  }
]
```

**Fields:**
- `name`: Unique identifier for the project
- `repo`: Git repository URL
- `frontend.path`: Relative path to frontend directory
- `frontend.port`: Port for frontend service
- `backend.path`: Relative path to backend/API directory
- `backend.port`: Port for backend service

## Usage

### Basic Usage

Run with default settings (2 concurrent agents, visual mode enabled):

```powershell
.\multi-agent-dashboard.ps1
```

### Advanced Usage

Customize the dashboard behavior with parameters:

```powershell
# Run with 3 concurrent agents
.\multi-agent-dashboard.ps1 -MaxConcurrentAgents 3

# Enable auto-retry for failed agents (up to 3 attempts)
.\multi-agent-dashboard.ps1 -AutoRetry

# Disable visual mode (basic console output)
.\multi-agent-dashboard.ps1 -VisualMode:$false

# Use custom brain knowledge file
.\multi-agent-dashboard.ps1 -BrainFile "C:\custom\path\brain.json"

# Combined options
.\multi-agent-dashboard.ps1 -MaxConcurrentAgents 3 -AutoRetry -BrainFile "C:\myprojects\brain.json"
```

### One-Line Execution

For quick execution:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; & "$env:USERPROFILE\Projects\axiomcore\multi-agent-dashboard.ps1"
```

## Interactive Controls

While the dashboard is running, use these keyboard shortcuts:

- **[P]** - Pause/Resume agent execution
- **[R]** - Force refresh the dashboard display
- **[Q]** - Quit the dashboard (graceful shutdown)

## Dashboard Layout

```
═══════════════════════════════════════════════════════════
 Multi-Agent Monitoring Dashboard - AxiomCore
═══════════════════════════════════════════════════════════

 Status: RUNNING
 Press [P] to Pause/Resume | [Q] to Quit | [R] to Refresh

 AGENT STATUS:
───────────────────────────────────────────────────────────
 [Running   ] axiomcore                    [████████████░░] 80%
    └─ Building Docker images
 [Completed ] energy-dashboard             [███████████████] 100%
 [Queued    ] ai-predictor                 

 STATISTICS:
───────────────────────────────────────────────────────────
  Completed: 1
  Failed: 0
  Running: 1
  Queued: 1

 RECENT LOGS:
───────────────────────────────────────────────────────────
  12:34:56 - [axiomcore] Creating frontend structure
  12:34:58 - [axiomcore] Building Docker image for frontend
  12:35:01 - [energy-dashboard] launched successfully

═══════════════════════════════════════════════════════════
```

## Agent Lifecycle

Each agent goes through the following phases:

1. **Queued** - Waiting for available execution slot
2. **Running** - Actively executing tasks
   - Cloning/updating repository (Progress: 10-25%)
   - Scaffolding frontend (Progress: 30-45%)
   - Scaffolding backend (Progress: 50-65%)
   - Building Docker images (Progress: 70-90%)
   - Launching browser (Progress: 95-100%)
3. **Completed** - Successfully finished all tasks
4. **Failed** - Encountered an error (with optional retry)

## Log Files

All dashboard activity is logged to:
```
$env:USERPROFILE\Projects\axiomcore\multi-agent-log.txt
```

Log entries include:
- Timestamp (HH:mm:ss format)
- Agent name
- Action/status message
- Error details (if applicable)

## Docker Management

The dashboard automatically:
- Creates Dockerfiles for frontend and backend
- Builds Docker images with tags: `{project-name}-frontend` and `{project-name}-api`
- Runs containers with port mappings
- Removes old containers before starting new ones

### Manual Docker Commands

View running containers:
```powershell
docker ps
```

Stop a specific project:
```powershell
docker stop axiomcore-frontend axiomcore-api
docker rm axiomcore-frontend axiomcore-api
```

View logs:
```powershell
docker logs axiomcore-frontend
```

## Troubleshooting

### Brain knowledge file not found
**Error:** `Brain Knowledge file not found at ...`

**Solution:** Create the file or specify correct path:
```powershell
.\multi-agent-dashboard.ps1 -BrainFile "C:\path\to\brain.json"
```

### Agent keeps failing
**Solution:** Enable auto-retry and check logs:
```powershell
.\multi-agent-dashboard.ps1 -AutoRetry
# Then check: $env:USERPROFILE\Projects\axiomcore\multi-agent-log.txt
```

### Port already in use
**Error:** Port binding issues

**Solution:** Stop conflicting containers:
```powershell
docker ps
docker stop {container-name}
```

### npm install fails
**Solution:** Ensure Node.js is installed and accessible:
```powershell
node --version
npm --version
```

## Performance Tuning

### Adjust Concurrent Agents
- **Low-end systems**: Use 1-2 concurrent agents
- **Mid-range systems**: Use 2-3 concurrent agents  
- **High-end systems**: Use 3-5 concurrent agents

```powershell
# For low-end systems
.\multi-agent-dashboard.ps1 -MaxConcurrentAgents 1

# For high-end systems
.\multi-agent-dashboard.ps1 -MaxConcurrentAgents 5
```

### Memory Considerations
Each agent requires:
- ~500MB for Node.js operations
- ~1GB for Docker builds
- Additional memory for running containers

**Recommended minimum**: 8GB RAM for 2 concurrent agents

## Integration

### CI/CD Integration
Add to your pipeline:

```yaml
# .github/workflows/deploy.yml
- name: Run Multi-Agent Dashboard
  shell: pwsh
  run: |
    .\multi-agent-dashboard.ps1 -MaxConcurrentAgents 2 -VisualMode:$false
```

### Scheduled Execution
Create a Windows Task Scheduler task:

```powershell
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
  -Argument "-File C:\path\to\multi-agent-dashboard.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At 9am
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "AxiomCore-Dashboard"
```

## Contributing

Contributions are welcome! Please submit pull requests or open issues on GitHub.

## License

MIT License - See LICENSE file for details

## Support

For issues and questions:
- GitHub Issues: https://github.com/FARICJH59/README-.gitignore-license/issues
- Documentation: This README

## Changelog

### Version 1.0.0 (Current)
- Initial release
- Multi-agent orchestration
- Visual dashboard with progress bars
- Pause/resume functionality
- Auto-retry capability
- Comprehensive logging
- Docker integration
- Browser auto-launch
