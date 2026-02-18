# Multi-Agent Dashboard - Visual Reference

## Dashboard Layout

The Multi-Agent Monitoring Dashboard provides a real-time, color-coded visual interface for managing multiple projects simultaneously.

### Main Interface Components

```
╔════════════════════════════════════════════════════════════╗
║     Multi-Agent Monitoring Dashboard - AxiomCore           ║
╚════════════════════════════════════════════════════════════╝

 Status: RUNNING
 Press [P] to Pause/Resume | [Q] to Quit | [R] to Refresh

 AGENT STATUS:
────────────────────────────────────────────────────────────
 [Running   ] axiomcore                    [████████████░░░] 80%
    └─ Building Docker images
 [Completed ] energy-dashboard             [███████████████] 100%
 [Failed    ] ai-predictor                 [███████░░░░░░░░] 50%
    └─ Error: Docker build failed
 [Queued    ] ml-service                   

 STATISTICS:
────────────────────────────────────────────────────────────
  Completed: 1
  Failed: 1
  Running: 1
  Queued: 1

 RECENT LOGS:
────────────────────────────────────────────────────────────
  12:34:56 - [axiomcore] Creating frontend structure
  12:34:58 - [axiomcore] Building Docker image for frontend
  12:35:01 - [energy-dashboard] launched successfully
  12:35:03 - [ai-predictor] Error: Docker build failed
  12:35:05 - [axiomcore] Starting Docker container for api

════════════════════════════════════════════════════════════
```

## Color Scheme

The dashboard uses color coding for quick status identification:

### Agent Status Colors
- **Green** (`Completed`) - Agent successfully completed all tasks
- **Red** (`Failed`) - Agent encountered an error
- **Cyan** (`Running`) - Agent is currently executing tasks
- **Gray** (`Queued`) - Agent is waiting for an available slot

### Log Entry Colors
- **Green** - Success messages (e.g., "launched successfully")
- **Red** - Error messages (e.g., "Error:", "failed")
- **Yellow** - Warning messages (e.g., "Warning:", "retry")
- **Gray** - Informational messages

### Progress Bar Colors
- **Green bars** (`█`) - Completed progress
- **Dark Gray dots** (`░`) - Remaining progress
- **White percentage** - Numeric progress indicator

## Agent Lifecycle Stages

Each agent progresses through these stages, reflected in the progress bar:

| Stage | Progress | Status Message |
|-------|----------|----------------|
| **Repository Clone** | 10-25% | "Cloning repository" |
| **Frontend Scaffold** | 30-45% | "Scaffolding frontend" |
| **Backend Scaffold** | 50-65% | "Scaffolding backend" |
| **Docker Build** | 70-90% | "Building Docker images" |
| **Browser Launch** | 95-100% | "Launching browser" |
| **Complete** | 100% | Status changes to "Completed" |

## Interactive Controls

### Keyboard Shortcuts
- **[P]** - Pause/Resume
  - When paused, status shows "PAUSED" in yellow
  - No new agents start while paused
  - Running agents continue to completion
  
- **[R]** - Force Refresh
  - Immediately updates the display
  - Useful if display appears stale
  
- **[Q]** - Quit
  - Graceful shutdown
  - Waits for running agents to complete
  - Displays final summary

## Pause Mode

When paused, the dashboard shows:

```
 Status: PAUSED
 Press [P] to Pause/Resume | [Q] to Quit | [R] to Refresh
```

The status indicator changes from green to yellow, and no new agents will start until resumed.

## Final Summary

After all agents complete, the dashboard displays:

```
========================================
 FINAL SUMMARY
========================================
 Total Projects: 4
 Completed: 2
 Failed: 1
 Log File: C:\Users\Username\Projects\axiomcore\multi-agent-log.txt
========================================
```

## Statistics Panel

The statistics section provides real-time counters:

- **Completed** (Green) - Number of successfully completed agents
- **Failed** (Red) - Number of failed agents
- **Running** (Cyan) - Number of currently executing agents
- **Queued** (Gray) - Number of agents waiting to start

## Log Display

The recent logs section shows the last 10 log entries with:
- Timestamp (HH:mm:ss format)
- Agent name in brackets
- Action or status message
- Color coding based on message type

## Progress Bar Details

Progress bars provide visual feedback with:
- **Width**: 30 characters
- **Filled portion**: Green bars (`█`)
- **Empty portion**: Dark gray dots (`░`)
- **Percentage**: Numeric value (0-100%)

Example states:
- `[               ] 0%` - Just queued
- `[███████░░░░░░░░] 50%` - Half complete
- `[███████████████] 100%` - Fully complete

## Error Display

When an agent fails, additional information is shown:

```
 [Failed    ] project-name                [████████░░░░░░░░] 55%
    └─ Error: npm install failed: Module not found
```

The error message is displayed in red, indented below the progress bar.

## Concurrency Control

The `MaxConcurrentAgents` parameter (default: 2) limits simultaneous execution:

- **Max 1**: Sequential execution, lowest resource usage
- **Max 2**: Default, balanced performance and resource usage
- **Max 3+**: Higher throughput, requires more system resources

Visual indication: Count in "Running" statistic never exceeds the limit.

## Auto-Retry Visualization

When auto-retry is enabled (`-AutoRetry`), failed agents show:

```
12:35:10 - [project-name] Error: Docker build failed
12:35:11 - [project-name] Retrying project-name (attempt #1)
```

The agent moves back to "Queued" status and will retry up to 3 times.

## Browser Launch

When frontend services start successfully:

```
12:35:15 - [axiomcore] Frontend launched at http://localhost:3000
```

A browser window automatically opens to the specified URL.

## Resource Requirements

Visual dashboard requirements:
- **Terminal**: PowerShell Console (not ISE)
- **Width**: Minimum 80 characters recommended
- **Height**: Minimum 30 lines for optimal display
- **Colors**: 16-color support minimum (true color preferred)

## Non-Visual Mode

Run with `-VisualMode:$false` for simple console output:

```powershell
.\multi-agent-dashboard.ps1 -VisualMode:$false
```

Output will be sequential log messages without the visual dashboard interface.

## Performance Notes

- Display refreshes every 1 second (500ms * 2 iterations)
- Log buffer limited to 100 entries (shows last 10)
- Minimal CPU usage when no agents are running
- Memory scales with number of concurrent agents

## Tips for Best Experience

1. **Terminal Size**: Maximize terminal window for best display
2. **Font**: Use monospaced font (Consolas, Courier New, etc.)
3. **Theme**: Dark theme recommended for color contrast
4. **Logging**: Review log file for complete history: `multi-agent-log.txt`
5. **Monitoring**: Watch statistics panel for overall progress
6. **Troubleshooting**: Check recent logs for error details

## Example Session

A typical dashboard session showing project bootstrapping:

1. **Start**: All agents in "Queued" state
2. **First Wave**: 2 agents start (max concurrency)
3. **Progress**: Progress bars advance as tasks complete
4. **Completion**: First agents finish, new ones start
5. **Browser Launch**: Frontends open in browser tabs
6. **Final**: All agents either "Completed" or "Failed"
7. **Summary**: Statistics show final counts

The entire process is visualized in real-time with color-coded status updates and progress indicators.
