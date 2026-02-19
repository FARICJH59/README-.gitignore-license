# QGPS Industrial Autopilot - Quick Reference

## What is QGPS?

QGPS (Quantum Global Platform System) is a **Brain-driven, MCP-managed multi-repository autopilot system** for industrial-grade projects. It provides centralized policy management, automated compliance enforcement, and multi-repo orchestration.

## Quick Start

### 1. Create QGPS System (One Command)

```powershell
# Windows
powershell -NoProfile -ExecutionPolicy Bypass -File .\create-qgps-starter.ps1 -RootPath "C:\Projects\QGPS"

# Linux/macOS
pwsh -File ./create-qgps-starter.ps1 -RootPath "/home/user/Projects/QGPS"
```

### 2. Navigate and Bootstrap

```powershell
cd C:\Projects\QGPS  # or your path
.\scripts\mega-bootstrap-qgps.ps1
```

### 3. Create Your First Autopilot Repository

```powershell
.\scripts\generate-autopilot-repo.ps1 `
    -RepoName "MyProject" `
    -RepoPath "C:\Projects\MyProject" `
    -Priority 5
```

## Core Commands

```powershell
# Sync repository with Brain
.\scripts\axiom-sync.ps1 -RepoPath "path/to/repo"

# Check compliance
.\scripts\axiom-compliance.ps1 -RepoPath "path/to/repo"

# Check compliance and auto-fix issues
.\scripts\axiom-compliance.ps1 -RepoPath "path/to/repo" -FixIssues

# View all repositories status
.\scripts\axiom-orchestrator.ps1 -Action status

# Sync all repositories
.\scripts\axiom-orchestrator.ps1 -Action sync-all

# Check compliance for all repositories
.\scripts\axiom-orchestrator.ps1 -Action check-all
```

## What Gets Created?

### Brain Core System
- **version.json** - Brain version and compatibility tracking
- **repo-registry.json** - Registry of all managed repositories
- **compliance/mandatory-modules.json** - Required folder/file structure
- **compliance/infra-policy.json** - Technology stack requirements

### Automation Scripts
- **axiom-sync.ps1** - Synchronizes repositories with Brain policies
- **axiom-compliance.ps1** - Validates compliance (with auto-fix)
- **axiom-orchestrator.ps1** - Multi-repo orchestration
- **generate-autopilot-repo.ps1** - Creates autopilot-ready repositories
- **mega-bootstrap-qgps.ps1** - System bootstrap and verification

### Repository Structure
Every managed repository will have:
```
project/
├── .brain/              # Brain synchronization data
│   ├── brain-version.json
│   ├── mandatory-modules.json
│   ├── infra-policy.json
│   ├── sync-metadata.json
│   └── compliance-log.json
├── src/                # Source code (mandatory)
├── config/             # Configuration (mandatory)
├── docs/               # Documentation (mandatory)
├── README.md          # Project docs (mandatory)
├── LICENSE            # License (mandatory)
└── .gitignore        # Git ignore (mandatory)
```

## Compliance Requirements

### Mandatory Structure
✅ Folders: `src/`, `config/`, `docs/`, `.brain/`  
✅ Files: `README.md`, `LICENSE`, `.gitignore`

### Technology Stack
- Node.js: 18.x+
- Python: 3.10+
- Docker: 24.x+
- Next.js: 14.x
- React: 18.x

### Security
- TLS 1.3
- SSL certificates required
- Vulnerability scanning required

## Features

✅ **Centralized Policy Management** - Brain core enforces standards  
✅ **Automated Compliance** - Validates structure and dependencies  
✅ **Multi-Repo Orchestration** - Manage multiple projects from one place  
✅ **Self-Healing** - Auto-fix compliance issues  
✅ **CI/CD Ready** - GitHub Actions workflow included  
✅ **Cross-Platform** - Works on Windows, Linux, macOS  
✅ **Priority-Based** - Manage project priorities (1-10)

## Use Cases

- ✅ ML/AI Projects
- ✅ IoT Edge Systems
- ✅ DevOps Automation
- ✅ SaaS Platforms
- ✅ Fintech Applications
- ✅ Industrial Automation
- ✅ Microservices
- ✅ Enterprise Systems

## Documentation

📚 **Complete Guide**: [`docs/QGPS-COMPLETE-GUIDE.md`](docs/QGPS-COMPLETE-GUIDE.md)  
📖 **Usage Examples**: [`docs/QGPS-EXAMPLES.md`](docs/QGPS-EXAMPLES.md)  
⚙️ **CI/CD Workflow**: [`.github/workflows/ci-cd-autopilot.yml`](.github/workflows/ci-cd-autopilot.yml)

## Testing

The system has been tested and verified:
- ✅ JSON configuration files validated
- ✅ Directory structure creation verified
- ✅ Brain sync functionality tested
- ✅ Compliance checking with auto-fix tested
- ✅ Cross-platform compatibility verified

## Architecture

```
QGPS System
    ├── Brain Core (Policies & Configuration)
    ├── Automation Scripts (PowerShell)
    ├── CI/CD Integration (GitHub Actions)
    └── Managed Repositories (Autopilot-ready)
```

## Workflow

1. **Create** - Generate QGPS system with one command
2. **Register** - Add repositories to Brain registry
3. **Sync** - Synchronize policies to repositories
4. **Validate** - Check compliance (auto-fix if needed)
5. **Orchestrate** - Manage multiple repositories
6. **Deploy** - Use CI/CD for continuous validation

## Example Session

```powershell
# Create QGPS system
.\create-qgps-starter.ps1 -RootPath "C:\QGPS"

# Navigate to it
cd C:\QGPS

# Bootstrap
.\scripts\mega-bootstrap-qgps.ps1

# Create first project
.\scripts\generate-autopilot-repo.ps1 -RepoName "WebApp" -RepoPath "C:\Projects\WebApp"

# Check status
.\scripts\axiom-orchestrator.ps1 -Action status

# Output:
# 📦 WebApp
#    Path: C:\Projects\WebApp
#    Priority: 5
#    Status: ✅ Exists
#    Brain: ✅ Synced
```

## Getting Help

1. **Complete Documentation**: See `docs/QGPS-COMPLETE-GUIDE.md`
2. **Examples**: See `docs/QGPS-EXAMPLES.md`
3. **Troubleshooting**: Check compliance logs in `.brain/compliance-log.json`
4. **Support**: Create an issue in the repository

## License

MIT License - See [LICENSE](LICENSE) file

---

**Built for enterprise-grade automation** 🏭  
**Version**: 1.0.0  
**Status**: Production Ready ✅

🚀 Ready to build industrial-grade autopilot systems!
