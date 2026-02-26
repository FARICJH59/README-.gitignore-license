# Using AxiomCore with GitHub Codespaces

## Overview

This repository, **AxiomCore MVP**, is fully compatible with **GitHub Codespaces**, providing you with a cloud-based development environment that can be accessed from anywhere. This document explains how this repository relates to your GitHub Codespaces and how to use them together effectively.

## What is the Relationship?

### This Repository and Your Codespaces

**This repository (`FARICJH59/README-.gitignore-license`)** serves as:

1. **A Development Template**: Contains the complete AxiomCore MVP platform with backend, frontend, and AI orchestration capabilities
2. **A Multi-Repository Manager**: Includes tools (like QGPS Cockpit) to manage multiple related repositories from a single location
3. **A Cloud-Ready Codebase**: Can be opened and developed in GitHub Codespaces without any local setup

### How They Work Together

When you open this repository in GitHub Codespaces:

- **Instant Environment**: Codespaces provides a pre-configured development environment in the cloud
- **No Local Setup**: You don't need to install PowerShell, Python, Node.js, or other dependencies locally
- **Consistent Development**: All team members get the same development environment
- **Access Anywhere**: Work on the project from any device with a web browser
- **Integrated Tools**: Git, terminal, and development tools are all available in the cloud

## Getting Started with Codespaces

### Opening This Repository in Codespaces

1. **From GitHub Web Interface**:
   - Navigate to https://github.com/FARICJH59/README-.gitignore-license
   - Click the green **"Code"** button
   - Select the **"Codespaces"** tab
   - Click **"Create codespace on main"** (or your preferred branch)

2. **From GitHub CLI**:
   ```bash
   gh codespace create --repo FARICJH59/README-.gitignore-license
   ```

3. **From VS Code**:
   - Install the "GitHub Codespaces" extension
   - Use Command Palette (Ctrl+Shift+P): "Codespaces: Create New Codespace"
   - Select this repository

### What Happens When You Open in Codespaces

GitHub Codespaces will:
1. Create a virtual machine in the cloud
2. Clone this repository
3. Install the devcontainer configuration (if available)
4. Set up all required development tools
5. Open VS Code in your browser (or connect to your local VS Code)

## Development Workflow in Codespaces

### 1. Initial Setup

Once your Codespace is running:

```bash
# Check PowerShell version
pwsh --version

# Check Python version
python --version

# Check Node.js version (for frontend work)
node --version

# Install project dependencies (if needed)
npm install  # For frontend
pip install -r requirements.txt  # For Python components
```

### 2. Using QGPS Cockpit

The QGPS Autonomous Cockpit works in Codespaces:

```powershell
# Navigate to scripts directory
cd /workspaces/README-.gitignore-license

# Run the cockpit
pwsh ./scripts/qgps-cockpit.ps1

# With custom settings
pwsh ./scripts/qgps-cockpit.ps1 -MaxConcurrency 3
```

### 3. Working with Multiple Repositories

If you manage multiple repositories:

```bash
# Clone related repositories into your Codespace
cd /workspaces
git clone https://github.com/YourOrg/other-repo.git

# Register with QGPS
pwsh ./scripts/generate-autopilot-repo.ps1
```

### 4. Running Dev Servers

Start development servers in your Codespace:

```bash
# Frontend development
cd frontend
npm run dev

# API server
cd api
npm start

# Python services
cd ai
python main.py
```

**Note**: Codespaces automatically forwards ports, so you can access your running services through generated URLs.

## Advantages of Using Codespaces

### For Individual Developers

- **Quick Start**: No need to configure your local machine
- **Consistency**: Same environment every time
- **Portability**: Work from any device
- **Resource Isolation**: Development doesn't affect your local system
- **Easy Cleanup**: Delete Codespace when done, no local artifacts

### For Teams

- **Onboarding**: New developers can start immediately
- **Standardization**: Everyone uses the same tools and versions
- **Collaboration**: Share Codespaces for pair programming
- **Cost Effective**: No need for powerful local machines

### For This Project Specifically

- **Multi-Language Support**: PowerShell, Python, and Node.js all available
- **Scripts Work**: All automation scripts (`.ps1`, `.sh`) run without modification
- **QGPS Integration**: Full cockpit functionality in the cloud
- **Version Control**: Git operations work seamlessly

## Codespaces Features for AxiomCore

