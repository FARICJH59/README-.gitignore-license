# Axiomcore-SYSTEM

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
git clone https://github.com/FARIJCH59/Axiomcore-SYSTEM.git
cd Axiomcore-SYSTEM
```

#### Option 2: Create a New Repository

If you need to create a new Axiomcore-SYSTEM repository, you can use the provided scripts:

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
gh repo create FARIJCH59/Axiomcore-SYSTEM \
  --private \
  --description "AxiomCore MVP — backend, frontend, AI orchestration" \
  --confirm
```

After creating the repository, you can initialize it with your project files:

```bash
# Clone the empty repository
git clone https://github.com/FARIJCH59/Axiomcore-SYSTEM.git
cd Axiomcore-SYSTEM

# Copy your project files into the directory
# Then commit and push them
git add .
git commit -m "Initial commit"
git push -u origin main
```

> **Note**: Option 2 requires GitHub CLI (`gh`) to be installed and authenticated. The repository will be created as private under the TechFusion-Quantum-Global-Platform organization.

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
