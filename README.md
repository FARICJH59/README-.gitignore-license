# axiomcore

AxiomCore MVP — backend, frontend, AI orchestration

## Description

This repository serves as the foundation for the AxiomCore MVP platform, providing backend services, frontend interfaces, and AI orchestration capabilities. The project is a comprehensive full-stack solution supporting both PowerShell and Python development environments.

## Features

- Full-stack platform architecture
- PowerShell scripting support
- Python application development
- Cross-platform compatibility
- **GitHub Codespaces support** for cloud-based development

## Getting Started

### Prerequisites

- PowerShell 7.0 or higher
- Python 3.8 or higher

**OR** use **GitHub Codespaces** for instant cloud-based development without local setup! [Learn more about Codespaces integration](CODESPACES.md)

### Installation

#### Option 1: GitHub Codespaces (Recommended for Quick Start)

Open this repository directly in GitHub Codespaces for instant cloud-based development:

1. Click the **"Code"** button on the GitHub repository page
2. Select the **"Codespaces"** tab
3. Click **"Create codespace on main"**

All prerequisites and tools will be automatically configured. See [CODESPACES.md](CODESPACES.md) for detailed information.

#### Option 2: Clone the Repository

Clone the repository:

```bash
git clone https://github.com/TechFusion-Quantum-Global-Platform/axiomcore.git
cd axiomcore
```

#### Option 3: Create a New Repository

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

## GitHub Codespaces Integration

### How This Repository Relates to Your Codespaces

This repository is **fully integrated with GitHub Codespaces**, providing a cloud-based development environment that eliminates local setup requirements. When you ask "How is this repo related to my code Spaces?", here's the relationship:

- **This Repository** = Your AxiomCore platform codebase, scripts, and configurations
- **GitHub Codespaces** = The cloud-based development environment where you can work on this repository
- **Together** = A complete cloud development solution with zero local configuration

### Quick Start with Codespaces

1. **Open in Codespaces**: Click "Code" → "Codespaces" → "Create codespace"
2. **Automatic Setup**: PowerShell, Python, Node.js, and all tools are pre-configured
3. **Start Developing**: Run scripts, start servers, and develop immediately

### Benefits

- ✅ **No Local Setup**: Skip installing PowerShell, Python, Node.js, Docker, etc.
- ✅ **Consistent Environment**: Same setup for all team members
- ✅ **Work Anywhere**: Access from any device with a browser
- ✅ **Pre-configured Tools**: VS Code extensions and settings ready to go
- ✅ **Port Forwarding**: Automatic access to running services (API, frontend, etc.)
- ✅ **QGPS Cockpit**: Full support for multi-repository management in the cloud

### Learn More

For comprehensive information about using this repository with GitHub Codespaces, see [CODESPACES.md](CODESPACES.md).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