### Port Forwarding

When you run services (API, frontend, etc.), Codespaces automatically:
- Detects open ports
- Forwards them to your local machine
- Provides shareable URLs for team collaboration

Example:
```bash
# Start API server on port 8080
npm run start
# Codespaces will show: "Port 8080 is available at: https://..."
```

### Secrets Management

For sensitive configuration (API keys, tokens):

1. Add secrets in GitHub Codespaces settings
2. Access them as environment variables:
   ```bash
   echo $API_KEY
   ```

### Extensions

VS Code extensions specified in `.devcontainer/devcontainer.json` are automatically installed.

### Persistent Storage

- Your `/workspaces` directory persists between sessions
- Changes to the filesystem are saved
- Codespace can be stopped and restarted without losing work

## Best Practices

### 1. Resource Management

- **Stop Codespaces** when not in use to avoid usage charges
- **Delete unused** Codespaces to free up resources
- **Set timeouts** to automatically stop inactive Codespaces

### 2. Configuration

- Use `.devcontainer/devcontainer.json` for custom setup (see below)
- Define required extensions
- Specify port forwarding preferences

### 3. Collaboration

- **Share Codespaces** with team members for real-time collaboration
- Use **Live Share** for pair programming
- Commit and push changes regularly

### 4. Security

- Never commit secrets to the repository
- Use GitHub Codespaces secrets for sensitive data
- Review `.gitignore` to prevent accidental commits

## Customizing Your Codespace

### Devcontainer Configuration

This repository can be enhanced with a `.devcontainer/devcontainer.json` file to:
- Pre-install VS Code extensions
- Run setup scripts automatically
- Configure shell settings
- Set environment variables

Example configuration (to be added):
```json
{
  "name": "AxiomCore Development",
  "image": "mcr.microsoft.com/devcontainers/universal:2",
  "features": {
    "ghcr.io/devcontainers/features/powershell:1": {},
    "ghcr.io/devcontainers/features/python:1": {
      "version": "3.8"
    },
    "ghcr.io/devcontainers/features/node:1": {
      "version": "18"
    }
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-vscode.powershell",
        "ms-python.python",
        "dbaeumer.vscode-eslint"
      ]
    }
  },
  "postCreateCommand": "echo 'AxiomCore Codespace ready!'",
  "forwardPorts": [8080, 3000]
}
```

## Troubleshooting

### Common Issues

**Problem**: Scripts fail with permission errors
```bash
# Solution: Make scripts executable
chmod +x ./scripts/*.sh
chmod +x ./create-repo.sh
```

**Problem**: PowerShell not found
```bash
# Solution: Install PowerShell (usually pre-installed in Codespaces)
# Or use the devcontainer configuration
```

**Problem**: Port not accessible
```bash
# Solution: Check port forwarding in Ports panel (VS Code)
# Make sure the service is binding to 0.0.0.0, not localhost
```

**Problem**: Out of disk space
```bash
# Solution: Clean up unnecessary files
rm -rf node_modules  # Re-install when needed
docker system prune  # If using Docker
```

## Relationship Summary

To directly answer "How is this repo related to my code Spaces":

1. **This repository IS your codebase** that can run in GitHub Codespaces
2. **Codespaces IS the environment** where you can develop this repository
3. **They are complementary**: 
   - Repository = The code, scripts, and project files
   - Codespaces = The cloud-based development environment to work on that code

Think of it this way:
- **This Repository** = Your house blueprints and furniture
- **GitHub Codespaces** = The lot where you build the house

## Next Steps

1. **Try it out**: Open this repository in a Codespace
2. **Explore**: Run the scripts and tools
3. **Customize**: Add `.devcontainer` configuration for your needs
4. **Collaborate**: Share Codespaces with your team
5. **Optimize**: Configure automatic tasks and extensions

## Additional Resources

- [GitHub Codespaces Documentation](https://docs.github.com/en/codespaces)
- [Devcontainer Specification](https://containers.dev/)
- [VS Code in Codespaces](https://code.visualstudio.com/docs/remote/codespaces)

## Contact

For questions about this repository in Codespaces:
- **Repository Issues**: https://github.com/FARICJH59/README-.gitignore-license/issues
- **Email**: farichva@gmail.com
- **Maintainer**: FARICJH59

---

**Last Updated**: 2026-02-22  
**Version**: 1.0
